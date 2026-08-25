/// Perfil de uma ONG (usado para identificar qual ONG o usuario gerencia).
///
/// Os campos "ricos" (descricao, logoBase64, capaBase64, endereco, fotosLocal)
/// so vem
/// preenchidos no GET /ongs/{id}; na listagem GET /ongs eles chegam nulos.
class Ong {
  final int id;
  final String nome;
  final String email;
  final String cidade;
  final String telefone;
  final String descricao;

  /// Logo (foto de perfil) do cabecalho, base64. Null = cai na inicial do nome.
  final String? logoBase64;

  /// Capa do perfil publico (base64, proporcao recomendada 3:1).
  final String? capaBase64;

  /// Endereco completo em texto (rua, numero, bairro).
  final String? endereco;

  /// Coordenadas do endereco (quando a ONG escolheu no autocomplete de mapa).
  /// Null = sem coordenada; o front cai no fallback por cidade.
  final double? latitude;
  final double? longitude;

  /// Fotos do local/sede (base64, ate 5).
  final List<String> fotosLocal;

  const Ong({
    required this.id,
    required this.nome,
    required this.email,
    required this.cidade,
    this.telefone = '',
    this.descricao = '',
    this.logoBase64,
    this.capaBase64,
    this.endereco,
    this.latitude,
    this.longitude,
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
      logoBase64: json['logoBase64'],
      capaBase64: json['capaBase64'],
      endereco: json['endereco'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      fotosLocal: ((json['fotosLocal'] as List?) ?? [])
          .whereType<String>()
          .toList(),
    );
  }
}
