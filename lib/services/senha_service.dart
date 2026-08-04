import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Resultado do pedido de recuperacao de senha.
///
/// [codigoDemo] so vem preenchido quando o servidor esta em modo demo
/// (sem e-mail real): a UI deve exibi-lo num card destacado.
class EsqueciSenhaResultado {
  final String mensagem;
  final String? codigoDemo;

  const EsqueciSenhaResultado({required this.mensagem, this.codigoDemo});
}

/// Recuperacao de senha (fluxo "esqueci a senha") contra a API.
///
/// Passo 1: [solicitarCodigo] (POST /auth/esqueci-senha) envia o codigo ao
/// e-mail. Passo 2: [redefinirSenha] (POST /auth/redefinir-senha) troca a
/// senha usando o codigo. Erros da API (ex.: "Código inválido ou expirado.")
/// sao relancados como Exception para a tela exibir com
/// [ApiService.mensagemAmigavel].
class SenhaService {
  static const Duration _timeout = Duration(seconds: 10);

  /// Pede o envio do codigo de recuperacao para [email].
  Future<EsqueciSenhaResultado> solicitarCodigo(String email) async {
    final response = await ApiService.rede
        .post(
          Uri.parse('${ApiService.baseUrl}/auth/esqueci-senha'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(_timeout);

    final body = _corpo(response);
    if (response.statusCode != 200) {
      throw Exception(_mensagemErro(body, response.statusCode));
    }
    return EsqueciSenhaResultado(
      mensagem: body['mensagem']?.toString() ??
          'Se o e-mail estiver cadastrado, você receberá um código.',
      codigoDemo: body['codigoDemo']?.toString(),
    );
  }

  /// Redefine a senha usando o [codigo] recebido. Retorna a mensagem de
  /// sucesso da API; codigo invalido/expirado vira Exception com o erro.
  Future<String> redefinirSenha({
    required String email,
    required String codigo,
    required String novaSenha,
  }) async {
    final response = await ApiService.rede
        .post(
          Uri.parse('${ApiService.baseUrl}/auth/redefinir-senha'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'codigo': codigo,
            'novaSenha': novaSenha,
          }),
        )
        .timeout(_timeout);

    final body = _corpo(response);
    if (response.statusCode != 200) {
      throw Exception(_mensagemErro(body, response.statusCode));
    }
    return body['mensagem']?.toString() ?? 'Senha redefinida com sucesso.';
  }

  // Decodifica o corpo JSON com tolerancia (corpo vazio/invalido vira {}).
  Map<String, dynamic> _corpo(http.Response response) {
    try {
      final decodificado = jsonDecode(utf8.decode(response.bodyBytes));
      return decodificado is Map<String, dynamic> ? decodificado : {};
    } catch (_) {
      return {};
    }
  }

  String _mensagemErro(Map<String, dynamic> body, int status) {
    final erro = body['erro'] ?? body['mensagem'];
    return erro?.toString() ?? 'Não foi possível concluir (HTTP $status).';
  }
}
