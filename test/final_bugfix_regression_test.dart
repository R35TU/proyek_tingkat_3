import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/kontrak_screen.dart';
import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/screens/laporan_mingguan_screen.dart';
import 'package:tata_saka_app/screens/laporan_screen.dart';
import 'package:tata_saka_app/screens/panduan_faq_screen.dart';
import 'package:tata_saka_app/screens/setting_screen.dart';
import 'package:tata_saka_app/screens/splash_screen.dart';
import 'package:tata_saka_app/screens/timeline_screen.dart';
import 'package:tata_saka_app/services/pdf_report_service.dart';
import 'package:tata_saka_app/utils/execution_period_helper.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';
import 'package:tata_saka_app/widgets/lembar_laporan_bulanan_widget.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

String _extractPdfTextStreams(Uint8List bytes) {
  final raw = latin1.decode(bytes, allowInvalid: true);
  final rawBuffer = StringBuffer(raw);
  int start = 0;
  while (true) {
    final streamIdx = raw.indexOf('stream', start);
    if (streamIdx < 0) break;
    int dataStart = streamIdx + 6;
    if (dataStart < raw.length && raw.codeUnitAt(dataStart) == 13) {
      dataStart++;
    }
    if (dataStart < raw.length && raw.codeUnitAt(dataStart) == 10) {
      dataStart++;
    }
    final endIdx = raw.indexOf('endstream', dataStart);
    if (endIdx < 0) break;
    final slice = bytes.sublist(dataStart, endIdx);
    try {
      final decoded = zlib.decode(slice);
      rawBuffer.writeln(latin1.decode(decoded, allowInvalid: true));
    } catch (_) {
      // Non-compressed stream already included in raw
    }
    start = endIdx + 9;
  }
  final allStreams = rawBuffer.toString();
  final tokens = RegExp(r'\[\((.*?)\)\]TJ')
      .allMatches(allStreams)
      .map((m) => m.group(1) ?? '')
      .join(' ');
  return '$allStreams\n$tokens';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildRoutedApp({
    required UserProfileProvider userProf,
    required GoRouter router,
    ContractProvider? contractProv,
    TimelineProvider? timelineProv,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
        ChangeNotifierProvider<ContractProvider>.value(
          value: contractProv ?? ContractProvider(),
        ),
        ChangeNotifierProvider<TimelineProvider>.value(
          value: timelineProv ?? TimelineProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'SAKA-REP',
        routerConfig: router,
      ),
    );
  }

  UserProfileProvider makeKonsultanProfile() {
    return UserProfileProvider()
      ..loginAs(const RegisteredUser(
        username: 'konsultan',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'CV. Tata Saka Consultant',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));
  }

  ContractModel makeUnsavedContract() {
    return ContractModel(
      id: 'c-nosig-01',
      namaKontrak: 'Paket Peningkatan Jalan Ruas Test',
      jenisKegiatan: 'Pengawasan Teknis',
      instansiDinas: ['DPU-PR Kab. Purbalingga'],
      nilaiKontrak: 'Rp 1.000.000.000,00',
      hariKalender: 90,
      tglMulaiSpk: '01 Juli 2026',
      nomorSpk: '001/SPK/2026',
      nomorSpmk: '001/SPMK/2026',
      tglMulaiSpmk: '01 Juli 2026',
      tglSelesaiSpmk: '28 September 2026',
      sumberDana: 'APBD',
      deskripsi: 'Paket uji tanpa tanda tangan default',
      strukturOrganisasi: const {'siteEngineer': 'Ir. Default Engineer'},
      kegiatans: [
        {
          'namaKegiatan': 'Ruas Uji Jalan',
          'lokasi': 'Purbalingga',
          'kontraktor': 'CV. KONTRAKTOR UJI',
          'konsultanPengawas': 'CV. TATA SAKA CONSULTANT',
          'penggunaAnggaran': 'Kepala Dinas Uji',
          'rkkDivisiList': [
            {
              'namaDivisi': 'Divisi 1',
              'items': [
                {
                  'no': '1.1',
                  'uraian': 'Galian Tanah',
                  'satuan': 'm3',
                  'volume': 100.0,
                  'hargaSatuan': 10000.0,
                  'jumlahHarga': 1000000.0,
                  'bobot': 100.0,
                  'bobotKontrak': 100.0,
                },
              ],
            },
          ],
          'laporanMingguan': [
            {
              'mingguKe': 1,
              'progresKumulatif': 25.0,
              'items': [
                {'no': '1.1', 'volumeMingguIni': 25.0},
              ],
            },
          ],
          'laporans': [
            {
              'id': 'harian-nosig-1',
              'tanggal': '2026-07-05',
              'tanggalFormatted': '05 Juli 2026',
              'hari': 'Minggu',
              'pekerjaan': 'Ruas Uji Jalan',
              'lokasi': 'Purbalingga',
              'kontraktor': 'CV. KONTRAKTOR UJI',
              'instruksiKonsultan': 'Instruksi uji',
              'pekerjaanList': [],
              'cuacaKejadianList': [],
            },
          ],
          'folders': [
            {
              'name': 'Laporan Harian',
              'documents': [
                {
                  'id': 'harian-nosig-1',
                  'tanggal': '2026-07-05',
                  'tanggalFormatted': '05 Juli 2026',
                  'hari': 'Minggu',
                  'pekerjaan': 'Ruas Uji Jalan',
                  'lokasi': 'Purbalingga',
                  'kontraktor': 'CV. KONTRAKTOR UJI',
                  'instruksiKonsultan': 'Instruksi uji',
                  'pekerjaanList': [],
                  'cuacaKejadianList': [],
                },
              ],
            },
          ],
        },
      ],
    );
  }

  group('Bug 1: Mobile Back Buttons & Navigation History', () {
    testWidgets(
      '1. Mobile bottom tabs follow sequential history Back and Dashboard stays root without Back button',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        resetShellRouteHistory();
        final userProf = makeKonsultanProfile();

        tester.view.physicalSize = const Size(400, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = createAppRouter(userProf, initialLocation: '/dashboard');
        addTearDown(router.dispose);

        await tester.pumpWidget(
          buildRoutedApp(userProf: userProf, router: router),
        );
        await tester.pumpAndSettle();

        // Root Dashboard has NO AppBar back button
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsNothing);

        // Navigate via BottomNav: Dashboard -> Kontrak -> Timeline -> Akun
        final navBar = find.byType(BottomNavigationBar);
        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Kontrak')),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/kontrak');
        expect(find.byType(KontrakScreen), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Timeline')),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/timeline');
        expect(find.byType(TimelineScreen), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Akun')),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/akun');
        expect(find.byType(SettingScreen), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Step Back sequentially via AppBar Back button:
        // Akun -> Timeline -> Kontrak -> Dashboard
        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/timeline');

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/kontrak');

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/dashboard');
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      },
    );

    testWidgets(
      '2. Android hardware Back respects shell history (Kontrak -> Akun -> hardware Back -> Kontrak -> Panduan -> Back -> Kontrak)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        resetShellRouteHistory();
        final userProf = makeKonsultanProfile();

        tester.view.physicalSize = const Size(400, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = createAppRouter(userProf, initialLocation: '/dashboard');
        addTearDown(router.dispose);

        await tester.pumpWidget(
          buildRoutedApp(userProf: userProf, router: router),
        );
        await tester.pumpAndSettle();

        final navBar = find.byType(BottomNavigationBar);
        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Kontrak')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: navBar, matching: find.text('Akun')),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/akun');

        // Simulate Android system back press
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/kontrak');

        // Navigate to Panduan from Kontrak, then tap Back -> Kontrak
        goTopLevelRoute(
          tester.element(find.byType(KontrakScreen)),
          '/panduan',
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/panduan');
        expect(find.byType(PanduanFaqScreen), findsOneWidget);

        await tester.tap(find.byIcon(Icons.arrow_back));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/kontrak');
      },
    );

    testWidgets(
      '3. Laporan, LaporanMingguan empty state, and LaporanBulanan empty state include Back buttons',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        resetShellRouteHistory();
        final userProf = makeKonsultanProfile();

        tester.view.physicalSize = const Size(400, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final emptyContractProvider = ContractProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider<ContractProvider>.value(
                value: emptyContractProvider,
              ),
            ],
            child: const MaterialApp(home: LaporanMingguanScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider<ContractProvider>.value(
                value: emptyContractProvider,
              ),
            ],
            child: const MaterialApp(home: LaporanBulananScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider<ContractProvider>.value(
                value: emptyContractProvider,
              ),
            ],
            child: const MaterialApp(home: LaporanScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      },
    );
  });

  group('Bug 2: No Default Signer Names, Roles, or Placeholders', () {
    testWidgets(
      '4. Daily Report UI & PDF render empty when no signature entered and partial when only name entered',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final contract = makeUnsavedContract();
        final report = Map<String, dynamic>.from(
          contract.kegiatans[0]['laporans'][0] as Map,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(create: (_) => ContractProvider()),
            ],
            child: MaterialApp(
              home: DetailDataLaporanScreen(contract: contract),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Buka & Lihat Dokumen Laporan').first);
        await tester.pumpAndSettle();

        expect(find.text('MISWANTO'), findsNothing);
        expect(find.text('Inspector'), findsNothing);

        final emptyPdfBytes = await PdfReportService.generateLaporanHarianPdf(
          report: report,
          namaKegiatan: 'Ruas Uji Jalan',
          lokasi: 'Purbalingga',
          dana: 'APBD',
          kontraktor: 'CV. KONTRAKTOR UJI',
          konsultan: 'CV. TATA SAKA CONSULTANT',
        );
        expect(latin1.decode(emptyPdfBytes.take(4).toList()), '%PDF');
        final emptyPdfText = _extractPdfTextStreams(emptyPdfBytes);
        expect(emptyPdfText, isNot(contains('MISWANTO')));
        expect(emptyPdfText, isNot(contains('Inspector')));

        // Partial signer: only nama entered
        final partialReport = Map<String, dynamic>.from(report)
          ..['ttdPengawasList'] = [
            {'nama': 'Budi Santoso', 'jabatan': '', 'signature': ''},
          ];
        final partialPdfBytes = await PdfReportService.generateLaporanHarianPdf(
          report: partialReport,
          namaKegiatan: 'Ruas Uji Jalan',
          lokasi: 'Purbalingga',
          dana: 'APBD',
          kontraktor: 'CV. KONTRAKTOR UJI',
          konsultan: 'CV. TATA SAKA CONSULTANT',
        );
        final partialPdfText = _extractPdfTextStreams(partialPdfBytes);
        expect(partialPdfText, contains('Budi Santoso'));
        expect(partialPdfText, isNot(contains('Inspector')));
        expect(partialPdfText, isNot(contains('MISWANTO')));
      },
    );

    testWidgets(
      '5. Monthly Report Model, Modal, Widget Preview, and PDF show no defaults when empty and only entered fields when partial',
      (tester) async {
        tester.view.physicalSize = const Size(412, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final contract = makeUnsavedContract();
        final reports = MonthlyReportModel.generateFromWeeklyReports(
          contract: contract,
          kegiatan: contract.kegiatans[0],
        );
        expect(reports, isNotEmpty);
        final m1 = reports.first;

        // Model must NOT fabricate signer names, roles, or dates
        expect(m1.ttdList, isNull);
        expect(m1.ttdKontraktor['nama'], '');
        expect(m1.ttdKontraktor['jabatan'], '');
        expect(m1.ttdKonsultan['nama'], '');
        expect(m1.ttdKonsultan['jabatan'], '');
        expect(m1.ttdPpk['nama'], '');
        expect(m1.ttdPpk['jabatan'], '');

        // Widget preview with empty signatures: NO defaults or dots
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LembarLaporanBulananWidget(report: m1),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Kontraktor Pelaksana'), findsNothing);
        expect(find.textContaining('Konsultan Supervisi'), findsNothing);
        expect(
          find.textContaining('Pejabat Pembuat Komitmen'),
          findsNothing,
        );
        expect(find.text('Penandatangan'), findsNothing);
        expect(find.text('( .................................... )'), findsNothing);
        expect(find.text('Ir. Default Engineer'), findsNothing);
        expect(find.text('Kepala Dinas Uji'), findsNothing);

        // Partial Monthly signer: only peran + nama
        final partialMonthly = m1.copyWithSignatures(
          ttdList: [
            {
              'peran': 'Tim Verifikasi Lapangan',
              'instansi': '',
              'nama': 'Sari Dewi',
              'tanggal': '',
              'signature': null,
            },
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LembarLaporanBulananWidget(report: partialMonthly),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Tim Verifikasi Lapangan'), findsOneWidget);
        expect(find.text('Sari Dewi'), findsOneWidget);
        expect(find.text('Penandatangan'), findsNothing);
        expect(find.text('( .................................... )'), findsNothing);
        expect(find.textContaining('Kontraktor Pelaksana'), findsNothing);

        // PDF with empty signatures vs partial signatures
        final emptyPdf = await PdfReportService.generateLaporanBulananPdf(
          report: m1,
          contract: contract,
        );
        expect(latin1.decode(emptyPdf.take(4).toList()), '%PDF');
        final emptyPdfText = _extractPdfTextStreams(emptyPdf);
        expect(emptyPdfText, isNot(contains('Kontraktor Pelaksana')));
        expect(emptyPdfText, isNot(contains('Konsultan Supervisi')));
        expect(emptyPdfText, isNot(contains('Pejabat Pembuat Komitmen')));
        expect(emptyPdfText, isNot(contains('Penandatangan')));
        expect(emptyPdfText, isNot(contains('....................................')));

        final partialPdf = await PdfReportService.generateLaporanBulananPdf(
          report: partialMonthly,
          contract: contract,
        );
        final partialPdfText = _extractPdfTextStreams(partialPdf);
        expect(partialPdfText, contains('Tim Verifikasi Lapangan'));
        expect(partialPdfText, contains('Sari Dewi'));
        expect(partialPdfText, isNot(contains('Penandatangan')));
        expect(
          partialPdfText,
          isNot(contains('....................................')),
        );

        // Opening Monthly Signature modal on unsaved month starts blank (no prefill)
        SharedPreferences.setMockInitialValues({});
        final provider = ContractProvider();
        final userProf = makeKonsultanProfile();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<ContractProvider>.value(value: provider),
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
            ],
            child: MaterialApp(
              home: LaporanBulananScreen(initialContract: contract),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (!provider.contracts.any((c) => c.id == contract.id)) {
          await provider.addContract(contract);
          await tester.pumpAndSettle();
        }

        await tester.scrollUntilVisible(
          find.text('Tanda Tangan').first,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Tanda Tangan').first);
        await tester.pumpAndSettle();

        final textFields = tester.widgetList<TextField>(find.byType(TextField));
        for (final tf in textFields) {
          expect(tf.controller?.text ?? '', isEmpty);
        }
        expect(find.text('Pengawas Lapangan'), findsNothing);

        // Tap Simpan Tanda Tangan without entering anything -> stores empty list & null fields
        await tester.ensureVisible(find.text('Simpan Tanda Tangan'));
        await tester.tap(find.text('Simpan Tanda Tangan'));
        await tester.pumpAndSettle();
        final savedBulanan =
            contract.kegiatans[0]['laporanBulanan_1'] as Map<String, dynamic>?;
        expect(savedBulanan?['ttdList'], isEmpty);
        expect(savedBulanan?['ttdKontraktorNama'], isNull);
        expect(savedBulanan?['ttdKontraktorJabatan'], isNull);
      },
    );
  });

  group('Bug 3: Mobile Laporan Bulanan Metrics Responsive Layout', () {
    testWidgets(
      '6. Rencana, Realisasi, Deviasi render cleanly without overflow or collision across 320px-430px viewports',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final contract = SampleContractData.getDemoContract();
        final provider = ContractProvider();
        final userProf = makeKonsultanProfile();

        for (final size in [
          const Size(320, 640),
          const Size(360, 780),
          const Size(390, 844),
          const Size(430, 932),
        ]) {
          FlutterErrorDetails? overflowErr;
          final prevOnError = FlutterError.onError;
          FlutterError.onError = (details) {
            overflowErr = details;
          };

          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          try {
            await tester.pumpWidget(
              MultiProvider(
                providers: [
                  ChangeNotifierProvider<ContractProvider>.value(value: provider),
                  ChangeNotifierProvider<UserProfileProvider>.value(
                    value: userProf,
                  ),
                ],
                child: MaterialApp(
                  home: LaporanBulananScreen(initialContract: contract),
                ),
              ),
            );
            await tester.pumpAndSettle();
            if (!provider.contracts.any((c) => c.id == contract.id)) {
              await provider.addContract(contract);
              await tester.pumpAndSettle();
            }

            await tester.scrollUntilVisible(
              find.text('Tanda Tangan').first,
              150,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
          } finally {
            FlutterError.onError = prevOnError;
          }
          expect(
            overflowErr,
            isNull,
            reason: 'Unexpected layout error at width ${size.width}: $overflowErr',
          );

          final rencanaRect = tester.getRect(find.text('Rencana').first);
          final realisasiRect = tester.getRect(find.text('Realisasi').first);
          final deviasiRect = tester.getRect(find.text('Deviasi').first);
          final signRect = tester.getRect(find.text('Tanda Tangan').first);

          // 3 metric columns sit horizontally side-by-side without overlap
          expect(rencanaRect.right, lessThan(realisasiRect.left));
          expect(realisasiRect.right, lessThan(deviasiRect.left));

          // On mobile compact width, action button moves below the metrics row
          expect(signRect.top, greaterThanOrEqualTo(deviasiRect.bottom));

          // Values remain intact
          expect(find.text('40.78%'), findsWidgets);

          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        }
      },
    );
  });

  group('Bug 4: SplashScreen Web Footer Removal & Mobile Preservation', () {
    testWidgets(
      '7. SplashScreen hides landingpage.png wave on Desktop (Web-sized) while preserving it on Android mobile',
      (tester) async {
        bool hasLandingWaveImage() {
          return tester.widgetList<Image>(find.byType(Image)).any((img) {
            final provider = img.image;
            return provider is AssetImage &&
                provider.assetName == 'assets/images/landingpage.png';
          });
        }

        // Desktop viewport -> wave hidden so logo & loader are never covered
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        final userProfDesktop = UserProfileProvider();
        final desktopRouter = createAppRouter(userProfDesktop);
        await tester.pumpWidget(
          buildRoutedApp(userProf: userProfDesktop, router: desktopRouter),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(hasLandingWaveImage(), isFalse);
        expect(find.text('Memuat aplikasi...'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        desktopRouter.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();

        // Native mobile viewport (VM kIsWeb=false) -> wave preserved
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        final userProfMobile = UserProfileProvider();
        final mobileRouter = createAppRouter(userProfMobile);
        await tester.pumpWidget(
          buildRoutedApp(userProf: userProfMobile, router: mobileRouter),
        );
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(hasLandingWaveImage(), isTrue);
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();
        mobileRouter.dispose();
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });

  group('Bug 5: Web Dashboard -> Kontrak -> Dashboard State & Content Sync', () {
    testWidgets(
      '8. Web Desktop ShellRoute syncs sidebar selection and content on Dashboard -> Kontrak -> Dashboard',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        resetShellRouteHistory();
        final userProf = makeKonsultanProfile();

        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = createAppRouter(userProf, initialLocation: '/dashboard');
        addTearDown(router.dispose);

        await tester.pumpWidget(
          buildRoutedApp(userProf: userProf, router: router),
        );
        await tester.pumpAndSettle();

        expect(router.routeInformationProvider.value.uri.path, '/dashboard');
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(KontrakScreen), findsNothing);
        // Should only have outer ShellRoute WebDashboardLayout, never nested double sidebar
        expect(find.byType(WebDashboardLayout), findsOneWidget);

        // Navigate Dashboard -> Kontrak via Web sidebar
        await tester.tap(find.text('Kontrak').first);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/kontrak');
        expect(find.byType(KontrakScreen), findsOneWidget);
        expect(find.byType(DashboardScreen), findsNothing);

        // Navigate Kontrak -> Dashboard via Web sidebar
        await tester.tap(find.text('Dashboard').first);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/dashboard');
        expect(find.byType(DashboardScreen), findsOneWidget);
        expect(find.byType(KontrakScreen), findsNothing);
      },
    );

    testWidgets(
      '9. Standalone DashboardScreen inside WebShellScope ignores stale initialMenu and syncs back history outside router',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final userProf = makeKonsultanProfile();

        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider(create: (_) => ContractProvider()),
              ChangeNotifierProvider(create: (_) => TimelineProvider()),
            ],
            child: const MaterialApp(
              home: DashboardScreen(initialMenu: 'kontrak'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(KontrakScreen), findsOneWidget);

        // Click Dashboard in sidebar -> returns cleanly from Kontrak to Dashboard content
        await tester.tap(find.text('Dashboard').first);
        await tester.pumpAndSettle();
        expect(find.byType(KontrakScreen), findsNothing);
        expect(find.text('Cari Kontrak...'), findsNothing);
      },
    );
  });

  group('Modul Laporan Adjustment: Status Mingguan, Kartu Laporan, & Sidebar', () {
    test(
      '10. Weekly period status turns Completed automatically after endDate without saved report (20-26 Nov vs 27 Nov-3 Des on 27 Nov 2026)',
      () {
        final contract = ContractModel(
          id: 'c-weekly-status-nov',
          namaKontrak: 'Pemeliharaan Ruas November',
          jenisKegiatan: 'Pengawasan',
          instansiDinas: ['DPUPR'],
          nilaiKontrak: 'Rp 300.000.000,00',
          hariKalender: 21,
          nomorSpk: '01/SPK/2026',
          tglMulaiSpk: '20 November 2026',
          nomorSpmk: '01/SPMK/2026',
          tglMulaiSpmk: '20 November 2026',
          tglSelesaiSpmk: '10 Desember 2026',
          sumberDana: 'APBD',
          deskripsi: 'Paket uji status mingguan November',
          kegiatans: [
            {
              'namaKegiatan': 'Paket Nov',
              'tglMulaiPelaksanaan': '20 November 2026',
              'tglSelesaiPelaksanaan': '10 Desember 2026',
              'masaPelaksanaanHari': 21,
              'laporans': [],
              'laporanMingguan': [],
            },
          ],
        );

        final periods = ExecutionPeriodHelper.generateWeeklyPeriods(
          contract: contract,
          kegMap: contract.kegiatans.first,
          referenceDate: DateTime(2026, 11, 27),
        );

        expect(periods.length, greaterThanOrEqualTo(3));
        expect(periods[0].mingguKe, 1);
        expect(periods[0].status, WeeklyPeriodStatus.completed);
        expect(periods[0].statusLabel, 'Completed');
        expect(periods[1].mingguKe, 2);
        expect(periods[1].status, WeeklyPeriodStatus.onProgress);
        expect(periods[1].statusLabel, 'On Progress');
        expect(periods[2].mingguKe, 3);
        expect(periods[2].status, WeeklyPeriodStatus.upcoming);
        expect(periods[2].statusLabel, 'Upcoming');
      },
    );

    testWidgets(
      '11. LaporanScreen renders exact card order on Web & Mobile without Data Laporan / mingguan text',
      (tester) async {
        final userProf = UserProfileProvider()
          ..loginAs(const RegisteredUser(
            username: 'konsultan_order',
            password: 'password123',
            role: 'Konsultan',
            namaLengkap: 'Konsultan Uji',
            companyOrAgency: 'CV. Tata Saka Consultant',
          ));
        final contractProv = ContractProvider();

        for (final size in const [Size(1280, 800), Size(412, 915)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<UserProfileProvider>.value(
                  value: userProf,
                ),
                ChangeNotifierProvider<ContractProvider>.value(
                  value: contractProv,
                ),
              ],
              child: const MaterialApp(home: LaporanScreen()),
            ),
          );
          await tester.pumpAndSettle();

          final buatPos = tester.getTopLeft(find.text('Buat Laporan Harian')).dy;
          final harianPos = tester
              .getTopLeft(find.text('Laporan Harian').last)
              .dy;
          final mingguanPos = tester
              .getTopLeft(find.text('Laporan Mingguan').last)
              .dy;
          final bulananPos = tester
              .getTopLeft(find.text('Laporan Bulanan').last)
              .dy;

          expect(buatPos, lessThan(harianPos));
          expect(harianPos, lessThan(mingguanPos));
          expect(mingguanPos, lessThan(bulananPos));
          expect(find.text('Data Laporan'), findsNothing);
          expect(find.textContaining('laporan harian & mingguan'), findsNothing);
        }

        // Dinas tetap view-only pada LaporanScreen dengan menu Laporan Harian
        userProf.loginAs(const RegisteredUser(
          username: 'dinas_order',
          password: 'password123',
          role: 'Dinas',
          namaLengkap: 'Dinas Uji',
          companyOrAgency: 'DPU-PR Kab. Purbalingga',
        ));
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(
                value: userProf,
              ),
              ChangeNotifierProvider<ContractProvider>.value(
                value: contractProv,
              ),
            ],
            child: const MaterialApp(home: LaporanScreen()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Buat Laporan Harian'), findsNothing);
        expect(find.text('Laporan Harian'), findsOneWidget);
        expect(find.textContaining('menu Laporan Harian'), findsOneWidget);
      },
    );

    testWidgets(
      '12. DetailDataLaporanScreen shows daily reports only (even with initialTab: 1) & DetailKegiatan opens LaporanMingguanScreen',
      (tester) async {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final sample = makeUnsavedContract();
        final contractProv = ContractProvider();
        await contractProv.addContract(sample);
        final userProf = UserProfileProvider()
          ..loginAs(const RegisteredUser(
            username: 'konsultan_harian',
            password: 'password123',
            role: 'Konsultan',
            namaLengkap: 'Konsultan Uji',
            companyOrAgency: 'CV. Tata Saka Consultant',
          ));

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider<ContractProvider>.value(
                value: contractProv,
              ),
              ChangeNotifierProvider(create: (_) => TimelineProvider()),
            ],
            child: MaterialApp(
              home: DetailDataLaporanScreen(
                contract: sample,
                kegiatanIndex: 0,
                initialTab: 1,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Laporan Harian'), findsOneWidget);
        expect(find.text('Data Laporan'), findsNothing);
        expect(find.text('Mingguan'), findsNothing);

        // Pastikan DetailKegiatanScreen folder Ringkasan Mingguan menuju LaporanMingguanScreen
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider<ContractProvider>.value(
                value: contractProv,
              ),
              ChangeNotifierProvider(create: (_) => TimelineProvider()),
            ],
            child: MaterialApp(
              home: DetailKegiatanScreen(contract: sample, kegiatanIndex: 0),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final folderMingguan = find.text('Laporan Mingguan');
        if (folderMingguan.evaluate().isNotEmpty) {
          await tester.ensureVisible(folderMingguan.first);
          await tester.tap(folderMingguan.first);
          await tester.pumpAndSettle();
          final weeklyBtn = find.text('Buka Data Ringkasan Mingguan');
          expect(weeklyBtn, findsOneWidget);
          await tester.ensureVisible(weeklyBtn);
          await tester.tap(weeklyBtn);
          await tester.pumpAndSettle();
          expect(find.byType(LaporanMingguanScreen), findsOneWidget);
        }
      },
    );

    testWidgets(
      '13. Web Sidebar & Mobile Dark Drawer route Laporan Harian -> /laporan/data and hide Data Laporan (Konsultan & Dinas)',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        // Desktop Web: klik Laporan Harian di sidebar -> /laporan/data (DataLaporanScreen)
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final userProf = UserProfileProvider()
          ..loginAs(const RegisteredUser(
            username: 'konsultan_nav_11',
            password: 'password123',
            role: 'Konsultan',
            namaLengkap: 'Konsultan Nav',
            companyOrAgency: 'CV. Tata Saka Consultant',
          ));
        final router = createAppRouter(
          userProf,
          initialLocation: '/dashboard',
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider(create: (_) => ContractProvider()),
              ChangeNotifierProvider(create: (_) => TimelineProvider()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Data Laporan'), findsNothing);
        await tester.tap(find.text('Laporan Harian').first);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/laporan/data');
        expect(find.byType(DataLaporanScreen), findsOneWidget);
        expect(find.byType(BuatLaporanScreen), findsNothing);

        // Dinas mobile dark drawer: punya Laporan Harian -> /laporan/data, tanpa Mingguan/Bulanan/Data Laporan
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;
        userProf.loginAs(const RegisteredUser(
          username: 'dinas_nav_11',
          password: 'password123',
          role: 'Dinas',
          namaLengkap: 'Dinas Nav',
          companyOrAgency: 'DPU-PR Kab. Purbalingga',
        ));
        router.go('/dashboard');
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();

        expect(find.text('Data Laporan'), findsNothing);
        expect(find.text('Buat Laporan'), findsNothing);
        expect(find.text('Laporan Mingguan'), findsNothing);
        expect(find.text('Laporan Bulanan'), findsNothing);
        final harianDrawerItem = find.text('Laporan Harian').last;
        await tester.tap(harianDrawerItem);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/laporan/data');
        expect(find.byType(DataLaporanScreen), findsOneWidget);
      },
    );

    testWidgets(
      '14. Web Sidebar & Mobile Dark Drawer Pelaporan section shows exact 5 ordered menus, routes correctly, and tracks active menu',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        bool isWebSidebarKeyActive(String key) {
          final itemFinder = find.byKey(ValueKey('sidebar_$key'));
          final activeContainer = find.descendant(
            of: itemFinder,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is AnimatedContainer &&
                  w.decoration is BoxDecoration &&
                  (w.decoration as BoxDecoration).color ==
                      const Color(0xFF1E293B),
            ),
          );
          return activeContainer.evaluate().isNotEmpty;
        }

        final userProf = UserProfileProvider()
          ..loginAs(const RegisteredUser(
            username: 'konsultan_5menu',
            password: 'password123',
            role: 'Konsultan',
            namaLengkap: 'Konsultan 5 Menu',
            companyOrAgency: 'CV. Tata Saka Consultant',
          ));
        final router = createAppRouter(
          userProf,
          initialLocation: '/dashboard',
        );
        addTearDown(router.dispose);

        // 1. Desktop Web (>= 900px)
        tester.view.physicalSize = const Size(1280, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider(create: (_) => ContractProvider()),
              ChangeNotifierProvider(create: (_) => TimelineProvider()),
            ],
            child: MaterialApp.router(routerConfig: router),
          ),
        );
        await tester.pumpAndSettle();

        final laporanDy = tester
            .getTopLeft(find.byKey(const ValueKey('sidebar_laporan')))
            .dy;
        final buatDy = tester
            .getTopLeft(find.byKey(const ValueKey('sidebar_buat_laporan')))
            .dy;
        final harianDy = tester
            .getTopLeft(find.byKey(const ValueKey('sidebar_laporan_harian')))
            .dy;
        final mingguanDy = tester
            .getTopLeft(find.byKey(const ValueKey('sidebar_laporan_mingguan')))
            .dy;
        final bulananDy = tester
            .getTopLeft(find.byKey(const ValueKey('sidebar_laporan_bulanan')))
            .dy;

        expect(laporanDy, lessThan(buatDy));
        expect(buatDy, lessThan(harianDy));
        expect(harianDy, lessThan(mingguanDy));
        expect(mingguanDy, lessThan(bulananDy));

        final webCases = <(String, String, Type)>[
          ('laporan', '/laporan', LaporanScreen),
          ('buat_laporan', '/laporan/harian', BuatLaporanScreen),
          ('laporan_harian', '/laporan/data', DataLaporanScreen),
          ('laporan_mingguan', '/laporan/mingguan', LaporanMingguanScreen),
          ('laporan_bulanan', '/laporan/bulanan', LaporanBulananScreen),
        ];

        for (final (menuKey, expectedPath, expectedScreen) in webCases) {
          final itemFinder = find.byKey(ValueKey('sidebar_$menuKey'));
          await tester.ensureVisible(itemFinder);
          await tester.tap(itemFinder);
          await tester.pumpAndSettle();
          expect(router.routeInformationProvider.value.uri.path, expectedPath);
          expect(find.byType(expectedScreen), findsOneWidget);
          expect(
            isWebSidebarKeyActive(menuKey),
            isTrue,
            reason: 'Web sidebar "$menuKey" should be active at $expectedPath',
          );
        }

        // Pastikan BuatLaporanScreen tanpa GoRouter juga menandai Buat Laporan aktif
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider(create: (_) => ContractProvider()),
              ChangeNotifierProvider(create: (_) => TimelineProvider()),
            ],
            child: const MaterialApp(home: BuatLaporanScreen()),
          ),
        );
        await tester.pumpAndSettle();
        expect(isWebSidebarKeyActive('buat_laporan'), isTrue);
        expect(isWebSidebarKeyActive('laporan'), isFalse);

        // 2. Mobile Dark Drawer (< 900px)
        tester.view.physicalSize = const Size(540, 960);
        tester.view.devicePixelRatio = 1.0;

        final mobileRouter = createAppRouter(
          userProf,
          initialLocation: '/dashboard',
        );
        addTearDown(mobileRouter.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider(create: (_) => ContractProvider()),
              ChangeNotifierProvider(create: (_) => TimelineProvider()),
            ],
            child: MaterialApp.router(routerConfig: mobileRouter),
          ),
        );
        await tester.pumpAndSettle();

        final mobileCases = <(String, String, Type)>[
          ('Laporan', '/laporan', LaporanScreen),
          ('Buat Laporan', '/laporan/harian', BuatLaporanScreen),
          ('Laporan Harian', '/laporan/data', DataLaporanScreen),
          ('Laporan Mingguan', '/laporan/mingguan', LaporanMingguanScreen),
          ('Laporan Bulanan', '/laporan/bulanan', LaporanBulananScreen),
        ];

        // Periksa urutan ke-5 item di Mobile Dark Drawer
        await tester.tap(find.byIcon(Icons.menu));
        await tester.pumpAndSettle();
        final drawerFinder = find.byKey(const ValueKey('mobile_dark_drawer'));
        expect(drawerFinder, findsOneWidget);
        expect(
          tester.widget<Container>(drawerFinder).color,
          const Color(0xFF0F172A),
        );

        double prevDy = -1.0;
        for (final (label, _, _) in mobileCases) {
          final itemFinder = find.descendant(
            of: drawerFinder,
            matching: find.text(label),
          );
          await tester.scrollUntilVisible(
            itemFinder,
            120,
            scrollable: find.descendant(
              of: drawerFinder,
              matching: find.byType(Scrollable),
            ),
          );
          final dy = tester.getTopLeft(itemFinder).dy;
          expect(dy, greaterThan(prevDy));
          prevDy = dy;
        }

        // Tutup drawer dengan memilih item pertama ('Laporan'), lalu uji semua 5 tujuan
        for (final (label, expectedPath, expectedScreen) in mobileCases) {
          if (drawerFinder.evaluate().isEmpty) {
            mobileRouter.go('/dashboard');
            await tester.pumpAndSettle();
            await tester.tap(find.byIcon(Icons.menu));
            await tester.pumpAndSettle();
          }
          final itemFinder = find.descendant(
            of: drawerFinder,
            matching: find.text(label),
          );
          await tester.scrollUntilVisible(
            itemFinder,
            120,
            scrollable: find.descendant(
              of: drawerFinder,
              matching: find.byType(Scrollable),
            ),
          );
          await tester.ensureVisible(itemFinder);
          await tester.pumpAndSettle();
          await tester.tap(itemFinder);
          await tester.pumpAndSettle();
          expect(
            mobileRouter.routeInformationProvider.value.uri.path,
            expectedPath,
          );
          expect(find.byType(expectedScreen), findsOneWidget);
        }
      },
    );
  });
}
