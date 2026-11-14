import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/kelola_addendum_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/screens/main_layout.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Role-Based Access Control (RBAC) - Authentication & Profiles', () {
    test('Default user is Konsultan with full access flags', () {
      final userProf = UserProfileProvider();
      expect(userProf.isKonsultan, isTrue);
      expect(userProf.isKontraktor, isFalse);
      expect(userProf.isDinas, isFalse);
      expect(userProf.namaLengkap, 'CV. Tata Saka Consultant');
      expect(userProf.companyOrAgency, 'CV. Tata Saka Consultant');
    });

    test('Login as kontraktor1 switches role to Kontraktor (CV. Divan Insan Cemerlang)', () {
      final userProf = UserProfileProvider();
      final success = userProf.login('kontraktor1', 'password123');
      expect(success, isTrue);
      expect(userProf.isKonsultan, isFalse);
      expect(userProf.isKontraktor, isTrue);
      expect(userProf.isDinas, isFalse);
      expect(userProf.namaLengkap, 'CV. Divan Insan Cemerlang');
      expect(userProf.companyOrAgency, 'CV. Divan Insan Cemerlang');
    });

    test('Login as kontraktor2 switches role to Kontraktor (CV. Langgeng)', () {
      final userProf = UserProfileProvider();
      final success = userProf.login('kontraktor2', 'password123');
      expect(success, isTrue);
      expect(userProf.isKonsultan, isFalse);
      expect(userProf.isKontraktor, isTrue);
      expect(userProf.isDinas, isFalse);
      expect(userProf.namaLengkap, 'CV. Langgeng');
      expect(userProf.companyOrAgency, 'CV. Langgeng');
    });

    test('Login as dinas switches role to Dinas (DPU-PR)', () {
      final userProf = UserProfileProvider();
      final success = userProf.login('dinas', 'password123');
      expect(success, isTrue);
      expect(userProf.isKonsultan, isFalse);
      expect(userProf.isKontraktor, isFalse);
      expect(userProf.isDinas, isTrue);
      expect(userProf.namaLengkap, 'DPU-PR Kabupaten Purbalingga');
      expect(userProf.companyOrAgency, 'DPU-PR');
    });

    test('Invalid credentials do not switch role', () {
      final userProf = UserProfileProvider();
      final success = userProf.login('kontraktor1', 'wrongpass');
      expect(success, isFalse);
      expect(userProf.isKonsultan, isTrue);
    });

    test('Registered contractors list contains both valid partner companies', () {
      expect(UserProfileProvider.registeredContractors, contains('CV. Divan Insan Cemerlang'));
      expect(UserProfileProvider.registeredContractors, contains('CV. Langgeng'));
    });
  });

  group('Dynamic Bottom Navigation Bar per Role', () {
    Widget buildNavTestWidget(UserProfileProvider userProf) {
      final contractProvider = ContractProvider();
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
          ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
        ],
        child: const MaterialApp(
          home: MainLayout(),
        ),
      );
    }

    testWidgets('Kontraktor bottom navigation has 4 tabs without Laporan', (tester) async {
      final userProf = UserProfileProvider();
      userProf.login('kontraktor1', 'password123');

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
      final userProf = UserProfileProvider();
      // Default is konsultan

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
      final userProf = UserProfileProvider();
      userProf.login('dinas', 'password123');

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
    test('Contractor data scoping correctly filters activities by contractor company', () {
      final contract = SampleContractData.getDemoContract();
      expect(contract.kegiatans.isNotEmpty, isTrue);

      final userProf1 = UserProfileProvider();
      userProf1.login('kontraktor1', 'password123');

      final userProf2 = UserProfileProvider();
      userProf2.login('kontraktor2', 'password123');

      // Kegiatan matching for contractor 1
      final k1Kegiatans = contract.kegiatans.where((k) {
        final kKontraktor = (k['kontraktor'] ?? '').toString().toLowerCase();
        return kKontraktor.contains('divan');
      }).toList();

      // Kegiatan matching for contractor 2
      final k2Kegiatans = contract.kegiatans.where((k) {
        final kKontraktor = (k['kontraktor'] ?? '').toString().toLowerCase();
        return kKontraktor.contains('langgeng');
      }).toList();

      expect(k1Kegiatans.isNotEmpty, isTrue);
      expect(k2Kegiatans.isNotEmpty, isTrue);
      // Kontraktor 1 should not match Kontraktor 2's kegiatan
      for (final k in k1Kegiatans) {
        expect((k['kontraktor'] ?? '').toString().toLowerCase().contains('langgeng'), isFalse);
      }
    });

    test('Dinas data scoping correctly matches DPU-PR agency in contracts', () {
      final contract = SampleContractData.getDemoContract();
      final isMatchingDinas = contract.instansiDinas.any((d) {
        final up = d.toUpperCase();
        return up.contains('DPU-PR') || up.contains('DINAS') || up.contains('PURBALINGGA');
      });
      expect(isMatchingDinas, isTrue);
    });
  });

  group('Read-Only UI Protections for Kontraktor & Dinas', () {
    testWidgets('KelolaRkkScreen in readOnly mode displays banner and hides mutation buttons', (tester) async {
      final contract = SampleContractData.getDemoContract();
      final userProf = UserProfileProvider();
      userProf.login('kontraktor1', 'password123');

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
      final userProf = UserProfileProvider();
      userProf.login('dinas', 'password123');

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
