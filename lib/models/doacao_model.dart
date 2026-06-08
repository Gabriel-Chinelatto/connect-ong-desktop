class DoacaoModel {

  final int? id;
  final String nome;
  final String descricao;
  final int quantidade;
  final String categoria;
  final String tipo;
  final bool urgente;
  final bool novo;

  DoacaoModel({
    this.id,
    required this.nome,
    required this.descricao,
    required this.quantidade,
    required this.categoria,
    required this.tipo,
    required this.urgente,
    required this.novo,
  });

  factory DoacaoModel.fromJson(
    Map<String, dynamic> json,
  ) {

    return DoacaoModel(

      id: json['id'],

      nome: json['nome'] ?? '',

      descricao: json['descricao'] ?? '',

      quantidade: json['quantidade'] ?? 0,

      categoria: json['categoria'] ?? '',

      tipo: json['tipo'] ?? '',

      urgente: json['urgente'] ?? false,

      novo: json['novo'] ?? false,

    );
  }
}