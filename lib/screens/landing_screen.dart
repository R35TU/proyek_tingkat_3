import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tata_saka_app/services/file_downloader.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';

/// Halaman Landing Page resmi aplikasi SAKA-REP (Tata Saka-Reporting System).
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  static const String _apkDownloadUrl =
      'https://kencana.basic.box.cloudeka.id/tatasaka-media-rw4mpj/app-release.apk';
  static const double _maxContentWidth = 1280;

  void _navigateTo(BuildContext context, String route) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(route);
    } else {
      Navigator.of(context).pushNamed(route);
    }
  }

  Future<void> _downloadApk(BuildContext context) async {
    try {
      if (kIsWeb) {
        await openRemoteInNewTab(_apkDownloadUrl);
      } else {
        await downloadAndOpenRemote(_apkDownloadUrl, 'app-release.apk');
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal memulai unduhan aplikasi. Silakan coba lagi.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isWide = width >= 1100;
    final horizontalPadding = isDesktop ? 48.0 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFD),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDesktop, horizontalPadding),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: isDesktop ? 40 : 28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight -
                                (isDesktop ? 80 : 56))
                            .clamp(0.0, double.infinity),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _maxContentWidth,
                          ),
                          child: isDesktop
                              ? _buildDesktopLayout(context, isWide)
                              : _buildMobileLayout(context),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildFooter(isDesktop, horizontalPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDesktop,
    double horizontalPadding,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: SizedBox(
            height: isDesktop ? 80 : 68,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          height: isDesktop ? 48 : 42,
                          width: isDesktop ? 48 : 42,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0D0F172A),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logoRev.png',
                            fit: BoxFit.contain,
                            cacheWidth: 144,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(
                              Icons.business,
                              color: AppColors.primaryBlue,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'SAKA-REP',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isDesktop ? 18 : 16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.3,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'TATA SAKA-REPORTING SYSTEM',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isDesktop ? 11 : 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _navigateTo(context, '/login'),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.hovered)) {
                          return const Color(0xFF1D4ED8);
                        }
                        return const Color(0xFF0F172A);
                      }),
                      foregroundColor:
                          const WidgetStatePropertyAll<Color>(Colors.white),
                      elevation: const WidgetStatePropertyAll<double>(2),
                      shadowColor: const WidgetStatePropertyAll<Color>(
                        Color(0x260F172A),
                      ),
                      padding: WidgetStatePropertyAll<EdgeInsets>(
                        EdgeInsets.symmetric(
                          horizontal: isDesktop ? 20 : 14,
                          vertical: isDesktop ? 15 : 12,
                        ),
                      ),
                      shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Login Portal',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isWide) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 7,
          child: _buildHeroText(context, isDesktop: true, isWide: isWide),
        ),
        const SizedBox(width: 40),
        Expanded(
          flex: 5,
          child: _buildHeroLogo(size: isWide ? 410 : 320),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        _buildHeroLogo(size: 185),
        const SizedBox(height: 18),
        _buildHeroText(
          context,
          isDesktop: false,
          isWide: false,
          isCenter: true,
        ),
      ],
    );
  }

  Widget _buildHeroLogo({required double size}) {
    final outerRing = size * 1.16;
    final innerRing = size * 1.02;

    return Center(
      child: SizedBox(
        width: outerRing,
        height: outerRing,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFDC2626).withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.9),
                    const Color(0xFF1D4ED8).withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
            Container(
              width: outerRing,
              height: outerRing,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1D4ED8).withValues(alpha: 0.08),
                ),
              ),
            ),
            Container(
              width: innerRing,
              height: innerRing,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                ),
              ),
            ),
            Container(
              width: size * 0.88,
              height: size * 0.88,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white,
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
              padding: EdgeInsets.all(size * 0.04),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logoRev.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.business,
                    size: 120,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroText(
    BuildContext context, {
    required bool isDesktop,
    required bool isWide,
    bool isCenter = false,
  }) {
    final align = isCenter ? TextAlign.center : TextAlign.left;
    final crossAlign =
        isCenter ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final double headlineSize = isWide ? 58 : (isDesktop ? 46 : 36);

    return Column(
      crossAxisAlignment: crossAlign,
      children: [
        Text(
          'Ngrancang\nKanthi Titi.\nNgawal\nNganti Tutug.',
          textAlign: align,
          style: TextStyle(
            fontSize: headlineSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
            height: 1.09,
            letterSpacing: isDesktop ? -1.4 : -0.6,
          ),
        ),
        const SizedBox(height: 22),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Pengawasan proyek infrastruktur, monitoring, dan pelaporan terintegrasi dengan koordinasi transparan antara konsultan, kontraktor, dan dinas.',
            textAlign: align,
            style: TextStyle(
              fontSize: isDesktop ? 17 : 15,
              color: const Color(0xFF475569),
              height: 1.58,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          alignment: isCenter ? WrapAlignment.center : WrapAlignment.start,
          children: [
            ElevatedButton(
              onPressed: () => _navigateTo(context, '/login'),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) {
                    return const Color(0xFF1D4ED8);
                  }
                  return const Color(0xFF0F172A);
                }),
                foregroundColor:
                    const WidgetStatePropertyAll<Color>(Colors.white),
                elevation: const WidgetStatePropertyAll<double>(2),
                shadowColor: const WidgetStatePropertyAll<Color>(
                  Color(0x330F172A),
                ),
                padding: const WidgetStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 26, vertical: 18),
                ),
                shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mulai',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: () => _navigateTo(context, '/panduan-umum'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                backgroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Panduan & FAQ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _downloadApk(context),
              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
              label: const Text(
                'Download Aplikasi',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1D4ED8),
                side: const BorderSide(color: Color(0xFFBFDBFE)),
                backgroundColor: const Color(0xFFEFF6FF),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFooter(bool isDesktop, double horizontalPadding) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 16,
              horizontal: horizontalPadding,
            ),
            child: Align(
              alignment:
                  isDesktop ? Alignment.centerLeft : Alignment.center,
              child: const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Tata Saka Consultant  ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    TextSpan(
                      text: '© 2026 Seluruh hak cipta dilindungi.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
