import 'package:flutter/material.dart';

import '../../models/ranking_ong.dart';
import '../../services/ranking_service.dart';
import '../../theme/app_colors.dart';

/// Cores das medalhas de transparencia.
const Color _ouro = Color(0xFFF59E0B);
const Color _prata = Color(0xFF9CA3AF);
const Color _bronze = Color(0xFFCD7F32);

Color _corNivel(String nivel) {
  switch (nivel.toUpperCase()) {
    case 'OURO':
      return _ouro;
    case 'PRATA':
      return _prata;
    default:
      return _bronze;
  }
}

String _rotuloNivel(String nivel) {
  switch (nivel.toUpperCase()) {
    case 'OURO':
      return 'Ouro';
    case 'PRATA':
      return 'Prata';
    default:
      return 'Bronze';
  }
}

/// Ranking publico de transparencia das ONGs, acessivel pelo painel.
class RankingTransparenciaScreen extends StatefulWidget {
  const RankingTransparenciaScreen({super.key});

  @override
  State<RankingTransparenciaScreen> createState() =>
      _RankingTransparenciaScreenState();
}

class _RankingTransparenciaScreenState
    extends State<RankingTransparenciaScreen> {
  final RankingService _service = RankingService();
  List<RankingOng> _ranking = const [];
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
      final lista = await _service.listar();
      if (!mounted) return;
      setState(() {
        _ranking = lista;
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
      appBar: AppBar(
        title: const Text('Ranking de Transparencia'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro
              ? _mensagem('Nao foi possivel carregar o ranking',
                  Icons.error_outline)
              : _ranking.isEmpty
                  ? _mensagem('Nenhuma ONG no ranking ainda',
                      Icons.emoji_events_outlined)
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _ranking.length,
                          itemBuilder: (context, i) =>
                              _cartao(i + 1, _ranking[i]),
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
          Icon(icon,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(texto),
          const SizedBox(height: 8),
          TextButton(onPressed: _carregar, child: const Text('Recarregar')),
        ],
      ),
    );
  }

  Widget _cartao(int posicao, RankingOng o) {
    final cor = _corNivel(o.nivel);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '#$posicao',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            Icon(Icons.workspace_premium, color: cor, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(o.nome,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      if (o.verificada) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified,
                            color: Colors.blue, size: 16),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(o.cidade,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${o.score}',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: cor)),
                Text(_rotuloNivel(o.nivel),
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
