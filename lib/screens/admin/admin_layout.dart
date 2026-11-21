import 'package:flutter/material.dart';
import 'package:tata_saka_app/screens/admin/admin_login_screen.dart';
import 'package:tata_saka_app/screens/admin/user_management_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedIndex = 0;
  final List<int> _adminHistory = [0];

  void _onNavSelected(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _adminHistory.add(index);
      _selectedIndex = index;
    });
  }

  // Daftar halaman konten
  final List<Widget> _pages = [
    const UserManagementPage(),
    const Center(child: Text('Halaman Proyek (Coming Soon)')),
    const Center(child: Text('Halaman Pengaturan (Coming Soon)')),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
          return;
        }
        if (_adminHistory.length > 1) {
          setState(() {
            _adminHistory.removeLast();
            _selectedIndex = _adminHistory.last;
          });
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Row(
        children: [
          // SIDEBAR NAVIGATION
          Container(
            width: 250,
            color: Colors.white,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: Color(0xFF1E293B),
                        size: 32,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Web Admin',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _buildNavItem(
                  icon: Icons.people,
                  title: 'Manajemen Akun',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.folder,
                  title: 'Data Proyek',
                  index: 1,
                ),
                _buildNavItem(
                  icon: Icons.settings,
                  title: 'Pengaturan',
                  index: 2,
                ),
                const Spacer(),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Keluar',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    // Route kembali ke halaman login admin yang benar
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminLoginScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Color(0xFFE2E8F0),
          ),
          // AREA KONTEN UTAMA
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF1F5F9) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF0F172A)
                : const Color(0xFF64748B),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () => _onNavSelected(index),
      ),
    );
  }
}
