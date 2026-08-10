import 'package:flutter/material.dart';

import '../utils/estado_cidade.dart';

/// Seleção de Estado (UF) e Cidade, consistente com o app mobile.
///
/// Dropdown com as 27 UFs (alfabético) e autocomplete de cidade filtrado pela
/// UF escolhida, usando o asset offline do IBGE (municipios_por_uf.json).
/// Se o asset falhar ou a UF não estiver escolhida, o campo de cidade degrada
/// para texto livre — nunca bloqueia o usuário.
///
/// O texto da cidade vive no [cidadeController] do chamador; a UF é controlada
/// pelo par [uf]/[onUfChanged] (widget controlado).
class SeletorEstadoCidade extends StatefulWidget {
  final String? uf;
  final TextEditingController cidadeController;
  final ValueChanged<String?> onUfChanged;
  final bool habilitado;

  const SeletorEstadoCidade({
    super.key,
    required this.uf,
    required this.cidadeController,
    required this.onUfChanged,
    this.habilitado = true,
  });

  @override
  State<SeletorEstadoCidade> createState() => _SeletorEstadoCidadeState();
}

class _SeletorEstadoCidadeState extends State<SeletorEstadoCidade> {
  final FocusNode _cidadeFocus = FocusNode();
  Map<String, List<String>> _municipios = const {};

  @override
  void initState() {
    super.initState();
    _carregarMunicipios();
  }

  Future<void> _carregarMunicipios() async {
    final mapa = await Municipios.carregar();
    if (!mounted) return;
    setState(() => _municipios = mapa);
    _inferirUfDaCidadeSalva();
  }

  /// Cadastros antigos guardavam só o nome da cidade (ex.: "Limeira"), sem a
  /// UF — o dropdown abria vazio mesmo com a cidade preenchida, parecendo um
  /// dado perdido. Quando o nome existe em um único estado, preenchemos a UF
  /// sozinhos; havendo cidades homônimas, deixamos em branco de propósito.
  void _inferirUfDaCidadeSalva() {
    if (widget.uf != null) return;
    final cidade = widget.cidadeController.text.trim();
    if (cidade.isEmpty) return;
    final uf = ufDaCidade(cidade, _municipios);
    if (uf != null) widget.onUfChanged(uf);
  }

  @override
  void dispose() {
    _cidadeFocus.dispose();
    super.dispose();
  }

  List<String> _cidadesDaUf() =>
      widget.uf == null ? const [] : (_municipios[widget.uf] ?? const []);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado ANTES da cidade: a UF filtra o autocomplete.
          SizedBox(
            width: 110,
            child: Tooltip(
              message: 'Estado (UF) da sua ONG',
              child: DropdownButtonFormField<String>(
                // A chave força o dropdown a refletir uma UF definida DE FORA
                // (ex.: inferida da cidade já salva) — `initialValue` sozinho
                // só vale na primeira construção.
                key: ValueKey(widget.uf),
                initialValue: widget.uf,
                decoration: const InputDecoration(labelText: 'UF'),
                items: [
                  for (final uf in ufsBrasil)
                    DropdownMenuItem(value: uf, child: Text(uf)),
                ],
                onChanged: widget.habilitado
                    ? (v) {
                        if (v == widget.uf) return;
                        // Só apaga a cidade se ela NÃO existir no novo estado.
                        // Antes limpava sempre, e quem só queria corrigir a UF
                        // de um cadastro antigo perdia a cidade digitada.
                        final cidade = widget.cidadeController.text;
                        if (!cidadePertenceAUf(cidade, v, _municipios)) {
                          widget.cidadeController.clear();
                        }
                        widget.onUfChanged(v);
                        setState(() {});
                      }
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RawAutocomplete<String>(
              textEditingController: widget.cidadeController,
              focusNode: _cidadeFocus,
              optionsBuilder: (TextEditingValue valor) {
                final cidades = _cidadesDaUf();
                if (cidades.isEmpty) return const Iterable<String>.empty();
                final busca = semAcento(valor.text.trim()).toLowerCase();
                final filtro = busca.isEmpty
                    ? cidades
                    : cidades
                        .where((c) =>
                            semAcento(c).toLowerCase().contains(busca))
                        .toList();
                // Limita as opções para a lista não ficar gigante.
                return filtro.take(50);
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: widget.habilitado,
                  decoration: InputDecoration(
                    labelText: 'Cidade',
                    hintText: widget.uf == null && _municipios.isNotEmpty
                        ? 'Escolha o estado primeiro'
                        : null,
                  ),
                  onFieldSubmitted: (_) => onFieldSubmitted(),
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(10),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxHeight: 240, maxWidth: 340),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, i) {
                          final opcao = options.elementAt(i);
                          return InkWell(
                            onTap: () => onSelected(opcao),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Text(opcao),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
