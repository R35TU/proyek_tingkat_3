import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/screens/laporan_mingguan_screen.dart';
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

    testWidgets('LaporanMingguanScreen renders LembarBoqMingguanWidget in weekly report modal', (WidgetTester tester) async {
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
        tglMulaiSpk: '19 April 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '19 April 2026',
        tglSelesaiSpmk: '17 Juli 2026',
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

      SharedPreferences.setMockInitialValues({});
      final contractProv = ContractProvider();
      await contractProv.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: contractProv),
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
          ],
          child: MaterialApp(
            home: LaporanMingguanScreen(initialContract: contract),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.dragUntilVisible(
        find.text('Buka'),
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.ensureVisible(find.text('Buka').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buka').first);
      await tester.pumpAndSettle();

      // Sheet 1: Ringkasan Mingguan
      expect(find.text('RINGKASAN KEGIATAN MINGGUAN'), findsOneWidget);

      // Pindah ke tab 2: Progress BoQ (14 Kolom)
      await tester.tap(find.text('2. Progress BoQ (14 Kolom)'));
      await tester.pumpAndSettle();
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

    testWidgets('KelolaRkkScreen allows jumping divisions (e.g. Divisi 6 VI) and calculates 7 columns automatically', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-rkk-jump',
        namaKontrak: 'PENINGKATAN JALAN KABUPATEN',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 288.350.703,03',
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
            'namaKegiatan': 'Ruas Jalan Kabupaten',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. TATA SAKA',
            'nilaiKontrak': 'Rp 288.350.703,03',
            'rkkDivisiList': [
              {
                'nomorRomawi': 'II',
                'namaDivisi': 'DIVISI 2. DRAINASE',
                'items': [
                  {
                    'no': '1',
                    'noMataPembayaran': '2.3.(12)',
                    'uraian': 'Gorong-Gorong Kotak Beton Bertulang',
                    'satuan': 'm1',
                    'hargaSatuan': 2139059.32,
                    'volume': 4.80,
                    'totalHarga': 10267484.74,
                    'nilaiBobot': 3.561,
                  }
                ],
              }
            ],
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: KelolaRkkScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify existing Divisi 2. DRAINASE with Roman numeral II
      expect(find.text('DIVISI 2. DRAINASE'), findsOneWidget);
      expect(find.text('II'), findsWidgets);
      expect(find.text('2.3.(12)'), findsOneWidget);
      expect(find.text('Volume: 4.8'), findsOneWidget);
      expect(find.text('Vol CCO'), findsNothing); // CCO MUST NOT APPEAR

      // Tap 'Tambah Divisi Pekerjaan' to add a jumping division: Divisi 6 (VI)
      final addDivBtn = find.text('Tambah Divisi Pekerjaan');
      expect(addDivBtn, findsOneWidget);
      await tester.tap(addDivBtn);
      await tester.pumpAndSettle();

      // Tap preset chip 'Divisi 6 (VI)'
      final presetDiv6 = find.text('Divisi 6 (VI)');
      expect(presetDiv6, findsOneWidget);
      await tester.ensureVisible(presetDiv6);
      await tester.pumpAndSettle();
      await tester.tap(presetDiv6);
      await tester.pumpAndSettle();

      // Confirm Divisi VI is selected in header badge and submit button
      expect(find.text('DIVISI VI'), findsOneWidget);
      expect(find.text('Tambahkan Divisi VI'), findsOneWidget);

      await tester.tap(find.text('Tambahkan Divisi VI'));
      await tester.pumpAndSettle();

      // Verify that Divisi 6 was added without changing Divisi 2 into Divisi 1!
      expect(find.text('DIVISI 2. DRAINASE'), findsOneWidget);
      expect(find.text('DIVISI 6. PERKERASAN ASPAL'), findsOneWidget);
      expect(find.text('VI'), findsWidgets);

      // Add item to Divisi 6
      final addItemBtn = find.text('Tambah Item Pekerjaan').last;
      await tester.tap(addItemBtn);
      await tester.pumpAndSettle();

      // Enter 7 columns:
      // 1. No Mata Pembayaran
      await tester.enterText(find.widgetWithText(TextField, '1.2 / 2.3.(12) / Taksir'), '6.1 (1)(a)');
      // 2. Satuan
      await tester.enterText(find.widgetWithText(TextField, 'm3, m2, Ls, liter'), 'liter');
      // 3. Uraian
      await tester.enterText(find.widgetWithText(TextField, 'Contoh: Gorong-Gorong Kotak Beton Bertulang / Lapis Resap Pengikat'), 'Lapis Resap Pengikat - Aspal Cair');
      // 4. Harga Satuan
      await tester.enterText(find.widgetWithText(TextField, 'Misal: 25958 atau 2139059.32'), '25958');
      // 5. Volume
      await tester.enterText(find.widgetWithText(TextField, 'Misal: 118.79 (0 jika taksiran)'), '118.79');
      await tester.pumpAndSettle();

      // Check auto-calculated Total Harga & Bobot
      // 25958 * 118.79 = 3083550.82
      expect(find.text('HASIL KALKULASI OTOMATIS'), findsOneWidget);

      // Submit Item
      await tester.tap(find.text('Tambahkan Item ke Divisi'));
      await tester.pumpAndSettle();

      // Verify item rendered in Divisi 6
      expect(find.text('6.1 (1)(a)'), findsOneWidget);
      expect(find.text('Lapis Resap Pengikat - Aspal Cair'), findsOneWidget);
      expect(find.text('Satuan: liter'), findsOneWidget);
      expect(find.text('Volume: 118.79'), findsOneWidget);

      // Tap Simpan to verify it saves without error and synchronizes contract
      final saveBtn = find.text('Simpan');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();
    });

    testWidgets('KelolaRkkScreen hides permanent edit/delete icons and shows action sheet on card hold (long-press)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-rkk-hold',
        namaKontrak: 'PENINGKATAN JALAN KABUPATEN',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 288.350.703,03',
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
            'namaKegiatan': 'Ruas Jalan Kabupaten',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. TATA SAKA',
            'nilaiKontrak': 'Rp 288.350.703,03',
            'rkkDivisiList': [
              {
                'nomorRomawi': 'I',
                'namaDivisi': 'DIVISI 1 UMUM',
                'items': [
                  {
                    'no': '1',
                    'noMataPembayaran': '1.2',
                    'uraian': 'Mobilisasi Alat & Personil',
                    'satuan': 'Ls',
                    'hargaSatuan': 12900000.0,
                    'volume': 1.0,
                    'totalHarga': 12900000.0,
                    'nilaiBobot': 4.474,
                  }
                ],
              }
            ],
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: KelolaRkkScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify that permanent IconButton edit and delete are NOT present on the screen
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byTooltip('Hapus Item'), findsNothing);
      expect(find.byTooltip('Ubah Item'), findsNothing);
      expect(find.byTooltip('Hapus Divisi'), findsNothing);

      // 2. Test HOLD (long-press) on Divisi Header opens Divisi Action Sheet
      final divHeader = find.text('DIVISI 1 UMUM');
      expect(divHeader, findsOneWidget);
      await tester.longPress(divHeader);
      await tester.pumpAndSettle();

      // Action sheet for division should appear
      expect(find.text('Ubah Nama / Nomor Divisi'), findsOneWidget);
      expect(find.text('Hapus Divisi'), findsOneWidget);

      // Dismiss bottom sheet by tapping barrier
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      // 3. Test HOLD (long-press) on Item Card opens Item Action Sheet
      final itemRow = find.text('Mobilisasi Alat & Personil');
      expect(itemRow, findsOneWidget);
      await tester.longPress(itemRow);
      await tester.pumpAndSettle();

      // Action sheet for item should appear
      expect(find.text('Ubah Item Pekerjaan'), findsOneWidget);
      expect(find.text('Hapus Item Pekerjaan'), findsOneWidget);

      // Dismiss bottom sheet
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();
    });

    testWidgets('DetailKegiatanScreen renders RAB table directly below Nilai Kontrak Kegiatan', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-rkk-table-view',
        namaKontrak: 'PENINGKATAN JALAN KABUPATEN',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 288.350.703,03',
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
            'namaKegiatan': 'Ruas Jalan Kabupaten',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. SATYA WIGUNA',
            'nilaiKontrak': 'Rp 350.000.000',
            'rkkDivisiList': KegiatanModel.defaultSampleRkk(),
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: DetailKegiatanScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Nilai Kontrak Kegiatan is present
      expect(find.text('Nilai Kontrak Kegiatan'), findsOneWidget);
      expect(find.text('Rp 350.000.000'), findsOneWidget);

      // Verify clean RAB Table Section is rendered right below Nilai Kontrak Kegiatan
      expect(find.text('RINCIAN KUANTITAS KONTRAK (RAB)'), findsOneWidget);

      // Verify clutter elements are removed as requested
      expect(find.text('Kelola RAB'), findsNothing);
      expect(find.text('100% Sesuai'), findsNothing);
      expect(find.textContaining('Geser tabel'), findsNothing);

      // Verify official table headers (styled like weekly BoQ report)
      expect(find.text('NO.'), findsOneWidget);
      expect(find.text('NO. MATA\nPEMBAYARAN'), findsOneWidget);
      expect(find.text('URAIAN PEKERJAAN'), findsOneWidget);
      expect(find.text('SATUAN'), findsOneWidget);
      expect(find.text('HARGA SATUAN\n(Rp)'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('TOTAL HARGA\n(Rp)'), findsOneWidget);
      expect(find.text('BOBOT\n(%)'), findsOneWidget);

      // Verify table content & footer
      expect(find.text('JUMLAH TOTAL HARGA PEKERJAAN'), findsOneWidget);
      expect(find.text('STRUKTUR ORGANISASI KEGIATAN'), findsOneWidget);
    });
  });
}
