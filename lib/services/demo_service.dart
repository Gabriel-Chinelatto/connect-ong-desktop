import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// "Modo Feira": pede ao backend para carregar os dados demonstrativos.
class DemoService {
  static const String _url = '${ApiService.baseUrl}/demo/seed';

  Future<Map<String, dynamic>> carregarDadosDemo() async {
    final response = await http.post(Uri.parse(_url));
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception('Erro ao carregar dados demonstrativos');
  }
}
