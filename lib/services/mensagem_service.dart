import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/mensagem.dart';
import 'api_service.dart';

/// Chat de um match (endpoint /mensagens), entre a ONG e o doador.
///
/// So existe conversa apos o interesse virar match (aceito). A tela de chat
/// faz polling deste servico a cada 2s para simular tempo real, ja que nao
/// ha WebSocket. As mensagens vem ordenadas por data.
class MensagemService {
  // Lista as mensagens de um match (ordenadas por data).
  Future<List<Mensagem>> listar(int interesseId) async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/mensagens?interesseId=$interesseId'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar mensagens');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Mensagem.fromJson(json)).toList();
  }

  // Envia uma mensagem no chat do match. Texto vazio e permitido SE houver
  // anexo de imagem (anexoBase64 + anexoTipo "imagem").
  Future<void> enviar({
    required int interesseId,
    required String remetente,
    required String conteudo,
    String? anexoBase64,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/mensagens'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'interesseId': interesseId,
        'remetente': remetente,
        'conteudo': conteudo,
        if (anexoBase64 != null) 'anexoBase64': anexoBase64,
        if (anexoBase64 != null) 'anexoTipo': 'imagem',
      }),
      // Timeout maior quando ha anexo (foto base64 no corpo).
    ).timeout(Duration(seconds: anexoBase64 != null ? 30 : 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao enviar mensagem');
    }
  }

  // Situacao do OUTRO participante (online / ultimo visto / digitando).
  // Chamar tambem registra a MINHA presenca (heartbeat) no backend.
  // Best-effort: NUNCA quebra o chat; em qualquer erro devolve default seguro.
  Future<Map<String, dynamic>> status(int interesseId) async {
    const seguro = {'online': false, 'ultimoVisto': null, 'digitando': false};
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/mensagens/status?interesseId=$interesseId'),
        headers: ApiService.authHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return seguro;
      return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      return seguro;
    }
  }

  // Alterna/troca a reacao (emoji) do usuario atual numa mensagem (toggle).
  // `emojiCode` e um CODIGO (ex.: LIKE, LOVE), nao o caractere.
  Future<void> reagir(int mensagemId, String emojiCode) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/mensagens/$mensagemId/reacao'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({'emoji': emojiCode}),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String msg = 'Erro ao reagir';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['erro'] != null) msg = body['erro'].toString();
      } catch (_) {
        // Corpo nao-JSON: mantem a mensagem generica.
      }
      throw Exception(msg);
    }
  }

  // Sinaliza que estou digitando neste match. Best-effort: ignora erros.
  Future<void> digitando(int interesseId) async {
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/mensagens/digitando?interesseId=$interesseId'),
        headers: ApiService.jsonHeaders(),
      ).timeout(const Duration(seconds: 10));
    } catch (_) {
      // Ignora: sinal de digitacao e best-effort.
    }
  }
}
