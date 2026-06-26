import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/notificacao.dart';
import 'api_service.dart';

class NotificacaoService {
  Future<List<Notificacao>> listar(int usuarioId) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/notificacoes?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar notificações');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((j) => Notificacao.fromJson(j)).toList();
  }

  Future<int> contarNaoLidas(int usuarioId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiService.baseUrl}/notificacoes/nao-lidas?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) return 0;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return (body['naoLidas'] ?? 0) as int;
  }

  Future<void> marcarTodas(int usuarioId) async {
    await http.put(
      Uri.parse(
          '${ApiService.baseUrl}/notificacoes/marcar-todas?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));
  }
}
