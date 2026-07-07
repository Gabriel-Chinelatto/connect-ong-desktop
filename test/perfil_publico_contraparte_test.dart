import 'package:flutter_test/flutter_test.dart';
import 'package:connect_ong/models/perfil_publico_doador.dart';
import 'package:connect_ong/models/perfil_publico_ong.dart';

void main() {
  group('PerfilPublicoDoador contato', () {
    test('lê email/telefone quando o backend os envia', () {
      final p = PerfilPublicoDoador.fromJson({
        'id': 7,
        'nome': 'Ana',
        'email': 'ana@exemplo.com',
        'telefone': '(11) 99999-0000',
      });
      expect(p.email, 'ana@exemplo.com');
      expect(p.telefone, '(11) 99999-0000');
    });

    test('email/telefone ausentes ou vazios viram null (privacidade)', () {
      final semCampo = PerfilPublicoDoador.fromJson({'id': 1, 'nome': 'Bia'});
      expect(semCampo.email, isNull);
      expect(semCampo.telefone, isNull);

      final vazio = PerfilPublicoDoador.fromJson(
          {'id': 2, 'nome': 'Cida', 'email': '  ', 'telefone': ''});
      expect(vazio.email, isNull);
      expect(vazio.telefone, isNull);
    });
  });

  group('Contraparte nas prestações', () {
    test('PrestacaoRecebida lê ongId (para link/agrupamento)', () {
      final pr = PrestacaoRecebida.fromJson({
        'titulo': 'Compra de cobertores',
        'descricao': 'ok',
        'ongId': 42,
        'ongNome': 'Casa do Bem',
      });
      expect(pr.ongId, 42);
      expect(pr.ongNome, 'Casa do Bem');
    });

    test('PrestacaoRecebida degrada com ongId ausente', () {
      final pr = PrestacaoRecebida.fromJson({'titulo': 't', 'descricao': 'd'});
      expect(pr.ongId, isNull);
    });

    test('PrestacaoResumo lê doadorId/doadorNome', () {
      final pr = PrestacaoResumo.fromJson({
        'titulo': 'Entrega feita',
        'descricao': 'ok',
        'doadorId': 9,
        'doadorNome': 'Ana',
      });
      expect(pr.doadorId, 9);
      expect(pr.doadorNome, 'Ana');
    });

    test('PrestacaoResumo degrada com doadorId ausente', () {
      final pr = PrestacaoResumo.fromJson({'titulo': 't', 'descricao': 'd'});
      expect(pr.doadorId, isNull);
      expect(pr.doadorNome, isNull);
    });
  });
}
