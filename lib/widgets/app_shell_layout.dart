import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

/// Shell utama aplikasi untuk Desktop Web (WebDashboardLayout)
/// dan Mobile (BottomNavigationBar pada top-level tabs).
/// Semua status aktif diturunkan langsung dari URL GoRouter aktif.
class AppShellLayout extends StatelessWidget {
  final GoRouterState routerState;
  final Widget child;

  const AppShellLayout({
    super.key,
    required this.routerState,
    required this.child,
  });

  static const Set<String> _topLevelMobilePaths = {
    '/dashboard',
    '/kontrak',
    '/kegiatan',
    '/laporan',
    '/timeline',
    '/akun',
  };

  bool _isNestedRoute(String path) {
    final clean = path.split('?').first;
    return clean.startsWith('/kontrak/') ||
        clean.startsWith('/kegiatan/') ||
        clean.startsWith('/laporan/') ||
        clean.startsWith('/akun/');
  }

  String _parentRouteFor(String path) {
    final clean = path.split('?').first;
    if (clean.startsWith('/kontrak/')) {
      final parts = clean.split('/').where((e) => e.isNotEmpty).toList();
      // /kontrak/:id/kegiatan/:idx/rkk -> /kontrak/:id/kegiatan/:idx
      if (parts.length >= 5) return '/${parts.take(4).join('/')}';
      // /kontrak/:id/kegiatan/:idx or /kontrak/:id/edit -> /kontrak/:id
      if (parts.length >= 3) return '/kontrak/${parts[1]}';
      return '/kontrak';
    }
    if (clean.startsWith('/kegiatan/')) {
      final parts = clean.split('/').where((e) => e.isNotEmpty).toList();
      if (parts.length >= 4) return '/${parts.take(3).join('/')}';
      return '/kegiatan';
    }
    if (clean.startsWith('/laporan/data/')) return '/laporan/data';
    if (clean.startsWith('/laporan/')) return '/laporan';
    if (clean.startsWith('/akun/')) return '/akun';
    return '/dashboard';
  }

  String _headerTitleForPath(String path, UserProfileProvider userProf) {
    final clean = path.split('?').first;
    if (clean == '/dashboard') {
      return userProf.isKontraktor
          ? 'Dashboard Kontraktor'
          : userProf.tr('nav_dashboard');
    }
    if (clean == '/kontrak') return userProf.tr('nav_kontrak');
    if (clean == '/kontrak/tambah') return 'Tambah Kontrak Baru';
    if (clean.contains('/edit')) return 'Edit Kontrak';
    if (clean.contains('/rkk')) return 'RAB / BoQ (Rencana Kerja)';
    if (clean.contains('/addendum')) return 'Addendum / CCO';
    if (clean.contains('/kegiatan/')) return 'Detail Kegiatan';
    if (clean.startsWith('/kontrak/')) return 'Detail Kontrak';
    if (clean == '/kegiatan') return userProf.tr('nav_kegiatan_saya');
    if (clean.startsWith('/kegiatan/')) return 'Detail Kegiatan';
    if (clean == '/laporan') return 'Laporan Proyek';
    if (clean == '/laporan/data') return 'Laporan Harian';
    if (clean.startsWith('/laporan/data/')) return 'Detail Laporan Harian';
    if (clean == '/laporan/harian') return 'Buat Laporan Harian';
    if (clean == '/laporan/mingguan') return 'Laporan Mingguan';
    if (clean == '/laporan/bulanan') return 'Laporan Bulanan';
    if (clean.startsWith('/timeline')) return 'Timeline & Histori';
    if (clean == '/akun') return userProf.tr('nav_account');
    if (clean.startsWith('/akun/profil')) return 'Edit Profil';
    if (clean.startsWith('/akun/pengaturan')) return userProf.tr('settings_title');
    if (clean.startsWith('/akun/keamanan')) return 'Keamanan & Sandi';
    if (clean.startsWith('/panduan')) return 'Panduan & FAQ';
    return userProf.tr('nav_dashboard');
  }

  int _mobileTabIndex(String path, bool isKontraktor) {
    final clean = path.split('?').first;
    if (isKontraktor) {
      if (clean.startsWith('/kegiatan')) return 1;
      if (clean.startsWith('/timeline')) return 2;
      if (clean.startsWith('/akun')) return 3;
      return 0;
    } else {
      if (clean.startsWith('/kontrak')) return 1;
      if (clean.startsWith('/laporan')) return 2;
      if (clean.startsWith('/timeline')) return 3;
      if (clean.startsWith('/akun')) return 4;
      return 0;
    }
  }

  Future<void> _handleMobileBack(BuildContext context, String path) async {
    if (context.canPop()) {
      context.pop();
      return;
    }
    if (path != '/dashboard') {
      goBackWithShellHistory(context, fallback: '/dashboard');
      return;
    }
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda berada di halaman utama Dashboard.'),
          duration: Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final exit = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Keluar Aplikasi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (exit == true) {
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProf = context.watch<UserProfileProvider>();
    if (!userProf.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentPath = routerState.uri.path;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      final activeMenu = WebDashboardLayout.menuKeyFromPath(currentPath);
      final isNested = _isNestedRoute(currentPath);
      return WebDashboardLayout(
        title: _headerTitleForPath(currentPath, userProf),
        activeMenu: activeMenu,
        showBackButton: isNested || context.canPop(),
        onBack: () {
          if (context.canPop()) {
            context.pop();
          } else {
            goTopLevelRoute(context, _parentRouteFor(currentPath));
          }
        },
        onMenuSelected: (menuKey) {
          goTopLevelRoute(context, WebDashboardLayout.routeForMenu(menuKey));
        },
        child: child,
      );
    }

    // Mobile layout (< 900px): jaga parent Scaffold + Stack tetap stabil agar
    // Navigator ShellRoute tidak pernah di-reparent saat transisi ke sub-rute.
    final isTopLevelTab = _topLevelMobilePaths.contains(currentPath);

    final isKontraktor = userProf.isKontraktor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final navBorder = isDark ? const Color(0xFF334155) : AppColors.border;
    final selectedColor =
        isDark ? const Color(0xFF38BDF8) : AppColors.navySlate;
    final unselectedColor = isDark ? const Color(0xFF94A3B8) : AppColors.slate;

    final List<String> tabPaths = isKontraktor
        ? ['/dashboard', '/kegiatan', '/timeline', '/akun']
        : ['/dashboard', '/kontrak', '/laporan', '/timeline', '/akun'];

    final List<BottomNavigationBarItem> navItems = isKontraktor
        ? [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: userProf.tr('nav_dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment),
              label: userProf.tr('nav_kegiatan_saya'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.show_chart),
              label: userProf.tr('nav_timeline'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: userProf.tr('nav_akun'),
            ),
          ]
        : [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_filled),
              label: userProf.tr('nav_dashboard'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.folder_outlined),
              activeIcon: const Icon(Icons.folder),
              label: userProf.tr('nav_kontrak'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.description_outlined),
              activeIcon: const Icon(Icons.description),
              label: userProf.tr('nav_laporan'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.show_chart),
              label: userProf.tr('nav_timeline'),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: userProf.tr('nav_akun'),
            ),
          ];

    if (isTopLevelTab) {
      recordShellRouteHistory(currentPath);
    }
    final currentIdx = _mobileTabIndex(currentPath, isKontraktor);

    return Scaffold(
      body: Stack(
        children: [
          child,
          if (isTopLevelTab)
            Positioned.fill(
              child: IgnorePointer(
                child: PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, _) async {
                    if (didPop) return;
                    await _handleMobileBack(context, currentPath);
                  },
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: isTopLevelTab
          ? Container(
              decoration: BoxDecoration(
                color: navBg,
                border: Border(top: BorderSide(color: navBorder, width: 0.8)),
              ),
              child: BottomNavigationBar(
                elevation: 0,
                currentIndex: currentIdx,
                onTap: (index) {
                  if (index < 0 || index >= tabPaths.length) return;
                  goTopLevelRoute(context, tabPaths[index]);
                },
                type: BottomNavigationBarType.fixed,
                backgroundColor: navBg,
                selectedItemColor: selectedColor,
                unselectedItemColor: unselectedColor,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
                items: navItems,
              ),
            )
          : null,
    );
  }
}
