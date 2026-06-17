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

                    color: Colors.green.withValues(
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

            Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(

                  'Dashboard',

                  style: TextStyle(

                    fontSize: 34,

                    fontWeight: FontWeight.bold,

                    color: Color(0xFF1E293B),
                  ),
                ),

                const SizedBox(height: 8),

                Text(

                  'Acompanhe suas doações e impacto social.',

                  style: TextStyle(

                    fontSize: 16,

                    color: Colors.grey.shade600,
                  ),
                ),
              ],
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
                      bottom: 12,
                    ),

                    child: ListTile(

                      contentPadding:
                          const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),

                      leading: Container(

                        padding:
                            const EdgeInsets.all(12),

                        decoration: BoxDecoration(

                          color: Colors.green
                              .withValues(
                            alpha: 0.10,
                          ),

                          borderRadius:
                              BorderRadius.circular(
                            14,
                          ),
                        ),

                        child: const Icon(

                          Icons.volunteer_activism,

                          color: Color(0xFF2E7D32),
                        ),
                      ),

                      title: Text(

                        d.nome,

                        style: const TextStyle(
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      subtitle: Padding(

                        padding:
                            const EdgeInsets.only(
                          top: 4,
                        ),

                        child: Text(
                          d.descricao,
                        ),
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

      final doacoes =
          (snapshot.data ?? [])
              .reversed
              .toList();

      return Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          const Text(

            "Histórico de Doações",

            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),

          const SizedBox(height: 8),

          Text(

            "Acompanhe todas as doações realizadas pela sua empresa.",

            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 32),

          Expanded(

            child: ListView.builder(

              padding: const EdgeInsets.only(
                top: 8,
              ),

              itemCount: doacoes.length,

              itemBuilder: (context, index) {

                final d = doacoes[index];

                return Container(

                  margin: const EdgeInsets.only(
                    bottom: 18,
                  ),

                  decoration: BoxDecoration(

                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(20),

                    boxShadow: [

                      BoxShadow(

                        color: Colors.black.withValues(
                          alpha: 0.04,
                        ),

                        blurRadius: 24,

                        offset: const Offset(
                          0,
                          10,
                        ),
                      ),
                    ],
                  ),

                  child: ListTile(

                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),

                    leading: Container(

                      width: 64,
                      height: 64,

                      decoration: BoxDecoration(

                        color: const Color(
                          0xFFE8F5E9,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          16,
                        ),
                      ),

                      child: const Icon(

                        Icons.volunteer_activism,

                        color: Color(0xFF2E7D32),

                        size: 32,
                      ),
                    ),

                    title: Text(

                      d.nome,

                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),

                    subtitle: Padding(

                      padding:
                          const EdgeInsets.only(
                        top: 8,
                      ),

                      child: Row(

                        children: [

                          Icon(

                            Icons.inventory_2_outlined,

                            size: 18,

                            color: Colors.grey.shade600,
                          ),

                          const SizedBox(width: 8),

                          Text(

                            "Quantidade: ${d.quantidade}",

                            style: TextStyle(
                              color:
                                  Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    trailing: Container(

                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),

                      decoration: BoxDecoration(

                        color: const Color(
                          0xFFE8F5E9,
                        ),

                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),

                      child: const Text(

                        "Concluída",

                        style: TextStyle(
                          color: Color(0xFF2E7D32),
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
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

  backgroundColor: Colors.white,

  extended: true,

  minExtendedWidth: 240,

  selectedIndex: _selectedIndex,

  useIndicator: true,

  indicatorColor: const Color(0xFFE8F5E9),

  selectedIconTheme: const IconThemeData(
    color: Color(0xFF2E7D32),
    size: 26,
  ),

  unselectedIconTheme: IconThemeData(
    color: Colors.grey.shade600,
    size: 24,
  ),

  selectedLabelTextStyle: const TextStyle(
    color: Color(0xFF2E7D32),
    fontWeight: FontWeight.w600,
  ),

  unselectedLabelTextStyle: TextStyle(
    color: Colors.grey.shade700,
  ),

  onDestinationSelected: (index) {

    setState(() {

      _selectedIndex = index;
    });
  },

  leading: Padding(

    padding: const EdgeInsets.all(24),

    child: Column(

      children: [

        Container(

          width: 110,
          height: 110,

          decoration: BoxDecoration(

            shape: BoxShape.circle,

            color: Colors.white,

            boxShadow: [

              BoxShadow(

                color: Colors.black.withValues(
                  alpha: 0.08,
                ),

                blurRadius: 24,
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

        const SizedBox(height: 20),

        Text(

          widget.emailUsuario,

          textAlign: TextAlign.center,

          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 24),

        ElevatedButton.icon(

          onPressed: () {

            Navigator.pushReplacement(

              context,

              MaterialPageRoute(

                builder: (_) => const LoginScreen(),
              ),
            );
          },

          icon: const Icon(Icons.logout),

          label: const Text('Sair'),

          style: ElevatedButton.styleFrom(

            backgroundColor: const Color(0xFFFFF1F2),

            foregroundColor: Colors.red.shade700,

            elevation: 0,
          ),
        ),
      ],
    ),
  ),

  destinations: const [

    NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Início'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.favorite_border),
      selectedIcon: Icon(Icons.favorite),
      label: Text('Doar'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: Text('Histórico'),
    ),

    NavigationRailDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
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

              color: const Color(0xFFF8FAFC),

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

      height: 220,

      decoration: BoxDecoration(

        borderRadius: BorderRadius.circular(24),

        gradient: LinearGradient(

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,

          colors: [

            Colors.white,

            color.withValues(alpha: 0.08)
          ],
        ),

        boxShadow: [

         BoxShadow(

          color: Colors.black.withValues(alpha: 0.08),

          blurRadius: 30,

            spreadRadius: -10,

            offset: const Offset(0, 8),
            ),
        ],
      ),

      child: Padding(

        padding: const EdgeInsets.all(24),

        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

           crossAxisAlignment: CrossAxisAlignment.start,


          children: [

            Container(

              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(

              color: color.withValues(alpha: 0.12),

              borderRadius: BorderRadius.circular(16),
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

                fontSize: 32,

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