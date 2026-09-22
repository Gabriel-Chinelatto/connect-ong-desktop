import 'dart:convert';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

/// Indicadores de resultado (item F-08 do Plano de Ação — nota 5 em "Análise
/// de Dados e Resultados" na FECITEC). Antes o painel só mostrava contagens;
/// aqui a ONG vê se a plataforma está FUNCIONANDO para ela:
///  - funil: necessidade publicada → recebeu interesse → atendida;
///  - taxa de atendimento, taxa de aceite e tempos medianos;
///  - por categoria e mês a mês (últimos 12 meses).
/// Alterna entre "Minha ONG" (`GET /ongs/{id}/indicadores`) e "Plataforma"
/// (`GET /publico/indicadores`) para a ONG se comparar com a média.
class IndicadoresScreen extends StatefulWidget {
  final int ongId;

  const IndicadoresScreen({super.key, required this.ongId});

  @override
  State<IndicadoresScreen> createState() => _IndicadoresScreenState();
}

class _IndicadoresScreenState extends State<IndicadoresScreen> {
  bool _plataforma = false;
  Map<String, dynamic>? _dados;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _dados = null;
      _erro = null;
    });
    try {
      final url = _plataforma
          ? '${ApiService.baseUrl}/publico/indicadores'
          : '${ApiService.baseUrl}/ongs/${widget.ongId}/indicadores';
      final r = await ApiService.rede
          .get(Uri.parse(url), headers: ApiService.authHeaders())
          .timeout(ApiService.timeout);
      if (r.statusCode != 200) throw Exception('HTTP ${r.statusCode}');
      final d = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
      if (mounted) setState(() => _dados = d);
    } catch (e) {
      if (mounted) setState(() => _erro = ApiService.mensagemAmigavel(e));
    }
  }

  num _n(dynamic v) => v is num ? v : 0;

  String _pct(dynamic v) => v == null
      ? '—'
      : '${(v as num).toStringAsFixed(1).replaceAll('.', ',')}%';

  String _dias(dynamic v) {
    if (v == null) return '—';
    final d = (v as num).toDouble();
    return d < 1
        ? 'menos de 1 dia'
        : '${d.toStringAsFixed(1).replaceAll('.', ',')} dias';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Indicadores e resultados'),
      ),
      body: _erro != null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_erro!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: _carregar, child: const Text('Tentar de novo')),
              ]),
            )
          : _dados == null
              ? const Center(child: CircularProgressIndicator())
              : _conteudo(),
    );
  }

  Widget _conteudo() {
    final d = _dados!;
    final f = (d['funil'] as Map?) ?? const {};
    final categorias = (d['porCategoria'] as List?) ?? const [];
    final mensal = (d['mensal'] as List?) ?? const [];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(width: 400, child: _seletor())),
        const SizedBox(height: 16),
        Wrap(spacing: 12, runSpacing: 12, children: [
          _kpi('Necessidades publicadas', '${_n(f['necessidades'])}',
              Icons.campaign_outlined),
          _kpi(
              'Taxa de atendimento', _pct(d['taxaAtendimento']), Icons.task_alt,
              dica: 'Necessidades com ao menos uma doação concluída'),
          _kpi(
              'Taxa de aceite', _pct(d['taxaAceite']), Icons.handshake_outlined,
              dica: 'Interesses aceitos entre os respondidos'),
          _kpi('Tempo até responder', _dias(d['diasAteRespostaDaOng']),
              Icons.schedule,
              dica: 'Mediana entre o interesse do doador e a resposta'),
          _kpi('Tempo até concluir', _dias(d['diasAteConclusao']),
              Icons.flag_outlined,
              dica: 'Mediana entre o interesse e a doação entregue'),
        ]),
        const SizedBox(height: 24),
        _secao('Funil das necessidades', 'Quantas viram doação de verdade'),
        _barraFunil('Publicadas', _n(f['necessidades']), _n(f['necessidades']),
            AppColors.primary),
        _barraFunil('Receberam interesse', _n(f['necessidadesComInteresse']),
            _n(f['necessidades']), AppColors.primary.withValues(alpha: 0.8)),
        _barraFunil(
            'Atendidas (doação concluída)',
            _n(f['necessidadesAtendidas']),
            _n(f['necessidades']),
            AppColors.primary.withValues(alpha: 0.6)),
        const SizedBox(height: 12),
        _secao('Funil dos interesses',
            'O que acontece depois que um doador se oferece'),
        _barraFunil('Interesses recebidos', _n(f['interesses']),
            _n(f['interesses']), Colors.indigo),
        _barraFunil('Aceitos', _n(f['interessesAceitos']), _n(f['interesses']),
            Colors.indigo.withValues(alpha: 0.8)),
        _barraFunil('Concluídos', _n(f['interessesConcluidos']),
            _n(f['interesses']), Colors.indigo.withValues(alpha: 0.6)),
        _barraFunil('Aguardando resposta', _n(f['interessesPendentes']),
            _n(f['interesses']), Colors.orange),
        _barraFunil('Recusados', _n(f['interessesRecusados']),
            _n(f['interesses']), Colors.red.shade300),
        const SizedBox(height: 24),
        _secao(
            'Por categoria', 'Necessidades publicadas e taxa de atendimento'),
        if (categorias.isEmpty)
          const Text('Ainda não há necessidades publicadas.'),
        for (final c in categorias.take(10))
          _barraFunil(
            '${c['categoria']} · ${_pct(c['taxaAtendimento'])} atendidas',
            _n(c['necessidades']),
            categorias
                .map((x) => _n(x['necessidades']))
                .fold<num>(0, (a, b) => a > b ? a : b),
            AppColors.primary,
          ),
        const SizedBox(height: 24),
        _secao('Mês a mês',
            'Interesses recebidos (verde) e doações concluídas (azul), últimos 12 meses'),
        _grafMensal(mensal),
        const SizedBox(height: 12),
        Text(
          'Dados calculados na hora a partir do banco da plataforma. '
          '"Mediana" é o valor do meio: um caso esquecido por meses não distorce o número.',
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _seletor() => SegmentedButton<bool>(
        segments: const [
          ButtonSegment(
              value: false,
              label: Text('Minha ONG'),
              icon: Icon(Icons.storefront_outlined)),
          ButtonSegment(
              value: true,
              label: Text('Toda a plataforma'),
              icon: Icon(Icons.public)),
        ],
        selected: {_plataforma},
        onSelectionChanged: (s) {
          setState(() => _plataforma = s.first);
          _carregar();
        },
      );

  Widget _kpi(String titulo, String valor, IconData icone, {String? dica}) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      width: 210,
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icone, color: AppColors.primary),
        const SizedBox(height: 8),
        Text(valor,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(titulo, style: TextStyle(color: cs.onSurfaceVariant)),
      ]),
    );
    return dica == null ? card : Tooltip(message: dica, child: card);
  }

  Widget _secao(String titulo, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(sub,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ]),
    );
  }

  Widget _barraFunil(String rotulo, num valor, num maximo, Color cor) {
    final frac = maximo <= 0 ? 0.0 : (valor / maximo).clamp(0, 1).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(
            width: 260, child: Text(rotulo, overflow: TextOverflow.ellipsis)),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => Stack(children: [
              Container(
                height: 22,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Container(
                height: 22,
                width: c.maxWidth * frac,
                decoration: BoxDecoration(
                    color: cor, borderRadius: BorderRadius.circular(6)),
              ),
            ]),
          ),
        ),
        SizedBox(
          width: 70,
          child: Text('$valor',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }

  Widget _grafMensal(List mensal) {
    final maximo = mensal.fold<num>(1, (a, m) {
      final v = _n(m['interesses']);
      return v > a ? v : a;
    });
    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final m in mensal)
            Expanded(
              child: Tooltip(
                message:
                    '${m['mes']}: ${m['interesses']} interesses, ${m['concluidos']} concluídos',
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _coluna(
                            _n(m['interesses']) / maximo, AppColors.primary),
                        const SizedBox(width: 2),
                        _coluna(_n(m['concluidos']) / maximo, Colors.indigo),
                      ]),
                  const SizedBox(height: 4),
                  Text(
                    '${m['mes']}'.substring(5),
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _coluna(double frac, Color cor) => Container(
        width: 12,
        height: (150 * frac.clamp(0, 1)).toDouble() + 2,
        decoration:
            BoxDecoration(color: cor, borderRadius: BorderRadius.circular(3)),
      );
}
