import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';

import 'admin_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String selectedRole = 'Konsultan';
  final roles = [
    'Konsultan',
    'Kontraktor',
    'Dinas',
  ]; // Eksternal dihapus sesuai instruksi
  bool obscurePassword = true;
  bool rememberMe = true;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(
      text: 'konsultan@tatasakaconsultant.id',
    );
    _passwordController = TextEditingController(text: 'password123');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onRoleChanged(String role) {
    setState(() {
      selectedRole = role;
      if (role == 'Konsultan') {
        _emailController.text = 'konsultan@tatasakaconsultant.id';
      } else if (role == 'Kontraktor') {
        _emailController.text = 'kontraktor1@tatasakaconsultant.id';
      } else if (role == 'Dinas') {
        _emailController.text = 'dinas@tatasakaconsultant.id';
      }
      _passwordController.text = 'password123';
    });
  }

  bool _isLoggingIn = false;

  Future<void> _performLogin() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_isLoggingIn || password.isEmpty) return;

    setState(() => _isLoggingIn = true);

    final userProf = context.read<UserProfileProvider>();
    final success = await userProf.login(
      username,
      password,
      roleHint: selectedRole,
    );

    if (!mounted) return;
    setState(() => _isLoggingIn = false);

    if (success) {
      // Admin (role Admin) masuk ke dashboard manajemen akun.
      if (userProf.role.toLowerCase() == 'admin') {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AdminPage()),
          (route) => false,
        );
        return;
      }
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email atau password salah. Silakan coba kembali.'),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isiLogin = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 36),
        // Logo
        Center(
          child: Image.asset(
            'assets/images/logoRev.png',
            height: 110,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.business,
              size: 80,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Welcome Text
        const Text(
          'Selamat Datang',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Silahkan pilih role & masuk ke akun Anda\nuntuk melanjutkan sistem monitoring proyek.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textLight,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Role Selector Tabs (Konsultan, Kontraktor, Dinas)
        Row(
          children: roles.map((role) {
            final isSelected = selectedRole == role;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () => _onRoleChanged(role),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.navySlate
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.navySlate
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        role,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Sub-chips jika Kontraktor (Pilihan Kontraktor 1 atau Kontraktor 2)
        if (selectedRole == 'Kontraktor') ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Akun Demo Kontraktor Pelaksana:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text(
                          'Kontraktor 1\n(CV. Divan Insan)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11),
                        ),
                        selected:
                            _emailController.text ==
                            'kontraktor1@tatasakaconsultant.id',
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color:
                              _emailController.text ==
                                  'kontraktor1@tatasakaconsultant.id'
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _emailController.text =
                                  'kontraktor1@tatasakaconsultant.id';
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text(
                          'Kontraktor 2\n(CV. Langgeng)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11),
                        ),
                        selected:
                            _emailController.text ==
                            'kontraktor2@tatasakaconsultant.id',
                        selectedColor: const Color(0xFF2563EB),
                        labelStyle: TextStyle(
                          color:
                              _emailController.text ==
                                  'kontraktor2@tatasakaconsultant.id'
                              ? Colors.white
                              : const Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          if (val) {
                            setState(() {
                              _emailController.text =
                                  'kontraktor2@tatasakaconsultant.id';
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),

        // Email Field
        const Text(
          'Email Akun',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'Masukkan email',
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        const Text(
          'Password',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _passwordController,
          obscureText: obscurePassword,
          decoration: InputDecoration(
            hintText: '••••••',
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2563EB)),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textLight,
              ),
              onPressed: () {
                setState(() {
                  obscurePassword = !obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Remember Me
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: rememberMe,
                onChanged: (val) {
                  setState(() {
                    rememberMe = val ?? true;
                  });
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: AppColors.textDark,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Ingat saya',
              style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Login Button
        ElevatedButton(
          onPressed: _performLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Masuk ke Sistem',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );

    return Scaffold(
      // Web: latar abu-abu, Mobile: putih
      backgroundColor: isDesktop ? AppColors.slateLighter : Colors.white,
      body: isDesktop
          // Versi web: card di tengah
          ? Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: isiLogin,
                    ),
                  ),
                ),
              ),
            )
          // Versi HP: tampilan seperti biasa
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: isiLogin,
              ),
            ),
    );
  }
}
