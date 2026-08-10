import 'dart:convert';

import 'package:http/http.dart' as http;


/// Uma sugestão de endereço real vinda do geocoder (OpenStreetMap/Nominatim).
class EnderecoSugestao {
  /// Endereço conciso para preencher o campo (cabe em 255 chars).
  final String descricao;

  /// Texto completo (display_name) — mostrado na lista de sugestões.
  final String descricaoCompleta;

  final double lat;
  final double lng;

  /// Cidade detectada (quando disponível), só informativo.
  final String? cidade;

  const EnderecoSugestao({
    required this.descricao,
    required this.descricaoCompleta,
    required this.lat,
    required this.lng,
    this.cidade,
  });
}

/// Autocomplete/validação de endereço usando o **Nominatim** (OpenStreetMap) —
/// serviço GRATUITO e sem chave, da mesma família dos mapas OSM que o front web
/// já usa (Leaflet). Escolher uma sugestão garante que o endereço EXISTE e nos
/// dá latitude/longitude para o mapa apontar o local exato.
///
/// Política de uso do Nominatim respeitada: no máximo ~1 requisição/segundo
/// (por isso o campo faz debounce de ~550ms) e um User-Agent identificando o
/// app (obrigatório; requisições sem ele são bloqueadas).
class GeocodingService {
  static const _base = 'https://nominatim.openstreetmap.org/search';
  static const _userAgent =
      'ConnectONG-Desktop/1.0 (TCC COTIL/UNICAMP; contato echinelat@gmail.com)';

  /// Busca endereços reais.
  ///
  /// [cidade] e [uf], quando informadas, ANCORAM a consulta na localidade da
  /// ONG: digitar "cotil" passa a procurar "cotil, Limeira, SP" em vez de
  /// varrer o Brasil inteiro. Sem isso o Nominatim devolvia ruas homônimas de
  /// outros estados no topo, e a pessoa não achava a própria rua.
  Future<List<EnderecoSugestao>> buscar(
    String consulta, {
    String? cidade,
    String? uf,
  }) async {
    final q = consulta.trim();
    if (q.length < 4) return const [];

    // Só acrescenta a cidade/UF se a pessoa ainda não as digitou.
    final alvo = _semAcento(q).toLowerCase();
    final termos = <String>[q];
    final c = (cidade ?? '').trim();
    final u = (uf ?? '').trim();
    if (c.isNotEmpty && !alvo.contains(_semAcento(c).toLowerCase())) {
      termos.add(c);
    }
    if (u.isNotEmpty && !alvo.contains(_semAcento(u).toLowerCase())) {
      termos.add(u);
    }

    final uri = Uri.parse(_base).replace(queryParameters: {
      'q': termos.join(', '),
      'format': 'jsonv2',
      'addressdetails': '1',
      'countrycodes': 'br', // só endereços do Brasil
      // 8 resultados: sobra margem para ordenar por relevância e ainda mostrar
      // as 6 melhores.
      'limit': '8',
      'accept-language': 'pt-BR',
    });

    // Nominatim (OpenStreetMap) e um servico DE TERCEIROS: nao usa o timeout
    // adaptativo da nossa API (que espera o Render acordar) nem o cliente que
    // repete — o Nominatim limita requisicoes e repetir levaria a bloqueio.
    final resp = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) return const [];

    final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
    if (decoded is! List) return const [];

    final sugestoes = decoded
        .whereType<Map<String, dynamic>>()
        .map(_daJson)
        .whereType<EnderecoSugestao>()
        .toList();

    // Relevância: o que está na cidade da ONG vem primeiro; depois o que
    // começa com o texto digitado (e não apenas contém). O Nominatim ordena
    // por "importância" do lugar, que costuma jogar a capital do estado para
    // cima mesmo quando a pessoa procura uma rua da própria cidade.
    final cidadeAlvo = _semAcento((cidade ?? '').trim()).toLowerCase();
    final digitado = _semAcento(q).toLowerCase();
    int pontos(EnderecoSugestao s) {
      var p = 0;
      final desc = _semAcento(s.descricao).toLowerCase();
      if (cidadeAlvo.isNotEmpty &&
          _semAcento(s.cidade ?? '').toLowerCase() == cidadeAlvo) {
        p += 10;
      }
      if (desc.startsWith(digitado)) p += 4;
      if (desc.contains(digitado)) p += 2;
      return p;
    }

    sugestoes.sort((a, b) => pontos(b).compareTo(pontos(a)));
    return sugestoes.take(6).toList();
  }

  /// Comparação sem acento (o Nominatim devolve "São Paulo", a pessoa digita
  /// "sao paulo").
  static String _semAcento(String s) {
    const de = 'áàâãäéèêëíìîïóòôõöúùûüçÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇ';
    const para = 'aaaaaeeeeiiiiooooouuuucAAAAAEEEEIIIIOOOOOUUUUC';
    final sb = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      final i = de.indexOf(ch);
      sb.write(i >= 0 ? para[i] : ch);
    }
    return sb.toString();
  }

  EnderecoSugestao? _daJson(Map<String, dynamic> j) {
    final lat = double.tryParse('${j['lat']}');
    final lng = double.tryParse('${j['lon']}');
    if (lat == null || lng == null) return null;

    final addr = (j['address'] as Map?)?.cast<String, dynamic>() ?? const {};
    String s(String k) => '${addr[k] ?? ''}'.trim();

    final rua = s('road').isNotEmpty
        ? s('road')
        : (s('pedestrian').isNotEmpty ? s('pedestrian') : s('cycleway'));
    final numero = s('house_number');
    final bairro = s('suburb').isNotEmpty
        ? s('suburb')
        : (s('neighbourhood').isNotEmpty ? s('neighbourhood') : s('city_district'));
    final cidade = s('city').isNotEmpty
        ? s('city')
        : (s('town').isNotEmpty
            ? s('town')
            : (s('village').isNotEmpty ? s('village') : s('municipality')));

    // Monta um endereço conciso e legível (cabe em 255):
    // "Rua Tal, 123 - Bairro - Cidade".
    final partes = <String>[];
    if (rua.isNotEmpty) partes.add(numero.isNotEmpty ? '$rua, $numero' : rua);
    if (bairro.isNotEmpty) partes.add(bairro);
    if (cidade.isNotEmpty) partes.add(cidade);

    final completo = '${j['display_name'] ?? ''}';
    var conciso = partes.isNotEmpty ? partes.join(' - ') : completo;
    if (conciso.length > 255) conciso = conciso.substring(0, 255);

    return EnderecoSugestao(
      descricao: conciso,
      descricaoCompleta: completo.isNotEmpty ? completo : conciso,
      lat: lat,
      lng: lng,
      cidade: cidade.isNotEmpty ? cidade : null,
    );
  }
}
