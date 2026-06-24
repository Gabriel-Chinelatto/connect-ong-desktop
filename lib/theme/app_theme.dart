import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light({bool dislexia = false, bool altoContraste = false}) =>
      _build(Brightness.light, dislexia, altoContraste);

  static ThemeData dark({bool dislexia = false, bool altoContraste = false}) =>
      _build(Brightness.dark, dislexia, altoContraste);

  static ThemeData _build(
      Brightness brightness, bool dislexia, bool altoContraste) {
    final bool escuro = brightness == Brightness.dark;

    final Color bg = escuro ? const Color(0xFF121212) : AppColors.background;
    final Color surface = escuro ? const Color(0xFF1E1E1E) : AppColors.surface;
    final Color texto = altoContraste
        ? (escuro ? Colors.white : Colors.black)
        : (escuro ? Colors.white70 : AppColors.textPrimary);

    final TextTheme base =
        dislexia ? GoogleFonts.lexendTextTheme() : GoogleFonts.poppinsTextTheme();
    final TextTheme textTheme =
        base.apply(bodyColor: texto, displayColor: texto);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: brightness,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        foregroundColor: texto,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: texto,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: altoContraste ? texto : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
