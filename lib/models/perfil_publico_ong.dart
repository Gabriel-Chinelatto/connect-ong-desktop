/// Perfil publico de uma ONG (espelha o PerfilPublicoOngDTO do backend).
/// No desktop serve para a ONG pre-visualizar como aparece para os doadores.
class PerfilPublicoOng {
  final int id;
  final String nome;
  final String cidade;
  final String descricao;
  final String telefone;
  final String email;
  final String? cnpj;
  final bool verificada;
  final double notaMedia;
  final int totalAvaliacoes;
  final int totalNecessidades;
  final int totalCampanhas;
  final int totalPrestacoes;
  final int transparenciaScore;
  final String nivelTransparencia;
  final List<NecessidadeResumo> necessidades;
  final List<CampanhaResumo> campanhas;
  final List<AvaliacaoResumo> avaliacoes;
  final List<PrestacaoResumo> prestacoes;

  /// Capa do perfil (base64, proporcao 3:1). Null = sem capa.
  final String? capaBase64;

  /// Endereco completo em texto (rua, numero, bairro).
  final String? endereco;

  /// Coordenadas do endereco (null = sem coordenada; usa fallback por cidade).
  final double? latitude;
  final double? longitude;

  /// Fotos do local/sede (base64, ate 5).
  final List<String> fotosLocal;

  /// Streak do ranking: dias como atual 1º lugar (null se nao for o topo).
  final int? diasNoTopo;

  /// Duracao (em dias) do ultimo reinado encerrado no topo do ranking.
  final int? ultimoReinadoDias;

  const PerfilPublicoOng({
    required this.id,
    required this.nome,
    required this.cidade,
    required this.descricao,
    required this.telefone,
    required this.email,
    this.cnpj,
    required this.verificada,
    required this.notaMedia,
    required this.totalAvaliacoes,
    required this.totalNecessidades,
    required this.totalCampanhas,
    required this.totalPrestacoes,
    required this.transparenciaScore,
    required this.nivelTransparencia,
    required this.necessidades,
    required this.campanhas,
    required this.avaliacoes,
    required this.prestacoes,
    this.capaBase64,
    this.endereco,
    this.latitude,
    this.longitude,
    this.fotosLocal = const [],
    this.diasNoTopo,
    this.ultimoReinadoDias,
  });

  factory PerfilPublicoOng.fromJson(Map<String, dynamic> j) {
    List<T> lista<T>(String chave, T Function(Map<String, dynamic>) f) {
      final raw = j[chave];
      if (raw is List) {
        return raw.map((e) => f(e as Map<String, dynamic>)).toList();
      }
      return <T>[];
    }

    return PerfilPublicoOng(
      id: (j['id'] ?? 0) as int,
      nome: j['nome'] ?? '',
      cidade: j['cidade'] ?? '',
      descricao: j['descricao'] ?? '',
      telefone: j['telefone'] ?? '',
      email: j['email'] ?? '',
      cnpj: j['cnpj'] as String?,
      verificada: j['verificada'] ?? false,
      notaMedia: ((j['notaMedia'] ?? 0) as num).toDouble(),
      totalAvaliacoes: (j['totalAvaliacoes'] ?? 0) as int,
      totalNecessidades: (j['totalNecessidades'] ?? 0) as int,
      totalCampanhas: (j['totalCampanhas'] ?? 0) as int,
      totalPrestacoes: (j['totalPrestacoes'] ?? 0) as int,
      transparenciaScore: (j['transparenciaScore'] ?? 0) as int,
      nivelTransparencia: j['nivelTransparencia'] ?? 'BRONZE',
      necessidades: lista('necessidades', NecessidadeResumo.fromJson),
      campanhas: lista('campanhas', CampanhaResumo.fromJson),
      avaliacoes: lista('avaliacoes', AvaliacaoResumo.fromJson),
      prestacoes: lista('prestacoes', PrestacaoResumo.fromJson),
      capaBase64: j['capaBase64'] as String?,
      endereco: j['endereco'] as String?,
      latitude: (j['latitude'] as num?)?.toDouble(),
      longitude: (j['longitude'] as num?)?.toDouble(),
      fotosLocal:
          ((j['fotosLocal'] as List?) ?? []).whereType<String>().toList(),
      diasNoTopo: (j['diasNoTopo'] as num?)?.toInt(),
      ultimoReinadoDias: (j['ultimoReinadoDias'] as num?)?.toInt(),
    );
  }
}

class NecessidadeResumo {
  final int id;
  final String titulo;
  final String categoria;
  final bool urgente;
  final String status;

  const NecessidadeResumo({
    required this.id,
    required this.titulo,
    required this.categoria,
    required this.urgente,
    required this.status,
  });

  factory NecessidadeResumo.fromJson(Map<String, dynamic> j) => NecessidadeResumo(
        id: (j['id'] ?? 0) as int,
        titulo: j['titulo'] ?? '',
        categoria: j['categoria'] ?? '',
        urgente: j['urgente'] ?? false,
        status: j['status'] ?? '',
      );
}

class CampanhaResumo {
  final int id;
  final String titulo;
  final double metaValor;
  final double valorArrecadado;
  final int progresso;
  final bool encerrada;

  const CampanhaResumo({
    required this.id,
    required this.titulo,
    required this.metaValor,
    required this.valorArrecadado,
    required this.progresso,
    required this.encerrada,
  });

  factory CampanhaResumo.fromJson(Map<String, dynamic> j) => CampanhaResumo(
        id: (j['id'] ?? 0) as int,
        titulo: j['titulo'] ?? '',
        metaValor: ((j['metaValor'] ?? 0) as num).toDouble(),
        valorArrecadado: ((j['valorArrecadado'] ?? 0) as num).toDouble(),
        progresso: (j['progresso'] ?? 0) as int,
        encerrada: j['encerrada'] ?? false,
      );
}

class AvaliacaoResumo {
  final String doadorNome;
  final int nota;
  final String? comentario;

  const AvaliacaoResumo({
    required this.doadorNome,
    required this.nota,
    this.comentario,
  });

  factory AvaliacaoResumo.fromJson(Map<String, dynamic> j) => AvaliacaoResumo(
        doadorNome: j['doadorNome'] ?? 'Anonimo',
        nota: (j['nota'] ?? 0) as int,
        comentario: j['comentario'] as String?,
      );
}

class PrestacaoResumo {
  final String titulo;
  final String descricao;

  /// Fotos da prestacao (base64) e valor utilizado, quando informados.
  final List<String> fotos;
  final double? valorUtilizado;

  /// Contraparte: o doador para quem esta prestação foi feita. [doadorId]
  /// permite abrir o perfil público do doador; quando null, degrada (sem
  /// link/agrupamento por doador).
  final int? doadorId;
  final String? doadorNome;

  const PrestacaoResumo({
    required this.titulo,
    required this.descricao,
    this.fotos = const [],
    this.valorUtilizado,
    this.doadorId,
    this.doadorNome,
  });

  factory PrestacaoResumo.fromJson(Map<String, dynamic> j) => PrestacaoResumo(
        titulo: j['titulo'] ?? '',
        descricao: j['descricao'] ?? '',
        fotos: ((j['fotos'] as List?) ?? []).whereType<String>().toList(),
        valorUtilizado: (j['valorUtilizado'] as num?)?.toDouble(),
        doadorId: (j['doadorId'] as num?)?.toInt(),
        doadorNome: j['doadorNome'] as String?,
      );
}
