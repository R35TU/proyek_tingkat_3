import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/pdf_viewer_screen.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_profile_data': jsonEncode({
        'name': 'Konsultan Supervisi',
        'role': 'Konsultan',
        'email': 'konsultan@tatasaka.com',
      }),
    });
  });

  final sampleContract = ContractModel(
    id: 'kontrak-test-web-01',
    jenisKegiatan: 'Pekerjaan Konstruksi',
    namaKontrak: 'Peningkatan Jalan Ruas Bobotsari',
    nomorSpk: '602.1/SPK/2026',
    tglMulaiSpk: '01 Juli 2026',
    nomorSpmk: '602.1/SPMK/2026',
    tglMulaiSpmk: '01 Juli 2026',
    tglSelesaiSpmk: '31 Oktober 2026',
    hariKalender: 120,
    nilaiKontrak: 'Rp 1.000.000.000,00',
    instansiDinas: ['Dinas Pekerjaan Umum'],
    sumberDana: 'APBN',
    deskripsi: 'Pengawasan Lapangan',
    kegiatans: [
      {
        'namaKegiatan': 'Peningkatan Jalan Paket 1',
        'lokasi': 'Bobotsari',
        'kontraktor': 'CV Testing',
        'sumberDana': 'APBN',
        'laporans': [],
      }
    ],
  );

  Widget createTestWidget({
    required Widget child,
    Size surfaceSize = const Size(1280, 800),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => ContractProvider()),
        ChangeNotifierProvider(create: (_) => TimelineProvider()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: child,
        ),
      ),
    );
  }

  group('Web Navigation & Drill-Down Detail Screen Consistency Tests', () {
    testWidgets('1. DetailDataLaporanScreen in Web mode renders inside WebDashboardLayout with persistent sidebar & back button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: DetailDataLaporanScreen(
            contract: sampleContract,
            kegiatanIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert persistent WebDashboardLayout and WebSidebar are present
      expect(find.byType(WebDashboardLayout), findsOneWidget);
      expect(find.text('CV. TATA SAKA CONSULTANT'), findsOneWidget);
      expect(find.byType(VerticalDivider), findsOneWidget);

      // Assert Back Button is rendered in Web Heading
      expect(find.byTooltip('Kembali'), findsOneWidget);
      expect(find.textContaining('Laporan Harian'), findsWidgets);
      expect(find.text('Mingguan'), findsNothing);
    });

    testWidgets('2. DetailKegiatanScreen in Web mode renders inside WebDashboardLayout without going fullscreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: DetailKegiatanScreen(
            contract: sampleContract,
            kegiatanIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WebDashboardLayout), findsOneWidget);
      expect(find.text('CV. TATA SAKA CONSULTANT'), findsWidgets);
      expect(find.text('KONSULTAN TEKNIS'), findsOneWidget);
      expect(find.byTooltip('Kembali'), findsOneWidget);
    });

    testWidgets('3. DetailKontrakScreen in Web mode renders inside WebDashboardLayout with tabs and sidebar intact', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: DetailKontrakScreen(contract: sampleContract),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WebDashboardLayout), findsOneWidget);
      expect(find.text('CV. TATA SAKA CONSULTANT'), findsOneWidget);
      expect(find.text('Umum'), findsWidgets);
      expect(find.text('Administrasi'), findsWidgets);
      expect(find.byTooltip('Kembali'), findsOneWidget);
    });

    testWidgets('4. PdfViewerScreen in Web mode renders inside WebDashboardLayout with sidebar and download button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: PdfViewerScreen(
            title: 'Pratinjau Laporan Harian',
            fileName: 'Test_Report.pdf',
            buildPdf: () async => Uint8List(0),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(WebDashboardLayout), findsOneWidget);
      expect(find.text('CV. TATA SAKA CONSULTANT'), findsOneWidget);
      expect(find.byTooltip('Simpan / Buka File PDF'), findsOneWidget);
      expect(find.byTooltip('Kembali'), findsOneWidget);
    });

    testWidgets('5. Mobile mode (< 900px) does not show WebSidebar and preserves native mobile layout', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        createTestWidget(
          child: DetailDataLaporanScreen(
            contract: sampleContract,
            kegiatanIndex: 0,
          ),
          surfaceSize: const Size(400, 800),
        ),
      );
      await tester.pumpAndSettle();

      // On mobile, persistent WebSidebar and VerticalDivider should NOT exist
      expect(find.text('CV. TATA SAKA CONSULTANT'), findsNothing);
      expect(find.byType(VerticalDivider), findsNothing);
    });
  });
}
