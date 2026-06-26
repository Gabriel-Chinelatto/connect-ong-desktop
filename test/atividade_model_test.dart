import 'package:flutter_test/flutter_test.dart';
import 'package:connect_ong/models/atividade.dart';

void main() {
  group('Atividade.fromJson', () {
    test('le os campos da resposta da API', () {
      final a = Atividade.fromJson({
        'id': 12,
        'tipo': 'CAMPANHA',
        'descricao': 'A campanha "Natal Solidario" atingiu a meta!',
        'ongId': 4,
        'ongNome': 'Lar Viva',
        'dataCriacao': '2026-06-26T14:30:00',
      });

      expect(a.id, 12);
      expect(a.tipo, 'CAMPANHA');
      expect(a.descricao, 'A campanha "Natal Solidario" atingiu a meta!');
      expect(a.ongId, 4);
      expect(a.ongNome, 'Lar Viva');
      expect(a.dataCriacao, '2026-06-26T14:30:00');
    });

    test('usa defaults e aceita nulos quando campos vem ausentes', () {
      final a = Atividade.fromJson({'id': 1});

      expect(a.id, 1);
      expect(a.tipo, '');
      expect(a.descricao, '');
      expect(a.ongId, isNull);
      expect(a.ongNome, isNull);
      expect(a.dataCriacao, isNull);
    });
  });
}
