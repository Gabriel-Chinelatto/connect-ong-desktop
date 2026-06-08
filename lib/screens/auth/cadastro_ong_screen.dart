import 'package:flutter/material.dart';

class CadastroOngScreen extends StatelessWidget {
  const CadastroOngScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastro de ONG'),
      ),
      body: const Center(
        child: Text(
          'Tela de cadastro de ONG em desenvolvimento',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}