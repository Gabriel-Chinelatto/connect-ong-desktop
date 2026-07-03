import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/prestacao.dart';
import '../../models/perfil_publico_doador.dart';
import '../../services/api_service.dart';
import '../../services/avaliacao_doador_service.dart';
import '../../services/prestacao_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/imagens.dart';
import '../../widgets/visualizador_imagem.dart';
import '../../widgets/feedback/empty_state.dart';

const Color _verde = AppColors.primary;

// ===========================================================================
// FORMULARIO DE PRESTACAO DE CONTAS RICA (dialog com fotos + valor)
// ===========================================================================
class FormPrestacao extends StatefulWidget {
  final int interesseId;

  const FormPrestacao({super.key, required this.interesseId});

  @override
  State<FormPrestacao> createState() => _FormPrestacaoState();
}

class _FormPrestacaoState extends State<FormPrestacao> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _valor = TextEditingController();

  // Fotos escolhidas (ja comprimidas), com preview e "remover".
  final List<ImagemSelecionada> _fotos = [];
  static const int _maxFotos = 5;

  bool _enviando = false;
  bool _escolhendoFoto = false;

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _valor.dispose();
    super.dispose();
  }

  Future<void> _adicionarFoto() async {
    // Guard anti-duplo-clique do seletor de arquivos.
    if (_escolhendoFoto || _fotos.length >= _maxFotos) return;
    _escolhendoFoto = true;
    try {
      final img = await escolherImagem();
      if (img != null && mounted) {
        setState(() => _fotos.add(img));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ApiService.mensagemAmigavel(e)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _escolhendoFoto = false;
    }
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      final valorTexto = _valor.text.trim().replaceAll(',', '.');
      await PrestacaoService().criar(
        interesseId: widget.interesseId,
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        fotos: [for (final f in _fotos) f.base64],
        valorUtilizado: valorTexto.isEmpty ? null : double.parse(valorTexto),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.mensagemAmigavel(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Prestar contas'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titulo,
                  autofocus: true,
                  maxLength: 150,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                      labelText: 'Título', counterText: ''),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe o título'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricao,
                  maxLines: 3,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                      labelText: 'O que foi feito com a doação',
                      counterText: ''),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Descreva o que foi feito com a doação'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _valor,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Valor utilizado (R\$) — opcional',
                    hintText: 'Ex.: 150,00',
                  ),
                  validator: (v) {
                    final texto = (v ?? '').trim();
                    if (texto.isEmpty) return null; // opcional
                    final n = double.tryParse(texto.replaceAll(',', '.'));
                    if (n == null || n <= 0) {
                      return 'Informe um valor válido (maior que zero)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text('Fotos (${_fotos.length}/$_maxFotos)',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Mostre o que a doação virou: fotos valem mais que texto.',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (int i = 0; i < _fotos.length; i++) _miniaturaFoto(i),
                    if (_fotos.length < _maxFotos)
                      Tooltip(
                        message: 'Adicionar foto (JPG ou PNG)',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: _enviando ? null : _adicionarFoto,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: cs.outlineVariant, width: 1.4),
                            ),
                            child: Icon(Icons.add_a_photo_outlined,
                                color: cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _enviando ? null : _publicar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Publicar'),
        ),
      ],
    );
  }

  Widget _miniaturaFoto(int indice) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => mostrarImagemGrande(context, _fotos[indice].bytes),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _fotos[indice].bytes,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: Tooltip(
            message: 'Remover foto',
            child: InkWell(
              onTap: _enviando
                  ? null
                  : () => setState(() => _fotos.removeAt(indice)),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// LISTA DE PRESTACOES DE UM MATCH (dialog com fotos e valor)
// ===========================================================================
class DialogPrestacoes extends StatefulWidget {
  final int interesseId;
  final String titulo;

  const DialogPrestacoes({
    super.key,
    required this.interesseId,
    required this.titulo,
  });

  @override
  State<DialogPrestacoes> createState() => _DialogPrestacoesState();
}

class _DialogPrestacoesState extends State<DialogPrestacoes> {
  List<Prestacao> _prestacoes = [];
  // Fotos decodificadas uma unica vez (indice da prestacao -> bytes).
  final Map<int, List<Uint8List>> _fotosDecodificadas = {};
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final lista =
          await PrestacaoService().listarPorInteresse(widget.interesseId);
      // Decodifica o base64 uma vez so (decodificar a cada build custaria
      // caro). Fotos invalidas sao ignoradas em silencio.
      _fotosDecodificadas.clear();
      for (int i = 0; i < lista.length; i++) {
        final bytes = <Uint8List>[];
        for (final f in lista[i].fotos) {
          try {
            bytes.add(base64Decode(f));
          } catch (_) {}
        }
        _fotosDecodificadas[i] = bytes;
      }
      if (!mounted) return;
      setState(() {
        _prestacoes = lista;
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _erro = ApiService.mensagemAmigavel(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Prestações — ${widget.titulo}'),
      content: SizedBox(
        width: 520,
        height: 420,
        child: _carregando
            ? const Center(child: CircularProgressIndicator())
            : _erro != null
                ? EmptyState(
                    icone: Icons.cloud_off_outlined,
                    mensagem: 'Não foi possível carregar',
                    detalhe: _erro,
                    acaoRotulo: 'Tentar de novo',
                    onAcao: _carregar,
                  )
                : _prestacoes.isEmpty
                    ? const EmptyState(
                        icone: Icons.receipt_long_outlined,
                        mensagem: 'Nenhuma prestação publicada ainda',
                        detalhe:
                            'Use "Prestar contas" para mostrar ao doador o '
                            'que a doação virou.',
                      )
                    : ListView.builder(
                        itemCount: _prestacoes.length,
                        itemBuilder: (context, i) => _cardPrestacao(i),
                      ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    );
  }

  Widget _cardPrestacao(int indice) {
    final p = _prestacoes[indice];
    final fotos = _fotosDecodificadas[indice] ?? const <Uint8List>[];
    final cs = Theme.of(context).colorScheme;
    String dataCurta() {
      final d = DateTime.tryParse(p.dataCriacao ?? '');
      if (d == null) return '';
      String dois(int n) => n.toString().padLeft(2, '0');
      return '${dois(d.day)}/${dois(d.month)}/${d.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (dataCurta().isNotEmpty)
                  Text(dataCurta(),
                      style:
                          TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
            if (p.descricao.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(p.descricao),
            ],
            if (p.valorUtilizado != null) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _verde.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Valor utilizado: R\$ '
                  '${p.valorUtilizado!.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: const TextStyle(
                      color: _verde, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
            if (fotos.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final bytes in fotos)
                    Tooltip(
                      message: 'Ampliar foto',
                      child: GestureDetector(
                        onTap: () =>
                            mostrarImagemGrande(context, bytes, titulo: p.titulo),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            bytes,
                            width: 84,
                            height: 84,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// AVALIAR O DOADOR (dialog 5 estrelas, estilo Uber; upsert)
// ===========================================================================
class DialogAvaliarDoador extends StatefulWidget {
  final int doadorId;
  final String doadorNome;

  /// Avaliacao ja feita por esta ONG (pre-carrega estrelas/comentario).
  final AvaliacaoDoador? existente;

  const DialogAvaliarDoador({
    super.key,
    required this.doadorId,
    required this.doadorNome,
    this.existente,
  });

  @override
  State<DialogAvaliarDoador> createState() => _DialogAvaliarDoadorState();
}

class _DialogAvaliarDoadorState extends State<DialogAvaliarDoador> {
  late int _nota;
  late final TextEditingController _comentario;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    _nota = widget.existente?.nota ?? 0;
    _comentario =
        TextEditingController(text: widget.existente?.comentario ?? '');
  }

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (_nota < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escolha de 1 a 5 estrelas.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (_enviando) return;
    setState(() => _enviando = true);
    try {
      await AvaliacaoDoadorService().avaliar(
        doadorId: widget.doadorId,
        nota: _nota,
        comentario: _comentario.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.mensagemAmigavel(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  static const List<String> _rotulosNota = [
    '',
    'Muito ruim',
    'Ruim',
    'Ok',
    'Boa',
    'Excelente!',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final editando = widget.existente != null;
    return AlertDialog(
      title: Text(editando
          ? 'Editar avaliação — ${widget.doadorNome}'
          : 'Avaliar ${widget.doadorNome}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Como foi a experiência com este doador?',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 5; i++)
                  IconButton(
                    tooltip: '$i ${i == 1 ? "estrela" : "estrelas"}',
                    iconSize: 36,
                    onPressed:
                        _enviando ? null : () => setState(() => _nota = i),
                    icon: Icon(
                      i <= _nota ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                  ),
              ],
            ),
            SizedBox(
              height: 20,
              child: Text(
                _nota >= 1 ? _rotulosNota[_nota] : '',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _comentario,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Comentário (opcional)',
                hintText: 'Ex.: entrega combinada e pontual, doador atencioso',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _enviando ? null : _enviar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(editando ? 'Salvar' : 'Enviar avaliação'),
        ),
      ],
    );
  }
}
