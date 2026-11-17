import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tata_saka_app/services/auth_service.dart';

import 'login_screen.dart';

/// Akun pengguna tersimpan di Firestore collection `users` (doc id = uid Auth).
/// Password TIDAK tersimpan di Firestore — dikelola Firebase Auth.
class UserAccount {
  final String id; // uid Firebase Auth
  String name;
  String email;
  String role; // 'Konsultan', 'Kontraktor', 'Dinas', 'Admin'
  String instansi; // Nama CV/PT/Dinas
  bool isActive;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.instansi,
    this.isActive = true,
  });

  factory UserAccount.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return UserAccount(
      id: doc.id,
      name: (d['namaLengkap'] ?? d['username'] ?? '-').toString(),
      email: (d['email'] ?? '-').toString(),
      role: (d['role'] ?? 'Konsultan').toString(),
      instansi: (d['companyOrAgency'] ?? '-').toString(),
      isActive: d['isActive'] ?? true,
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String _selectedRoleFilter = 'Semua';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  // Daftar akun langsung dari Firestore `users` (real-time).
  final List<UserAccount> _accounts = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSub;
  bool _loadingAccounts = true;

  @override
  void initState() {
    super.initState();
    try {
      _usersSub = FirebaseFirestore.instance
          .collection('users')
          .orderBy('createdAt')
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        setState(() {
          _accounts
            ..clear()
            ..addAll(snap.docs.map(UserAccount.fromDoc));
          _loadingAccounts = false;
        });
      }, onError: (_) {
        if (mounted) setState(() => _loadingAccounts = false);
      });
    } catch (_) {
      // Firestore tidak tersedia (mis. lingkungan test) → daftar kosong.
      _loadingAccounts = false;
    }
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<UserAccount> get _filteredAccounts {
    return _accounts.where((acc) {
      final matchesRole =
          _selectedRoleFilter == 'Semua' || acc.role == _selectedRoleFilter;
      final matchesSearch =
          acc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          acc.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          acc.instansi.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesRole && matchesSearch;
    }).toList();
  }

  int _countByRole(String role) =>
      _accounts.where((acc) => acc.role == role).length;

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Konsultan':
        return const Color(0xFF2563EB); // Biru
      case 'Kontraktor':
        return const Color(0xFFD97706); // Oranye/Amber
      case 'Dinas':
        return const Color(0xFF059669); // Hijau
      default:
        return Colors.grey;
    }
  }

  void _showAccountFormDialog({UserAccount? existingAccount}) {
    final isEdit = existingAccount != null;
    final nameCtrl = TextEditingController(text: existingAccount?.name ?? '');
    final emailCtrl = TextEditingController(text: existingAccount?.email ?? '');
    final passCtrl = TextEditingController();
    final instansiCtrl = TextEditingController(
      text: existingAccount?.instansi ?? '',
    );
    String selectedRole = existingAccount?.role ?? 'Konsultan';
    bool isActive = existingAccount?.isActive ?? true;
    bool isSaving = false;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                isEdit ? 'Edit Akun Pengguna' : 'Tambah Akun Baru',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: MediaQuery.sizeOf(context).width < 500
                    ? MediaQuery.sizeOf(context).width - 64
                    : 450,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role / Peran Akun',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          items: ['Konsultan', 'Kontraktor', 'Dinas']
                              .map(
                                (role) => DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => selectedRole = val);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap & Gelar',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Nama wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: instansiCtrl,
                          decoration: const InputDecoration(
                            labelText:
                                'Nama Instansi / Perusahaan (CV/PT/Dinas)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business_outlined),
                          ),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Instansi wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Email Login',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (v) => v == null || !v.contains('@')
                              ? 'Masukkan email yang valid'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        if (isEdit)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 4),
                            child: Text(
                              'Password diubah oleh pengguna sendiri lewat menu Keamanan.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          )
                        else
                          TextFormField(
                            controller: passCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (v) => v == null || v.length < 6
                                ? 'Password minimal 6 karakter (ketentuan Firebase)'
                                : null,
                          ),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Status Akun Aktif'),
                          subtitle: Text(
                            isActive
                                ? 'Pengguna dapat login ke aplikasi'
                                : 'Akses login ditangguhkan',
                            style: const TextStyle(fontSize: 12),
                          ),
                          value: isActive,
                          onChanged: (val) {
                            setDialogState(() => isActive = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => isSaving = true);
                          try {
                            if (isEdit) {
                              await AuthService.updateUserDoc(
                                existingAccount.id,
                                {
                                  'namaLengkap': nameCtrl.text.trim(),
                                  'role': selectedRole,
                                  'companyOrAgency': instansiCtrl.text.trim(),
                                  'isActive': isActive,
                                },
                              );
                            } else {
                              await AuthService.createAccount(
                                email: emailCtrl.text,
                                password: passCtrl.text.trim(),
                                role: selectedRole,
                                namaLengkap: nameCtrl.text,
                                instansi: instansiCtrl.text,
                                isActive: isActive,
                              );
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Akun berhasil diperbarui'
                                      : 'Akun baru berhasil ditambahkan ke Firebase',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (ctx.mounted) {
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e is FirebaseAuthException &&
                                            e.code == 'email-already-in-use'
                                        ? 'Email sudah dipakai akun lain.'
                                        : 'Gagal menyimpan: $e',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: Text(isEdit ? 'Simpan Perubahan' : 'Buat Akun'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(UserAccount account) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus akun "${account.name}" (${account.role})?\n\n'
          'Pengguna tidak akan bisa login lagi ke aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService.deleteUserDoc(account.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Akun berhasil dihapus')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menghapus: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 8),
            Text('Konfirmasi Keluar'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await AuthService.signOut();
              } catch (_) {}
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.sizeOf(context).width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(
              Icons.admin_panel_settings,
              size: 26,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Admin',
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                if (!isCompact)
                  const Text(
                    'Manajemen akun',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal: isCompact ? 8 : 16,
            ),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: isCompact
                  ? const SizedBox.shrink()
                  : const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;
          final horizontalPadding = isCompact ? 12.0 : 20.0;

          return Center(
            child: SizedBox(
              width: constraints.maxWidth > 1400 ? 1400 : constraints.maxWidth,
              child: Padding(
                padding: EdgeInsets.all(horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, statsConstraints) {
                        final columns = statsConstraints.maxWidth >= 1000
                            ? 4
                            : 2;
                        final spacing = isCompact ? 12.0 : 16.0;
                        final cardWidth =
                            (statsConstraints.maxWidth -
                                spacing * (columns - 1)) /
                            columns;

                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            _buildStatCard(
                              'Total Akun',
                              _accounts.length.toString(),
                              Icons.people,
                              const Color(0xFF1E3A8A),
                              width: cardWidth,
                              compact: isCompact,
                            ),
                            _buildStatCard(
                              'Konsultan',
                              _countByRole('Konsultan').toString(),
                              Icons.engineering,
                              const Color(0xFF2563EB),
                              width: cardWidth,
                              compact: isCompact,
                            ),
                            _buildStatCard(
                              'Kontraktor',
                              _countByRole('Kontraktor').toString(),
                              Icons.construction,
                              const Color(0xFFD97706),
                              width: cardWidth,
                              compact: isCompact,
                            ),
                            _buildStatCard(
                              'Dinas',
                              _countByRole('Dinas').toString(),
                              Icons.account_balance,
                              const Color(0xFF059669),
                              width: cardWidth,
                              compact: isCompact,
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: isCompact ? 16 : 24),
                    if (isCompact)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchField(),
                          const SizedBox(height: 10),
                          _buildAddAccountButton(compact: true),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(child: _buildSearchField()),
                          const SizedBox(width: 12),
                          _buildAddAccountButton(),
                        ],
                      ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Semua', 'Konsultan', 'Kontraktor', 'Dinas']
                            .map((role) {
                              final isSelected = _selectedRoleFilter == role;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(role),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF1E3A8A),
                                  checkmarkColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  onSelected: (_) {
                                    setState(() => _selectedRoleFilter = role);
                                  },
                                ),
                              );
                            })
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: _loadingAccounts
                          ? const Center(child: CircularProgressIndicator())
                          : _filteredAccounts.isEmpty
                          ? const Center(
                              child: Text(
                                'Tidak ada akun yang ditemukan.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredAccounts.length,
                              itemBuilder: (context, index) =>
                                  _buildAccountCard(
                                    _filteredAccounts[index],
                                    compact: isCompact,
                                  ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => setState(() => _searchQuery = val),
      decoration: InputDecoration(
        hintText: 'Cari nama, email, atau instansi...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildAddAccountButton({bool compact = false}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: 16,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: () => _showAccountFormDialog(),
      icon: const Icon(Icons.person_add),
      label: const Text('Tambah Akun'),
    );
  }

  Widget _buildAccountCard(UserAccount acc, {required bool compact}) {
    final roleColor = _getRoleColor(acc.role);
    final avatar = CircleAvatar(
      backgroundColor: roleColor.withOpacity(0.15),
      child: Text(
        acc.name.isNotEmpty ? acc.name[0].toUpperCase() : '?',
        style: TextStyle(color: roleColor, fontWeight: FontWeight.bold),
      ),
    );
    final badges = Wrap(
      spacing: 6,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _buildAccountBadge(acc.role, roleColor),
        if (!acc.isActive) _buildAccountBadge('Nonaktif', Colors.red),
      ],
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(acc.instansi, maxLines: 2, overflow: TextOverflow.ellipsis),
        Text(acc.email, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Edit Akun',
          icon: const Icon(Icons.edit_outlined, color: Colors.blue),
          onPressed: () => _showAccountFormDialog(existingAccount: acc),
        ),
        IconButton(
          tooltip: 'Hapus Akun',
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _confirmDelete(acc),
        ),
      ],
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: compact
          ? Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      avatar,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              acc.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            badges,
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: details,
                  ),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              ),
            )
          : ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: avatar,
              title: Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    acc.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  badges,
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: details,
              ),
              trailing: actions,
            ),
    );
  }

  Widget _buildAccountBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color, {
    required double width,
    required bool compact,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
