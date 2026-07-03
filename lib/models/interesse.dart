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

  /// Quando a ONG marcou a doação como recebida (ISO, só em CONCLUIDO).
  final String? dataConclusao;

  const Interesse({
    required this.id,
    required this.status,
    this.necessidadeId,
    this.necessidadeTitulo,
    this.doadorId,
    this.doadorNome,
    this.ongId,
    this.ongNome,
    this.dataConclusao,
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
      dataConclusao: json['dataConclusao'],
    );
  }
}
