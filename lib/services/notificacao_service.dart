import 'dart:async';
import 'dart:convert';


import '../models/notificacao.dart';
import 'api_service.dart';

/// Notificacoes do usuario da ONG (endpoint /notificacoes).
///
/// Lista as notificacoes, conta as nao-lidas (usado pelo sino do painel) e
/// marca todas como lidas. Sempre filtradas pelo usuario autenticado.
class NotificacaoService {
  Future<List<Notificacao>> listar(int usuarioId) async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede.get(
      Uri.parse('${ApiService.baseUrl}/notificacoes?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar notificações');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((j) => Notificacao.fromJson(j)).toList();
  }

  Future<int> contarNaoLidas(int usuarioId) async {
    final response = await ApiService.rede.get(
      Uri.parse(
          '${ApiService.baseUrl}/notificacoes/nao-lidas?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) return 0;
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    return (body['naoLidas'] ?? 0) as int;
  }

  Future<void> marcarTodas(int usuarioId) async {
    final response = await ApiService.rede.put(
      Uri.parse(
          '${ApiService.baseUrl}/notificacoes/marcar-todas?usuarioId=$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    // Antes o status era ignorado: um 500 passava como sucesso e as notificacoes
    // continuavam nao-lidas apos recarregar, sem avisar o usuario.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Erro ao marcar notificações como lidas');
    }
  }

  // Marca UMA notificação como lida (PUT /notificacoes/{id}/lida). O backend
  // confere o dono pelo token.
  Future<void> marcarLida(int id) async {
    await ApiService.rede.put(
      Uri.parse('${ApiService.baseUrl}/notificacoes/$id/lida'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
  }
}
