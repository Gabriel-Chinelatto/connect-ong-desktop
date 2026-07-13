import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Resultado da redação assistida por IA de uma necessidade: um título curto e
/// uma descrição reescrita a partir do rascunho da ONG. [modo] = 'ia' quando o
/// modelo respondeu; 'regras' quando caiu no fallback local (sem chave de IA).
class RedacaoIA {
  final String titulo;
  final String descricao;
  final String modo;

  const RedacaoIA({
    required this.titulo,
    required this.descricao,
    required this.modo,
  });

  bool get modoRegras => modo.toLowerCase() == 'regras';

  factory RedacaoIA.fromJson(Map<String, dynamic> j) => RedacaoIA(
        titulo: (j['titulo'] ?? '').toString(),
        descricao: (j['descricao'] ?? '').toString(),
        modo: (j['modo'] ?? 'regras').toString(),
      );
}

/// Resultado da redação/refino do "Sobre" (descrição institucional) da ONG.
class SobreOngIA {
  final String descricao;
  final String modo;

  const SobreOngIA({required this.descricao, required this.modo});

  bool get modoRegras => modo.toLowerCase() == 'regras';

  factory SobreOngIA.fromJson(Map<String, dynamic> j) => SobreOngIA(
        descricao: (j['descricao'] ?? '').toString(),
        modo: (j['modo'] ?? 'regras').toString(),
      );
}

/// Cliente das funções de IA do painel da ONG. Hoje: redigir uma necessidade
/// clara e convincente para os doadores a partir de um rascunho (`POST
/// /ia/redacao`), e escrever/refinar o "Sobre" da ONG com loop de ajuste
/// (`POST /ia/sobre-ong`). A chave da IA fica no backend (gratuita, Groq); sem
/// chave o backend responde no modo "regras". Qualquer falha vira mensagem
/// amigável.
class IaService {
  Future<RedacaoIA> redigirNecessidade({
    String? titulo,
    required String rascunho,
    String? categoria,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/ia/redacao'),
            headers: ApiService.jsonHeaders(),
            body: jsonEncode({
              if (titulo != null && titulo.isNotEmpty) 'titulo': titulo,
              'rascunho': rascunho,
              if (categoria != null && categoria.isNotEmpty)
                'categoria': categoria,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Não foi possível redigir com IA agora.');
      }
      final json =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return RedacaoIA.fromJson(json);
    } catch (e) {
      throw Exception(ApiService.mensagemAmigavel(e));
    }
  }

  /// Escreve/refina o "Sobre" da ONG. Na 1ª chamada [rascunho] é o texto base
  /// que a ONG digitou e [ajuste] fica vazio; nas seguintes, [rascunho] é a
  /// sugestão anterior e [ajuste] é o que a ONG pediu para mudar ("mais curto",
  /// "mencione que atendemos crianças"...). O backend ancora nos DADOS REAIS da
  /// ONG (nome, cidade, categorias...) para não inventar informação.
  Future<SobreOngIA> escreverSobre({
    required int ongId,
    String? rascunho,
    String? ajuste,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/ia/sobre-ong'),
            headers: ApiService.jsonHeaders(),
            body: jsonEncode({
              'ongId': ongId,
              if (rascunho != null && rascunho.isNotEmpty) 'rascunho': rascunho,
              if (ajuste != null && ajuste.isNotEmpty) 'ajuste': ajuste,
            }),
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception('Não foi possível gerar o texto agora.');
      }
      final json =
          jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
      return SobreOngIA.fromJson(json);
    } catch (e) {
      throw Exception(ApiService.mensagemAmigavel(e));
    }
  }
}
