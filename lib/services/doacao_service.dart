import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/doacao_model.dart';
import 'api_service.dart';

class DoacaoService {

  static Future<List<DoacaoModel>> listarDoacoes() async {

    try {

      final response = await http.get(

        Uri.parse(
          '${ApiService.baseUrl}/doacoes',
        ),
      );

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
}