import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/admin_page.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/landing_screen.dart';
import 'package:tata_saka_app/screens/main_layout.dart';
import 'package:tata_saka_app/services/auth_service.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/utils/web_navigation.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    // Di web, rute '/' langsung di-render deklaratif oleh build()
    if (kIsWeb) return;

    _navTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (ModalRoute.of(context)?.isCurrent != true) return;
      final userProf = context.read<UserProfileProvider>();
      final isAuth = AuthService.currentUser != null && userProf.username.isNotEmpty;
      if (isAuth) {
        if (userProf.role.toLowerCase() == 'admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
        }
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, '/landing', (route) => false);
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _navTimer = null;
    super.dispose();
  }

  Widget _buildSplashBody() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Center Logo
          Center(
            child: Image.asset(
              'assets/images/logoRev.png',
              width: 250,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if logo not found
                return const Text(
                  'CV. TATA SAKA',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                );
              },
            ),
          ),

          // Bottom Footer Shape
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/landingpage.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pada web, route '/' langsung tampilkan konten sebenarnya tanpa screen mati
    if (kIsWeb) {
      final userProf = context.watch<UserProfileProvider>();
      if (!userProf.isInitialized) {
        return _buildSplashBody();
      }
      if (userProf.isAuthenticated) {
        final initialWebRoute = getInitialWebRoute();
        if (initialWebRoute.isNotEmpty && initialWebRoute != '/') {
          final uri = Uri.tryParse(initialWebRoute);
          if (uri != null) {
            if (uri.path == '/detail-kontrak') {
              final cid = uri.queryParameters['id'];
              final tab = int.tryParse(uri.queryParameters['tab'] ?? '0') ?? 0;
              return DetailKontrakScreen(contractId: cid, initialTabIndex: tab);
            }
            final cleanPath = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
            if (cleanPath.isNotEmpty && cleanPath != 'main') {
              return MainLayout(initialMenu: cleanPath);
            }
          }
        }
        if (userProf.role.toLowerCase() == 'admin') {
          replaceWebUrl('/#/admin');
          return const AdminPage();
        }
        replaceWebUrl('/#/dashboard');
        return const MainLayout(initialMenu: 'dashboard');
      }
      return const LandingScreen();
    }

    return _buildSplashBody();
  }
}

class SplashFooterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBlack = Paint()..color = Colors.black;
    final paintRed = Paint()..color = AppColors.primaryRed;
    final paintBlue = Paint()..color = AppColors.primaryBlue;

    // Red Wave
    final pathRed = Path();
    pathRed.moveTo(0, size.height * 0.3);
    pathRed.quadraticBezierTo(
        size.width * 0.3, size.height * 0.5, size.width * 0.6, size.height * 0.8);
    pathRed.lineTo(0, size.height * 0.8);
    pathRed.close();
    canvas.drawPath(pathRed, paintRed);

    // Blue Wave
    final pathBlue = Path();
    pathBlue.moveTo(size.width, size.height * 0.2);
    pathBlue.quadraticBezierTo(
        size.width * 0.6, size.height * 0.6, size.width * 0.3, size.height * 0.9);
    pathBlue.lineTo(size.width, size.height * 0.9);
    pathBlue.close();
    canvas.drawPath(pathBlue, paintBlue);

    // Black Base
    final pathBlack = Path();
    pathBlack.moveTo(0, size.height * 0.5);
    pathBlack.quadraticBezierTo(
        size.width * 0.5, size.height * 0.7, size.width, size.height * 0.5);
    pathBlack.lineTo(size.width, size.height);
    pathBlack.lineTo(0, size.height);
    pathBlack.close();
    canvas.drawPath(pathBlack, paintBlack);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
