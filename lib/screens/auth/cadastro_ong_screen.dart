import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../services/ong_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/estado_cidade.dart';
import '../../widgets/confirmar_saida.dart';
import '../../widgets/seletor_estado_cidade.dart';
import '../legal/documentos_legais_screen.dart';

/// Cadastro de uma nova ONG na plataforma.
///
/// Coleta os dados da ONG e a senha de acesso, exige o aceite dos termos
/// (LGPD) e cria, de uma vez, o perfil da ONG mais a conta de login.
class CadastroOngScreen extends StatefulWidget {
  const CadastroOngScreen({super.key});

  @override
  State<CadastroOngScreen> createState() => _CadastroOngScreenState();
}

class _CadastroOngScreenState extends State<CadastroOngScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _telefone = TextEditingController();
  final _cidade = TextEditingController();
  final _descricao = TextEditingController();
  final _cnpj = TextEditingController();
  final _senha = TextEditingController();

  final OngService _ongService = OngService();
  bool _enviando = false;
  bool _aceitouTermos = false;

  /// Cadastro concluído: sair depois do sucesso não deve perguntar.
  bool _cadastrou = false;

  /// UF escolhida no dropdown (o backend guarda "Cidade - UF" num campo só).
  String? _uf;

  /// Todos os campos de texto (para detectar preenchimento e reagir a ele).
  late final List<TextEditingController> _controllers = [
    _nome, _email, _telefone, _cidade, _descricao, _cnpj, _senha,
  ];

  /// Há algo preenchido e o cadastro ainda não foi concluído?
  bool get _temMudanca =>
      !_cadastrou &&
      (_controllers.any((c) => c.text.isNotEmpty) ||
          _uf != null ||
          _aceitouTermos);

  @override
  void initState() {
    super.initState();
    // Digitar não rebuilda a tela sozinho; o guarda de saída (canPop) precisa
    // ser reavaliado a cada tecla para não liberar a saída sem aviso.
    for (final c in _controllers) {
      c.addListener(_reavaliarGuarda);
    }
  }

  void _reavaliarGuarda() => setState(() {});

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _cidade.dispose();
    _descricao.dispose();
    _cnpj.dispose();
    _senha.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_aceitouTermos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Para continuar, aceite os Termos de Uso e a Politica de Privacidade.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    setState(() => _enviando = true);
    try {
      await _ongService.registrar(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        telefone: _telefone.text.trim(),
        cidade: formatarCidadeUf(_cidade.text, _uf),
        descricao: _descricao.text.trim(),
        cnpj: _cnpj.text.trim(),
        senha: _senha.text,
      );
      if (!mounted) return;
      _cadastrou = true; // sucesso: sair sem perguntar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ONG cadastrada! Agora é só fazer login. 💚'),
          backgroundColor: AppColors.primary,
        ),
      );
      Navigator.pop(context); // volta para o login
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
    // Guarda de saída: avisa se algo já foi preenchido e o cadastro não foi
    // concluído. Sem aoSalvar — não faz sentido "salvar" cadastro pela metade.
    return GuardaDeSaida(
      temMudanca: _temMudanca,
      child: Scaffold(
      appBar: AppBar(title: const Text('Cadastro de ONG')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Cadastre sua ONG',
                    style:
                        TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crie o perfil e o acesso da sua organização.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  _campo(_nome, 'Nome da ONG',
                      obrigatorio: true,
                      maxLength: 120,
                      validador: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Campo obrigatório';
                        if (t.length < 2) return 'Nome muito curto';
                        return null;
                      }),
                  _campo(_email, 'E-mail',
                      obrigatorio: true,
                      maxLength: 150,
                      teclado: TextInputType.emailAddress,
                      validador: _validarEmail),
                  _campo(_telefone, 'Telefone',
                      maxLength: 20,
                      teclado: TextInputType.phone),
                  // Estado antes da cidade: a UF filtra o autocomplete
                  // (mesmo padrão do app mobile).
                  SeletorEstadoCidade(
                    uf: _uf,
                    cidadeController: _cidade,
                    onUfChanged: (v) => setState(() => _uf = v),
                    habilitado: !_enviando,
                  ),
                  _campo(_cnpj, 'CNPJ (opcional, para verificação)',
                      maxLength: 20),
                  _campo(_descricao, 'Descrição', linhas: 3, maxLength: 1000),
                  _campo(_senha, 'Senha',
                      obrigatorio: true,
                      senha: true,
                      validador: _validarSenha),
                  const SizedBox(height: 8),
                  _consentimento(),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _cadastrar,
                      child: _enviando
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Cadastrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  Widget _consentimento() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _aceitouTermos,
          activeColor: AppColors.primary,
          onChanged: (v) => setState(() => _aceitouTermos = v ?? false),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface),
                children: [
                  const TextSpan(text: 'Li e concordo com os '),
                  TextSpan(
                    text: 'Termos de Uso',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => _abrirDocumento(DocumentoLegal.termos),
                  ),
                  const TextSpan(text: ' e a '),
                  TextSpan(
                    text: 'Politica de Privacidade',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap =
                          () => _abrirDocumento(DocumentoLegal.privacidade),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Validacao de e-mail por regex simples (nome@dominio.tld).
  String? _validarEmail(String? v) {
    final texto = (v ?? '').trim();
    if (texto.isEmpty) return 'Campo obrigatório';
    final regex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');
    if (!regex.hasMatch(texto)) return 'Informe um e-mail válido';
    return null;
  }

  // Senha minima de 6 caracteres.
  String? _validarSenha(String? v) {
    final texto = v ?? '';
    if (texto.isEmpty) return 'Campo obrigatório';
    if (texto.length < 6) return 'Mínimo de 6 caracteres';
    return null;
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    bool obrigatorio = false,
    bool senha = false,
    int linhas = 1,
    TextInputType? teclado,
    String? Function(String?)? validador,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        obscureText: senha,
        maxLines: senha ? 1 : linhas,
        keyboardType: teclado,
        // Espelha o limite do backend (OngRegistroDTO), para o erro aparecer
        // enquanto se digita e nao so ao enviar o cadastro.
        maxLength: maxLength,
        buildCounter: (context,
                {required currentLength, required isFocused, maxLength}) =>
            (maxLength != null && currentLength > maxLength * 0.8)
                ? Text('$currentLength/$maxLength',
                    style: Theme.of(context).textTheme.bodySmall)
                : null,
        decoration: InputDecoration(labelText: label),
        validator: validador ??
            (obrigatorio
                ? (v) => (v == null || v.trim().isEmpty)
                    ? 'Campo obrigatório'
                    : null
                : null),
      ),
    );
  }
}
