import 'package:flutter/material.dart';

import '../config/config_controller.dart';
import '../screens/ong/notificacoes_screen.dart';
import '../services/notificacao_service.dart';

/// Sino de notificacoes com contador de nao-lidas (desktop).
class NotificacaoBell extends StatefulWidget {
  const NotificacaoBell({super.key});

  @override
  State<NotificacaoBell> createState() => _NotificacaoBellState();
}

class _NotificacaoBellState extends State<NotificacaoBell> {
  final NotificacaoService _service = NotificacaoService();
  int _naoLidas = 0;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  Future<void> _atualizar() async {
    final id = ConfigController.instance.usuarioId;
    if (id == null) return;
    try {
      final n = await _service.contarNaoLidas(id);
      if (mounted) setState(() => _naoLidas = n);
    } catch (_) {}
  }

  Future<void> _abrir() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificacoesScreen()),
    );
    _atualizar();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notificações',
          icon: const Icon(Icons.notifications_outlined),
          onPressed: _abrir,
        ),
        if (_naoLidas > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                _naoLidas > 9 ? '9+' : '$_naoLidas',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
