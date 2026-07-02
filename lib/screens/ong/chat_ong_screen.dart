import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/mensagem.dart';
import '../../services/mensagem_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';

const Color _verde = AppColors.primary;

// Mapa CODIGO -> emoji (o backend usa codigos, nao o caractere).
const Map<String, String> _emojis = {
  'LIKE': '👍',
  'LOVE': '❤️',
  'LAUGH': '😂',
  'WOW': '😮',
  'SAD': '😢',
  'PRAY': '🙏',
};

// Ordem fixa dos 6 codigos exibidos no seletor de reacao.
const List<String> _emojiCodigos = ['LIKE', 'LOVE', 'LAUGH', 'WOW', 'SAD', 'PRAY'];

/// Tela de chat da ONG com um doador (dentro de um match aceito).
/// Atualiza automaticamente a cada 2 segundos (polling).
class ChatOngScreen extends StatefulWidget {
  final int interesseId;
  final String titulo;

  const ChatOngScreen({
    super.key,
    required this.interesseId,
    required this.titulo,
  });

  @override
  State<ChatOngScreen> createState() => _ChatOngScreenState();
}

class _ChatOngScreenState extends State<ChatOngScreen> {
  final MensagemService _service = MensagemService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  static const String _meuRemetente = 'ONG';

  List<Mensagem> _mensagens = [];
  bool _carregando = true;
  bool _enviando = false;
  Timer? _timer;

  // Presenca do OUTRO participante (atualizada no mesmo tick do polling).
  bool _online = false;
  String? _ultimoVisto;
  bool _digitando = false;

  // Throttle do heartbeat de digitacao (no maximo 1x a cada 2s).
  DateTime? _ultimoHeartbeat;

  @override
  void initState() {
    super.initState();
    _carregar(primeira: true);
    _carregarStatus();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        _carregar();
        _carregarStatus();
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _carregar({bool primeira = false}) async {
    try {
      final lista = await _service.listar(widget.interesseId);
      if (!mounted) return;
      final mudou = lista.length != _mensagens.length;
      setState(() {
        _mensagens = lista;
        _carregando = false;
      });
      if (mudou) _irParaOFim();
    } catch (e) {
      if (!mounted) return;
      if (primeira) setState(() => _carregando = false);
    }
  }

  // Atualiza a presenca do outro participante. Best-effort e silencioso:
  // sem spinner e sem erro visivel; em falha mantem os defaults do service.
  Future<void> _carregarStatus() async {
    final s = await _service.status(widget.interesseId);
    if (!mounted) return;
    setState(() {
      _online = (s['online'] ?? false) as bool;
      _ultimoVisto = s['ultimoVisto'] as String?;
      _digitando = (s['digitando'] ?? false) as bool;
    });
  }

  // Envia o heartbeat de digitacao com throttle de no maximo 1x/2s.
  void _sinalizarDigitando() {
    final agora = DateTime.now();
    if (_ultimoHeartbeat != null &&
        agora.difference(_ultimoHeartbeat!) < const Duration(seconds: 2)) {
      return;
    }
    _ultimoHeartbeat = agora;
    _service.digitando(widget.interesseId);
  }

  // Texto de presenca exibido abaixo do titulo na AppBar.
  String _textoPresenca() {
    if (_digitando) return 'digitando...';
    if (_online) return 'online';
    if (_ultimoVisto != null) {
      final dt = DateTime.parse(_ultimoVisto!).toLocal();
      final hh = dt.hour.toString().padLeft(2, '0');
      final mm = dt.minute.toString().padLeft(2, '0');
      return 'visto por último às $hh:$mm';
    }
    return '';
  }

  void _irParaOFim() {
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

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty) return;
    setState(() => _enviando = true);
    try {
      await _service.enviar(
        interesseId: widget.interesseId,
        remetente: _meuRemetente,
        conteudo: texto,
      );
      // Se o usuario saiu da tela durante o envio, o _controller ja foi
      // descartado no dispose(): mexer nele lancaria "used after disposed".
      if (!mounted) return;
      _controller.clear();
      await _carregar();
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
      if (mounted) setState(() => _enviando = false);
    }
  }

  // Abre o seletor de reacoes (long press na bolha; funciona no desktop).
  // Ao escolher um emoji: fecha, envia a reacao (toggle) e recarrega.
  Future<void> _abrirSeletorReacao(Mensagem m) async {
    final codigo = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in _emojiCodigos)
                InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.of(ctx).pop(c),
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    child: Text(
                      _emojis[c] ?? '',
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (codigo == null) return;
    try {
      await _service.reagir(m.id, codigo);
      await _carregar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.mensagemAmigavel(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _bolha(Mensagem m) {
    final minha = m.remetente == _meuRemetente;
    final cs = Theme.of(context).colorScheme;
    // Ha alguma reacao feita pelo MEU lado? Da destaque sutil ao chip.
    final reagiuMeuLado =
        m.reacoes.any((r) => r.lado == _meuRemetente);
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            minha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onLongPress: () => _abrirSeletorReacao(m),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              margin: const EdgeInsets.only(top: 4, left: 12, right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: minha ? _verde : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(minha ? 16 : 4),
                  bottomRight: Radius.circular(minha ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    m.conteudo,
                    style: TextStyle(
                      color: minha ? Colors.white : cs.onSurface,
                      height: 1.3,
                    ),
                  ),
                  // Check de "visto" apenas nas MINHAS mensagens.
                  if (minha)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Icon(
                          m.lida ? Icons.done_all : Icons.check,
                          size: 14,
                          color: m.lida
                              ? Colors.lightBlueAccent
                              : Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Chip de reacoes abaixo da bolha (nao interfere no check de visto).
          if (m.reacoes.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 2, left: 12, right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: reagiuMeuLado
                    ? _verde.withValues(alpha: 0.15)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: reagiuMeuLado
                    ? Border.all(color: _verde.withValues(alpha: 0.6))
                    : null,
              ),
              child: Text(
                m.reacoes.map((r) => _emojis[r.emoji] ?? '').join(),
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Conversa — ${widget.titulo}'),
            if (_textoPresenca().isNotEmpty)
              Text(
                _textoPresenca(),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _mensagens.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhuma mensagem ainda.\nDiga olá ao doador! 👋',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            itemCount: _mensagens.length,
                            itemBuilder: (context, i) => _bolha(_mensagens[i]),
                          ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Mensagem...',
                        ),
                        onChanged: (texto) {
                          if (texto.isNotEmpty) _sinalizarDigitando();
                        },
                        onSubmitted: (_) => _enviar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _verde,
                      child: IconButton(
                        tooltip: 'Enviar mensagem',
                        icon: _enviando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                        onPressed: _enviando ? null : _enviar,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
