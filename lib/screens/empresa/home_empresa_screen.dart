import 'package:flutter/material.dart';

import '../../models/doacao_model.dart';
import '../../services/doacao_service.dart';
import '../auth/login_screen.dart';

class HomeEmpresaScreen extends StatefulWidget {

  final String emailUsuario;

  const HomeEmpresaScreen({
    super.key,
    required this.emailUsuario,
  });

  @override
  State<HomeEmpresaScreen> createState() =>
      _HomeEmpresaScreenState();
}

class _HomeEmpresaScreenState
    extends State<HomeEmpresaScreen> {

  int _selectedIndex = 0;

  late Future<List<DoacaoModel>> _futureDoacoes;

  final _formKey = GlobalKey<FormState>();

  final _tituloController = TextEditingController();
  final _descricaoController = TextEditingController();
  final _quantidadeController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _futureDoacoes =
        DoacaoService.listarDoacoes();
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

  return Center(

    child: Column(

      mainAxisAlignment:
          MainAxisAlignment.center,

      children: [

        Container(

          width: 70,
          height: 70,

          decoration: BoxDecoration(

            color:
                Colors.green.withValues(
              alpha: 0.08,
            ),

            borderRadius:
                BorderRadius.circular(20),
          ),

          child: const Padding(

            padding: EdgeInsets.all(18),

            child:
                CircularProgressIndicator(
              strokeWidth: 4,
              color: Colors.green,
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(

          'Carregando dashboard...',

          style: TextStyle(

            fontSize: 18,

            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 8),

        Text(

          'Buscando informações do sistema',

          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
      ],
    ),
  );
}

            final doacoes =
                (snapshot.data ?? [])
                    .reversed
                    .toList();

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

                          subtitle:
                              Text(d.descricao),
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

            final doacoes =
                (snapshot.data ?? [])
                    .reversed
                    .toList();

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

            ListTile(

              leading: const Icon(
                Icons.business,
                size: 40,
              ),

              title: const Text(
                "Usuário Conectado",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: Text(
                widget.emailUsuario,
              ),
            ),

            const SizedBox(height: 20),

            Card(

              elevation: 2,

              child: Column(
                children: [

                  ListTile(

                    leading:
                        const Icon(Icons.email),

                    title:
                        const Text("E-mail"),

                    subtitle:
                        Text(widget.emailUsuario),
                  ),

                  const Divider(),

                  const ListTile(

                    leading:
                        Icon(Icons.location_on),

                    title:
                        Text("Status"),

                    subtitle:
                        Text("Conta ativa"),
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

            leading: Padding(

              padding:
                  const EdgeInsets.all(20),

              child: Column(

                children: [

                  Container(

  width: 90,
  height: 90,

  decoration: BoxDecoration(

    shape: BoxShape.circle,

    color: Colors.white,

    boxShadow: [

      BoxShadow(

        color:
            Colors.black.withValues(
          alpha: 0.08,
        ),

        blurRadius: 10,
      ),
    ],
  ),

  child: Padding(

    padding: const EdgeInsets.all(12),

    child: ClipOval(

      child: Image.asset(

        'assets/images/logo.jpg',

        fit: BoxFit.cover,
      ),
    ),
  ),
),

                  const SizedBox(height: 12),

                  Text(

                    widget.emailUsuario,

                    textAlign: TextAlign.center,

                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton.icon(

                    onPressed: () {

                      Navigator.pushReplacement(

                        context,

                        MaterialPageRoute(

                          builder: (_) =>
                              const LoginScreen(),
                        ),
                      );
                    },

                    icon:
                        const Icon(Icons.logout),

                    label:
                        const Text('Sair'),

                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red,
                      foregroundColor:
                          Colors.white,
                    ),
                  ),
                ],
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

              child:
                  screens[_selectedIndex],
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

    child: Container(

      height: 210,

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(24),

        gradient: LinearGradient(

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [

            Colors.white,

            color.withOpacity(0.08),
          ],
        ),

        boxShadow: [

          BoxShadow(

            color: Colors.black.withOpacity(0.08),

            blurRadius: 20,

            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Container(

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(

                color: color.withOpacity(0.12),

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Icon(
                icon,
                size: 34,
                color: color,
              ),
            ),

            const Spacer(),

            Text(

              title,

              style: TextStyle(

                fontSize: 15,

                color: Colors.grey[700],

                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Text(

              value,

              style: const TextStyle(

                fontSize: 30,

                fontWeight: FontWeight.bold,

                letterSpacing: -1,
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
                  fontWeight:
                      FontWeight.bold,
                  color: Colors.green,
                ),
              ),

              const SizedBox(height: 40),

              TextFormField(
                controller:
                    _tituloController,

                decoration:
                    const InputDecoration(
                  labelText: "Título",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller:
                    _descricaoController,

                maxLines: 3,

                decoration:
                    const InputDecoration(
                  labelText: "Descrição",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller:
                    _quantidadeController,

                decoration:
                    const InputDecoration(
                  labelText: "Quantidade",
                  border:
                      OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(

                width: 250,
                height: 50,

                child: ElevatedButton(

                  onPressed: () async {

  showDialog(

    context: context,

    barrierDismissible: false,

    builder: (_) => const Center(

      child: CircularProgressIndicator(),
    ),
  );

  final sucesso =
      await DoacaoService.criarDoacao(

    nome: _tituloController.text,

    descricao:
        _descricaoController.text,

    quantidade: int.tryParse(
          _quantidadeController.text,
        ) ??
        0,
  );

  if (mounted) {
    Navigator.pop(context);
  }

  if (sucesso) {

    showDialog(

      context: context,

      builder: (_) => AlertDialog(

        shape: RoundedRectangleBorder(

          borderRadius:
              BorderRadius.circular(20),
        ),

        title: const Row(

          children: [

            Icon(
              Icons.check_circle,
              color: Colors.green,
            ),

            SizedBox(width: 10),

            Text('Sucesso'),
          ],
        ),

        content: const Text(
          'Doação cadastrada com sucesso!',
        ),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.pop(context);
            },

            child: const Text('OK'),
          ),
        ],
      ),
    );

    _tituloController.clear();

    _descricaoController.clear();

    _quantidadeController.clear();

    setState(() {

      _futureDoacoes =
          Future.delayed(

        const Duration(
            milliseconds: 200),

        () => DoacaoService
            .listarDoacoes(),
      );
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (mounted) {

      setState(() {

        _selectedIndex = 0;
      });
    }

  } else {

    showDialog(

      context: context,

      builder: (_) => AlertDialog(

        shape: RoundedRectangleBorder(

          borderRadius:
              BorderRadius.circular(20),
        ),

        title: const Row(

          children: [

            Icon(
              Icons.error,
              color: Colors.red,
            ),

            SizedBox(width: 10),

            Text('Erro'),
          ],
        ),

        content: const Text(
          'Erro ao cadastrar doação',
        ),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.pop(context);
            },

            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }
},

                  child: const Text(
                    'Cadastrar Doação',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}