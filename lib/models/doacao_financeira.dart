/// Doacao financeira (PIX simulado) recebida pela ONG.
///
/// Espelha o DoacaoFinanceiraResponseDTO do backend (GET /doacoes-financeiras).
/// O codigoPix e OMITIDO pela API na listagem por ONG (seguranca), por isso
/// nao existe aqui: a ONG ve apenas doador, valor, status e data.
class DoacaoFinanceira {
  final int id;
  final String doadorNome;
  final double valor;
  final String status; // CONFIRMADO (PIX simulado)
  final String? dataCriacao; // ISO-8601 (ex.: 2026-07-02T14:30:00)

  const DoacaoFinanceira({
    required this.id,
    required this.doadorNome,
    required this.valor,
    required this.status,
    this.dataCriacao,
  });

  factory DoacaoFinanceira.fromJson(Map<String, dynamic> json) {
    return DoacaoFinanceira(
      id: json['id'] ?? 0,
      doadorNome: (json['doadorNome'] as String?)?.trim().isNotEmpty == true
          ? (json['doadorNome'] as String).trim()
          : 'Doador',
      valor: (json['valor'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? '',
      dataCriacao: json['dataCriacao'],
    );
  }

  /// Data de criacao ja convertida (null se ausente ou invalida).
  DateTime? get data =>
      dataCriacao == null ? null : DateTime.tryParse(dataCriacao!);
}
