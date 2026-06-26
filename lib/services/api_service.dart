class ApiService {

  static const String baseUrl =
      'http://localhost:8080';

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
