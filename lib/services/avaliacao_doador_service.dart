import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/perfil_publico_doador.dart';
import 'api_service.dart';

/// Avaliacao de doadores pela ONG (endpoint /avaliacoes-doador).
///
/// Estilo Uber: apos um match CONCLUIDO a ONG da 1-5 estrelas ao doador,
/// com comentario opcional. E um UPSERT por par ONG+doador (reenviar
/// atualiza a avaliacao existente) e o doador e notificado. A ONG
/// avaliadora vem do token JWT, nao do corpo.
class AvaliacaoDoadorService {
  // Cria ou atualiza (upsert) a avaliacao da ONG logada para um doador.
  Future<void> avaliar({
    required int doadorId,
    required int nota,
    String? comentario,
    List<String>? fotos,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/avaliacoes-doador'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'doadorId': doadorId,
        'nota': nota,
        if (comentario != null && comentario.trim().isNotEmpty)
          'comentario': comentario.trim(),
        // fotos == null: não mexe nas fotos existentes (contrato do backend).
        if (fotos != null) 'fotos': fotos,
      }),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode != 200 && response.statusCode != 201) {
      String msg = 'Erro ao enviar a avaliação';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['erro'] != null) msg = body['erro'].toString();
      } catch (_) {
        // Corpo nao-JSON: mantem a mensagem generica.
      }
      throw Exception(msg);
    }
  }

  // Lista as avaliacoes recebidas por um doador (publico).
  // Cada item traz ongNome/nota/comentario/criadoEm (sem ongId — para saber
  // se "eu ja avaliei", compare o ongNome com o nome da ONG da sessao).
  Future<List<AvaliacaoDoador>> listarPorDoador(int doadorId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/avaliacoes-doador?doadorId=$doadorId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar as avaliações do doador');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((j) => AvaliacaoDoador.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
