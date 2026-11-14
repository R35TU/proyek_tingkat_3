import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/kontrak_screen.dart';
import 'package:tata_saka_app/screens/laporan_screen.dart';
import 'package:tata_saka_app/screens/setting_screen.dart';
import 'package:tata_saka_app/screens/timeline_screen.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProf = context.watch<UserProfileProvider>();
    final isKontraktor = userProf.isKontraktor;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final navBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final navBorder = isDark ? const Color(0xFF334155) : AppColors.border;
    final selectedColor = isDark ? const Color(0xFF38BDF8) : AppColors.navySlate;
    final unselectedColor = isDark ? const Color(0xFF94A3B8) : AppColors.slate;

    final lblDashboard = userProf.tr('nav_dashboard');
    final lblKontrak = userProf.tr('nav_kontrak');
    final lblKegiatanSaya = userProf.tr('nav_kegiatan_saya');
    final lblLaporan = userProf.tr('nav_laporan');
    final lblTimeline = userProf.tr('nav_timeline');
    final lblAkun = userProf.tr('nav_akun');

    // Layar & item navbar disesuaikan secara dinamis berdasarkan Role
    final List<Widget> screens;
    final List<BottomNavigationBarItem> navItems;

    if (isKontraktor) {
      // Role Kontraktor: 4 Tab (Tab Laporan DITUTUP TOTAL sesuai Opsi A)
      screens = [
        const DashboardScreen(),
        const KontrakScreen(), // Beroperasi dalam mode 'Kegiatan Saya'
        const TimelineScreen(),
        const SettingScreen(),
      ];
      navItems = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_filled),
          label: lblDashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.assignment_outlined),
          activeIcon: const Icon(Icons.assignment),
          label: lblKegiatanSaya,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.show_chart),
          label: lblTimeline,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: lblAkun,
        ),
      ];
    } else {
      // Role Konsultan & Dinas: 5 Tab
      screens = [
        const DashboardScreen(),
        const KontrakScreen(),
        const LaporanScreen(),
        const TimelineScreen(),
        const SettingScreen(),
      ];
      navItems = [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home_filled),
          label: lblDashboard,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.folder_outlined),
          activeIcon: const Icon(Icons.folder),
          label: lblKontrak,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.description_outlined),
          activeIcon: const Icon(Icons.description),
          label: lblLaporan,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.show_chart),
          label: lblTimeline,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.person_outline),
          activeIcon: const Icon(Icons.person),
          label: lblAkun,
        ),
      ];
    }

    if (_currentIndex >= screens.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: navBg,
          border: Border(
            top: BorderSide(color: navBorder, width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: navBg,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: navItems,
        ),
      ),
    );
  }
}
