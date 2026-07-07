import 'package:flutter_test/flutter_test.dart';

import 'package:connect_ong/models/preferencia.dart';

void main() {
  group('Preferencia.doisFatores (2FA)', () {
    test('fromJson lê o campo doisFatores quando presente', () {
      final p = Preferencia.fromJson({'doisFatores': true});
      expect(p.doisFatores, isTrue);
    });

    test('campo ausente (backend antigo) = desligado', () {
      final p = Preferencia.fromJson({});
      expect(p.doisFatores, isFalse);
    });

    test('toJson inclui doisFatores (round-trip preserva o valor)', () {
      final p = Preferencia(doisFatores: true);
      expect(p.toJson()['doisFatores'], isTrue);
      final volta = Preferencia.fromJson(p.toJson());
      expect(volta.doisFatores, isTrue);
    });

    test('copy() preserva doisFatores', () {
      final p = Preferencia(doisFatores: true).copy();
      expect(p.doisFatores, isTrue);
    });
  });
}
