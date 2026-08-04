import 'dart:async';
import 'dart:convert';


import '../models/ranking_ong.dart';
import 'api_service.dart';

class RankingService {
  static const String _base = '${ApiService.baseUrl}/publico';

  /// Busca o ranking de transparencia das ONGs (GET /publico/ranking?limite=N),
  /// ja ordenado por score decrescente pelo backend.
  Future<List<RankingOng>> listar({int limite = 20}) async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede
        .get(
          Uri.parse('$_base/ranking?limite=$limite'),
          headers: ApiService.authHeaders(),
        )
        .timeout(ApiService.timeout);
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
