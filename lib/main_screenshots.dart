// HARNESS DE VERIFICACAO VISUAL (nao entra no app final).
//
// Build:  flutter build web --release -t lib/main_screenshots.dart
// Uso:    servir build/web e abrir  http://localhost:PORTA/#<tela>
//
// Faz login REAL como a ONG demo (demo.larviva / demo123) e abre a tela
// escolhida pelo fragment, p/ verificar as telas da rodada de 2026-07-03.
//
// Telas (#fragment):
//   painel        -> Painel aba Interesses (chip Concluida, avaliar doador,
//                    banner de pendencias de prestacao)
//   necessidades  -> Painel aba Necessidades (banner de pendencias no topo)
//   chat          -> ChatOngScreen do match 8 (cabecalho clicavel do doador)
//   perfil-ong    -> preview do perfil publico (capa/streak/Maps/galeria)
//   perfil-doador -> perfil publico do doador 18 (botao Bloquear/Desbloquear)
//   bloqueados    -> lista de doadores bloqueados (Configuracoes)
//   configuracoes -> central de configuracoes (salvar em lote)
//   sobre         -> "Sobre o projeto" + changelog (Versoes). Use ?dark=1 p/ escuro
//   cadastro      -> cadastro de ONG (dropdown UF + autocomplete de cidade)
//   editar-ong    -> edicao do perfil da ONG (UF/cidade por selecao)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/auth/cadastro_ong_screen.dart';
import 'screens/ong/chat_ong_screen.dart';
import 'screens/ong/configuracoes_screen.dart';
import 'screens/ong/doadores_bloqueados_screen.dart';
import 'screens/ong/editar_ong_screen.dart';
import 'screens/ong/painel_ong_screen.dart';
import 'screens/ong/perfil_publico_doador_screen.dart';
import 'screens/ong/perfil_publico_ong_screen.dart';
import 'screens/ong/sobre_projeto_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Login real da ONG demo -> grava o token como o app faria.
  final resp = await http.post(
    Uri.parse('${ApiService.baseUrl}/usuarios/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': 'demo.larviva@connectong.com',
      'senha': 'demo123',
    }),
  );
  final dados = jsonDecode(resp.body) as Map<String, dynamic>;
  await ApiService.setToken(dados['accessToken'] as String?);

  final tela = Uri.base.fragment.isEmpty ? 'painel' : Uri.base.fragment;
  // ?dark=1 força o tema escuro (para conferir legibilidade no modo escuro).
  final escuro = Uri.base.queryParameters['dark'] == '1';
  runApp(_HarnessApp(tela: tela, escuro: escuro));
}

class _HarnessApp extends StatelessWidget {
  final String tela;
  final bool escuro;
  const _HarnessApp({required this.tela, this.escuro = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: escuro ? ThemeMode.dark : ThemeMode.light,
      home: _telaPorNome(tela),
    );
  }

  Widget _telaPorNome(String nome) {
    switch (nome) {
      case 'necessidades':
        return const PainelOngScreen(
          emailUsuario: 'demo.larviva@connectong.com',
          ongId: 33,
          ongNome: 'Lar Viva',
        );
      case 'chat':
        return const ChatOngScreen(
          interesseId: 8,
          titulo: 'Joao Pereira',
          doadorId: 18,
        );
      case 'perfil-ong':
        return const PerfilPublicoOngScreen(ongId: 33, ongNome: 'Lar Viva');
      case 'perfil-doador':
        return const PerfilPublicoDoadorScreen(
            doadorId: 18, doadorNome: 'Joao Pereira');
      case 'bloqueados':
        return const DoadoresBloqueadosScreen();
      case 'configuracoes':
        return const ConfiguracoesScreen();
      case 'sobre':
        return const SobreProjetoScreen();
      case 'cadastro':
        return const CadastroOngScreen();
      case 'editar-ong':
        return const EditarOngScreen(ongId: 33);
      case 'painel':
      default:
        return const PainelOngScreen(
          emailUsuario: 'demo.larviva@connectong.com',
          ongId: 33,
          ongNome: 'Lar Viva',
          abaInicial: 1,
        );
    }
  }
}
