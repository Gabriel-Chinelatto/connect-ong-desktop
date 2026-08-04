import 'dart:async';
import 'dart:convert';


import 'api_service.dart';

/// Perfil e seguranca da conta do usuario (endpoint /usuarios/{id}).
///
/// Permite ler/editar os dados do perfil e alterar a senha (exige a senha
/// atual). Opera sempre sobre o usuario autenticado.
class PerfilService {
  Future<Map<String, dynamic>> obter(int usuarioId) async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede.get(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/perfil'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar perfil');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> atualizar(
    int usuarioId,
    Map<String, dynamic> dados,
  ) async {
    final response = await ApiService.rede.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/perfil'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(dados),
    ).timeout(ApiService.timeout);
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
    final response = await ApiService.rede.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/senha'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({'senhaAtual': senhaAtual, 'novaSenha': novaSenha}),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao alterar senha');
    }
  }

  /// Altera o e-mail de login do usuario autenticado.
  ///
  /// Contrato: PUT /usuarios/{id}/email {novoEmail, senha}. Exige a senha
  /// atual como confirmacao. Mapeia os status conhecidos para mensagens
  /// amigaveis: 401 (senha incorreta), 409 (e-mail ja em uso), 404/405
  /// (rota indisponivel no backend antigo).
  Future<void> alterarEmail(
    int usuarioId,
    String novoEmail,
    String senha,
  ) async {
    final response = await ApiService.rede.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/email'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({'novoEmail': novoEmail, 'senha': senha}),
    ).timeout(ApiService.timeout);

    if (response.statusCode >= 200 && response.statusCode < 300) return;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Senha incorreta.');
    }
    if (response.statusCode == 409) {
      throw Exception('Este e-mail já está em uso por outra conta.');
    }
    if (response.statusCode == 404 || response.statusCode == 405) {
      throw Exception(
          'Alteração de e-mail indisponível nesta versão do servidor.');
    }
    String msg = 'Erro ao alterar o e-mail';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['erro'] != null) msg = body['erro'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  /// Exclui (soft-delete) a conta do proprio usuario autenticado.
  ///
  /// O backend desativa a conta (nao loga mais) e, sendo ONG, remove o perfil
  /// das listagens, preservando o historico. So o dono pode excluir; o backend
  /// valida a partir do token. Lanca [Exception] com a mensagem do corpo se a
  /// resposta nao for 2xx.
  Future<void> excluirConta(int usuarioId) async {
    final response = await ApiService.rede.delete(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
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
