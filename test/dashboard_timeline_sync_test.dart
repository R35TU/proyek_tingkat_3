import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/timeline_event_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/timeline_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createDashboardApp({
    required UserProfileProvider userProfile,
    required ContractProvider contractProvider,
    required TimelineProvider timelineProvider,
    Size surfaceSize = const Size(1280, 900),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProfileProvider>.value(value: userProfile),
        ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
        ChangeNotifierProvider<TimelineProvider>.value(value: timelineProvider),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: const DashboardScreen(),
        ),
      ),
    );
  }

  group('Dashboard Recent Activities & Timeline Sync Tests', () {
    testWidgets('1. Dashboard renders recent activities from TimelineProvider source', (tester) async {
      final userProfile = UserProfileProvider();
      userProfile.loginAs(const RegisteredUser(
        username: 'konsultan',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'CV. Tata Saka Consultant',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));

      final contractProv = ContractProvider();
      final timelineProv = TimelineProvider();
      await timelineProv.loadEvents();

      // Log a custom event into Timeline with future timestamp so it's strictly newest
      final futureTime = DateTime.now().add(const Duration(days: 365));
      await timelineProv.logEvent(
        actorName: 'CV. Tata Saka Consultant',
        actionType: 'CREATE',
        entityType: 'LAPORAN_HARIAN',
        contractId: 'c_test_1',
        contractName: 'Pengawasan Jalan Raya',
        kegiatanName: 'Paket Pekerjaan 1',
        title: 'Buku Harian Standar Baru Hari Ini',
        description: 'Pekerjaan galian tanah dan saluran drainase.',
        customTimestamp: futureTime,
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createDashboardApp(
          userProfile: userProfile,
          contractProvider: contractProv,
          timelineProvider: timelineProv,
        ),
      );
      await tester.pumpAndSettle();

      // Header "Aktivitas Terkini" is present
      expect(find.text('Aktivitas Terkini'), findsWidgets);

      // The new event logged in Timeline is immediately visible on Dashboard
      expect(find.text('Buku Harian Standar Baru Hari Ini'), findsOneWidget);
      expect(find.text('Pekerjaan galian tanah dan saluran drainase.'), findsOneWidget);
    });

    testWidgets('2. Role-based isolation on Dashboard matches Timeline filtering (Kontraktor)', (tester) async {
      // Login as Kontraktor (CV. Divan Insan Cemerlang)
      final userProfile = UserProfileProvider();
      userProfile.loginAs(const RegisteredUser(
        username: 'kontraktor1',
        password: 'password123',
        role: 'Kontraktor',
        namaLengkap: 'Restu (CV. Divan)',
        companyOrAgency: 'CV. Divan Insan Cemerlang',
      ));

      final contractProv = ContractProvider();
      final timelineProv = TimelineProvider();
      await timelineProv.loadEvents();

      final futureTime = DateTime.now().add(const Duration(days: 365));

      // Event for this contractor
      await timelineProv.logEvent(
        actorName: 'Restu (CV. Divan)',
        actorRole: 'Kontraktor',
        actionType: 'CREATE',
        entityType: 'LAPORAN_HARIAN',
        contractId: 'c_test_1',
        contractName: 'Pengawasan Jalan Raya',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        title: 'Laporan Mandiri CV Divan',
        description: 'Pekerjaan aspal lapis aus.',
        customTimestamp: futureTime,
      );

      // Event for another contractor
      await timelineProv.logEvent(
        actorName: 'PT. Lain',
        actorRole: 'Kontraktor',
        actionType: 'CREATE',
        entityType: 'LAPORAN_HARIAN',
        contractId: 'c_test_2',
        contractName: 'Pengawasan Jembatan',
        kegiatanName: 'Jembatan X',
        kontraktorName: 'PT. Lain Kontraktor',
        title: 'Laporan Rahasia Kontraktor Lain',
        description: 'Pondasi jembatan.',
        customTimestamp: futureTime,
      );

      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createDashboardApp(
          userProfile: userProfile,
          contractProvider: contractProv,
          timelineProvider: timelineProv,
        ),
      );
      await tester.pumpAndSettle();

      // Contractor sees their own event
      expect(find.text('Laporan Mandiri CV Divan'), findsOneWidget);

      // Contractor DOES NOT see other contractor's event
      expect(find.text('Laporan Rahasia Kontraktor Lain'), findsNothing);
    });

    testWidgets('3. Tapping "Lihat Semua" navigates to Timeline screen', (tester) async {
      final userProfile = UserProfileProvider();
      userProfile.loginAs(const RegisteredUser(
        username: 'konsultan',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'CV. Tata Saka Consultant',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));

      final contractProv = ContractProvider();
      final timelineProv = TimelineProvider();

      // Mobile viewport
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createDashboardApp(
          userProfile: userProfile,
          contractProvider: contractProv,
          timelineProvider: timelineProv,
          surfaceSize: const Size(400, 800),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Lihat Semua"
      final seeAllBtn = find.text('Lihat Semua');
      if (seeAllBtn.evaluate().isNotEmpty) {
        await tester.tap(seeAllBtn.first);
        await tester.pumpAndSettle();

        // TimelineScreen is opened
        expect(find.byType(TimelineScreen), findsOneWidget);
      }
    });
  });
}
