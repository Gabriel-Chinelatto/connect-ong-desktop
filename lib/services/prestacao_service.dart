import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class PrestacaoService {
  // ONG publica uma prestacao de contas num match.
  Future<void> criar({
    required int interesseId,
    required String titulo,
    required String descricao,
    required String fotoUrl,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/prestacoes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'interesseId': interesseId,
        'titulo': titulo,
        'descricao': descricao,
        'fotoUrl': fotoUrl,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao publicar prestação de contas');
    }
  }
}
