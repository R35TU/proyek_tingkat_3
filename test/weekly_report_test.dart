import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/widgets/lembar_laporan_mingguan_widget.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/screens/buat_laporan_mingguan_screen.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/laporan_mingguan_screen.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';

void main() {
  group('WeeklyReportModel Calculations & Parsing Tests', () {
    test('Sample document matches photo numbers exactly', () {
      final sample = WeeklyReportModel.sampleDocument();

      expect(sample.pekerjaan, 'PEMELIHARAAN BERKALA JALAN LETJEND MT. HARYONO');
      expect(sample.lokasiProyek, 'KEC. PURBALINGGA');
      expect(sample.kontraktor, 'PT. ANDHIKA BANGUNAN PERKASA');
      expect(sample.jangkaWaktu, 90);
      expect(sample.nomorKontrak, '000.3.3/ 1128 /KONST/BM/IV/2026');
      expect(sample.tanggalKontrak, '20 April 2026');
      expect(sample.tanggalSpmk, '20 April 2026');
      expect(sample.mingguKe, 6);
      expect(sample.totalMinggu, 13);
      expect(sample.periodeAwal, '24 Mei 2026');
      expect(sample.periodeAkhir, '30 Mei 2026');
      expect(sample.rencanaPersen, 1.433);
      expect(sample.rencanaNominal, 42990000.0);
      expect(sample.realisasiPersen, 6.930);
      expect(sample.realisasiNominal, 207900000.0);
      expect(sample.deviasiPersen, closeTo(5.497, 0.001));
      expect(sample.deviasiNominal, closeTo(164910000.0, 1.0));
      expect(sample.waktuTerpakai, 41);
      expect(sample.sisaWaktu, 49);
      expect(sample.akhirMasaKontrak, '18 Juli 2026');
    });

    test('RupiahUtil smart parsing and auto formatting tests', () {
      // 1. Raw digits
      expect(RupiahUtil.parseToDouble('3000000000'), 3000000000.0);
      expect(RupiahUtil.formatString('3000000000'), '3.000.000.000');

      // 2. Dots already present
      expect(RupiahUtil.parseToDouble('3.000.000.000'), 3000000000.0);
      expect(RupiahUtil.formatString('3.000.000.000'), '3.000.000.000');

      // 3. Random/misplaced dots e.g. 3.00.00.00.00.0
      expect(RupiahUtil.parseToDouble('3.00.00.00.00.0'), 3000000000.0);
      expect(RupiahUtil.formatString('3.00.00.00.00.0'), '3.000.000.000');

      // 4. Currency prefix & suffixes
      expect(RupiahUtil.parseToDouble('Rp 3.000.000.000,00'), 3000000000.0);
      expect(RupiahUtil.parseToDouble('Rp 3.000.000.000 (Termasuk PPN+PPH)'), 3000000000.0);
      expect(RupiahUtil.formatWithRp(3000000000), 'Rp 3.000.000.000');
    });

    test('Indonesian currency & percentage formatting', () {
      expect(WeeklyReportModel.parseRupiah('Rp 3.000.000.000,00'), 3000000000.0);
      expect(WeeklyReportModel.formatPercent(1.433, decimalDigits: 2), '1,43 %');
      expect(WeeklyReportModel.formatPercent(5.497, decimalDigits: 2, showSign: true), '+5,50 %');
      expect(WeeklyReportModel.formatPercent(-0.074, decimalDigits: 3, showSign: true), '-0,074 %');
    });

    test('Serialization to and from JSON', () {
      final sample = WeeklyReportModel.sampleDocument();
      final json = sample.toJson();
      final restored = WeeklyReportModel.fromJson(json);

      expect(restored.mingguKe, sample.mingguKe);
      expect(restored.tabelMingguan.length, sample.tabelMingguan.length);
      expect(restored.deviasiPersen, closeTo(sample.deviasiPersen, 0.001));
    });
  });

  group('LembarLaporanMingguanWidget UI Tests', () {
    testWidgets('Renders authentic document headers and highlighted week row', (tester) async {
      final sample = WeeklyReportModel.sampleDocument();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LembarLaporanMingguanWidget(report: sample),
            ),
          ),
        ),
      );

      // Verify title and metadata
      expect(find.text('RINGKASAN KEGIATAN MINGGUAN'), findsOneWidget);
      expect(find.text('PEKERJAAN'), findsOneWidget);
      expect(find.text('LOKASI PROYEK'), findsOneWidget);
      expect(find.text('KONTRAKTOR PELAKSANA'), findsOneWidget);
      expect(find.text('JANGKA WAKTU KONTRAK'), findsOneWidget);
      expect(find.text('NOMOR KONTRAK'), findsOneWidget);
      expect(find.text('TANGGAL KONTRAK'), findsOneWidget);
      expect(find.text('NILAI KONTRAK'), findsOneWidget);
      expect(find.text('TANGGAL SPMK'), findsOneWidget);
      expect(find.text('LAPORAN MINGGU KE -'), findsOneWidget);
      expect(find.text('PERIODE'), findsWidgets);
      expect(find.text('RENCANA FISIK S/D MINGGU INI'), findsOneWidget);
      expect(find.text('REALISASI FISIK S/D MINGGU INI'), findsOneWidget);
      expect(find.text('DEVIASI (+/-)'), findsOneWidget);
      expect(find.text('WAKTU TERPAKAI'), findsOneWidget);
      expect(find.text('SISA WAKTU'), findsOneWidget);
      expect(find.text('AKHIR MASA KONTRAK'), findsOneWidget);
    });
  });

  group('BuatLaporanMingguanScreen UI Tests', () {
    testWidgets('Form renders interactive controls and syncs calculations', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ContractProvider(),
          child: const MaterialApp(
            home: BuatLaporanMingguanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Ringkasan Laporan Mingguan'), findsWidgets);
      expect(find.text('Form Input'), findsOneWidget);
      expect(find.text('Pratinjau Dokumen Fisik'), findsOneWidget);
    });

    testWidgets('Form renders without overflow on narrow 360px screen', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      FlutterErrorDetails? errorDetails;
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (d) {
        errorDetails = d;
      };

      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ContractProvider(),
          child: const MaterialApp(
            home: BuatLaporanMingguanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();
      FlutterError.onError = oldOnError;

      if (errorDetails != null) {
        // ignore: avoid_print
        print('EXACT ERROR:\n${errorDetails!.toString()}');
      }
      expect(errorDetails, isNull);
    });

    testWidgets('Table is automatically generated and compiles cumulative weekly schedule', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => ContractProvider(),
          child: const MaterialApp(
            home: BuatLaporanMingguanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify integrated contract data card is rendered on Form Input tab
      expect(find.text('Data Pokok Kontrak Kegiatan'), findsOneWidget);
      expect(find.text('Terintegrasi'), findsWidgets);

      // Tap on 'Pratinjau Dokumen Fisik'
      await tester.tap(find.text('Pratinjau Dokumen Fisik'));
      await tester.pumpAndSettle();

      // Physical document preview displays the full table
      expect(find.text('RINGKASAN KEGIATAN MINGGUAN'), findsOneWidget);
      expect(find.text('STATUS\nKONTRAK/\nADDENDUM'), findsOneWidget);
      expect(find.text('MINGGU\nKE -'), findsOneWidget);
    });
  });

  group('LaporanMingguanScreen & Daily UI Tests', () {
    testWidgets('Renders weekly report list and detail without overflow on 360px screen', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleWeekly = WeeklyReportModel.sampleDocument();
      final contract = ContractModel(
        id: 'test-contract',
        jenisKegiatan: 'Pengawasan Teknis',
        namaKontrak: 'PEMELIHARAAN BERKALA JALAN LETJEND MT. HARYONO',
        nomorSpk: '000.3.3/ 1128 /KONST/BM/IV/2026',
        tglMulaiSpk: '19 April 2026',
        nomorSpmk: '000.3.3/ 1128 /KONST/BM/IV/2026',
        tglMulaiSpmk: '19 April 2026',
        tglSelesaiSpmk: '17 Juli 2026',
        hariKalender: 90,
        nilaiKontrak: 'Rp 3.000.000.000,00',
        instansiDinas: ['DPUPR Purbalingga'],
        sumberDana: 'APBD Kab. Purbalingga',
        deskripsi: 'Pekerjaan Pemeliharaan Berkala',
        progressFisik: 0.0693,
        kegiatans: [
          {
            'namaKegiatan': 'Pemeliharaan Berkala Jalan Letjend MT. Haryono',
            'lokasi': 'KEC. PURBALINGGA',
            'kontraktor': 'PT. ANDHIKA BANGUNAN PERKASA',
            'laporans': [],
            'laporanMingguan': [sampleWeekly.toJson()],
          },
        ],
      );

      SharedPreferences.setMockInitialValues({});
      final provider = ContractProvider();
      await provider.addContract(contract);
      final userProf = UserProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: userProf),
          ],
          child: MaterialApp(
            home: LaporanMingguanScreen(
              initialContract: contract,
              initialKegiatanIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Minggu 6'),
        220,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Minggu 6'), findsOneWidget);
      expect(find.text('Buka'), findsWidgets);
      await tester.tap(find.text('Minggu 6'));
      await tester.pumpAndSettle();
      expect(find.text('RINGKASAN KEGIATAN MINGGUAN'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders LaporanMingguanScreen and daily DetailDataLaporanScreen without overflow on 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleWeekly = WeeklyReportModel.sampleDocument();
      final contract = ContractModel(
        id: 'test-contract',
        jenisKegiatan: 'Pengawasan Teknis',
        namaKontrak: 'PEMELIHARAAN BERKALA JALAN LETJEND MT. HARYONO',
        nomorSpk: '000.3.3/ 1128 /KONST/BM/IV/2026',
        tglMulaiSpk: '19 April 2026',
        nomorSpmk: '000.3.3/ 1128 /KONST/BM/IV/2026',
        tglMulaiSpmk: '19 April 2026',
        tglSelesaiSpmk: '17 Juli 2026',
        hariKalender: 90,
        nilaiKontrak: 'Rp 3.000.000.000,00',
        instansiDinas: ['DPUPR Purbalingga'],
        sumberDana: 'APBD Kab. Purbalingga',
        deskripsi: 'Pekerjaan Pemeliharaan Berkala',
        progressFisik: 0.0693,
        kegiatans: [
          {
            'namaKegiatan': 'Pemeliharaan Berkala Jalan Letjend MT. Haryono',
            'lokasi': 'KEC. PURBALINGGA',
            'kontraktor': 'PT. ANDHIKA BANGUNAN PERKASA',
            'laporans': [],
            'laporanMingguan': [sampleWeekly.toJson()],
          },
        ],
      );

      SharedPreferences.setMockInitialValues({});
      final provider = ContractProvider();
      await provider.addContract(contract);
      final userProf = UserProfileProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: userProf),
          ],
          child: MaterialApp(
            home: LaporanMingguanScreen(
              initialContract: contract,
              initialKegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
            ChangeNotifierProvider.value(value: userProf),
          ],
          child: MaterialApp(
            home: DetailDataLaporanScreen(
              contract: contract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mingguan'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

