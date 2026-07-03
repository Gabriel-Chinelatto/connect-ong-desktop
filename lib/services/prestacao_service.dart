import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/prestacao.dart';
import 'api_service.dart';

/// Prestacao de contas da ONG num match (endpoint /prestacoes).
///
/// Apos receber uma doacao, a ONG publica como ela foi usada (titulo,
/// descricao, ate 5 fotos e o valor utilizado), reforcando a transparencia
/// exibida ao doador. Vale para matches ACEITO ou CONCLUIDO; apos a
/// conclusao ha um prazo de 10 dias (ver [pendencias]).
class PrestacaoService {
  // ONG publica uma prestacao de contas num match.
  // `fotos` sao strings base64 (max 5, ~2MB cada apos a compressao local).
  Future<void> criar({
    required int interesseId,
    required String titulo,
    required String descricao,
    List<String> fotos = const [],
    double? valorUtilizado,
  }) async {
    // Timeout maior que o padrao: o corpo pode carregar ate 5 fotos base64.
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/prestacoes'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'interesseId': interesseId,
        'titulo': titulo,
        'descricao': descricao,
        if (fotos.isNotEmpty) 'fotos': fotos,
        if (valorUtilizado != null) 'valorUtilizado': valorUtilizado,
      }),
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao publicar prestação de contas');
    }
  }

  // Lista as prestacoes de contas de um match (mais recentes primeiro).
  Future<List<Prestacao>> listarPorInteresse(int interesseId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/prestacoes?interesseId=$interesseId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar as prestações de contas');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((j) => Prestacao.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  // Pendencias da ONG: matches CONCLUIDOS ainda sem prestacao de contas.
  // So a propria ONG pode consultar (escopo do JWT). Pendencia `definitivo`
  // (prazo de 10 dias estourado) desconta 5 pontos do score de transparencia.
  Future<List<PendenciaPrestacao>> pendencias(int ongId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/prestacoes/pendencias?ongId=$ongId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar as pendências de prestação');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((j) => PendenciaPrestacao.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
