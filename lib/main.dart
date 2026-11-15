import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/splash_screen.dart';
import 'package:tata_saka_app/screens/login_screen.dart';
import 'package:tata_saka_app/screens/main_layout.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('id_ID', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContractProvider()),

        ChangeNotifierProvider(create: (_) => UserProfileProvider()),

        ChangeNotifierProvider(create: (_) => TimelineProvider()),
      ],

      child: const TataSakaApp(),
    ),
  );
}

class TataSakaApp extends StatelessWidget {
  const TataSakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProf, _) {
        return MaterialApp(
          title: 'Tata Saka Consultant',
          debugShowCheckedModeBanner: false,
          builder: (context, child) => child == null
              ? const SizedBox.shrink()
              : ResponsiveAppFrame(child: child),
          themeMode: userProf.flutterThemeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
          locale: userProf.language == 'English'
              ? const Locale('en', 'US')
              : const Locale('id', 'ID'),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.navySlate,
              primary: AppColors.navySlate,
              surface: Colors.white,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: AppColors.softGray,
            cardColor: Colors.white,
            dividerColor: AppColors.border,
            fontFamily: 'Inter',
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navySlate,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: AppColors.navySlate,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: AppColors.navySlate),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navySlate,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: AppColors.navySlate,
              foregroundColor: Colors.white,
              elevation: 2,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF38BDF8),
              secondary: Color(0xFF60A5FA),
              surface: Color(0xFF1E293B),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            cardColor: const Color(0xFF1E293B),
            dividerColor: const Color(0xFF334155),
            fontFamily: 'Inter',
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E293B),
              foregroundColor: Color(0xFFF8FAFC),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: Color(0xFFF8FAFC),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E293B),
              selectedItemColor: Color(0xFF38BDF8),
              unselectedItemColor: Color(0xFF94A3B8),
            ),
          ),
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
            '/main': (context) => const MainLayout(),
          },
        );
      },
    );
  }
}
