import 'package:flutter/material.dart';

import '../../models/ong.dart';
import '../../models/necessidade.dart';
import '../../models/interesse.dart';
import '../../services/ong_service.dart';
import '../../services/necessidade_service.dart';
import '../../services/interesse_service.dart';
import '../../services/prestacao_service.dart';
import '../auth/login_screen.dart';
import 'chat_ong_screen.dart';
import 'configuracoes_screen.dart';
import 'perfil_screen.dart';
import '../../theme/app_colors.dart';
import '../../config/config_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _resolverOng();
  }

  Future<void> _resolverOng() async {
    setState(() => _carregando = true);

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
      setState(() => _carregando = false);
    }
  }

  void _logout() {
    ConfigController.instance.limpar();
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
    if (_ong == null) {
      return _buildSeletor();
    }
    return _PainelConteudo(ong: _ong!, onLogout: _logout);
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

  List<Necessidade> _necessidades = [];
  List<Interesse> _interesses = [];
  bool _carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarTudo();
  }

  Future<void> _carregarTudo() async {
    setState(() => _carregando = true);
    try {
      final nec = await _necessidadeService.listarPorOng(widget.ong.id);
      final ints = await _interesseService.listarPorOng(widget.ong.id);
      if (!mounted) return;
      setState(() {
        _necessidades = nec;
        _interesses = ints;
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

  Future<void> _aceitar(Interesse i) async {
    try {
      await _interesseService.aceitar(i.id);
      _snack('Interesse aceito! Match criado. 💚', _verde);
      _carregarTudo();
    } catch (e) {
      _snack('Erro ao aceitar', Colors.red);
    }
  }

  Future<void> _recusar(Interesse i) async {
    try {
      await _interesseService.recusar(i.id);
      _snack('Interesse recusado.', Colors.orange.shade700);
      _carregarTudo();
    } catch (e) {
      _snack('Erro ao recusar', Colors.red);
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

  Future<void> _abrirPrestarContas(Interesse it) async {
    final tituloC = TextEditingController();
    final descC = TextEditingController();
    final fotoC = TextEditingController();

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
              if (tituloC.text.trim().isEmpty) return;
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
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content:
                        Text(e.toString().replaceFirst('Exception: ', '')),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Publicar'),
          ),
        ],
      ),
    );

    if (ok == true) {
      _snack('Prestação de contas publicada! 🧾', _verde);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Painel — ${widget.ong.nome}'),
          actions: [
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
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
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
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
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
      return const Center(
        child: Text(
          'Nenhuma necessidade publicada ainda.\nClique em "Publicar necessidade".',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
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
                    style: TextStyle(color: Colors.grey.shade600)),
          ),
        );
      },
    );
  }

  // ---- ABA 2: interesses recebidos ----
  Widget _abaInteresses() {
    if (_interesses.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum interesse recebido ainda.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
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
                          style: TextStyle(color: Colors.grey.shade700)),
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
  final _categoriaController = TextEditingController();
  bool _urgente = false;
  bool _enviando = false;

  final NecessidadeService _service = NecessidadeService();

  @override
  void dispose() {
    _tituloController.dispose();
    _descricaoController.dispose();
    _categoriaController.dispose();
    super.dispose();
  }

  Future<void> _publicar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await _service.criar(
        titulo: _tituloController.text.trim(),
        descricao: _descricaoController.text.trim(),
        categoria: _categoriaController.text.trim(),
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
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
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
                  decoration: const InputDecoration(labelText: 'Título'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe o título' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descricaoController,
                  decoration: const InputDecoration(labelText: 'Descrição'),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoriaController,
                  decoration: const InputDecoration(
                      labelText: 'Categoria (ex.: Alimento, Roupa)'),
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
