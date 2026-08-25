import 'dart:async';
import 'dart:convert';


import '../models/ong.dart';
import 'api_service.dart';

/// Cadastro e identificacao de ONGs (endpoint /ongs).
///
/// Cobre o registro de uma nova ONG (perfil + conta de login juntos) e a
/// descoberta de qual ONG o usuario gerencia a partir do email do login.
class OngService {
  // Lista todas as ONGs (usado no seletor "qual ONG voce gerencia").
  Future<List<Ong>> listarTodas() async {
    // Timeout adaptativo (ApiService.timeout) para nao travar a UI.
    final response = await ApiService.rede.get(
      Uri.parse('${ApiService.baseUrl}/ongs'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);

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
    final response = await ApiService.rede.post(
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
    ).timeout(ApiService.timeout);

    if (response.statusCode != 200 && response.statusCode != 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['erro'] ?? 'Erro ao cadastrar ONG');
    }
  }

  // Busca o perfil completo de uma ONG (GET /ongs/{id}), incluindo os
  // campos ricos: capaBase64, endereco e fotosLocal.
  Future<Ong> buscarPorId(int id) async {
    final response = await ApiService.rede.get(
      Uri.parse('${ApiService.baseUrl}/ongs/$id'),
      headers: ApiService.authHeaders(),
    ).timeout(ApiService.timeout);

    if (response.statusCode != 200) {
      throw Exception('Erro ao carregar os dados da ONG');
    }
    return Ong.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
  }

  // Atualiza o perfil da ONG (PUT /ongs/{id}; so a propria ONG).
  //
  // Contrato do backend: telefone/cidade/descricao sao sobrescritos pelo que
  // for enviado; nome/email so mudam quando vem PREENCHIDOS; logoBase64/
  // capaBase64/endereco/fotosLocal preservam o atual quando null (e fotosLocal,
  // quando presente, SUBSTITUI todas as fotos).
  //
  // O e-mail e opcional aqui de proposito: o GET do perfil NAO o devolve
  // (privacidade), entao esta tela nunca o conhece. Mandar vazio fazia o
  // backend responder 500 e a ONG nao conseguia salvar nada.
  Future<void> atualizar({
    required int id,
    required String nome,
    String? email,
    required String telefone,
    required String cidade,
    required String descricao,
    String? logoBase64,
    String? capaBase64,
    String? endereco,
    double? latitude,
    double? longitude,
    List<String>? fotosLocal,
  }) async {
    // Timeout maior: o corpo pode carregar capa + ate 5 fotos base64.
    final response = await ApiService.rede.put(
      Uri.parse('${ApiService.baseUrl}/ongs/$id'),
      headers: ApiService.jsonHeaders(),
      body: jsonEncode({
        'nome': nome,
        // So vai quando a tela realmente tem o e-mail (ver comentario acima).
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'telefone': telefone,
        'cidade': cidade,
        'descricao': descricao,
        if (logoBase64 != null) 'logoBase64': logoBase64,
        if (capaBase64 != null) 'capaBase64': capaBase64,
        if (endereco != null) 'endereco': endereco,
        // Coordenadas so vao quando ambas presentes (endereco confirmado no
        // mapa). O backend valida a faixa e so sobrescreve se validas.
        if (latitude != null && longitude != null) 'latitude': latitude,
        if (latitude != null && longitude != null) 'longitude': longitude,
        if (fotosLocal != null) 'fotosLocal': fotosLocal,
      }),
    ).timeout(ApiService.timeoutPesado);

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
