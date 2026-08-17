import 'package:flutter/material.dart';

/// O que a pessoa escolheu ao tentar sair com alterações pendentes.
enum SaidaEscolha { continuarEditando, descartar, salvar }

/// Pergunta o que fazer quando se tenta sair de um formulário com mudanças
/// pendentes.
///
/// Quando [permiteSalvar] é true, oferece as três saídas — continuar editando,
/// descartar ou **salvar na hora** —, que era o comportamento (melhor) já
/// existente na tela de Configurações. As telas de EDIÇÃO não tinham proteção
/// nenhuma e perdiam o trabalho em silêncio (varredura de 10/08/2026).
Future<SaidaEscolha> perguntarSaida(
  BuildContext context, {
  bool permiteSalvar = false,
}) async {
  final escolha = await showDialog<SaidaEscolha>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Alterações não salvas'),
      content: Text(permiteSalvar
          ? 'Você tem mudanças que ainda não foram salvas. O que deseja fazer?'
          : 'Você tem mudanças que ainda não foram salvas. Se sair agora, '
              'elas serão perdidas.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, SaidaEscolha.continuarEditando),
          child: const Text('Continuar editando'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, SaidaEscolha.descartar),
          child: const Text('Descartar'),
        ),
        if (permiteSalvar)
          FilledButton(
            onPressed: () => Navigator.pop(ctx, SaidaEscolha.salvar),
            child: const Text('Salvar'),
          ),
      ],
    ),
  );
  return escolha ?? SaidaEscolha.continuarEditando;
}

/// Envolve um formulário e intercepta a saída quando [temMudanca] é true.
///
/// Passe [aoSalvar] (que deve devolver true quando salvou com sucesso) para
/// oferecer o botão "Salvar" dentro do próprio aviso.
class GuardaDeSaida extends StatelessWidget {
  final bool temMudanca;
  final Widget child;
  final Future<bool> Function()? aoSalvar;

  const GuardaDeSaida({
    super.key,
    required this.temMudanca,
    required this.child,
    this.aoSalvar,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !temMudanca,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navegador = Navigator.of(context);
        final escolha =
            await perguntarSaida(context, permiteSalvar: aoSalvar != null);
        switch (escolha) {
          case SaidaEscolha.salvar:
            final ok = await aoSalvar!.call();
            if (ok && navegador.mounted) navegador.pop();
          case SaidaEscolha.descartar:
            if (navegador.mounted) navegador.pop();
          case SaidaEscolha.continuarEditando:
            break;
        }
      },
      child: child,
    );
  }
}

/// Guarda de saída para DIALOGS (AlertDialog aberto via showDialog).
///
/// Diferente do [GuardaDeSaida], recebe [temMudanca] como FUNÇÃO e usa
/// `canPop: false` sempre: digitar num TextField não rebuilda o dialog, então
/// um `canPop: !temMudanca` ficaria desatualizado e deixaria sair sem avisar.
/// A checagem acontece na hora do pop (toque fora, Esc e "Cancelar" passam
/// pelo maybePop). Pop programático via `Navigator.pop` (após salvar com
/// sucesso) NÃO passa por aqui e fecha direto.
class GuardaDeSaidaDialog extends StatelessWidget {
  final bool Function() temMudanca;
  final Widget child;

  const GuardaDeSaidaDialog({
    super.key,
    required this.temMudanca,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, resultado) async {
        if (didPop) return;
        final navegador = Navigator.of(context);
        if (!temMudanca()) {
          // Nada pendente: fecha repassando o resultado (ex.: false do
          // Cancelar; null do toque fora).
          navegador.pop(resultado);
          return;
        }
        final escolha = await perguntarSaida(context);
        if (escolha == SaidaEscolha.descartar && navegador.mounted) {
          navegador.pop(resultado);
        }
      },
      child: child,
    );
  }
}
