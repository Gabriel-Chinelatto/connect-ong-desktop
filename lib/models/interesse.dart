/// O interesse de um doador em uma necessidade da ONG.
class Interesse {
  final int id;
  final String status; // PENDENTE, ACEITO, RECUSADO, CONCLUIDO
  final int? necessidadeId;
  final String? necessidadeTitulo;
  final int? doadorId;
  final String? doadorNome;
  final int? ongId;
  final String? ongNome;

  /// Quando o interesse foi criado (ISO) — "início" do match.
  final String? dataCriacao;

  /// Quando a ONG marcou a doação como recebida (ISO, só em CONCLUIDO).
  final String? dataConclusao;

  /// Quando ocorreu a última mudança de status (ISO): aceite/recusa/conclusão.
  /// Null enquanto PENDENTE. Base do "recusado em ..." / "aceito em ...".
  final String? dataStatus;

  /// true quando a ONG bloqueou este doador (contrato novo do
  /// GET /interesses?ongId=). Campo ausente (backend antigo) = não bloqueado.
  final bool bloqueadoPelaOng;

  /// Há quantos dias o doador espera o aceite (só em PENDENTE; null nos demais
  /// status ou em backend antigo). Calculado no servidor a partir da dataCriacao.
  final int? diasEsperando;

  const Interesse({
    required this.id,
    required this.status,
    this.necessidadeId,
    this.necessidadeTitulo,
    this.doadorId,
    this.doadorNome,
    this.ongId,
    this.ongNome,
    this.dataCriacao,
    this.dataConclusao,
    this.dataStatus,
    this.bloqueadoPelaOng = false,
    this.diasEsperando,
  });

  factory Interesse.fromJson(Map<String, dynamic> json) {
    return Interesse(
      id: json['id'],
      status: json['status'] ?? '',
      necessidadeId: json['necessidadeId'],
      necessidadeTitulo: json['necessidadeTitulo'],
      doadorId: json['doadorId'],
      doadorNome: json['doadorNome'],
      ongId: json['ongId'],
      ongNome: json['ongNome'],
      dataCriacao: json['dataCriacao'],
      dataConclusao: json['dataConclusao'],
      dataStatus: json['dataStatus'],
      bloqueadoPelaOng: json['bloqueadoPelaOng'] == true,
      diasEsperando: (json['diasEsperando'] as num?)?.toInt(),
    );
  }
}
