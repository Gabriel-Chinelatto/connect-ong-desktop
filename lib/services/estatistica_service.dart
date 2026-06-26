import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Numeros publicos da plataforma (transparencia / mural de impacto).
class EstatisticasPublicas {
  final int totalOngs;
  final int totalDoadores;
  final int totalNecessidades;
  final int totalMatches;
  final int totalDoacoesFinanceiras;
  final double valorTotalDoado;
  final int totalPrestacoes;

  const EstatisticasPublicas({
    required this.totalOngs,
    required this.totalDoadores,
    required this.totalNecessidades,
    required this.totalMatches,
    required this.totalDoacoesFinanceiras,
    required this.valorTotalDoado,
    required this.totalPrestacoes,
  });

  factory EstatisticasPublicas.fromJson(Map<String, dynamic> j) {
    return EstatisticasPublicas(
      totalOngs: (j['totalOngs'] ?? 0) as int,
      totalDoadores: (j['totalDoadores'] ?? 0) as int,
      totalNecessidades: (j['totalNecessidades'] ?? 0) as int,
      totalMatches: (j['totalMatches'] ?? 0) as int,
      totalDoacoesFinanceiras: (j['totalDoacoesFinanceiras'] ?? 0) as int,
      valorTotalDoado: ((j['valorTotalDoado'] ?? 0) as num).toDouble(),
      totalPrestacoes: (j['totalPrestacoes'] ?? 0) as int,
    );
  }

  static const EstatisticasPublicas zero = EstatisticasPublicas(
    totalOngs: 0,
    totalDoadores: 0,
    totalNecessidades: 0,
    totalMatches: 0,
    totalDoacoesFinanceiras: 0,
    valorTotalDoado: 0,
    totalPrestacoes: 0,
  );
}

class EstatisticaService {
  static const String _url = '${ApiService.baseUrl}/publico/estatisticas';

  Future<EstatisticasPublicas> carregar() async {
    // Timeout de 10s para nao travar a UI se o servidor nao responder.
    final response = await http
        .get(Uri.parse(_url), headers: ApiService.authHeaders())
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 200) {
      return EstatisticasPublicas.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    }
    throw Exception('Erro ao carregar estatisticas');
  }
}
