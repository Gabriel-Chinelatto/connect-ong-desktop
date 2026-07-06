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
//   chat          -> ChatOngScreen do match 8 (anexo de imagem)
//   perfil-ong    -> preview do perfil publico (capa/streak/Maps/galeria)
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'screens/ong/chat_ong_screen.dart';
import 'screens/ong/painel_ong_screen.dart';
import 'screens/ong/perfil_publico_ong_screen.dart';
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
  runApp(_HarnessApp(tela: tela));
}

class _HarnessApp extends StatelessWidget {
  final String tela;
  const _HarnessApp({required this.tela});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
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
          titulo: 'Fraldas geriatricas — Joao Pereira',
        );
      case 'perfil-ong':
        return const PerfilPublicoOngScreen(ongId: 33, ongNome: 'Lar Viva');
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
