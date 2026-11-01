import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
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
    expect(find.text('F. INSTRUKSI DAN SARAN-SARAN'), findsOneWidget);

    expect(errorDetails, isNull);
  });

  testWidgets('BuatLaporanScreen with full populated data renders without overflow on ultra-narrow 320px screen', (WidgetTester tester) async {
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
      expect(tester.takeException(), isNull);
    }
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
}

