/// Conquista (gamificacao) de uma ONG.
/// Espelha um elemento da resposta de GET /conquistas/ong/{ongId}.
class Conquista {
  final String chave;
  final String titulo;
  final String descricao;
  final bool conquistada;

  const Conquista({
    required this.chave,
    required this.titulo,
    required this.descricao,
    required this.conquistada,
  });

  factory Conquista.fromJson(Map<String, dynamic> j) => Conquista(
        chave: j['chave'] ?? '',
        titulo: j['titulo'] ?? '',
        descricao: j['descricao'] ?? '',
        conquistada: j['conquistada'] ?? false,
      );
}
