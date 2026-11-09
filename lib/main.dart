import 'package:flutter/material.dart';

import 'screens/main_screen.dart';
import 'services/api_service.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.instance.restore();
  runApp(const FusaShieldApp());
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
      home: const MainScreen(),
    );
  }
}
