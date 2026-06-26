import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/perfil_publico_ong.dart';
import 'api_service.dart';

class PerfilPublicoService {
  static const String _base = '${ApiService.baseUrl}/ongs';

  /// Busca o perfil publico completo de uma ONG (GET /ongs/{id}/perfil-publico).
  Future<PerfilPublicoOng> buscar(int ongId) async {
    final response = await http.get(Uri.parse('$_base/$ongId/perfil-publico'));
    if (response.statusCode == 200) {
      return PerfilPublicoOng.fromJson(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
    }
    throw Exception('Erro ao carregar o perfil da ONG');
  }
}
