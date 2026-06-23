/// Perfil de uma ONG (usado para identificar qual ONG o usuario gerencia).
class Ong {
  final int id;
  final String nome;
  final String email;
  final String cidade;

  const Ong({
    required this.id,
    required this.nome,
    required this.email,
    required this.cidade,
  });

  factory Ong.fromJson(Map<String, dynamic> json) {
    return Ong(
      id: json['id'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cidade: json['cidade'] ?? '',
    );
  }
}
