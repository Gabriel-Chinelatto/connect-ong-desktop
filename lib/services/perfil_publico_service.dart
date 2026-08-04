import 'dart:async';
import 'dart:convert';


import '../models/perfil_publico_ong.dart';
import 'api_service.dart';

class PerfilPublicoService {
  static const String _base = '${ApiService.baseUrl}/ongs';

  /// Busca o perfil publico completo de uma ONG (GET /ongs/{id}/perfil-publico).
  Future<PerfilPublicoOng> buscar(int ongId) async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede
        .get(
          Uri.parse('$_base/$ongId/perfil-publico'),
          headers: ApiService.authHeaders(),
        )
        .timeout(ApiService.timeout);
    if (response.statusCode == 200) {
      return PerfilPublicoOng.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Erro ao carregar o perfil da ONG');
  }
}
