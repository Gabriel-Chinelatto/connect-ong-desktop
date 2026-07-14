import 'package:flutter/material.dart';

import '../../services/assistente_dev_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

/// Chat "Sobre o Desenvolvimento" (painel da ONG): um assistente que explica
/// COMO o Connect ONG foi construido (tecnologias, metodos, decisoes, historico
/// de versoes). Consome `POST /assistente-dev` — IA ancorada num documento
/// curado do projeto, com fallback por regras. Conversa leve de consulta (sem
/// persistencia), com layout centralizado para a tela larga do desktop.
class DesenvolvimentoChatScreen extends StatefulWidget {
  const DesenvolvimentoChatScreen({super.key});

  @override
  State<DesenvolvimentoChatScreen> createState() =>
      _DesenvolvimentoChatScreenState();
}

enum _Papel { usuario, assistente, erro }

class _Msg {
  final _Papel papel;
  final String texto;
  final bool modoRegras;
  const _Msg(this.papel, this.texto, {this.modoRegras = false});
}

class _DesenvolvimentoChatScreenState extends State<DesenvolvimentoChatScreen> {
  static const Color _border = Color(0xFFE2E8F0);
  static const Color _muted = Color(0xFFF1F5F9);

  final AssistenteDevService _service = AssistenteDevService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<_Msg> _msgs = [];
  bool _carregando = false;

  static const List<String> _chips = [
    'Qual é a stack do projeto?',
    'Por que a web é em HTML puro?',
    'Quando a IA foi adicionada?',
    'Quais recursos são exclusivos da web?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _enviar([String? texto]) async {
    final msg = (texto ?? _controller.text).trim();
    if (msg.isEmpty || _carregando) return;
    _controller.clear();

    // Histórico = trocas ANTERIORES (a pergunta atual vai como 'mensagem').
    final historico = _msgs
        .where((m) => m.papel != _Papel.erro)
        .map((m) => {
              'papel': m.papel == _Papel.usuario ? 'user' : 'assistente',
              'texto': m.texto,
            })
        .toList();
    final recorte = historico.length > 8
        ? historico.sublist(historico.length - 8)
        : historico;

    setState(() {
      _msgs.add(_Msg(_Papel.usuario, msg));
      _carregando = true;
    });
    _rolarAoFim();

    try {
      final resp = await _service.perguntar(mensagem: msg, historico: recorte);
      if (!mounted) return;
      final texto = resp.resposta.trim().isEmpty
          ? 'Não consegui responder agora.'
          : resp.resposta.trim();
      setState(() {
        _msgs.add(_Msg(_Papel.assistente, texto, modoRegras: resp.modoRegras));
        _carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _msgs.add(
            _Msg(_Papel.erro, e.toString().replaceFirst('Exception: ', '')));
        _carregando = false;
      });
    }
    _rolarAoFim();
  }

  void _rolarAoFim() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Sobre o Desenvolvimento'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  controller: _scroll,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    _bolhaBoas(),
                    if (_msgs.isEmpty) _chipsIniciais(),
                    for (final m in _msgs) _bolha(m),
                    if (_carregando) _digitando(),
                  ],
                ),
              ),
              _campoEnvio(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bolhaBoas() {
    return _balao(
      alinhado: Alignment.centerLeft,
      cor: AppColors.surface,
      corTexto: AppColors.textPrimary,
      comBorda: true,
      filho: const Text(
        'Oi! 👋 Posso explicar como o Connect ONG foi desenvolvido: tecnologias, '
        'métodos, decisões e o histórico de versões. O que você quer saber?',
        style: TextStyle(height: 1.35),
      ),
    );
  }

  Widget _chipsIniciais() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          for (final c in _chips)
            ActionChip(
              label: Text(c),
              onPressed: () => _enviar(c),
              backgroundColor: AppColors.surface,
              labelStyle: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13),
              side: const BorderSide(color: _border),
              shape: const StadiumBorder(),
            ),
        ],
      ),
    );
  }

  Widget _bolha(_Msg m) {
    if (m.papel == _Papel.usuario) {
      return _balao(
        alinhado: Alignment.centerRight,
        cor: AppColors.primary,
        corTexto: Colors.white,
        filho: Text(m.texto, style: const TextStyle(height: 1.35)),
      );
    }
    if (m.papel == _Papel.erro) {
      return _balao(
        alinhado: Alignment.centerLeft,
        cor: const Color(0xFFFDECEA),
        corTexto: AppColors.error,
        filho: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 18, color: AppColors.error),
            const SizedBox(width: AppSpacing.xs),
            Flexible(child: Text(m.texto)),
          ],
        ),
      );
    }
    return _balao(
      alinhado: Alignment.centerLeft,
      cor: AppColors.surface,
      corTexto: AppColors.textPrimary,
      comBorda: true,
      filho: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(m.texto, style: const TextStyle(height: 1.4)),
          if (m.modoRegras)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _muted,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text('Modo básico',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _digitando() {
    return _balao(
      alinhado: Alignment.centerLeft,
      cor: AppColors.surface,
      corTexto: AppColors.textSecondary,
      comBorda: true,
      filho: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: AppSpacing.sm),
          Text('Pensando…'),
        ],
      ),
    );
  }

  Widget _balao({
    required Alignment alinhado,
    required Color cor,
    required Color corTexto,
    required Widget filho,
    bool comBorda = false,
  }) {
    final ehDireita = alinhado == Alignment.centerRight;
    return Align(
      alignment: alinhado,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        decoration: BoxDecoration(
          color: cor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppRadius.lg),
            topRight: const Radius.circular(AppRadius.lg),
            bottomLeft: Radius.circular(ehDireita ? AppRadius.lg : AppRadius.sm),
            bottomRight:
                Radius.circular(ehDireita ? AppRadius.sm : AppRadius.lg),
          ),
          border: comBorda ? Border.all(color: _border) : null,
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(color: corTexto, fontSize: 14),
          child: filho,
        ),
      ),
    );
  }

  Widget _campoEnvio() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _enviar(),
              decoration: InputDecoration(
                hintText: 'Pergunte sobre o desenvolvimento do projeto…',
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _carregando ? null : () => _enviar(),
              child: const Padding(
                padding: EdgeInsets.all(AppSpacing.sm + 3),
                child:
                    Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
