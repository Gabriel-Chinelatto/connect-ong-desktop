import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/feedback/app_snackbar.dart';

/// Abre um link externo no navegador/aplicativo padrão do sistema.
///
/// No desktop e na web o `canLaunchUrl` costuma dar falso-negativo (o sistema
/// não expõe a consulta de handlers), então NÃO usamos canLaunch: chamamos
/// `launchUrl` direto dentro de try/catch. Se falhar (exceção ou retorno
/// false), degradamos copiando o link para a área de transferência e avisando
/// o usuário — assim a ação nunca "morre" sem saída.
///
/// Use esta função em QUALQUER abertura de link do app, no lugar de chamar o
/// url_launcher diretamente.
Future<void> abrirLinkExterno(
  BuildContext context,
  Uri uri, {
  /// Texto copiado no fallback (padrão: a própria URL).
  String? textoCopia,
}) async {
  bool abriu = false;
  try {
    abriu = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    abriu = false;
  }
  if (abriu) return;

  await Clipboard.setData(ClipboardData(text: textoCopia ?? uri.toString()));
  if (context.mounted) {
    AppSnackbar.info(context, 'Link copiado — cole no navegador.');
  }
}
