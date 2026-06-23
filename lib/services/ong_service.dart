import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ong.dart';
import 'api_service.dart';

class OngService {
  // Lista todas as ONGs (usado no seletor "qual ONG voce gerencia").
  Future<List<Ong>> listarTodas() async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/ongs'),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar ONGs');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Ong.fromJson(json)).toList();
  }

  // Tenta identificar a ONG do usuario pelo email do login.
  // Retorna null se nenhuma ONG tiver esse email.
  Future<Ong?> buscarPorEmail(String email) async {
    final todas = await listarTodas();
    final alvo = email.trim().toLowerCase();
    for (final ong in todas) {
      if (ong.email.trim().toLowerCase() == alvo) {
        return ong;
      }
    }
    return null;
  }
}
