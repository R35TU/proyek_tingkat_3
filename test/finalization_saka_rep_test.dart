import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/edit_profil_screen.dart';
import 'package:tata_saka_app/screens/keamanan_screen.dart';
import 'package:tata_saka_app/screens/kontrak_screen.dart';
import 'package:tata_saka_app/screens/landing_screen.dart';
import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/screens/laporan_mingguan_screen.dart';
import 'package:tata_saka_app/screens/laporan_screen.dart';
import 'package:tata_saka_app/screens/panduan_faq_screen.dart';
import 'package:tata_saka_app/screens/pengaturan_screen.dart';
import 'package:tata_saka_app/screens/setting_screen.dart';
import 'package:tata_saka_app/screens/timeline_screen.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildRoutedApp({
    required UserProfileProvider userProf,
    required GoRouter router,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
        ChangeNotifierProvider<ContractProvider>(
          create: (_) => ContractProvider(),
        ),
        ChangeNotifierProvider<TimelineProvider>(
          create: (_) => TimelineProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'SAKA-REP',
        routerConfig: router,
      ),
    );
  }

  group('Finalization SAKA-REP: Mobile Sidebar, Branding & Download Link', () {
    test(
      '1. Android branding, preserved applicationId, launcher icons, and landing APK URL',
      () {
        final manifest =
            File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
        expect(manifest, contains('android:label="SAKA-REP"'));
        expect(manifest, isNot(contains('android:label="Tata Saka Consultant"')));

        final gradle =
            File('android/app/build.gradle.kts').readAsStringSync();
        expect(gradle, contains('applicationId = "com.example.tata_saka_app"'));

        final mainDart = File('lib/main.dart').readAsStringSync();
        expect(mainDart, contains("title: 'SAKA-REP'"));

        final landingDart =
            File('lib/screens/landing_screen.dart').readAsStringSync();
        expect(
          landingDart,
          contains(
            'https://kencana.basic.box.cloudeka.id/tatasaka-media-rw4mpj/SAKA-REP.apk',
          ),
        );
        expect(landingDart, contains("downloadAndOpenRemote(_apkDownloadUrl, 'SAKA-REP.apk')"));
        expect(landingDart, isNot(contains('app-release.apk')));

        for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
          for (final iconName in [
            'ic_launcher.png',
            'ic_launcher_round.png',
            'ic_launcher_foreground.png',
          ]) {
            expect(
              File('android/app/src/main/res/mipmap-$density/$iconName')
                  .existsSync(),
              isTrue,
              reason: 'Missing mipmap-$density/$iconName',
            );
          }
        }
        for (final adaptiveXml in [
          'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
          'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml',
        ]) {
          final xml = File(adaptiveXml).readAsStringSync();
          expect(
            xml,
            contains('android:drawable="@color/ic_launcher_background"'),
            reason: '$adaptiveXml must use android:drawable for <background>',
          );
          expect(xml, isNot(contains('android:color=')));
        }
      },
    );

    test(
      '2. Shared sidebarSectionsFor matches web & role rules for Konsultan, Dinas, Kontraktor',
      () {
        final konsultan = UserProfileProvider()
          ..loginAs(const RegisteredUser(
            username: 'konsultan',
            password: 'password123',
            role: 'Konsultan',
            namaLengkap: 'CV. Tata Saka Consultant',
            companyOrAgency: 'CV. Tata Saka Consultant',
          ));
        final konsultanKeys = WebDashboardLayout.sidebarSectionsFor(konsultan)
            .expand((s) => s.items.map((e) => e.key))
            .toList();
        expect(konsultanKeys, [
          'dashboard',
          'kontrak',
          'laporan',
          'buat_laporan',
          'laporan_harian',
          'laporan_mingguan',
          'laporan_bulanan',
          'timeline',
          'akun',
          'pengaturan',
          'keamanan',
          'edit_profil',
          'panduan_faq',
        ]);

        final dinas = UserProfileProvider()
          ..loginAs(const RegisteredUser(
            username: 'dinas',
            password: 'password123',
            role: 'Dinas',
            namaLengkap: 'Dinas PUPR',
            companyOrAgency: 'Dinas PUPR',
          ));
        final dinasKeys = WebDashboardLayout.sidebarSectionsFor(dinas)
            .expand((s) => s.items.map((e) => e.key))
            .toList();
        expect(dinasKeys, [
          'dashboard',
          'kontrak',
          'laporan',
          'laporan_harian',
          // Dinas boleh memantau laporan mingguan & bulanan (view-only).
          'laporan_mingguan',
          'laporan_bulanan',
          'timeline',
          'akun',
          'pengaturan',
          'keamanan',
          'edit_profil',
          'panduan_faq',
        ]);

        final kontraktor = UserProfileProvider()
          ..loginAs(const RegisteredUser(
            username: 'kontraktor',
            password: 'password123',
            role: 'Kontraktor',
            namaLengkap: 'CV. Karya Mandiri',
            companyOrAgency: 'CV. Karya Mandiri',
          ));
        final kontraktorKeys = WebDashboardLayout.sidebarSectionsFor(kontraktor)
            .expand((s) => s.items.map((e) => e.key))
            .toList();
        expect(kontraktorKeys, [
          'dashboard',
          'kegiatan',
          'timeline',
          'akun',
          'pengaturan',
          'keamanan',
          'edit_profil',
          'panduan_faq',
        ]);
      },
    );

    testWidgets(
      '3. Mobile dark drawer preserves dark theme, displays all web submenus, and routes every submenu cleanly',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final userProf = UserProfileProvider();
        await tester.pump();
        userProf.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));

        tester.view.physicalSize = const Size(540, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = createAppRouter(userProf, initialLocation: '/dashboard');
        addTearDown(router.dispose);

        await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
        await tester.pumpAndSettle();

        // Buka Drawer mobile pada Dashboard
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        final mobileDrawerFinder = find.byKey(const ValueKey('mobile_dark_drawer'));
        expect(mobileDrawerFinder, findsOneWidget);

        // Pastikan tema gelap (#0F172A) dipertahankan pada container Drawer
        final drawerContainer = tester.widget<Container>(mobileDrawerFinder);
        expect(drawerContainer.color, const Color(0xFF0F172A));

        // Pastikan seluruh kategori & submenu Web tersedia di Mobile Drawer
        final expectedLabels = WebDashboardLayout.sidebarSectionsFor(userProf)
            .expand((s) => s.items.map((e) => e.label))
            .toList();

        for (final label in expectedLabels) {
          final finder = find.descendant(
            of: mobileDrawerFinder,
            matching: find.text(label),
          );
          await tester.scrollUntilVisible(
            finder,
            120,
            scrollable: find.descendant(
              of: mobileDrawerFinder,
              matching: find.byType(Scrollable),
            ),
          );
          expect(finder, findsOneWidget);
        }

        // Uji klik menu Laporan Harian -> /laporan/data (DataLaporanScreen) -> Back kembali ke /laporan
        final laporanHarianFinder = find.descendant(
          of: mobileDrawerFinder,
          matching: find.text('Laporan Harian'),
        );
        await tester.scrollUntilVisible(
          laporanHarianFinder,
          120,
          scrollable: find.descendant(
            of: mobileDrawerFinder,
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(laporanHarianFinder);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/laporan/data');
        expect(find.byType(DataLaporanScreen), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/laporan');
        expect(find.byType(LaporanScreen), findsOneWidget);

        // Dari LaporanScreen, kartu Buat Laporan Harian membuka /laporan/harian (BuatLaporanScreen)
        await tester.tap(find.text('Buat Laporan Harian'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/laporan/harian');
        expect(find.byType(BuatLaporanScreen), findsOneWidget);

        // Kembali ke /dashboard dan uji seluruh rute submenu drawer lainnya
        router.go('/dashboard');
        await tester.pumpAndSettle();

        final routeExpectations = <String, (String, Type)>{
          'Kontrak': ('/kontrak', KontrakScreen),
          'Laporan': ('/laporan', LaporanScreen),
          'Buat Laporan': ('/laporan/harian', BuatLaporanScreen),
          'Laporan Mingguan': ('/laporan/mingguan', LaporanMingguanScreen),
          'Laporan Bulanan': ('/laporan/bulanan', LaporanBulananScreen),
          'Timeline & Histori': ('/timeline', TimelineScreen),
          'Akun': ('/akun', SettingScreen),
          'Pengaturan Akun': ('/akun/pengaturan', PengaturanScreen),
          'Keamanan & Sandi': ('/akun/keamanan', KeamananScreen),
          'Edit Profil': ('/akun/profil', EditProfilScreen),
          'Panduan & FAQ': ('/panduan', PanduanFaqScreen),
        };

        for (final entry in routeExpectations.entries) {
          router.go('/dashboard');
          await tester.pumpAndSettle();
          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();

          final itemFinder = find.descendant(
            of: mobileDrawerFinder,
            matching: find.text(entry.key),
          );
          await tester.scrollUntilVisible(
            itemFinder,
            120,
            scrollable: find.descendant(
              of: mobileDrawerFinder,
              matching: find.byType(Scrollable),
            ),
          );
          await tester.ensureVisible(itemFinder);
          await tester.pumpAndSettle();
          await tester.tap(itemFinder);
          await tester.pumpAndSettle();

          expect(
            router.routeInformationProvider.value.uri.path,
            entry.value.$1,
            reason: 'Tap "${entry.key}" should navigate to ${entry.value.$1}',
          );
          expect(find.byType(entry.value.$2), findsOneWidget);
        }

        // Pada /panduan, tombol Back kembali ke /dashboard
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/dashboard');
        expect(find.byType(DashboardScreen), findsOneWidget);

        // Uji akun sub-route Back ke /akun (SettingScreen)
        router.go('/akun/pengaturan');
        await tester.pumpAndSettle();
        expect(find.byType(PengaturanScreen), findsOneWidget);
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/akun');
        expect(find.byType(SettingScreen), findsOneWidget);
      },
    );

    testWidgets(
      '4. Mobile Drawer for Kontraktor shows Kegiatan Saya and hides Pelaporan submenus',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final userProf = UserProfileProvider();
        await tester.pump();
        userProf.loginAs(const RegisteredUser(
          username: 'kontraktor',
          password: 'password123',
          role: 'Kontraktor',
          namaLengkap: 'CV. Karya Mandiri',
          companyOrAgency: 'CV. Karya Mandiri',
        ));

        tester.view.physicalSize = const Size(540, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = createAppRouter(userProf, initialLocation: '/dashboard');
        addTearDown(router.dispose);

        await tester.pumpWidget(buildRoutedApp(userProf: userProf, router: router));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        final mobileDrawerFinder = find.byKey(const ValueKey('mobile_dark_drawer'));
        expect(mobileDrawerFinder, findsOneWidget);

        expect(
          find.descendant(
            of: mobileDrawerFinder,
            matching: find.text('PELAPORAN'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: mobileDrawerFinder,
            matching: find.text('Laporan Harian'),
          ),
          findsNothing,
        );

        final kegiatanFinder = find.descendant(
          of: mobileDrawerFinder,
          matching: find.text(userProf.tr('nav_kegiatan_saya')),
        );
        expect(kegiatanFinder, findsOneWidget);
        await tester.tap(kegiatanFinder);
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/kegiatan');
        expect(find.byType(KontrakScreen), findsOneWidget);
        expect(find.text('Kegiatan Saya'), findsWidgets);
      },
    );

    testWidgets(
      '5. LandingScreen renders Download Aplikasi cleanly on desktop and mobile',
      (tester) async {
        for (final viewport in [const Size(1440, 900), const Size(390, 844)]) {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1.0;

          SharedPreferences.setMockInitialValues({});
          final userProf = UserProfileProvider();
          final router = createAppRouter(userProf, initialLocation: '/landing');

          await tester.pumpWidget(
            buildRoutedApp(userProf: userProf, router: router),
          );
          await tester.pumpAndSettle();

          final downloadBtn = find.text('Download Aplikasi');
          expect(downloadBtn, findsOneWidget);
          await tester.ensureVisible(downloadBtn);
          expect(tester.takeException(), isNull);

          router.dispose();
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      },
    );
  });
}
