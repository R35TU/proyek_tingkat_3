import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/widgets/lembar_boq_mingguan_widget.dart';

void main() {
  group('RKK and BoQ Tests', () {
    testWidgets('DetailKegiatanScreen renders Action Card for RKK', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-rkk-test',
        namaKontrak: 'PEMELIHARAAN JALAN LETJEN MT HARYONO',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 1.000.000.000,00',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Ruas Jalan Letjen MT Haryono',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
            'rkkDivisiList': KegiatanModel.defaultSampleRkk(),
          }
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ContractProvider())],
          child: MaterialApp(
            home: DetailKegiatanScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to Action Card if needed
      await tester.scrollUntilVisible(
        find.text('Rincian Kuantitas & Bobot Pekerjaan'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // Verify Action Card
      expect(find.text('Rincian Kuantitas & Bobot Pekerjaan'), findsOneWidget);
      expect(find.text('Kelola Rincian Pekerjaan (RKK)'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
    });

    testWidgets('KelolaRkkScreen renders PU template and displays divisions and items', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-rkk-test-2',
        namaKontrak: 'PEMELIHARAAN JALAN MT HARYONO',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 1.000.000.000,00',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Ruas MT Haryono',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
            'rkkDivisiList': KegiatanModel.defaultSampleRkk(),
          }
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ContractProvider())],
          child: MaterialApp(
            home: KelolaRkkScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check divisions and items from default sample
      expect(find.text('DIVISI 1 UMUM'), findsOneWidget);
      expect(find.text('DIVISI 2. DRAINASE'), findsOneWidget);
      expect(find.text('Mobilisasi'), findsOneWidget);
      expect(find.text('Sesuai 100%'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('DIVISI 7 STRUKTUR'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('DIVISI 7 STRUKTUR'), findsOneWidget);
    });

    testWidgets('BuatLaporanScreen provides RKK dropdown for Pekerjaan', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-rkk-daily',
        namaKontrak: 'PEMELIHARAAN JALAN MT HARYONO',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 1.000.000.000,00',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Ruas MT Haryono',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
            'rkkDivisiList': KegiatanModel.defaultSampleRkk(),
            'laporans': [],
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: const MaterialApp(
            home: BuatLaporanScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the RKK dropdown label
      expect(find.text('Pilih dari RKK Kontrak *'), findsOneWidget);
    });

    testWidgets('DetailDataLaporanScreen renders LembarBoqMingguanWidget below weekly report', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final weeklySample = WeeklyReportModel.sampleDocument();
      final contract = ContractModel(
        id: 'c-rkk-weekly',
        namaKontrak: 'PEMELIHARAAN JALAN MT HARYONO',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 1.000.000.000,00',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Ruas MT Haryono',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. DIVAN INSAN CEMERLANG',
            'rkkDivisiList': KegiatanModel.defaultSampleRkk(),
            'laporans': [],
            'laporanMingguan': [weeklySample.toJson()],
          }
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ContractProvider())],
          child: MaterialApp(
            home: DetailDataLaporanScreen(contract: contract, initialTab: 1),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on 'Buka Dokumen' for weekly report
      final openDocButton = find.text('Buka Dokumen');
      expect(openDocButton, findsOneWidget);
      await tester.tap(openDocButton);
      await tester.pumpAndSettle();

      // Verify BOTH sheets are rendered: Sheet 1 (Ringkasan) & Sheet 2 (BoQ)
      expect(find.text('RINGKASAN KEGIATAN MINGGUAN'), findsOneWidget);
      expect(find.byType(LembarBoqMingguanWidget), findsOneWidget);
      expect(find.text('LAPORAN MINGGUAN'), findsOneWidget);
    });

    testWidgets('KelolaRkkScreen renders elegant empty state without template button and auto-generates Roman numerals', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-rkk-empty',
        namaKontrak: 'PEMELIHARAAN JALAN BARU',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 500.000.000,00',
        hariKalender: 60,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 September 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Ruas Jalan Baru',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. LANGGENG',
            'rkkDivisiList': [], // EMPTY
          }
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => ContractProvider())],
          child: MaterialApp(
            home: KelolaRkkScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify template button is GONE
      expect(find.text('Gunakan Template Standar PU'), findsNothing);
      expect(find.text('Belum Ada Rincian Kuantitas Kontrak'), findsNothing);

      // Verify elegant empty state
      expect(find.text('Mulai Susun Rincian Kuantitas (RKK)'), findsOneWidget);
      final addFirstBtn = find.text('Tambah Divisi Pertama');
      expect(addFirstBtn, findsOneWidget);

      // Tap to open bottom sheet
      await tester.tap(addFirstBtn);
      await tester.pumpAndSettle();

      // Verify Roman numeral is automatic (DIVISI I)
      expect(find.text('DIVISI I'), findsOneWidget);

      // Enter division name via quick chip or typing
      final chipUmum = find.text('UMUM');
      expect(chipUmum, findsOneWidget);
      await tester.tap(chipUmum);
      await tester.pumpAndSettle();

      // Tap add
      await tester.tap(find.text('Tambahkan Divisi I'));
      await tester.pumpAndSettle();

      // Verify division is added with Roman numeral prefix
      expect(find.text('DIVISI I. UMUM'), findsOneWidget);
    });
  });
}
