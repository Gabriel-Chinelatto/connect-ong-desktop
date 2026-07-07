import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../config/config_controller.dart';
import '../../widgets/feedback/app_snackbar.dart';
import '../ong/painel_ong_screen.dart';
import 'cadastro_ong_screen.dart';
import 'esqueci_senha_screen.dart';

/// Tela inicial: login do responsavel pela ONG.
///
/// Autentica via [AuthService] (que guarda o JWT), carrega as preferencias do
/// usuario e abre o painel da ONG. Da acesso tambem ao cadastro de nova ONG.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Credenciais de demonstracao (conta ONG de exemplo) exibidas no "Modo Feira".
  static const String _demoEmail = 'demo.larviva@connectong.com';
  static const String _demoSenha = 'demo123';

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _loading = false;
  bool _mostrarSenha = false;

  /// Preenche os campos com as credenciais de demonstracao (Modo Feira).
  void _preencherDemo() {
    _emailController.text = _demoEmail;
    _senhaController.text = _demoSenha;
  }

  /// Cartao discreto com as credenciais de demonstracao (Modo Feira).
  Widget _cardModoFeira(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.celebration_outlined,
                  size: 18, color: AppColors.primary),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Modo Feira — acesso de demonstração',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _linhaCredencial(cs, 'E-mail', _demoEmail),
          const SizedBox(height: 4),
          _linhaCredencial(cs, 'Senha', _demoSenha),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _preencherDemo,
              icon: const Icon(Icons.edit_note, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
              ),
              label: const Text('Preencher'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _linhaCredencial(ColorScheme cs, String rotulo, String valor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(
            rotulo,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            valor,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  /// Abre o fluxo "Esqueci a senha"; se a senha foi redefinida, confirma aqui.
  Future<void> _abrirEsqueciSenha() async {
    final redefiniu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const EsqueciSenhaScreen()),
    );
    if (redefiniu == true && mounted) {
      AppSnackbar.sucesso(
          context, 'Senha redefinida! Faça login com a nova senha.');
    }
  }

  Future<void> fazerLogin() async {
    if (_loading) return;

    setState(() {
      _loading = true;
    });

    final authService = AuthService();

    Map<String, dynamic>? usuario;
    String? erroConexao;
    try {
      usuario = await authService.login(
        _emailController.text,
        _senhaController.text,
      );
    } catch (e) {
      // Falha de rede (servidor fora do ar, timeout, sem conexao).
      erroConexao = ApiService.mensagemAmigavel(e);
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });

    if (erroConexao != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erroConexao)),
      );
      return;
    }

    if (usuario != null) {
      // 2FA ligado: o login veio SEM token, pedindo a segunda etapa (código).
      if (usuario['requer2fa'] == true) {
        final email =
            (usuario['email'] ?? _emailController.text).toString();
        final codigoDemo = usuario['codigoDemo']?.toString();
        final concluido = await _abrir2fa(email, codigoDemo);
        if (!mounted) return;
        if (concluido != null) await _concluirLogin(concluido);
        return;
      }
      await _concluirLogin(usuario);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('E-mail ou senha inválidos')),
      );
    }
  }

  /// Conclui o login (comum ao fluxo normal e ao 2FA): valida que é uma conta
  /// de ONG, carrega preferências, guarda o e-mail da sessão e abre o painel.
  Future<void> _concluirLogin(Map<String, dynamic> usuario) async {
    // Este painel e EXCLUSIVO de ONGs. Uma conta de doador (cadastrada no app
    // mobile) tem credenciais validas, mas nao pode gerenciar uma ONG. Sem esta
    // barreira, um doador entraria no painel administrativo (e, no fallback do
    // seletor, veria/gerenciaria qualquer ONG). Bloqueamos aqui no cliente.
    if (usuario['tipo'] != 'ONG') {
      await ApiService.setToken(null); // descarta o JWT do doador
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Este acesso e exclusivo para ONGs. Use o app do doador para contas de doador.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Guarda o e-mail da sessao (usado, ex., no "Alterar e-mail").
    ConfigController.instance
        .setUsuarioEmail((usuario['email'] ?? _emailController.text).toString());

    // Carrega as preferencias (tema, fonte, etc.) do usuario.
    final id = usuario['id'];
    if (id is int) {
      await ConfigController.instance.carregar(id);
      if (!mounted) return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PainelOngScreen(
          emailUsuario: _emailController.text,
          ongId: usuario['ongId'],
          ongNome: usuario['nome'],
        ),
      ),
    );
  }

  /// Etapa do código 2FA: dialog com campo de 6 dígitos (e card de demo quando
  /// o servidor devolve [codigoDemo]). Valida via POST /auth/login-2fa e
  /// retorna os dados do usuário autenticado (com token) ou null se cancelado.
  Future<Map<String, dynamic>?> _abrir2fa(
      String email, String? codigoDemo) {
    final codigoController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool enviando = false;

    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setLocal) => AlertDialog(
          title: const Text('Verificação em duas etapas'),
          content: SizedBox(
            width: 360,
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enviamos um código de 6 dígitos para\n$email.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (codigoDemo != null && codigoDemo.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Modo demonstração',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            codigoDemo,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: codigoController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Código (6 dígitos)',
                      counterText: '',
                    ),
                    validator: (v) => (v == null || v.trim().length != 6)
                        ? 'Informe os 6 dígitos'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  enviando ? null : () => Navigator.pop(dialogContext, null),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setLocal(() => enviando = true);
                      try {
                        final dados = await AuthService().loginDoisFatores(
                          email,
                          codigoController.text.trim(),
                        );
                        if (!dialogContext.mounted) return;
                        if (dados != null) {
                          Navigator.pop(dialogContext, dados);
                        } else {
                          setLocal(() => enviando = false);
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                              content: Text('Código inválido ou expirado.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      } catch (e) {
                        setLocal(() => enviando = false);
                        if (!dialogContext.mounted) return;
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(ApiService.mensagemAmigavel(e)),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    },
              child: enviando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Entrar'),
            ),
          ],
        ),
      ),
    ).whenComplete(codigoController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo.jpg',
                height: 120,
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect ONG',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _senhaController,
                obscureText: !_mostrarSenha,
                onSubmitted: (_) => fazerLogin(),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_mostrarSenha
                        ? Icons.visibility_off
                        : Icons.visibility),
                    tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
                    onPressed: () =>
                        setState(() => _mostrarSenha = !_mostrarSenha),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _abrirEsqueciSenha,
                  child: const Text('Esqueceu a senha?',
                      style: TextStyle(fontSize: 13)),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _loading ? null : fazerLogin,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              // Cartao do "Modo Feira": exibe as credenciais de demonstracao para
              // a apresentacao (FECITEC), sem precisar anota-las em papel. So
              // aparece quando a flag esta ligada (ver Configuracoes).
              if (ConfigController.instance.modoFeira) ...[
                const SizedBox(height: 20),
                _cardModoFeira(cs),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CadastroOngScreen(),
                    ),
                  );
                },
                child: const Text('Ainda não tem conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
