import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/doacao_model.dart';
import 'api_service.dart';

/// Doacoes/itens (endpoint /doacoes), via metodos estaticos.
///
/// Lista e cria registros de doacao. Diferente dos demais servicos, trata
/// falhas de forma silenciosa (retorna lista vazia ou false) para nao
/// interromper o fluxo da tela em caso de erro de rede.
class DoacaoService {

  // =========================
  // LISTAR
  // =========================

  static Future<List<DoacaoModel>> listarDoacoes() async {

    try {

      // Timeout de 10s; o TimeoutException cai no catch abaixo.
      final response = await http.get(

        Uri.parse(
          '${ApiService.baseUrl}/doacoes',
        ),
        headers: ApiService.authHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {

        final List<dynamic> jsonList =
            jsonDecode(response.body);

        return jsonList
            .map(
              (e) => DoacaoModel.fromJson(e),
            )
            .toList();
      }

      return [];

    } catch (e) {

      return [];

    }
  }

  // =========================
  // CRIAR
  // =========================

  static Future<bool> criarDoacao({

    required String nome,
    required String descricao,
    required int quantidade,

  }) async {

    try {

      // Timeout de 10s; o TimeoutException cai no catch abaixo.
      final response = await http.post(

        Uri.parse(
          '${ApiService.baseUrl}/doacoes',
        ),

        headers: ApiService.jsonHeaders(),

        body: jsonEncode({

          'nome': nome,
          'descricao': descricao,
          'quantidade': quantidade,

          'categoria': 'Alimentos',
          'tipo': 'Doação',
          'urgente': false,
          'novo': true,

        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200
          || response.statusCode == 201;

    } catch (e) {

      return false;

    }
  }
}