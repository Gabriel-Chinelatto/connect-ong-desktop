import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/perfil_publico_doador.dart';
import '../../services/api_service.dart';
import '../../services/bloqueio_service.dart';
import '../../services/perfil_publico_doador_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/feedback/app_snackbar.dart';
import '../../widgets/feedback/empty_state.dart';
import 'perfil_publico_ong_screen.dart';

/// Perfil publico de um doador, visto pela ONG (contrato
/// GET /usuarios/{id}/perfil-publico). Header com foto/inicial, nome, cidade,
/// estrelas da media e "membro desde"; stats; avaliacoes de ONGs; prestacoes
/// ja recebidas. Degrada bem com campos null.
class PerfilPublicoDoadorScreen extends StatefulWidget {
  final int doadorId;
  final String doadorNome;

  const PerfilPublicoDoadorScreen({
    super.key,
    required this.doadorId,
    required this.doadorNome,
  });

  @override
  State<PerfilPublicoDoadorScreen> createState() =>
      _PerfilPublicoDoadorScreenState();
}

class _PerfilPublicoDoadorScreenState extends State<PerfilPublicoDoadorScreen> {
  final PerfilPublicoDoadorService _service = PerfilPublicoDoadorService();
  final BloqueioService _bloqueioService = BloqueioService();
  PerfilPublicoDoador? _perfil;
  Uint8List? _fotoBytes;
  bool _carregando = true;
  bool _erro = false;

  /// Estado do bloqueio deste doador pela ONG logada (GET /bloqueios).
  /// Backend antigo/erro degrada para "não bloqueado" (campo ausente).
  bool _bloqueado = false;
  bool _mudandoBloqueio = false;

  /// Guarda anti-duplo-clique ao abrir o perfil de uma ONG (contraparte das
  /// prestações). Evita empilhar a mesma tela duas vezes.
  bool _navegando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final p = await _service.buscar(widget.doadorId);
      Uint8List? bytes;
      if (p.fotoBase64 != null && p.fotoBase64!.isNotEmpty) {
        try {
          bytes = base64Decode(p.fotoBase64!);
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _perfil = p;
        _fotoBytes = bytes;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
    _carregarBloqueio();
  }

  /// Best-effort: consulta se este doador está na lista de bloqueados da ONG.
  /// Silencioso em erro (mantém o padrão "não bloqueado").
  Future<void> _carregarBloqueio() async {
    try {
      final lista = await _bloqueioService.listar();
      if (!mounted) return;
      setState(() {
        _bloqueado = lista.any((b) => b.doadorId == widget.doadorId);
      });
    } catch (_) {
      // Sem quebra: o botão continua mostrando "Bloquear".
    }
  }

  /// Bloqueia (com dialog de confirmação explicando o efeito) ou desbloqueia.
  Future<void> _alternarBloqueio() async {
    if (_mudandoBloqueio) return;

    if (!_bloqueado) {
      final confirmou = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Bloquear ${widget.doadorNome}?'),
          content: const Text(
              'O doador deixará de ver sua ONG e não poderá enviar '
              'mensagens. Você pode desbloquear quando quiser, em '
              'Configurações > Doadores bloqueados.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.block, size: 18),
              label: const Text('Bloquear'),
            ),
          ],
        ),
      );
      if (confirmou != true || !mounted) return;
    }

    setState(() => _mudandoBloqueio = true);
    try {
      if (_bloqueado) {
        await _bloqueioService.desbloquear(widget.doadorId);
      } else {
        await _bloqueioService.bloquear(widget.doadorId);
      }
      if (!mounted) return;
      setState(() => _bloqueado = !_bloqueado);
      if (_bloqueado) {
        AppSnackbar.aviso(context, '${widget.doadorNome} foi bloqueado.');
      } else {
        AppSnackbar.sucesso(context, '${widget.doadorNome} foi desbloqueado.');
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _mudandoBloqueio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Perfil de ${widget.doadorNome}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro || _perfil == null
              ? EmptyState(
                  icone: Icons.cloud_off_outlined,
                  mensagem: 'Não foi possível carregar o perfil',
                  detalhe: 'Verifique sua conexão e tente novamente.',
                  acaoRotulo: 'Tentar de novo',
                  onAcao: _carregar,
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        _cabecalho(_perfil!),
                        const SizedBox(height: AppSpacing.md),
                        _stats(_perfil!),
                        if (_perfil!.email != null ||
                            _perfil!.telefone != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _secao(
                            'Contato',
                            Icons.contact_mail_outlined,
                            [
                              if (_perfil!.email != null)
                                _linhaContato(
                                    Icons.email_outlined, _perfil!.email!),
                              if (_perfil!.telefone != null)
                                _linhaContato(
                                    Icons.phone_outlined, _perfil!.telefone!),
                            ],
                          ),
                        ],
                        if (_perfil!.avaliacoes.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _secao(
                            'Avaliações de ONGs',
                            Icons.star_outline,
                            [
                              for (final a in _perfil!.avaliacoes)
                                _avaliacao(a),
                            ],
                          ),
                        ],
                        if (_perfil!.prestacoesRecebidas.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          _secao(
                            'Prestações de contas recebidas',
                            Icons.receipt_long_outlined,
                            _prestacoesAgrupadas(_perfil!.prestacoesRecebidas),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _botaoBloqueio(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Botão de bloqueio no rodapé do perfil (estilo WhatsApp): vermelho para
  /// bloquear; vira "Desbloquear" quando o doador já está bloqueado.
  Widget _botaoBloqueio() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_bloqueado)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Você bloqueou este doador',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        Tooltip(
          message: _bloqueado
              ? 'O doador voltará a ver sua ONG e a poder enviar mensagens'
              : 'O doador deixará de ver sua ONG e não poderá enviar mensagens',
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: _bloqueado ? AppColors.primary : AppColors.error,
              side: BorderSide(
                  color:
                      _bloqueado ? AppColors.primary : AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _mudandoBloqueio ? null : _alternarBloqueio,
            icon: _mudandoBloqueio
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(_bloqueado ? Icons.lock_open : Icons.block, size: 18),
            label:
                Text(_bloqueado ? 'Desbloquear doador' : 'Bloquear doador'),
          ),
        ),
      ],
    );
  }

  Widget _cabecalho(PerfilPublicoDoador p) {
    final cs = Theme.of(context).colorScheme;
    final inicial = p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?';
    final localizacao = [p.cidade, p.estado]
        .where((e) => e != null && e.isNotEmpty)
        .join(' - ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              backgroundImage:
                  _fotoBytes != null ? MemoryImage(_fotoBytes!) : null,
              child: _fotoBytes == null
                  ? Text(inicial,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700))
                  : null,
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nome,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  if (localizacao.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.place_outlined,
                            size: 16, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(localizacao,
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (int i = 0; i < 5; i++)
                        Icon(
                          i < (p.notaMediaDoador ?? 0).round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 18,
                          color: Colors.amber,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        p.totalAvaliacoesDoador > 0 &&
                                p.notaMediaDoador != null
                            ? '${p.notaMediaDoador!.toStringAsFixed(1)} '
                                '(${p.totalAvaliacoesDoador})'
                            : 'Sem avaliações',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (p.membroDesde != null) ...[
                    const SizedBox(height: 6),
                    Text('Membro desde ${_mesAno(p.membroDesde!)}',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stats(PerfilPublicoDoador p) {
    Widget item(IconData icon, String v, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(v,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            item(Icons.handshake_outlined, '${p.matchesConcluidos}',
                'Doações concluídas'),
            item(Icons.pix, '${p.totalDoacoesPix}', 'Doações PIX'),
            item(Icons.star_outline, '${p.totalAvaliacoesDoador}',
                'Avaliações'),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, IconData icon, List<Widget> filhos) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...filhos,
          ],
        ),
      ),
    );
  }

  Widget _avaliacao(AvaliacaoDoador a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(a.ongNome ?? 'ONG',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              for (int i = 0; i < 5; i++)
                Icon(i < a.nota ? Icons.star : Icons.star_border,
                    size: 14, color: Colors.amber),
            ],
          ),
          if (a.comentario != null && a.comentario!.isNotEmpty)
            Text(a.comentario!),
          if (a.criadoEm != null)
            Text(_mesAno(a.criadoEm!),
                style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  /// Linha de contato (e-mail/telefone) selecionável para copiar.
  Widget _linhaContato(IconData icon, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: SelectableText(texto)),
          ],
        ),
      );

  /// Agrupa as prestações recebidas pela ONG emissora (contraparte). Cada ONG
  /// vira um cabeçalho clicável (→ perfil da ONG) mostrado UMA vez, com suas
  /// prestações listadas abaixo. Prestações sem ONG identificada (ongId/ongNome
  /// nulos) degradam: aparecem sem cabeçalho/link.
  List<Widget> _prestacoesAgrupadas(List<PrestacaoRecebida> lista) {
    final grupos = <String, List<PrestacaoRecebida>>{};
    final ordem = <String>[];
    for (final p in lista) {
      final chave = p.ongId != null
          ? 'id:${p.ongId}'
          : (p.ongNome != null && p.ongNome!.isNotEmpty
              ? 'nome:${p.ongNome}'
              : '_sem_');
      if (!grupos.containsKey(chave)) ordem.add(chave);
      grupos.putIfAbsent(chave, () => []).add(p);
    }

    final widgets = <Widget>[];
    for (var g = 0; g < ordem.length; g++) {
      final chave = ordem[g];
      final itens = grupos[chave]!;
      final ref = itens.first;
      if (g > 0) widgets.add(const Divider(height: 20));
      if (chave != '_sem_') widgets.add(_cabecalhoOng(ref));
      for (final p in itens) {
        widgets.add(_itemPrestacao(p));
      }
    }
    return widgets;
  }

  /// Cabeçalho da ONG emissora: clicável quando há ongId; caso contrário só
  /// exibe o nome (degrada sem link).
  Widget _cabecalhoOng(PrestacaoRecebida ref) {
    final nome = (ref.ongNome != null && ref.ongNome!.isNotEmpty)
        ? ref.ongNome!
        : 'ONG';
    final cs = Theme.of(context).colorScheme;
    if (ref.ongId == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.corporate_fare_outlined,
                size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(nome,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant)),
            ),
          ],
        ),
      );
    }
    return Tooltip(
      message: 'Ver perfil de $nome',
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _abrirOng(ref.ongId!, nome),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.corporate_fare_outlined,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(nome,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  size: 16, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemPrestacao(PrestacaoRecebida p) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(left: 22, bottom: 12, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (p.descricao.isNotEmpty) Text(p.descricao),
          if ((p.necessidadeTitulo != null &&
                  p.necessidadeTitulo!.isNotEmpty) ||
              p.criadoEm != null) ...[
            const SizedBox(height: 2),
            Text(
              [
                if (p.necessidadeTitulo != null &&
                    p.necessidadeTitulo!.isNotEmpty)
                  p.necessidadeTitulo,
                if (p.criadoEm != null) _mesAno(p.criadoEm!),
              ].where((e) => e != null && e.isNotEmpty).join(' • '),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ],
      ),
    );
  }

  /// Abre o perfil público da ONG contraparte (com guarda anti-duplo-clique).
  Future<void> _abrirOng(int ongId, String ongNome) async {
    if (_navegando) return;
    _navegando = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PerfilPublicoOngScreen(ongId: ongId, ongNome: ongNome),
      ),
    );
    if (mounted) _navegando = false;
  }

  /// Formata uma data ISO como "MM/aaaa" (usado em "membro desde").
  String _mesAno(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final mes = d.month.toString().padLeft(2, '0');
    return '$mes/${d.year}';
  }
}
