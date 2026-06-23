import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/interesse.dart';
import 'api_service.dart';

class InteresseService {
  // Lista os interesses recebidos nas necessidades de uma ONG.
  Future<List<Interesse>> listarPorOng(int ongId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/interesses?ongId=$ongId'),
    );

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

  Future<void> _mudarStatus(int interesseId, String acao) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/interesses/$interesseId/$acao'),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar o interesse');
    }
  }
}
