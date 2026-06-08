import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/login_screen.dart';

void main() {
  runApp(const ConnectONGApp());
}

class ConnectONGApp extends StatelessWidget {
  const ConnectONGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Connect ONG',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // O fromSeed cria toda a paleta (primary, surface, etc) baseada no seu verde
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32), // Verde Social
          brightness: Brightness.light,
        ),
        // Google Fonts aplicado de forma global
        textTheme: GoogleFonts.poppinsTextTheme(),
        
        // Estilização global para os botões (para não ter que configurar um por um)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}