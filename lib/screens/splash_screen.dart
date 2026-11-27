import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  Timer? _navTimer;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _progressAnimation;
  UserProfileProvider? _userProfileProvider;
  bool _minDurationElapsed = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _progressAnimation = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeInOut),
    );
    _animController.forward();

    _navTimer = Timer(const Duration(milliseconds: 1500), () {
      _minDurationElapsed = true;
      _tryNavigate();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<UserProfileProvider>();
    if (!identical(_userProfileProvider, provider)) {
      _userProfileProvider?.removeListener(_onAuthStateChanged);
      _userProfileProvider = provider;
      _userProfileProvider?.addListener(_onAuthStateChanged);
    }
    _tryNavigate();
  }

  void _onAuthStateChanged() {
    _tryNavigate();
  }

  void _tryNavigate() {
    if (!mounted || _hasNavigated || !_minDurationElapsed) return;
    final userProf = _userProfileProvider ?? context.read<UserProfileProvider>();
    if (!userProf.isInitialized) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;

    _hasNavigated = true;
    final target = userProf.isAuthenticated
        ? (userProf.role.toLowerCase() == 'admin' ? '/admin' : '/dashboard')
        : '/landing';

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      Router.neglect(context, () => router.go(target));
    } else {
      Navigator.of(context).pushReplacementNamed(target);
    }
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _navTimer = null;
    _userProfileProvider?.removeListener(_onAuthStateChanged);
    _animController.dispose();
    super.dispose();
  }

  Widget _buildSplashBody() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Center Logo, Animation & Loading Indicator
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/logoRev.png',
                      width: 250,
                      errorBuilder: (context, error, stackTrace) {
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
                    const SizedBox(height: 28),
                    SizedBox(
                      width: 160,
                      child: AnimatedBuilder(
                        animation: _progressAnimation,
                        builder: (context, _) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: _progressAnimation.value,
                              minHeight: 4,
                              backgroundColor: AppColors.slateLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.navySlate,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Memuat aplikasi...',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Footer Shape (khusus tampilan mobile agar tidak menimpa logo pada Web desktop/layar awal)
          if (!kIsWeb && !ResponsiveBreakpoints.isDesktop(context))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/landingpage.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 150,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
