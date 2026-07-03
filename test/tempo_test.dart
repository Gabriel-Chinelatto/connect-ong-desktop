import 'package:flutter_test/flutter_test.dart';
import 'package:connect_ong/utils/tempo.dart';

void main() {
  group('formatarVistoPorUltimo', () {
    // Relogio fixo para os testes: 03/07/2026 20:00 (fuso local).
    final agora = DateTime(2026, 7, 3, 20, 0);
    int epoch(DateTime d) => d.millisecondsSinceEpoch;

    test('online tem prioridade sobre tudo', () {
      final r = formatarVistoPorUltimo(
        online: true,
        ultimoVistoEpoch: epoch(DateTime(2026, 7, 1, 10, 0)),
        agora: agora,
      );
      expect(r, 'online');
    });

    test('visto hoje -> "visto por último às HH:mm"', () {
      final r = formatarVistoPorUltimo(
        online: false,
        ultimoVistoEpoch: epoch(DateTime(2026, 7, 3, 14, 5)),
        agora: agora,
      );
      expect(r, 'visto por último às 14:05');
    });

    test('visto ontem -> "ontem às HH:mm"', () {
      final r = formatarVistoPorUltimo(
        online: false,
        ultimoVistoEpoch: epoch(DateTime(2026, 7, 2, 9, 30)),
        agora: agora,
      );
      expect(r, 'ontem às 09:30');
    });

    test('mais antigo -> "em dd/MM às HH:mm"', () {
      final r = formatarVistoPorUltimo(
        online: false,
        ultimoVistoEpoch: epoch(DateTime(2026, 6, 28, 7, 8)),
        agora: agora,
      );
      expect(r, 'em 28/06 às 07:08');
    });

    test('sem epoch e offline -> vazio', () {
      final r = formatarVistoPorUltimo(
        online: false,
        ultimoVistoEpoch: null,
        agora: agora,
      );
      expect(r, '');
    });
  });
}
