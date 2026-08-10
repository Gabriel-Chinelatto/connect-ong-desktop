import 'package:flutter_test/flutter_test.dart';

import 'package:connect_ong/utils/estado_cidade.dart';

/// Regras de Estado/Cidade do perfil da ONG.
///
/// Contexto (feedback de 10/08/2026): a ONG "Lar Viva" abria o perfil com a
/// cidade "Limeira" preenchida e o campo UF VAZIO — cadastros antigos guardavam
/// só o nome da cidade. Pior: escolher a UF apagava a cidade digitada.
void main() {
  // Recorte do mapa UF -> municípios (o app carrega o asset completo do IBGE).
  const municipios = <String, List<String>>{
    'SP': ['Limeira', 'Campinas', 'São Paulo', 'Bom Jesus dos Perdões'],
    'RJ': ['Rio de Janeiro', 'Niterói'],
    'PI': ['Bom Jesus'],
    'RS': ['Bom Jesus', 'Porto Alegre'],
  };

  group('ufDaCidade', () {
    test('descobre a UF quando a cidade existe em um único estado', () {
      expect(ufDaCidade('Limeira', municipios), 'SP');
      expect(ufDaCidade('Niterói', municipios), 'RJ');
    });

    test('ignora acento e caixa', () {
      expect(ufDaCidade('sao paulo', municipios), 'SP');
      expect(ufDaCidade('NITEROI', municipios), 'RJ');
    });

    test('não chuta quando há cidades homônimas em estados diferentes', () {
      // "Bom Jesus" existe no PI e no RS: melhor deixar a pessoa escolher.
      expect(ufDaCidade('Bom Jesus', municipios), isNull);
    });

    test('cidade desconhecida ou vazia não inventa estado', () {
      expect(ufDaCidade('Cidade Que Não Existe', municipios), isNull);
      expect(ufDaCidade('   ', municipios), isNull);
    });
  });

  group('cidadePertenceAUf', () {
    test('reconhece a cidade do estado escolhido', () {
      expect(cidadePertenceAUf('Limeira', 'SP', municipios), isTrue);
      expect(cidadePertenceAUf('limeira', 'SP', municipios), isTrue);
    });

    test('nega quando a cidade é de outro estado', () {
      expect(cidadePertenceAUf('Limeira', 'RJ', municipios), isFalse);
    });

    test('sem UF escolhida não pertence a nada', () {
      expect(cidadePertenceAUf('Limeira', null, municipios), isFalse);
    });
  });

  group('formatar/separar (contrato do campo único do backend)', () {
    test('ida e volta preserva cidade e UF', () {
      final salvo = formatarCidadeUf('Limeira', 'SP');
      expect(salvo, 'Limeira - SP');

      final lido = separarCidadeUf(salvo);
      expect(lido.cidade, 'Limeira');
      expect(lido.uf, 'SP');
    });

    test('cadastro antigo (só a cidade) é lido sem UF', () {
      final lido = separarCidadeUf('Limeira');
      expect(lido.cidade, 'Limeira');
      expect(lido.uf, isNull);
      // ... e é daí que a inferência acima entra em ação:
      expect(ufDaCidade(lido.cidade, municipios), 'SP');
    });

    test('sufixo que não é UF continua fazendo parte do nome', () {
      final lido = separarCidadeUf('Santa Cruz - ZZ');
      expect(lido.cidade, 'Santa Cruz - ZZ');
      expect(lido.uf, isNull);
    });
  });
}
