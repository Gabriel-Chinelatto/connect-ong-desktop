import 'package:connect_ong/utils/validadores.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// F-02: as regras da tela. Os MESMOS casos de RegrasFormatoTest.java na API —
/// se um lado aceitar o que o outro recusa, o usuário vê "salvo" e a API diz 400.
void main() {
  group('telefone', () {
    for (final t in [
      '(19) 99876-5432',
      '19998765432',
      '+55 19 99876-5432',
      '(19) 3451-2000',
      '11 2345-6789',
    ]) {
      test('aceita $t', () => expect(Validadores.telefone(t), isNull));
    }
    for (final t in [
      'abc',
      '123',
      '(19) 8888-7777',
      '(00) 99876-5432',
      '(19) 89876-5432',
      '(19) 99999-9999',
    ]) {
      test('recusa $t', () => expect(Validadores.telefone(t), isNotNull));
    }
    test(
      'vazio é válido (opcional)',
      () => expect(Validadores.telefone(''), isNull),
    );
  });

  group('cnpj', () {
    for (final c in [
      '11.222.333/0001-81',
      '11222333000181',
      '12.ABC.345/01DE-35',
    ]) {
      test('aceita $c', () => expect(Validadores.cnpj(c), isNull));
    }
    for (final c in [
      '11.222.333/0001-82',
      '00.000.000/0000-00',
      '1234',
      'abcdefghijklmn',
    ]) {
      test('recusa $c', () => expect(Validadores.cnpj(c), isNotNull));
    }
  });

  test('texto legível', () {
    expect(Validadores.textoLegivel('Cestas básicas para 30 famílias'), isNull);
    expect(Validadores.textoLegivel('!!!!'), isNotNull);
    expect(Validadores.textoLegivel('12345'), isNotNull);
    expect(Validadores.textoLegivel('<script>alert(1)</script>'), isNotNull);
  });

  test('nome próprio', () {
    expect(Validadores.nomeProprio("João D'Ávila-Souza"), isNull);
    expect(Validadores.nomeProprio('Jo4o'), isNotNull);
    expect(Validadores.nomeProprio('@@@'), isNotNull);
  });

  test('senha forte', () {
    expect(Validadores.senhaForte('doacao2026'), isNull);
    expect(Validadores.senhaForte('123456'), isNotNull);
    expect(Validadores.senhaForte('abcdefgh'), isNotNull);
    expect(Validadores.senhaForte('12345678'), isNotNull);
    expect(Validadores.senhaForte('Senha123'), isNotNull);
  });

  test('máscaras', () {
    TextEditingValue f(TextInputFormatter m, String s) =>
        m.formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: s));
    expect(f(TelefoneInputFormatter(), '19998765432').text, '(19) 99876-5432');
    expect(f(TelefoneInputFormatter(), '1934512000').text, '(19) 3451-2000');
    expect(
      f(CnpjInputFormatter(), '11222333000181').text,
      '11.222.333/0001-81',
    );
  });
}
