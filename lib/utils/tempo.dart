/// Helpers de formatação de tempo do chat (presença "visto por último").
///
/// O backend manda `ultimoVistoEpoch` (millis desde epoch, UTC) e `online`
/// (boolean calculado no servidor, janela de 2 min). Este helper converte
/// isso no texto exibido sob o título do chat, no fuso local da máquina:
///
/// - online              -> "online"
/// - visto hoje          -> "visto por último às HH:mm"
/// - visto ontem         -> "ontem às HH:mm"
/// - mais antigo         -> "em dd/MM às HH:mm"
/// - sem informação      -> "" (string vazia; a UI esconde a linha)
///
/// `agora` é injetável para os testes fixarem o relógio.
String formatarVistoPorUltimo({
  required bool online,
  int? ultimoVistoEpoch,
  DateTime? agora,
}) {
  if (online) return 'online';
  if (ultimoVistoEpoch == null) return '';

  final ref = agora ?? DateTime.now();
  // fromMillisecondsSinceEpoch interpreta o instante e devolve no fuso local.
  final visto = DateTime.fromMillisecondsSinceEpoch(ultimoVistoEpoch);

  String dois(int n) => n.toString().padLeft(2, '0');
  final hora = '${dois(visto.hour)}:${dois(visto.minute)}';

  final hoje = DateTime(ref.year, ref.month, ref.day);
  final diaVisto = DateTime(visto.year, visto.month, visto.day);
  final diasAtras = hoje.difference(diaVisto).inDays;

  if (diasAtras <= 0) return 'visto por último às $hora';
  if (diasAtras == 1) return 'ontem às $hora';
  return 'em ${dois(visto.day)}/${dois(visto.month)} às $hora';
}
