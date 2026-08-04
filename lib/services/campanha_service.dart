import 'dart:async';
import 'dart:convert';


import '../models/campanha.dart';
import 'api_service.dart';

/// Campanhas de arrecadacao da ONG (endpoint /campanhas).
///
/// A ONG cria campanhas com meta de valor, lista as proprias e pode encerra-las.
/// Chamadas autenticadas via [ApiService], com timeout adaptativo.
class CampanhaService {
  static const String _base = '${ApiService.baseUrl}/campanhas';

  Future<List<Campanha>> listarPorOng(int ongId) async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede
        .get(
          Uri.parse('$_base?ongId=$ongId'),
          headers: ApiService.authHeaders(),
        )
        .timeout(ApiService.timeout);
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
    final response = await ApiService.rede
        .post(
          Uri.parse(_base),
          headers: ApiService.jsonHeaders(),
          body: jsonEncode({
            'titulo': titulo,
            'descricao': descricao,
            'metaValor': metaValor,
            'categoria': categoria,
            'destaque': destaque,
            'ongId': ongId,
          }),
        )
        .timeout(ApiService.timeout);
    if (response.statusCode != 200 && response.statusCode != 201) {
      final corpo = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(corpo['erro'] ?? 'Erro ao criar campanha');
    }
  }

  Future<void> encerrar(int id) async {
    final response = await ApiService.rede
        .put(
          Uri.parse('$_base/$id/encerrar'),
          headers: ApiService.authHeaders(),
        )
        .timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao encerrar campanha');
    }
  }
}
