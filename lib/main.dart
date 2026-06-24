import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/auth/login_screen.dart';
import 'theme/app_colors.dart';

void main() {

  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ConnectONGApp());
}

class ConnectONGApp extends StatelessWidget {

  const ConnectONGApp({super.key});

  @override
  Widget build(BuildContext context) {

    final baseTextTheme =
        GoogleFonts.poppinsTextTheme();

    return MaterialApp(

      title: 'Connect ONG',

      debugShowCheckedModeBanner: false,

      theme: ThemeData(

        useMaterial3: true,

        brightness: Brightness.light,

        scaffoldBackgroundColor:
            const Color(0xFFF5F7FA),

        colorScheme: ColorScheme.fromSeed(

          seedColor: AppColors.primary,

          brightness: Brightness.light,
        ),

        textTheme: baseTextTheme.apply(

          bodyColor: const Color(0xFF1E293B),

          displayColor:
              const Color(0xFF1E293B),
        ),

        appBarTheme: AppBarTheme(

          backgroundColor: Colors.white,

          elevation: 0,

          centerTitle: false,

          titleTextStyle: GoogleFonts.poppins(

            fontSize: 22,

            fontWeight: FontWeight.bold,

            color: const Color(0xFF1E293B),
          ),
        ),

        cardTheme: CardThemeData(

          elevation: 0,

          color: Colors.white,

          shape: RoundedRectangleBorder(

            borderRadius:
                BorderRadius.circular(20),
          ),
        ),

        elevatedButtonTheme:
            ElevatedButtonThemeData(

          style: ElevatedButton.styleFrom(

            elevation: 0,

            backgroundColor:
                AppColors.primary,

            foregroundColor: Colors.white,

            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 18,
            ),

            shape: RoundedRectangleBorder(

              borderRadius:
                  BorderRadius.circular(14),
            ),

            textStyle: GoogleFonts.poppins(

              fontSize: 15,

              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        inputDecorationTheme:
            InputDecorationTheme(

          filled: true,

          fillColor: Colors.white,

          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),

          border: OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(14),

            borderSide: BorderSide.none,
          ),

          enabledBorder:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(14),

            borderSide: BorderSide(
              color: Colors.grey.shade300,
            ),
          ),

          focusedBorder:
              OutlineInputBorder(

            borderRadius:
                BorderRadius.circular(14),

            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
        ),
      ),

      home: const LoginScreen(),
    );
  }
}