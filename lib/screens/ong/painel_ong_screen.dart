import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../models/ong.dart';
import '../../models/necessidade.dart';
import '../../models/interesse.dart';
import '../../models/campanha.dart';
import '../../models/atividade.dart';
import '../../services/api_service.dart';
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
import '../../utils/categorias.dart';
import '../../config/config_controller.dart';
import '../../widgets/notificacao_bell.dart';
import '../../widgets/feedback/empty_state.dart';

const Color _verde = AppColors.primary;

/// Painel administrativo da ONG (desktop).
/// Resolve qual ONG o usuario gerencia (pelo email, com seletor de fallback)
/// e mostra o painel com necessidades publicadas e interesses recebidos.
class PainelOngScreen extends StatefulWidget {
  final String emailUsuario;
  final int? ongId;
  final String? ongNome;

  const PainelOngScreen({
    super.key,
    required this.emailUsuario,
    this.ongId,
    this.ongNome,
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
    return _PainelConteudo(ong: _ong!, onLogout: _logout);
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

  const _PainelConteudo({required this.ong, required this.onLogout});

  @override
  State<_PainelConteudo> createState() => _PainelConteudoState();
}

class _PainelConteudoState extends State<_PainelConteudo> {
  final NecessidadeService _necessidadeService = NecessidadeService();
  final InteresseService _interesseService = InteresseService();
  final CampanhaService _campanhaService = CampanhaService();
  final AtividadeService _atividadeService = AtividadeService();

  List<Necessidade> _necessidades = [];
  List<Interesse> _interesses = [];
  List<Campanha> _campanhas = [];
  List<Atividade> _atividades = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
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
      _snack('Erro ao carregar dados do painel', Colors.red);
    }
  }

  void _snack(String msg, Color cor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Bloco 30: gera e abre o relatorio em PDF da ONG.
  Future<void> _gerarRelatorioPdf() async {
    _snack('Gerando relatório PDF...', _verde);
    try {
      final p = await PerfilPublicoService().buscar(widget.ong.id);
      final bytes = await RelatorioPdfService.relatorioOng(p);
      if (!mounted) return;
      await Printing.layoutPdf(onLayout: (format) async => bytes);
    } catch (e) {
      if (!mounted) return;
      _snack('Erro ao gerar relatório PDF', Colors.red);
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
      _snack('Interesse aceito! Match criado. 💚', _verde);
      _carregarTudo();
    } catch (e) {
      _snack('Erro ao aceitar', Colors.red);
    } finally {
      _acaoEmCurso = false;
    }
  }

  Future<void> _recusar(Interesse i) async {
    if (_acaoEmCurso) return;
    _acaoEmCurso = true;
    try {
      await _interesseService.recusar(i.id);
      _snack('Interesse recusado.', Colors.orange.shade700);
      _carregarTudo();
    } catch (e) {
      _snack('Erro ao recusar', Colors.red);
    } finally {
      _acaoEmCurso = false;
    }
  }

  Future<void> _abrirFormPublicar() async {
    final publicou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormNecessidade(ongId: widget.ong.id),
    );
    if (publicou == true) {
      _snack('Necessidade publicada! 🎉', _verde);
      _carregarTudo();
    }
  }

  Future<void> _abrirFormCampanha() async {
    final criou = await showDialog<bool>(
      context: context,
      builder: (_) => _FormCampanha(ongId: widget.ong.id),
    );
    if (criou == true) {
      _snack('Campanha criada! 🎉', _verde);
      _carregarTudo();
    }
  }

  Future<void> _encerrarCampanha(Campanha c) async {
    if (_acaoEmCurso) return;
    _acaoEmCurso = true;
    try {
      await _campanhaService.encerrar(c.id);
      _snack('Campanha encerrada.', Colors.orange.shade700);
      _carregarTudo();
    } catch (e) {
      _snack('Erro ao encerrar campanha', Colors.red);
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

    if (ok == true) {
      _snack('Prestação de contas publicada! 🧾', _verde);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Painel — ${widget.ong.nome}'),
          actions: [
            const NotificacaoBell(),
            IconButton(
              tooltip: 'Relatorio PDF',
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
              tooltip: 'Ranking de Transparencia',
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
              tooltip: 'Ver meu perfil publico',
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
              Tab(text: 'Atividades (${_atividades.length})'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _abrirFormPublicar,
          backgroundColor: _verde,
          icon: const Icon(Icons.add),
          label: const Text('Publicar necessidade'),
        ),
        body: _carregando
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _statsHeader(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _abaNecessidades(),
                        _abaInteresses(),
                        _abaCampanhas(),
                        _abaTimeline(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ---- Resumo em numeros (dashboard da ONG) ----
  Widget _statsHeader() {
    final matches =
        _interesses.where((i) => i.status == 'ACEITO').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          _statMini(Icons.campaign, '${_necessidades.length}',
              'Necessidades', _verde),
          const SizedBox(width: 14),
          _statMini(Icons.people, '${_interesses.length}', 'Interesses',
              Colors.blue.shade400),
          const SizedBox(width: 14),
          _statMini(Icons.handshake, '$matches', 'Matches fechados',
              Colors.pink.shade400),
        ],
      ),
    );
  }

  Widget _statMini(IconData icone, String numero, String rotulo, Color cor) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(numero,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                Text(rotulo,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
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
      padding: const EdgeInsets.all(20),
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
                    backgroundColor: Colors.red.shade50,
                    labelStyle: TextStyle(color: Colors.red.shade700),
                  )
                : Text(n.status,
                    style: const TextStyle(color: AppColors.textSecondary)),
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
      padding: const EdgeInsets.all(20),
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
                          style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                if (pendente) ...[
                  TextButton.icon(
                    onPressed: () => _recusar(it),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Recusar',
                        style: TextStyle(color: Colors.red)),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Row(
            children: [
              const Expanded(
                child: Text('Suas campanhas de arrecadação',
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
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
                  padding: const EdgeInsets.all(20),
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
                style: const TextStyle(color: AppColors.textSecondary)),
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

  // ---- ABA 4: timeline (feed global de atividades da plataforma) ----
  Widget _abaTimeline() {
    if (_atividades.isEmpty) {
      return const EmptyState(
        icone: Icons.timeline_outlined,
        mensagem: 'Nenhuma atividade recente na plataforma',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(20),
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
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
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
    final cor = aceito ? _verde : Colors.red.shade600;
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
