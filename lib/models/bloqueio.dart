/// Um doador bloqueado pela ONG (contrato GET /bloqueios).
///
/// A lista retornada pelo backend contém apenas os bloqueios da própria ONG
/// autenticada (escopo do JWT).
class Bloqueio {
  final int doadorId;
  final String doadorNome;

  /// Quando o bloqueio foi criado (ISO). Pode vir nulo de backends antigos.
  final String? criadoEm;

  const Bloqueio({
    required this.doadorId,
    required this.doadorNome,
    this.criadoEm,
  });

  factory Bloqueio.fromJson(Map<String, dynamic> json) {
    return Bloqueio(
      doadorId: (json['doadorId'] as num).toInt(),
      doadorNome: (json['doadorNome'] as String?)?.trim().isNotEmpty == true
          ? (json['doadorNome'] as String).trim()
          : 'Doador',
      criadoEm: json['criadoEm'] as String?,
    );
  }
}
