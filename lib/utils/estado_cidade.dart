import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Utilitários de Estado (UF) e Cidade.
///
/// O backend guarda a localização da ONG num único campo `cidade`; para não
/// perder a UF escolhida, persistimos no formato "Cidade - UF" (ex.:
/// "São Paulo - SP") e fazemos o parse de volta ao carregar. Os helpers
/// [formatarCidadeUf] e [separarCidadeUf] centralizam esse contrato.

/// Siglas das 27 UFs brasileiras, em ordem alfabética (fonte: IBGE).
const List<String> ufsBrasil = [
  'AC', 'AL', 'AM', 'AP', 'BA', 'CE', 'DF', 'ES', 'GO',
  'MA', 'MG', 'MS', 'MT', 'PA', 'PB', 'PE', 'PI', 'PR',
  'RJ', 'RN', 'RO', 'RR', 'RS', 'SC', 'SE', 'SP', 'TO',
];

/// Junta cidade e UF no formato persistido no campo único `cidade`.
/// Sem cidade não há o que guardar (retorna vazio); sem UF, só a cidade.
String formatarCidadeUf(String cidade, String? uf) {
  final c = cidade.trim();
  final u = uf?.trim().toUpperCase() ?? '';
  if (c.isEmpty) return '';
  if (u.isEmpty || !ufsBrasil.contains(u)) return c;
  return '$c - $u';
}

/// Separa um valor "Cidade - UF" de volta em cidade e UF.
/// Se o sufixo não for uma UF válida, tudo é tratado como cidade (uf null) —
/// compatível com cadastros antigos de campo livre.
({String cidade, String? uf}) separarCidadeUf(String valor) {
  final v = valor.trim();
  final m = RegExp(r'^(.*\S)\s*-\s*([A-Za-z]{2})$').firstMatch(v);
  if (m != null) {
    final uf = m.group(2)!.toUpperCase();
    if (ufsBrasil.contains(uf)) {
      return (cidade: m.group(1)!.trim(), uf: uf);
    }
  }
  return (cidade: v, uf: null);
}

/// Carrega (uma vez) o mapa UF -> municípios do asset offline gerado a partir
/// da API de localidades do IBGE (assets/dados/municipios_por_uf.json).
///
/// Em falha de leitura/parse retorna um mapa vazio: o autocomplete de cidade
/// degrada para campo livre, sem quebrar a tela.
class Municipios {
  Municipios._();

  static Map<String, List<String>>? _cache;

  static Future<Map<String, List<String>>> carregar() async {
    final atual = _cache;
    if (atual != null) return atual;
    try {
      final raw =
          await rootBundle.loadString('assets/dados/municipios_por_uf.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      _cache = {
        for (final e in json.entries)
          e.key: (e.value as List).whereType<String>().toList(),
      };
    } catch (_) {
      _cache = const {};
    }
    return _cache!;
  }
}

/// Remove acentos para comparações de busca (não altera a exibição).
String semAcento(String s) {
  const de = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
  const para = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
  final sb = StringBuffer();
  for (final r in s.runes) {
    final ch = String.fromCharCode(r);
    final i = de.indexOf(ch);
    sb.write(i >= 0 ? para[i] : ch);
  }
  return sb.toString();
}
