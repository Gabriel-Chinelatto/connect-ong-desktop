import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/atividade.dart';
import 'api_service.dart';

class AtividadeService {
  static const String _base = '${ApiService.baseUrl}/atividades';

  /// Feed global de atividades recentes da plataforma (ordenado por data desc).
  Future<List<Atividade>> listarRecentes({int limit = 30}) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http
        .get(
          Uri.parse('$_base?limit=$limit'),
          headers: ApiService.authHeaders(),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Atividade.fromJson(e)).toList();
    }
    throw Exception('Erro ao carregar atividades');
  }
}
