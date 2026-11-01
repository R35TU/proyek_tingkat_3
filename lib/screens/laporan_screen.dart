import 'package:flutter/material.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/buat_laporan_mingguan_screen.dart';

class LaporanScreen extends StatelessWidget {
  const LaporanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () {},
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildMenuCard(
              title: 'Data Laporan',
              description: 'Lihat daftar proyek dan semua data\nlaporan harian & mingguan tersedia',
              icon: Icons.folder_outlined,
              iconBgColor: AppColors.blueLight,
              iconColor: AppColors.primaryBlue,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DataLaporanScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              title: 'Buat Laporan Harian',
              description: 'Buku Harian Standar (pekerjaan, material, alat,\npersonil, cuaca & kejadian)',
              icon: Icons.edit_note,
              iconBgColor: const Color(0xFFE6F4EA),
              iconColor: AppColors.successGreen,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuatLaporanScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              title: 'Buat Laporan Mingguan',
              description: 'Ringkasan Kegiatan Mingguan (bobot rencana,\nrealisasi fisik, deviasi, & tabel mingguan)',
              icon: Icons.analytics_outlined,
              iconBgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuatLaporanMingguanScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 28,
                  ),
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
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textLight,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
