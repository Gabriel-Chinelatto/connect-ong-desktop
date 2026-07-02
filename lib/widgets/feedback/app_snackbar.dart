import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';

/// Helper para exibir snackbars padronizados de feedback ao usuario.
///
/// Oferece [sucesso] (verde da marca) e [erro] (vermelho semantico), ambos no
/// estilo flutuante e arredondado da marca. Usa as cores do design system
/// (AppColors) para manter contraste correto tambem no tema escuro.
class AppSnackbar {
  AppSnackbar._();

  static void sucesso(BuildContext context, String mensagem) {
    _mostrar(context, mensagem, AppColors.success);
  }

  static void erro(BuildContext context, String mensagem) {
    _mostrar(context, mensagem, AppColors.error);
  }

  static void _mostrar(BuildContext context, String mensagem, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensagem,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
      ),
    );
  }
}
