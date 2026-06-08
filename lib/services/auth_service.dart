import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

class AuthService {

  Future<bool> login(
    String email,
    String senha,
  ) async {

    try {

      final response = await http.post(

        Uri.parse(
          '${ApiService.baseUrl}/usuarios/login',
        ),

        headers: {
          'Content-Type': 'application/json',
        },

        body: jsonEncode({

          'email': email,
          'senha': senha,

        }),
      );

      return response.statusCode == 200;

    } catch (e) {

      return false;

    }
  }
}