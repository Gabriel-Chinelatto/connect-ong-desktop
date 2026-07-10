import 'json_utils.dart';

/// Uma necessidade publicada por uma ONG.
class Necessidade {
  final int id;
  final String titulo;
  final String descricao;
  final String categoria;
  final bool urgente;
  final String status;
  final int? ongId;
  final String? ongNome;

  const Necessidade({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.categoria,
    required this.urgente,
    required this.status,
    this.ongId,
    this.ongNome,
  });

  factory Necessidade.fromJson(Map<String, dynamic> json) {
    return Necessidade(
      id: asInt(json['id']),
      titulo: asString(json['titulo']),
      descricao: asString(json['descricao']),
      categoria: asString(json['categoria']),
      urgente: asBool(json['urgente']),
      status: asString(json['status']),
      ongId: asIntOrNull(json['ongId']),
      ongNome: asStringOrNull(json['ongNome']),
    );
  }
}
