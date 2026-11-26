import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class EditProfilScreen extends StatefulWidget {
  final bool isEmbedded;
  const EditProfilScreen({super.key, this.isEmbedded = false});

  @override
  State<EditProfilScreen> createState() => _EditProfilScreenState();
}

class _EditProfilScreenState extends State<EditProfilScreen> {
  late TextEditingController _namaLengkapController;
  late TextEditingController _usernameController;
  late TextEditingController _roleController;
  String? _temporaryImagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final profile = context.read<UserProfileProvider>();
    _namaLengkapController = TextEditingController(text: profile.namaLengkap);
    _usernameController = TextEditingController(text: profile.username);
    _roleController = TextEditingController(text: profile.role);
    _temporaryImagePath = profile.profileImagePath;
  }

  @override
  void dispose() {
    _namaLengkapController.dispose();
    _usernameController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _temporaryImagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat memilih gambar: $e'),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
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
              if (_temporaryImagePath != null)
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
                    setState(() {
                      _temporaryImagePath = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProfile() {
    final newName = _namaLengkapController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama Lengkap tidak boleh kosong.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    final provider = context.read<UserProfileProvider>();
    provider.updateNamaLengkap(newName);
    provider.updateProfileImage(_temporaryImagePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Profil berhasil diperbarui.'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      goBackOrParent(context, '/akun');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () => goBackOrParent(context, '/akun'),
        ),
        title: const Text(
          'Edit Profil',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.save_rounded,
              color: Color(0xFF2563EB),
              size: 26,
            ),
            tooltip: 'Simpan Profil',
            onPressed: _saveProfile,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),

            // ─── 1. AVATAR PROFILE DENGAN BADGE KAMERA ───
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                          ),
                          child: ClipOval(
                            child: _temporaryImagePath != null
                                ? Image.file(
                                    File(_temporaryImagePath!),
                                    width: 110,
                                    height: 110,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.person,
                                      size: 65,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 65,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Column(
                      children: const [
                        Text(
                          'Tap untuk ganti foto',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF475569),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Format JPG/PNG. Maks. 2MB',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),

            // ─── 2. INFORMASI PROFIL ───
            const Text(
              'Informasi Profil',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 18),

            // Field Nama Lengkap (Editable)
            const Text(
              'Nama Lengkap',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _namaLengkapController,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Field Username (Read-Only)
            const Text(
              'Username',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _usernameController,
              enabled: false,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Field Role (Read-Only)
            const Text(
              'Role',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _roleController,
              enabled: false,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
