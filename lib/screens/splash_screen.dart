import 'package:flutter/material.dart';
import 'package:tata_saka_app/services/auth_service.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;
      final user = AuthService.currentUser;
      if (user == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
        return;
      }
      // Sesi masih ada → pastikan akun belum dinonaktifkan/hapus oleh Admin.
      try {
        final doc = await AuthService.fetchUserDoc(user.uid);
        if (doc == null || doc['isActive'] == false) {
          await AuthService.signOut();
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          return;
        }
      } catch (_) {
        // Offline / Firestore tak terjangkau → biarkan sesi berlanjut.
      }
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    });
  }

  @override
  Widget build(BuildContext context) {
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
