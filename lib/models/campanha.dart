/// Campanha de arrecadacao de uma ONG (meta + progresso).
class Campanha {
  final int id;
  final String titulo;
  final String descricao;
  final double metaValor;
  final double valorArrecadado;
  final int progresso; // 0 a 100
  final String? categoria;
  final bool encerrada;
  final bool destaque;

  const Campanha({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.metaValor,
    required this.valorArrecadado,
    required this.progresso,
    required this.encerrada,
    required this.destaque,
    this.categoria,
  });

  factory Campanha.fromJson(Map<String, dynamic> j) {
    return Campanha(
      id: (j['id'] ?? 0) as int,
      titulo: j['titulo'] ?? '',
      descricao: j['descricao'] ?? '',
      metaValor: ((j['metaValor'] ?? 0) as num).toDouble(),
      valorArrecadado: ((j['valorArrecadado'] ?? 0) as num).toDouble(),
      progresso: (j['progresso'] ?? 0) as int,
      encerrada: j['encerrada'] ?? false,
      destaque: j['destaque'] ?? false,
      categoria: j['categoria'],
    );
  }
}
