import 'dart:async';
import 'dart:convert';


import 'api_service.dart';

/// "Modo Feira": pede ao backend para carregar os dados demonstrativos.
class DemoService {
  static const String _url = '${ApiService.baseUrl}/demo/seed';

  Future<Map<String, dynamic>> carregarDadosDemo() async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede
        .post(Uri.parse(_url), headers: ApiService.authHeaders())
        .timeout(ApiService.timeout);
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Erro ao carregar dados demonstrativos');
  }
}
