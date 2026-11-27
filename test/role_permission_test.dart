import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/screens/admin_page.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/kelola_addendum_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/screens/login_screen.dart';
import 'package:tata_saka_app/screens/main_layout.dart';
import 'package:tata_saka_app/utils/contract_access.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const konsultanUser = RegisteredUser(
    username: 'konsultan',
    password: 'password123',
    role: 'Konsultan',
    namaLengkap: 'CV. Tata Saka Consultant',
    companyOrAgency: 'CV. Tata Saka Consultant',
  );

  const kontraktor1User = RegisteredUser(
    username: 'kontraktor1',
    password: 'password123',
    role: 'Kontraktor',
    namaLengkap: 'CV. Divan Insan Cemerlang',
    companyOrAgency: 'CV. Divan Insan Cemerlang',
  );

  const kontraktor2User = RegisteredUser(
    username: 'kontraktor2',
    password: 'password123',
    role: 'Kontraktor',
    namaLengkap: 'CV. Langgeng',
    companyOrAgency: 'CV. Langgeng',
  );

  const dinasUser = RegisteredUser(
    username: 'dinas',
    password: 'password123',
    role: 'Dinas',
    namaLengkap: 'DPU-PR Kabupaten Purbalingga',
    companyOrAgency: 'DPU-PR',
  );

  const adminUser = RegisteredUser(
    username: 'admin',
    password: 'password123',
    role: 'Admin',
    namaLengkap: 'Administrator Sistem',
    companyOrAgency: 'CV. Tata Saka Consultant',
  );

  group('Role-Based Access Control (RBAC) - Authentication & Profiles', () {
    test('Unauthenticated initial state has empty role & no hardcoded contractor seed', () async {
      final userProf = UserProfileProvider();
      expect(userProf.isAuthenticated, isFalse);
      expect(userProf.isKonsultan, isFalse);
      expect(userProf.isKontraktor, isFalse);
      expect(userProf.isDinas, isFalse);
      expect(userProf.role, isEmpty);
      expect(userProf.namaLengkap, isEmpty);
      expect(UserProfileProvider.registeredUsers, isEmpty);
      expect(UserProfileProvider.registeredContractors, isEmpty);
    });

    test('Offline login() without FirebaseAuth returns false and keeps user unauthenticated', () async {
      final userProf = UserProfileProvider();
      final success = await userProf.login('kontraktor1', 'password123');
      expect(success, isFalse);
      expect(userProf.isAuthenticated, isFalse);
      expect(userProf.isKonsultan, isFalse);
      expect(userProf.isKontraktor, isFalse);
      expect(userProf.isDinas, isFalse);
    });

    test('Authenticated Konsultan session sets full access flags cleanly', () async {
      final userProf = UserProfileProvider();
      userProf.loginAs(konsultanUser);
      expect(userProf.isAuthenticated, isTrue);
      expect(userProf.isKonsultan, isTrue);
      expect(userProf.isKontraktor, isFalse);
      expect(userProf.isDinas, isFalse);
      expect(userProf.namaLengkap, 'CV. Tata Saka Consultant');
      expect(userProf.companyOrAgency, 'CV. Tata Saka Consultant');
    });

    test('Authenticated Kontraktor 1 session isolates role and company to CV. Divan Insan Cemerlang', () async {
      final userProf = UserProfileProvider();
      userProf.loginAs(kontraktor1User);
      expect(userProf.isAuthenticated, isTrue);
      expect(userProf.isKonsultan, isFalse);
      expect(userProf.isKontraktor, isTrue);
      expect(userProf.isDinas, isFalse);
      expect(userProf.namaLengkap, 'CV. Divan Insan Cemerlang');
      expect(userProf.companyOrAgency, 'CV. Divan Insan Cemerlang');
    });

    test('Authenticated Kontraktor 2 session isolates role and company to CV. Langgeng', () async {
      final userProf = UserProfileProvider();
      userProf.loginAs(kontraktor2User);
      expect(userProf.isAuthenticated, isTrue);
      expect(userProf.isKonsultan, isFalse);
      expect(userProf.isKontraktor, isTrue);
      expect(userProf.isDinas, isFalse);
      expect(userProf.namaLengkap, 'CV. Langgeng');
      expect(userProf.companyOrAgency, 'CV. Langgeng');
    });

    test('Authenticated Dinas session sets Dinas (DPU-PR) role and logout clears access', () async {
      final userProf = UserProfileProvider();
      userProf.loginAs(dinasUser);
      expect(userProf.isAuthenticated, isTrue);
      expect(userProf.isKonsultan, isFalse);
      expect(userProf.isKontraktor, isFalse);
      expect(userProf.isDinas, isTrue);
      expect(userProf.namaLengkap, 'DPU-PR Kabupaten Purbalingga');
      expect(userProf.companyOrAgency, 'DPU-PR');

      await userProf.logout();
      expect(userProf.isAuthenticated, isFalse);
      expect(userProf.isDinas, isFalse);
      expect(userProf.role, isEmpty);
    });
  });

  group('Direct Route & Screen Access Guards (RBAC Security)', () {
    Widget buildRoutedTestApp({
      required UserProfileProvider userProf,
      required GoRouter router,
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
          ChangeNotifierProvider<ContractProvider>(create: (_) => ContractProvider()),
          ChangeNotifierProvider<TimelineProvider>(create: (_) => TimelineProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      );
    }

    testWidgets('Unauthenticated direct navigation to protected routes redirects strictly to /login', (tester) async {
      final userProf = UserProfileProvider();
      final router = createAppRouter(userProf, initialLocation: '/landing');
      addTearDown(router.dispose);

      await tester.pumpWidget(buildRoutedTestApp(userProf: userProf, router: router));
      await tester.pumpAndSettle();

      for (final protectedPath in [
        '/dashboard',
        '/kontrak',
        '/kontrak/tambah',
        '/laporan',
        '/laporan/harian',
        '/laporan/mingguan',
        '/laporan/bulanan',
        '/timeline',
        '/akun',
        '/admin',
      ]) {
        router.go(protectedPath);
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget, reason: '$protectedPath must redirect to LoginScreen');
        expect(router.routeInformationProvider.value.uri.path, '/login');
      }
    });

    testWidgets('Non-admin direct access to /admin is blocked to /dashboard, and Admin is confined to /admin', (tester) async {
      for (final nonAdmin in [konsultanUser, kontraktor1User, dinasUser]) {
        SharedPreferences.setMockInitialValues({
          'user_profile_data': jsonEncode({
            'uid': 'u-${nonAdmin.username}',
            'username': nonAdmin.username,
            'role': nonAdmin.role,
            'namaLengkap': nonAdmin.namaLengkap,
            'companyOrAgency': nonAdmin.companyOrAgency,
          }),
        });
        final userProf = UserProfileProvider();
        final router = createAppRouter(userProf, initialLocation: '/admin');

        await tester.pumpWidget(buildRoutedTestApp(userProf: userProf, router: router));
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/dashboard');
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(AdminPage), findsNothing);

        await tester.pumpWidget(const SizedBox.shrink());
        router.dispose();
      }

      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'u-admin',
          'username': adminUser.username,
          'role': adminUser.role,
          'namaLengkap': adminUser.namaLengkap,
          'companyOrAgency': adminUser.companyOrAgency,
        }),
      });
      final adminProf = UserProfileProvider();
      final adminRouter = createAppRouter(adminProf, initialLocation: '/dashboard');

      await tester.pumpWidget(buildRoutedTestApp(userProf: adminProf, router: adminRouter));
      await tester.pumpAndSettle();

      expect(adminRouter.routeInformationProvider.value.uri.path, '/admin');
      expect(find.byType(AdminPage), findsOneWidget);

      adminRouter.go('/kontrak');
      await tester.pumpAndSettle();
      expect(adminRouter.routeInformationProvider.value.uri.path, '/admin');

      await tester.pumpWidget(const SizedBox.shrink());
      adminRouter.dispose();
    });

    testWidgets('Unauthenticated MainLayout redirects directly to /login', (tester) async {
      final userProf = UserProfileProvider();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
            ChangeNotifierProvider<ContractProvider>(create: (_) => ContractProvider()),
            ChangeNotifierProvider<TimelineProvider>(create: (_) => TimelineProvider()),
          ],
          child: MaterialApp(
            routes: {
              '/login': (_) => const Scaffold(body: Text('Redirected Login')),
            },
            home: const MainLayout(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Redirected Login'), findsOneWidget);
    });

    testWidgets('Dinas direct access to BuatLaporanScreen shows Akses Dibatasi guard', (tester) async {
      final userProf = UserProfileProvider()..loginAs(dinasUser);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
            ChangeNotifierProvider<ContractProvider>(create: (_) => ContractProvider()),
          ],
          child: const MaterialApp(home: BuatLaporanScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Akses Dibatasi'), findsOneWidget);
      expect(find.textContaining('Role Dinas bersifat pemantau'), findsOneWidget);
    });
  });

  group('Dynamic Bottom Navigation Bar per Role', () {
    Widget buildNavTestWidget(UserProfileProvider userProf) {
      final contractProvider = ContractProvider();
      final timelineProvider = TimelineProvider();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
          ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
          ChangeNotifierProvider<TimelineProvider>.value(value: timelineProvider),
        ],
        child: MaterialApp(
          routes: {
            '/login': (_) => const Scaffold(body: Text('Login Route')),
          },
          home: const MainLayout(),
        ),
      );
    }

    testWidgets('Kontraktor bottom navigation has 4 tabs without Laporan', (tester) async {
      final userProf = UserProfileProvider()..loginAs(kontraktor1User);

      await tester.pumpWidget(buildNavTestWidget(userProf));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      expect(navBar, findsOneWidget);

      // Should have 4 tabs: Dashboard, Kegiatan Saya, Timeline, Akun
      expect(find.descendant(of: navBar, matching: find.text('Dashboard')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Kegiatan Saya')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Timeline')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Akun')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Laporan')), findsNothing);
      expect(find.descendant(of: navBar, matching: find.text('Kontrak')), findsNothing);
    });

    testWidgets('Konsultan bottom navigation has 5 tabs including Kontrak and Laporan', (tester) async {
      final userProf = UserProfileProvider()..loginAs(konsultanUser);

      await tester.pumpWidget(buildNavTestWidget(userProf));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      expect(navBar, findsOneWidget);

      // Should have 5 tabs: Dashboard, Kontrak, Laporan, Timeline, Akun
      expect(find.descendant(of: navBar, matching: find.text('Dashboard')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Kontrak')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Laporan')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Timeline')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Akun')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Kegiatan Saya')), findsNothing);
    });

    testWidgets('Dinas bottom navigation has 5 tabs including Kontrak and Laporan', (tester) async {
      final userProf = UserProfileProvider()..loginAs(dinasUser);

      await tester.pumpWidget(buildNavTestWidget(userProf));
      await tester.pumpAndSettle();

      final navBar = find.byType(BottomNavigationBar);
      expect(navBar, findsOneWidget);

      // Should have 5 tabs: Dashboard, Kontrak, Laporan, Timeline, Akun
      expect(find.descendant(of: navBar, matching: find.text('Dashboard')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Kontrak')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Laporan')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Timeline')), findsOneWidget);
      expect(find.descendant(of: navBar, matching: find.text('Akun')), findsOneWidget);
    });
  });

  group('Data Scoping and Isolation Tests', () {
    test('Contractor data scoping correctly filters activities by contractor company', () async {
      final contract = SampleContractData.getDemoContract();
      expect(contract.kegiatans.isNotEmpty, isTrue);

      final userProf1 = UserProfileProvider()..loginAs(kontraktor1User);
      final userProf2 = UserProfileProvider()..loginAs(kontraktor2User);

      final visible1 = ContractAccess.visibleKegiatanEntries(contract, userProf1);
      final visible2 = ContractAccess.visibleKegiatanEntries(contract, userProf2);

      expect(visible1.isNotEmpty, isTrue);
      expect(visible2.isNotEmpty, isTrue);
      for (final entry in visible1) {
        expect((entry.value['kontraktor'] ?? '').toString().toLowerCase().contains('divan'), isTrue);
        expect((entry.value['kontraktor'] ?? '').toString().toLowerCase().contains('langgeng'), isFalse);
      }
      for (final entry in visible2) {
        expect((entry.value['kontraktor'] ?? '').toString().toLowerCase().contains('langgeng'), isTrue);
      }
    });

    test('Dinas data scoping correctly matches DPU-PR agency in contracts', () async {
      final contract = SampleContractData.getDemoContract();
      final userDinas = UserProfileProvider()..loginAs(dinasUser);
      final visible = ContractAccess.visibleContracts([contract], userDinas);
      expect(visible.length, 1);

      final otherDinas = UserProfileProvider()
        ..loginAs(const RegisteredUser(
          username: 'dinas_lain',
          password: 'password123',
          role: 'Dinas',
          namaLengkap: 'Dinas Pendidikan',
          companyOrAgency: 'DINAS PENDIDIKAN',
        ));
      expect(ContractAccess.visibleContracts([contract], otherDinas), isEmpty);
    });
  });

  group('Read-Only UI Protections for Kontraktor & Dinas', () {
    testWidgets('KelolaRkkScreen in readOnly mode displays banner and hides mutation buttons', (tester) async {
      final contract = SampleContractData.getDemoContract();
      final userProf = UserProfileProvider()..loginAs(kontraktor1User);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
            ChangeNotifierProvider<ContractProvider>(create: (_) => ContractProvider()),
          ],
          child: MaterialApp(
            home: KelolaRkkScreen(
              contract: contract,
              kegiatanIndex: 0,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Read-only info text must be shown
      expect(find.textContaining('Mode Lihat Saja (Read-Only)'), findsOneWidget);

      // Save/Mutate buttons must not be rendered
      expect(find.text('Simpan'), findsNothing);
      expect(find.text('Tambah Divisi'), findsNothing);
    });

    testWidgets('KelolaAddendumScreen in readOnly mode hides Addendum creation button', (tester) async {
      final contract = SampleContractData.getDemoContract();
      final userProf = UserProfileProvider()..loginAs(dinasUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
            ChangeNotifierProvider<ContractProvider>(create: (_) => ContractProvider()),
          ],
          child: MaterialApp(
            home: KelolaAddendumScreen(
              contract: contract,
              kegiatanIndex: 0,
              readOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Addendum creation button must be hidden in readOnly
      expect(find.text('Buat Addendum Baru'), findsNothing);
    });
  });
}
