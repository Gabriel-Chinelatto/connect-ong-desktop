import 'package:flutter/material.dart';

import '../../models/doacao_model.dart';
import '../../services/doacao_service.dart';

class HomeEmpresaScreen extends StatefulWidget {
  const HomeEmpresaScreen({super.key});

  @override
  State<HomeEmpresaScreen> createState() => _HomeEmpresaScreenState();
}

class _HomeEmpresaScreenState extends State<HomeEmpresaScreen> {

  int _selectedIndex = 0;

  late Future<List<DoacaoModel>> _futureDoacoes;

  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _quantidadeController = TextEditingController();

  bool _isEditing = false;

  final _empresaNameController =
      TextEditingController(text: "Minha Empresa S.A.");

  final _emailController =
      TextEditingController(text: "contato@minhaempresa.com.br");

  final _enderecoController =
      TextEditingController(text: "Rua das ONGs, 123 - São Paulo/SP");

  @override
  void initState() {
    super.initState();

    _futureDoacoes = DoacaoService.listarDoacoes();
  }

  @override
  Widget build(BuildContext context) {

    final List<Widget> screens = [

      // DASHBOARD
      Padding(

        padding: const EdgeInsets.all(32),

        child: FutureBuilder<List<DoacaoModel>>(

          future: _futureDoacoes,

          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {

              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final doacoes = snapshot.data ?? [];

            return Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(
                  "Bem-vindo de volta!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                Row(
                  children: [

                    _buildMetricCard(
                      "Total Doado",
                      "${doacoes.length}",
                      Icons.favorite,
                      Colors.blue,
                    ),

                    const SizedBox(width: 20),

                    _buildMetricCard(
                      "Em Aberto",
                      "2",
                      Icons.pending_actions,
                      Colors.orange,
                    ),

                    const SizedBox(width: 20),

                    _buildMetricCard(
                      "Impacto",
                      "500kg",
                      Icons.eco,
                      Colors.green,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                const Text(
                  "Últimas Doações",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(

                  child: ListView.builder(

                    itemCount: doacoes.length > 3
                        ? 3
                        : doacoes.length,

                    itemBuilder: (context, index) {

                      final d = doacoes[index];

                      return Card(

                        margin:
                            const EdgeInsets.only(
                          bottom: 10,
                        ),

                        child: ListTile(

                          leading: const Icon(
                            Icons.history,
                            color: Colors.green,
                          ),

                          title: Text(d.nome),

                          subtitle: Text(
                            d.descricao,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // DOAR
      _buildFormularioDoacao(),

      // HISTÓRICO
      Padding(

        padding: const EdgeInsets.all(20),

        child: FutureBuilder<List<DoacaoModel>>(

          future: _futureDoacoes,

          builder: (context, snapshot) {

            if (snapshot.connectionState ==
                ConnectionState.waiting) {

              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final doacoes = snapshot.data ?? [];

            return Column(

              children: [

                const Text(
                  "Histórico",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(

                  child: ListView.builder(

                    itemCount: doacoes.length,

                    itemBuilder: (context, index) {

                      final d = doacoes[index];

                      return Card(

                        child: ListTile(

                          title: Text(d.nome),

                          subtitle: Text(
                            "Qtd: ${d.quantidade}",
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),

      // PERFIL
      Padding(

        padding: const EdgeInsets.all(40),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              "Meu Perfil",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),

            const SizedBox(height: 30),

            _isEditing

                ? TextFormField(
                    controller:
                        _empresaNameController,
                    decoration:
                        const InputDecoration(
                      labelText:
                          "Nome da Empresa",
                      border:
                          OutlineInputBorder(),
                    ),
                  )

                : ListTile(
                    leading: const Icon(
                      Icons.business,
                      size: 40,
                    ),
                    title: Text(
                      _empresaNameController.text,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                  ),

            const SizedBox(height: 20),

            Card(
              elevation: 2,
              child: Column(
                children: [

                  _isEditing

                      ? TextFormField(
                          controller:
                              _emailController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "E-mail",
                            border:
                                OutlineInputBorder(),
                          ),
                        )

                      : ListTile(
                          leading:
                              const Icon(Icons.email),
                          title:
                              const Text("E-mail"),
                          subtitle: Text(
                            _emailController.text,
                          ),
                        ),

                  const Divider(),

                  _isEditing

                      ? TextFormField(
                          controller:
                              _enderecoController,
                          decoration:
                              const InputDecoration(
                            labelText:
                                "Endereço",
                            border:
                                OutlineInputBorder(),
                          ),
                        )

                      : ListTile(
                          leading:
                              const Icon(Icons.location_on),
                          title:
                              const Text("Endereço"),
                          subtitle: Text(
                            _enderecoController.text,
                          ),
                        ),
                ],
              ),
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

            onDestinationSelected:
                (int index) {

              setState(() {

                _selectedIndex = index;
              });
            },

            leading: const Padding(
              padding: EdgeInsets.all(20),
              child: CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.business,
                  color: Colors.white,
                ),
              ),
            ),

            destinations: const [

              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('Início'),
              ),

              NavigationRailDestination(
                icon: Icon(Icons.add_circle),
                label: Text('Doar'),
              ),

              NavigationRailDestination(
                icon: Icon(Icons.history),
                label: Text('Histórico'),
              ),

              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                label: Text('Perfil'),
              ),
            ],
          ),

          const VerticalDivider(
            thickness: 1,
            width: 1,
          ),

          Expanded(
            child: Container(
              color: Colors.grey[50],
              child: screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {

    return Expanded(

      child: Card(

        elevation: 2,

        child: Padding(

          padding: const EdgeInsets.all(20),

          child: Column(

            children: [

              Icon(
                icon,
                size: 40,
                color: color,
              ),

              const SizedBox(height: 10),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),

              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormularioDoacao() {

    return Padding(

      padding: const EdgeInsets.all(40),

      child: SingleChildScrollView(

        child: Form(

          key: _formKey,

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              const Text(
                "Nova Doação",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 40),

              TextFormField(
                controller: _tituloController,
                decoration: const InputDecoration(
                  labelText: "Título",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _descricaoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Descrição",
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _quantidadeController,
                decoration: const InputDecoration(
                  labelText: "Quantidade",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}