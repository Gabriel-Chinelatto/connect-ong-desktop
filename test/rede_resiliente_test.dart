import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:connect_ong/services/api_service.dart';

/// Regras da camada de rede do painel, criadas depois de dois incidentes reais:
///
/// - 2026-08-03: o Render (plano gratuito) hiberna apos ~15 min parado e a
///   primeira chamada levou 95s. Com timeout fixo de 10s a tela sempre falhava.
/// - 2026-08-04: o Render ficou SEM DEPLOY ATIVO e devolveu 502 em 100% das
///   chamadas; o painel desistia na primeira tentativa e dizia ao usuario que
///   o problema era a conexao dele.
void main() {
  test('sem nenhuma resposta ainda, espera o tempo LONGO (servidor acordando)',
      () {
    expect(ApiService.apiPodeEstarDormindo, isTrue);
    expect(ApiService.timeout, const Duration(seconds: 100));
    expect(ApiService.timeoutPesado, const Duration(seconds: 100));
  });

  test('depois que a API responde, volta aos tempos CURTOS', () {
    ApiService.registrarResposta();

    expect(ApiService.apiPodeEstarDormindo, isFalse);
    expect(ApiService.timeout, const Duration(seconds: 12));
    // Upload de imagem e IA continuam com folga maior que as telas comuns.
    expect(ApiService.timeoutPesado, const Duration(seconds: 30));
  });

  group('servidor indisponivel (5xx de infraestrutura)', () {
    test('502, 503 e 504 valem uma nova tentativa', () {
      expect(ApiService.servidorIndisponivel(502), isTrue);
      expect(ApiService.servidorIndisponivel(503), isTrue);
      expect(ApiService.servidorIndisponivel(504), isTrue);
    });

    test('erros do proprio pedido NAO valem nova tentativa', () {
      for (final status in [200, 201, 400, 401, 403, 404, 409, 500]) {
        expect(ApiService.servidorIndisponivel(status), isFalse,
            reason: 'status $status nao e indisponibilidade de servidor');
      }
    });
  });

  test('mensagem de demora nao expoe o erro cru', () {
    final msg = ApiService.mensagemAmigavel(
      TimeoutException('Future not completed', const Duration(seconds: 12)),
    );
    expect(msg, isNot(contains('TimeoutException')));
    expect(msg, contains('servidor'));
  });
}
