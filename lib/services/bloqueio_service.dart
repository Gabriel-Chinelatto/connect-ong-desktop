import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/bloqueio.dart';
import 'api_service.dart';

/// Bloqueio de doadores pela ONG (endpoints /bloqueios).
///
/// Contrato (ONG autenticada; escopo do JWT):
/// - GET  /bloqueios              -> [{doadorId, doadorNome, criadoEm}]
/// - POST /bloqueios {doadorId}   -> 200 {"mensagem"} (idempotente)
/// - DELETE /bloqueios/{doadorId} -> 200
///
/// Degradação: durante a transição o backend pode ainda não ter os endpoints;
/// um GET 404 é tratado como "nenhum bloqueio" para a UI não quebrar.
class BloqueioService {
  /// Lista os doadores bloqueados pela ONG logada.
  /// Backend antigo (404) degrada para lista vazia.
  Future<List<Bloqueio>> listar() async {
    final response = await ApiService.rede.get(
      Uri.parse('${ApiService.baseUrl}/bloqueios'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);

    if (response.statusCode == 404) return const [];
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar os doadores bloqueados');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .where((j) => j['doadorId'] is num)
        .map(Bloqueio.fromJson)
        .toList();
  }

  /// Bloqueia um doador (idempotente no backend).
  Future<void> bloquear(int doadorId) async {
    final response = await ApiService.rede.post(
      Uri.parse('${ApiService.baseUrl}/bloqueios'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({'doadorId': doadorId}),
    ).timeout(ApiService.timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(_erroDoCorpo(response, 'Erro ao bloquear o doador'));
    }
  }

  /// Remove o bloqueio de um doador.
  Future<void> desbloquear(int doadorId) async {
    final response = await ApiService.rede.delete(
      Uri.parse('${ApiService.baseUrl}/bloqueios/$doadorId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(_erroDoCorpo(response, 'Erro ao desbloquear o doador'));
    }
  }

  /// Extrai a mensagem do campo `erro` do corpo, se houver.
  String _erroDoCorpo(http.Response response, String padrao) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['erro'] != null) return body['erro'].toString();
    } catch (_) {
      // Corpo não-JSON: mantém a mensagem padrão.
    }
    return padrao;
  }
}
