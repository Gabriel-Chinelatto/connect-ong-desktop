import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/ong_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/estado_cidade.dart';
import '../../utils/imagens.dart';
import '../../widgets/seletor_estado_cidade.dart';
import '../../widgets/visualizador_imagem.dart';
import '../../widgets/feedback/app_snackbar.dart';
import '../../widgets/feedback/empty_state.dart';
import 'sobre_com_ia_dialog.dart';

/// Edicao do perfil PUBLICO da ONG: dados basicos + capa, endereco completo
/// e fotos do local (ate 5). Tudo salvo via PUT /ongs/{id}.
///
/// Contrato importante do backend: nome/email/telefone/cidade/descricao sao
/// sobrescritos SEMPRE (por isso a tela carrega os atuais e reenvia todos);
/// capaBase64/endereco/fotosLocal so sao enviados quando o usuario mexeu
/// neles (null = backend nao altera; fotosLocal presente SUBSTITUI todas).
class EditarOngScreen extends StatefulWidget {
  final int ongId;

  const EditarOngScreen({super.key, required this.ongId});

  @override
  State<EditarOngScreen> createState() => _EditarOngScreenState();
}

class _EditarOngScreenState extends State<EditarOngScreen> {
  final OngService _service = OngService();

  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController();
  final _descricao = TextEditingController();
  final _endereco = TextEditingController();

  String _email = '';

  /// UF escolhida no dropdown. O backend guarda "Cidade - UF" no campo único
  /// `cidade`; na carga fazemos o parse de volta (separarCidadeUf).
  String? _uf;

  // Capa (base64 + bytes p/ preview). Vazio = sem capa.
  String _capaBase64 = '';
  Uint8List? _capaBytes;
  bool _capaAlterada = false;

  // Fotos do local (pares base64/bytes na mesma ordem).
  final List<String> _fotosBase64 = [];
  final List<Uint8List> _fotosBytes = [];
  bool _fotosAlteradas = false;
  static const int _maxFotos = 5;

  bool _carregando = true;
  bool _erro = false;
  bool _salvando = false;
  bool _escolhendoArquivo = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nome.dispose();
    _telefone.dispose();
    _cidade.dispose();
    _descricao.dispose();
    _endereco.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final ong = await _service.buscarPorId(widget.ongId);
      if (!mounted) return;
      setState(() {
        _email = ong.email;
        _nome.text = ong.nome;
        _telefone.text = ong.telefone;
        final local = separarCidadeUf(ong.cidade);
        _cidade.text = local.cidade;
        _uf = local.uf;
        _descricao.text = ong.descricao;
        _endereco.text = ong.endereco ?? '';
        _capaBase64 = ong.capaBase64 ?? '';
        _capaBytes = _decodificar(_capaBase64);
        _fotosBase64
          ..clear()
          ..addAll(ong.fotosLocal);
        _fotosBytes
          ..clear()
          ..addAll(ong.fotosLocal
              .map(_decodificar)
              .whereType<Uint8List>());
        // Se alguma foto veio corrompida, mantem as listas alinhadas.
        if (_fotosBytes.length != _fotosBase64.length) {
          _fotosBase64
            ..clear()
            ..addAll(_fotosBytes.map(base64Encode));
        }
        _capaAlterada = false;
        _fotosAlteradas = false;
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

  Uint8List? _decodificar(String base64) {
    if (base64.isEmpty) return null;
    try {
      return base64Decode(base64);
    } catch (_) {
      return null;
    }
  }

  Future<void> _escolherCapa() async {
    if (_escolhendoArquivo) return;
    _escolhendoArquivo = true;
    try {
      // Capa e larga (3:1): permite mais resolucao horizontal.
      final img = await escolherImagem(larguraMax: 1600);
      if (img != null && mounted) {
        setState(() {
          _capaBase64 = img.base64;
          _capaBytes = img.bytes;
          _capaAlterada = true;
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      _escolhendoArquivo = false;
    }
  }

  void _removerCapa() {
    setState(() {
      _capaBase64 = '';
      _capaBytes = null;
      _capaAlterada = true;
    });
  }

  Future<void> _adicionarFotoLocal() async {
    if (_escolhendoArquivo || _fotosBase64.length >= _maxFotos) return;
    _escolhendoArquivo = true;
    try {
      final img = await escolherImagem();
      if (img != null && mounted) {
        setState(() {
          _fotosBase64.add(img.base64);
          _fotosBytes.add(img.bytes);
          _fotosAlteradas = true;
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      _escolhendoArquivo = false;
    }
  }

  Future<void> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      AppSnackbar.erro(context, 'O nome da ONG não pode ficar vazio.');
      return;
    }
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await _service.atualizar(
        id: widget.ongId,
        nome: _nome.text.trim(),
        email: _email,
        telefone: _telefone.text.trim(),
        cidade: formatarCidadeUf(_cidade.text, _uf),
        descricao: _descricao.text.trim(),
        // Endereco sempre vai (texto editavel direto); capa/fotos so se mexeu.
        endereco: _endereco.text.trim(),
        capaBase64: _capaAlterada ? _capaBase64 : null,
        fotosLocal: _fotosAlteradas ? List.of(_fotosBase64) : null,
      );
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _capaAlterada = false;
        _fotosAlteradas = false;
      });
      AppSnackbar.sucesso(context, 'Perfil da ONG atualizado! 💚');
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil da ONG')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? EmptyState(
                  icone: Icons.cloud_off_outlined,
                  mensagem: 'Não foi possível carregar os dados da ONG',
                  detalhe: 'Verifique sua conexão e tente novamente.',
                  acaoRotulo: 'Tentar de novo',
                  onAcao: _carregar,
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: ListView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        _secaoCapa(),
                        const SizedBox(height: AppSpacing.lg),
                        _campo(_nome, 'Nome da ONG'),
                        _campo(_telefone, 'Telefone'),
                        // Estado antes da cidade: a UF filtra o autocomplete
                        // (mesmo padrão do app mobile).
                        SeletorEstadoCidade(
                          uf: _uf,
                          cidadeController: _cidade,
                          onUfChanged: (v) => setState(() => _uf = v),
                          habilitado: !_salvando,
                        ),
                        _campo(_descricao, 'Descrição (o que a ONG faz)',
                            linhas: 3),
                        // Escreve/refina o "Sobre" com IA (loop de ajuste),
                        // ancorado nos dados reais desta ONG.
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed:
                                _salvando ? null : _escreverSobreComIa,
                            icon: const Icon(Icons.auto_awesome, size: 18),
                            label: const Text('Escrever com IA'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _campo(_endereco,
                            'Endereço completo (rua, número, bairro)'),
                        const SizedBox(height: AppSpacing.sm),
                        _secaoFotosLocal(),
                        const SizedBox(height: AppSpacing.lg),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _salvando ? null : _salvar,
                            icon: _salvando
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.save),
                            label: const Text('Salvar'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
    );
  }

  // Abre o diálogo "Sobre com IA" e, se a ONG confirmar, adota o texto no campo
  // de descrição (ainda precisa Salvar para persistir via PUT /ongs/{id}).
  Future<void> _escreverSobreComIa() async {
    final texto = await mostrarSobreComIa(
      context,
      ongId: widget.ongId,
      rascunhoAtual: _descricao.text.trim(),
    );
    if (!mounted || texto == null || texto.isEmpty) return;
    setState(() => _descricao.text = texto);
    AppSnackbar.sucesso(context, 'Sobre atualizado. Não esqueça de Salvar.');
  }

  Widget _campo(TextEditingController c, String label, {int linhas = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        maxLines: linhas,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  // ---- Capa do perfil (faixa 3:1 com preview) ----
  Widget _secaoCapa() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Capa do perfil',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'Recomendado: 1200x400 (3:1), máx 2MB. Aparece atrás do cabeçalho '
          'do seu perfil público.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 3,
          child: _capaBytes != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      onTap: () =>
                          mostrarImagemGrande(context, _capaBytes!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(_capaBytes!,
                            fit: BoxFit.cover, gaplessPlayback: true),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _botaoSobreCapa(
                            tooltip: 'Trocar capa',
                            icone: Icons.edit,
                            onTap: _salvando ? null : _escolherCapa,
                          ),
                          const SizedBox(width: 6),
                          _botaoSobreCapa(
                            tooltip: 'Remover capa',
                            icone: Icons.delete_outline,
                            onTap: _salvando ? null : _removerCapa,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _salvando ? null : _escolherCapa,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: cs.outlineVariant, width: 1.4),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.panorama_outlined,
                            size: 40, color: cs.onSurfaceVariant),
                        const SizedBox(height: 6),
                        Text('Escolher imagem de capa',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _botaoSobreCapa({
    required String tooltip,
    required IconData icone,
    VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            shape: BoxShape.circle,
          ),
          child: Icon(icone, size: 18, color: Colors.white),
        ),
      ),
    );
  }

  // ---- Fotos do local (ate 5, com preview e remover) ----
  Widget _secaoFotosLocal() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos do local (${_fotosBase64.length}/$_maxFotos)',
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'Mostre a sede/espaço da ONG aos doadores. Salvar substitui as '
          'fotos anteriores pelas daqui.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _fotosBytes.length; i++) _miniatura(i),
            if (_fotosBase64.length < _maxFotos)
              Tooltip(
                message: 'Adicionar foto (JPG ou PNG)',
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _salvando ? null : _adicionarFotoLocal,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: cs.outlineVariant, width: 1.4),
                    ),
                    child: Icon(Icons.add_a_photo_outlined,
                        color: cs.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _miniatura(int indice) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () => mostrarImagemGrande(context, _fotosBytes[indice]),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _fotosBytes[indice],
              width: 96,
              height: 96,
              fit: BoxFit.cover,
              gaplessPlayback: true,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Tooltip(
            message: 'Remover foto',
            child: InkWell(
              onTap: _salvando
                  ? null
                  : () => setState(() {
                        _fotosBase64.removeAt(indice);
                        _fotosBytes.removeAt(indice);
                        _fotosAlteradas = true;
                      }),
              child: Container(
                padding: const EdgeInsets.all(3),
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
