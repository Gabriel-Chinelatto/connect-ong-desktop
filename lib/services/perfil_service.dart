import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class PerfilService {
  Future<Map<String, dynamic>> obter(int usuarioId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/perfil'),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar perfil');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizar(
    int usuarioId,
    Map<String, dynamic> dados,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/perfil'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dados),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao salvar perfil');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<void> alterarSenha(
    int usuarioId,
    String senhaAtual,
    String novaSenha,
  ) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/senha'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'senhaAtual': senhaAtual, 'novaSenha': novaSenha}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao alterar senha');
    }
  }
}
