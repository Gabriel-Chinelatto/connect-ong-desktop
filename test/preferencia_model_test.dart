import 'package:flutter_test/flutter_test.dart';

import 'package:connect_ong/models/preferencia.dart';

void main() {
  group('Preferencia.doisFatores (2FA)', () {
    test('fromJson lê o campo doisFatores como INTEIRO (contrato do backend)', () {
      expect(Preferencia.fromJson({'doisFatores': 1}).doisFatores, isTrue);
      expect(Preferencia.fromJson({'doisFatores': 0}).doisFatores, isFalse);
    });

    test('fromJson aceita boolean por robustez (versoes antigas)', () {
      expect(Preferencia.fromJson({'doisFatores': true}).doisFatores, isTrue);
      expect(Preferencia.fromJson({'doisFatores': false}).doisFatores, isFalse);
    });

    test('campo ausente/null (backend antigo) = desligado', () {
      expect(Preferencia.fromJson({}).doisFatores, isFalse);
      expect(Preferencia.fromJson({'doisFatores': null}).doisFatores, isFalse);
    });

    test('toJson serializa doisFatores como 1/0 (o backend rejeita boolean)', () {
      expect(Preferencia(doisFatores: true).toJson()['doisFatores'], 1);
      expect(Preferencia(doisFatores: false).toJson()['doisFatores'], 0);
      // Round-trip preserva o valor logico.
      final volta = Preferencia.fromJson(Preferencia(doisFatores: true).toJson());
      expect(volta.doisFatores, isTrue);
    });

    test('copy() preserva doisFatores', () {
      final p = Preferencia(doisFatores: true).copy();
      expect(p.doisFatores, isTrue);
    });
  });
}
