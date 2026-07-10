import 'package:flutter/material.dart';

/// Diálogo que explica o SISTEMA DE PONTOS (índice de transparência) da ONG:
/// o que faz ganhar e perder pontos e os níveis. Quanto maior o score, mais
/// visibilidade no ranking — por isso vale a pena entender as regras.
///
/// Fonte única (mesmos números do backend `TransparenciaService`): mantê-los
/// aqui em sincronia evita a UI prometer pontos que o servidor não dá.
void mostrarComoPontuar(BuildContext context) {
  final cs = Theme.of(context).colorScheme;

  Widget linha(IconData icon, Color cor, String texto) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: cor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(texto,
                  style: TextStyle(fontSize: 13, color: cs.onSurface)),
            ),
          ],
        ),
      );

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.amber.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text('Como sua ONG pontua')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'O índice de transparência vai de 0 a 100. Quanto maior, mais '
              'alto sua ONG aparece no ranking e mais confiança ela passa.',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Text('Você GANHA pontos com:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            linha(Icons.verified, Colors.blue, 'Selo de verificação: +25'),
            linha(Icons.star, Colors.amber.shade700,
                'Boas avaliações dos doadores: até +25'),
            linha(Icons.receipt_long, Colors.green,
                'Cada prestação de contas publicada: +5 (até +25)'),
            linha(Icons.campaign, Colors.green,
                'Cada campanha concluída: +5 (até +25)'),
            const SizedBox(height: 12),
            Text('Você PERDE pontos com:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            linha(Icons.timer_off, Colors.red,
                'Cada doação concluída sem prestar contas em 10 dias: −5'),
            const SizedBox(height: 14),
            Text('Níveis:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: cs.onSurface)),
            const SizedBox(height: 4),
            Text('🥇 Ouro: 75 ou mais   🥈 Prata: 45 a 74   🥉 Bronze: até 44',
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendi'),
        ),
      ],
    ),
  );
}
