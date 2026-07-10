import 'package:flutter/material.dart';

import '../../config/config_controller.dart';
import '../../models/notificacao.dart';
import '../../services/api_service.dart';
import '../../services/notificacao_service.dart';
import '../../theme/app_colors.dart';

/// Lista de notificacoes do usuario da ONG.
///
/// Mostra os avisos (novos interesses, mensagens, etc.) e marca todas como
/// lidas ao abrir, zerando o contador do sino no painel.
class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen> {
  final NotificacaoService _service = NotificacaoService();

  List<Notificacao> _itens = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final id = ConfigController.instance.usuarioId;
    if (id == null) {
      setState(() => _carregando = false);
      return;
    }
    setState(() => _carregando = true);
    try {
      final lista = await _service.listar(id);
      if (!mounted) return;
      setState(() {
        _itens = lista;
        _carregando = false;
      });
    } catch (e) {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _marcarTodas() async {
    final id = ConfigController.instance.usuarioId;
    if (id == null) return;
    try {
      await _service.marcarTodas(id);
      _carregar();
    } catch (e) {
      // Antes a falha de rede subia como excecao nao tratada (sem feedback).
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiService.mensagemAmigavel(e))),
      );
    }
  }

  // Clicar numa notificacao marca SO ela como lida (otimista + backend).
  Future<void> _marcarUma(Notificacao n) async {
    if (n.lida) return;
    setState(() {
      final idx = _itens.indexWhere((x) => x.id == n.id);
      if (idx >= 0) _itens[idx] = _itens[idx].copyWith(lida: true);
    });
    try {
      await _service.marcarLida(n.id);
    } catch (_) {
      // rede instavel: o estado local ja mudou; recarrega no proximo refresh.
    }
  }

  IconData _icone(String tipo) {
    switch (tipo) {
      case 'MENSAGEM':
        return Icons.chat_bubble_outline;
      case 'PRESTACAO':
        return Icons.receipt_long;
      case 'MATCH':
        return Icons.handshake;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificações'),
        actions: [
          if (_itens.any((n) => !n.lida))
            TextButton(
              onPressed: _marcarTodas,
              child: const Text('Marcar todas'),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: _carregando
              ? const Center(child: CircularProgressIndicator())
              : _itens.isEmpty
                  ? Center(
                      child: Text('Nenhuma notificação ainda.',
                          style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    )
                  : ListView.separated(
                      itemCount: _itens.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final n = _itens[i];
                        return Container(
                          color: n.lida
                              ? null
                              : AppColors.primary.withValues(alpha: 0.06),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.12),
                              child: Icon(_icone(n.tipo),
                                  color: AppColors.primary),
                            ),
                            title: Text(n.titulo,
                                style: TextStyle(
                                    fontWeight: n.lida
                                        ? FontWeight.normal
                                        : FontWeight.bold)),
                            subtitle: Text(n.mensagem),
                            trailing: n.lida
                                ? null
                                : const Icon(Icons.circle,
                                    size: 10, color: AppColors.primary),
                            onTap: n.lida ? null : () => _marcarUma(n),
                          ),
                        );
                      },
                    ),
        ),
      ),
    );
  }
}
