import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/perfil_publico_ong.dart';
import '../../services/perfil_publico_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/app_links.dart';
import '../../widgets/visualizador_imagem.dart';
import '../../widgets/feedback/empty_state.dart';
import 'perfil_publico_doador_screen.dart';

/// Pre-visualizacao de como a ONG aparece publicamente para os doadores
/// (mesmo endpoint usado pelo app do doador).
class PerfilPublicoOngScreen extends StatefulWidget {
  final int ongId;
  final String ongNome;

  const PerfilPublicoOngScreen({
    super.key,
    required this.ongId,
    required this.ongNome,
  });

  @override
  State<PerfilPublicoOngScreen> createState() => _PerfilPublicoOngScreenState();
}

class _PerfilPublicoOngScreenState extends State<PerfilPublicoOngScreen> {
  final PerfilPublicoService _service = PerfilPublicoService();
  PerfilPublicoOng? _perfil;
  Uint8List? _logoBytes;
  Uint8List? _capaBytes;
  List<Uint8List> _fotosLocalBytes = [];
  bool _carregando = true;
  bool _erro = false;

  /// Guarda anti-duplo-clique ao abrir o perfil de um doador (contraparte das
  /// prestações).
  bool _navegando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Uint8List? _decodificar(String? base64) {
    if (base64 == null || base64.isEmpty) return null;
    try {
      // Aceita base64 puro (o que o painel grava) e data-URI (o que o script
      // que ilustra a demonstracao grava).
      final i = base64.indexOf(',');
      final limpo =
          base64.startsWith('data:') && i > 0 ? base64.substring(i + 1) : base64;
      return base64Decode(limpo);
    } catch (_) {
      return null;
    }
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final p = await _service.buscar(widget.ongId);
      if (!mounted) return;
      setState(() {
        _perfil = p;
        _logoBytes = _decodificar(p.logoBase64);
        _capaBytes = _decodificar(p.capaBase64);
        _fotosLocalBytes =
            p.fotosLocal.map(_decodificar).whereType<Uint8List>().toList();
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
        title: Text('Perfil publico — ${widget.ongNome}'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro || _perfil == null
              ? _vazio()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _cabecalho(_perfil!),
                        const SizedBox(height: 16),
                        _stats(_perfil!),
                        const SizedBox(height: 16),
                        _secao('Sobre', Icons.info_outline, [
                          Text(
                            _perfil!.descricao.isNotEmpty
                                ? _perfil!.descricao
                                : 'Sem descricao.',
                            style: const TextStyle(height: 1.5),
                          ),
                        ]),
                        _secao('Contato', Icons.contact_mail_outlined, [
                          _linha(Icons.email_outlined, _perfil!.email),
                          _linha(Icons.phone_outlined, _perfil!.telefone),
                          if (_perfil!.cnpj != null && _perfil!.cnpj!.isNotEmpty)
                            _linha(Icons.badge_outlined,
                                'CNPJ: ${_perfil!.cnpj}'),
                        ]),
                        if (_perfil!.endereco != null &&
                            _perfil!.endereco!.isNotEmpty)
                          _secaoEndereco(_perfil!.endereco!),
                        if (_fotosLocalBytes.isNotEmpty)
                          _secao('Fotos do local', Icons.photo_library_outlined,
                              [_galeriaLocal()]),
                        if (_perfil!.campanhas.isNotEmpty)
                          _secao('Campanhas', Icons.campaign_outlined, [
                            for (final c in _perfil!.campanhas) _campanha(c),
                          ]),
                        if (_perfil!.necessidades.isNotEmpty)
                          _secao('Necessidades', Icons.favorite_outline, [
                            for (final n in _perfil!.necessidades)
                              _necessidade(n),
                          ]),
                        if (_perfil!.prestacoes.isNotEmpty)
                          _secao('Prestacoes de contas',
                              Icons.receipt_long_outlined,
                              _prestacoesAgrupadas(_perfil!.prestacoes)),
                        if (_perfil!.avaliacoes.isNotEmpty)
                          _secao('Avaliacoes', Icons.star_outline, [
                            for (final a in _perfil!.avaliacoes) _avaliacao(a),
                          ]),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _vazio() {
    return EmptyState(
      icone: Icons.cloud_off_outlined,
      mensagem: 'Não foi possível carregar o perfil',
      detalhe: 'Verifique sua conexão e tente novamente.',
      acaoRotulo: 'Tentar de novo',
      onAcao: _carregar,
    );
  }

  Widget _cabecalho(PerfilPublicoOng p) {
    final inicial = p.nome.isNotEmpty ? p.nome[0].toUpperCase() : '?';
    final miolo = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.primary,
            // Com logo, ele preenche o circulo; sem logo, continua a inicial.
            backgroundImage:
                _logoBytes != null ? MemoryImage(_logoBytes!) : null,
            child: _logoBytes != null
                ? null
                : Text(inicial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(p.nome,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                    if (p.verificada) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified,
                          color: AppColors.info, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(p.cidade,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (int i = 0; i < 5; i++)
                      Icon(
                          i < p.notaMedia.round()
                              ? Icons.star
                              : Icons.star_border,
                          size: 18,
                          color: Colors.amber),
                    const SizedBox(width: 8),
                    Text(p.totalAvaliacoes > 0
                        ? '${p.notaMedia.toStringAsFixed(1)} (${p.totalAvaliacoes})'
                        : 'Sem avaliacoes'),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chipTransparencia(p),
                    if (_chipStreak(p) != null) _chipStreak(p)!,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: _capaBytes == null
          ? miolo
          : Column(
              children: [
                // Capa 3:1 com gradiente escuro embaixo para legibilidade do
                // conteudo que vem logo abaixo.
                AspectRatio(
                  aspectRatio: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.memory(_capaBytes!,
                          fit: BoxFit.cover, gaplessPlayback: true),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black54,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                miolo,
              ],
            ),
    );
  }

  /// Chip do streak do ranking: 🔥 "Há N dias em 1º lugar" quando a ONG e o
  /// atual topo; senao "Já ficou N dias em 1º lugar" do ultimo reinado.
  Widget? _chipStreak(PerfilPublicoOng p) {
    final bool atual = p.diasNoTopo != null && p.diasNoTopo! > 0;
    final bool passado =
        !atual && p.ultimoReinadoDias != null && p.ultimoReinadoDias! > 0;
    if (!atual && !passado) return null;

    final int dias = atual ? p.diasNoTopo! : p.ultimoReinadoDias!;
    final String texto = atual
        ? 'Há $dias ${dias == 1 ? "dia" : "dias"} em 1º lugar'
        : 'Já ficou $dias ${dias == 1 ? "dia" : "dias"} em 1º lugar';
    final Color cor = atual ? const Color(0xFFF59E0B) : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(texto,
              style: TextStyle(
                  color: cor, fontWeight: FontWeight.w700, fontSize: 13)),
        ],
      ),
    );
  }

  // Secao de endereco com botao "Abrir no Maps".
  Widget _secaoEndereco(String endereco) {
    return _secao('Endereço', Icons.place_outlined, [
      Text(endereco, style: const TextStyle(height: 1.4)),
      const SizedBox(height: 10),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _abrirNoMaps(endereco),
          icon: const Icon(Icons.map_outlined, size: 18),
          label: const Text('Abrir no Maps'),
        ),
      ),
    ]);
  }

  // Abre o endereco no Google Maps. Quando a ONG confirmou o local no mapa
  // (latitude/longitude), abre na COORDENADA EXATA (mais preciso); senao cai no
  // endereco em texto. No desktop/web o launch pode falhar; o helper degrada
  // copiando o link para a area de transferencia.
  Future<void> _abrirNoMaps(String endereco) async {
    final lat = _perfil?.latitude;
    final lng = _perfil?.longitude;
    final query = (lat != null && lng != null)
        ? '$lat,$lng'
        : Uri.encodeComponent(endereco);
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$query');
    await abrirLinkExterno(context, url);
  }

  // Galeria das fotos do local (miniaturas clicaveis -> visualizacao grande).
  Widget _galeriaLocal() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final bytes in _fotosLocalBytes)
          Tooltip(
            message: 'Ampliar foto',
            child: GestureDetector(
              onTap: () => mostrarImagemGrande(context, bytes),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  bytes,
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chipTransparencia(PerfilPublicoOng p) {
    final cor = _corNivel(p.nivelTransparencia);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium, color: cor, size: 18),
          const SizedBox(width: 6),
          Text(
            'Transparencia: ${_rotuloNivel(p.nivelTransparencia)} '
            '(${p.transparenciaScore})',
            style: TextStyle(
                color: cor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Color _corNivel(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'OURO':
        return const Color(0xFFF59E0B);
      case 'PRATA':
        return const Color(0xFF9CA3AF);
      default:
        return const Color(0xFFCD7F32);
    }
  }

  String _rotuloNivel(String nivel) {
    switch (nivel.toUpperCase()) {
      case 'OURO':
        return 'Ouro';
      case 'PRATA':
        return 'Prata';
      default:
        return 'Bronze';
    }
  }

  Widget _stats(PerfilPublicoOng p) {
    Widget item(IconData icon, int v, String label) => Expanded(
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(height: 4),
              Text('$v',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            item(Icons.favorite_outline, p.totalNecessidades, 'Necessidades'),
            item(Icons.campaign_outlined, p.totalCampanhas, 'Campanhas'),
            item(Icons.receipt_long_outlined, p.totalPrestacoes, 'Prestacoes'),
          ],
        ),
      ),
    );
  }

  Widget _secao(String titulo, IconData icon, List<Widget> filhos) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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

  Widget _linha(IconData icon, String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(texto)),
          ],
        ),
      );

  Widget _campanha(CampanhaResumo c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(c.titulo,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (c.encerrada)
                Text('Encerrada',
                    style: TextStyle(
                        fontSize: 12,
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: c.progresso / 100,
              minHeight: 8,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 4),
          Text(
              'R\$ ${c.valorArrecadado.toStringAsFixed(0)} de '
              'R\$ ${c.metaValor.toStringAsFixed(0)} (${c.progresso}%)',
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _necessidade(NecessidadeResumo n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(n.urgente ? Icons.priority_high : Icons.circle,
              size: n.urgente ? 18 : 8,
              color: n.urgente ? AppColors.error : AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(n.titulo, overflow: TextOverflow.ellipsis)),
          if (n.categoria.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(n.categoria,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }

  Widget _avaliacao(AvaliacaoResumo a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Flexible + ellipsis: nome de doador comprido não empurra as
              // estrelas para fora (evita RenderFlex RIGHT overflow).
              Flexible(
                child: Text(a.doadorNome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 8),
              for (int i = 0; i < 5; i++)
                Icon(i < a.nota ? Icons.star : Icons.star_border,
                    size: 14, color: Colors.amber),
            ],
          ),
          if (a.comentario != null && a.comentario!.isNotEmpty)
            Text(a.comentario!),
        ],
      ),
    );
  }

  /// Agrupa as prestações por doador (contraparte). Cada doador vira um
  /// cabeçalho "para <doador>" clicável (→ perfil do doador), mostrado UMA vez,
  /// com suas prestações abaixo. Prestações sem doador identificado
  /// (doadorId/doadorNome nulos) degradam: aparecem sem cabeçalho/link.
  List<Widget> _prestacoesAgrupadas(List<PrestacaoResumo> lista) {
    final grupos = <String, List<PrestacaoResumo>>{};
    final ordem = <String>[];
    for (final p in lista) {
      final chave = p.doadorId != null
          ? 'id:${p.doadorId}'
          : (p.doadorNome != null && p.doadorNome!.isNotEmpty
              ? 'nome:${p.doadorNome}'
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
      if (chave != '_sem_') widgets.add(_cabecalhoDoador(ref));
      for (final p in itens) {
        widgets.add(_itemPrestacao(p, comRecuo: chave != '_sem_'));
      }
    }
    return widgets;
  }

  /// Cabeçalho "para <doador>": clicável quando há doadorId; senão só texto.
  Widget _cabecalhoDoador(PrestacaoResumo ref) {
    final nome = (ref.doadorNome != null && ref.doadorNome!.isNotEmpty)
        ? ref.doadorNome!
        : 'Doador';
    final cs = Theme.of(context).colorScheme;
    if (ref.doadorId == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(Icons.person_outline, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text('para $nome',
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
        onTap: () => _abrirDoador(ref.doadorId!, nome),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Flexible(
                child: Text('para $nome',
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

  Widget _itemPrestacao(PrestacaoResumo p, {required bool comRecuo}) {
    return Padding(
      padding: EdgeInsets.only(left: comRecuo ? 22 : 0, bottom: 10, top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(p.titulo,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          if (p.descricao.isNotEmpty) Text(p.descricao),
        ],
      ),
    );
  }

  /// Abre o perfil público do doador contraparte (guarda anti-duplo-clique).
  Future<void> _abrirDoador(int doadorId, String doadorNome) async {
    if (_navegando) return;
    _navegando = true;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilPublicoDoadorScreen(
            doadorId: doadorId, doadorNome: doadorNome),
      ),
    );
    if (mounted) _navegando = false;
  }
}
