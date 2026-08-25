import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/geocoding_service.dart';
import '../../services/ong_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/estado_cidade.dart';
import '../../utils/imagens.dart';
import '../../widgets/campo_endereco_autocomplete.dart';
import '../../widgets/confirmar_saida.dart';
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
  final GeocodingService _geo = GeocodingService();

  final _nome = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController();
  final _descricao = TextEditingController();
  final _endereco = TextEditingController();

  // Coordenadas do endereco escolhido no autocomplete de mapa (null = ainda
  // nao confirmado no mapa). Chave para o pino exato no web e no Maps.
  double? _lat;
  double? _lng;

  String _email = '';

  /// UF escolhida no dropdown. O backend guarda "Cidade - UF" no campo único
  /// `cidade`; na carga fazemos o parse de volta (separarCidadeUf).
  String? _uf;

  // Logo / foto de perfil (base64 + bytes p/ preview). Vazio = sem logo, e o
  // cabecalho volta a mostrar a inicial do nome.
  String _logoBase64 = '';
  Uint8List? _logoBytes;
  bool _logoAlterado = false;

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

  /// Retrato dos campos como estavam na última carga/salvamento. Serve para
  /// saber se há alteração pendente e avisar antes de sair da tela.
  String _retratoSalvo = '';

  String _retratoAtual() => [
        _nome.text,
        _telefone.text,
        _cidade.text,
        _uf ?? '',
        _descricao.text,
        _endereco.text,
      ].join('');

  bool get _temMudanca =>
      !_carregando &&
      (_retratoAtual() != _retratoSalvo ||
          _logoAlterado ||
          _capaAlterada ||
          _fotosAlteradas);
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
        _lat = ong.latitude;
        _lng = ong.longitude;
        _logoBase64 = ong.logoBase64 ?? '';
        _logoBytes = _decodificar(_logoBase64);
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
        _logoAlterado = false;
        _capaAlterada = false;
        _fotosAlteradas = false;
        _carregando = false;
      });
      _retratoSalvo = _retratoAtual();
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
      // O painel grava base64 puro; o script que ilustra a demonstracao grava
      // data-URI ("data:image/png;base64,..."). Aceitamos os dois — antes, um
      // data-URI estourava aqui e a imagem simplesmente nao aparecia.
      final i = base64.indexOf(',');
      final limpo =
          base64.startsWith('data:') && i > 0 ? base64.substring(i + 1) : base64;
      return base64Decode(limpo);
    } catch (_) {
      return null;
    }
  }

  Future<void> _escolherLogo() async {
    if (_escolhendoArquivo) return;
    _escolhendoArquivo = true;
    try {
      // Logo e pequeno e quadrado: 512px ja sobra para o circulo do cabecalho.
      final img = await escolherImagem(larguraMax: 512);
      if (img != null && mounted) {
        setState(() {
          _logoBase64 = img.base64;
          _logoBytes = img.bytes;
          _logoAlterado = true;
        });
      }
    } catch (e) {
      if (mounted) AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      _escolhendoArquivo = false;
    }
  }

  void _removerLogo() {
    setState(() {
      _logoBase64 = '';
      _logoBytes = null;
      _logoAlterado = true;
    });
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

  Future<bool> _salvar() async {
    if (_nome.text.trim().isEmpty) {
      AppSnackbar.erro(context, 'O nome da ONG não pode ficar vazio.');
      return false;
    }
    if (_salvando) return false;
    setState(() => _salvando = true);

    final endereco = _endereco.text.trim();
    // VALIDAÇÃO: se a ONG digitou um endereço mas não escolheu no mapa (sem
    // coordenada), tentamos resolver o texto no geocoder. Se achar, marcamos o
    // local; se não achar, avisamos (mas deixamos salvar — o texto ainda vale).
    if (endereco.isNotEmpty && (_lat == null || _lng == null)) {
      try {
        final r = await _geo.buscar(endereco,
            cidade: _cidade.text, uf: _uf);
        if (r.isNotEmpty) {
          _lat = r.first.lat;
          _lng = r.first.lng;
        }
      } catch (_) {
        // Sem internet/geocoder: segue salvando só o texto.
      }
      if (mounted && _lat == null && endereco.length >= 4) {
        AppSnackbar.aviso(
          context,
          'Endereço não localizado no mapa — o pino pode ficar impreciso. '
          'Dica: escolha uma sugestão da lista.',
        );
      }
    }

    try {
      await _service.atualizar(
        id: widget.ongId,
        nome: _nome.text.trim(),
        email: _email,
        telefone: _telefone.text.trim(),
        cidade: formatarCidadeUf(_cidade.text, _uf),
        descricao: _descricao.text.trim(),
        // Endereco sempre vai (texto editavel direto); capa/fotos so se mexeu.
        endereco: endereco,
        latitude: _lat,
        longitude: _lng,
        logoBase64: _logoAlterado ? _logoBase64 : null,
        capaBase64: _capaAlterada ? _capaBase64 : null,
        fotosLocal: _fotosAlteradas ? List.of(_fotosBase64) : null,
      );
      if (!mounted) return false;
      setState(() {
        _salvando = false;
        _logoAlterado = false;
        _capaAlterada = false;
        _fotosAlteradas = false;
      });
      // Novo ponto de referência: a partir daqui não há mais pendência.
      _retratoSalvo = _retratoAtual();
      AppSnackbar.sucesso(context, 'Perfil da ONG atualizado! 💚');
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _salvando = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GuardaDeSaida(
      temMudanca: _temMudanca,
      aoSalvar: _salvar,
      child: _conteudo(context),
    );
  }

  Widget _conteudo(BuildContext context) {
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
                        _secaoLogo(),
                        const SizedBox(height: AppSpacing.lg),
                        _secaoCapa(),
                        const SizedBox(height: AppSpacing.lg),
                        // Limites iguais aos do backend (OngUpdateDTO).
                        _campo(_nome, 'Nome da ONG', maxLength: 100),
                        _campo(_telefone, 'Telefone', maxLength: 20),
                        // Estado antes da cidade: a UF filtra o autocomplete
                        // (mesmo padrão do app mobile).
                        SeletorEstadoCidade(
                          uf: _uf,
                          cidadeController: _cidade,
                          onUfChanged: (v) => setState(() => _uf = v),
                          habilitado: !_salvando,
                        ),
                        _campo(_descricao, 'Descrição (o que a ONG faz)',
                            linhas: 3, maxLength: 1000),
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
                        CampoEnderecoAutocomplete(
                          controller: _endereco,
                          enabled: !_salvando,
                          latInicial: _lat,
                          lngInicial: _lng,
                          // Ancora a busca na localidade já informada acima.
                          cidade: _cidade.text,
                          uf: _uf,
                          onCoordenadas: (lat, lng) {
                            _lat = lat;
                            _lng = lng;
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
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

  /// Campo de texto do formulário.
  ///
  /// [maxLength] espelha o limite que o BACKEND valida (ver OngUpdateDTO).
  /// Sem ele, a ONG escrevia uma descrição longa e só descobria o problema ao
  /// salvar, com um erro genérico — agora o próprio campo impede e mostra o
  /// contador quando está chegando perto do limite.
  Widget _campo(TextEditingController c, String label,
      {int linhas = 1, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        maxLines: linhas,
        maxLength: maxLength,
        buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) =>
            (maxLength != null && currentLength > maxLength * 0.8)
                ? Text('$currentLength/$maxLength',
                    style: Theme.of(context).textTheme.bodySmall)
                : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  // ---- Logo / foto de perfil (quadrado, mostrado em circulo) ----
  Widget _secaoLogo() {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Logo da ONG',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'Imagem quadrada (ex.: 512x512). Aparece em círculo no topo do seu '
          'perfil e ao lado do nome nas listas. Sem logo, mostramos a inicial.',
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            InkWell(
              onTap: _salvando ? null : _escolherLogo,
              customBorder: const CircleBorder(),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: cs.surfaceContainerHighest,
                  border: Border.all(color: cs.outlineVariant, width: 1.4),
                  image: _logoBytes != null
                      ? DecorationImage(
                          image: MemoryImage(_logoBytes!), fit: BoxFit.cover)
                      : null,
                ),
                child: _logoBytes != null
                    ? null
                    : Icon(Icons.add_a_photo_outlined,
                        color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            TextButton.icon(
              onPressed: _salvando ? null : _escolherLogo,
              icon: const Icon(Icons.upload_outlined, size: 18),
              label: Text(_logoBytes == null ? 'Escolher logo' : 'Trocar logo'),
            ),
            if (_logoBytes != null)
              TextButton.icon(
                onPressed: _salvando ? null : _removerLogo,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Remover'),
              ),
          ],
        ),
      ],
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
