import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:connect_ong/utils/estado_cidade.dart';

/// Contrato do formato "Cidade - UF" persistido no campo único `cidade` do
/// backend, e sanidade do asset offline do IBGE (municipios_por_uf.json).
void main() {
  group('formatarCidadeUf', () {
    test('junta cidade e UF no formato persistido', () {
      expect(formatarCidadeUf('São Paulo', 'SP'), 'São Paulo - SP');
    });

    test('sem UF (ou UF inválida) devolve só a cidade', () {
      expect(formatarCidadeUf('Curitiba', null), 'Curitiba');
      expect(formatarCidadeUf('Curitiba', 'ZZ'), 'Curitiba');
    });

    test('sem cidade não há o que guardar (mesmo com UF)', () {
      expect(formatarCidadeUf('', 'SP'), '');
      expect(formatarCidadeUf('   ', 'SP'), '');
    });

    test('normaliza espaços e caixa da UF', () {
      expect(formatarCidadeUf('  Maringá ', ' pr '), 'Maringá - PR');
    });
  });

  group('separarCidadeUf', () {
    test('separa "Cidade - UF" em cidade e UF', () {
      final r = separarCidadeUf('São Paulo - SP');
      expect(r.cidade, 'São Paulo');
      expect(r.uf, 'SP');
    });

    test('cidade com apóstrofo e hífen interno não confunde o parse', () {
      final r = separarCidadeUf("Mirassol d'Oeste - MT");
      expect(r.cidade, "Mirassol d'Oeste");
      expect(r.uf, 'MT');
    });

    test('cadastro antigo de campo livre vira só cidade (uf null)', () {
      final r = separarCidadeUf('Curitiba');
      expect(r.cidade, 'Curitiba');
      expect(r.uf, isNull);
    });

    test('sufixo de 2 letras que NÃO é UF vira parte da cidade', () {
      final r = separarCidadeUf('Vila Nova - XY');
      expect(r.cidade, 'Vila Nova - XY');
      expect(r.uf, isNull);
    });

    test('ida e volta preserva os valores', () {
      final r = separarCidadeUf(formatarCidadeUf('João Pessoa', 'PB'));
      expect(r.cidade, 'João Pessoa');
      expect(r.uf, 'PB');
    });
  });

  group('asset municipios_por_uf.json', () {
    test('tem as 27 UFs em ordem alfabética, com listas ordenadas', () {
      final raw =
          File('assets/dados/municipios_por_uf.json').readAsStringSync();
      final mapa = jsonDecode(raw) as Map<String, dynamic>;

      expect(mapa.keys.toList(), ufsBrasil, reason: '27 UFs, alfabético');
      for (final e in mapa.entries) {
        final cidades = (e.value as List).whereType<String>().toList();
        expect(cidades, isNotEmpty, reason: 'UF ${e.key} sem municípios');
        final ordenada = [...cidades]..sort((a, b) => semAcento(a)
            .toLowerCase()
            .compareTo(semAcento(b).toLowerCase()));
        expect(cidades, ordenada, reason: 'UF ${e.key} fora de ordem');
      }
      expect((mapa['SP'] as List), contains('São Paulo'));
      expect((mapa['DF'] as List), ['Brasília']);
    });
  });
}
