import 'package:flutter_test/flutter_test.dart';
import 'package:connect_ong/models/doacao_financeira.dart';

void main() {
  group('DoacaoFinanceira.fromJson', () {
    test('le os campos da resposta da API (sem codigoPix, omitido p/ ONG)',
        () {
      final d = DoacaoFinanceira.fromJson({
        'id': 7,
        'ongId': 4,
        'ongNome': 'Lar Viva',
        'doadorNome': 'Maria Silva',
        'valor': 150.5,
        'status': 'CONFIRMADO',
        'dataCriacao': '2026-07-02T14:30:00',
      });

      expect(d.id, 7);
      expect(d.doadorNome, 'Maria Silva');
      expect(d.valor, 150.5);
      expect(d.status, 'CONFIRMADO');
      expect(d.dataCriacao, '2026-07-02T14:30:00');
      expect(d.data, DateTime(2026, 7, 2, 14, 30));
    });

    test('usa defaults quando campos vem ausentes ou nulos', () {
      final d = DoacaoFinanceira.fromJson({});

      expect(d.id, 0);
      expect(d.doadorNome, 'Doador');
      expect(d.valor, 0);
      expect(d.status, '');
      expect(d.dataCriacao, isNull);
      expect(d.data, isNull);
    });

    test('aceita valor inteiro (num) vindo do JSON', () {
      final d = DoacaoFinanceira.fromJson({'id': 1, 'valor': 200});
      expect(d.valor, 200.0);
    });

    test('data invalida vira null (nao quebra a lista)', () {
      final d = DoacaoFinanceira.fromJson(
          {'id': 1, 'dataCriacao': 'nao-e-data'});
      expect(d.data, isNull);
    });
  });
}
