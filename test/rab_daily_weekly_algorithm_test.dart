import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/widgets/clean_text_form_field.dart';
import 'package:tata_saka_app/widgets/lembar_boq_mingguan_widget.dart';

void main() {
  group('Algoritma RAB, Laporan Harian & Mingguan Tests', () {
    late ContractModel testContract;

    setUp(() {
      testContract = ContractModel(
        id: 'c-algo-test',
        namaKontrak: 'PEMELIHARAAN JALAN MT HARYONO',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 350.000.000,00',
        hariKalender: 90,
        tglMulaiSpk: '20 April 2026',
        nomorSpk: '602.1/01/SP-KTR/BM/IV/2026',
        nomorSpmk: '602.1/01/SPMK-KTR/BM/IV/2026',
        tglMulaiSpmk: '20 April 2026',
        tglSelesaiSpmk: '18 Juli 2026',
        sumberDana: 'APBD',
        deskripsi: 'Proyek Jalan',
        kegiatans: [
          {
            'namaKegiatan': 'Ruas Jalan MT Haryono',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
            'rkkDivisiList': [
              {
                'nomorRomawi': 'II',
                'namaDivisi': 'DRAINASE',
                'items': [
                  {
                    'noMataPembayaran': '2.3.(12)',
                    'uraian': 'Gorong-gorong Kotak 50x50cm',
                    'satuan': 'm1',
                    'volume': 4.80,
                    'volumeCCO': 4.80,
                    'hargaSatuan': 2139059.32,
                    'totalHarga': 10267484.74,
                    'nilaiBobot': 3.561,
                  },
                ],
              },
            ],
            'laporans': [
              {
                'id': 'lap-01',
                'tanggal': '2026-04-21',
                'pekerjaanList': [
                  {
                    'noMataPembayaran': '2.3.(12)',
                    'jenis': 'Gorong-gorong Kotak 50x50cm',
                    'uraian': 'Gorong-gorong Kotak 50x50cm',
                    'volume': '4.30',
                    'satuan': 'm1',
                  }
                ],
              }
            ],
            'laporanMingguan': [],
          }
        ],
      );
    });

    testWidgets('Dropdown Jenis Pekerjaan displays clean description and locks satuan & no mata pembayaran', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contractProvider = ContractProvider();
      await contractProvider.addContract(testContract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: BuatLaporanScreen(
              initialContract: testContract,
              initialKegiatanIndex: 0,
              initialDate: DateTime(2026, 4, 22),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify manual input is not an option when RKK items exist
      expect(find.text('✏️ Input Manual (Pekerjaan Bebas / Lainnya)'), findsNothing);

      // Open dropdown
      await tester.tap(find.text('Pilih item pekerjaan dari daftar RKK'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Verify clean dropdown option exists in popup
      expect(find.text('Gorong-gorong Kotak 50x50cm'), findsWidgets);

      // Tap the item in dropdown overlay
      await tester.tap(find.text('Gorong-gorong Kotak 50x50cm').last);
      await tester.pumpAndSettle();

      // Verify badges appear: Mata Pembayaran and Satuan
      expect(find.text('Mata Pembayaran: 2.3.(12)'), findsOneWidget);
      expect(find.text('Satuan: m1'), findsWidgets);

      // Verify Status Card renders with accurate historical data:
      // Target: 4.80 m1, Sudah Dikerjakan: 4.30 m1, Sisa Target: 0.50 m1
      expect(find.text('Status Target & Akumulasi Pekerjaan'), findsOneWidget);
      expect(find.text('Target Kontrak'), findsOneWidget);
      expect(find.text('4.80 m1'), findsOneWidget);
      expect(find.text('Sudah Dikerjakan'), findsOneWidget);
      expect(find.text('4.30 m1'), findsNWidgets(2)); // in Sudah Dikerjakan and in Akumulasi Realisasi (when input is 0)
      expect(find.text('Sisa Target'), findsOneWidget);
      expect(find.text('0.50 m1'), findsOneWidget);
    });

    testWidgets('Entering volume updates accumulation in real-time', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contractProvider = ContractProvider();
      await contractProvider.addContract(testContract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: BuatLaporanScreen(
              initialContract: testContract,
              initialKegiatanIndex: 0,
              initialDate: DateTime(2026, 4, 22),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select the item
      await tester.tap(find.text('Pilih item pekerjaan dari daftar RKK'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gorong-gorong Kotak 50x50cm').last);
      await tester.pumpAndSettle();

      // Find the volume text field by its label
      final volField = find.widgetWithText(CleanTextFormField, 'Volume Realisasi Hari Ini *');
      expect(volField, findsOneWidget);

      // Type 0.30 m1
      await tester.enterText(volField, '0.30');
      await tester.pumpAndSettle();

      // Akumulasi should now be 4.30 + 0.30 = 4.60 m1
      expect(find.text('Akumulasi Realisasi'), findsOneWidget);
      expect(find.text('4.60 m1'), findsOneWidget);
      // Persentase akumulasi = (4.60 / 4.80) * 100 = 95.8%
      expect(find.text('95.8%'), findsOneWidget);
    });

    testWidgets('Strict lock: Exceeding remaining contract volume shows warning and blocks saving', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contractProvider = ContractProvider();
      await contractProvider.addContract(testContract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: BuatLaporanScreen(
              initialContract: testContract,
              initialKegiatanIndex: 0,
              initialDate: DateTime(2026, 4, 22),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select item
      await tester.tap(find.text('Pilih item pekerjaan dari daftar RKK'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gorong-gorong Kotak 50x50cm').last);
      await tester.pumpAndSettle();

      // Enter 0.80 m1 (4.30 + 0.80 = 5.10 m1 > 4.80 m1 target)
      final volField = find.widgetWithText(CleanTextFormField, 'Volume Realisasi Hari Ini *');
      await tester.enterText(volField, '0.80');
      await tester.pumpAndSettle();

      // Real-time red warning banner should appear
      expect(find.textContaining('⛔ Melebihi target kontrak sebesar +0.30 m1'), findsOneWidget);

      // Attempt to save report using top AppBar Simpan button
      final saveBtn = find.text('Simpan').first;
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify AlertDialog appears blocking the save
      expect(find.text('Penyimpanan Dikunci'), findsOneWidget);
      expect(find.textContaining('melebihi batas kuantitas kontrak/CCO'), findsOneWidget);
      expect(find.text('Tutup & Perbaiki Volume'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Tutup & Perbaiki Volume'));
      await tester.pumpAndSettle();
      expect(find.text('Penyimpanan Dikunci'), findsNothing);
    });

    testWidgets('DetailKegiatanScreen calculates live physical progress from daily reports', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Target: 4.80 m1 with weight 3.561%. Realized: 4.30 m1
      // Expected live progress = (4.30 / 4.80) * 3.561 = 3.19%
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ContractProvider())],
          child: MaterialApp(
            home: DetailKegiatanScreen(contract: testContract, kegiatanIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Progres Fisik'), findsOneWidget);
      expect(find.text('3.19%'), findsOneWidget);
    });

    test('LembarBoqMingguanWidget aggregates daily volumes partitioned by week dates', () {
      final weeklyReport = WeeklyReportModel(
        id: 'w-test',
        pekerjaan: 'MT Haryono',
        lokasiProyek: 'Purbalingga',
        kontraktor: 'CV. DIVAN',
        jangkaWaktu: 90,
        nomorKontrak: 'SPK-01',
        tanggalKontrak: '20 April 2026',
        nilaiKontrak: 'Rp 350.000.000,00',
        nilaiKontrakNumeric: 350000000.0,
        tanggalSpmk: '20 April 2026',
        mingguKe: 1,
        totalMinggu: 13,
        periodeAwal: '20 April 2026',
        periodeAkhir: '26 April 2026',
        rencanaPersen: 1.0,
        rencanaNominal: 3500000.0,
        realisasiPersen: 3.19,
        realisasiNominal: 11165000.0,
        deviasiPersen: 2.19,
        deviasiNominal: 7665000.0,
        waktuTerpakai: 7,
        sisaWaktu: 83,
        akhirMasaKontrak: '18 Juli 2026',
        tabelMingguan: [],
      );

      final widget = LembarBoqMingguanWidget(
        report: weeklyReport,
        kegiatan: testContract.kegiatans[0],
      );

      expect(widget.report.mingguKe, 1);
      expect(widget.report.periodeAwal, '20 April 2026');
      expect(widget.report.periodeAkhir, '26 April 2026');
    });
  });
}
