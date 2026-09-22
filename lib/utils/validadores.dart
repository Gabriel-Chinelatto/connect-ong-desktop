import 'package:flutter/services.dart';

/// Regras de formato dos campos (item F-01/F-02 do Plano de Ação — o
/// avaliador da FECITEC: "não tinha validações nos campos, podia colocar o que
/// quisesse em tudo").
///
/// ESPELHO de `validacao/Regras.java` na API: a mesma regra aqui (erro embaixo
/// do campo, antes de enviar) e lá (a palavra final — qualquer um pode chamar a
/// API sem passar pela tela). Se mudar uma, mude a outra. O mesmo arquivo
/// existe no app do doador (`connect-ong/lib/utils/validadores.dart`).
///
/// Cada função devolve a MENSAGEM de erro, ou `null` se estiver tudo certo —
/// o formato que o `validator:` do `TextFormField` espera. Campo vazio é
/// válido aqui; obrigatoriedade é com [obrigatorio].
class Validadores {
  Validadores._();

  static const _ddds = {
    11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 24, 27, 28, //
    31, 32, 33, 34, 35, 37, 38, 41, 42, 43, 44, 45, 46, 47, 48, 49,
    51, 53, 54, 55, 61, 62, 63, 64, 65, 66, 67, 68, 69,
    71, 73, 74, 75, 77, 79, 81, 82, 83, 84, 85, 86, 87, 88, 89,
    91, 92, 93, 94, 95, 96, 97, 98, 99,
  };

  static const _senhasComuns = {
    'senha123',
    'senha1234',
    'password1',
    'abc12345',
    'abcd1234',
    'qwerty123',
    '12345678a',
    'a12345678',
    'admin123',
    'mudar123',
    'brasil123',
    'teste123',
  };

  static const _pesosCnpj1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  static const _pesosCnpj2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  static final _letra = RegExp(r'\p{L}', unicode: true);
  static final _nomeProprio = RegExp(r"^[\p{L}\s'’.\-]+$", unicode: true);

  static bool _vazio(String? s) => s == null || s.trim().isEmpty;

  static String? obrigatorio(String? v, [String rotulo = 'Este campo']) =>
      _vazio(v) ? '$rotulo é obrigatório.' : null;

  /// Aplica várias regras em ordem e devolve o primeiro erro.
  static String? todas(String? v, List<String? Function(String?)> regras) {
    for (final r in regras) {
      final erro = r(v);
      if (erro != null) return erro;
    }
    return null;
  }

  static String? email(String? v) {
    if (_vazio(v)) return null;
    final ok = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$').hasMatch(v!.trim());
    return ok ? null : 'E-mail inválido.';
  }

  /// Telefone com DDD: fixo (10 dígitos, começa de 2 a 5) ou celular (11, começa com 9).
  static String? telefone(String? v) {
    if (_vazio(v)) return null;
    const erro = 'Telefone inválido: use DDD + número, ex.: (19) 99876-5432.';
    if (!RegExp(r'^[0-9()+\-.\s]+$').hasMatch(v!)) return erro;
    var d = v.replaceAll(RegExp(r'\D'), '');
    if ((d.length == 12 || d.length == 13) && d.startsWith('55')) {
      d = d.substring(2);
    }
    if (d.length != 10 && d.length != 11) return erro;
    if (!_ddds.contains(int.parse(d.substring(0, 2)))) return 'DDD inválido.';
    final numero = d.substring(2);
    if (d.length == 11 && numero[0] != '9') {
      return 'Celular deve começar com 9 depois do DDD.';
    }
    if (d.length == 10 && !'2345'.contains(numero[0])) return erro;
    if (numero.split('').every((c) => c == numero[0])) return erro;
    return null;
  }

  /// CNPJ com dígitos verificadores (numérico ou o alfanumérico de 2026).
  static String? cnpj(String? v) {
    if (_vazio(v)) return null;
    const erro =
        'CNPJ inválido: confira os 14 caracteres e os dígitos verificadores.';
    if (!RegExp(r'^[0-9A-Za-z./\-\s]+$').hasMatch(v!)) return erro;
    final c = v.replaceAll(RegExp(r'[./\-\s]'), '').toUpperCase();
    if (c.length != 14) return erro;
    if (!RegExp(r'^[0-9A-Z]{12}\d{2}$').hasMatch(c)) return erro;
    if (c.split('').every((x) => x == c[0])) return erro;
    int dv(String base, List<int> pesos) {
      var soma = 0;
      for (var i = 0; i < pesos.length; i++) {
        soma += (base.codeUnitAt(i) - 48) * pesos[i];
      }
      final resto = soma % 11;
      return resto < 2 ? 0 : 11 - resto;
    }

    final dv1 = dv(c, _pesosCnpj1);
    final dv2 = dv('${c.substring(0, 12)}$dv1', _pesosCnpj2);
    return (c.codeUnitAt(12) - 48 == dv1 && c.codeUnitAt(13) - 48 == dv2)
        ? null
        : erro;
  }

  /// Texto livre (título, descrição, nome de ONG): ao menos 2 letras e sem HTML.
  static String? textoLegivel(String? v) {
    if (_vazio(v)) return null;
    if (v!.contains('<') || v.contains('>')) {
      return 'Não use os caracteres < e >.';
    }
    if (_letra.allMatches(v).length < 2) {
      return 'Escreva com letras (não só números ou símbolos).';
    }
    return null;
  }

  /// Nome de pessoa ou de cidade: só letras, espaço, hífen, apóstrofo e ponto.
  static String? nomeProprio(String? v) {
    if (_vazio(v)) return null;
    final t = v!.trim();
    if (!_nomeProprio.hasMatch(t) || _letra.allMatches(t).length < 2) {
      return 'Use apenas letras (sem números ou símbolos).';
    }
    return null;
  }

  /// Senha nova: 8+ caracteres, com letra e número, fora das mais comuns.
  static String? senhaForte(String? v) {
    if (v == null || v.isEmpty) return 'Crie uma senha.';
    if (v.length < 8) return 'A senha precisa de pelo menos 8 caracteres.';
    if (v.length > 100) return 'Senha longa demais.';
    if (!_letra.hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Use letras e números na senha.';
    }
    if (_senhasComuns.contains(v.toLowerCase())) {
      return 'Essa senha é muito comum. Escolha outra.';
    }
    return null;
  }

  static String? tamanhoMax(String? v, int max) =>
      (v != null && v.length > max) ? 'Máximo de $max caracteres.' : null;
}

/// Máscara de telefone enquanto digita: (19) 99876-5432 ou (19) 3451-2000.
class TelefoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var d = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (d.length > 11) d = d.substring(0, 11);
    final sb = StringBuffer();
    for (var i = 0; i < d.length; i++) {
      if (i == 0) sb.write('(');
      if (i == 2) sb.write(') ');
      final corte = d.length == 11 ? 7 : 6;
      if (i == corte) sb.write('-');
      sb.write(d[i]);
    }
    final t = sb.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}

/// Máscara de CNPJ enquanto digita: 11.222.333/0001-81 (aceita letras, CNPJ alfanumérico).
class CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var c = newValue.text.toUpperCase().replaceAll(RegExp(r'[^0-9A-Z]'), '');
    if (c.length > 14) c = c.substring(0, 14);
    final sb = StringBuffer();
    for (var i = 0; i < c.length; i++) {
      if (i == 2 || i == 5) sb.write('.');
      if (i == 8) sb.write('/');
      if (i == 12) sb.write('-');
      sb.write(c[i]);
    }
    final t = sb.toString();
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
