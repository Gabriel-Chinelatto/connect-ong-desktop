import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/interesse.dart';
import 'api_service.dart';

/// Interesses de doadores nas necessidades da ONG (endpoint /interesses).
///
/// Regra de negocio central do match: ao aceitar um interesse ele vira um
/// "match" (libera o chat e a prestacao de contas); ao recusar, e descartado.
/// A ONG so opera os interesses das proprias necessidades (escopo do JWT).
class InteresseService {
  // Lista os interesses recebidos nas necessidades de uma ONG.
  Future<List<Interesse>> listarPorOng(int ongId) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/interesses?ongId=$ongId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar interesses');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Interesse.fromJson(json)).toList();
  }

  // ONG aceita um interesse (vira match).
  Future<void> aceitar(int interesseId) async {
    await _mudarStatus(interesseId, 'aceitar');
  }

  // ONG recusa um interesse.
  Future<void> recusar(int interesseId) async {
    await _mudarStatus(interesseId, 'recusar');
  }

  // ONG marca a doacao do match como recebida (ACEITO -> CONCLUIDO).
  // Inicia o prazo de 10 dias para a prestacao de contas e notifica o doador.
  Future<void> concluir(int interesseId) async {
    await _mudarStatus(interesseId, 'concluir');
  }

  Future<void> _mudarStatus(int interesseId, String acao) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/interesses/$interesseId/$acao'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      String msg = 'Erro ao atualizar o interesse';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['erro'] != null) msg = body['erro'].toString();
      } catch (_) {
        // Corpo nao-JSON: mantem a mensagem generica.
      }
      throw Exception(msg);
    }
  }
}
