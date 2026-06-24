import 'package:flutter/material.dart';

/// Paleta de cores da marca Connect ONG (mesma do app mobile).
/// Fonte unica de verdade — use estas constantes em vez de Color(0xFF...).
class AppColors {
  AppColors._();

  // Verde da marca
  static const Color primary = Color(0xFF0A8449);
  static const Color primaryDark = Color(0xFF076637);
  static const Color primaryLight = Color(0xFFA8DBC1);

  // Superficies e fundo
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;

  // Texto
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  // Estados / feedback
  static const Color success = Color(0xFF0A8449);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFF59E0B);
}
