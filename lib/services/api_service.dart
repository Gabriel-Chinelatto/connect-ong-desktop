import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

/// Base de toda a comunicacao HTTP com a API Spring Boot.
///
/// Centraliza: a [baseUrl] do backend, o token JWT de acesso (mantido apenas
/// em memoria) e a montagem dos cabecalhos `Authorization: Bearer <token>`
/// que autenticam cada requisicao. Como o token nao e persistido em disco,
/// o app desktop exige um novo login a cada abertura. Os servicos especificos
/// reutilizam estes cabecalhos, o cliente [rede] (que repete leituras) e o
/// timeout adaptativo em cada chamada.
class ApiService {

  // ---------------------------------------------------------------------------
  // TIMEOUT ADAPTATIVO + REPETICAO
  //
  // O backend hospedado roda no plano gratuito do Render, que desliga o servico
  // apos ~15 min sem acesso: a primeira chamada precisa esperar o servidor subir
  // (medido em 2026-08-03: 95s). Com timeout fixo a primeira tela falhava
  // sempre. E em 2026-08-04 o Render ficou sem deploy ativo e devolveu 502 em
  // 100% das chamadas — o painel desistia na primeira tentativa.
  // ---------------------------------------------------------------------------

  /// Espera normal, com a API no ar e respondendo.
  static const Duration _timeoutNormal = Duration(seconds: 12);

  /// Espera para operacoes PESADAS (upload de imagem, IA).
  static const Duration _timeoutPesadoNormal = Duration(seconds: 30);

  /// Espera enquanto o servidor pode estar saindo da hibernacao.
  static const Duration _timeoutAcordando = Duration(seconds: 100);

  /// Depois deste tempo sem NENHUMA resposta, tratamos a API como possivelmente
  /// adormecida de novo (o Render dorme com ~15 min de ociosidade).
  static const Duration _janelaAcordada = Duration(minutes: 12);

  static DateTime? _ultimaResposta;

  /// true quando ainda nao houve resposta nesta sessao (ou faz tempo demais).
  static bool get apiPodeEstarDormindo {
    final ultima = _ultimaResposta;
    return ultima == null ||
        DateTime.now().difference(ultima) > _janelaAcordada;
  }

  /// Timeout padrao das chamadas: generoso enquanto o servidor pode estar
  /// acordando, curto depois que ele provou estar no ar.
  static Duration get timeout =>
      apiPodeEstarDormindo ? _timeoutAcordando : _timeoutNormal;

  /// Timeout das operacoes pesadas (upload, IA), pela mesma regra.
  static Duration get timeoutPesado =>
      apiPodeEstarDormindo ? _timeoutAcordando : _timeoutPesadoNormal;

  /// Registra que a API respondeu (usado pelo cliente resiliente).
  static void registrarResposta() => _ultimaResposta = DateTime.now();

  /// Status de servidor INDISPONIVEL (nao e erro do que foi pedido): vale a
  /// pena tentar de novo.
  static bool servidorIndisponivel(int status) =>
      status == 502 || status == 503 || status == 504;

  /// Cliente HTTP usado por TODOS os servicos: repete automaticamente as
  /// LEITURAS (GET) quando o servidor esta indisponivel ou a rede falha.
  /// Escritas passam direto — repetir um POST criaria registros duplicados.
  static final http.Client rede = _ClienteResiliente();

  /// Acorda o servidor o quanto antes (chamado no start do painel). Erros sao
  /// ignorados de proposito: e um aquecimento, nao um passo obrigatorio.
  static void acordarServidor() async {
    try {
      await ApiService.rede.get(Uri.parse('$baseUrl/publico/estatisticas'))
          .timeout(_timeoutAcordando);
      registrarResposta();
    } catch (_) {
      // A propria tela tenta de novo e mostra o erro, se for o caso.
    }
  }

  /// Converte qualquer erro capturado em uma mensagem amigavel para o usuario.
  /// Usar em catches de UI no lugar de expor `e.toString()` cru.
  static String mensagemAmigavel(Object erro) {
    if (erro is TimeoutException) {
      return apiPodeEstarDormindo
          ? 'O servidor estava em repouso e ainda está iniciando. '
              'Aguarde alguns segundos e tente de novo.'
          : 'O servidor demorou a responder. Tente novamente.';
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

/// Cliente HTTP que REPETE automaticamente as leituras que falharam por culpa
/// do servidor (502/503/504) ou da rede, com espera crescente entre as
/// tentativas (1s, 2s).
///
/// So GET e repetido: ele e idempotente (nao cria nem altera nada). Repetir um
/// POST/PUT/DELETE poderia cadastrar a mesma necessidade duas vezes ou apagar
/// algo depois de ja ter apagado.
class _ClienteResiliente extends http.BaseClient {
  final http.Client _interno = http.Client();

  /// Tentativas EXTRAS alem da primeira.
  static const int _tentativasExtras = 2;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.method != 'GET') {
      final resposta = await _interno.send(request);
      ApiService.registrarResposta();
      return resposta;
    }

    Object? ultimoErro;
    for (int tentativa = 1; tentativa <= 1 + _tentativasExtras; tentativa++) {
      try {
        // GET nao tem corpo: da para remontar o pedido a cada tentativa (um
        // BaseRequest ja enviado nao pode ser reenviado).
        final novo = http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..followRedirects = request.followRedirects
          ..maxRedirects = request.maxRedirects;

        final resposta = await _interno.send(novo);
        ApiService.registrarResposta();

        if (ApiService.servidorIndisponivel(resposta.statusCode) &&
            tentativa <= _tentativasExtras) {
          await Future.delayed(Duration(seconds: tentativa));
          continue;
        }
        return resposta;
      } on SocketException catch (e) {
        ultimoErro = e;
      } on http.ClientException catch (e) {
        ultimoErro = e;
      }
      if (tentativa <= _tentativasExtras) {
        await Future.delayed(Duration(seconds: tentativa));
      }
    }
    throw ultimoErro!;
  }

  @override
  void close() {
    _interno.close();
    super.close();
  }
}
