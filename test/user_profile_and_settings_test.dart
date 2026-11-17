import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('UserProfileProvider Unit Tests', () {
    test('Initial profile and default credentials are correct', () async {
      final provider = UserProfileProvider();
      expect(provider.namaLengkap, 'CV. Tata Saka Consultant');
      expect(provider.username, 'konsultan');
      expect(provider.role, 'Konsultan');
      expect(provider.profileImagePath, isNull);
      expect(provider.verifyCurrentPassword('password123'), isTrue);
    });

    test('Updating namaLengkap works and preserves username & role', () async {
      final provider = UserProfileProvider();
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
      final provider = UserProfileProvider();
      final failed = await provider.changePassword('wrongpass', 'NewPass123!');
      expect(failed, isFalse);
      expect(provider.verifyCurrentPassword('password123'), isTrue);

      final success = await provider.changePassword('password123', 'Secret2026#');
      expect(success, isTrue);
      expect(provider.verifyCurrentPassword('Secret2026#'), isTrue);
    });

    test('Clearing cache resets cache size to 0 KB', () async {
      final provider = UserProfileProvider();
      expect(provider.cacheSize, '12.4 MB');
      provider.clearCache();
      expect(provider.cacheSize, '0 KB');
    });

    test('Logout from all other devices removes non-current sessions', () async {
      final provider = UserProfileProvider();
      expect(provider.loginActivities.length, greaterThan(1));
      provider.logoutFromAllOtherDevices();
      expect(provider.loginActivities.length, 1);
      expect(provider.loginActivities.first.isCurrent, isTrue);
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

      await tester.pumpWidget(buildTestApp(const SettingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Akun'), findsOneWidget);
      expect(find.text('CV. Tata Saka Consultant'), findsWidgets);
      expect(find.text('konsultan'), findsOneWidget);
      expect(find.text('Konsultan'), findsWidgets);

      // Proyek Terkait
      expect(find.text('Proyek Terkait'), findsOneWidget);
      expect(find.textContaining('PEMELIHARAAN BERKALA'), findsOneWidget);

      // Menu Lainnya
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Bantuan & FAQ'), findsOneWidget);
      expect(find.text('Keluar'), findsOneWidget);
    });

    testWidgets('EditProfilScreen renders editable Nama Lengkap and disabled Username & Role', (tester) async {
      final userProf = UserProfileProvider();
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

      final userProf = UserProfileProvider();
      await tester.pumpWidget(buildTestApp(const KeamananScreen(), userProf: userProf));
      await tester.pumpAndSettle();

      expect(find.text('Keamanan'), findsOneWidget);
      expect(find.text('Ubah Password'), findsOneWidget);
      expect(find.text('Syarat Password'), findsOneWidget);
      expect(find.text('Minimal 8 Karakter'), findsOneWidget);
      expect(find.text('Mengandung huruf besar dan kecil'), findsOneWidget);
      expect(find.text('Mengandung angka'), findsOneWidget);
      expect(find.text('Mengandung simbol'), findsOneWidget);

      // Aktivitas Login Terakhir
      expect(find.text('Aktivitas Login Terakhir'), findsOneWidget);
      expect(find.text('iPhone 11'), findsOneWidget);
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
