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

/// Descobre a UF de uma cidade quando ela NÃO foi salva junto (cadastros
/// antigos guardavam só "Limeira", sem o " - SP").
///
/// Só responde quando o nome existe em UMA única UF — se houver homônimas
/// (ex.: "Bom Jesus" aparece em vários estados), devolve null e deixa a
/// escolha para a pessoa, em vez de chutar um estado errado.
String? ufDaCidade(String cidade, Map<String, List<String>> municipios) {
  final alvo = semAcento(cidade.trim()).toLowerCase();
  if (alvo.isEmpty) return null;
  String? achada;
  for (final entrada in municipios.entries) {
    final tem = entrada.value
        .any((c) => semAcento(c).toLowerCase() == alvo);
    if (!tem) continue;
    if (achada != null) return null; // homônima em mais de um estado
    achada = entrada.key;
  }
  return achada;
}

/// Diz se a cidade informada pertence à UF (comparação sem acento/caixa).
bool cidadePertenceAUf(
    String cidade, String? uf, Map<String, List<String>> municipios) {
  if (uf == null) return false;
  final alvo = semAcento(cidade.trim()).toLowerCase();
  if (alvo.isEmpty) return false;
  return (municipios[uf] ?? const [])
      .any((c) => semAcento(c).toLowerCase() == alvo);
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
