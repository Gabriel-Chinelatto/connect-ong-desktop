import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/necessidade.dart';
import 'api_service.dart';

/// Necessidades publicadas pela ONG (endpoint /necessidades).
///
/// A ONG cria pedidos (alimentos, roupas, etc.) que os doadores veem no app
/// mobile; aqui ela publica novas necessidades e lista as proprias. As
/// requisicoes seguem autenticadas via [ApiService] e com timeout de 10s.
class NecessidadeService {
  // ONG publica uma nova necessidade.
  Future<void> criar({
    required String titulo,
    required String descricao,
    required String categoria,
    required bool urgente,
    required int ongId,
  }) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/necessidades'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoria,
        'urgente': urgente,
        'ongId': ongId,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao publicar necessidade');
    }
  }

  // ONG edita uma necessidade existente (so a dona; validado pelo JWT).
  // Contrato: PUT /necessidades/{id} {titulo, descricao, categoria, urgente}.
  // Degrada com backend antigo: 404/405 (rota ainda nao publicada) vira uma
  // Exception amigavel em vez de "Erro" cru, para a UI nao quebrar.
  Future<void> editar({
    required int id,
    required String titulo,
    required String descricao,
    required String categoria,
    required bool urgente,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/necessidades/$id'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'titulo': titulo,
        'descricao': descricao,
        'categoria': categoria,
        'urgente': urgente,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200 || response.statusCode == 201) return;
    if (response.statusCode == 404 || response.statusCode == 405) {
      throw Exception(
          'Edição de necessidade indisponível nesta versão do servidor.');
    }
    String msg = 'Erro ao salvar a necessidade';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['erro'] != null) msg = body['erro'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  // ONG exclui uma necessidade (so a dona; validado pelo JWT).
  // Contrato: DELETE /necessidades/{id}. Degrada como o editar acima.
  Future<void> excluir(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/necessidades/$id'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 404 || response.statusCode == 405) {
      throw Exception(
          'Exclusão de necessidade indisponível nesta versão do servidor.');
    }
    String msg = 'Erro ao excluir a necessidade';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['erro'] != null) msg = body['erro'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  // Lista as necessidades publicadas por uma ONG.
  Future<List<Necessidade>> listarPorOng(int ongId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/necessidades?ongId=$ongId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar necessidades');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Necessidade.fromJson(json)).toList();
  }
}
