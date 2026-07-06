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
                initialValue: widget.uf,
                decoration: const InputDecoration(labelText: 'UF'),
                items: [
                  for (final uf in ufsBrasil)
                    DropdownMenuItem(value: uf, child: Text(uf)),
                ],
                onChanged: widget.habilitado
                    ? (v) {
                        if (v == widget.uf) return;
                        // Trocou de UF: a cidade anterior deixa de valer.
                        widget.cidadeController.clear();
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
