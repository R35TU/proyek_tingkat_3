import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';
import 'package:tata_saka_app/widgets/lembar_laporan_bulanan_widget.dart';

void main() {
  group('MonthlyReportModel Unit & Calculation Tests', () {
    test('generateFromWeeklyReports correctly groups 4-week chunks and compiles CCO progress', () {
      final contract = SampleContractData.getDemoContract();
      final kegMap = contract.kegiatans[0];

      final reports = MonthlyReportModel.generateFromWeeklyReports(
        contract: contract,
        kegiatan: kegMap,
      );

      // Proyek MT Haryono adalah 13 minggu -> harus terbagi menjadi 4 periode bulan (1-4, 5-8, 9-12, 13)
      expect(reports.length, 4);

      // 1. Bulan I (Minggu 1 - 4) - Data lengkap 4 minggu
      final b1 = reports[0];
      expect(b1.bulanKe, 1);
      expect(b1.bulanRomawi, 'I');
      expect(b1.mingguMulai, 1);
      expect(b1.mingguSelesai, 4);
      expect(b1.status, 'Selesai');
      expect(b1.statusDetail, contains('Lengkap (M-1 s.d. M-4)'));
      expect(b1.mingguTersedia.length, 4);

      // Realisasi kumulatif s/d M-4 adalah 40.776%
      expect((b1.realisasiKumulatifPersen - 40.776).abs() < 0.05, isTrue);
      // Bulan 1 bulan lalu harus 0
      expect(b1.totalBobotBulanLalu, 0.0);
      expect((b1.totalBobotBulanIni - 41.050).abs() < 0.05, isTrue);
      expect((b1.totalBobotSdBulanIni - 41.050).abs() < 0.05, isTrue);
      expect((b1.totalBobotSisa - (100.0 - 41.050)).abs() < 0.05, isTrue);

      // 2. Bulan II (Minggu 5 - 8) - Sedang Berjalan (baru ada Minggu 5)
      final b2 = reports[1];
      expect(b2.bulanKe, 2);
      expect(b2.bulanRomawi, 'II');
      expect(b2.mingguMulai, 5);
      expect(b2.mingguSelesai, 8);
      expect(b2.status, 'Sedang Berjalan');
      expect(b2.statusDetail, 'Sedang Berjalan (M-5)');
      expect(b2.mingguTersedia.length, 1);

      // Realisasi kumulatif s/d M-5 adalah 53.865%
      expect((b2.realisasiKumulatifPersen - 53.865).abs() < 0.05, isTrue);
      // Bulan lalu (s/d M-4) harus 41.050%
      expect((b2.totalBobotBulanLalu - 41.050).abs() < 0.05, isTrue);
      // Bulan ini murni minggu 5 (Lapen 15 m3 = 13.090%)
      expect((b2.totalBobotBulanIni - 13.090).abs() < 0.05, isTrue);
      // S/D Bulan Ini = 54.140%
      expect((b2.totalBobotSdBulanIni - (41.050 + 13.090)).abs() < 0.05, isTrue);
      expect((b2.totalBobotSisa - (100.0 - (41.050 + 13.090))).abs() < 0.05, isTrue);

      // 3. Bulan III & IV - Belum Ada Data
      final b3 = reports[2];
      expect(b3.status, 'Belum Ada Data');
      expect(b3.mingguTersedia.isEmpty, isTrue);

      final b4 = reports[3];
      expect(b4.status, 'Belum Ada Data');
      expect(b4.mingguMulai, 13);
      expect(b4.mingguSelesai, 13);
    });

    test('Mathematical identity holds for every month BoQ items', () {
      final contract = SampleContractData.getDemoContract();
      final kegMap = contract.kegiatans[0];

      final reports = MonthlyReportModel.generateFromWeeklyReports(
        contract: contract,
        kegiatan: kegMap,
      );

      for (final report in reports) {
        // Jumlah CCO mendekati 100%
        expect((report.totalBobotCCO - 100.0).abs() < 0.1, isTrue);

        // Identitas: Bulan Lalu + Bulan Ini = S/D Bulan Ini
        final sumLaluIni = report.totalBobotBulanLalu + report.totalBobotBulanIni;
        expect((sumLaluIni - report.totalBobotSdBulanIni).abs() < 0.05, isTrue);

        // Identitas: S/D Bulan Ini + Sisa = Total Bobot CCO
        final sumSdSisa = report.totalBobotSdBulanIni + report.totalBobotSisa;
        expect((sumSdSisa - report.totalBobotCCO).abs() < 0.05, isTrue);

        // Rincian per item
        for (final div in report.divisions) {
          for (final it in div.items) {
            expect((it.bobotBulanLalu + it.bobotBulanIni - it.bobotSdBulanIni).abs() < 0.01, isTrue);
            expect((it.bobotSdBulanIni + it.sisaBobot - it.bobotCCO).abs() < 0.01, isTrue);
            expect(it.sisaVolume >= 0.0, isTrue);
          }
        }
      }
    });
  });

  group('Laporan Bulanan Widget & Screen UI Tests', () {
    testWidgets('LembarLaporanBulananWidget renders authentic document headers, table, and summary without error', (tester) async {
      final contract = SampleContractData.getDemoContract();
      final kegMap = contract.kegiatans[0];

      final reports = MonthlyReportModel.generateFromWeeklyReports(
        contract: contract,
        kegiatan: kegMap,
      );

      final reportBulan1 = reports[0];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LembarLaporanBulananWidget(
              report: reportBulan1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check Title
      expect(find.text('LAPORAN BULANAN'), findsOneWidget);
      expect(find.text('BULAN I'), findsOneWidget);

      // Check Metadata
      expect(find.text('Pekerjaan'), findsOneWidget);
      expect(find.text('CV. DIVAN INSAN CEMERLANG'), findsWidgets);

      // Check Table headers
      expect(find.text('NO.'), findsOneWidget);
      expect(find.text('URAIAN'), findsOneWidget);
      expect(find.text('Volume\nCCO'), findsOneWidget);
      expect(find.text('BULAN LALU'), findsWidgets);
      expect(find.text('BULAN INI'), findsWidgets);
      expect(find.text('S/D BULAN INI'), findsWidgets);
      expect(find.text('Sisa Pekerjaan'), findsWidgets);

      // Check Summary at bottom
      expect(find.text('Rencana Pekerjaan'), findsOneWidget);
      expect(find.text('Realisasi Pekerjaan'), findsOneWidget);
      expect(find.text('Deviasi'), findsOneWidget);

      // Check PDF button exists
      expect(find.text('PDF'), findsOneWidget);
    });

    testWidgets('LaporanBulananScreen renders project overview and month cards', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final contract = SampleContractData.getDemoContract();
      final provider = ContractProvider();
      provider.addContract(contract);

      await tester.pumpWidget(
        ChangeNotifierProvider<ContractProvider>.value(
          value: provider,
          child: MaterialApp(
            home: LaporanBulananScreen(
              initialContract: contract,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check AppBar
      expect(find.text('Laporan Bulanan'), findsOneWidget);

      // Check Month Cards
      expect(find.text('BULAN I'), findsOneWidget);
      expect(find.text('BULAN II'), findsOneWidget);
      expect(find.text('BULAN III'), findsOneWidget);

      // Check Status chips
      expect(find.text('Selesai'), findsOneWidget);
      expect(find.text('Sedang Berjalan'), findsOneWidget);

      // Tap on Bulan I to open modal
      await tester.tap(find.text('BULAN I'));
      await tester.pumpAndSettle();

      // Modal is open
      expect(find.text('Lembar Laporan Bulanan (Bulan I)'), findsOneWidget);
      expect(find.text('LAPORAN BULANAN'), findsOneWidget);
      expect(find.textContaining('Lengkap'), findsOneWidget);
    });
  });
}
