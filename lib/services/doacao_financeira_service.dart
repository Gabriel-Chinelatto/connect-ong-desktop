import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/doacao_financeira.dart';
import 'api_service.dart';

/// Doacoes financeiras (PIX simulado) do recurso /doacoes-financeiras.
///
/// No desktop a ONG usa apenas a listagem das doacoes RECEBIDAS por ela
/// (GET /doacoes-financeiras?ongId=...). O endpoint exige o JWT da propria
/// ONG (ownership no backend); erros de rede/HTTP sao relancados para a tela
/// exibir com [ApiService.mensagemAmigavel].
class DoacaoFinanceiraService {
  /// Lista as doacoes PIX recebidas pela ONG [ongId], mais recentes primeiro.
  Future<List<DoacaoFinanceira>> listarPorOng(int ongId) async {
    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/doacoes-financeiras?ongId=$ongId'),
          headers: ApiService.authHeaders(),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
          'Não foi possível carregar as doações (HTTP ${response.statusCode}).');
    }

    final lista = jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>;
    final doacoes = lista
        .map((e) => DoacaoFinanceira.fromJson(e as Map<String, dynamic>))
        .toList();

    // Mais recentes primeiro (doacoes sem data vao para o fim).
    doacoes.sort((a, b) {
      final da = a.data;
      final db = b.data;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return doacoes;
  }
}
