import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/timeline_event_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/timeline_screen.dart';

Future<void> _seedProjectAuditEvents(TimelineProvider prov) async {
  const cId = 'kontrak-ruas-uji-01';
  const cName = 'PENGAWASAN JALAN PAKET UJI';
  const dinas = 'DPU-PR Kab. Purbalingga';

  await prov.logEvent(
    actorName: 'PPK DPU-PR',
    actorRole: 'Dinas',
    actionType: 'CREATE',
    entityType: 'KONTRAK',
    contractId: cId,
    contractName: cName,
    dinasName: dinas,
    title: 'Penerbitan SPK Kontrak Pengawasan',
    description: 'Kontrak pengawasan teknis diterbitkan.',
    customTimestamp: DateTime(2026, 4, 20, 8, 30),
  );

  await prov.logEvent(
    actorName: 'Site Engineer',
    actorRole: 'Konsultan',
    actionType: 'CREATE',
    entityType: 'RKK',
    contractId: cId,
    contractName: cName,
    kegiatanId: 'keg_ruas_a',
    kegiatanName: 'Ruas Jalan A',
    kontraktorName: 'CV. Divan Insan Cemerlang',
    dinasName: dinas,
    title: 'Pengisian Master RAB / BoQ Ruas Jalan A',
    description: 'Input rincian BoQ kontrak awal.',
    customTimestamp: DateTime(2026, 4, 22, 10, 00),
  );

  await prov.logEvent(
    actorName: 'Inspektor Lapangan',
    actorRole: 'Konsultan',
    actionType: 'CREATE',
    entityType: 'LAPORAN_HARIAN',
    contractId: cId,
    contractName: cName,
    kegiatanId: 'keg_ruas_b',
    kegiatanName: 'Ruas Jalan B',
    kontraktorName: 'CV. Langgeng',
    dinasName: dinas,
    title: 'Buku Harian Standar #03: Ruas Jalan B',
    description: 'Pekerjaan lapis pondasi agregat.',
    customTimestamp: DateTime(2026, 5, 10, 16, 00),
  );

  await prov.logEvent(
    actorName: 'Inspektor Lapangan',
    actorRole: 'Konsultan',
    actionType: 'CREATE',
    entityType: 'LAPORAN_HARIAN',
    contractId: cId,
    contractName: cName,
    kegiatanId: 'keg_ruas_a',
    kegiatanName: 'Ruas Jalan A',
    kontraktorName: 'CV. Divan Insan Cemerlang',
    dinasName: dinas,
    title: 'Buku Harian Standar #08: Ruas Jalan A',
    description: 'Pekerjaan galian dan perkerasan bahu jalan.',
    customTimestamp: DateTime(2026, 5, 11, 16, 30),
  );

  await prov.logEvent(
    actorName: 'CV. Tata Saka Consultant & PPK DPU-PR',
    actorRole: 'Konsultan',
    actionType: 'UPDATE',
    entityType: 'ADDENDUM',
    contractId: cId,
    contractName: cName,
    kegiatanId: 'keg_ruas_a',
    kegiatanName: 'Ruas Jalan A',
    kontraktorName: 'CV. Divan Insan Cemerlang',
    dinasName: dinas,
    title: 'Penerbitan Addendum 01 (CCO Rekayasa Lapangan)',
    description: 'Penyesuaian volume pekerjaan.',
    changes: const [
      {
        'parameter': 'Divisi 3.1 Galian Biasa',
        'oldValue': '210.00 m3',
        'newValue': '245.00 m3 (+35.00 m3)',
      },
      {
        'parameter': 'Divisi 6.3 Campuran Aspal Panas (AC-WC)',
        'oldValue': '95.50 Ton',
        'newValue': '102.30 Ton (+6.80 Ton)',
      },
    ],
    metadata: const {'nomorAddendum': '01'},
    customTimestamp: DateTime(2026, 5, 12, 14, 00),
  );

  await prov.logEvent(
    actorName: 'Site Engineer',
    actorRole: 'Konsultan',
    actionType: 'CREATE',
    entityType: 'LAPORAN_MINGGUAN',
    contractId: cId,
    contractName: cName,
    kegiatanId: 'keg_ruas_a',
    kegiatanName: 'Ruas Jalan A',
    kontraktorName: 'CV. Divan Insan Cemerlang',
    dinasName: dinas,
    title: 'Penerbitan Laporan Mingguan ke-4',
    description: 'Realisasi kumulatif Ruas Jalan A minggu ke-4.',
    customTimestamp: DateTime(2026, 5, 17, 17, 00),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TimelineEventModel Unit & Logic Tests', () {
    test('TimelineEventModel correctly identifies category, actionLabel, and actionColor', () {
      final evKontrak = TimelineEventModel(
        id: '1',
        timestamp: DateTime(2026, 4, 20, 10, 0),
        actorName: 'Dinas PU',
        actionType: 'CREATE',
        entityType: 'KONTRAK',
        contractId: 'c1',
        contractName: 'Kontrak Jalan',
        title: 'Pembuatan Kontrak',
        description: 'Kontrak Baru dibuat',
      );
      expect(evKontrak.category, 'Kontrak & Kegiatan');
      expect(evKontrak.actionLabel, 'Dibuat');
      expect(evKontrak.actionColor, const Color(0xFF10B981));

      final evAddendum = TimelineEventModel(
        id: '2',
        timestamp: DateTime(2026, 5, 10, 14, 0),
        actorName: 'Konsultan',
        actionType: 'UPDATE',
        entityType: 'ADDENDUM',
        contractId: 'c1',
        contractName: 'Kontrak Jalan',
        title: 'Addendum 01',
        description: 'CCO Tambah Kurang',
        changes: [
          {
            'parameter': 'Divisi 3.1 Galian Biasa',
            'oldValue': '210.00 m3',
            'newValue': '245.00 m3 (+35.00 m3)',
          }
        ],
      );
      expect(evAddendum.category, 'Addendum (CCO)');
      expect(evAddendum.actionLabel, 'Diperbarui');
      expect(evAddendum.changes.length, 1);
      expect(evAddendum.changes.first['parameter'], 'Divisi 3.1 Galian Biasa');

      final evLaporan = TimelineEventModel(
        id: '3',
        timestamp: DateTime(2026, 5, 12, 17, 0),
        actorName: 'Inspektor',
        actionType: 'CREATE',
        entityType: 'LAPORAN_HARIAN',
        contractId: 'c1',
        contractName: 'Kontrak Jalan',
        title: 'Buku Harian',
        description: 'Laporan harian',
      );
      expect(evLaporan.category, 'Laporan');
    });

    test('TimelineEventModel serialization to JSON and back preserves Opsi A changes', () {
      final original = TimelineEventModel(
        id: 'ev_test_100',
        timestamp: DateTime(2026, 5, 1, 9, 30),
        actorName: 'Site Engineer',
        actorRole: 'Konsultan',
        actionType: 'UPDATE',
        entityType: 'ADDENDUM',
        contractId: 'c_test',
        contractName: 'Kontrak Test',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        title: 'Addendum Rekayasa Lapangan',
        description: 'Penyesuaian volume galian dan aspal',
        changes: [
          {
            'parameter': 'Divisi 6.3 AC-WC',
            'oldValue': '95.50 Ton',
            'newValue': '102.30 Ton',
          }
        ],
        metadata: {'nomorAddendum': '01'},
      );

      final json = original.toJson();
      final reconstructed = TimelineEventModel.fromJson(json);

      expect(reconstructed.id, 'ev_test_100');
      expect(reconstructed.actorName, 'Site Engineer');
      expect(reconstructed.changes.length, 1);
      expect(reconstructed.changes.first['parameter'], 'Divisi 6.3 AC-WC');
      expect(reconstructed.changes.first['oldValue'], '95.50 Ton');
      expect(reconstructed.changes.first['newValue'], '102.30 Ton');
      expect(reconstructed.metadata['nomorAddendum'], '01');
    });
  });

  group('TimelineProvider Audit Trail & Role Isolation Tests', () {
    late TimelineProvider timelineProv;
    late UserProfileProvider userProfileProv;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      timelineProv = TimelineProvider();
      await timelineProv.loadEvents();
      await _seedProjectAuditEvents(timelineProv);
      userProfileProv = UserProfileProvider();
    });

    test('Empty initial TimelineProvider does not auto-seed dummy MT Haryono and logged events stay newest-first across reload', () async {
      expect(timelineProv.allEvents.length, 6);
      // Verify descending order
      for (int i = 0; i < timelineProv.allEvents.length - 1; i++) {
        expect(
          timelineProv.allEvents[i].timestamp.isAfter(timelineProv.allEvents[i + 1].timestamp) ||
              timelineProv.allEvents[i].timestamp.isAtSameMomentAs(timelineProv.allEvents[i + 1].timestamp),
          true,
        );
      }

      // Reload pada instance provider baru: histori tetap ada dan tidak hilang
      final reloadedProv = TimelineProvider();
      await reloadedProv.loadEvents();
      expect(reloadedProv.allEvents.length, 6);
      expect(
        reloadedProv.allEvents.any((e) => e.title.contains('Addendum 01')),
        isTrue,
      );
    });

    test('1. Konsultan has full visibility across all project events', () {
      userProfileProv.loginAs(const RegisteredUser(
        username: 'konsultan',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'CV. Tata Saka Consultant',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));
      expect(userProfileProv.isKonsultan, true);

      final konsultanEvents = timelineProv.getFilteredEvents(userProfile: userProfileProv);
      expect(konsultanEvents.length, timelineProv.allEvents.length);

      // Konsultan sees Ruas Jalan A, Ruas Jalan B, and Contract level events
      expect(konsultanEvents.any((e) => e.kegiatanName == 'Ruas Jalan A'), true);
      expect(konsultanEvents.any((e) => e.kegiatanName == 'Ruas Jalan B'), true);
      expect(konsultanEvents.any((e) => e.entityType == 'KONTRAK'), true);
    });

    test('2. Kontraktor ONLY sees events related to their assigned activity, isolating other contractors', () {
      userProfileProv.loginAs(const RegisteredUser(
        username: 'kontraktor1',
        password: 'password123',
        role: 'Kontraktor',
        namaLengkap: 'Restu (CV. Divan)',
        companyOrAgency: 'CV. Divan Insan Cemerlang',
      ));
      expect(userProfileProv.isKontraktor, true);
      expect(userProfileProv.companyOrAgency, 'CV. Divan Insan Cemerlang');

      final contractorEvents = timelineProv.getFilteredEvents(userProfile: userProfileProv);
      expect(contractorEvents.isNotEmpty, true);

      // Must see their own activity events
      expect(
        contractorEvents.every(
          (e) => (e.kontraktorName ?? '').toLowerCase().contains('divan') ||
              (e.kegiatanName ?? '').toLowerCase().contains('ruas jalan a'),
        ),
        true,
      );

      // Must NOT see events from other contractors (CV. Langgeng / Ruas Jalan B)
      expect(contractorEvents.any((e) => (e.kontraktorName ?? '').contains('Langgeng')), false);
      expect(contractorEvents.any((e) => (e.kegiatanName ?? '') == 'Ruas Jalan B'), false);

      // Contractor CAN see summary events of daily/weekly reports for their activity
      expect(contractorEvents.any((e) => e.entityType == 'LAPORAN_HARIAN' || e.entityType == 'LAPORAN_MINGGUAN'), true);
    });

    test('3. Dinas sees events under its agency authority', () {
      userProfileProv.loginAs(const RegisteredUser(
        username: 'dinas',
        password: 'password123',
        role: 'Dinas',
        namaLengkap: 'Dinas PU Kab. Purbalingga',
        companyOrAgency: 'DPU-PR Kab. Purbalingga',
      ));
      expect(userProfileProv.isDinas, true);

      final dinasEvents = timelineProv.getFilteredEvents(userProfile: userProfileProv);
      expect(dinasEvents.isNotEmpty, true);
      expect(dinasEvents.every((e) => (e.dinasName ?? '').toLowerCase().contains('dpu-pr')), true);
    });

    test('4. Fast Category Filter isolates specific activity categories', () {
      userProfileProv.loginAs(const RegisteredUser(
        username: 'konsultan',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'CV. Tata Saka Consultant',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));

      // Filter by 'Addendum (CCO)'
      final ccoEvents = timelineProv.getFilteredEvents(
        userProfile: userProfileProv,
        category: 'Addendum (CCO)',
      );
      expect(ccoEvents.isNotEmpty, true);
      expect(ccoEvents.every((e) => e.category == 'Addendum (CCO)'), true);

      // Filter by 'Laporan'
      final reportEvents = timelineProv.getFilteredEvents(
        userProfile: userProfileProv,
        category: 'Laporan',
      );
      expect(reportEvents.isNotEmpty, true);
      expect(reportEvents.every((e) => e.category == 'Laporan'), true);

      // Filter by 'RAB / BoQ'
      final rkkEvents = timelineProv.getFilteredEvents(
        userProfile: userProfileProv,
        category: 'RAB / BoQ',
      );
      expect(rkkEvents.isNotEmpty, true);
      expect(rkkEvents.every((e) => e.category == 'RAB / BoQ'), true);
    });

    test('5. Search Query filters by title, description, or Opsi A parameter changes', () {
      userProfileProv.loginAs(const RegisteredUser(
        username: 'konsultan',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'CV. Tata Saka Consultant',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));

      // Search by parameter in Opsi A changes: 'AC-WC'
      final searchResult = timelineProv.getFilteredEvents(
        userProfile: userProfileProv,
        searchQuery: 'AC-WC',
      );
      expect(searchResult.isNotEmpty, true);
      expect(searchResult.first.entityType, 'ADDENDUM');

      // Search non-existent keyword
      final emptyResult = timelineProv.getFilteredEvents(
        userProfile: userProfileProv,
        searchQuery: 'XYZ_NON_EXISTENT_9999',
      );
      expect(emptyResult.isEmpty, true);
    });

    test('6. logEvent adds a new event and updates persistence', () async {
      userProfileProv.loginAs(const RegisteredUser(
        username: 'konsultan',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'CV. Tata Saka Consultant',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));
      final beforeCount = timelineProv.allEvents.length;

      await timelineProv.logEvent(
        actorName: 'CV. Tata Saka Consultant',
        actionType: 'CREATE',
        entityType: 'LAPORAN_HARIAN',
        contractId: 'kontrak-ruas-uji-01',
        contractName: 'PENGAWASAN JALAN PAKET UJI',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        title: 'Buku Harian Standar #25: Ruas Jalan A',
        description: 'Pekerjaan perkerasan bahu jalan STA 1+000.',
      );

      expect(timelineProv.allEvents.length, beforeCount + 1);
      expect(timelineProv.allEvents.first.title, 'Buku Harian Standar #25: Ruas Jalan A');
    });
  });

  group('TimelineScreen UI & Opsi A Widget Tests', () {
    Future<Widget> createWidgetUnderTest({
      String role = 'konsultan',
      bool isDark = false,
    }) async {
      final contractProv = ContractProvider();
      final userProfileProv = UserProfileProvider();
      if (role == 'kontraktor1') {
        userProfileProv.loginAs(const RegisteredUser(
          username: 'kontraktor1',
          password: 'password123',
          role: 'Kontraktor',
          namaLengkap: 'CV. Divan Insan Cemerlang',
          companyOrAgency: 'CV. Divan Insan Cemerlang',
        ));
      } else {
        userProfileProv.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));
      }
      if (isDark) {
        userProfileProv.setThemeMode('Gelap');
      }

      final timelineProv = TimelineProvider();
      await timelineProv.loadEvents();
      await _seedProjectAuditEvents(timelineProv);

      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ContractProvider>.value(value: contractProv),
          ChangeNotifierProvider<UserProfileProvider>.value(value: userProfileProv),
          ChangeNotifierProvider<TimelineProvider>.value(value: timelineProv),
        ],
        child: MaterialApp(
          theme: isDark ? ThemeData.dark() : ThemeData.light(),
          home: const TimelineScreen(),
        ),
      );
    }

    testWidgets('TimelineScreen renders header, fast filter chips, and timeline items', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 900));
      await tester.pumpWidget(await createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Kronologi Proyek'), findsOneWidget);

      // Verify Filter Chips
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Kontrak & Kegiatan'), findsOneWidget);
      expect(find.text('RAB / BoQ'), findsOneWidget);

      // Verify at least one group header and event card are present
      expect(find.textContaining('2026'), findsWidgets);
    });

    testWidgets('Tapping category filter chip filters the visible timeline cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(await createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 'Addendum (CCO)' category chip (using .first to pick the filter chip)
      final ccoChip = find.text('Addendum (CCO)').first;
      expect(ccoChip, findsOneWidget);
      await tester.tap(ccoChip);
      await tester.pumpAndSettle();

      // Should find Addendum title
      expect(find.textContaining('Addendum 01'), findsOneWidget);

      // Should NOT find unrelated daily report in this filtered state
      expect(find.textContaining('Buku Harian Standar #08'), findsNothing);
    });

    testWidgets('Opsi A: Tapping "Lihat Detail Perubahan" opens before vs after comparison modal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      await tester.pumpWidget(await createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Filter to Addendum
      await tester.tap(find.text('Addendum (CCO)').first);
      await tester.pumpAndSettle();

      // Find button "Lihat Detail Perubahan"
      final btnDetailPerubahan = find.text('Lihat Detail Perubahan');
      expect(btnDetailPerubahan, findsOneWidget);

      // Tap it
      await tester.tap(btnDetailPerubahan);
      await tester.pumpAndSettle();

      // Modal Title
      expect(find.text('Detail Perubahan Data'), findsOneWidget);

      // Verify Opsi A parameter comparison
      expect(find.text('Divisi 3.1 Galian Biasa'), findsOneWidget);
      expect(find.text('Sebelumnya'), findsWidgets);
      expect(find.text('Menjadi'), findsWidgets);
      expect(find.text('210.00 m3'), findsOneWidget);
      expect(find.text('245.00 m3 (+35.00 m3)'), findsOneWidget);

      // Close modal
      final btnTutup = find.text('Tutup');
      expect(btnTutup, findsOneWidget);
      await tester.tap(btnTutup);
      await tester.pumpAndSettle();

      expect(find.text('Detail Perubahan Data'), findsNothing);
    });

    testWidgets('Dark Mode renders cleanly without any overflow or unhandled exceptions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 720)); // Narrow screen test
      await tester.pumpWidget(await createWidgetUnderTest(isDark: true));
      await tester.pumpAndSettle();

      expect(find.text('Kronologi Proyek'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Kontraktor role only sees their own activities in Timeline', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      await tester.pumpWidget(await createWidgetUnderTest(role: 'kontraktor1'));
      await tester.pumpAndSettle();

      // Ruas Jalan A should be present
      expect(find.textContaining('Ruas Jalan A'), findsWidgets);

      // Ruas Jalan B (CV. Langgeng) MUST NOT be present
      expect(find.textContaining('Ruas Jalan B'), findsNothing);
      expect(find.textContaining('CV. Langgeng'), findsNothing);
    });
  });
}
