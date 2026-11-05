import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'screens/main_screen.dart';
import 'services/api_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.restore();
  runApp(const FusaShieldApp());
}

/// Belum login -> halaman login. Sudah login (atau sesi habis lalu logout otomatis) -> otomatis berganti.
class _Gate extends StatelessWidget {
  const _Gate();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: ApiService.loggedIn,
        builder: (context, ok, child) => ok ? const MainScreen() : const LoginPage(),
      );
}

class FusaShieldApp extends StatelessWidget {
  const FusaShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FusaShield',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
        ),
        fontFamily: 'Roboto',
      ),
      home: const _Gate(),
    );
  }
}
