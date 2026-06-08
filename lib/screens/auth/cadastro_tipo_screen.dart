import 'package:connect_ong/screens/auth/cadastro_ong_screen.dart';
import 'package:flutter/material.dart';
import '../empresa/cadastro_empresa_screen.dart';

class CadastroTipoScreen extends StatelessWidget {
  const CadastroTipoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Nova Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Como você deseja se cadastrar?',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Cartão para Empresa Doadora
                  _buildCard(
                    context: context,
                    title: 'Sou uma Empresa',
                    description:
                        'Quero cadastrar minha empresa para realizar doações de itens ou serviços.',
                    icon: Icons.business,
                    onTap: () {
                      // Ir para tela de cadastro de empresa (Faremos depois)
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const CadastroEmpresaScreen()),
                      );
                    },
                  ),
                  const SizedBox(width: 32),
                  // Cartão para ONG
                  _buildCard(
                    context: context,
                    title: 'Sou uma ONG',
                    description:
                        'Quero cadastrar minha instituição para receber doações de empresas.',
                    icon: Icons.volunteer_activism,
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const CadastroOngScreen()));
                      // Ir para tela de cadastro de ONG (Faremos depois)
                      debugPrint("Clicou em ONG");
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Função para criar o design do cartão
  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 80, color: const Color(0xFF2E7D32)),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
