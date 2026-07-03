import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../models/ong.dart';
import '../../models/necessidade.dart';
import '../../models/interesse.dart';
import '../../models/campanha.dart';
import '../../models/atividade.dart';
import '../../models/doacao_financeira.dart';
import '../../services/api_service.dart';
import '../../services/doacao_financeira_service.dart';
import '../../services/ong_service.dart';
import '../../services/necessidade_service.dart';
import '../../services/interesse_service.dart';
import '../../services/prestacao_service.dart';
import '../../services/campanha_service.dart';
import '../../services/atividade_service.dart';
import '../../services/perfil_publico_service.dart';
import '../../services/relatorio_pdf_service.dart';
import '../auth/login_screen.dart';
import 'chat_ong_screen.dart';
import 'configuracoes_screen.dart';
import 'perfil_publico_ong_screen.dart';
import 'mural_impacto_screen.dart';
import 'ranking_transparencia_screen.dart';
import 'conquistas_screen.dart';
import 'perfil_screen.dart';
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

  // Aba "Doações": estados proprios (loading/erro/lista) para a aba poder
  // falhar e ser recarregada sem derrubar o resto do painel.
  List<DoacaoFinanceira> _doacoes = [];
  bool _carregandoDoacoes = true;
  String? _erroDoacoes;

  // Selo "verificada" do cabecalho (best-effort, via perfil publico).
  bool _verificada = false;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
    _carregarDoacoes();
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
      // Feed global da plataforma — best-effort: se falhar, o painel
      // continua funcionando com a timeline vazia.
      List<Atividade> ativs = [];
      try {
        ativs = await _atividadeService.listarRecentes();
      } catch (_) {
        ativs = [];
      }
      // Selo "verificada" do cabecalho — tambem best-effort.
      try {
        final perfil = await PerfilPublicoService().buscar(widget.ong.id);
        _verificada = perfil.verificada;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _necessidades = nec;
        _interesses = ints;
        _campanhas = camps;
        _atividades = ativs;
        _carregando = false;
      });
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

  Future<void> _abrirPrestarContas(Interesse it) async {
    final tituloC = TextEditingController();
    final descC = TextEditingController();
    final fotoC = TextEditingController();
    // Guarda anti-duplo-clique: setada sincronamente antes do 1o await, entao um
    // segundo toque no "Publicar" e ignorado (evita prestacao de contas duplicada).
    bool enviando = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Prestar contas'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tituloC,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Título'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descC,
                maxLines: 3,
                decoration: const InputDecoration(
                    labelText: 'O que foi feito com a doação'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fotoC,
                decoration:
                    const InputDecoration(labelText: 'URL da foto (opcional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Sem titulo o botao parecia "morto": agora avisa o usuario.
              if (tituloC.text.trim().isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Informe um título para a prestação de contas.'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              if (enviando) return;
              enviando = true;
              try {
                await PrestacaoService().criar(
                  interesseId: it.id,
                  titulo: tituloC.text.trim(),
                  descricao: descC.text.trim(),
                  fotoUrl: fotoC.text.trim(),
                );
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (e) {
                enviando = false; // permite tentar de novo apos falha
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(ApiService.mensagemAmigavel(e)),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    // Libera os controllers depois que o dialogo fecha (evita vazamento).
    tituloC.dispose();
    descC.dispose();
    fotoC.dispose();

    if (ok == true && mounted) {
      AppSnackbar.sucesso(context, 'Prestação de contas publicada! 🧾');
    }
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
            IconButton(
              tooltip: 'Relatório PDF',
              onPressed: _gerarRelatorioPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              tooltip: 'Mural de Impacto',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MuralImpactoScreen(),
                ),
              ),
              icon: const Icon(Icons.public),
            ),
            IconButton(
              tooltip: 'Ranking de Transparência',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RankingTransparenciaScreen(),
                ),
              ),
              icon: const Icon(Icons.leaderboard_outlined),
            ),
            IconButton(
              tooltip: 'Conquistas',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConquistasScreen(ongId: widget.ong.id),
                ),
              ),
              icon: const Icon(Icons.emoji_events_outlined),
            ),
            IconButton(
              tooltip: 'Ver meu perfil público',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PerfilPublicoOngScreen(
                    ongId: widget.ong.id,
                    ongNome: widget.ong.nome,
                  ),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined),
            ),
            IconButton(
              tooltip: 'Meu Perfil',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PerfilScreen()),
              ),
              icon: const Icon(Icons.person_outline),
            ),
            IconButton(
              tooltip: 'Configurações',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ConfiguracoesScreen()),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
            IconButton(
              tooltip: 'Sair',
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            labelColor: _verde,
            indicatorColor: _verde,
            tabs: [
              Tab(text: 'Necessidades (${_necessidades.length})'),
              Tab(text: 'Interesses (${_interesses.length})'),
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

  // ---- Resumo em numeros (dashboard da ONG) ----
  Widget _statsHeader() {
    final matches =
        _interesses.where((i) => i.status == 'ACEITO').length;
    final totalPix = _doacoes.fold<double>(0, (s, d) => s + d.valor);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xs),
      child: Row(
        children: [
          _statMini(Icons.campaign, '${_necessidades.length}',
              'Necessidades', _verde),
          const SizedBox(width: 14),
          _statMini(Icons.people, '${_interesses.length}', 'Interesses',
              AppColors.info),
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
            trailing: n.urgente
                ? Chip(
                    label: const Text('Urgente'),
                    backgroundColor: AppColors.error.withValues(alpha: 0.12),
                    labelStyle: const TextStyle(color: AppColors.error),
                    side: BorderSide.none,
                  )
                : Text(n.status,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        );
      },
    );
  }

  // ---- ABA 2: interesses recebidos ----
  Widget _abaInteresses() {
    if (_interesses.isEmpty) {
      return const EmptyState(
        icone: Icons.people_outline,
        mensagem: 'Nenhum interesse recebido ainda',
        detalhe: 'Assim que um doador se interessar, aparece aqui.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _interesses.length,
      itemBuilder: (context, i) {
        final it = _interesses[i];
        final pendente = it.status == 'PENDENTE';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
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
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                ),
                if (pendente) ...[
                  TextButton.icon(
                    onPressed: () => _recusar(it),
                    icon: const Icon(Icons.close, color: AppColors.error),
                    label: const Text('Recusar',
                        style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _aceitar(it),
                    icon: const Icon(Icons.check),
                    label: const Text('Aceitar'),
                  ),
                ] else if (it.status == 'ACEITO') ...[
                  _statusBadge(it.status),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _abrirPrestarContas(it),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('Prestar contas'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatOngScreen(
                            interesseId: it.id,
                            titulo: it.doadorNome ?? 'Doador',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Conversar'),
                  ),
                ] else
                  _statusBadge(it.status),
              ],
            ),
          ),
        );
      },
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
                    child: const Text('Encerrar'),
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
                Text(
                    'R\$ ${c.valorArrecadado.toStringAsFixed(0)} de '
                    'R\$ ${c.metaValor.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
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
        trailing: Column(
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

  const _FormNecessidade({required this.ongId});

  @override
  State<_FormNecessidade> createState() => _FormNecessidadeState();
}

class _FormNecessidadeState extends State<_FormNecessidade> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  // Categoria canonica (mesma lista do mobile e do backend).
  String _categoria = Categorias.todas.first.valor;
  bool _urgente = false;
  bool _enviando = false;

  final NecessidadeService _service = NecessidadeService();

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await _service.criar(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        categoria: _categoria,
        urgente: _urgente,
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
      title: const Text('Publicar necessidade'),
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
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe a descrição'
                      : null,
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
              : const Text('Publicar'),
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
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Mínimo 3 caracteres'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricao,
                  maxLines: 3,
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
