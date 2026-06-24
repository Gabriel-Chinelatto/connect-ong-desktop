import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class AuthService {
  /// Faz login e retorna os dados do usuario (id, nome, email, tipo, ongId)
  /// ou null se as credenciais forem invalidas.
  Future<Map<String, dynamic>?> login(
    String email,
    String senha,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/usuarios/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'senha': senha,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
