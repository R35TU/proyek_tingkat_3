import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';

class KeamananScreen extends StatefulWidget {
  final bool isEmbedded;
  const KeamananScreen({super.key, this.isEmbedded = false});

  @override
  State<KeamananScreen> createState() => _KeamananScreenState();
}

class _KeamananScreenState extends State<KeamananScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // Syarat Password Validators
  bool get _hasMin8 => _newPasswordController.text.length >= 8;
  bool get _hasUpperLower =>
      _newPasswordController.text.contains(RegExp(r'[A-Z]')) &&
      _newPasswordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSymbol =>
      _newPasswordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

  bool get _allRequirementsMet =>
      _hasMin8 && _hasUpperLower && _hasNumber && _hasSymbol;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChangePassword() async {
    final currentPass = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (currentPass.isEmpty) {
      _showErrorSnackBar('Masukkan password saat ini.');
      return;
    }

    final provider = context.read<UserProfileProvider>();
    if (!provider.verifyCurrentPassword(currentPass)) {
      _showErrorSnackBar('Password saat ini salah. Silakan periksa kembali.');
      return;
    }

    if (!_allRequirementsMet) {
      _showErrorSnackBar('Password baru belum memenuhi semua kriteria keamanan.');
      return;
    }

    if (newPass != confirmPass) {
      _showErrorSnackBar('Konfirmasi password tidak cocok dengan password baru.');
      return;
    }

    if (newPass == currentPass) {
      _showErrorSnackBar('Password baru tidak boleh sama dengan password saat ini.');
      return;
    }

    final success = await provider.changePassword(currentPass, newPass);
    if (!mounted) return;
    if (success) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Password berhasil diperbarui.')),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAllActivitiesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<UserProfileProvider>(
          builder: (context, userProf, _) {
            final activities = userProf.loginActivities;
            return SafeArea(
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
                          'Semua Aktivitas Login',
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
                    ...activities.map((act) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(act.icon, color: const Color(0xFF475569), size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          act.deviceName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                        ),
                                        if (act.isCurrent) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Aktif Sekarang',
                                              style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${act.location} • ${act.time}',
                                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                                    ),
                                  ],
                                ),
                              ),
                              if (!act.isCurrent)
                                IconButton(
                                  icon: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 18),
                                  tooltip: 'Keluarkan sesi ini',
                                  onPressed: () {
                                    userProf.removeLoginActivity(act.id);
                                  },
                                ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLogoutAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar Dari Semua Perangkat'),
        content: const Text(
          'Apakah Anda yakin ingin mengeluarkan sesi dari seluruh perangkat lain? Anda akan tetap login di perangkat ini, namun perangkat lain harus login ulang.',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<UserProfileProvider>().logoutFromAllOtherDevices();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      SizedBox(width: 10),
                      Expanded(child: Text('Berhasil keluar dari seluruh perangkat lain.')),
                    ],
                  ),
                  backgroundColor: const Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            child: const Text('Keluar Semua'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
            }
          },
        ),
        title: const Text(
          'Keamanan',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, userProf, child) {
          final activities = userProf.loginActivities;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ─── 1. UBAH PASSWORD CARD ───
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Ubah Password',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Password Saat Ini
                    const Text(
                      'Password Saat ini',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      decoration: InputDecoration(
                        hintText: 'Masukkan password saat ini',
                        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                      ),
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),

                    // Password Baru
                    const Text(
                      'Password Baru',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Masukkan password baru',
                        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                      ),
                    ),
                    const Divider(height: 24, color: Color(0xFFF1F5F9)),

                    // Konfirmasi Password Baru
                    const Text(
                      'Konfirmasi Password Baru',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Masukkan kembali password baru',
                        hintStyle: const TextStyle(fontSize: 13.5, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: const Color(0xFF64748B),
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // ─── 2. SYARAT PASSWORD CARD ───
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Syarat Password',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRequirementItem('Minimal 8 Karakter', _hasMin8),
                    const SizedBox(height: 8),
                    _buildRequirementItem('Mengandung huruf besar dan kecil', _hasUpperLower),
                    const SizedBox(height: 8),
                    _buildRequirementItem('Mengandung angka', _hasNumber),
                    const SizedBox(height: 8),
                    _buildRequirementItem('Mengandung simbol', _hasSymbol),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── 3. TOMBOL SIMPAN PASSWORD ───
              ElevatedButton(
                onPressed: _submitChangePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1D4ED8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text(
                  'Simpan Password',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ─── 4. AKTIVITAS LOGIN TERAKHIR ───
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  'Aktivitas Login Terakhir',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    if (activities.isNotEmpty) ...[
                      _buildActivityItem(activities[0]),
                      if (activities.length > 1) ...[
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        _buildActivityItem(activities[1]),
                      ],
                    ],
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    InkWell(
                      onTap: () => _showAllActivitiesSheet(context),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        alignment: Alignment.center,
                        child: const Text(
                          'Lihat Semua Aktivitas',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── 5. KELUAR DARI SEMUA PERANGKAT BUTTON ───
              OutlinedButton.icon(
                onPressed: () => _showLogoutAllDialog(context),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFEA580C),
                  side: const BorderSide(color: Color(0xFFF97316), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFEA580C)),
                label: const Text(
                  'Keluar Dari Semua Perangkat',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
              const SizedBox(height: 36),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isMet ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
          ),
          child: Icon(
            Icons.check,
            size: 13,
            color: isMet ? Colors.white : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            color: isMet ? const Color(0xFF1E293B) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(LoginActivityItem act) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(act.icon, color: const Color(0xFF475569), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  act.deviceName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  act.location,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 1),
                Text(
                  act.time,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
