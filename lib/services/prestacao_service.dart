import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Prestacao de contas da ONG num match (endpoint /prestacoes).
///
/// Apos receber uma doacao, a ONG publica como ela foi usada (titulo,
/// descricao e foto), reforcando a transparencia exibida ao doador.
class PrestacaoService {
  // ONG publica uma prestacao de contas num match.
  Future<void> criar({
    required int interesseId,
    required String titulo,
    required String descricao,
    required String fotoUrl,
  }) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/prestacoes'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'interesseId': interesseId,
        'titulo': titulo,
        'descricao': descricao,
        'fotoUrl': fotoUrl,
      }),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao publicar prestação de contas');
    }
  }
}
