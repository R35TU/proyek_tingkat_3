import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscurePassword = true;
  bool rememberMe = true;
  bool _isLoggingIn = false;

  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    // Jika sudah ada sesi aktif, langsung arahkan ke dashboard yang sesuai
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userProf = context.read<UserProfileProvider>();
      if (!userProf.isInitialized) return;
      final isAuth = userProf.isAuthenticated;
      if (isAuth) {
        final target = userProf.role.toLowerCase() == 'admin'
            ? '/admin'
            : '/dashboard';
        final router = GoRouter.maybeOf(context);
        if (router != null) {
          Router.neglect(context, () => router.go(target));
        }
      }
    });
  }

  void _handleBack(BuildContext context) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/landing');
      }
      return;
    }
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (_isLoggingIn || password.isEmpty) return;

    setState(() => _isLoggingIn = true);

    final userProf = context.read<UserProfileProvider>();
    final success = await userProf.login(
      username,
      password,
    );

    if (!mounted) return;
    setState(() => _isLoggingIn = false);

    if (success) {
      final target = userProf.role.toLowerCase() == 'admin'
          ? '/admin'
          : '/dashboard';
      Router.neglect(context, () => context.go(target));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Username/Email atau password salah. Silakan coba kembali.',
          ),
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
        SizedBox(height: isDesktop ? 4 : 8),
        // Logo
        Center(
          child: Image.asset(
            'assets/images/logoRev.png',
            height: isDesktop ? 92 : 88,
            cacheHeight: 276,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.business,
              size: 76,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 20),

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
          'Silakan masuk ke akun Anda\nuntuk melanjutkan sistem monitoring proyek.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textLight,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 24),

        // Username atau Email Field
        const Text(
          'Username atau Email',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _emailController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: 'Masukkan username atau email',
            prefixIcon: const Icon(
              Icons.person_outline,
              size: 20,
              color: Color(0xFF64748B),
            ),
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
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _performLogin(),
          decoration: InputDecoration(
            hintText: '••••••',
            prefixIcon: const Icon(
              Icons.lock_outline,
              size: 20,
              color: Color(0xFF64748B),
            ),
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
        const SizedBox(height: 22),

        // Login Button
        ElevatedButton(
          onPressed: _isLoggingIn ? null : _performLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            disabledBackgroundColor:
                AppColors.primaryBlue.withValues(alpha: 0.65),
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoggingIn
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Masuk ke Sistem',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
        ),
        SizedBox(height: isDesktop ? 4 : 8),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBack(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: isDesktop ? AppColors.slateLighter : Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.navySlate),
            tooltip: 'Kembali ke Landing Page',
            onPressed: () => _handleBack(context),
          ),
        ),
        // Web: latar abu-abu, Mobile: putih
        backgroundColor: isDesktop ? AppColors.slateLighter : Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 24 : 24,
                  vertical: isDesktop ? 24 : 16,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        (constraints.maxHeight - (isDesktop ? 48 : 32))
                            .clamp(0.0, double.infinity),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isDesktop ? 420 : 440,
                      ),
                      child: isDesktop
                          ? Card(
                              elevation: 4,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: isiLogin,
                              ),
                            )
                          : isiLogin,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
