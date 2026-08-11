import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connect_ong/widgets/confirmar_saida.dart';

/// Aviso de "alterações não salvas".
///
/// Pedido do usuário na varredura de campos (10/08/2026): ao alterar e tentar
/// sair, o app deve avisar. Só a tela de Configurações fazia isso; editar o
/// perfil e voltar perdia tudo em silêncio.
void main() {
  /// Monta uma tela com botão "voltar" e o guarda aplicado.
  Widget cenario({
    required bool temMudanca,
    Future<bool> Function()? aoSalvar,
    required List<String> eventos,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GuardaDeSaida(
                  temMudanca: temMudanca,
                  aoSalvar: aoSalvar,
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Formulário')),
                    body: const Text('conteúdo'),
                  ),
                ),
              ),
            ).then((_) => eventos.add('saiu')),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
  }

  Future<void> abrirEVoltar(WidgetTester tester) async {
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    // Toca no botão de voltar da AppBar.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  testWidgets('sem alterações, sai direto (não incomoda)', (tester) async {
    final eventos = <String>[];
    await tester.pumpWidget(cenario(temMudanca: false, eventos: eventos));

    await abrirEVoltar(tester);

    expect(find.text('Alterações não salvas'), findsNothing);
    expect(eventos, contains('saiu'));
  });

  testWidgets('com alterações, avisa antes de sair', (tester) async {
    final eventos = <String>[];
    await tester.pumpWidget(cenario(temMudanca: true, eventos: eventos));

    await abrirEVoltar(tester);

    expect(find.text('Alterações não salvas'), findsOneWidget);
    expect(eventos, isEmpty, reason: 'não pode ter saído ainda');
  });

  testWidgets('"Continuar editando" mantém a pessoa na tela', (tester) async {
    final eventos = <String>[];
    await tester.pumpWidget(cenario(temMudanca: true, eventos: eventos));
    await abrirEVoltar(tester);

    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();

    expect(eventos, isEmpty);
    expect(find.text('Formulário'), findsOneWidget);
  });

  testWidgets('"Descartar" sai e perde as alterações', (tester) async {
    final eventos = <String>[];
    await tester.pumpWidget(cenario(temMudanca: true, eventos: eventos));
    await abrirEVoltar(tester);

    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(eventos, contains('saiu'));
  });

  testWidgets('"Salvar" só aparece quando a tela sabe salvar', (tester) async {
    final eventos = <String>[];
    await tester.pumpWidget(cenario(temMudanca: true, eventos: eventos));
    await abrirEVoltar(tester);

    expect(find.text('Salvar'), findsNothing);
  });

  testWidgets('"Salvar" grava e depois sai', (tester) async {
    final eventos = <String>[];
    await tester.pumpWidget(cenario(
      temMudanca: true,
      aoSalvar: () async {
        eventos.add('salvou');
        return true;
      },
      eventos: eventos,
    ));
    await abrirEVoltar(tester);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(eventos, containsAllInOrder(['salvou', 'saiu']));
  });

  testWidgets('se o salvamento falha, a pessoa continua na tela',
      (tester) async {
    final eventos = <String>[];
    await tester.pumpWidget(cenario(
      temMudanca: true,
      aoSalvar: () async {
        eventos.add('tentou salvar');
        return false; // ex.: sem internet
      },
      eventos: eventos,
    ));
    await abrirEVoltar(tester);

    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(eventos, contains('tentou salvar'));
    expect(eventos, isNot(contains('saiu')),
        reason: 'não pode sair perdendo o que falhou ao salvar');
  });
}
