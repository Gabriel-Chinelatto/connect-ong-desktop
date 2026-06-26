import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mensagem.dart';
import 'api_service.dart';

/// Chat de um match (endpoint /mensagens), entre a ONG e o doador.
///
/// So existe conversa apos o interesse virar match (aceito). A tela de chat
/// faz polling deste servico a cada 2s para simular tempo real, ja que nao
/// ha WebSocket. As mensagens vem ordenadas por data.
class MensagemService {
  // Lista as mensagens de um match (ordenadas por data).
  Future<List<Mensagem>> listar(int interesseId) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/mensagens?interesseId=$interesseId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar mensagens');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Mensagem.fromJson(json)).toList();
  }

  // Envia uma mensagem no chat do match.
  Future<void> enviar({
    required int interesseId,
    required String remetente,
    required String conteudo,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/mensagens'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'interesseId': interesseId,
        'remetente': remetente,
        'conteudo': conteudo,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao enviar mensagem');
    }
  }
}
