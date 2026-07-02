import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Estado vazio padronizado do app: icone grande + mensagem + acao opcional.
///
/// Substitui os `_vazio()` que cada tela implementava com pequenas variacoes.
/// Sempre nas cores do TEMA (dark mode ok). Use dentro de um ListView quando a
/// tela tiver pull-to-refresh.
class EmptyState extends StatelessWidget {
  final IconData icone;
  final String mensagem;
  final String? detalhe;
  final String? acaoRotulo;
  final VoidCallback? onAcao;

  const EmptyState({
    super.key,
    required this.icone,
    required this.mensagem,
    this.detalhe,
    this.acaoRotulo,
    this.onAcao,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: cs.onSurfaceVariant.withValues(alpha: 0.6)),
            const SizedBox(height: AppSpacing.md),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            if (detalhe != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                detalhe!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ],
            if (acaoRotulo != null && onAcao != null) ...[
              const SizedBox(height: AppSpacing.md),
              FilledButton.tonal(onPressed: onAcao, child: Text(acaoRotulo!)),
            ],
          ],
        ),
      ),
    );
  }
}
