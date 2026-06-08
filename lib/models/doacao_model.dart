class Doacao {
  final String id;
  final String titulo;
  final String descricao;
  final DateTime dataPostagem;
  final String status; // 'disponivel', 'reservado', 'entregue'

  Doacao({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.dataPostagem,
    this.status = 'disponivel',
  });
}