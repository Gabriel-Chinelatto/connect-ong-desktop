import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/perfil_publico_doador.dart';
import 'api_service.dart';

/// Perfil publico de um doador (GET /usuarios/{id}/perfil-publico).
///
/// A ONG usa para ver quem e o doador do match: nome, cidade, nota media
/// dada por outras ONGs, stats e prestacoes ja recebidas.
class PerfilPublicoDoadorService {
  Future<PerfilPublicoDoador> buscar(int usuarioId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/perfil-publico'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar o perfil do doador');
    }
    return PerfilPublicoDoador.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }
}
