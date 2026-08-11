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
