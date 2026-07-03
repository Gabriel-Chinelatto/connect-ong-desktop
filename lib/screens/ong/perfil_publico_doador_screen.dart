import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/perfil_publico_doador.dart';
import '../../services/perfil_publico_doador_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/feedback/empty_state.dart';

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
  PerfilPublicoDoador? _perfil;
  Uint8List? _fotoBytes;
  bool _carregando = true;
  bool _erro = false;

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
                            [
                              for (final p in _perfil!.prestacoesRecebidas)
                                _prestacao(p),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
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

  Widget _prestacao(PrestacaoRecebida p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
          if (p.descricao.isNotEmpty) Text(p.descricao),
          const SizedBox(height: 2),
          Text(
            [
              if (p.ongNome != null && p.ongNome!.isNotEmpty) p.ongNome,
              if (p.necessidadeTitulo != null &&
                  p.necessidadeTitulo!.isNotEmpty)
                p.necessidadeTitulo,
            ].join(' • '),
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Formata uma data ISO como "MM/aaaa" (usado em "membro desde").
  String _mesAno(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    final mes = d.month.toString().padLeft(2, '0');
    return '$mes/${d.year}';
  }
}
