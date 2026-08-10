import 'dart:async';

import 'package:flutter/material.dart';

import '../services/geocoding_service.dart';

/// Campo de endereço com autocomplete de mapa (Nominatim/OpenStreetMap).
///
/// Conforme a ONG digita, sugere endereços REAIS (com debounce, respeitando o
/// limite do serviço gratuito). Ao escolher uma sugestão, o campo é preenchido
/// e captura-se latitude/longitude — garantindo que o endereço existe (evita
/// rua inexistente/nome errado) e permitindo que o mapa do web e o link do
/// Google Maps apontem o LOCAL EXATO da ONG.
///
/// Editar o texto à mão invalida a coordenada anterior (via [onCoordenadas] com
/// null), até a ONG escolher outra sugestão.
class CampoEnderecoAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final double? latInicial;
  final double? lngInicial;
  final void Function(double? lat, double? lng) onCoordenadas;

  /// Cidade e UF já escolhidas no formulário. Ancoram a busca na localidade da
  /// ONG (digitar "cotil" procura em Limeira/SP, e não no Brasil inteiro).
  final String? cidade;
  final String? uf;

  const CampoEnderecoAutocomplete({
    super.key,
    required this.controller,
    required this.onCoordenadas,
    this.enabled = true,
    this.latInicial,
    this.lngInicial,
    this.cidade,
    this.uf,
  });

  @override
  State<CampoEnderecoAutocomplete> createState() =>
      _CampoEnderecoAutocompleteState();
}

class _CampoEnderecoAutocompleteState extends State<CampoEnderecoAutocomplete> {
  final _geo = GeocodingService();
  final _focus = FocusNode();
  final _link = LayerLink();

  OverlayEntry? _overlay;
  Timer? _debounce;
  List<EnderecoSugestao> _sugestoes = const [];
  bool _carregando = false;
  bool _semResultado = false;
  bool _temCoord = false;
  String _ultimaBusca = '';

  @override
  void initState() {
    super.initState();
    _temCoord = widget.latInicial != null && widget.lngInicial != null;
    _focus.addListener(() {
      if (!_focus.hasFocus) _fecharOverlay();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _removerOverlay();
    _focus.dispose();
    super.dispose();
  }

  void _aoDigitar(String texto) {
    // Editou o texto à mão => a coordenada anterior não vale mais.
    if (_temCoord) {
      _temCoord = false;
      widget.onCoordenadas(null, null);
    }
    _debounce?.cancel();
    final q = texto.trim();
    if (q.length < 4) {
      _atualizar(const [], carregando: false, semResultado: false);
      return;
    }
    setState(() {}); // atualiza o ícone do sufixo
    _debounce = Timer(const Duration(milliseconds: 550), () => _buscar(q));
  }

  Future<void> _buscar(String q) async {
    if (q == _ultimaBusca && _sugestoes.isNotEmpty) return;
    _ultimaBusca = q;
    _atualizar(_sugestoes, carregando: true, semResultado: false);
    try {
      final res =
          await _geo.buscar(q, cidade: widget.cidade, uf: widget.uf);
      if (!mounted) return;
      _atualizar(res, carregando: false, semResultado: res.isEmpty);
    } catch (_) {
      if (!mounted) return;
      _atualizar(const [], carregando: false, semResultado: true);
    }
  }

  void _atualizar(List<EnderecoSugestao> s,
      {required bool carregando, required bool semResultado}) {
    setState(() {
      _sugestoes = s;
      _carregando = carregando;
      _semResultado = semResultado;
    });
    if (_focus.hasFocus && (s.isNotEmpty || carregando || semResultado)) {
      _mostrarOverlay();
    } else {
      _fecharOverlay();
    }
  }

  void _escolher(EnderecoSugestao s) {
    // Guarda contra escolha repetida (o mesmo toque pode chegar por mais de um
    // caminho de evento).
    if (_temCoord && widget.controller.text == s.descricao) return;
    widget.controller.text = s.descricao;
    widget.controller.selection =
        TextSelection.collapsed(offset: s.descricao.length);
    _temCoord = true;
    widget.onCoordenadas(s.lat, s.lng);
    _fecharOverlay();
    _focus.unfocus();
    setState(() {});
  }

  // ---- Overlay (lista de sugestões flutuando abaixo do campo) ----
  void _mostrarOverlay() {
    if (_overlay == null) {
      _overlay = _criarOverlay();
      Overlay.of(context).insert(_overlay!);
    } else {
      _overlay!.markNeedsBuild();
    }
  }

  void _fecharOverlay() {
    _removerOverlay();
    if (mounted) setState(() {});
  }

  void _removerOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  OverlayEntry _criarOverlay() {
    // Largura do próprio campo (o Column ocupa a largura disponível), lida do
    // contexto do WIDGET — não do contexto do Overlay (que seria a tela toda).
    final larguraCampo =
        (context.findRenderObject() as RenderBox?)?.size.width ?? 320.0;
    return OverlayEntry(
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return Positioned(
          width: larguraCampo,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            offset: const Offset(0, 56),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: _conteudoOverlay(cs),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _conteudoOverlay(ColorScheme cs) {
    if (_carregando) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Row(children: [
          SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Procurando endereços…'),
        ]),
      );
    }
    if (_semResultado) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(Icons.search_off, color: cs.onSurfaceVariant, size: 20),
          const SizedBox(width: 10),
          const Expanded(
              child: Text('Nenhum endereço encontrado. Tente detalhar mais.')),
        ]),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _sugestoes.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final s = _sugestoes[i];
        // Listener/onPointerDown em vez de onTap: ao tocar na sugestão o campo
        // perde o foco PRIMEIRO, o ouvinte de foco fechava a lista e o toque
        // morria junto — a pessoa clicava e nada acontecia, ficando só o texto
        // digitado. O evento de "pressionou" chega antes da troca de foco.
        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => _escolher(s),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined, size: 20),
            title: Text(s.descricao,
                maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(s.descricaoCompleta,
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final vazio = widget.controller.text.trim().isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CompositedTransformTarget(
          link: _link,
          child: TextField(
            controller: widget.controller,
            focusNode: _focus,
            enabled: widget.enabled,
            onChanged: _aoDigitar,
            decoration: InputDecoration(
              labelText: 'Endereço (comece a digitar e escolha no mapa)',
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: vazio
                  ? null
                  : (_temCoord
                      ? Icon(Icons.check_circle, color: cs.primary)
                      : (_carregando
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)))
                          : null)),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: Text(
            _temCoord
                ? '✓ Local confirmado no mapa — o Maps e o mapinha vão apontar aqui.'
                : 'Escolha uma sugestão para marcar o local exato no mapa.',
            style: TextStyle(
              fontSize: 12,
              color: _temCoord ? cs.primary : cs.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
