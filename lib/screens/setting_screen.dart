import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/edit_profil_screen.dart';
import 'package:tata_saka_app/screens/keamanan_screen.dart';
import 'package:tata_saka_app/screens/pengaturan_screen.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null && mounted) {
        context.read<UserProfileProvider>().updateProfileImage(pickedFile.path);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui.'),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    final hasPhoto = context.read<UserProfileProvider>().profileImagePath != null;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
                ),
                title: const Text('Ambil Foto Kamera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.photo_library, color: Color(0xFF2563EB)),
                ),
                title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (hasPhoto)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                  ),
                  title: const Text('Hapus Foto Profil', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFDC2626))),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.read<UserProfileProvider>().updateProfileImage(null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Foto profil berhasil dihapus.'),
                        backgroundColor: Color(0xFF059669),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaqDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pusat Bantuan & FAQ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildFaqItem(
                'Bagaimana cara membuat Laporan Harian?',
                'Masuk ke tab Laporan > Buat Laporan Baru > Isi item pekerjaan, material, alat, tenaga kerja, cuaca, dan instruksi pengawas.',
              ),
              _buildFaqItem(
                'Kapan Laporan Mingguan dihitung?',
                'Laporan mingguan secara otomatis menjumlahkan volume dari seluruh laporan harian pada minggu bersangkutan ke ringkasan BoQ.',
              ),
              _buildFaqItem(
                'Bagaimana membuat Addendum CCO?',
                'Buka menu Detail Kegiatan > Kelola Addendum & Tambah Kurang > Buat Addendum Baru.',
              ),
              _buildFaqItem(
                'Kontak Bantuan & Layanan Teknis',
                'Email: support@tatasaka.com\nTelepon/WA: +62 812-3456-7890 (Hari Kerja 08:00 - 17:00 WIB)',
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String q, String a) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text(a, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4)),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari aplikasi Tata Saka Consultant?',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, userProf, _) {
        final profileImage = userProf.profileImagePath;

        return Scaffold(
          backgroundColor: AppColors.getBackground(context),
          appBar: AppBar(
            backgroundColor: AppColors.getCardBackground(context),
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Text(
              userProf.tr('nav_account'),
              style: TextStyle(
                color: AppColors.getTextDark(context),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF2563EB)),
                tooltip: 'Edit Profil',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfilScreen()),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── 1. PROFILE HEADER DENGAN GANTI FOTO ───
                Row(
                  children: [
                    GestureDetector(
                      onTap: _showImageSourceDialog,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                            ),
                            child: ClipOval(
                              child: profileImage != null
                                  ? Image.file(
                                      File(profileImage),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProf.namaLengkap,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextDark(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFDBEAFE)),
                            ),
                            child: Text(
                              userProf.role,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ─── 2. INFORMASI PROFIL CARD ───
                Text(
                  userProf.tr('profil_info'),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextDark(context),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Column(
                    children: [
                      _buildProfileItem(Icons.person_outline, userProf.tr('nama_lengkap'), userProf.namaLengkap),
                      Divider(height: 1, color: AppColors.getBorder(context)),
                      _buildProfileItem(Icons.badge_outlined, userProf.tr('username'), userProf.username),
                      Divider(height: 1, color: AppColors.getBorder(context)),
                      _buildProfileItem(Icons.verified_user_outlined, userProf.tr('role'), userProf.role),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ─── 3. PROYEK TERKAIT ───
                Text(
                  userProf.tr('proyek_terkait'),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextDark(context),
                  ),
                ),
                const SizedBox(height: 12),
                Consumer<ContractProvider>(
                  builder: (context, provider, child) {
                    final contracts = provider.contracts;
                    if (contracts.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.getCardBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.getBorder(context)),
                        ),
                        child: Center(
                          child: Text(
                            'Belum ada proyek atau kontrak aktif.',
                            style: TextStyle(color: AppColors.getTextLight(context), fontSize: 13),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: contracts.map((c) => _buildContractCard(c)).toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // ─── 4. MENU LAINNYA ───
                Text(
                  userProf.tr('menu_lainnya'),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextDark(context),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(context),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        Icons.settings_outlined,
                        userProf.tr('pengaturan'),
                        userProf.tr('pengaturan_sub'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PengaturanScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, color: AppColors.getBorder(context)),
                      _buildMenuItem(
                        Icons.security_outlined,
                        userProf.tr('keamanan'),
                        userProf.tr('keamanan_sub'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const KeamananScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, color: AppColors.getBorder(context)),
                      _buildMenuItem(
                        Icons.help_outline,
                        userProf.tr('pusat_bantuan'),
                        userProf.tr('pusat_bantuan_sub'),
                        onTap: _showFaqDialog,
                      ),
                      Divider(height: 1, color: AppColors.getBorder(context)),
                      _buildMenuItem(
                        Icons.logout_rounded,
                        userProf.tr('logout'),
                        userProf.tr('logout_sub'),
                        iconColor: const Color(0xFFDC2626),
                        titleColor: const Color(0xFFDC2626),
                        onTap: _showLogoutDialog,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContractCard(ContractModel c) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailKontrakScreen(contract: c)),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.getCardBackground(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.folder_shared_outlined,
                color: Color(0xFF2563EB),
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.namaKontrak,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextDark(context),
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${c.kegiatans.length} Kegiatan • ${c.jenisKegiatan}',
                    style: TextStyle(color: AppColors.getTextLight(context), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.getTextLight(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: AppColors.getTextLight(context), size: 20),
          const SizedBox(width: 14),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.getTextDark(context),
              fontSize: 13.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextLight(context),
              fontWeight: FontWeight.w500,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle, {
    Color? iconColor,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor != null) ? const Color(0xFFFEE2E2) : AppColors.getSurfaceLighter(context),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.getTextDark(context), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: titleColor ?? AppColors.getTextDark(context),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.getTextLight(context),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.getTextLight(context), size: 20),
          ],
        ),
      ),
    );
  }
}
