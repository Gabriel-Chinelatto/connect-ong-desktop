/// Prestacao de contas de um match (espelha o PrestacaoResponseDTO da API).
class Prestacao {
  final int id;
  final int? interesseId;
  final String titulo;
  final String descricao;
  final String? fotoUrl; // campo legado (URL externa)
  final String? dataCriacao; // ISO
  final String? doadorNome;
  final String? ongNome;
  final String? necessidadeTitulo;

  /// Fotos reais da prestacao (base64, ate 5).
  final List<String> fotos;

  /// Valor utilizado em reais (opcional).
  final double? valorUtilizado;

  const Prestacao({
    required this.id,
    required this.titulo,
    required this.descricao,
    this.interesseId,
    this.fotoUrl,
    this.dataCriacao,
    this.doadorNome,
    this.ongNome,
    this.necessidadeTitulo,
    this.fotos = const [],
    this.valorUtilizado,
  });

  factory Prestacao.fromJson(Map<String, dynamic> json) {
    return Prestacao(
      id: (json['id'] ?? 0) as int,
      interesseId: json['interesseId'],
      titulo: json['titulo'] ?? '',
      descricao: json['descricao'] ?? '',
      fotoUrl: json['fotoUrl'],
      dataCriacao: json['dataCriacao'],
      doadorNome: json['doadorNome'],
      ongNome: json['ongNome'],
      necessidadeTitulo: json['necessidadeTitulo'],
      fotos: ((json['fotos'] as List?) ?? []).whereType<String>().toList(),
      valorUtilizado: (json['valorUtilizado'] as num?)?.toDouble(),
    );
  }
}

/// Pendencia de prestacao de contas: match CONCLUIDO ainda sem prestacao.
///
/// O prazo e de 10 dias apos a conclusao; quando estoura, `definitivo` vira
/// true e a ONG perde 5 pontos no score de transparencia.
class PendenciaPrestacao {
  final int interesseId;
  final String? necessidadeTitulo;
  final String? doadorNome;
  final String? dataConclusao; // ISO
  final int diasRestantes; // 0 quando o prazo estourou
  final bool definitivo;

  const PendenciaPrestacao({
    required this.interesseId,
    required this.diasRestantes,
    required this.definitivo,
    this.necessidadeTitulo,
    this.doadorNome,
    this.dataConclusao,
  });

  factory PendenciaPrestacao.fromJson(Map<String, dynamic> json) {
    return PendenciaPrestacao(
      interesseId: (json['interesseId'] ?? 0) as int,
      necessidadeTitulo: json['necessidadeTitulo'],
      doadorNome: json['doadorNome'],
      dataConclusao: json['dataConclusao'],
      diasRestantes: (json['diasRestantes'] ?? 0) as int,
      definitivo: (json['definitivo'] ?? false) as bool,
    );
  }
}
