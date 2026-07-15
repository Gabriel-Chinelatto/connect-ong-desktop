import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Base de toda a comunicacao HTTP com a API Spring Boot.
///
/// Centraliza: a [baseUrl] do backend, o token JWT de acesso (mantido apenas
/// em memoria) e a montagem dos cabecalhos `Authorization: Bearer <token>`
/// que autenticam cada requisicao. Como o token nao e persistido em disco,
/// o app desktop exige um novo login a cada abertura. Os servicos especificos
/// reutilizam estes cabecalhos e aplicam um timeout de 10s em cada chamada.
class ApiService {

  /// Converte qualquer erro capturado em uma mensagem amigavel para o usuario.
  /// Usar em catches de UI no lugar de expor `e.toString()` cru.
  static String mensagemAmigavel(Object erro) {
    if (erro is TimeoutException) {
      return 'O servidor demorou a responder. Tente novamente.';
    }
    if (erro is SocketException || erro is http.ClientException) {
      return 'Não foi possível conectar ao servidor. Verifique sua conexão.';
    }
    return erro.toString().replaceFirst('Exception: ', '');
  }

  // Endereco base da API (backend Spring Boot).
  //
  // PADRAO = API NA NUVEM (Render): o painel funciona em qualquer maquina, sem
  // precisar rodar o backend localmente.
  //
  // Para desenvolver com o backend local (mais rapido, sem latencia):
  //   flutter run -d windows --dart-define=API_BASE=http://localhost:8080
  static const String baseUrl = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://connect-ong-api.onrender.com',
  );

  // Token JWT de acesso, mantido apenas em memoria (sem persistencia em disco).
  // O app desktop nao guarda sessao: o usuario faz login a cada abertura.
  static String? _accessToken;

  static String? get accessToken => _accessToken;

  // Chave reservada para uma futura persistencia (ex.: SharedPreferences).
  // ignore: unused_field
  static const String _tokenKey = 'access_token';

  /// Define (ou limpa, se [token] for null) o token de acesso em memoria.
  /// Mantem a assinatura async por consistencia, facilitando plugar
  /// persistencia depois sem alterar quem chama.
  static Future<void> setToken(String? token) async {
    _accessToken = token;
  }

  /// Carrega o token na inicializacao. No-op por enquanto (sem persistencia):
  /// existe para facilitar plugar SharedPreferences no futuro.
  static Future<void> carregarToken() async {
    // Sem persistencia: nada a carregar.
    return;
  }

  /// Cabecalhos JSON com o token (quando houver), para POST/PUT com corpo JSON.
  static Map<String, String> jsonHeaders() => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Cabecalhos apenas com o token (quando houver), para GET/DELETE sem corpo.
  static Map<String, String> authHeaders() => {
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

}
