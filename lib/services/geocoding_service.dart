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

  Future<List<EnderecoSugestao>> buscar(String consulta) async {
    final q = consulta.trim();
    if (q.length < 4) return const [];

    final uri = Uri.parse(_base).replace(queryParameters: {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': '1',
      'countrycodes': 'br', // só endereços do Brasil
      'limit': '6',
      'accept-language': 'pt-BR',
    });

    final resp = await http
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(const Duration(seconds: 8));

    if (resp.statusCode != 200) return const [];

    final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_daJson)
        .whereType<EnderecoSugestao>()
        .toList();
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
