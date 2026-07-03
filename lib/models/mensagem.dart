/// Uma reacao (emoji) de um participante a uma mensagem.
/// `emoji` e um CODIGO (ex.: LIKE, LOVE), nao o caractere.
/// `lado` indica quem reagiu (ONG ou DOADOR).
class ReacaoMsg {
  final String emoji;
  final String lado;

  const ReacaoMsg({required this.emoji, required this.lado});

  factory ReacaoMsg.fromJson(Map<String, dynamic> json) {
    return ReacaoMsg(
      emoji: json['emoji'] ?? '',
      lado: json['lado'] ?? '',
    );
  }
}

/// Uma mensagem de chat dentro de um match.
class Mensagem {
  final int id;
  final int? interesseId;
  final String remetente; // DOADOR ou ONG
  final String conteudo;
  final String? dataEnvio;
  final bool lida; // true = ja foi vista pelo outro participante
  final List<ReacaoMsg> reacoes; // 0 a 2 reacoes (uma por lado)

  /// Anexo de imagem (base64) e seu tipo ("imagem"). Uma mensagem pode ser
  /// so texto, so anexo, ou os dois.
  final String? anexoBase64;
  final String? anexoTipo;

  const Mensagem({
    required this.id,
    required this.remetente,
    required this.conteudo,
    this.interesseId,
    this.dataEnvio,
    this.lida = false,
    this.reacoes = const [],
    this.anexoBase64,
    this.anexoTipo,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: json['id'],
      interesseId: json['interesseId'],
      remetente: json['remetente'] ?? '',
      conteudo: json['conteudo'] ?? '',
      dataEnvio: json['dataEnvio'],
      lida: (json['lida'] ?? false) as bool,
      reacoes: ((json['reacoes'] as List?) ?? [])
          .map((r) => ReacaoMsg.fromJson(r as Map<String, dynamic>))
          .toList(),
      anexoBase64: json['anexoBase64'],
      anexoTipo: json['anexoTipo'],
    );
  }
}
