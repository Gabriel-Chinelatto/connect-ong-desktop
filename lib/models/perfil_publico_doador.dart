/// Perfil publico de um doador (GET /usuarios/{id}/perfil-publico).
///
/// Usado pela ONG para conhecer quem esta doando: identidade basica, nota
/// media dada por outras ONGs, stats e as prestacoes que ele ja recebeu.
/// O email/telefone só vêm preenchidos quando o doador ligou "exibir e-mail/
/// telefone" nas configurações; caso contrário chegam null (privacidade).
class PerfilPublicoDoador {
  final int id;
  final String nome;
  final String? cidade;
  final String? estado;
  final String? fotoBase64;
  final String? membroDesde; // ISO
  final double? notaMediaDoador; // null quando sem avaliacoes
  final int totalAvaliacoesDoador;
  final int matchesConcluidos;
  final int totalDoacoesPix; // CONTAGEM de doacoes PIX (nao valor)
  final List<AvaliacaoDoador> avaliacoes;
  final List<PrestacaoRecebida> prestacoesRecebidas;

  /// Contato do doador. Vêm null quando o doador NÃO autorizou exibir
  /// (toggles "exibir e-mail/telefone" desligados) — a UI só mostra a seção
  /// de contato quando ao menos um destes vier não-nulo.
  final String? email;
  final String? telefone;

  const PerfilPublicoDoador({
    required this.id,
    required this.nome,
    this.cidade,
    this.estado,
    this.fotoBase64,
    this.membroDesde,
    this.notaMediaDoador,
    this.totalAvaliacoesDoador = 0,
    this.matchesConcluidos = 0,
    this.totalDoacoesPix = 0,
    this.avaliacoes = const [],
    this.prestacoesRecebidas = const [],
    this.email,
    this.telefone,
  });

  factory PerfilPublicoDoador.fromJson(Map<String, dynamic> j) {
    final stats = (j['stats'] as Map<String, dynamic>?) ?? const {};
    String? textoOuNull(dynamic v) {
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    return PerfilPublicoDoador(
      id: (j['id'] ?? 0) as int,
      nome: j['nome'] ?? '',
      cidade: j['cidade'],
      estado: j['estado'],
      fotoBase64: j['fotoBase64'],
      membroDesde: j['membroDesde'],
      email: textoOuNull(j['email']),
      telefone: textoOuNull(j['telefone']),
      notaMediaDoador: (j['notaMediaDoador'] as num?)?.toDouble(),
      totalAvaliacoesDoador: (j['totalAvaliacoesDoador'] ?? 0) as int,
      matchesConcluidos: ((stats['matchesConcluidos'] ?? 0) as num).toInt(),
      totalDoacoesPix: ((stats['totalDoacoesPix'] ?? 0) as num).toInt(),
      avaliacoes: ((j['avaliacoes'] as List?) ?? [])
          .map((e) => AvaliacaoDoador.fromJson(e as Map<String, dynamic>))
          .toList(),
      prestacoesRecebidas: ((j['prestacoesRecebidas'] as List?) ?? [])
          .map((e) => PrestacaoRecebida.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Avaliacao que uma ONG deu a um doador (estilo Uber, 1-5 estrelas).
class AvaliacaoDoador {
  final String? ongNome;
  final int nota;
  final String? comentario;
  final String? criadoEm; // ISO

  const AvaliacaoDoador({
    required this.nota,
    this.ongNome,
    this.comentario,
    this.criadoEm,
  });

  factory AvaliacaoDoador.fromJson(Map<String, dynamic> j) => AvaliacaoDoador(
        ongNome: j['ongNome'],
        nota: (j['nota'] ?? 0) as int,
        comentario: j['comentario'],
        criadoEm: j['criadoEm'],
      );
}

/// Resumo publico de uma prestacao de contas recebida pelo doador.
class PrestacaoRecebida {
  final String titulo;
  final String descricao;

  /// Contraparte: a ONG que emitiu esta prestação. [ongId] permite abrir o
  /// perfil público da ONG; quando null, a UI degrada (sem link/agrupamento).
  final int? ongId;
  final String? ongNome;
  final String? necessidadeTitulo;
  final String? criadoEm; // ISO

  const PrestacaoRecebida({
    required this.titulo,
    required this.descricao,
    this.ongId,
    this.ongNome,
    this.necessidadeTitulo,
    this.criadoEm,
  });

  factory PrestacaoRecebida.fromJson(Map<String, dynamic> j) =>
      PrestacaoRecebida(
        titulo: j['titulo'] ?? '',
        descricao: j['descricao'] ?? '',
        ongId: (j['ongId'] as num?)?.toInt(),
        ongNome: j['ongNome'],
        necessidadeTitulo: j['necessidadeTitulo'],
        criadoEm: j['criadoEm'],
      );
}
