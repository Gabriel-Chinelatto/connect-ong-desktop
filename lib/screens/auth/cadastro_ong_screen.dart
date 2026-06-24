import 'package:flutter/material.dart';

import '../../services/ong_service.dart';
import '../../theme/app_colors.dart';

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
    setState(() => _enviando = true);
    try {
      await _ongService.registrar(
        nome: _nome.text.trim(),
        email: _email.text.trim(),
        telefone: _telefone.text.trim(),
        cidade: _cidade.text.trim(),
        descricao: _descricao.text.trim(),
        cnpj: _cnpj.text.trim(),
        senha: _senha.text,
      );
      if (!mounted) return;
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
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  const Text(
                    'Crie o perfil e o acesso da sua organização.',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  _campo(_nome, 'Nome da ONG', obrigatorio: true),
                  _campo(_email, 'E-mail', obrigatorio: true),
                  _campo(_telefone, 'Telefone'),
                  _campo(_cidade, 'Cidade'),
                  _campo(_cnpj, 'CNPJ (opcional, para verificação)'),
                  _campo(_descricao, 'Descrição', linhas: 3),
                  _campo(_senha, 'Senha', obrigatorio: true, senha: true),
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
    );
  }

  Widget _campo(
    TextEditingController c,
    String label, {
    bool obrigatorio = false,
    bool senha = false,
    int linhas = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: c,
        obscureText: senha,
        maxLines: senha ? 1 : linhas,
        decoration: InputDecoration(labelText: label),
        validator: obrigatorio
            ? (v) => (v == null || v.trim().isEmpty)
                ? 'Campo obrigatório'
                : null
            : null,
      ),
    );
  }
}
