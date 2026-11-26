import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/screens/admin_page.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/screens/kontrak_screen.dart';
import 'package:tata_saka_app/screens/landing_screen.dart';
import 'package:tata_saka_app/screens/login_screen.dart';
import 'package:tata_saka_app/screens/splash_screen.dart';
import 'package:tata_saka_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildRoutedApp({
    required UserProfileProvider userProf,
    ContractProvider? contractProv,
    TimelineProvider? timelineProv,
    GoRouter? router,
  }) {
    final appRouter = router ?? createAppRouter(userProf);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
        ChangeNotifierProvider<ContractProvider>.value(
          value: contractProv ?? ContractProvider(),
        ),
        ChangeNotifierProvider<TimelineProvider>.value(
          value: timelineProv ?? TimelineProvider(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
      ),
    );
  }

  final sampleContract = ContractModel(
    id: 'kontrak-audit-01',
    jenisKegiatan: 'Pengawasan Teknis',
    namaKontrak: 'Paket Audit Navigasi 2026',
    nomorSpk: '001/SPK/2026',
    tglMulaiSpk: '01 Juli 2026',
    nomorSpmk: '001/SPMK/2026',
    tglMulaiSpmk: '01 Juli 2026',
    tglSelesaiSpmk: '31 Oktober 2026',
    hariKalender: 120,
    nilaiKontrak: 'Rp 500.000.000,00',
    instansiDinas: ['DPU-PR'],
    sumberDana: 'APBD',
    deskripsi: 'Pengawasan Jalan',
    kegiatans: [
      {
        'namaKegiatan': 'Ruas Jalan Audit',
        'lokasi': 'Purbalingga',
        'kontraktor': 'CV Testing',
        'sumberDana': 'APBD',
        'rkkDivisiList': [],
        'addendums': [],
        'laporans': [],
      },
    ],
  );

  group('Splash Screen HTML Removal & Flutter Splash Transition', () {
    test('web/index.html only acts as Flutter Web bootstrap without HTML/JS splash or redirect', () {
      final indexHtml = File('web/index.html').readAsStringSync();
      expect(indexHtml, contains('flutter_bootstrap.js'));
      expect(indexHtml, isNot(contains('landing/index.html')));
      expect(indexHtml, isNot(contains('window.location.replace')));
      expect(indexHtml, isNot(contains('id="splash"')));
    });

    testWidgets('1. Unauthenticated open renders Flutter SplashScreen with animation & loading then transitions to LandingScreen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final userProf = UserProfileProvider();
      final router = createAppRouter(userProf);

      await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
      await tester.pump(const Duration(milliseconds: 300));

      // Splash screen rendered by Flutter
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.text('Memuat aplikasi...'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Wait for splash minimum timer (1500ms) + transition settle
      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();

      expect(find.byType(LandingScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/landing');
      expect(router.canPop(), isFalse);
    });

    testWidgets('2. Authenticated open renders Flutter SplashScreen then transitions to DashboardScreen without splash in back stack', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'u-1',
          'username': 'konsultan1',
          'role': 'Konsultan',
          'namaLengkap': 'Konsultan Uji',
          'companyOrAgency': 'CV. Tata Saka Consultant',
        }),
      });
      final userProf = UserProfileProvider();
      final router = createAppRouter(userProf);

      await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1400));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
      expect(router.canPop(), isFalse);
    });
  });

  group('Routing Guards, Back Navigation, Deep Linking & Logout Protection', () {
    testWidgets('3. Unauthenticated access to protected URLs redirects to /login', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final userProf = UserProfileProvider();
      final router = createAppRouter(userProf);

      await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      for (final protectedPath in [
        '/dashboard',
        '/kontrak',
        '/kontrak/kontrak-audit-01',
        '/laporan/data',
        '/akun/pengaturan',
        '/admin',
      ]) {
        router.go(protectedPath);
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget, reason: '$protectedPath must redirect to LoginScreen');
        expect(router.routeInformationProvider.value.uri.path, '/login');
      }
    });

    testWidgets('4. Top-level menu navigation updates URL, Detail drill-down keeps Back history, and Dashboard cannot pop to Login/Splash', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'u-2',
          'username': 'konsultan1',
          'role': 'Konsultan',
          'namaLengkap': 'Konsultan Uji',
          'companyOrAgency': 'CV. Tata Saka Consultant',
        }),
      });
      final userProf = UserProfileProvider();
      final contractProv = ContractProvider();
      final router = createAppRouter(userProf);

      await tester.pumpWidget(
        buildRoutedApp(
          userProf: userProf,
          contractProv: contractProv,
          router: router,
        ),
      );
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();

      // At Dashboard: cannot pop back to Splash/Login
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(router.canPop(), isFalse);

      // Navigate via sidebar menu -> Kontrak (URL updates to /kontrak)
      await tester.tap(find.widgetWithText(InkWell, 'Kontrak'));
      await tester.pumpAndSettle();
      expect(find.byType(KontrakScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/kontrak');

      // Drill-down into Detail Kontrak -> Detail Kegiatan -> RKK
      router.go('/kontrak/${sampleContract.id}?tab=0', extra: sampleContract);
      await tester.pumpAndSettle();
      expect(find.byType(DetailKontrakScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/kontrak/${sampleContract.id}');
      expect(router.canPop(), isTrue);

      router.go('/kontrak/${sampleContract.id}/kegiatan/0', extra: sampleContract);
      await tester.pumpAndSettle();
      expect(find.byType(DetailKegiatanScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/kontrak/${sampleContract.id}/kegiatan/0');

      router.go('/kontrak/${sampleContract.id}/kegiatan/0/rkk', extra: sampleContract);
      await tester.pumpAndSettle();
      expect(find.byType(KelolaRkkScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/kontrak/${sampleContract.id}/kegiatan/0/rkk');

      // Back button pops one hierarchy level at a time
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(DetailKegiatanScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/kontrak/${sampleContract.id}/kegiatan/0');

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(DetailKontrakScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/kontrak/${sampleContract.id}');

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(KontrakScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/kontrak');
    });

    testWidgets('5. Deep link / refresh simulation on Admin & Kontrak detail preserves destination after initialization', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'admin-1',
          'username': 'admin',
          'role': 'Admin',
          'namaLengkap': 'Administrator',
          'companyOrAgency': 'CV. Tata Saka Consultant',
        }),
      });
      final userProf = UserProfileProvider();
      final router = createAppRouter(userProf, initialLocation: '/admin');

      await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
      await tester.pumpAndSettle();

      expect(find.byType(AdminPage), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/admin');

      router.dispose();
    });

    testWidgets('5b. Deep link / refresh simulation on nested Kontrak detail preserves route', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'u-deep',
          'username': 'konsultan1',
          'role': 'Konsultan',
          'namaLengkap': 'Konsultan Uji',
          'companyOrAgency': 'CV. Tata Saka Consultant',
        }),
      });
      final userProf = UserProfileProvider();
      final router = createAppRouter(
        userProf,
        initialLocation: '/kontrak/${sampleContract.id}?tab=1',
      );

      await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
      await tester.pumpAndSettle();

      expect(find.byType(DetailKontrakScreen), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.toString(),
        '/kontrak/${sampleContract.id}?tab=1',
      );

      // Back button from refreshed detail page falls back safely to /kontrak
      await tester.tap(find.byTooltip('Kembali'));
      await tester.pumpAndSettle();
      expect(find.byType(KontrakScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/kontrak');

      router.dispose();
    });

    testWidgets('6. Logout clears session, goes to /login, and blocks return to protected routes', (tester) async {
      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'u-3',
          'username': 'konsultan1',
          'role': 'Konsultan',
          'namaLengkap': 'Konsultan Uji',
          'companyOrAgency': 'CV. Tata Saka Consultant',
        }),
      });
      final userProf = UserProfileProvider();
      final router = createAppRouter(userProf);

      await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
      await tester.pump(const Duration(milliseconds: 1700));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      await userProf.logout();
      await tester.pumpAndSettle();

      expect(userProf.isAuthenticated, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/login');
      expect(router.canPop(), isFalse);

      // Pop route (Back button on /login after logout) moves cleanly to /landing, NEVER back to /dashboard
      await WidgetsBinding.instance.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsNothing);
      expect(find.byType(LandingScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/landing');

      // Simulated browser Back / URL navigation to protected routes redirects to /login
      for (final route in ['/dashboard', '/kontrak', '/admin']) {
        router.routeInformationProvider.didPushRouteInformation(
          RouteInformation(uri: Uri.parse(route)),
        );
        await tester.pumpAndSettle();
        expect(find.byType(LoginScreen), findsOneWidget);
        expect(router.routeInformationProvider.value.uri.path, '/login');
      }
    });

    testWidgets('7. Login transition uses Router.neglect to /dashboard and Back from dashboard stays on dashboard', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final userProf = UserProfileProvider();
      final router = createAppRouter(userProf, initialLocation: '/login');

      await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Back from /login returns cleanly to /landing
      await tester.tap(find.byTooltip('Kembali ke Landing Page'));
      await tester.pumpAndSettle();
      expect(find.byType(LandingScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/landing');

      // Navigate back to /login and sign in
      router.go('/login');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      final loginCtx = tester.element(find.byType(LoginScreen));
      userProf.loginAs(const RegisteredUser(
        username: 'konsultan1',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'Konsultan Uji',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));
      Router.neglect(loginCtx, () => GoRouter.of(loginCtx).go('/dashboard'));
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
      expect(router.canPop(), isFalse);

      // System/browser Back from dashboard must NOT return to /login or /
      await WidgetsBinding.instance.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/dashboard');

      // Even if a browser history Back pops toward /login or /, guard keeps user on /dashboard
      router.routeInformationProvider.didPushRouteInformation(
        RouteInformation(uri: Uri.parse('/login')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, '/dashboard');
    });

    testWidgets('8. LandingScreen matches updated layout and navigates to Login & Panduan on Desktop and Mobile', (tester) async {
      for (final viewport in [const Size(1440, 900), const Size(390, 844)]) {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1.0;

        SharedPreferences.setMockInitialValues({});
        final userProf = UserProfileProvider();
        final router = createAppRouter(userProf, initialLocation: '/landing');

        await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
        await tester.pumpAndSettle();

        expect(find.byType(LandingScreen), findsOneWidget);
        expect(find.text('SAKA-REP'), findsOneWidget);
        expect(find.text('TATA SAKA-REPORTING SYSTEM'), findsOneWidget);
        expect(find.text('Login Portal'), findsOneWidget);
        expect(
          find.text('Ngrancang\nKanthi Titi.\nNgawal\nNganti Tutug.'),
          findsOneWidget,
        );
        expect(find.text('Mulai'), findsOneWidget);
        expect(find.text('Panduan & FAQ'), findsOneWidget);
        expect(find.text('Download Aplikasi'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.ensureVisible(find.text('Panduan & FAQ'));
        await tester.tap(find.text('Panduan & FAQ'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/panduan-umum');

        router.go('/landing');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Mulai'));
        await tester.tap(find.text('Mulai'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/login');

        router.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      }
    });
  });
}
