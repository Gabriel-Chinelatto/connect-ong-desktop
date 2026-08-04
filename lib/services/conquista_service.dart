import 'dart:async';
import 'dart:convert';


import '../models/conquista.dart';
import 'api_service.dart';

class ConquistaService {
  static const String _base = '${ApiService.baseUrl}/conquistas';

  /// Busca a lista completa de conquistas da ONG
  /// (GET /conquistas/ong/{ongId}), incluindo as ainda nao conquistadas.
  Future<List<Conquista>> ong(int ongId) async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede
        .get(
          Uri.parse('$_base/ong/$ongId'),
          headers: ApiService.authHeaders(),
        )
        .timeout(ApiService.timeout);
    if (response.statusCode == 200) {
      final raw = jsonDecode(utf8.decode(response.bodyBytes));
      if (raw is List) {
        return raw
            .map((e) => Conquista.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <Conquista>[];
    }
    throw Exception('Erro ao carregar as conquistas');
  }
}
