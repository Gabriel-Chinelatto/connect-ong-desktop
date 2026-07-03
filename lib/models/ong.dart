/// Perfil de uma ONG (usado para identificar qual ONG o usuario gerencia).
///
/// Os campos "ricos" (descricao, capaBase64, endereco, fotosLocal) so vem
/// preenchidos no GET /ongs/{id}; na listagem GET /ongs eles chegam nulos.
class Ong {
  final int id;
  final String nome;
  final String email;
  final String cidade;
  final String telefone;
  final String descricao;

  /// Capa do perfil publico (base64, proporcao recomendada 3:1).
  final String? capaBase64;

  /// Endereco completo em texto (rua, numero, bairro).
  final String? endereco;

  /// Fotos do local/sede (base64, ate 5).
  final List<String> fotosLocal;

  const Ong({
    required this.id,
    required this.nome,
    required this.email,
    required this.cidade,
    this.telefone = '',
    this.descricao = '',
    this.capaBase64,
    this.endereco,
    this.fotosLocal = const [],
  });

  factory Ong.fromJson(Map<String, dynamic> json) {
    return Ong(
      id: json['id'],
      nome: json['nome'] ?? '',
      email: json['email'] ?? '',
      cidade: json['cidade'] ?? '',
      telefone: json['telefone'] ?? '',
      descricao: json['descricao'] ?? '',
      capaBase64: json['capaBase64'],
      endereco: json['endereco'],
      fotosLocal: ((json['fotosLocal'] as List?) ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}
