import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Abre uma visualização grande da imagem (dialog com zoom/arrastar).
///
/// Usado pelas miniaturas de fotos (prestação de contas, fotos do local,
/// anexos do chat): clicar na miniatura chama este helper.
Future<void> mostrarImagemGrande(
  BuildContext context,
  Uint8List bytes, {
  String? titulo,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      insetPadding: const EdgeInsets.all(24),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (titulo != null && titulo.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8, right: 40),
                    child: Text(
                      titulo,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                Flexible(
                  child: InteractiveViewer(
                    maxScale: 5,
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              tooltip: 'Fechar',
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ),
        ],
      ),
    ),
  );
}
