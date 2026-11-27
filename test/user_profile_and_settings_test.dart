import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/edit_profil_screen.dart';
import 'package:tata_saka_app/screens/keamanan_screen.dart';
import 'package:tata_saka_app/screens/pengaturan_screen.dart';
import 'package:tata_saka_app/screens/setting_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const konsultanUser = RegisteredUser(
    username: 'konsultan',
    password: 'password123',
    role: 'Konsultan',
    namaLengkap: 'CV. Tata Saka Consultant',
    companyOrAgency: 'CV. Tata Saka Consultant',
  );

  group('UserProfileProvider Unit Tests', () {
    test('Initial profile starts unauthenticated & empty, and loginAs populates authenticated Konsultan credentials', () async {
      final provider = UserProfileProvider();
      expect(provider.isAuthenticated, isFalse);
      expect(provider.namaLengkap, isEmpty);
      expect(provider.username, isEmpty);
      expect(provider.role, isEmpty);
      expect(provider.profileImagePath, isNull);
      expect(provider.cacheSize, '0 KB');
      expect(provider.loginActivities, isEmpty);

      provider.loginAs(konsultanUser);
      expect(provider.isAuthenticated, isTrue);
      expect(provider.namaLengkap, 'CV. Tata Saka Consultant');
      expect(provider.username, 'konsultan');
      expect(provider.role, 'Konsultan');
      expect(provider.profileImagePath, isNull);
      expect(provider.verifyCurrentPassword('password123'), isTrue);
    });

    test('Updating namaLengkap works and preserves username & role', () async {
      final provider = UserProfileProvider()..loginAs(konsultanUser);
      provider.updateNamaLengkap('CV. Tata Saka Konsultan Utama');
      expect(provider.namaLengkap, 'CV. Tata Saka Konsultan Utama');
      expect(provider.username, 'konsultan');
      expect(provider.role, 'Konsultan');
    });

    test('Updating theme and language updates preferences', () async {
      final provider = UserProfileProvider();
      provider.updateTheme('Gelap');
      expect(provider.themeMode, 'Gelap');
      expect(provider.flutterThemeMode, ThemeMode.dark);

      provider.updateTheme('Mengikuti Sistem');
      expect(provider.flutterThemeMode, ThemeMode.system);

      provider.updateLanguage('English');
      expect(provider.language, 'English');
    });

    test('Notification toggles update correctly', () async {
      final provider = UserProfileProvider();
      provider.setNotifikasiPush(false);
      provider.setEmailNotifikasi(false);
      provider.setNotifikasiProyek(false);
      provider.setNotifikasiLaporan(false);

      expect(provider.notifikasiPush, isFalse);
      expect(provider.emailNotifikasi, isFalse);
      expect(provider.notifikasiProyek, isFalse);
      expect(provider.notifikasiLaporan, isFalse);
    });

    test('Changing password validates old password and stores new password', () async {
      final provider = UserProfileProvider()..loginAs(konsultanUser);
      final failed = await provider.changePassword('wrongpass', 'NewPass123!');
      expect(failed, isFalse);
      expect(provider.verifyCurrentPassword('password123'), isTrue);

      final success = await provider.changePassword('password123', 'Secret2026#');
      expect(success, isTrue);
      expect(provider.verifyCurrentPassword('Secret2026#'), isTrue);
    });

    test('Clearing cache resets cache size to 0 KB', () async {
      final provider = UserProfileProvider();
      expect(provider.cacheSize, '0 KB');
      provider.clearCache();
      expect(provider.cacheSize, '0 KB');
    });

    test('Logout from all other devices handles empty sessions safely without dummy data', () async {
      final provider = UserProfileProvider();
      expect(provider.loginActivities, isEmpty);
      provider.logoutFromAllOtherDevices();
      expect(provider.loginActivities, isEmpty);
    });

    test('Enforced auth drops cached user_profile_data when Firebase Auth user is null', () async {
      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'uid-dinas-old',
          'username': 'dinas_pupr',
          'role': 'Dinas',
          'namaLengkap': 'Dinas PUPR',
          'companyOrAgency': 'Dinas PUPR Kab. Purbalingga',
        }),
      });

      final provider = UserProfileProvider(
        authSessionResolver: () async => (enforceAuth: true, uid: null),
      );
      while (!provider.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(provider.isAuthenticated, isFalse);
      expect(provider.username, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_profile_data'), isNull);
    });

    test('Enforced auth drops cached user_profile_data when UID mismatches active Firebase Auth session', () async {
      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'uid-dinas-old',
          'username': 'dinas_pupr',
          'role': 'Dinas',
          'namaLengkap': 'Dinas PUPR',
          'companyOrAgency': 'Dinas PUPR Kab. Purbalingga',
        }),
      });

      final provider = UserProfileProvider(
        authSessionResolver: () async => (enforceAuth: true, uid: 'uid-konsultan-new'),
      );
      while (!provider.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(provider.isAuthenticated, isFalse);
      expect(provider.username, isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_profile_data'), isNull);
    });

    test('Enforced auth restores cached profile when UID matches active Firebase Auth session', () async {
      SharedPreferences.setMockInitialValues({
        'user_profile_data': jsonEncode({
          'uid': 'uid-konsultan-1',
          'username': 'konsultan1',
          'role': 'Konsultan',
          'namaLengkap': 'Konsultan Uji',
          'companyOrAgency': 'CV. Tata Saka Consultant',
        }),
      });

      final provider = UserProfileProvider(
        authSessionResolver: () async => (enforceAuth: true, uid: 'uid-konsultan-1'),
      );
      while (!provider.isInitialized) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }

      expect(provider.isAuthenticated, isTrue);
      expect(provider.uid, 'uid-konsultan-1');
      expect(provider.username, 'konsultan1');
      expect(provider.role, 'Konsultan');
    });
  });

  group('Page Akun & Settings Widget Tests', () {
    Widget buildTestApp(Widget child, {UserProfileProvider? userProf, ContractProvider? contractProv}) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => userProf ?? UserProfileProvider()),
          ChangeNotifierProvider(create: (_) => contractProv ?? ContractProvider()),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('SettingScreen (Akun) renders Profile, Proyek Terkait, and Menu Lainnya', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final userProf = UserProfileProvider()..loginAs(konsultanUser);
      final contractProv = ContractProvider();
      await contractProv.addContract(
        ContractModel(
          id: 'ktr-akun-test-1',
          namaKontrak: 'PAKET PENGAWASAN RUAS UJI',
          jenisKegiatan: 'Pengawasan Teknis',
          nomorSpk: 'SPK-01',
          tglMulaiSpk: '20 April 2026',
          nomorSpmk: 'SPMK-01',
          tglMulaiSpmk: '20 April 2026',
          tglSelesaiSpmk: '18 Juli 2026',
          hariKalender: 90,
          nilaiKontrak: 'Rp 250.000.000,00',
          instansiDinas: ['DPU-PR'],
          sumberDana: 'APBD',
          deskripsi: 'Kontrak terkait uji tampilan Akun',
          kegiatans: [],
        ),
      );

      await tester.pumpWidget(
        buildTestApp(
          const SettingScreen(),
          userProf: userProf,
          contractProv: contractProv,
        ),
      );
      await tester.pumpAndSettle();

      // Pada layout Web Desktop (>= 900px), terdapat menu sidebar 'Akun' & judul header 'Akun'
      final sidebarAkun = find.byKey(const ValueKey('sidebar_akun'));
      expect(sidebarAkun, findsOneWidget);
      expect(find.descendant(of: sidebarAkun, matching: find.text('Akun')), findsOneWidget);
      expect(find.text('Akun'), findsNWidgets(2));

      expect(find.text('CV. Tata Saka Consultant'), findsWidgets);
      expect(find.text('konsultan'), findsOneWidget);
      expect(find.text('Konsultan'), findsWidgets);

      // Proyek Terkait
      expect(find.text('Proyek Terkait'), findsOneWidget);
      expect(find.textContaining('PAKET PENGAWASAN RUAS UJI'), findsOneWidget);

      // Menu Lainnya
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Bantuan & FAQ'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('EditProfilScreen renders editable Nama Lengkap and disabled Username & Role', (tester) async {
      final userProf = UserProfileProvider()..loginAs(konsultanUser);
      await tester.pumpWidget(buildTestApp(const EditProfilScreen(), userProf: userProf));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Tap untuk ganti foto'), findsOneWidget);
      expect(find.text('Informasi Profil'), findsOneWidget);

      // Cari TextFormField untuk Nama Lengkap dan ubah
      final nameFields = find.widgetWithText(TextFormField, 'CV. Tata Saka Consultant');
      expect(nameFields, findsOneWidget);

      await tester.enterText(nameFields, 'CV. Tata Saka Perubahan');
      await tester.pumpAndSettle();

      // Klik tombol Simpan Profil di kanan atas
      final saveBtn = find.byIcon(Icons.save_rounded);
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(userProf.namaLengkap, 'CV. Tata Saka Perubahan');
      expect(userProf.username, 'konsultan');
      expect(userProf.role, 'Konsultan');
    });

    testWidgets('PengaturanScreen renders preferences and handles backup info & clear cache', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final userProf = UserProfileProvider();
      await tester.pumpWidget(buildTestApp(const PengaturanScreen(), userProf: userProf));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Preferensi Aplikasi'), findsOneWidget);
      expect(find.text('Tema Aplikasi'), findsOneWidget);
      expect(find.text('Bahasa'), findsOneWidget);

      // Notifikasi
      expect(find.text('Notifikasi Push'), findsOneWidget);
      expect(find.text('Email Notifikasi'), findsOneWidget);
      expect(find.text('Notifikasi Proyek'), findsOneWidget);
      expect(find.text('Notifikasi Laporan'), findsOneWidget);

      // Backup Data tap shows Version 2.0.0 info
      await tester.tap(find.text('Backup Data'));
      await tester.pumpAndSettle();
      expect(find.text('Informasi Backup Cloud'), findsOneWidget);
      expect(find.textContaining('Versi 2.0.0'), findsOneWidget);

      await tester.tap(find.text('Mengerti'));
      await tester.pumpAndSettle();

      // Bersihkan Cache tap
      await tester.tap(find.text('Bersihkan Cache'));
      await tester.pumpAndSettle();
      expect(find.text('Bersihkan Cache'), findsWidgets);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Bersihkan'));
      await tester.pumpAndSettle();
      expect(userProf.cacheSize, '0 KB');
    });

    testWidgets('KeamananScreen validates password criteria in real-time', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final userProf = UserProfileProvider()..loginAs(konsultanUser);
      await tester.pumpWidget(buildTestApp(const KeamananScreen(), userProf: userProf));
      await tester.pumpAndSettle();

      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Ubah Password'), findsOneWidget);
      expect(find.text('Syarat Password'), findsOneWidget);
      expect(find.text('Minimal 8 Karakter'), findsOneWidget);
      expect(find.text('Mengandung huruf besar dan kecil'), findsOneWidget);
      expect(find.text('Mengandung angka'), findsOneWidget);
      expect(find.text('Mengandung simbol'), findsOneWidget);

      // Aktivitas Login Terakhir tanpa data dummy palsu
      expect(find.text('Aktivitas Login Terakhir'), findsOneWidget);
      expect(find.text('iPhone 11'), findsNothing);
      expect(find.text('Lihat Semua Aktivitas'), findsOneWidget);
      expect(find.text('Keluar Dari Semua Perangkat'), findsOneWidget);

      // Input password
      final currentPassField = find.widgetWithText(TextFormField, 'Masukkan password saat ini');
      final newPassField = find.widgetWithText(TextFormField, 'Masukkan password baru');
      final confirmPassField = find.widgetWithText(TextFormField, 'Masukkan kembali password baru');

      await tester.enterText(currentPassField, 'password123');
      await tester.enterText(newPassField, 'SuperKuat2026!');
      await tester.enterText(confirmPassField, 'SuperKuat2026!');
      await tester.pumpAndSettle();

      // Simpan password
      await tester.tap(find.widgetWithText(ElevatedButton, 'Simpan Password'));
      await tester.pumpAndSettle();

      expect(userProf.verifyCurrentPassword('SuperKuat2026!'), isTrue);
    });
  });
}
