import 'package:flutter/widgets.dart';

/// Escala de arredondamento de cantos do app.
///
/// Mantem um "raio" consistente entre cards, botoes, inputs e chips.
class AppRadius {
  AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  // Atalhos prontos de BorderRadius (evita repetir BorderRadius.circular(...)).
  static const BorderRadius brSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius brMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius brLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius brXl = BorderRadius.all(Radius.circular(xl));
}
