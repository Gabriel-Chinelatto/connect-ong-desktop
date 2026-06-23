import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mensagem.dart';
import 'api_service.dart';

class MensagemService {
  // Lista as mensagens de um match (ordenadas por data).
  Future<List<Mensagem>> listar(int interesseId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/mensagens?interesseId=$interesseId'),
    );

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
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'interesseId': interesseId,
        'remetente': remetente,
        'conteudo': conteudo,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao enviar mensagem');
    }
  }
}
