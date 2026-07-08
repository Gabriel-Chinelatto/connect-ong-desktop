/// Preferencias/configuracoes do usuario (espelha a entidade do backend).
class Preferencia {
  String tema; // CLARO, ESCURO, AUTOMATICO
  String tamanhoFonte; // PEQUENA, MEDIA, GRANDE
  bool altoContraste;
  bool fonteDislexia;
  bool navegacaoSimplificada;
  bool notifMensagens;
  bool notifMatch;
  bool notifCampanhas;
  bool notifNecessidades;
  bool notifNoticias;
  bool mostrarTelefone;
  bool mostrarEmail;
  bool perfilPublico;
  bool receberContatos;
  bool receberSugestoes;

  /// Verificação em duas etapas (2FA) no login. Persistida junto das demais
  /// preferências. Campo ausente (backend antigo) = desligado.
  bool doisFatores;

  Preferencia({
    this.tema = 'AUTOMATICO',
    this.tamanhoFonte = 'MEDIA',
    this.altoContraste = false,
    this.fonteDislexia = false,
    this.navegacaoSimplificada = false,
    this.notifMensagens = true,
    this.notifMatch = true,
    this.notifCampanhas = true,
    this.notifNecessidades = true,
    this.notifNoticias = true,
    this.mostrarTelefone = true,
    this.mostrarEmail = false,
    this.perfilPublico = true,
    this.receberContatos = true,
    this.receberSugestoes = true,
    this.doisFatores = false,
  });

  factory Preferencia.fromJson(Map<String, dynamic> j) {
    bool b(dynamic v, bool padrao) => v is bool ? v : padrao;
    // O backend armazena "doisFatores" como INTEIRO (0/1), nao como boolean:
    // o GET devolve 0/1 e o PUT exige 0/1 (enviar `true`/`false` gera HTTP 400
    // "Corpo da requisicao invalido ou mal formatado."). Aceitamos ambos os
    // formatos na leitura para robustez (bool de versoes antigas ou int atual).
    bool doisFatores(dynamic v) => v == true || v == 1;
    return Preferencia(
      tema: j['tema'] ?? 'AUTOMATICO',
      tamanhoFonte: j['tamanhoFonte'] ?? 'MEDIA',
      altoContraste: b(j['altoContraste'], false),
      fonteDislexia: b(j['fonteDislexia'], false),
      navegacaoSimplificada: b(j['navegacaoSimplificada'], false),
      notifMensagens: b(j['notifMensagens'], true),
      notifMatch: b(j['notifMatch'], true),
      notifCampanhas: b(j['notifCampanhas'], true),
      notifNecessidades: b(j['notifNecessidades'], true),
      notifNoticias: b(j['notifNoticias'], true),
      mostrarTelefone: b(j['mostrarTelefone'], true),
      mostrarEmail: b(j['mostrarEmail'], false),
      perfilPublico: b(j['perfilPublico'], true),
      receberContatos: b(j['receberContatos'], true),
      receberSugestoes: b(j['receberSugestoes'], true),
      doisFatores: doisFatores(j['doisFatores']),
    );
  }

  Map<String, dynamic> toJson() => {
        'tema': tema,
        'tamanhoFonte': tamanhoFonte,
        'altoContraste': altoContraste,
        'fonteDislexia': fonteDislexia,
        'navegacaoSimplificada': navegacaoSimplificada,
        'notifMensagens': notifMensagens,
        'notifMatch': notifMatch,
        'notifCampanhas': notifCampanhas,
        'notifNecessidades': notifNecessidades,
        'notifNoticias': notifNoticias,
        'mostrarTelefone': mostrarTelefone,
        'mostrarEmail': mostrarEmail,
        'perfilPublico': perfilPublico,
        'receberContatos': receberContatos,
        'receberSugestoes': receberSugestoes,
        // Enviar como INTEIRO (1/0): o backend rejeita boolean com HTTP 400.
        'doisFatores': doisFatores ? 1 : 0,
      };

  Preferencia copy() => Preferencia.fromJson(toJson());
}
