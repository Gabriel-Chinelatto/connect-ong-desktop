import 'package:flutter/material.dart';
import '../../services/doacao_service.dart';

class HomeEmpresaScreen extends StatefulWidget {
  const HomeEmpresaScreen({super.key});

  @override
  State<HomeEmpresaScreen> createState() => _HomeEmpresaScreenState();
}

class _HomeEmpresaScreenState extends State<HomeEmpresaScreen> {
  int _selectedIndex = 0;

  // Controllers para formulários
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _quantidadeController = TextEditingController();

  // Controllers para Perfil (Interativo)
  bool _isEditing = false;
  final _empresaNameController = TextEditingController(text: "Minha Empresa S.A.");
  final _emailController = TextEditingController(text: "contato@minhaempresa.com.br");
  final _enderecoController = TextEditingController(text: "Rua das ONGs, 123 - São Paulo/SP");

  @override
  Widget build(BuildContext context) {
    // Lista de telas organizada
    final List<Widget> screens = [
      // Índice 0: Dashboard (Início)
      Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Bem-vindo de volta!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            
            Row(
              children: [
                _buildMetricCard("Total Doado", "${DoacaoService.todasAsDoacoes.length}", Icons.favorite, Colors.blue),
                const SizedBox(width: 20),
                _buildMetricCard("Em Aberto", "2", Icons.pending_actions, Colors.orange),
                const SizedBox(width: 20),
                _buildMetricCard("Impacto", "500kg", Icons.eco, Colors.green),
              ],
            ),
            
            const SizedBox(height: 40),
            const Text("Últimas Doações", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            Expanded(
              child: ListView.builder(
                itemCount: DoacaoService.todasAsDoacoes.length > 3 ? 3 : DoacaoService.todasAsDoacoes.length,
                itemBuilder: (context, index) {
                  final d = DoacaoService.todasAsDoacoes[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.history, color: Colors.green),
                      title: Text(d['item']),
                      subtitle: Text("Empresa: ${d['empresa']}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Índice 1: Doar
      _buildFormularioDoacao(),

      // Índice 2: Histórico
      Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("Histórico", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: DoacaoService.todasAsDoacoes.length,
                itemBuilder: (context, index) {
                  final d = DoacaoService.todasAsDoacoes[index];
                  return Card(
                    child: ListTile(
                      title: Text(d['item']),
                      subtitle: Text("Qtd: ${d['quantidade']} | Empresa: ${d['empresa']}"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Índice 3: Perfil (Interativo)
      Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Meu Perfil", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 30),
            
            // Edição de Nome
            _isEditing 
              ? TextFormField(controller: _empresaNameController, decoration: const InputDecoration(labelText: "Nome da Empresa", border: OutlineInputBorder()))
              : ListTile(leading: const Icon(Icons.business, size: 40), title: Text(_empresaNameController.text, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
            
            const SizedBox(height: 20),
            
            Card(
              elevation: 2,
              child: Column(
                children: [
                  _isEditing
                    ? TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: "E-mail", border: OutlineInputBorder()))
                    : ListTile(leading: const Icon(Icons.email), title: const Text("E-mail"), subtitle: Text(_emailController.text)),
                  const Divider(),
                  _isEditing
                    ? TextFormField(controller: _enderecoController, decoration: const InputDecoration(labelText: "Endereço", border: OutlineInputBorder()))
                    : ListTile(leading: const Icon(Icons.location_on), title: const Text("Endereço"), subtitle: Text(_enderecoController.text)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    if (_isEditing) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Perfil atualizado!")));
                    _isEditing = !_isEditing;
                  }),
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  label: Text(_isEditing ? "SALVAR ALTERAÇÕES" : "EDITAR PERFIL"),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 20),
                  TextButton(onPressed: () => setState(() => _isEditing = false), child: const Text("CANCELAR")),
                ],
                const SizedBox(width: 20),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  label: const Text("SAIR", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    ];

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            extended: true,
            onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
            leading: const Padding(
              padding: EdgeInsets.all(20.0),
              child: CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.business, color: Colors.white)),
            ),
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Início')),
              NavigationRailDestination(icon: Icon(Icons.add_circle), label: Text('Doar')),
              NavigationRailDestination(icon: Icon(Icons.history), label: Text('Histórico')),
              NavigationRailDestination(icon: Icon(Icons.person_outline), label: Text('Perfil')),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: Container(color: Colors.grey[50], child: screens[_selectedIndex])),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioDoacao() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Nova Doação", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
              const SizedBox(height: 40),
              TextFormField(controller: _tituloController, decoration: const InputDecoration(labelText: "Título", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Campo obrigatório" : null),
              const SizedBox(height: 20),
              TextFormField(controller: _descricaoController, maxLines: 3, decoration: const InputDecoration(labelText: "Descrição", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Campo obrigatório" : null),
              const SizedBox(height: 20),
              TextFormField(controller: _quantidadeController, decoration: const InputDecoration(labelText: "Quantidade", border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? "Campo obrigatório" : null),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    DoacaoService.adicionar({
                      "item": _tituloController.text,
                      "quantidade": _quantidadeController.text,
                      "empresa": "Minha Empresa",
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Doação publicada!")));
                    _tituloController.clear();
                    _descricaoController.clear();
                    _quantidadeController.clear();
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.check_circle),
                label: const Text("PUBLICAR DOAÇÃO"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}