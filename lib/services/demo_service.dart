import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// "Modo Feira": pede ao backend para carregar os dados demonstrativos.
class DemoService {
  static const String _url = '${ApiService.baseUrl}/demo/seed';

  Future<Map<String, dynamic>> carregarDadosDemo() async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http
        .post(Uri.parse(_url), headers: ApiService.authHeaders())
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Erro ao carregar dados demonstrativos');
  }
}
