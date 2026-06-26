import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/campanha.dart';
import 'api_service.dart';

class CampanhaService {
  static const String _base = '${ApiService.baseUrl}/campanhas';

  Future<List<Campanha>> listarPorOng(int ongId) async {
    final response = await http.get(Uri.parse('$_base?ongId=$ongId'));
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Campanha.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar campanhas');
  }

  Future<void> criar({
    required String titulo,
    required String descricao,
    required double metaValor,
    String? categoria,
    bool destaque = false,
    required int ongId,
  }) async {
    final response = await http.post(
      Uri.parse(_base),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'metaValor': metaValor,
        'categoria': categoria,
        'destaque': destaque,
        'ongId': ongId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final corpo = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(corpo['erro'] ?? 'Erro ao criar campanha');
    }
  }

  Future<void> encerrar(int id) async {
    final response = await http.put(Uri.parse('$_base/$id/encerrar'));
    if (response.statusCode != 200) {
      throw Exception('Erro ao encerrar campanha');
    }
  }
}
