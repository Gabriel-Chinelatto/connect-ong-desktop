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

  /// Exclui (soft-delete) a conta do proprio usuario autenticado.
  ///
  /// O backend desativa a conta (nao loga mais) e, sendo ONG, remove o perfil
  /// das listagens, preservando o historico. So o dono pode excluir; o backend
  /// valida a partir do token. Lanca [Exception] com a mensagem do corpo se a
  /// resposta nao for 2xx.
  Future<void> excluirConta(int usuarioId) async {
    final response = await http.delete(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String mensagem = 'Erro ao excluir a conta';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['erro'] != null) {
          mensagem = body['erro'].toString();
        } else if (body is Map && body['mensagem'] != null) {
          mensagem = body['mensagem'].toString();
        }
      } catch (_) {}
      throw Exception(mensagem);
    }
  }
}
