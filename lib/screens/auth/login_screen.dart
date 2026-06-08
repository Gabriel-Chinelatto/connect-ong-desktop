import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../empresa/home_empresa_screen.dart';
import 'cadastro_tipo_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _loading = false;

  Future<void> fazerLogin() async {

    setState(() {
      _loading = true;
    });

    final authService = AuthService();

    final sucesso = await authService.login(
      _emailController.text,
      _senhaController.text,
    );

    setState(() {
      _loading = false;
    });

    if (sucesso) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeEmpresaScreen(),
        ),
      );

    } else {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login inválido'),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: Center(

        child: Container(

          width: 400,

          padding: const EdgeInsets.all(32),

          decoration: BoxDecoration(
            color: Colors.white,
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

              const Icon(
                Icons.handshake,
                size: 64,
                color: Color(0xFF2E7D32),
              ),

              const SizedBox(height: 16),

              const Text(
                'Connect ONG',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),

              const SizedBox(height: 32),

              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _senhaController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,

                child: ElevatedButton(

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                  ),

                  onPressed: _loading ? null : fazerLogin,

                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(

                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CadastroTipoScreen(),
                    ),
                  );

                },

                child: const Text(
                  'Ainda não tem conta? Cadastre-se',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}