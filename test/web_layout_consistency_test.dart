import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/kontrak_screen.dart';
import 'package:tata_saka_app/screens/laporan_screen.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestApp({
    required UserProfileProvider userProfile,
    required ContractProvider contractProvider,
    required TimelineProvider timelineProvider,
    Widget home = const DashboardScreen(),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProfileProvider>.value(value: userProfile),
        ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
        ChangeNotifierProvider<TimelineProvider>.value(value: timelineProvider),
      ],
      child: MaterialApp(home: home),
    );
  }

  group('Web Layout & Dashboard Consistency Tests', () {
    late UserProfileProvider konsultanProfile;
    late ContractProvider contractProvider;
    late TimelineProvider timelineProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      konsultanProfile = UserProfileProvider();
      konsultanProfile.loginAs(const RegisteredUser(
        username: 'konsultan',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'CV. Tata Saka Consultant',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));
      contractProvider = ContractProvider();
      timelineProvider = TimelineProvider();
    });

    testWidgets(
      '1. Web Mode: Sidebar and Heading persist when switching from Dashboard to Kontrak',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial State: On Dashboard
        expect(find.byType(VerticalDivider), findsOneWidget);
        expect(find.text('CV. TATA SAKA'), findsOneWidget);
        expect(find.text('Consultant Engineer'), findsOneWidget);
        expect(find.text('Dashboard'), findsWidgets);

        // 2. Click 'Kontrak' on the Sidebar
        final kontrakMenu = find.widgetWithText(InkWell, 'Kontrak');
        expect(kontrakMenu, findsOneWidget);
        await tester.tap(kontrakMenu);
        await tester.pumpAndSettle();

        // 3. Verify Sidebar is STILL visible
        expect(find.byType(VerticalDivider), findsOneWidget);
        expect(find.text('CV. TATA SAKA'), findsOneWidget);
        expect(find.text('Consultant Engineer'), findsOneWidget);

        // 4. Verify Heading is STILL visible and updated to Kontrak
        expect(find.text('Kontrak'), findsWidgets);

        // 5. Verify Kontrak content is displayed (Search box & Embedded KontrakScreen)
        expect(find.byType(KontrakScreen), findsOneWidget);
        expect(find.text('Cari Kontrak...'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Web Mode: Sidebar and Heading persist when switching to Laporan',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Scroll to Laporan item if needed
        final laporanMenu = find.widgetWithText(InkWell, 'Laporan');
        expect(laporanMenu, findsOneWidget);
        await tester.tap(laporanMenu);
        await tester.pumpAndSettle();

        // Sidebar and Heading stay visible
        expect(find.byType(VerticalDivider), findsOneWidget);
        expect(find.text('CV. TATA SAKA'), findsOneWidget);
        expect(find.byType(LaporanScreen), findsOneWidget);
      },
    );

    testWidgets(
      '3. Web Mode: Sidebar Minimize expands content area and adjusts layout',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Initial expanded sidebar shows brand text
        expect(find.text('CV. TATA SAKA'), findsOneWidget);

        // Toggle via Heading menu button
        final toggleBtn = find.byTooltip('Ciutkan Sidebar');
        expect(toggleBtn, findsWidgets);
        await tester.tap(toggleBtn.first);
        await tester.pumpAndSettle();

        // Minimized: Text hidden, 'Buka Sidebar' tooltip available
        expect(find.text('CV. TATA SAKA'), findsNothing);
        expect(find.byTooltip('Buka Sidebar'), findsWidgets);

        // Toggle again to expand
        await tester.tap(find.byTooltip('Buka Sidebar').first);
        await tester.pumpAndSettle();

        // Brand text back
        expect(find.text('CV. TATA SAKA'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Mobile Mode (< 900px): Persistent sidebar is omitted and Drawer is used',
      (tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
          ),
        );
        await tester.pumpAndSettle();

        // No persistent sidebar in body
        expect(find.byType(VerticalDivider), findsNothing);

        // Hamburger icon opens Drawer
        final menuButton = find.byIcon(Icons.menu);
        expect(menuButton, findsOneWidget);
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Drawer is open
        expect(find.text('CV. TATA SAKA'), findsOneWidget);
      },
    );

    testWidgets(
      '5. WebDashboardLayout widget renders persistent sidebar & heading cleanly',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createTestApp(
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
            home: const WebDashboardLayout(
              title: 'Halaman Pengujian Web',
              activeMenu: 'kontrak',
              child: Center(child: Text('Konten Pengujian')),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Halaman Pengujian Web'), findsOneWidget);
        expect(find.text('Konten Pengujian'), findsOneWidget);
        expect(find.byType(VerticalDivider), findsOneWidget);
        expect(find.text('CV. TATA SAKA'), findsOneWidget);
      },
    );
  });
}
