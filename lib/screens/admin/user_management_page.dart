import 'package:flutter/material.dart';

class UserAccount {
  String id;
  String name;
  String username;
  String role;

  UserAccount({
    required this.id,
    required this.name,
    required this.username,
    required this.role,
  });
}

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  // Dummy Data
  List<UserAccount> users = [
    UserAccount(
      id: '1',
      name: 'CV. Tata Saka',
      username: 'konsultan1',
      role: 'Konsultan',
    ),
    UserAccount(
      id: '2',
      name: 'Dinas PUPR',
      username: 'dinas_pupr',
      role: 'Dinas',
    ),
    UserAccount(
      id: '3',
      name: 'Budi Kontraktor',
      username: 'budi_kontrak',
      role: 'Kontraktor',
    ),
  ];

  void _showFormDialog({UserAccount? user}) {
    final isEdit = user != null;
    final nameCtrl = TextEditingController(text: user?.name ?? '');
    final userCtrl = TextEditingController(text: user?.username ?? '');
    String selectedRole = user?.role ?? 'Konsultan';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Akun' : 'Tambah Akun Baru'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: userCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Konsultan', 'Kontraktor', 'Dinas', 'Eksternal']
                      .map(
                        (role) =>
                            DropdownMenuItem(value: role, child: Text(role)),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) selectedRole = val;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  if (isEdit) {
                    user.name = nameCtrl.text;
                    user.username = userCtrl.text;
                    user.role = selectedRole;
                  } else {
                    users.add(
                      UserAccount(
                        id: DateTime.now().toString(),
                        name: nameCtrl.text,
                        username: userCtrl.text,
                        role: selectedRole,
                      ),
                    );
                  }
                });
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteUser(UserAccount user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Akun?'),
        content: Text('Apakah Anda yakin ingin menghapus akun ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              setState(() {
                users.removeWhere((element) => element.id == user.id);
              });
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Halaman
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manajemen Akun User',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kelola hak akses dan akun pengguna aplikasi.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Tambah Akun'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Tabel Data Akun
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
              color: Colors.white,
              elevation: 0,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DataTable(
                    // Menggunakan WidgetStateProperty agar kompatibel dengan versi Flutter terbaru
                    headingRowColor: WidgetStateProperty.all(
                      const Color(0xFFF8FAFC),
                    ),
                    columns: const [
                      DataColumn(
                        label: Text(
                          'Nama Lengkap',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Username',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Role',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Aksi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    rows: users.map((user) {
                      return DataRow(
                        cells: [
                          DataCell(Text(user.name)),
                          DataCell(Text(user.username)),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                user.role,
                                style: const TextStyle(
                                  color: Color(0xFF0369A1),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                  tooltip: 'Edit',
                                  onPressed: () => _showFormDialog(user: user),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  tooltip: 'Hapus',
                                  onPressed: () => _deleteUser(user),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
