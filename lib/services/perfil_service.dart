import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Perfil e seguranca da conta do usuario (endpoint /usuarios/{id}).
///
/// Permite ler/editar os dados do perfil e alterar a senha (exige a senha
/// atual). Opera sempre sobre o usuario autenticado.
class PerfilService {
  Future<Map<String, dynamic>> obter(int usuarioId) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/perfil'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));
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
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(dados),
    ).timeout(const Duration(seconds: 10));
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
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({'senhaAtual': senhaAtual, 'novaSenha': novaSenha}),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao alterar senha');
    }
  }
}
