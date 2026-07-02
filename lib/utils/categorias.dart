import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Uma categoria canonica de doacao/necessidade.
///
/// [valor] e o que trafega e fica armazenado no backend (sem acento, no
/// plural — igual ao seed e ao GET /categorias da API). [rotulo] e o texto
/// exibido ao usuario (com acento). [cor] e o acento visual da categoria
/// (capas, chips e avatares).
class CategoriaInfo {
  final String valor;
  final String rotulo;
  final IconData icone;
  final Color cor;

  const CategoriaInfo(this.valor, this.rotulo, this.icone, this.cor);
}

/// Fonte unica de verdade das categorias no desktop (espelha o backend e o
/// app mobile).
///
/// Alem da lista canonica, oferece [normalizar] para casar valores legados
/// (singular, com acento, caixa diferente) com o valor canonico — assim
/// filtros e chips nao duplicam "Alimento" e "Alimentos".
class Categorias {
  Categorias._();

  static const List<CategoriaInfo> todas = [
    CategoriaInfo('Alimentos', 'Alimentos', Icons.restaurant_outlined,
        AppColors.primary),
    CategoriaInfo(
        'Roupas', 'Roupas', Icons.checkroom_outlined, AppColors.info),
    CategoriaInfo('Higiene', 'Higiene', Icons.clean_hands_outlined,
        Color(0xFF7C3AED)), // roxo de acento
    CategoriaInfo('Brinquedos', 'Brinquedos', Icons.toys_outlined,
        Color(0xFFDB2777)), // rosa de acento
    CategoriaInfo(
        'Educacao', 'Educação', Icons.school_outlined, AppColors.warning),
    CategoriaInfo('Saude', 'Saúde', Icons.health_and_safety_outlined,
        AppColors.error),
  ];

  /// Mapeia um valor qualquer para o canonico ("alimento" → "Alimentos").
  /// Valores desconhecidos voltam com trim, sem serem rejeitados.
  static String normalizar(String valor) {
    final chave = _chave(valor);
    for (final c in todas) {
      final canonica = _chave(c.valor);
      if (chave == canonica || '${chave}s' == canonica) return c.valor;
    }
    return valor.trim();
  }

  /// Rotulo de exibicao ("Educacao" → "Educação"). Desconhecidos: o proprio valor.
  static String rotulo(String valor) => _busca(valor)?.rotulo ?? valor.trim();

  /// Icone da categoria (fallback generico para valores desconhecidos).
  static IconData icone(String valor) =>
      _busca(valor)?.icone ?? Icons.category_outlined;

  /// Cor de acento da categoria (fallback: verde da marca).
  static Color cor(String valor) => _busca(valor)?.cor ?? AppColors.primary;

  static CategoriaInfo? _busca(String valor) {
    final v = normalizar(valor);
    for (final c in todas) {
      if (c.valor == v) return c;
    }
    return null;
  }

  // Chave de comparacao: minusculas e sem acentos.
  static String _chave(String v) {
    var s = v.trim().toLowerCase();
    const de = 'áàâãäéèêëíìîïóòôõöúùûüç';
    const para = 'aaaaaeeeeiiiiooooouuuuc';
    for (var i = 0; i < de.length; i++) {
      s = s.replaceAll(de[i], para[i]);
    }
    return s;
  }
}
