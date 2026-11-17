import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleContract = ContractModel(
    id: 'test_contract_01',
    jenisKegiatan: 'Pekerjaan Konstruksi',
    namaKontrak: 'Pembangunan Jembatan Saka',
    nomorSpk: '602/01/SPK/2026',
    tglMulaiSpk: '01 Januari 2026',
    nomorSpmk: '602/01/SPMK/2026',
    tglMulaiSpmk: '01 Januari 2026',
    tglSelesaiSpmk: '31 Desember 2026',
    hariKalender: 365,
    nilaiKontrak: 'Rp 1.500.000.000,00',
    instansiDinas: ['Dinas Pekerjaan Umum'],
    sumberDana: 'APBN',
    deskripsi: 'Pengawasan Lapangan',
    kegiatans: [
      {
        'namaKegiatan': 'Pekerjaan Pondasi Tiang Pancang',
        'lokasi': 'Sta 0+000 - 0+500',
        'kontraktor': 'CV Testing',
        'sumberDana': 'APBN',
        'rkkDivisiList': [
          {
            'romawi': 'DIVISI 1',
            'judul': 'UMUM',
            'items': [
              {
                'uraian': 'Mobilisasi dan Demobilisasi',
                'satuan': 'ls',
                'volume': 1.0,
                'hargaSatuan': 15000000.0,
              }
            ],
          }
        ],
        'folders': [
          {'name': 'Dokumen Kontrak', 'files': []},
        ],
        'laporans': [],
      }
    ],
  );

  Widget createTestApp({
    required Widget child,
    required UserProfileProvider userProfile,
    ContractProvider? contractProvider,
    TimelineProvider? timelineProvider,
    Size surfaceSize = const Size(1280, 800),
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProfileProvider>.value(value: userProfile),
        ChangeNotifierProvider<ContractProvider>.value(
          value: contractProvider ?? ContractProvider(),
        ),
        ChangeNotifierProvider<TimelineProvider>.value(
          value: timelineProvider ?? TimelineProvider(),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: child,
        ),
      ),
    );
  }

  group('Sidebar Alignment and Feature Access Audit', () {
    testWidgets(
      '1. Web Mode: Sidebar excludes RAB/BoQ, Addendum CCO, and Administrasi Dokumen',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));

        tester.view.physicalSize = const Size(1280, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestApp(
            child: const DashboardScreen(),
            userProfile: konsultanProfile,
            surfaceSize: const Size(1280, 1200),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Sidebar contains expected structured categories
        expect(find.text('UTAMA'), findsOneWidget);
        expect(find.text('PELAPORAN'), findsOneWidget);
        expect(find.text('DOKUMEN & HISTORI'), findsOneWidget);
        expect(find.text('AKUN & PENGATURAN'), findsOneWidget);
        expect(find.text('BANTUAN'), findsOneWidget);

        // 2. The 3 removed items and their former category are completely absent
        expect(find.text('TEKNIS & ANGGARAN'), findsNothing);
        expect(find.text('RAB / BoQ'), findsNothing);
        expect(find.text('Addendum CCO'), findsNothing);
        expect(find.text('Administrasi Dokumen'), findsNothing);
      },
    );

    testWidgets(
      '2. Mobile Mode: Drawer excludes RAB/BoQ, Addendum CCO, and Administrasi Dokumen',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));

        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestApp(
            child: const DashboardScreen(),
            userProfile: konsultanProfile,
            surfaceSize: const Size(400, 800),
          ),
        );
        await tester.pumpAndSettle();

        // Open mobile drawer via hamburger icon
        final menuBtn = find.byIcon(Icons.menu);
        expect(menuBtn, findsOneWidget);
        await tester.tap(menuBtn);
        await tester.pumpAndSettle();

        // Check drawer categories
        expect(find.text('UTAMA'), findsOneWidget);
        expect(find.text('PELAPORAN'), findsOneWidget);

        // Verify that the 3 removed items are absent in Mobile Drawer
        expect(find.text('TEKNIS & ANGGARAN'), findsNothing);
        expect(find.text('RAB / BoQ'), findsNothing);
        expect(find.text('Addendum CCO'), findsNothing);
        expect(find.text('Administrasi Dokumen'), findsNothing);
      },
    );

    testWidgets(
      '3. DetailKegiatanScreen retains full access to RAB/BoQ, Addendum CCO, and Folder Administrasi',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));

        tester.view.physicalSize = const Size(1280, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestApp(
            child: DetailKegiatanScreen(
              contract: sampleContract,
              kegiatanIndex: 0,
            ),
            userProfile: konsultanProfile,
            surfaceSize: const Size(1280, 2400),
          ),
        );
        await tester.pumpAndSettle();

        // 1. RAB / BoQ Action Card exists
        expect(find.text('Rincian Kuantitas & Bobot Pekerjaan'), findsOneWidget);
        expect(find.text('Kelola Rincian Pekerjaan (RKK)'), findsOneWidget);

        // 2. Addendum CCO action button exists
        expect(find.text('Kelola Addendum (CCO)'), findsOneWidget);

        // 3. Administrasi Dokumen folder exists
        expect(find.text('Folder Administrasi'), findsOneWidget);
        expect(find.text('Dokumen Kontrak'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Role Isolation: Kontraktor role hides Pelaporan in Web Sidebar and Mobile Drawer',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final kontraktorProfile = UserProfileProvider();
        kontraktorProfile.loginAs(const RegisteredUser(
          username: 'kontraktor',
          password: 'password123',
          role: 'Kontraktor',
          namaLengkap: 'PT. Kontraktor Andal',
          companyOrAgency: 'PT. Kontraktor Andal',
        ));

        // Web mode test
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestApp(
            child: const DashboardScreen(),
            userProfile: kontraktorProfile,
          ),
        );
        await tester.pumpAndSettle();

        // Pelaporan category is hidden for Kontraktor
        expect(find.text('PELAPORAN'), findsNothing);
        expect(find.text('Laporan Harian'), findsNothing);
        expect(find.text('Kegiatan Saya'), findsWidgets);

        // Removed items are also absent
        expect(find.text('TEKNIS & ANGGARAN'), findsNothing);
        expect(find.text('RAB / BoQ'), findsNothing);
        expect(find.text('Addendum CCO'), findsNothing);
      },
    );
  });
}
