import 'package:flutter_test/flutter_test.dart';
import 'package:connect_ong/models/ong.dart';

void main() {
  group('Ong.fromJson', () {
    test('le os campos da resposta da API', () {
      final ong = Ong.fromJson({
        'id': 3,
        'nome': 'Casa do Bem',
        'email': 'casa@bem.org',
        'cidade': 'Campinas',
      });

      expect(ong.id, 3);
      expect(ong.nome, 'Casa do Bem');
      expect(ong.email, 'casa@bem.org');
      expect(ong.cidade, 'Campinas');
    });

    test('usa defaults quando campos de texto vem nulos', () {
      final ong = Ong.fromJson({'id': 1});

      expect(ong.id, 1);
      expect(ong.nome, '');
      expect(ong.email, '');
      expect(ong.cidade, '');
    });
  });
}
