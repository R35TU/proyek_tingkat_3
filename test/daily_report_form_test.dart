import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/widgets/clean_text_form_field.dart';

void main() {
  testWidgets('BuatLaporanScreen renders cleanly on narrow 360px mobile screen without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    FlutterErrorDetails? errorDetails;
    final oldOnError = FlutterError.onError;
    FlutterError.onError = (d) {
      errorDetails = d;
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: const MaterialApp(
          home: BuatLaporanScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify main sections exist
    expect(find.text('A. PEKERJAAN'), findsOneWidget);
    expect(find.text('B. MATERIAL DIGUNAKAN'), findsOneWidget);
    expect(find.text('C. JENIS PERALATAN YANG DIGUNAKAN'), findsOneWidget);
    expect(find.text('D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR'), findsOneWidget);

    // Scroll down to see remaining sections
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    FlutterError.onError = oldOnError;
    if (errorDetails != null) {
      // ignore: avoid_print
      print('EXACT OVERFLOW CAUSE:\n${errorDetails!.toString()}');
    }

    expect(find.text('E. CUACA / BENCANA / KEJADIAN PENGHAMBAT PEKERJAAN'), findsOneWidget);
    expect(find.text('Cuaca'), findsOneWidget);
    expect(find.text('Jenis Kejadian'), findsOneWidget);

    // Verify Cuaca is positioned before (above) Jenis Kejadian
    final cuacaY = tester.getTopLeft(find.text('Cuaca')).dy;
    final jenisKejadianY = tester.getTopLeft(find.text('Jenis Kejadian')).dy;
    expect(cuacaY < jenisKejadianY, isTrue);

    expect(find.text('F. INSTRUKSI DAN SARAN-SARAN'), findsOneWidget);

    expect(errorDetails, isNull);
  });

  testWidgets('BuatLaporanScreen with full populated data renders without overflow on ultra-narrow 320px screen', (WidgetTester tester) async {
    FlutterErrorDetails? errorDetails;
    final prevOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      errorDetails = details;
    };
    addTearDown(() {
      FlutterError.onError = prevOnError;
    });

    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockReportData = {
      'pekerjaanList': [
        {'jenis': 'Pekerjaan Pasangan Batu', 'volume': '25 m³', 'lokasi': 'STA 0+150'},
      ],
      'materialList': [
        {'jenis': 'Semen Gresik 50kg', 'volume': '50 Sak', 'lokasiAwal': 'Gudang Utama', 'lokasiTujuan': 'STA 0+150'},
      ],
      'peralatanList': [
        {
          'jenis': 'Excavator Komatsu PC200',
          'cacahAktif': '1 Unit',
          'jumlah': '2 Unit',
          'noRusak': '1',
          'jenisRusak': 'Excavator PC200',
          'kode': 'EX-01',
          'rusak': 'Bocor Seal Hidrolik',
        },
      ],
      'personilList': [
        {'role': 'Pelaksana Lapangan', 'cacah': '2 Orang', 'lokasi': 'STA 0+150'},
      ],
      'cuacaKejadianList': [
        {
          'jenis': 'Hujan Lebat Sore',
          'jam': '14:30 - 16:00 WIB',
          'lokasi': 'Seluruh Ruas',
          'tanggungJawab': 'Tidak',
          'akibat': 'Pengecoran ditunda',
        },
      ],
      'instruksiList': [
        {'pihak': 'Konsultan Supervisi', 'uraian': 'Tutup area galian dengan terpal'},
      ],
      'hasRekapSuhuLapangan': true,
      'rekapSuhuLapanganList': [
        {
          'nomorKendaraan': 'R 8899 AB',
          'jamDatang': '08:30 WIB',
          'suhu': '148',
          'jamMulaiTuang': '08:45 WIB',
          'jamSelesaiTuang': '09:15 WIB',
          'jamPulang': '09:30 WIB',
        },
      ],
      'hasRekapSuhuAmp': true,
      'rekapSuhuAmpList': [
        {
          'nomorKendaraan': 'R 8899 AB',
          'jamPergi': '07:15 WIB',
          'suhuAmp': '155',
          'jamPulang': '10:00 WIB',
        },
      ],
      'hasRekapTonaseAspal': true,
      'rekapTonaseAspalList': [
        {
          'nomorKendaraan': 'R 8899 AB',
          'tonaseTiket': '8.5',
          'jumlahKumulatif': '8.50',
        },
      ],
      'customFields': [
        {'nama': 'Kadar Aspal Rata-rata', 'isi': '5.8% sesuai JMF'},
      ],
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: MaterialApp(
          home: BuatLaporanScreen(editReport: mockReportData),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify fields populated
    expect(find.text('Pekerjaan Pasangan Batu'), findsOneWidget);
    expect(find.text('Semen Gresik 50kg'), findsOneWidget);

    // Scroll through the entire form and verify zero exceptions or overflows
    for (int i = 0; i < 6; i++) {
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();
    }
    expect(errorDetails, isNull);
  });

  testWidgets('BuatLaporanScreen Section F, G (TTD Canvas), and H (Foto) render correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: const MaterialApp(
          home: BuatLaporanScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll down to Section F, G, and H
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();

    // 1. Verify Section F (Instruksi dan Saran) auto Konsultan Supervisi
    expect(find.text('F. INSTRUKSI DAN SARAN-SARAN'), findsOneWidget);
    expect(find.text('Instruksi dan Saran - Saran'), findsOneWidget);

    // 2. Verify Section G (Tanda Tangan Pengawas)
    expect(find.text('G. TANDA TANGAN PENGAWAS (TTD)'), findsOneWidget);
    expect(find.text('Nama Penandatangan *'), findsOneWidget);
    expect(find.text('Posisi / Jabatan *'), findsOneWidget);
    expect(find.text('Tanda Tangan Digital'), findsOneWidget);

    // Scroll further down to Section H
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // 3. Verify Section H (Dokumentasi Foto Lapangan)
    expect(find.text('H. DOKUMENTASI FOTO LAPANGAN'), findsOneWidget);
    expect(find.text('Ambil Kamera'), findsOneWidget);
    expect(find.text('Pilih File / Galeri'), findsOneWidget);
    expect(find.text('Tarik & lepas file foto ke sini'), findsOneWidget);
  });

  testWidgets('CleanTextFormField hides hintText when focused and restores it when unfocused', (WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CleanTextFormField(
            controller: controller,
            focusNode: focusNode,
            label: 'Nama Penandatangan',
            hintText: 'Contoh: MISWANTO',
          ),
        ),
      ),
    );

    // Initial state: not focused -> hint is present in tree
    expect(find.text('Contoh: MISWANTO'), findsOneWidget);

    // Focus field -> hint disappears
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(find.text('Contoh: MISWANTO'), findsNothing);

    // Unfocus field -> hint reappears
    focusNode.unfocus();
    await tester.pumpAndSettle();
    expect(find.text('Contoh: MISWANTO'), findsOneWidget);
  });

  testWidgets('Section E splits Jenis Kejadian and Cuaca in form and loads correctly', (WidgetTester tester) async {
    final mockReportData = {
      'cuacaKejadianList': [
        {
          'jenisKejadian': 'Genangan Air dan Longsor',
          'cuaca': 'Hujan Deras',
          'jam': '14:00 - 16:30',
          'lokasi': 'STA 0+200',
          'tanggungJawab': 'Tidak',
          'akibat': 'Pekerjaan dihentikan',
        },
      ],
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: MaterialApp(
          home: BuatLaporanScreen(editReport: mockReportData),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll down to Section E
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Jenis Kejadian'), findsOneWidget);
    expect(find.text('Cuaca'), findsOneWidget);
    expect(find.text('Genangan Air dan Longsor'), findsOneWidget);
    expect(find.text('Hujan Deras'), findsOneWidget);
  });

  testWidgets('DetailDataLaporanScreen document preview renders separate Jenis Kejadian and Cuaca columns', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final mockContract = ContractModel(
      id: 'c-test',
      namaKontrak: 'Kontrak Pengawasan Jalan',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas PU'],
      nilaiKontrak: 'Rp 200.000.000,00',
      hariKalender: 60,
      tglMulaiSpk: '26 Mei 2026',
      nomorSpk: 'SPK-01',
      nomorSpmk: 'SPMK-01',
      tglMulaiSpmk: '18 Juni 2026',
      tglSelesaiSpmk: '16 Agustus 2026',
      sumberDana: 'APBD',
      deskripsi: 'Deskripsi',
      kegiatans: [
        {
          'namaKegiatan': 'Pengawasan Rutin',
          'lokasi': 'STA 0+000 - 1+000',
          'kontraktor': 'CV. LANGGENG',
          'laporans': [
            {
              'id': 'rep-test-1',
              'tanggal': todayKey,
              'tanggalFormatted': 'Hari Ini',
              'cuaca': 'Hujan Ringan',
              'pekerjaanList': [
                {'jenis': 'Pekerjaan Saluran', 'volume': '10 m', 'lokasi': 'STA 0+100'},
              ],
              'cuacaKejadianList': [
                {
                  'jenisKejadian': 'Pohon Tumbang',
                  'cuaca': 'Hujan Ringan',
                  'jam': '14:00 - 15:00',
                  'lokasi': 'STA 0+200',
                  'tanggungJawab': 'Tidak',
                  'akibat': 'Lalu lintas macet',
                },
              ],
            },
          ],
        }
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: MaterialApp(
          home: DetailDataLaporanScreen(contract: mockContract),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Find and tap the sample report button to open the document bottom sheet
    final reportButtonFinder = find.text('Buka & Lihat Dokumen Laporan');
    expect(reportButtonFinder, findsWidgets);
    await tester.tap(reportButtonFinder.first);
    await tester.pumpAndSettle();

    // Verify the table headers for Section E exist in the preview sheet
    expect(find.text('Jenis Kejadian'), findsWidgets);
    expect(find.text('Cuaca'), findsWidgets); // Appears in chip and table header

    // In the table header, Cuaca is to the left of Jenis Kejadian
    final cuacaHeaderFinder = find.descendant(
      of: find.byType(Table),
      matching: find.text('Cuaca'),
    );
    expect(cuacaHeaderFinder, findsWidgets);
    final cuacaHeaderX = tester.getTopLeft(cuacaHeaderFinder.first).dx;
    final jenisKejadianHeaderX = tester.getTopLeft(find.text('Jenis Kejadian').first).dx;
    expect(cuacaHeaderX < jenisKejadianHeaderX, isTrue);
  });

  testWidgets('Output document partitioned per pekerjaan with dedicated A, B, C, D sections and bottom E, F, G', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final mockContract = ContractModel(
      id: 'c-opt-a',
      namaKontrak: 'Pengawasan Proyek Drainase',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas PU'],
      nilaiKontrak: 'Rp 150.000.000,00',
      hariKalender: 45,
      tglMulaiSpk: '01 Juli 2026',
      nomorSpk: 'SPK-02',
      nomorSpmk: 'SPMK-02',
      tglMulaiSpmk: '05 Juli 2026',
      tglSelesaiSpmk: '18 Agustus 2026',
      sumberDana: 'APBD',
      deskripsi: 'Deskripsi Proyek',
      kegiatans: [
        {
          'namaKegiatan': 'Pekerjaan Saluran Air',
          'lokasi': 'STA 0+000 - 0+500',
          'kontraktor': 'CV. LANGGENG',
          'laporans': [
            {
              'id': 'rep-opt-a',
              'tanggal': todayKey,
              'tanggalFormatted': 'Senin, 10 Agustus 2026',
              'cuaca': 'Cerah',
              'pekerjaanList': [
                {
                  'no': '1',
                  'jenis': 'Galian Saluran Tanah',
                  'volume': '40 m³',
                  'lokasi': 'STA 0+000 - 0+100',
                  'materials': [],
                  'peralatans': [
                    {'jenis': 'Excavator Mini', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit'}
                  ],
                  'personils': [
                    {'role': 'Pekerja Galian', 'cacah': '4 Orang', 'lokasi': 'STA 0+000'}
                  ],
                },
                {
                  'no': '2',
                  'jenis': 'Pasangan Precast Saluran',
                  'volume': '15 Unit',
                  'lokasi': 'STA 0+000 - 0+030',
                  'materials': [
                    {'jenis': 'U-Ditch Precast 40x40', 'volume': '15 Unit', 'lokasiAwal': 'Basecamp', 'lokasiTujuan': 'STA 0+000'},
                  ],
                  'peralatans': [
                    {'jenis': 'Crane Truck', 'cacahAktif': '1 Unit', 'jumlah': '1 Unit'}
                  ],
                  'personils': [
                    {'role': 'Tukang Pasang', 'cacah': '2 Orang', 'lokasi': 'STA 0+000'}
                  ],
                },
              ],
            },
          ],
        }
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: MaterialApp(
          home: DetailDataLaporanScreen(contract: mockContract),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open report preview
    final reportButton = find.text('Buka & Lihat Dokumen Laporan');
    expect(reportButton, findsOneWidget);
    await tester.tap(reportButton);
    await tester.pumpAndSettle();

    // Verify Partitioned Structure:
    // 1. Partition Banners for Pekerjaan #1 and #2 exist
    expect(find.text('PEKERJAAN #1'), findsOneWidget);
    expect(find.text('GALIAN SALURAN TANAH'), findsOneWidget);
    expect(find.text('PEKERJAAN #2'), findsOneWidget);
    expect(find.text('PASANGAN PRECAST SALURAN'), findsOneWidget);

    // 2. Table B (Material): Job #1 without material shows clean note, Job #2 shows actual material
    expect(find.text('Tidak ada penggunaan material pada pekerjaan ini'), findsOneWidget);
    expect(find.text('U-Ditch Precast 40x40'), findsWidgets);

    // 3. Table C (Equipment):
    expect(find.text('Excavator Mini'), findsWidgets);
    expect(find.text('Crane Truck'), findsWidgets);

    // 4. Table D (Personil):
    expect(find.text('Pekerja Galian'), findsWidgets);
    expect(find.text('Tukang Pasang'), findsWidgets);

    // 5. Global Sections E and F rendered:
    expect(find.text('E.   CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN'), findsWidgets);
    expect(find.text('F.   INSTRUKSI DAN SARAN-SARAN'), findsWidgets);

    // 6. Rekapan Format Lama Section exists at the top
    expect(find.text('RINCIAN OPERASIONAL PER ITEM PEKERJAAN'), findsOneWidget);
  });

  testWidgets('Unified Rekapitulasi DT form enters license plate once per delivery trip', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockContract = ContractModel(
      id: 'c-unified-dt',
      namaKontrak: 'Peningkatan Jalan Ruas A',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas PU'],
      nilaiKontrak: 'Rp 500.000.000,00',
      hariKalender: 90,
      tglMulaiSpk: '01 Juli 2026',
      nomorSpk: 'SPK-03',
      nomorSpmk: 'SPMK-03',
      tglMulaiSpmk: '05 Juli 2026',
      tglSelesaiSpmk: '03 Oktober 2026',
      sumberDana: 'APBD',
      deskripsi: 'Deskripsi Proyek',
      kegiatans: [
        {
          'namaKegiatan': 'Pekerjaan Aspal Hotmix AC-WC',
          'lokasi': 'STA 0+000 - 1+000',
          'kontraktor': 'CV. LANGGENG',
          'laporans': [],
        }
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: MaterialApp(
          home: BuatLaporanScreen(initialContract: mockContract),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll down to toggle Rekapitulasi Aspal
    final aspalSection = find.widgetWithText(Row, 'Aktifkan Dokumen Pengawasan Aspal');
    expect(aspalSection, findsOneWidget);
    await tester.ensureVisible(aspalSection);
    final switchFinder = find.descendant(of: aspalSection, matching: find.byType(Switch));
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify Unified Section is active:
    expect(find.text('Rekapitulasi Ritase Pengiriman DT Aspal'), findsOneWidget);
    expect(find.text('1 Ritase'), findsOneWidget);

    // Verify the sub-sections within the single card:
    expect(find.text('1. IDENTITAS KENDARAAN (DT)'), findsOneWidget);
    expect(find.text('2. DATA DI PABRIK (AMP)'), findsOneWidget);

    // Verify there is only 1 "Nomor Kendaraan / Plat DT" input field for this delivery
    expect(find.text('Nomor Kendaraan / Plat DT'), findsOneWidget);

    // Ensure visible the rest of the delivery card
    await tester.ensureVisible(find.text('3. DATA DI LOKASI PROYEK (LAPANGAN)'));
    await tester.pumpAndSettle();
    expect(find.text('3. DATA DI LOKASI PROYEK (LAPANGAN)'), findsOneWidget);
    expect(find.text('Suhu Datang (°C)'), findsOneWidget);
    expect(find.text('Waktu Antrian (Menit)'), findsOneWidget);
    expect(find.text('Suhu Hampar di Lapangan (°C)'), findsOneWidget);

    await tester.ensureVisible(find.text('Suhu Pemadatan Akhir (°C)'));
    await tester.pumpAndSettle();
    expect(find.text('Suhu Pemadatan Akhir (°C)'), findsOneWidget);

    await tester.ensureVisible(find.text('4. DATA TONASE TIKET'));
    await tester.pumpAndSettle();
    expect(find.text('4. DATA TONASE TIKET'), findsOneWidget);

    // Test Alarm-style CupertinoTimerPicker wheel (HH:mm:ss) opens on tap and sets time
    final clockIcon = find.byIcon(Icons.access_time_rounded).first;
    await tester.ensureVisible(clockIcon);
    await tester.tap(clockIcon);
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoTimerPicker), findsOneWidget);
    expect(find.text('Jam Berangkat dari AMP'), findsWidgets);
    expect(find.text('Selesai'), findsOneWidget);

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoTimerPicker), findsNothing);
  });

  testWidgets('Rekapitulasi Beton switch activates concrete form and renders header and truck mixer fields', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockContract = ContractModel(
      id: 'c-beton',
      namaKontrak: 'Pembangunan Saluran & Rigid Pavement',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas PU'],
      nilaiKontrak: 'Rp 750.000.000,00',
      hariKalender: 120,
      tglMulaiSpk: '01 Juli 2026',
      nomorSpk: 'SPK-04',
      nomorSpmk: 'SPMK-04',
      tglMulaiSpmk: '05 Juli 2026',
      tglSelesaiSpmk: '03 November 2026',
      sumberDana: 'APBD',
      deskripsi: 'Deskripsi Proyek',
      kegiatans: [
        {
          'namaKegiatan': 'Pengecoran Rigid Pavement',
          'lokasi': 'STA 0+000 - 0+500',
          'kontraktor': 'PT. JAYA BETON',
          'laporans': [],
        }
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: MaterialApp(
          home: BuatLaporanScreen(initialContract: mockContract),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll down to find the Beton section switch
    final betonSwitchFinder = find.widgetWithText(Row, 'Aktifkan Dokumen Pengawasan Beton');
    expect(betonSwitchFinder, findsOneWidget);
    await tester.ensureVisible(betonSwitchFinder);

    final switchWidget = find.descendant(of: betonSwitchFinder, matching: find.byType(Switch));
    expect(switchWidget, findsOneWidget);
    await tester.tap(switchWidget);
    await tester.pumpAndSettle();

    // Verify Beton Header fields are displayed:
    expect(find.text('Informasi Header Pengecoran Beton'), findsOneWidget);
    expect(find.text('Kegiatan (Otomatis)'), findsOneWidget);
    expect(find.text('Penyedia Jasa (Kontraktor)'), findsOneWidget);
    expect(find.text('Jenis Beton'), findsOneWidget);

    // Verify Mixer Truck Card #1 and its fields:
    expect(find.text('Truck Mixer #1'), findsOneWidget);
    expect(find.text('Nomor Kendaraan / Plat Truck Mixer'), findsOneWidget);
    expect(find.text('Batching Plant Ready Mix'), findsOneWidget);
    expect(find.text('Jam Berangkat dari Batching Plant'), findsOneWidget);
    expect(find.text('Jam Datang di Lapangan'), findsOneWidget);
    expect(find.text('Slump Test'), findsOneWidget);
    expect(find.text('Volume Cor (m³ / Kubik)'), findsOneWidget);
  });

  testWidgets('DetailDataLaporanScreen renders authentic 7-column Rekapitulasi Beton document sheet', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final mockContract = ContractModel(
      id: 'c-beton-preview',
      namaKontrak: 'Pengecoran Jalan Beton',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas Pekerjaan Umum'],
      nilaiKontrak: 'Rp 1.000.000.000,00',
      hariKalender: 90,
      tglMulaiSpk: '01 Juli 2026',
      nomorSpk: 'SPK-BETON-01',
      nomorSpmk: 'SPMK-BETON-01',
      tglMulaiSpmk: '05 Juli 2026',
      tglSelesaiSpmk: '03 Oktober 2026',
      sumberDana: 'APBD',
      deskripsi: 'Deskripsi Proyek',
      kegiatans: [
        {
          'namaKegiatan': 'Rigid Pavement Ruas 1',
          'lokasi': 'STA 0+000 - 0+400',
          'kontraktor': 'PT. WIJAYA KARYA',
          'laporans': [
            {
              'id': 'rep-beton-01',
              'tanggal': todayKey,
              'tanggalFormatted': 'Rabu, 15 Juli 2026',
              'namaKegiatan': 'Rigid Pavement Ruas 1',
              'kontraktor': 'PT. WIJAYA KARYA',
              'hasRekapBeton': true,
              'jenisBeton': "Fc' 25 MPa / K-300",
              'penyediaJasaBeton': 'PT. WIJAYA KARYA',
              'pekerjaanList': [
                {'jenis': 'Pengecoran Rigid Pavement', 'volume': '7.0 m³', 'lokasi': 'STA 0+000 - 0+400'},
              ],
              'rekapPengecoranBetonList': [
                {
                  'no': '1',
                  'nomorKendaraan': 'B 9876 XYZ',
                  'batchingPlant': 'PT. Varia Usaha Beton',
                  'jamBerangkat': '08:00:00',
                  'jamDatang': '09:15:00',
                  'slumpTest': '10 ± 2 cm',
                  'volume': '7.0',
                  'volumeKumulatif': '7.0',
                },
              ],
            },
          ],
        }
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: MaterialApp(
          home: DetailDataLaporanScreen(contract: mockContract),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap to open report preview
    final openDocButton = find.text('Buka & Lihat Dokumen Laporan');
    expect(openDocButton, findsOneWidget);
    await tester.tap(openDocButton);
    await tester.pumpAndSettle();

    // Verify Concrete Recap Sheet Header and Metadata
    expect(find.text('REKAPITULASI PENGIRIMAN & PENGECORAN BETON READY MIX'), findsOneWidget);
    expect(find.text(':  Fc\' 25 MPa / K-300'), findsOneWidget);
    expect(find.text(':  PT. WIJAYA KARYA'), findsWidgets);

    // Verify Table Content
    expect(find.text('B 9876 XYZ'), findsOneWidget);
    expect(find.text('PT. Varia Usaha Beton'), findsOneWidget);
    expect(find.text('08:00:00'), findsOneWidget);
    expect(find.text('09:15:00'), findsOneWidget);
    expect(find.text('10 ± 2 cm'), findsOneWidget);
    expect(find.text('7.0 m³'), findsWidgets);

    // Verify Total Volume
    expect(find.text('TOTAL VOLUME PENGECORAN BETON'), findsOneWidget);
  });

  testWidgets('BuatLaporanScreen allows adding multiple pengawas signers and renders them in DetailDataLaporanScreen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: const MaterialApp(
          home: BuatLaporanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Scroll down to Section G
    final addSignerBtn = find.text('Tambah Penandatangan Pengawas');
    await tester.scrollUntilVisible(addSignerBtn, 500, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();

    expect(find.text('Pengawas #1'), findsOneWidget);
    expect(addSignerBtn, findsOneWidget);

    // Tap to add a second supervisor signer
    await tester.tap(addSignerBtn);
    await tester.pumpAndSettle();

    expect(find.text('Pengawas #1'), findsOneWidget);
    expect(find.text('Pengawas #2'), findsOneWidget);

    // Now test DetailDataLaporanScreen with multiple pengawas
    final now = DateTime.now();
    final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final multiSignerReport = {
      'id': 'rep-multi-signer',
      'tanggal': todayKey,
      'tanggalFormatted': '26 Oktober 2026',
      'hari': 'Senin',
      'pekerjaan': 'Pemeliharaan Jalan',
      'lokasi': 'STA 0+000',
      'kontraktor': 'CV. SATYA WIGUNA',
      'instruksiKonsultan': 'Instruksi bersama tim pengawas',
      'ttdPengawasList': [
        {
          'nama': 'MUBALLIGH, ST., M.Sc.',
          'jabatan': 'Inspektor Lapangan',
          'signature': '',
        },
        {
          'nama': 'SENDAYU GALIH K., ST',
          'jabatan': 'Site Engineer',
          'signature': '',
        },
      ],
      'pekerjaanList': [],
      'cuacaKejadianList': [],
    };

    final mockContract = ContractModel(
      id: 'c-test',
      namaKontrak: 'Kontrak Pengawasan Jalan',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas PU'],
      nilaiKontrak: 'Rp 200.000.000,00',
      hariKalender: 60,
      tglMulaiSpk: '26 Mei 2026',
      nomorSpk: 'SPK-01',
      nomorSpmk: 'SPMK-01',
      tglMulaiSpmk: '18 Juni 2026',
      tglSelesaiSpmk: '16 Agustus 2026',
      sumberDana: 'APBD',
      deskripsi: 'Deskripsi',
      kegiatans: [
        {
          'namaKegiatan': 'Ruas Jalan A',
          'kontraktor': 'CV. SATYA WIGUNA',
          'laporans': [
            multiSignerReport,
          ],
          'folders': [
            {
              'name': 'Laporan Harian',
              'documents': [
                multiSignerReport,
              ],
            },
          ],
        },
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ContractProvider()),
        ],
        child: MaterialApp(
          home: DetailDataLaporanScreen(contract: mockContract),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final reportButtonFinder = find.text('Buka & Lihat Dokumen Laporan');
    expect(reportButtonFinder, findsWidgets);
    await tester.tap(reportButtonFinder.first);
    await tester.pumpAndSettle();

    // Both supervisors should appear in the preview table
    expect(find.text('MUBALLIGH, ST., M.Sc.'), findsWidgets);
    expect(find.text('Inspektor Lapangan'), findsWidgets);
    expect(find.text('SENDAYU GALIH K., ST'), findsWidgets);
    expect(find.text('Site Engineer'), findsWidgets);
  });
}

