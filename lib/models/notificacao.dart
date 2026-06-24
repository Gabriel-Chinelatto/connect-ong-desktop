/// Uma notificacao do usuario.
class Notificacao {
  final int id;
  final String titulo;
  final String mensagem;
  final String tipo;
  final bool lida;
  final String? dataCriacao;

  const Notificacao({
    required this.id,
    required this.titulo,
    required this.mensagem,
    required this.tipo,
    required this.lida,
    this.dataCriacao,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'],
      titulo: json['titulo'] ?? '',
      mensagem: json['mensagem'] ?? '',
      tipo: json['tipo'] ?? '',
      lida: json['lida'] ?? false,
      dataCriacao: json['dataCriacao'],
    );
  }
}
