import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ong.dart';
import 'api_service.dart';

/// Cadastro e identificacao de ONGs (endpoint /ongs).
///
/// Cobre o registro de uma nova ONG (perfil + conta de login juntos) e a
/// descoberta de qual ONG o usuario gerencia a partir do email do login.
class OngService {
  // Lista todas as ONGs (usado no seletor "qual ONG voce gerencia").
  Future<List<Ong>> listarTodas() async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/ongs'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar ONGs');
    }

    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Ong.fromJson(json)).toList();
  }

  // Cadastra uma ONG: cria o perfil + a conta de login juntos.
  Future<void> registrar({
    required String nome,
    required String email,
    required String telefone,
    required String cidade,
    required String descricao,
    required String senha,
    String cnpj = '',
  }) async {
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/ongs/registro'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'cidade': cidade,
        'descricao': descricao,
        'cnpj': cnpj,
        'senha': senha,
      }),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao cadastrar ONG');
    }
  }

  // Busca o perfil completo de uma ONG (GET /ongs/{id}), incluindo os
  // campos ricos: capaBase64, endereco e fotosLocal.
  Future<Ong> buscarPorId(int id) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/ongs/$id'),
      headers: ApiService.authHeaders(),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar os dados da ONG');
    }
    return Ong.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  // Atualiza o perfil da ONG (PUT /ongs/{id}; so a propria ONG).
  //
  // ATENCAO ao contrato do backend: nome/email/telefone/cidade/descricao sao
  // SEMPRE sobrescritos (se faltarem, viram null!) — envie sempre os 5.
  // Ja capaBase64/endereco/fotosLocal preservam o valor atual quando null;
  // fotosLocal, quando presente, SUBSTITUI todas as fotos.
  Future<void> atualizar({
    required int id,
    required String nome,
    required String email,
    required String telefone,
    required String cidade,
    required String descricao,
    String? capaBase64,
    String? endereco,
    List<String>? fotosLocal,
  }) async {
    // Timeout maior: o corpo pode carregar capa + ate 5 fotos base64.
    final response = await http.put(
      Uri.parse('${ApiService.baseUrl}/ongs/$id'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'nome': nome,
        'email': email,
        'telefone': telefone,
        'cidade': cidade,
        'descricao': descricao,
        if (capaBase64 != null) 'capaBase64': capaBase64,
        if (endereco != null) 'endereco': endereco,
        if (fotosLocal != null) 'fotosLocal': fotosLocal,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      String msg = 'Erro ao salvar o perfil da ONG';
      try {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        if (body is Map && body['erro'] != null) msg = body['erro'].toString();
      } catch (_) {
        // Corpo nao-JSON: mantem a mensagem generica.
      }
      throw Exception(msg);
    }
  }

  // Tenta identificar a ONG do usuario pelo email do login.
  // Retorna null se nenhuma ONG tiver esse email.
  Future<Ong?> buscarPorEmail(String email) async {
    final todas = await listarTodas();
    final alvo = email.trim().toLowerCase();
    for (final ong in todas) {
      if (ong.email.trim().toLowerCase() == alvo) {
        return ong;
      }
    }
    return null;
  }
}
