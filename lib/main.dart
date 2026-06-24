import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'theme/app_theme.dart';
import 'config/config_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConnectONGApp());
}

class ConnectONGApp extends StatelessWidget {
  const ConnectONGApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = ConfigController.instance;

    return ListenableBuilder(
      listenable: config,
      builder: (context, _) {
        return MaterialApp(
          title: 'Connect ONG',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(
            dislexia: config.fonteDislexia,
            altoContraste: config.altoContraste,
          ),
          darkTheme: AppTheme.dark(
            dislexia: config.fonteDislexia,
            altoContraste: config.altoContraste,
          ),
          themeMode: config.themeMode,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(config.textScale),
              ),
              child: child!,
            );
          },
          home: const LoginScreen(),
        );
      },
    );
  }
}
