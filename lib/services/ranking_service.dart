import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ranking_ong.dart';
import 'api_service.dart';

class RankingService {
  static const String _base = '${ApiService.baseUrl}/publico';

  /// Busca o ranking de transparencia das ONGs (GET /publico/ranking?limite=N),
  /// ja ordenado por score decrescente pelo backend.
  Future<List<RankingOng>> listar({int limite = 20}) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http
        .get(
          Uri.parse('$_base/ranking?limite=$limite'),
          headers: ApiService.authHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final raw = jsonDecode(utf8.decode(response.bodyBytes));
      if (raw is List) {
        return raw
            .map((e) => RankingOng.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <RankingOng>[];
    }
    throw Exception('Erro ao carregar o ranking de transparencia');
  }
}
