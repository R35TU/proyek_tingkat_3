import 'package:flutter/material.dart';

import 'login_screen.dart';

// Sesuaikan import provider/model dan login_screen dengan nama project di pubspec.yaml kamu
// import '../providers/auth_provider.dart';
// import 'login_screen.dart';

class UserAccount {
  final String id;
  String name;
  String email;
  String password;
  String role; // 'Konsultan', 'Kontraktor', 'Dinas'
  String instansi; // Nama CV/PT/Dinas
  bool isActive;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    required this.instansi,
    this.isActive = true,
  });
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

  // Data dummy sementara (nanti bisa dipindahkan ke Provider / Firebase / API)
  final List<UserAccount> _accounts = [
    UserAccount(
      id: '1',
      name: 'Budi Santoso, S.T.',
      email: 'konsultan@tatasaka.id',
      password: '123',
      role: 'Konsultan',
      instansi: 'CV. Tata Saka Consultant',
    ),
    UserAccount(
      id: '2',
      name: 'Andi Wijaya',
      email: 'kontraktor@karyamandiri.id',
      password: '123',
      role: 'Kontraktor',
      instansi: 'PT. Karya Mandiri Konstruksi',
    ),
    UserAccount(
      id: '3',
      name: 'Ir. Siti Aminah',
      email: 'dinas@pupr.go.id',
      password: '123',
      role: 'Dinas',
      instansi: 'Dinas Pekerjaan Umum (PUPR)',
    ),
  ];

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
    final passCtrl = TextEditingController(
      text: existingAccount?.password ?? '',
    );
    final instansiCtrl = TextEditingController(
      text: existingAccount?.instansi ?? '',
    );
    String selectedRole = existingAccount?.role ?? 'Konsultan';
    bool isActive = existingAccount?.isActive ?? true;
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
                width: 450,
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
                        TextFormField(
                          controller: passCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (v) => v == null || v.length < 3
                              ? 'Password minimal 3 karakter'
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
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        if (isEdit) {
                          existingAccount.name = nameCtrl.text.trim();
                          existingAccount.email = emailCtrl.text.trim();
                          existingAccount.password = passCtrl.text.trim();
                          existingAccount.role = selectedRole;
                          existingAccount.instansi = instansiCtrl.text.trim();
                          existingAccount.isActive = isActive;
                        } else {
                          _accounts.add(
                            UserAccount(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: nameCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text.trim(),
                              role: selectedRole,
                              instansi: instansiCtrl.text.trim(),
                              isActive: isActive,
                            ),
                          );
                        }
                      });
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isEdit
                                ? 'Akun berhasil diperbarui'
                                : 'Akun baru berhasil ditambahkan',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
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
          'Apakah Anda yakin ingin menghapus akun "${account.name}" (${account.role})?',
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
            onPressed: () {
              setState(() {
                _accounts.removeWhere((item) => item.id == account.id);
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Akun berhasil dihapus')),
              );
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
            onPressed: () {
              Navigator.pop(ctx);
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
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 26),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard Admin',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Manajemen Akun Konsultan, Kontraktor & Dinas',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: _confirmLogout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kartu Ringkasan Jumlah Akun
            LayoutBuilder(
              builder: (context, constraints) {
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      'Total Akun',
                      _accounts.length.toString(),
                      Icons.people,
                      const Color(0xFF1E3A8A),
                    ),
                    _buildStatCard(
                      'Konsultan',
                      _countByRole('Konsultan').toString(),
                      Icons.engineering,
                      const Color(0xFF2563EB),
                    ),
                    _buildStatCard(
                      'Kontraktor',
                      _countByRole('Kontraktor').toString(),
                      Icons.construction,
                      const Color(0xFFD97706),
                    ),
                    _buildStatCard(
                      'Dinas',
                      _countByRole('Dinas').toString(),
                      Icons.account_balance,
                      const Color(0xFF059669),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Bar Pencarian, Filter & Tombol Tambah
            Row(
              children: [
                Expanded(
                  child: TextField(
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
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _showAccountFormDialog(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Tambah Akun'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Filter Role
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Konsultan', 'Kontraktor', 'Dinas'].map((
                  role,
                ) {
                  final isSelected = _selectedRoleFilter == role;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(role),
                      selected: isSelected,
                      selectedColor: const Color(0xFF1E3A8A),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) {
                        setState(() => _selectedRoleFilter = role);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Daftar Akun
            Expanded(
              child: _filteredAccounts.isEmpty
                  ? const Center(
                      child: Text(
                        'Tidak ada akun yang ditemukan.',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredAccounts.length,
                      itemBuilder: (context, index) {
                        final acc = _filteredAccounts[index];
                        final roleColor = _getRoleColor(acc.role);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: roleColor.withOpacity(0.15),
                              child: Text(
                                acc.name.isNotEmpty
                                    ? acc.name[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    acc.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: roleColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    acc.role,
                                    style: TextStyle(
                                      color: roleColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (!acc.isActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Nonaktif',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${acc.instansi} • ${acc.email}'),
                                  Text(
                                    'Password: ${acc.password}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Edit Akun',
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () => _showAccountFormDialog(
                                    existingAccount: acc,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Hapus Akun',
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _confirmDelete(acc),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
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
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
