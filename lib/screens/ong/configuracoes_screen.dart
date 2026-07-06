import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import '../../config/config_controller.dart';
import '../../models/preferencia.dart';
import '../../services/api_service.dart';
import '../../services/demo_service.dart';
import '../../services/perfil_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/feedback/app_snackbar.dart';
import '../auth/login_screen.dart';
import '../legal/documentos_legais_screen.dart';
import 'doadores_bloqueados_screen.dart';

/// Central de configurações da ONG.
///
/// As alterações de aparência/notificações/privacidade ficam LOCAIS até o
/// usuário tocar em "Salvar configurações" (barra fixa embaixo, visível só
/// quando há mudança pendente), que aplica tudo de uma vez: PUT das
/// preferências + tema. Sair com mudanças pendentes pede confirmação.
/// Ações pontuais (Modo Feira, senha, excluir conta) continuam imediatas.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  /// Cópia local editável; só vira "oficial" no Salvar.
  late Preferencia _p;

  /// Snapshot do último estado salvo (base da detecção de mudança pendente).
  late Preferencia _original;

  bool _salvando = false;
  bool _carregandoDemo = false;
  bool _excluindoConta = false;

  @override
  void initState() {
    super.initState();
    _p = ConfigController.instance.prefs.copy();
    _original = _p.copy();
  }

  bool get _temMudanca => !mapEquals(_p.toJson(), _original.toJson());

  /// Toggles apenas alteram a cópia local (nada é aplicado/persistido aqui).
  void _mudar(VoidCallback aplicar) => setState(aplicar);

  /// Aplica tudo de uma vez: tema/fonte no app + PUT das preferências.
  Future<void> _salvar() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await ConfigController.instance.salvar(_p.copy());
      if (!mounted) return;
      setState(() {
        _original = _p.copy();
        _salvando = false;
      });
      AppSnackbar.sucesso(context, 'Configurações salvas! 💚');
    } catch (e) {
      if (!mounted) return;
      // Mantém as mudanças pendentes para o usuário tentar salvar de novo.
      setState(() => _salvando = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  /// Volta a cópia local para o último estado salvo.
  void _descartar() {
    setState(() => _p = _original.copy());
    AppSnackbar.info(context, 'Alterações descartadas.');
  }

  /// Ao tentar sair com mudanças pendentes: "Descartar alterações?".
  Future<void> _confirmarSaida() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
            'Você tem mudanças que ainda não foram salvas. Se sair agora, '
            'elas serão perdidas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (descartar == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_temMudanca,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmarSaida();
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Configurações')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.md),
              children: [
                _cartaoSecao('Aparência e acessibilidade',
                    Icons.palette_outlined, [
                  _escolha('Tema', const ['CLARO', 'ESCURO', 'AUTOMATICO'],
                      const ['Claro', 'Escuro', 'Automático'], _p.tema,
                      (v) => _mudar(() => _p.tema = v)),
                  _escolha(
                      'Tamanho da fonte',
                      const ['PEQUENA', 'MEDIA', 'GRANDE'],
                      const ['Pequena', 'Média', 'Grande'],
                      _p.tamanhoFonte,
                      (v) => _mudar(() => _p.tamanhoFonte = v)),
                  _switch('Alto contraste', 'Mais contraste para leitura',
                      _p.altoContraste,
                      (v) => _mudar(() => _p.altoContraste = v)),
                  _switch('Fonte para dislexia', 'Usa uma fonte mais legível',
                      _p.fonteDislexia,
                      (v) => _mudar(() => _p.fonteDislexia = v)),
                  _switch(
                      'Navegação simplificada',
                      'Modo mais simples de usar',
                      _p.navegacaoSimplificada,
                      (v) => _mudar(() => _p.navegacaoSimplificada = v)),
                ]),
                _cartaoSecao('Notificações', Icons.notifications_outlined, [
                  _switch('Novas mensagens', null, _p.notifMensagens,
                      (v) => _mudar(() => _p.notifMensagens = v)),
                  _switch('Match de doações', null, _p.notifMatch,
                      (v) => _mudar(() => _p.notifMatch = v)),
                  _switch('Atualizações de campanhas', null, _p.notifCampanhas,
                      (v) => _mudar(() => _p.notifCampanhas = v)),
                  _switch('Novas necessidades', null, _p.notifNecessidades,
                      (v) => _mudar(() => _p.notifNecessidades = v)),
                  _switch('Notícias da plataforma', null, _p.notifNoticias,
                      (v) => _mudar(() => _p.notifNoticias = v)),
                ]),
                _cartaoSecao('Privacidade', Icons.lock_outline, [
                  _switch('Exibir telefone', null, _p.mostrarTelefone,
                      (v) => _mudar(() => _p.mostrarTelefone = v)),
                  _switch('Exibir e-mail', null, _p.mostrarEmail,
                      (v) => _mudar(() => _p.mostrarEmail = v)),
                  _switch('Perfil público', null, _p.perfilPublico,
                      (v) => _mudar(() => _p.perfilPublico = v)),
                  _switch('Receber sugestões', null, _p.receberSugestoes,
                      (v) => _mudar(() => _p.receberSugestoes = v)),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Doadores bloqueados'),
                    subtitle: const Text(
                        'Gerencie quem não pode ver sua ONG nem enviar mensagens'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DoadoresBloqueadosScreen(),
                      ),
                    ),
                  ),
                ]),
                _cartaoSecao('Segurança', Icons.shield_outlined, [
                  ListTile(
                    leading: const Icon(Icons.password),
                    title: const Text('Alterar senha'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _abrirAlterarSenha,
                  ),
                ]),
                _cartaoSecao('Termos e Privacidade', Icons.gavel_outlined, [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Política de Privacidade'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrirDocumento(DocumentoLegal.privacidade),
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Termos de Uso'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _abrirDocumento(DocumentoLegal.termos),
                  ),
                ]),
                _cartaoSecao('Modo Feira', Icons.celebration_outlined, [
                  SwitchListTile(
                    title: const Text('Modo Feira'),
                    subtitle: const Text(
                        'Mostra as credenciais de demonstração na tela de login'),
                    value: ConfigController.instance.modoFeira,
                    activeThumbColor: AppColors.primary,
                    onChanged: (v) {
                      // Flag local do dispositivo: aplica na hora (não faz
                      // parte das preferências salvas no backend).
                      ConfigController.instance.setModoFeira(v);
                      setState(() {});
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.auto_awesome),
                    title: const Text('Carregar dados demonstrativos'),
                    subtitle: const Text(
                        'Popula o sistema com ONGs, doadores e doações para a apresentação'),
                    trailing: _carregandoDemo
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right),
                    onTap: _carregandoDemo ? null : _carregarDadosDemo,
                  ),
                ]),
                _cartaoSecao('Zona de perigo', Icons.warning_amber_outlined, [
                  ListTile(
                    leading:
                        const Icon(Icons.delete_forever, color: AppColors.error),
                    title: const Text(
                      'Excluir minha conta',
                      style: TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                        'Desativa a conta da ONG e a remove da plataforma'),
                    trailing: _excluindoConta
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right,
                            color: AppColors.error),
                    onTap: _excluindoConta ? null : _confirmarExcluirConta,
                  ),
                ], corTitulo: AppColors.error),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
        // Barra fixa de salvar: só aparece quando há mudança pendente.
        bottomNavigationBar: !_temMudanca
            ? null
            : Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline,
                                size: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Você tem alterações não salvas',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant),
                              ),
                            ),
                            TextButton(
                              onPressed: _salvando ? null : _descartar,
                              child: const Text('Descartar'),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            FilledButton.icon(
                              onPressed: _salvando ? null : _salvar,
                              icon: _salvando
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Salvar configurações'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// Card de seção: cabeçalho com ícone + título e os itens agrupados.
  Widget _cartaoSecao(String titulo, IconData icone, List<Widget> filhos,
      {Color corTitulo = AppColors.primary}) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xs),
              child: Row(
                children: [
                  Icon(icone, size: 20, color: corTitulo),
                  const SizedBox(width: AppSpacing.sm),
                  Text(titulo,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: corTitulo)),
                ],
              ),
            ),
            ...filhos,
          ],
        ),
      ),
    );
  }

  void _abrirDocumento(DocumentoLegal tipo) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DocumentosLegaisScreen(tipo: tipo),
      ),
    );
  }

  Future<void> _carregarDadosDemo() async {
    setState(() => _carregandoDemo = true);
    try {
      final r = await DemoService().carregarDadosDemo();
      if (!mounted) return;
      final jaTinha = r['status'] == 'ja_carregado';
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(jaTinha
              ? 'Dados demonstrativos ja carregados'
              : 'Dados demonstrativos carregados!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(jaTinha
                  ? 'O sistema ja possui os dados de demonstracao.'
                  : 'ONGs, doadores, necessidades, matches e doacoes foram criados.'),
              const SizedBox(height: 12),
              const Text('Contas de exemplo (senha: demo123):',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('ONG:    ${r['contaOngExemplo']}'),
              Text('Doador: ${r['contaDoadorExemplo']}'),
              const SizedBox(height: 12),
              Text('Total de ONGs: ${r['totalOngs']}  •  '
                  'Necessidades: ${r['totalNecessidades']}'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    } finally {
      if (mounted) setState(() => _carregandoDemo = false);
    }
  }

  /// Fluxo de exclusao da propria conta: confirma, chama o backend e, em caso
  /// de sucesso, faz o MESMO logout do painel (limpa sessao/token e volta ao
  /// login). Reutiliza o fluxo existente, sem alterar login/logout.
  Future<void> _confirmarExcluirConta() async {
    if (_excluindoConta) return;

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir minha conta'),
        content: const Text(
            'Tem certeza? A conta da ONG será desativada e sumirá da '
            'plataforma; você não poderá mais acessá-la. Esta ação não pode '
            'ser desfeita pelo app.'),
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

    if (confirmado != true) return;
    if (!mounted) return;

    final usuarioId = ConfigController.instance.usuarioId;
    if (usuarioId == null) return;

    setState(() => _excluindoConta = true);
    try {
      await PerfilService().excluirConta(usuarioId);
      if (!mounted) return;
      // Mesmo fluxo de logout do painel: limpa sessao e token e volta ao login.
      ConfigController.instance.limpar();
      ApiService.setToken(null);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Conta excluída.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
      setState(() => _excluindoConta = false);
    }
  }

  Widget _switch(String titulo, String? subtitulo, bool valor,
      ValueChanged<bool> onChange) {
    return SwitchListTile(
      title: Text(titulo),
      subtitle: subtitulo == null ? null : Text(subtitulo),
      value: valor,
      activeThumbColor: AppColors.primary,
      onChanged: onChange,
    );
  }

  Widget _escolha(String titulo, List<String> valores, List<String> rotulos,
      String selecionado, ValueChanged<String> onChange) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(titulo),
          ),
          Wrap(
            spacing: 8,
            children: List.generate(valores.length, (i) {
              final sel = valores[i] == selecionado;
              return ChoiceChip(
                label: Text(rotulos[i]),
                selected: sel,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(color: sel ? Colors.white : null),
                onSelected: (_) => onChange(valores[i]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _abrirAlterarSenha() async {
    final atual = TextEditingController();
    final nova = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final usuarioId = ConfigController.instance.usuarioId;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: atual,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nova,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) =>
                    (v == null || v.length < 4) ? 'Mínimo 4 caracteres' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              if (usuarioId == null) return;
              try {
                await PerfilService()
                    .alterarSenha(usuarioId, atual.text, nova.text);
                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (!mounted) return;
                AppSnackbar.sucesso(context, 'Senha alterada com sucesso! 💚');
              } catch (e) {
                if (!dialogContext.mounted) return;
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(ApiService.mensagemAmigavel(e)),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    // Libera os controllers depois que o dialogo fecha (evita vazamento).
    atual.dispose();
    nova.dispose();
  }
}
