import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/preferencia.dart';
import 'api_service.dart';

class PreferenciaService {
  Future<Preferencia> obter(int usuarioId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/preferencias'),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar preferências');
    }
    return Preferencia.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  Future<void> salvar(int usuarioId, Preferencia prefs) async {
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/preferencias'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(prefs.toJson()),
    );
    if (response.statusCode != 200) {
      throw Exception('Erro ao salvar preferências');
    }
  }
}
