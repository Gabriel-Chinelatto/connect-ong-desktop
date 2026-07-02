import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Autenticacao do usuario da ONG contra a API (POST /usuarios/login).
///
/// Em caso de sucesso, captura o JWT retornado e o guarda no [ApiService]
/// para que as proximas chamadas sejam autenticadas. Cada usuario so enxerga
/// os proprios dados/ONG; o token nao e persistido (login a cada abertura).
class AuthService {
  /// Faz login e retorna os dados do usuario (id, nome, email, tipo, ongId)
  /// ou null se as credenciais forem invalidas.
  ///
  /// Credenciais invalidas retornam `null`. Falhas de conexao (servidor fora
  /// do ar, timeout, sem rede) sao RELANCADAS como [Exception] para a tela
  /// distinguir "Login inválido" de "Não foi possível conectar ao servidor"
  /// (veja [ApiService.mensagemAmigavel]).
  Future<Map<String, dynamic>?> login(
    String email,
    String senha,
  ) async {
    // Timeout de 10s; TimeoutException/SocketException/ClientException sao
    // propagados para a tela tratar como falha de conexao (nao "login invalido").
    final response = await http
        .post(
          Uri.parse('${ApiService.baseUrl}/usuarios/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'senha': senha,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final dados =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      // Captura o token JWT retornado pelo login para as proximas chamadas.
      await ApiService.setToken(dados['accessToken'] as String?);
      return dados;
    }
    // Status != 200 (ex.: 401/403) = credenciais invalidas.
    return null;
  }
}
