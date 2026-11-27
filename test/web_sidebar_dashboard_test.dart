import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createDashboardWidget({
    required UserProfileProvider userProfile,
    required ContractProvider contractProvider,
    required TimelineProvider timelineProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProfileProvider>.value(value: userProfile),
        ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
        ChangeNotifierProvider<TimelineProvider>.value(value: timelineProvider),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );
  }

  group('Web Sidebar & Responsive Dashboard Tests', () {
    testWidgets(
      '1. Mobile layout (< 900px) does not show persistent sidebar, but opens Drawer on hamburger tap',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));
        final contractProvider = ContractProvider();
        final timelineProvider = TimelineProvider();

        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createDashboardWidget(
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
          ),
        );
        await tester.pumpAndSettle();

        // On mobile, the persistent sidebar Row is not rendered in body
        expect(find.byType(VerticalDivider), findsNothing);

        // Tap hamburger menu icon in AppBar
        final menuButton = find.byIcon(Icons.menu);
        expect(menuButton, findsOneWidget);
        await tester.tap(menuButton);
        await tester.pumpAndSettle();

        // Drawer is opened, showing Corporate Slate Sidebar
        expect(find.text('CV. TATA SAKA CONSULTANT'), findsOneWidget);
        expect(find.text('KONSULTAN TEKNIS'), findsOneWidget);
        for (final category in [
          'UTAMA',
          'PELAPORAN',
          'DOKUMEN & HISTORI',
          'AKUN & PENGATURAN',
          'BANTUAN',
        ]) {
          var scrollAttempts = 0;
          while (find.text(category).evaluate().isEmpty && scrollAttempts < 5) {
            await tester.dragFrom(
              const Offset(150, 700),
              const Offset(0, -500),
            );
            await tester.pumpAndSettle();
            scrollAttempts++;
          }
          expect(find.text(category), findsOneWidget);
        }
        // Pastikan menu yang dihapus TIDAK ada di mobile drawer
        expect(find.text('TEKNIS & ANGGARAN'), findsNothing);
        expect(find.text('RAB / BoQ'), findsNothing);
        expect(find.text('Addendum CCO'), findsNothing);
        expect(find.text('Administrasi Dokumen'), findsNothing);
      },
    );

    testWidgets(
      '2. Web layout (>= 900px) displays persistent Corporate Slate Sidebar with collapse toggle',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));
        final contractProvider = ContractProvider();
        final timelineProvider = TimelineProvider();

        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createDashboardWidget(
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Sidebar is visible in main body
        expect(find.byType(VerticalDivider), findsOneWidget);
        expect(find.text('CV. TATA SAKA CONSULTANT'), findsOneWidget);
        expect(find.text('KONSULTAN TEKNIS'), findsOneWidget);
        expect(find.text('UTAMA'), findsOneWidget);
        expect(find.text('PELAPORAN'), findsOneWidget);
        // Menu yang dihapus TIDAK ada di Web sidebar
        expect(find.text('TEKNIS & ANGGARAN'), findsNothing);
        expect(find.text('RAB / BoQ'), findsNothing);
        expect(find.text('Addendum CCO'), findsNothing);
        expect(find.text('Administrasi Dokumen'), findsNothing);

        // Tap collapse button (chevron_left)
        final collapseBtn = find.byIcon(Icons.chevron_left);
        expect(collapseBtn, findsOneWidget);
        await tester.tap(collapseBtn);
        await tester.pumpAndSettle();

        // In collapsed state, text labels are hidden, chevron_right is shown
        expect(find.text('CV. TATA SAKA CONSULTANT'), findsNothing);
        expect(find.byIcon(Icons.chevron_right), findsOneWidget);

        // Tap expand button (chevron_right)
        await tester.tap(find.byIcon(Icons.chevron_right));
        await tester.pumpAndSettle();

        // Expanded again
        expect(find.text('CV. TATA SAKA CONSULTANT'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Kontraktor Role isolates data on Web Sidebar: Pelaporan & Data Kontrak are hidden',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'user_profile_data': jsonEncode({
            'username': 'kontraktor1',
            'role': 'Kontraktor',
            'namaLengkap': 'CV. Divan Insan Cemerlang',
            'companyOrAgency': 'CV. Divan Insan Cemerlang',
          }),
        });

        final kontraktorProfile = UserProfileProvider();
        kontraktorProfile.loginAs(const RegisteredUser(
          username: 'kontraktor1',
          password: 'password123',
          role: 'Kontraktor',
          namaLengkap: 'CV. Divan Insan Cemerlang',
          companyOrAgency: 'CV. Divan Insan Cemerlang',
        ));
        final contractProvider = ContractProvider();
        final timelineProvider = TimelineProvider();

        tester.view.physicalSize = const Size(1200, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createDashboardWidget(
            userProfile: kontraktorProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Contractor dashboard header
        expect(find.text('Dashboard Kontraktor'), findsOneWidget);

        // Pelaporan category and Data Kontrak must NOT be displayed for Kontraktor
        expect(find.text('PELAPORAN'), findsNothing);
        expect(find.text('Laporan Harian'), findsNothing);
        expect(find.text('Laporan Mingguan'), findsNothing);
        expect(find.text('Laporan Bulanan'), findsNothing);

        // Sidebar and dashboard card show 'Kegiatan Saya'
        expect(find.text('Kegiatan Saya'), findsWidgets);
        expect(find.text('Data Kontrak'), findsNothing);
      },
    );

    testWidgets(
      '4. Timeline sync accurately registers all Daily Report dates',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final timelineProvider = TimelineProvider();

        final contracts = [SampleContractData.getDemoContract()];
        expect(contracts, isNotEmpty);

        // Sync contracts with timeline
        await timelineProvider.syncWithContracts(contracts);

        final events = timelineProvider.allEvents;
        expect(events, isNotEmpty);

        // Check for daily report events
        final dailyEvents = events
            .where((e) => e.entityType == 'LAPORAN_HARIAN')
            .toList();
        expect(dailyEvents, isNotEmpty);

        // Check dates representation
        final dates = dailyEvents
            .map(
              (e) =>
                  '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}-${e.timestamp.day.toString().padLeft(2, '0')}',
            )
            .toSet();

        final expectedDates = <String>{};
        for (final contract in contracts) {
          for (final kegiatan in contract.kegiatans) {
            for (final report in kegiatan['laporans'] as List? ?? const []) {
              if (report is Map && report['tanggal'] != null) {
                expectedDates.add(report['tanggal'].toString());
              }
            }
          }
        }

        expect(expectedDates, isNotEmpty);
        expect(dates, containsAll(expectedDates));
      },
    );

    testWidgets(
      '5. Header buttons order and standard icons: [Tombol Collapse Sidebar] on left, [Tombol Back] on right',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));

        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        WebDashboardLayout.isSidebarOpen.value = true;

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(
                value: konsultanProfile,
              ),
            ],
            child: MaterialApp(
              home: WebDashboardLayout(
                title: 'Detail Kontrak Pengujian',
                showBackButton: true,
                child: const Center(child: Text('Konten')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Temukan kedua tombol di Header
        final collapseBtnFinder = find.byTooltip('Ciutkan Sidebar');
        final backBtnFinder = find.byTooltip('Kembali');

        expect(collapseBtnFinder, findsOneWidget);
        expect(backBtnFinder, findsOneWidget);

        // 2. Verifikasi posisi: [Tombol Collapse Sidebar] berada di sebelah kiri [Tombol Back]
        final collapseTopLeft = tester.getTopLeft(collapseBtnFinder);
        final backTopLeft = tester.getTopLeft(backBtnFinder);
        expect(
          collapseTopLeft.dx < backTopLeft.dx,
          isTrue,
          reason: 'Tombol Collapse Sidebar harus berada di sebelah kiri Tombol Back',
        );

        // 3. Verifikasi ukuran kedua tombol konsisten
        final collapseSize = tester.getSize(collapseBtnFinder);
        final backSize = tester.getSize(backBtnFinder);
        expect(collapseSize.width, equals(backSize.width));
        expect(collapseSize.height, equals(backSize.height));

        // 4. Verifikasi ikon Header menggunakan standard Material Icons
        expect(find.byIcon(Icons.menu_open), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // 5. Verifikasi ikon Menu Sidebar menggunakan standard Material Icons
        expect(find.byIcon(Icons.dashboard), findsOneWidget);
        expect(find.byIcon(Icons.folder_open), findsNothing);
        expect(find.byIcon(Icons.today_outlined), findsOneWidget);
        expect(find.byIcon(Icons.timeline), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byIcon(Icons.help_outline),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
      },
    );

    testWidgets(
      '6. Web Sidebar menu icons, active dot indicator, and hover state isolation',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));
        final contractProvider = ContractProvider();
        final timelineProvider = TimelineProvider();

        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          createDashboardWidget(
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
            timelineProvider: timelineProvider,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial: Dashboard is active with standard Material Icons
        expect(find.byIcon(Icons.dashboard), findsWidgets);
        expect(find.byIcon(Icons.folder_outlined), findsWidgets);
        expect(find.byIcon(Icons.description_outlined), findsWidgets);
        expect(find.byIcon(Icons.edit_note_outlined), findsWidgets);
        expect(find.byIcon(Icons.folder_open), findsNothing);
        expect(find.byIcon(Icons.today_outlined), findsWidgets);
        expect(find.byIcon(Icons.date_range_outlined), findsWidgets);
        expect(find.byIcon(Icons.calendar_month_outlined), findsWidgets);
        expect(find.byIcon(Icons.account_circle_outlined), findsWidgets);

        // 2. Switch to Timeline & Histori
        final timelineFinder = find.widgetWithText(InkWell, 'Timeline & Histori');
        expect(timelineFinder, findsOneWidget);
        await tester.tap(timelineFinder);
        await tester.pumpAndSettle();

        // 3. Verify Timeline icon exists and renders
        expect(find.byIcon(Icons.timeline), findsOneWidget);
      },
    );
  });
}
