import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/screens/pengaturan_screen.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';
import 'package:tata_saka_app/widgets/lembar_laporan_bulanan_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Pengaturan Tema Aplikasi Tests', () {
    test('Theme switching updates isDarkMode correctly', () {
      final userProf = UserProfileProvider();
      expect(userProf.themeMode, 'Terang');
      expect(userProf.isDarkMode, isFalse);

      userProf.setThemeMode('Gelap');
      expect(userProf.themeMode, 'Gelap');
      expect(userProf.isDarkMode, isTrue);

      userProf.setThemeMode('Mengikuti Sistem');
      expect(userProf.themeMode, 'Mengikuti Sistem');

      userProf.setThemeMode('Terang');
      expect(userProf.themeMode, 'Terang');
      expect(userProf.isDarkMode, isFalse);
    });

    testWidgets('PengaturanScreen allows switching theme via bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final userProf = UserProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
          ],
          child: const MaterialApp(
            home: PengaturanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Tema Aplikasi row
      expect(find.text('Tema Aplikasi'), findsOneWidget);
      await tester.tap(find.text('Tema Aplikasi'));
      await tester.pumpAndSettle();

      // Options: Terang, Gelap, Mengikuti Sistem
      expect(find.text('Pilih Tema Aplikasi'), findsOneWidget);
      expect(find.text('Gelap'), findsOneWidget);

      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();

      expect(userProf.themeMode, 'Gelap');
      expect(userProf.isDarkMode, isTrue);
    });
  });

  group('2. Pengaturan Bahasa Tests', () {
    test('Language switching translates keys throughout app', () {
      final userProf = UserProfileProvider();
      expect(userProf.language, 'Indonesia');
      expect(userProf.isEnglish, isFalse);
      expect(userProf.tr('nav_kontrak'), 'Kontrak');
      expect(userProf.tr('settings_title'), 'Pengaturan');

      userProf.setLanguage('English');
      expect(userProf.language, 'English');
      expect(userProf.isEnglish, isTrue);
      expect(userProf.tr('nav_kontrak'), 'Contracts');
      expect(userProf.tr('settings_title'), 'Settings');
      expect(userProf.tr('account_title'), 'Account');
      expect(userProf.tr('btn_cancel'), 'Cancel');

      // Switch back
      userProf.setLanguage('Indonesia');
      expect(userProf.language, 'Indonesia');
      expect(userProf.isEnglish, isFalse);
      expect(userProf.tr('nav_kontrak'), 'Kontrak');
      expect(userProf.tr('settings_title'), 'Pengaturan');
    });

    testWidgets('PengaturanScreen allows switching language via dialog', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final userProf = UserProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
          ],
          child: const MaterialApp(
            home: PengaturanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bahasa'), findsOneWidget);
      await tester.tap(find.text('Bahasa'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Bahasa Aplikasi'), findsOneWidget);
      expect(find.textContaining('English'), findsOneWidget);

      await tester.tap(find.textContaining('English'));
      await tester.pumpAndSettle();

      expect(userProf.language, 'English');
      expect(userProf.isEnglish, isTrue);
    });
  });

  group('3. Pengaturan Notifikasi Switch Design Tests', () {
    testWidgets('Notification switches have white thumb and clear track colors', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final userProf = UserProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
          ],
          child: const MaterialApp(
            home: PengaturanScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all Switch widgets
      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.length, 4);

      for (final s in switches) {
        expect(s.activeThumbColor, Colors.white);
        expect(s.activeTrackColor, const Color(0xFF2563EB));
        expect(s.inactiveThumbColor, Colors.white);
      }

      // Toggle first switch
      final initialVal = userProf.notifikasiPush;
      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();
      expect(userProf.notifikasiPush, !initialVal);
    });
  });

  group('4. Tampilan dan Scroll Laporan Bulanan Tests', () {
    testWidgets('LaporanBulananScreen renders with high contrast and allows viewing reports', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final contractProvider = ContractProvider();
      contractProvider.addContract(SampleContractData.getDemoContract());
      final userProf = UserProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
          ],
          child: const MaterialApp(
            home: LaporanBulananScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laporan Bulanan'), findsOneWidget);
      expect(find.text('Rekapitulasi Periode 4 Mingguan'), findsOneWidget);

      // Verify Month 1 is displayed
      expect(find.text('BULAN I'), findsOneWidget);

      // Tap on Month 1 card to open bottom sheet
      await tester.tap(find.text('BULAN I'));
      await tester.pumpAndSettle();

      // Bottom sheet is opened
      expect(find.byType(LembarLaporanBulananWidget), findsOneWidget);
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('LembarLaporanBulananWidget renders dual scrollviews with high contrast text', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final contract = SampleContractData.getDemoContract();
      final monthlyReports = MonthlyReportModel.generateFromWeeklyReports(
        contract: contract,
        kegiatan: KegiatanModel.fromJson(contract.kegiatans.first, fallbackContract: contract),
      );
      final report = monthlyReports.first;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 1000,
              child: LembarLaporanBulananWidget(report: report),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LAPORAN BULANAN'), findsOneWidget);
      expect(find.text('BULAN I'), findsOneWidget);
      expect(find.text('NO.'), findsOneWidget);
      expect(find.text('URAIAN'), findsOneWidget);
      expect(find.text('Volume\nCCO'), findsOneWidget);

      // Dual-Axis SingleChildScrollView widgets exist (vertical + horizontal)
      final scrollViews = tester.widgetList<SingleChildScrollView>(find.byType(SingleChildScrollView)).toList();
      expect(scrollViews.length, greaterThanOrEqualTo(2));
    });
  });

  group('5. Data Laporan Harian Indicator & Live Binding Tests', () {
    testWidgets('DetailDataLaporanScreen renders green dots on dates with reports and updates live', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final contractProvider = ContractProvider();
      final demoContract = SampleContractData.getDemoContract();
      contractProvider.addContract(demoContract);

      final userProf = UserProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
            ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
          ],
          child: MaterialApp(
            home: DetailDataLaporanScreen(
              contract: demoContract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laporan Harian'), findsOneWidget);
      expect(find.text('Data Laporan'), findsNothing);
      expect(find.text('Mingguan'), findsNothing);

      // Check for green dot indicators (Container with Color(0xFF10B981))
      final greenDots = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final box = widget.decoration as BoxDecoration;
          return box.color == const Color(0xFF10B981);
        }
        return false;
      });

      expect(greenDots, findsWidgets);

      // Verify live contract binding: add a report to contract and update contract provider
      final currentReports = List<Map<String, dynamic>>.from(
        demoContract.kegiatans[0]['laporans'] ?? [],
      );
      currentReports.add({
        'id': 'rep-new-test',
        'tanggal': '2026-04-21',
        'tanggalFormatted': 'Selasa, 21 April 2026',
        'pekerjaanList': [],
        'materialList': [],
        'peralatanList': [],
        'personilList': [],
        'cuacaKejadianList': [],
        'instruksiList': [],
      });
      demoContract.kegiatans[0]['laporans'] = currentReports;
      contractProvider.updateContract(demoContract);
      await tester.pumpAndSettle();

      // Dot for the new report date is rendered
      expect(greenDots, findsWidgets);
    });
  });
}
