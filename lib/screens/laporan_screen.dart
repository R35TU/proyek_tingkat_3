import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/laporan_mingguan_screen.dart';
import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

class LaporanScreen extends StatelessWidget {
  final bool isEmbedded;
  const LaporanScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final userProf = context.watch<UserProfileProvider>();
    final bool isDinas = userProf.isDinas;

    final Widget mainBody = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          if (!isDinas) ...[
            _buildMenuCard(
              title: 'Buat Laporan Harian',
              description:
                  'Buku Harian Standar (pekerjaan, material, alat,\npersonil, cuaca & kejadian)',
              icon: Icons.edit_note,
              iconBgColor: const Color(0xFFE6F4EA),
              iconColor: AppColors.successGreen,
              onTap: () {
                final router = GoRouter.maybeOf(context);
                if (router != null) {
                  router.go('/laporan/harian');
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BuatLaporanScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildMenuCard(
            title: 'Laporan Harian',
            description:
                'Lihat daftar proyek dan seluruh data\nlaporan harian yang tersimpan',
            icon: Icons.folder_outlined,
            iconBgColor: AppColors.blueLight,
            iconColor: AppColors.primaryBlue,
            onTap: () {
              final router = GoRouter.maybeOf(context);
              if (router != null) {
                router.go('/laporan/data');
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataLaporanScreen(),
                  ),
                );
              }
            },
          ),
          if (!isDinas) ...[
            const SizedBox(height: 16),
            _buildMenuCard(
              title: 'Laporan Mingguan',
              description:
                  'Daftar Periode Mingguan (status berjalan, realisasi\nharian otomatis, bobot BoQ 14 kolom & tanda tangan)',
              icon: Icons.analytics_outlined,
              iconBgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              onTap: () {
                final router = GoRouter.maybeOf(context);
                if (router != null) {
                  router.go('/laporan/mingguan');
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LaporanMingguanScreen(),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              title: 'Laporan Bulanan',
              description:
                  'Rekapitulasi Fisik Bulanan (Otomatis per 4 minggu,\nkemajuan fisik CCO, bulan lalu, bulan ini & sisa)',
              icon: Icons.calendar_month_outlined,
              iconBgColor: const Color(0xFFEDE9FE),
              iconColor: const Color(0xFF7C3AED),
              onTap: () {
                final router = GoRouter.maybeOf(context);
                if (router != null) {
                  router.go('/laporan/bulanan');
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LaporanBulananScreen(),
                    ),
                  );
                }
              },
            ),
          ] else ...[
            const SizedBox(height: 16),
            _buildInfoCardDinas(),
          ],
        ],
      ),
    );

    if (isEmbedded) {
      return mainBody;
    }

    if (isDesktop) {
      return WebDashboardLayout(
        title: 'Laporan Proyek',
        activeMenu: 'laporan',
        showBackButton: false,
        child: mainBody,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => goBackWithShellHistory(context),
        ),
        title: const Text(
          'Laporan Proyek',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: mainBody,
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textLight),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

  /// Kartu info untuk role Dinas: akses terbatas pada pembacaan laporan.
  Widget _buildInfoCardDinas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueLight),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Role Dinas bersifat pemantau: Anda dapat melihat semua laporan '
              '(harian, mingguan, bulanan) melalui menu Laporan Harian.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
            ),
          ),
        ],
      ),
    );
  }
