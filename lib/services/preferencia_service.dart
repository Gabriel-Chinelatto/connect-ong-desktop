import 'dart:async';
import 'dart:convert';


import '../models/preferencia.dart';
import 'api_service.dart';

/// Preferencias de aparencia/acessibilidade do usuario
/// (endpoint /usuarios/{id}/preferencias).
///
/// Persiste no backend o que o [ConfigController] aplica na UI (tema, fonte,
/// alto contraste, notificacoes). Le e salva sempre o usuario autenticado.
class PreferenciaService {
  Future<Preferencia> obter(int usuarioId) async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede.get(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/preferencias'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar preferências');
    }
    return Preferencia.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }

  Future<void> salvar(int usuarioId, Preferencia prefs) async {
    final response = await ApiService.rede.put(
      Uri.parse('${ApiService.baseUrl}/usuarios/$usuarioId/preferencias'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode(prefs.toJson()),
    ).timeout(ApiService.timeout);
    if (response.statusCode != 200) {
      throw Exception('Erro ao salvar preferências');
    }
  }
}
