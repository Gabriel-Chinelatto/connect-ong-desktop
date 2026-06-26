import 'package:flutter/material.dart';

import '../../models/conquista.dart';
import '../../services/conquista_service.dart';
import '../../theme/app_colors.dart';

/// Icone correspondente a cada chave de conquista.
IconData _iconeConquista(String chave) {
  switch (chave) {
    case 'ONG_VERIFICADA':
      return Icons.verified;
    case 'PRIMEIRA_CAMPANHA':
      return Icons.campaign;
    case 'PRIMEIRA_PRESTACAO':
      return Icons.receipt_long;
    case 'PRIMEIRA_AVALIACAO':
      return Icons.star;
    case 'CAMPANHA_CONCLUIDA':
      return Icons.emoji_events;
    default:
      return Icons.emoji_events;
  }
}

/// Tela de conquistas (gamificacao) da ONG, acessivel pelo painel.
class ConquistasScreen extends StatefulWidget {
  final int ongId;

  const ConquistasScreen({super.key, required this.ongId});

  @override
  State<ConquistasScreen> createState() => _ConquistasScreenState();
}

class _ConquistasScreenState extends State<ConquistasScreen> {
  final ConquistaService _service = ConquistaService();
  List<Conquista> _conquistas = const [];
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });
    try {
      final lista = await _service.ong(widget.ongId);
      if (!mounted) return;
      setState(() {
        _conquistas = lista;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Conquistas'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? _mensagem(
                  'Nao foi possivel carregar as conquistas',
                  Icons.error_outline,
                )
              : _conquistas.isEmpty
                  ? _mensagem(
                      'Nenhuma conquista disponivel ainda',
                      Icons.emoji_events_outlined,
                    )
                  : _conteudo(),
    );
  }

  Widget _conteudo() {
    final total = _conquistas.length;
    final feitas = _conquistas.where((c) => c.conquistada).length;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    '$feitas de $total conquistadas',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _conquistas.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemBuilder: (context, i) => _cartao(_conquistas[i]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mensagem(String texto, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey),
          const SizedBox(height: 12),
          Text(texto),
          const SizedBox(height: 8),
          TextButton(onPressed: _carregar, child: const Text('Recarregar')),
        ],
      ),
    );
  }

  Widget _cartao(Conquista c) {
    final feita = c.conquistada;
    final corIcone = feita ? AppColors.primary : Colors.grey.shade400;
    return Card(
      child: Opacity(
        opacity: feita ? 1.0 : 0.6,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: corIcone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  feita ? _iconeConquista(c.chave) : Icons.lock_outline,
                  color: corIcone,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                c.titulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: feita ? AppColors.textPrimary : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  c.descricao,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                feita ? Icons.check_circle : Icons.lock_outline,
                size: 18,
                color: feita ? AppColors.primary : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
