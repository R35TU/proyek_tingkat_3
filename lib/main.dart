import 'package:flutter/material.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/splash_screen.dart';
import 'package:tata_saka_app/screens/login_screen.dart';
import 'package:tata_saka_app/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContractProvider()),
      ],
      child: const TataSakaApp(),
    ),
  );
}

class TataSakaApp extends StatelessWidget {
  const TataSakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tata Saka Consultant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          primary: AppColors.primaryBlue,
          background: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Inter', // We can add google_fonts later if needed
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainLayout(),
      },
    );
  }
}
