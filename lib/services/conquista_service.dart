import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/conquista.dart';
import 'api_service.dart';

class ConquistaService {
  static const String _base = '${ApiService.baseUrl}/conquistas';

  /// Busca a lista completa de conquistas da ONG
  /// (GET /conquistas/ong/{ongId}), incluindo as ainda nao conquistadas.
  Future<List<Conquista>> ong(int ongId) async {
    final response = await http.get(Uri.parse('$_base/ong/$ongId'));
    if (response.statusCode == 200) {
      final raw = jsonDecode(utf8.decode(response.bodyBytes));
      if (raw is List) {
        return raw
            .map((e) => Conquista.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return <Conquista>[];
    }
    throw Exception('Erro ao carregar as conquistas');
  }
}
