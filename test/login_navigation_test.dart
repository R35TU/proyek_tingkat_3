import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/screens/admin_page.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/login_screen.dart';
import 'package:tata_saka_app/screens/splash_screen.dart';
import 'package:tata_saka_app/services/auth_service.dart';

class _TestAuthProfileProvider extends UserProfileProvider {
  _TestAuthProfileProvider(this._roleToAssign);

  final String _roleToAssign;
  String? capturedRoleHint = 'initial-sentinel';
  String? capturedUsername;

  @override
  Future<bool> login(
    String input,
    String passwordInput, {
    String? roleHint,
  }) async {
    capturedUsername = input;
    capturedRoleHint = roleHint;
    if (input.isEmpty || passwordInput.isEmpty) return false;
    loginAs(
      RegisteredUser(
        username: input,
        password: passwordInput,
        role: _roleToAssign,
        namaLengkap: 'Akun $_roleToAssign',
        companyOrAgency: _roleToAssign == 'Konsultan'
            ? 'CV. Tata Saka Consultant'
            : 'Instansi Uji',
      ),
    );
    return true;
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('LoginScreen renders back button and does not throw user away', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProfileProvider()),
          ChangeNotifierProvider(create: (_) => ContractProvider()),
          ChangeNotifierProvider(create: (_) => TimelineProvider()),
        ],
        child: MaterialApp(
          initialRoute: '/login',
          routes: {
            '/': (context) => const SplashScreen(),
            '/login': (context) => const LoginScreen(),
          },
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Masuk ke Sistem'), findsOneWidget);
    expect(find.byTooltip('Kembali ke Landing Page'), findsOneWidget);
  });

  testWidgets('LoginScreen removes role selector and remains responsive on web & mobile', (tester) async {
    for (final viewport in [const Size(1440, 900), const Size(390, 844)]) {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => ContractProvider()),
            ChangeNotifierProvider(create: (_) => TimelineProvider()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text('Selamat Datang'), findsOneWidget);
      expect(find.text('Username atau Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Masuk ke Sistem'), findsOneWidget);

      // Pilihan role manual sudah dihapus
      expect(find.text('Konsultan'), findsNothing);
      expect(find.text('Kontraktor'), findsNothing);
      expect(find.text('Dinas'), findsNothing);
      expect(find.textContaining('pilih role'), findsNothing);

      // Form tetap dapat diisi
      await tester.enterText(find.byType(TextFormField).first, 'konsultan1');
      await tester.enterText(find.byType(TextFormField).last, 'rahasia123');
      expect(find.text('konsultan1'), findsOneWidget);
      expect(find.text('rahasia123'), findsOneWidget);
      expect(tester.takeException(), isNull);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    }
  });

  testWidgets('Submitting LoginScreen without role selector redirects Konsultan to /dashboard and Admin to /admin', (tester) async {
    for (final entry in [
      ('konsultan1', 'Konsultan', '/dashboard', DashboardScreen),
      ('admin1', 'Admin', '/admin', AdminPage),
    ]) {
      SharedPreferences.setMockInitialValues({});
      final userProf = _TestAuthProfileProvider(entry.$2);
      final router = createAppRouter(userProf, initialLocation: '/login');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
            ChangeNotifierProvider(create: (_) => ContractProvider()),
            ChangeNotifierProvider(create: (_) => TimelineProvider()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, entry.$1);
      await tester.enterText(find.byType(TextFormField).last, 'password123');
      await tester.ensureVisible(find.text('Masuk ke Sistem'));
      await tester.tap(find.text('Masuk ke Sistem'));
      await tester.pumpAndSettle();

      expect(userProf.capturedUsername, entry.$1);
      expect(userProf.capturedRoleHint, isNull);
      expect(router.routeInformationProvider.value.uri.path, entry.$3);
      expect(find.byType(entry.$4), findsOneWidget);

      router.dispose();
    }
  });
}
