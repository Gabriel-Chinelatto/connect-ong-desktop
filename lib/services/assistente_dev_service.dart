import 'dart:convert';


import 'api_service.dart';

/// Resposta do assistente "Sobre o Desenvolvimento" (POST /assistente-dev):
/// o texto a exibir e o [modo] ('ia' = modelo; 'regras' = fallback local).
class RespostaDev {
  final String resposta;
  final String modo;

  const RespostaDev({required this.resposta, this.modo = 'ia'});

  bool get modoRegras => modo.toLowerCase() == 'regras';

  factory RespostaDev.fromJson(Map<String, dynamic> j) => RespostaDev(
        resposta: (j['resposta'] ?? '').toString(),
        modo: (j['modo'] ?? 'ia').toString(),
      );
}

/// Cliente do chat "Sobre o Desenvolvimento": explica COMO o Connect ONG foi
/// construido (stack, metodos, decisoes, historico de versoes). Fala com
/// `POST /assistente-dev` — IA ancorada num documento curado do projeto, com
/// fallback por regras. Rota PUBLICA. Falha de rede vira mensagem amigavel.
class AssistenteDevService {
  Future<RespostaDev> perguntar({
    required String mensagem,
    List<Map<String, String>> historico = const [],
  }) async {
    try {
      final resp = await ApiService.rede
          .post(
            Uri.parse('${ApiService.baseUrl}/assistente-dev'),
            headers: ApiService.jsonHeaders(),
            body: jsonEncode({
              'mensagem': mensagem,
              'historico': historico,
            }),
          )
          .timeout(ApiService.timeoutPesado);
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('O assistente esta indisponivel no momento.');
      }
      final json =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return RespostaDev.fromJson(json);
    } catch (e) {
      throw Exception(ApiService.mensagemAmigavel(e));
    }
  }
}
