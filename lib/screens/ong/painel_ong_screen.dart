import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../models/ong.dart';
import '../../models/necessidade.dart';
import '../../models/interesse.dart';
import '../../models/campanha.dart';
import '../../models/atividade.dart';
import '../../models/doacao_financeira.dart';
import '../../models/prestacao.dart';
import '../../models/perfil_publico_doador.dart';
import '../../services/api_service.dart';
import '../../services/doacao_financeira_service.dart';
import '../../services/ong_service.dart';
import '../../services/necessidade_service.dart';
import '../../services/ia_service.dart';
import '../../services/interesse_service.dart';
import '../../services/prestacao_service.dart';
import '../../services/avaliacao_doador_service.dart';
import '../../services/campanha_service.dart';
import '../../services/atividade_service.dart';
import '../../services/perfil_publico_service.dart';
import '../../services/relatorio_pdf_service.dart';
import '../../widgets/common/dialog_pontuacao.dart';
import '../auth/login_screen.dart';
import 'chat_ong_screen.dart';
import 'configuracoes_screen.dart';
import 'desenvolvimento_chat_screen.dart';
import 'dialogs_match.dart';
import 'editar_ong_screen.dart';
import 'perfil_publico_ong_screen.dart';
import 'perfil_publico_doador_screen.dart';
import 'sobre_projeto_screen.dart';
import 'mural_impacto_screen.dart';
import 'ranking_transparencia_screen.dart';
import 'conquistas_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/categorias.dart';
import '../../config/config_controller.dart';
import '../../widgets/notificacao_bell.dart';
import '../../widgets/feedback/app_snackbar.dart';
import '../../widgets/feedback/empty_state.dart';

const Color _verde = AppColors.primary;

/// Painel administrativo da ONG (desktop).
/// Resolve qual ONG o usuario gerencia (pelo email, com seletor de fallback)
/// e mostra o painel com necessidades publicadas e interesses recebidos.
class PainelOngScreen extends StatefulWidget {
  final String emailUsuario;
  final int? ongId;
  final String? ongNome;

  /// Aba do painel aberta inicialmente (0 = Necessidades ... 3 = Doações).
  final int abaInicial;

  const PainelOngScreen({
    super.key,
    required this.emailUsuario,
    this.ongId,
    this.ongNome,
    this.abaInicial = 0,
  });

  @override
  State<PainelOngScreen> createState() => _PainelOngScreenState();
}

class _PainelOngScreenState extends State<PainelOngScreen> {
  final OngService _ongService = OngService();

  Ong? _ong;
  List<Ong> _todasOngs = [];
  bool _carregando = true;
  bool _erro = false;

  @override
  void initState() {
    super.initState();
    _resolverOng();
  }

  Future<void> _resolverOng() async {
    setState(() {
      _carregando = true;
      _erro = false;
    });

    // Caminho direto: o login ja trouxe o ongId vinculado ao perfil.
    if (widget.ongId != null) {
      setState(() {
        _ong = Ong(
          id: widget.ongId!,
          nome: widget.ongNome ?? 'Minha ONG',
          email: widget.emailUsuario,
          cidade: '',
        );
        _carregando = false;
      });
      return;
    }

    try {
      final encontrada =
          await _ongService.buscarPorEmail(widget.emailUsuario);
      if (!mounted) return;
      if (encontrada != null) {
        setState(() {
          _ong = encontrada;
          _carregando = false;
        });
      } else {
        final todas = await _ongService.listarTodas();
        if (!mounted) return;
        setState(() {
          _todasOngs = todas;
          _carregando = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Falha de rede ao resolver a ONG: mostra tela de erro com "Tentar de
      // novo" em vez de cair no seletor vazio (estado enganoso).
      setState(() {
        _carregando = false;
        _erro = true;
      });
    }
  }

  void _logout() {
    ConfigController.instance.limpar();
    // Limpa o token JWT em memoria ao sair.
    ApiService.setToken(null);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_erro) {
      return _buildErro();
    }
    if (_ong == null) {
      return _buildSeletor();
    }
    return _PainelConteudo(
      ong: _ong!,
      onLogout: _logout,
      abaInicial: widget.abaInicial,
    );
  }

  // Tela de falha ao carregar a ONG, com acao para tentar novamente.
  Widget _buildErro() {
    return Scaffold(
      appBar: AppBar(title: const Text('Painel')),
      body: EmptyState(
        icone: Icons.cloud_off_outlined,
        mensagem: 'Não foi possível carregar',
        detalhe: 'Verifique sua conexão e tente novamente.',
        acaoRotulo: 'Tentar de novo',
        onAcao: _resolverOng,
      ),
    );
  }

  // Mostrado quando o email do login nao corresponde a nenhuma ONG.
  Widget _buildSeletor() {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecione sua ONG')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Não encontramos uma ONG com o seu email. '
                  'Selecione qual ONG você gerencia:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                if (_todasOngs.isEmpty)
                  const Text('Nenhuma ONG cadastrada ainda.')
                else
                  ..._todasOngs.map(
                    (o) => Card(
                      child: ListTile(
                        leading:
                            const Icon(Icons.handshake, color: _verde),
                        title: Text(o.nome),
                        subtitle: Text(o.cidade),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => setState(() => _ong = o),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// CONTEUDO DO PAINEL (com as duas abas)
// ===========================================================================
class _PainelConteudo extends StatefulWidget {
  final Ong ong;
  final VoidCallback onLogout;

  /// Aba aberta inicialmente (repassada ao DefaultTabController).
  final int abaInicial;

  const _PainelConteudo({
    required this.ong,
    required this.onLogout,
    this.abaInicial = 0,
  });

  @override
  State<_PainelConteudo> createState() => _PainelConteudoState();
}

class _PainelConteudoState extends State<_PainelConteudo> {
  final NecessidadeService _necessidadeService = NecessidadeService();
  final InteresseService _interesseService = InteresseService();
  final CampanhaService _campanhaService = CampanhaService();
  final AtividadeService _atividadeService = AtividadeService();
  final DoacaoFinanceiraService _doacaoFinanceiraService =
      DoacaoFinanceiraService();

  List<Necessidade> _necessidades = [];
  List<Interesse> _interesses = [];
  List<Campanha> _campanhas = [];
  List<Atividade> _atividades = [];
  bool _carregando = true;

  // Sub-aba dos interesses: 0 = Ativos (pendentes+aceitos), 1 = Recusados,
  // 2 = Concluídos. Separa o que precisa de acao do historico.
  int _subInteresses = 0;

  List<Interesse> get _interessesAtivos => _interesses
      .where((i) => i.status == 'PENDENTE' || i.status == 'ACEITO')
      .toList();
  List<Interesse> get _interessesRecusados =>
      _interesses.where((i) => i.status == 'RECUSADO').toList();
  List<Interesse> get _interessesConcluidos =>
      _interesses.where((i) => i.status == 'CONCLUIDO').toList();

  // Pendencias de prestacao de contas (matches CONCLUIDOS sem prestacao).
  // Alimenta o banner do topo e a secao no comeco da aba Interesses.
  List<PendenciaPrestacao> _pendencias = [];

  // Minha avaliacao (desta ONG) por doador, para o botao virar
  // "Editar avaliação" e o dialog abrir pre-carregado. Best-effort.
  Map<int, AvaliacaoDoador> _minhasAvaliacoes = {};

  // Aba "Doações": estados proprios (loading/erro/lista) para a aba poder
  // falhar e ser recarregada sem derrubar o resto do painel.
  List<DoacaoFinanceira> _doacoes = [];
  bool _carregandoDoacoes = true;
  String? _erroDoacoes;

  // Selo "verificada" do cabecalho (best-effort, via perfil publico).
  bool _verificada = false;

  // ---- Interesses em tempo real ----
  // Polling leve (a cada 4s) so da lista de interesses, para um novo interesse
  // do doador aparecer sem o usuario sair e reabrir o painel. Detecta ids ainda
  // nao vistos e avisa com um toast "Novo interesse recebido!".
  Timer? _timerInteresses;
  Set<int> _idsInteressesVistos = {};
  bool _interessesInicializados = false;
  bool _pollEmCurso = false;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
    _carregarDoacoes();
    _timerInteresses = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _pollInteresses(),
    );
  }

  @override
  void dispose() {
    _timerInteresses?.cancel();
    super.dispose();
  }

  /// Poll leve da lista de interesses (sem recarregar o painel inteiro).
  /// Ao detectar interesses novos (id nunca visto), avisa e atualiza a lista e
  /// o contador do cabecalho. Best-effort: erros de rede sao ignorados.
  Future<void> _pollInteresses() async {
    if (_pollEmCurso || !mounted) return;
    _pollEmCurso = true;
    try {
      final lista = await _interesseService.listarPorOng(widget.ong.id);
      if (!mounted) return;
      final novos = _interessesInicializados
          ? lista.where((i) => !_idsInteressesVistos.contains(i.id)).length
          : 0;
      setState(() => _interesses = lista);
      _idsInteressesVistos = lista.map((i) => i.id).toSet();
      _interessesInicializados = true;
      if (novos > 0) {
        AppSnackbar.info(
          context,
          novos == 1
              ? 'Novo interesse recebido! 💚'
              : '$novos novos interesses recebidos! 💚',
        );
      }
    } catch (_) {
      // Silencioso: o proximo tick tenta de novo.
    } finally {
      _pollEmCurso = false;
    }
  }

  /// Carrega as doacoes PIX recebidas pela ONG (aba "Doações").
  Future<void> _carregarDoacoes() async {
    setState(() {
      _carregandoDoacoes = true;
      _erroDoacoes = null;
    });
    try {
      final ds = await _doacaoFinanceiraService.listarPorOng(widget.ong.id);
      if (!mounted) return;
      setState(() {
        _doacoes = ds;
        _carregandoDoacoes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _carregandoDoacoes = false;
        _erroDoacoes = ApiService.mensagemAmigavel(e);
      });
    }
  }

  Future<void> _carregarTudo() async {
    setState(() => _carregando = true);
    try {
      // Carrega as tres listas essenciais em paralelo (mais rapido que 3 awaits
      // sequenciais). O feed global e best-effort e vem depois.
      final resultados = await Future.wait([
        _necessidadeService.listarPorOng(widget.ong.id),
        _interesseService.listarPorOng(widget.ong.id),
        _campanhaService.listarPorOng(widget.ong.id),
      ]);
      final nec = resultados[0] as List<Necessidade>;
      final ints = resultados[1] as List<Interesse>;
      final camps = resultados[2] as List<Campanha>;
      if (!mounted) return;
      // Mostra JA o essencial (o painel aparece imediatamente); os dados
      // best-effort abaixo carregam em paralelo e preenchem em seguida.
      setState(() {
        _necessidades = nec;
        _interesses = ints;
        _campanhas = camps;
        _carregando = false;
      });
      // Base do polling em tempo real: a partir daqui, ids ainda nao vistos
      // sao considerados "novos interesses".
      _idsInteressesVistos = ints.map((i) => i.id).toSet();
      _interessesInicializados = true;

      // Os 4 blocos best-effort agora rodam em PARALELO (antes eram awaits em
      // serie, somando a latencia de cada um — principal causa da lentidao ao
      // abrir o painel). Cada um trata o proprio erro e nao derruba os outros.
      await Future.wait<void>([
        // Feed global da plataforma.
        () async {
          try {
            _atividades = await _atividadeService.listarRecentes();
          } catch (_) {
            _atividades = [];
          }
        }(),
        // Selo "verificada" do cabecalho.
        () async {
          try {
            final perfil = await PerfilPublicoService().buscar(widget.ong.id);
            _verificada = perfil.verificada;
          } catch (_) {}
        }(),
        // Pendencias de prestacao de contas.
        () async {
          try {
            _pendencias = await PrestacaoService().pendencias(widget.ong.id);
          } catch (_) {
            _pendencias = [];
          }
        }(),
        // Minhas avaliacoes dos doadores com match CONCLUIDO. O GET publico so
        // traz ongNome (sem ongId), entao compara com o nome da ONG da sessao.
        // As consultas por doador tambem vao em paralelo (antes era N+1 serie).
        () async {
          try {
            final doadores = ints
                .where((i) => i.status == 'CONCLUIDO' && i.doadorId != null)
                .map((i) => i.doadorId!)
                .toSet()
                .toList();
            final listas = await Future.wait(doadores
                .map((d) => AvaliacaoDoadorService().listarPorDoador(d)));
            final mapa = <int, AvaliacaoDoador>{};
            for (var k = 0; k < doadores.length; k++) {
              for (final a in listas[k]) {
                if (a.ongNome != null && a.ongNome == widget.ong.nome) {
                  mapa[doadores[k]] = a;
                  break;
                }
              }
            }
            _minhasAvaliacoes = mapa;
          } catch (_) {}
        }(),
      ]);
      if (!mounted) return;
      // Reflete os dados best-effort que chegaram (atividades, selo, pendencias,
      // avaliacoes). O essencial ja foi mostrado acima.
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      setState(() => _carregando = false);
      AppSnackbar.erro(context, 'Erro ao carregar dados do painel');
    }
  }

  /// Bloco 30: gera e abre o relatorio em PDF da ONG.
  Future<void> _gerarRelatorioPdf() async {
    AppSnackbar.info(context, 'Gerando relatório PDF...');
    try {
      final p = await PerfilPublicoService().buscar(widget.ong.id);
      final bytes = await RelatorioPdfService.relatorioOng(p);
      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, 'Erro ao gerar relatório PDF');
    }
  }

  // Guarda anti-duplo-clique para as acoes de mutacao (aceitar/recusar/encerrar).
  // Sem ela, dois toques rapidos disparavam dois PUT; o segundo falhava ("ja
  // aceito") e mostrava "Erro ao aceitar" logo apos um sucesso.
  bool _acaoEmCurso = false;

  Future<void> _aceitar(Interesse i) async {
    if (_acaoEmCurso) return;
    _acaoEmCurso = true;
    try {
      await _interesseService.aceitar(i.id);
      if (!mounted) return;
      AppSnackbar.sucesso(context, 'Interesse aceito! Match criado. 💚');
      _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, 'Erro ao aceitar');
    } finally {
      _acaoEmCurso = false;
    }
  }

  Future<void> _recusar(Interesse i) async {
    if (_acaoEmCurso) return;
    _acaoEmCurso = true;
    try {
      await _interesseService.recusar(i.id);
      if (!mounted) return;
      AppSnackbar.aviso(context, 'Interesse recusado.');
      _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, 'Erro ao recusar');
    } finally {
      _acaoEmCurso = false;
    }
  }

  Future<void> _abrirFormPublicar() async {
    final publicou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormNecessidade(ongId: widget.ong.id),
    );
    if (publicou == true && mounted) {
      AppSnackbar.sucesso(context, 'Necessidade publicada! 🎉');
      _carregarTudo();
    }
  }

  /// Abre o formulario de necessidade pre-preenchido para EDICAO (PUT).
  Future<void> _abrirFormEditarNecessidade(Necessidade n) async {
    final editou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormNecessidade(ongId: widget.ong.id, necessidade: n),
    );
    if (editou == true && mounted) {
      AppSnackbar.sucesso(context, 'Necessidade atualizada! ✏️');
      _carregarTudo();
    }
  }

  /// Exclui uma necessidade (com confirmacao). Degrada com backend antigo:
  /// se a rota nao existir, mostra erro amigavel sem quebrar o painel.
  Future<void> _excluirNecessidade(Necessidade n) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir necessidade?'),
        content: Text(
            'Tem certeza que deseja excluir "${n.titulo}"? '
            'Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    if (_acaoEmCurso) return;
    _acaoEmCurso = true;
    try {
      await _necessidadeService.excluir(n.id);
      if (!mounted) return;
      AppSnackbar.aviso(context, 'Necessidade excluída.');
      _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      _acaoEmCurso = false;
    }
  }

  Future<void> _abrirFormCampanha() async {
    final criou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormCampanha(ongId: widget.ong.id),
    );
    if (criou == true && mounted) {
      AppSnackbar.sucesso(context, 'Campanha criada! 🎉');
      _carregarTudo();
    }
  }

  Future<void> _encerrarCampanha(Campanha c) async {
    if (_acaoEmCurso) return;
    _acaoEmCurso = true;
    try {
      await _campanhaService.encerrar(c.id);
      if (!mounted) return;
      AppSnackbar.aviso(context, 'Campanha encerrada.');
      _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, 'Erro ao encerrar campanha');
    } finally {
      _acaoEmCurso = false;
    }
  }

  /// Marca a doacao de um match ACEITO como recebida (vira CONCLUIDO).
  /// Pede confirmacao porque a acao inicia o prazo de 10 dias da prestacao.
  Future<void> _concluir(Interesse it) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doação recebida?'),
        content: Text(
          'Confirmar que você recebeu a doação de '
          '${it.doadorNome ?? "este doador"}?\n\n'
          'Isso marca a doação como entregue e inicia o prazo de 10 dias '
          'para a prestação de contas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check),
            label: const Text('Doação recebida'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;

    if (_acaoEmCurso) return;
    _acaoEmCurso = true;
    try {
      await _interesseService.concluir(it.id);
      if (!mounted) return;
      AppSnackbar.sucesso(
          context, 'Doação marcada como recebida! O doador foi avisado. 💚');
      _carregarTudo();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      _acaoEmCurso = false;
    }
  }

  /// Abre o formulario rico de prestacao de contas (fotos + valor).
  Future<void> _abrirPrestarContas(int interesseId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => FormPrestacao(interesseId: interesseId),
    );
    if (ok == true && mounted) {
      AppSnackbar.sucesso(context, 'Prestação de contas publicada! 🧾');
      // Recarrega: a pendencia deste match (se havia) some da lista.
      _carregarTudo();
    }
  }

  /// Lista as prestacoes de contas ja publicadas neste match.
  void _verPrestacoes(Interesse it) {
    showDialog<void>(
      context: context,
      builder: (_) => DialogPrestacoes(
        interesseId: it.id,
        titulo: it.necessidadeTitulo ?? 'Prestações de contas',
      ),
    );
  }

  /// Avalia o doador de um match CONCLUIDO (1-5 estrelas, estilo Uber).
  /// Upsert: se ja avaliou, o dialog abre pre-carregado para edicao.
  Future<void> _avaliarDoador(Interesse it) async {
    if (it.doadorId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => DialogAvaliarDoador(
        doadorId: it.doadorId!,
        doadorNome: it.doadorNome ?? 'Doador',
        existente: _minhasAvaliacoes[it.doadorId!],
      ),
    );
    if (ok == true && mounted) {
      AppSnackbar.sucesso(context, 'Avaliação enviada. Obrigado! ⭐');
      _carregarTudo();
    }
  }

  /// Abre o perfil publico do doador (novo contrato /usuarios/{id}/perfil-publico).
  void _verPerfilDoador(Interesse it) {
    if (it.doadorId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PerfilPublicoDoadorScreen(
          doadorId: it.doadorId!,
          doadorNome: it.doadorNome ?? 'Doador',
        ),
      ),
    );
  }

  // Item padrao dos menus da AppBar (icone + texto). O texto e Flexible para
  // rotulos longos nao estourarem a largura do menu (overflow de pixels).
  PopupMenuItem<int> _menuItem(int valor, IconData icon, String texto) {
    return PopupMenuItem<int>(
      value: valor,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Flexible(child: Text(texto, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      initialIndex: widget.abaInicial,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel da ONG'),
          actions: [
            const NotificacaoBell(),
            // PERFIL: editar o perfil da ONG e ver o perfil público.
            PopupMenuButton<int>(
              tooltip: 'Perfil',
              icon: const Icon(Icons.account_circle_outlined),
              onSelected: (v) {
                if (v == 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditarOngScreen(ongId: widget.ong.id),
                    ),
                  );
                } else if (v == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PerfilPublicoOngScreen(
                        ongId: widget.ong.id,
                        ongNome: widget.ong.nome,
                      ),
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                _menuItem(0, Icons.storefront_outlined, 'Editar perfil da ONG'),
                _menuItem(1, Icons.visibility_outlined,
                    'Ver meu perfil público'),
              ],
            ),
            // TRANSPARÊNCIA & RELATÓRIOS: ranking, pontuação, conquistas,
            // mural de impacto e relatório PDF.
            PopupMenuButton<int>(
              tooltip: 'Transparência e relatórios',
              icon: const Icon(Icons.insights_outlined),
              onSelected: (v) {
                switch (v) {
                  case 0:
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const RankingTransparenciaScreen()));
                    break;
                  case 1:
                    mostrarComoPontuar(context);
                    break;
                  case 2:
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ConquistasScreen(ongId: widget.ong.id)));
                    break;
                  case 3:
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const MuralImpactoScreen()));
                    break;
                  case 4:
                    _gerarRelatorioPdf();
                    break;
                }
              },
              itemBuilder: (_) => [
                _menuItem(0, Icons.leaderboard_outlined,
                    'Ranking de transparência'),
                _menuItem(1, Icons.info_outline, 'Como pontuar'),
                _menuItem(2, Icons.emoji_events_outlined, 'Conquistas'),
                _menuItem(3, Icons.public, 'Mural de impacto'),
                _menuItem(4, Icons.picture_as_pdf_outlined, 'Relatório PDF'),
              ],
            ),
            // CONTA: configurações, sobre o projeto e sair.
            PopupMenuButton<int>(
              tooltip: 'Conta',
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                switch (v) {
                  case 0:
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ConfiguracoesScreen()));
                    break;
                  case 1:
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SobreProjetoScreen()));
                    break;
                  case 2:
                    widget.onLogout();
                    break;
                  case 3:
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const DesenvolvimentoChatScreen()));
                    break;
                }
              },
              itemBuilder: (_) => [
                _menuItem(0, Icons.settings_outlined, 'Configurações'),
                _menuItem(1, Icons.info_outline, 'Sobre o projeto'),
                _menuItem(3, Icons.code, 'Sobre o Desenvolvimento'),
                _menuItem(2, Icons.logout, 'Sair'),
              ],
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: _verde,
            indicatorColor: _verde,
            tabs: [
              Tab(text: 'Necessidades (${_necessidades.length})'),
              Tab(text: 'Interesses (${_interessesAtivos.length})'),
              Tab(text: 'Campanhas (${_campanhas.length})'),
              Tab(text: 'Doações (${_doacoes.length})'),
              Tab(text: 'Atividades (${_atividades.length})'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _abrirFormPublicar,
          backgroundColor: _verde,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Publicar necessidade'),
        ),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _cabecalhoOng(),
                  _statsHeader(),
                  // Builder: o atalho "Ver pendências" troca para a aba
                  // Interesses e precisa de um context ABAIXO do
                  // DefaultTabController criado neste build.
                  Builder(builder: (ctx) => _bannerPendencias(ctx)),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _abaNecessidades(),
                        _abaInteresses(),
                        _abaCampanhas(),
                        _abaDoacoes(),
                        _abaTimeline(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---- Cabecalho: identidade da ONG (nome + selo + contexto) ----
  Widget _cabecalhoOng() {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final inicial = widget.ong.nome.isNotEmpty
        ? widget.ong.nome[0].toUpperCase()
        : '?';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: _verde,
            child: Text(inicial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.ong.nome,
                        overflow: TextOverflow.ellipsis,
                        style: tt.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (_verificada) ...[
                      const SizedBox(width: 6),
                      const Tooltip(
                        message: 'ONG verificada',
                        child: Icon(Icons.verified,
                            color: AppColors.info, size: 20),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Painel administrativo • ${widget.ong.email}',
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- Banner de pendencias de prestacao de contas ----
  // Ambar quando ha pendencias no prazo; VERMELHO se alguma ja e definitiva
  // (prazo de 10 dias estourado = -5 pontos no score de transparencia).
  Widget _bannerPendencias(BuildContext ctx) {
    if (_pendencias.isEmpty) return const SizedBox.shrink();
    final temDefinitiva = _pendencias.any((p) => p.definitivo);
    final cor = temDefinitiva ? AppColors.error : AppColors.warning;
    final n = _pendencias.length;
    final titulo = n == 1
        ? 'Você tem 1 prestação de contas pendente'
        : 'Você tem $n prestações de contas pendentes';
    final detalhe = temDefinitiva
        ? 'Há pendência com prazo esgotado (definitiva): −5 pontos no seu '
            'score de transparência.'
        : 'Prazo: 10 dias após marcar a doação como recebida.';
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(temDefinitiva ? Icons.error_outline : Icons.warning_amber,
              color: cor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    style: TextStyle(fontWeight: FontWeight.w700, color: cor)),
                Text(detalhe,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          TextButton(
            // Leva para a aba Interesses, onde a lista de pendencias vive.
            onPressed: () => DefaultTabController.of(ctx).animateTo(1),
            child: Text('Ver pendências',
                style: TextStyle(color: cor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ---- Resumo em numeros (dashboard da ONG) ----
  Widget _statsHeader() {
    // Match "fechado" = aceito ou ja concluido (a conclusao nao desfaz o match).
    final matches = _interesses
        .where((i) => i.status == 'ACEITO' || i.status == 'CONCLUIDO')
        .length;
    final totalPix = _doacoes.fold<double>(0, (s, d) => s + d.valor);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          _statMini(Icons.campaign, '${_necessidades.length}',
              'Necessidades', _verde),
          const SizedBox(width: 14),
          _statMini(Icons.people, '${_interessesAtivos.length}',
              'Interesses ativos', AppColors.info),
          const SizedBox(width: 14),
          _statMini(Icons.handshake, '$matches', 'Matches fechados',
              Colors.pink.shade400),
          const SizedBox(width: 14),
          _statMini(Icons.savings_outlined, _formatarReal(totalPix),
              'Recebido em PIX', AppColors.warning),
        ],
      ),
    );
  }

  Widget _statMini(IconData icone, String numero, String rotulo, Color cor) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icone, color: cor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // FittedBox evita overflow com valores longos (ex.: R$).
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(numero,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                  ),
                  Text(rotulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: cs.onSurfaceVariant, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- ABA 1: necessidades publicadas ----
  Widget _abaNecessidades() {
    if (_necessidades.isEmpty) {
      return const EmptyState(
        icone: Icons.campaign_outlined,
        mensagem: 'Nenhuma necessidade publicada ainda',
        detalhe: 'Clique em "Publicar necessidade" para começar.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _necessidades.length,
      itemBuilder: (context, i) {
        final n = _necessidades[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _verde.withValues(alpha: 0.12),
              child: const Icon(Icons.campaign, color: _verde),
            ),
            title: Text(n.titulo,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${n.categoria} • ${n.descricao}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (n.urgente)
                  Chip(
                    label: const Text('Urgente'),
                    backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    labelStyle: const TextStyle(color: AppColors.error),
                    side: BorderSide.none,
                  )
                else
                  Text(n.status,
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant)),
                PopupMenuButton<String>(
                  tooltip: 'Opções da necessidade',
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == 'editar') _abrirFormEditarNecessidade(n);
                    if (v == 'excluir') _excluirNecessidade(n);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'editar',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Editar'),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'excluir',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Icons.delete_outline, color: AppColors.error),
                        title: Text('Excluir',
                            style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- ABA 2: interesses recebidos (+ pendencias de prestacao) ----
  Widget _abaInteresses() {
    if (_interesses.isEmpty && _pendencias.isEmpty) {
      return const EmptyState(
        icone: Icons.people_outline,
        mensagem: 'Nenhum interesse recebido ainda',
        detalhe: 'Assim que um doador se interessar, aparece aqui.',
      );
    }
    final ativos = _interessesAtivos;
    final recusados = _interessesRecusados;
    final concluidos = _interessesConcluidos;
    final fonte = _subInteresses == 1
        ? recusados
        : _subInteresses == 2
            ? concluidos
            : ativos;
    final vazioMsg = _subInteresses == 1
        ? 'Nenhuma doação recusada.'
        : _subInteresses == 2
            ? 'Nenhuma doação concluída ainda.'
            : 'Nenhum interesse ativo no momento.';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (_pendencias.isNotEmpty) ...[
          _tituloSecao('Prestações de contas pendentes'),
          for (final p in _pendencias) _cardPendencia(p),
          const SizedBox(height: AppSpacing.md),
        ],
        // Separa o que precisa de acao (Ativos) do historico (Recusados/
        // Concluidos). Wrap de chips: quebra linha em telas estreitas (sem
        // overflow de pixels, ao contrario do SegmentedButton).
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _chipInteresse(0, 'Ativos', ativos.length),
            _chipInteresse(1, 'Recusados', recusados.length),
            _chipInteresse(2, 'Concluídos', concluidos.length),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (fonte.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(vazioMsg),
          )
        else
          ..._interessesAgrupados(fonte),
      ],
    );
  }

  // Chip de filtro das sub-abas de interesses (Ativos/Recusados/Concluídos).
  Widget _chipInteresse(int valor, String rotulo, int n) {
    return ChoiceChip(
      label: Text('$rotulo ($n)'),
      selected: _subInteresses == valor,
      onSelected: (_) => setState(() => _subInteresses = valor),
    );
  }

  /// Monta a lista de interesses AGRUPADA por doador.
  ///
  /// Um doador com mais de um interesse/doação vira um card expansível (nome +
  /// avatar + contador + um único "Ver perfil do doador"); as doações
  /// CONCLUÍDAS vão para o fim, dentro do grupo. Com apenas um interesse, o
  /// card é direto (como antes). Interesses sem doadorId identificável não são
  /// agrupados (aparecem como cards diretos).
  List<Widget> _interessesAgrupados(List<Interesse> fonte) {
    final Map<int, List<Interesse>> porDoador = {};
    final List<int> ordem = [];
    final List<Interesse> semDoador = [];
    for (final it in fonte) {
      final id = it.doadorId;
      if (id == null) {
        semDoador.add(it);
        continue;
      }
      (porDoador[id] ??= (() {
        ordem.add(id);
        return <Interesse>[];
      })())
          .add(it);
    }

    final widgets = <Widget>[];
    for (final id in ordem) {
      final lista = porDoador[id]!;
      if (lista.length == 1) {
        widgets.add(_cardInteresse(lista.first));
      } else {
        widgets.add(_grupoDoador(lista));
      }
    }
    for (final it in semDoador) {
      widgets.add(_cardInteresse(it));
    }
    return widgets;
  }

  /// Card expansível de um doador com vários interesses/doações na ONG.
  Widget _grupoDoador(List<Interesse> lista) {
    final cs = Theme.of(context).colorScheme;
    final primeiro = lista.first;
    final nome = primeiro.doadorNome ?? 'Doador';
    // Dentro da sub-aba todos compartilham a mesma situacao; mantem a ordem.
    final ordenadas = lista;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        // Remove as divisórias padrão do ExpansionTile (visual mais limpo).
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(bottom: 8),
          leading: CircleAvatar(
            backgroundColor: _verde.withValues(alpha: 0.12),
            child: const Icon(Icons.person, color: _verde),
          ),
          title: Row(
            children: [
              Flexible(
                child: Text(nome,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _verde.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${lista.length} doações',
                  style: const TextStyle(
                      color: _verde,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    '${lista.length} ${lista.length == 1 ? "doação" : "doações"}'
                    ' deste doador',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
                if (primeiro.doadorId != null)
                  TextButton.icon(
                    onPressed: () => _verPerfilDoador(primeiro),
                    icon: const Icon(Icons.person_search_outlined, size: 18),
                    label: const Text('Ver perfil do doador'),
                  ),
              ],
            ),
          ),
          children: [
            for (final it in ordenadas)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _cardInteresse(it, emGrupo: true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _tituloSecao(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        texto,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  /// Card de uma pendencia: necessidade + doador + contagem regressiva do
  /// prazo de 10 dias + atalho para prestar contas na hora.
  Widget _cardPendencia(PendenciaPrestacao p) {
    final cor = p.definitivo ? AppColors.error : AppColors.warning;
    final String prazo;
    if (p.definitivo) {
      prazo = 'prazo esgotado — pendência definitiva';
    } else if (p.diasRestantes == 0) {
      prazo = 'último dia do prazo!';
    } else if (p.diasRestantes == 1) {
      prazo = 'falta 1 dia';
    } else {
      prazo = 'faltam ${p.diasRestantes} dias';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cor.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: cor.withValues(alpha: 0.12),
              child: Icon(
                  p.definitivo ? Icons.error_outline : Icons.hourglass_bottom,
                  color: cor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.necessidadeTitulo ?? 'Doação recebida',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(
                    'Doador: ${p.doadorNome ?? "-"} • '
                    'Recebida em ${_formatarDataCurta(p.dataConclusao)}',
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timer_outlined, size: 14, color: cor),
                        const SizedBox(width: 4),
                        Text(prazo,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: cor)),
                        if (p.definitivo) ...[
                          const SizedBox(width: 6),
                          Text('(−5 pontos de transparência)',
                              style: TextStyle(fontSize: 12, color: cor)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () => _abrirPrestarContas(p.interesseId),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('Prestar contas agora'),
            ),
          ],
        ),
      ),
    );
  }

  /// Card de um interesse/match, com as acoes do seu status atual.
  ///
  /// [emGrupo] = true quando o card e renderizado DENTRO de um grupo por
  /// doador: nesse caso o botao "Ver perfil do doador" e omitido (o grupo ja
  /// tem um unico botao no cabecalho, evitando repeticao).
  Widget _cardInteresse(Interesse it, {bool emGrupo = false}) {
    final cs = Theme.of(context).colorScheme;
    final concluido = it.status == 'CONCLUIDO';
    final jaAvaliei =
        it.doadorId != null && _minhasAvaliacoes.containsKey(it.doadorId);
    // Match concluido ainda sem prestacao de contas (aparece em _pendencias).
    final semPrestacao = _pendencias.any((p) => p.interesseId == it.id);

    // Acoes por status (em Wrap: nunca estouram a largura do card).
    final List<Widget> acoes;
    switch (it.status) {
      case 'PENDENTE':
        acoes = [
          // Ver o perfil do doador ANTES de decidir (reputação, avaliações).
          if (!emGrupo && it.doadorId != null)
            TextButton.icon(
              onPressed: () => _verPerfilDoador(it),
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: const Text('Ver perfil do doador'),
            ),
          TextButton.icon(
            onPressed: () => _recusar(it),
            icon: const Icon(Icons.close, color: AppColors.error),
            label: const Text('Recusar',
                style: TextStyle(color: AppColors.error)),
          ),
          ElevatedButton.icon(
            onPressed: () => _aceitar(it),
            icon: const Icon(Icons.check),
            label: const Text('Aceitar'),
          ),
        ];
        break;
      case 'ACEITO':
        // Match ativo: Conversar + Prestar contas + Doação recebida + Ver perfil.
        acoes = [
          ElevatedButton.icon(
            onPressed: () => _abrirChat(it),
            icon: const Icon(Icons.chat),
            label: const Text('Conversar'),
          ),
          OutlinedButton.icon(
            onPressed: () => _abrirPrestarContas(it.id),
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('Prestar contas'),
          ),
          ElevatedButton.icon(
            onPressed: () => _concluir(it),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Doação recebida'),
          ),
          if (!emGrupo && it.doadorId != null)
            TextButton.icon(
              onPressed: () => _verPerfilDoador(it),
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: const Text('Ver perfil do doador'),
            ),
        ];
        break;
      case 'CONCLUIDO':
        // Match encerrado: o chat vira Histórico (só leitura); prestar contas
        // apenas enquanto pendente, senão ver o que já foi prestado.
        acoes = [
          OutlinedButton.icon(
            onPressed: () => _abrirChat(it, historico: true),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('Histórico da conversa'),
          ),
          if (semPrestacao)
            OutlinedButton.icon(
              onPressed: () => _abrirPrestarContas(it.id),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('Prestar contas (+5 pts)'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _verPrestacoes(it),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Ver prestações'),
            ),
          if (it.doadorId != null)
            ElevatedButton.icon(
              onPressed: () => _avaliarDoador(it),
              icon: Icon(jaAvaliei ? Icons.edit : Icons.star_outline,
                  size: 18),
              label:
                  Text(jaAvaliei ? 'Editar avaliação' : 'Avaliar doador'),
            ),
          if (!emGrupo && it.doadorId != null)
            TextButton.icon(
              onPressed: () => _verPerfilDoador(it),
              icon: const Icon(Icons.person_search_outlined, size: 18),
              label: const Text('Ver perfil do doador'),
            ),
        ];
        break;
      default:
        acoes = const [];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _verde.withValues(alpha: 0.12),
                  child: const Icon(Icons.person, color: _verde),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(it.doadorNome ?? 'Doador',
                          style:
                              const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Interesse em: ${it.necessidadeTitulo ?? "-"}',
                          style: TextStyle(color: cs.onSurfaceVariant)),
                      _infoDatas(it),
                      // Há quantos dias o doador espera o aceite (só PENDENTE).
                      // A partir de 10 dias destaca em laranja (o backend também
                      // manda uma notificação nesse ponto e a cada 5 dias).
                      if (it.status == 'PENDENTE' && it.diasEsperando != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.hourglass_bottom,
                                size: 14,
                                color: it.diasEsperando! >= 10
                                    ? Colors.orange.shade800
                                    : cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              it.diasEsperando! <= 0
                                  ? 'Aguardando seu aceite (hoje)'
                                  : 'Há ${it.diasEsperando} '
                                      '${it.diasEsperando == 1 ? "dia" : "dias"} '
                                      'esperando seu aceite',
                              style: TextStyle(
                                fontSize: 12,
                                color: it.diasEsperando! >= 10
                                    ? Colors.orange.shade800
                                    : cs.onSurfaceVariant,
                                fontWeight: it.diasEsperando! >= 10
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Aviso discreto: a ONG bloqueou este doador (o envio
                      // de mensagens fica desabilitado no chat).
                      if (it.bloqueadoPelaOng) ...[
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block,
                                size: 14, color: cs.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text('Você bloqueou este doador',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: cs.onSurfaceVariant)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (concluido)
                  _chipConcluida(it)
                else if (it.status != 'PENDENTE')
                  _statusBadge(it.status),
              ],
            ),
            if (acoes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: acoes,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Chip verde do match concluido, com a data em que a doacao foi recebida.
  Widget _chipConcluida(Interesse it) {
    final data = _formatarDataCurta(it.dataConclusao);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _verde.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _verde.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: _verde),
          const SizedBox(width: 6),
          Text(
            data.isNotEmpty ? 'Concluída em $data' : 'Concluída',
            style: const TextStyle(
                color: _verde, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Abre o chat do match. Para matches CONCLUIDOS ([historico] = true) abre em
  /// modo SO LEITURA ("Histórico da conversa", sem campo de envio).
  Future<void> _abrirChat(Interesse it, {bool historico = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatOngScreen(
          interesseId: it.id,
          titulo: it.doadorNome ?? 'Doador',
          doadorId: it.doadorId,
          bloqueadoPelaOng: it.bloqueadoPelaOng,
          somenteLeitura: historico,
        ),
      ),
    );
    // O bloqueio pode ter mudado dentro do chat/perfil: recarrega os matches.
    if (mounted) _carregarTudo();
  }

  /// Formata uma data ISO como dd/MM/aaaa (ou vazio se nula/invalida).
  String _formatarDataCurta(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year}';
  }

  String _formatarDataHora(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso);
    if (d == null) return '';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  // Linha de datas do card, conforme o status: início (criação), aceite,
  // conclusão (início + conclusão) e recusa (com hora).
  Widget _infoDatas(Interesse it) {
    final cs = Theme.of(context).colorScheme;
    final ini = _formatarDataCurta(it.dataCriacao);
    String texto;
    switch (it.status) {
      case 'RECUSADO':
        final q = _formatarDataHora(it.dataStatus);
        texto = q.isEmpty ? '' : 'Recusado em $q';
        break;
      case 'CONCLUIDO':
        final fim = _formatarDataCurta(it.dataConclusao);
        texto = [
          if (ini.isNotEmpty) 'Início $ini',
          if (fim.isNotEmpty) 'Concluído em $fim',
        ].join(' · ');
        break;
      case 'ACEITO':
        final ace = _formatarDataCurta(it.dataStatus);
        texto = [
          if (ini.isNotEmpty) 'Início $ini',
          if (ace.isNotEmpty) 'Aceito em $ace',
        ].join(' · ');
        break;
      default: // PENDENTE
        texto = ini.isEmpty ? '' : 'Início $ini';
    }
    if (texto.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event, size: 13, color: cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Flexible(
            child: Text(texto,
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  // ---- ABA 3: campanhas da ONG ----
  Widget _abaCampanhas() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Text('Suas campanhas de arrecadação',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              ElevatedButton.icon(
                onPressed: _abrirFormCampanha,
                icon: const Icon(Icons.add),
                label: const Text('Nova campanha'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _campanhas.isEmpty
              ? const EmptyState(
                  icone: Icons.volunteer_activism_outlined,
                  mensagem: 'Nenhuma campanha criada ainda',
                  detalhe: 'Clique em "Nova campanha" para arrecadar.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _campanhas.length,
                  itemBuilder: (context, i) => _cardCampanha(_campanhas[i]),
                ),
        ),
      ],
    );
  }

  Widget _cardCampanha(Campanha c) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(c.titulo,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                if (c.destaque)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.star, color: Colors.amber, size: 20),
                  ),
                if (c.encerrada)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Encerrada',
                        style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  )
                else
                  TextButton(
                    onPressed: () => _encerrarCampanha(c),
                    child: const Text('Encerrar (+5 pts)'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(c.descricao,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: c.progresso / 100,
                minHeight: 10,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation<Color>(_verde),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Expanded + ellipsis: valores grandes (metas altas) não
                // empurram a porcentagem para fora do card.
                Expanded(
                  child: Text(
                    'R\$ ${c.valorArrecadado.toStringAsFixed(0)} de '
                    'R\$ ${c.metaValor.toStringAsFixed(0)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                Text('${c.progresso}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: _verde)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---- ABA 4: doacoes PIX recebidas pela ONG ----
  Widget _abaDoacoes() {
    if (_carregandoDoacoes) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erroDoacoes != null) {
      return EmptyState(
        icone: Icons.cloud_off_outlined,
        mensagem: 'Não foi possível carregar as doações',
        detalhe: _erroDoacoes,
        acaoRotulo: 'Tentar de novo',
        onAcao: _carregarDoacoes,
      );
    }
    if (_doacoes.isEmpty) {
      return const EmptyState(
        icone: Icons.volunteer_activism_outlined,
        mensagem: 'Nenhuma doação recebida ainda',
        detalhe: 'As doações PIX feitas pelos doadores aparecem aqui.',
      );
    }
    final total = _doacoes.fold<double>(0, (soma, d) => soma + d.valor);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        _cardTotalDoacoes(total),
        const SizedBox(height: 16),
        for (final d in _doacoes) _cardDoacao(d),
      ],
    );
  }

  // Destaque com o total somado das doacoes recebidas.
  Widget _cardTotalDoacoes(double total) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_verde, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.savings_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total recebido em doações PIX',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                _formatarReal(total),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${_doacoes.length} ${_doacoes.length == 1 ? "doação" : "doações"}',
            style: const TextStyle(
                color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _cardDoacao(DoacaoFinanceira d) {
    final confirmada = d.status.toUpperCase() == 'CONFIRMADO';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: _verde.withValues(alpha: 0.12),
          child: const Icon(Icons.pix, color: _verde),
        ),
        title: Text(d.doadorNome,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          _formatarData(d.data),
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        // FittedBox garante que a coluna (valor + status) caiba na altura que o
        // ListTile reserva ao trailing, sem o "BOTTOM OVERFLOWED BY 1 PIXEL".
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatarReal(d.valor),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _verde)),
              const SizedBox(height: 2),
              Text(
                confirmada ? 'Confirmada' : d.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: confirmada
                      ? AppColors.success
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formata um valor em reais no padrao pt-BR (ex.: R$ 1.234,56).
  String _formatarReal(double valor) {
    final partes = valor.toStringAsFixed(2).split('.');
    final inteiro = partes[0];
    final buf = StringBuffer();
    for (int i = 0; i < inteiro.length; i++) {
      if (i > 0 && (inteiro.length - i) % 3 == 0) buf.write('.');
      buf.write(inteiro[i]);
    }
    return 'R\$ $buf,${partes[1]}';
  }

  /// Formata a data como dd/mm/aaaa hh:mm (ou "—" se ausente).
  String _formatarData(DateTime? d) {
    if (d == null) return '—';
    String dois(int n) => n.toString().padLeft(2, '0');
    return '${dois(d.day)}/${dois(d.month)}/${d.year} às '
        '${dois(d.hour)}:${dois(d.minute)}';
  }

  // ---- ABA 5: timeline (feed global de atividades da plataforma) ----
  Widget _abaTimeline() {
    if (_atividades.isEmpty) {
      return const EmptyState(
        icone: Icons.timeline_outlined,
        mensagem: 'Nenhuma atividade recente na plataforma',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _atividades.length,
      itemBuilder: (context, i) => _cardAtividade(_atividades[i]),
    );
  }

  Widget _cardAtividade(Atividade a) {
    final tempo = _tempoRelativo(a.dataCriacao);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: _verde.withValues(alpha: 0.12),
              child: Icon(_iconeAtividade(a.tipo), color: _verde, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.descricao,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  if (a.ongNome != null && a.ongNome!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(a.ongNome!,
                        style: const TextStyle(fontSize: 13, color: _verde)),
                  ],
                  if (tempo.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(tempo,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconeAtividade(String tipo) {
    switch (tipo) {
      case 'NECESSIDADE':
        return Icons.favorite_outline;
      case 'INTERESSE':
        return Icons.volunteer_activism;
      case 'PRESTACAO':
        return Icons.receipt_long_outlined;
      case 'CAMPANHA':
        return Icons.campaign_outlined;
      case 'DOACAO':
        return Icons.attach_money;
      case 'AVALIACAO':
        return Icons.star_outline;
      default:
        return Icons.notifications_none;
    }
  }

  /// Converte a dataCriacao ISO em tempo relativo amigavel.
  /// Retorna vazio se a data for nula ou invalida.
  String _tempoRelativo(String? dataIso) {
    if (dataIso == null) return '';
    final data = DateTime.tryParse(dataIso);
    if (data == null) return '';
    final diff = DateTime.now().difference(data);
    if (diff.isNegative || diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours} h';
    return 'há ${diff.inDays} d';
  }

  Widget _statusBadge(String status) {
    final aceito = status == 'ACEITO';
    final cor = aceito ? _verde : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        aceito ? 'Match ✓' : 'Recusado',
        style: TextStyle(color: cor, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ===========================================================================
// FORMULARIO DE PUBLICAR NECESSIDADE (dialog)
// ===========================================================================
class _FormNecessidade extends StatefulWidget {
  final int ongId;

  /// Quando informada, o formulario abre em modo EDICAO (pre-preenchido) e o
  /// salvar faz PUT em vez de POST.
  final Necessidade? necessidade;

  const _FormNecessidade({required this.ongId, this.necessidade});

  @override
  State<_FormNecessidade> createState() => _FormNecessidadeState();
}

class _FormNecessidadeState extends State<_FormNecessidade> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  // Categoria canonica (mesma lista do mobile e do backend).
  late String _categoria;
  bool _urgente = false;
  bool _enviando = false;
  // Estado do botão "Escrever com IA" (redação assistida da descrição).
  bool _redigindo = false;

  final NecessidadeService _service = NecessidadeService();
  final IaService _ia = IaService();

  bool get _edicao => widget.necessidade != null;

  @override
  void initState() {
    super.initState();
    final n = widget.necessidade;
    _categoria = n?.categoria ?? Categorias.todas.first.valor;
    // Categoria fora da lista canonica (dado antigo): volta ao padrao para o
    // Dropdown nao quebrar por valor inexistente.
    if (!Categorias.todas.any((c) => c.valor == _categoria)) {
      _categoria = Categorias.todas.first.valor;
    }
    if (n != null) {
      _tituloController.text = n.titulo;
      _descricaoController.text = n.descricao;
      _urgente = n.urgente;
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  // "Escrever com IA": usa o rascunho (título + descrição + categoria) para
  // gerar um título curto e uma descrição clara e convincente para os doadores.
  // Preenche os campos com o resultado. Sem chave de IA, o backend responde no
  // modo "regras" (ainda limpa e estrutura o texto) — avisamos discretamente.
  Future<void> _redigirComIa() async {
    final rascunho = _descricaoController.text.trim();
    final titulo = _tituloController.text.trim();
    if (rascunho.isEmpty && titulo.isEmpty) {
      AppSnackbar.erro(
        context,
        'Escreva um rascunho do que a ONG precisa e a IA melhora para você.',
      );
      return;
    }
    setState(() => _redigindo = true);
    try {
      final r = await _ia.redigirNecessidade(
        titulo: titulo,
        rascunho: rascunho.isNotEmpty ? rascunho : titulo,
        categoria: _categoria,
      );
      if (!mounted) return;
      setState(() {
        if (r.titulo.isNotEmpty) _tituloController.text = r.titulo;
        if (r.descricao.isNotEmpty) _descricaoController.text = r.descricao;
        _redigindo = false;
      });
      if (r.modoRegras) {
        AppSnackbar.info(
          context,
          'Texto organizado no modo básico (IA indisponível no momento).',
        );
      } else {
        AppSnackbar.sucesso(context, 'Texto reescrito pela IA. Revise e ajuste.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _redigindo = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      if (_edicao) {
        await _service.editar(
          id: widget.necessidade!.id,
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
          categoria: _categoria,
          urgente: _urgente,
        );
      } else {
        await _service.criar(
          titulo: _tituloController.text.trim(),
          descricao: _descricaoController.text.trim(),
          categoria: _categoria,
          urgente: _urgente,
          ongId: widget.ongId,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.mensagemAmigavel(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_edicao ? 'Editar necessidade' : 'Publicar necessidade'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _tituloController,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  // Limites iguais aos do backend (NecessidadeRequestDTO):
                  // 3 a 150. Sem o minimo, um titulo de 1-2 letras so falhava
                  // ao salvar, com erro generico.
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Informe o título';
                    if (t.length < 3) return 'O título precisa de ao menos 3 letras';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                  maxLength: 2000, // igual ao backend
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe a descrição'
                      : null,
                ),
                // Redação assistida por IA: transforma o rascunho num texto
                // claro e convincente para os doadores.
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: (_enviando || _redigindo) ? null : _redigirComIa,
                    icon: _redigindo
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(_redigindo ? 'Escrevendo…' : 'Escrever com IA'),
                    style: TextButton.styleFrom(foregroundColor: _verde),
                  ),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [
                    for (final c in Categorias.todas)
                      DropdownMenuItem(
                        value: c.valor,
                        child: Row(
                          children: [
                            Icon(c.icone, size: 18, color: c.cor),
                            const SizedBox(width: 8),
                            Text(c.rotulo),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) =>
                      setState(() => _categoria = v ?? _categoria),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Marcar como urgente'),
                  activeThumbColor: _verde,
                  value: _urgente,
                  onChanged: (v) => setState(() => _urgente = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _enviando ? null : _publicar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(_edicao ? 'Salvar' : 'Publicar'),
        ),
      ],
    );
  }
}

// ===========================================================================
// FORMULARIO DE NOVA CAMPANHA (dialog)
// ===========================================================================
class _FormCampanha extends StatefulWidget {
  final int ongId;

  const _FormCampanha({required this.ongId});

  @override
  State<_FormCampanha> createState() => _FormCampanhaState();
}

class _FormCampanhaState extends State<_FormCampanha> {
  final _formKey = GlobalKey<FormState>();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  // Categoria canonica (mesma lista do mobile e do backend).
  String _categoria = Categorias.todas.first.valor;
  final _meta = TextEditingController();
  bool _destaque = false;
  bool _enviando = false;

  final CampanhaService _service = CampanhaService();

  @override
  void dispose() {
    _titulo.dispose();
    _descricao.dispose();
    _meta.dispose();
    super.dispose();
  }

  Future<void> _criar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await _service.criar(
        titulo: _titulo.text.trim(),
        descricao: _descricao.text.trim(),
        metaValor: double.parse(_meta.text.replaceAll(',', '.')),
        categoria: _categoria,
        destaque: _destaque,
        ongId: widget.ongId,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ApiService.mensagemAmigavel(e)),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova campanha'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titulo,
                  autofocus: true,
                  textInputAction: TextInputAction.next,
                  maxLength: 150, // igual ao backend (CampanhaRequestDTO)
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Mínimo 3 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricao,
                  maxLines: 3,
                  // A descricao da CAMPANHA e mais curta que a da necessidade
                  // no backend (255 x 2000) — o limite aqui evita o erro so na
                  // hora de salvar.
                  maxLength: 255,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe a descrição'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _meta,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration:
                      const InputDecoration(labelText: 'Meta (R\$)'),
                  validator: (v) {
                    final n = double.tryParse(
                        (v ?? '').replaceAll(',', '.'));
                    if (n == null || n <= 0) return 'Informe uma meta válida';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoria,
                  decoration: const InputDecoration(labelText: 'Categoria'),
                  items: [
                    for (final c in Categorias.todas)
                      DropdownMenuItem(
                        value: c.valor,
                        child: Row(
                          children: [
                            Icon(c.icone, size: 18, color: c.cor),
                            const SizedBox(width: 8),
                            Text(c.rotulo),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (v) =>
                      setState(() => _categoria = v ?? _categoria),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Destacar na plataforma'),
                  activeThumbColor: _verde,
                  value: _destaque,
                  onChanged: (v) => setState(() => _destaque = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _enviando ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _enviando ? null : _criar,
          child: _enviando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Text('Criar'),
        ),
      ],
    );
  }
}
