import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/mensagem.dart';
import '../../services/mensagem_service.dart';

const Color _verde = Color(0xFF2E7D32);

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

  @override
  void initState() {
    super.initState();
    _carregar(primeira: true);
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _carregar(),
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
      _controller.clear();
      await _carregar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _bolha(Mensagem m) {
    final minha = m.remetente == _meuRemetente;
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: minha ? _verde : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(minha ? 16 : 4),
            bottomRight: Radius.circular(minha ? 4 : 16),
          ),
        ),
        child: Text(
          m.conteudo,
          style: TextStyle(
            color: minha ? Colors.white : Colors.black87,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Conversa — ${widget.titulo}')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Expanded(
                child: _carregando
                    ? const Center(child: CircularProgressIndicator())
                    : _mensagens.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhuma mensagem ainda.\nDiga olá ao doador! 👋',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 16),
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
                        onSubmitted: (_) => _enviar(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: _verde,
                      child: IconButton(
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
