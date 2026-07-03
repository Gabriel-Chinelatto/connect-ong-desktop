import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/senha_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/feedback/app_snackbar.dart';

/// Fluxo "Esqueci a senha" em dois passos:
///
/// 1. Informar o e-mail -> a API envia (ou exibe, em modo demo) o codigo.
/// 2. Informar o codigo + nova senha (min. 6, com confirmacao).
///
/// Ao concluir, retorna `true` para a tela de login exibir o feedback.
class EsqueciSenhaScreen extends StatefulWidget {
  const EsqueciSenhaScreen({super.key});

  @override
  State<EsqueciSenhaScreen> createState() => _EsqueciSenhaScreenState();
}

class _EsqueciSenhaScreenState extends State<EsqueciSenhaScreen> {
  final SenhaService _service = SenhaService();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codigoController = TextEditingController();
  final _novaSenhaController = TextEditingController();
  final _confirmarController = TextEditingController();

  // Passo atual: 0 = e-mail, 1 = codigo + nova senha.
  int _passo = 0;
  bool _enviando = false; // anti-duplo-clique
  bool _mostrarSenha = false;

  // Feedback do passo 1 (mensagem da API + codigo do modo demo, se houver).
  String? _mensagemEnvio;
  String? _codigoDemo;

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    _novaSenhaController.dispose();
    _confirmarController.dispose();
    super.dispose();
  }

  Future<void> _enviarEmail() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      final r = await _service.solicitarCodigo(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _passo = 1;
        _mensagemEnvio = r.mensagem;
        _codigoDemo = r.codigoDemo;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  Future<void> _redefinir() async {
    if (_enviando) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enviando = true);
    try {
      await _service.redefinirSenha(
        email: _emailController.text.trim(),
        codigo: _codigoController.text.trim(),
        novaSenha: _novaSenhaController.text,
      );
      if (!mounted) return;
      Navigator.pop(context, true); // login mostra o snackbar de sucesso
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      AppSnackbar.erro(context, ApiService.mensagemAmigavel(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: AppRadius.brMd,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: _passo == 0 ? _passoEmail(cs) : _passoCodigo(cs),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Passo 1: e-mail ----
  Widget _passoEmail(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_reset, size: 44, color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        Text('Esqueceu a senha?',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Informe o e-mail da sua conta. Enviaremos um código para '
          'redefinir a senha.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          onFieldSubmitted: (_) => _enviarEmail(),
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          validator: (v) {
            final email = (v ?? '').trim();
            if (email.isEmpty) return 'Informe o e-mail';
            if (!email.contains('@') || !email.contains('.')) {
              return 'Informe um e-mail válido';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _enviando ? null : _enviarEmail,
            child: _enviando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enviar código'),
          ),
        ),
      ],
    );
  }

  // ---- Passo 2: codigo + nova senha ----
  Widget _passoCodigo(ColorScheme cs) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 44, color: AppColors.primary),
        const SizedBox(height: AppSpacing.md),
        Text('Verifique seu e-mail',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _mensagemEnvio ??
              'Enviamos um código para ${_emailController.text.trim()}.',
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
        // Card destacado com o codigo quando o servidor esta em modo demo
        // (sem envio de e-mail real — util na apresentacao da feira).
        if (_codigoDemo != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: AppRadius.brSm,
              border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                const Icon(Icons.science_outlined,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Modo demonstração: seu código é ',
                      style: TextStyle(fontSize: 13, color: cs.onSurface),
                      children: [
                        TextSpan(
                          text: _codigoDemo,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          controller: _codigoController,
          autofocus: true,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Código recebido',
            prefixIcon: Icon(Icons.pin_outlined),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Informe o código' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _novaSenhaController,
          obscureText: !_mostrarSenha,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Nova senha',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                  _mostrarSenha ? Icons.visibility_off : Icons.visibility),
              tooltip: _mostrarSenha ? 'Ocultar senha' : 'Mostrar senha',
              onPressed: () =>
                  setState(() => _mostrarSenha = !_mostrarSenha),
            ),
          ),
          validator: (v) =>
              (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _confirmarController,
          obscureText: !_mostrarSenha,
          onFieldSubmitted: (_) => _redefinir(),
          decoration: const InputDecoration(
            labelText: 'Confirmar nova senha',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          validator: (v) =>
              v != _novaSenhaController.text ? 'As senhas não coincidem' : null,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _enviando ? null : _redefinir,
            child: _enviando
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Redefinir senha'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Center(
          child: TextButton(
            onPressed: _enviando
                ? null
                : () => setState(() {
                      _passo = 0;
                      _codigoController.clear();
                    }),
            child: const Text('Usar outro e-mail'),
          ),
        ),
      ],
    );
  }
}
