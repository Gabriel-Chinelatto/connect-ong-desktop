import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:connect_ong/screens/ong/dialogs_match.dart';

/// Guarda de saída nos DIALOGS de formulário (varredura de 13/08/2026).
///
/// Os dialogs (prestação de contas, avaliação, necessidade, campanha, trocar
/// e-mail/senha) fechavam no toque fora ou no Cancelar perdendo tudo em
/// silêncio. Aqui cobrimos o FormPrestacao, que usa o mesmo
/// GuardaDeSaidaDialog dos demais.
void main() {
  Widget cenario() => MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (_) => const FormPrestacao(interesseId: 1),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );

  Future<void> abrir(WidgetTester tester) async {
    await tester.pumpWidget(cenario());
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets('sem nada digitado, Cancelar fecha direto (não incomoda)',
      (tester) async {
    await abrir(tester);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Alterações não salvas'), findsNothing);
    expect(find.text('Prestar contas'), findsNothing);
  });

  testWidgets('digitou e tentou fechar: avisa; Continuar mantém, Descartar sai',
      (tester) async {
    await abrir(tester);

    await tester.enterText(
        find.byType(TextFormField).first, 'Compra de ração');
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    // O aviso aparece e nada foi perdido ainda.
    expect(find.text('Alterações não salvas'), findsOneWidget);

    await tester.tap(find.text('Continuar editando'));
    await tester.pumpAndSettle();
    expect(find.text('Prestar contas'), findsOneWidget);
    expect(find.text('Compra de ração'), findsOneWidget);

    // Agora descarta de verdade.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Prestar contas'), findsNothing);
  });
}
