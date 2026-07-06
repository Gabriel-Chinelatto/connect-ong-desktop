import 'package:flutter_test/flutter_test.dart';

import 'package:connect_ong/models/bloqueio.dart';
import 'package:connect_ong/models/interesse.dart';

/// Contratos do bloqueio de doadores (GET /bloqueios) e do campo novo
/// `bloqueadoPelaOng` no GET /interesses?ongId= — com ênfase na degradação
/// graciosa quando o backend antigo não envia os campos.
void main() {
  group('Bloqueio.fromJson', () {
    test('parse do contrato completo', () {
      final b = Bloqueio.fromJson({
        'doadorId': 7,
        'doadorNome': 'Maria Silva',
        'criadoEm': '2026-07-01T10:00:00',
      });
      expect(b.doadorId, 7);
      expect(b.doadorNome, 'Maria Silva');
      expect(b.criadoEm, '2026-07-01T10:00:00');
    });

    test('nome vazio/ausente vira "Doador" e criadoEm pode faltar', () {
      final b = Bloqueio.fromJson({'doadorId': 3, 'doadorNome': '  '});
      expect(b.doadorNome, 'Doador');
      expect(b.criadoEm, isNull);
    });
  });

  group('Interesse.bloqueadoPelaOng', () {
    test('campo ausente (backend antigo) = não bloqueado', () {
      final it = Interesse.fromJson({'id': 1, 'status': 'ACEITO'});
      expect(it.bloqueadoPelaOng, isFalse);
    });

    test('true só quando o backend manda true', () {
      final sim = Interesse.fromJson(
          {'id': 1, 'status': 'ACEITO', 'bloqueadoPelaOng': true});
      final nao = Interesse.fromJson(
          {'id': 2, 'status': 'ACEITO', 'bloqueadoPelaOng': false});
      final lixo = Interesse.fromJson(
          {'id': 3, 'status': 'ACEITO', 'bloqueadoPelaOng': 'sim'});
      expect(sim.bloqueadoPelaOng, isTrue);
      expect(nao.bloqueadoPelaOng, isFalse);
      expect(lixo.bloqueadoPelaOng, isFalse);
    });
  });
}
