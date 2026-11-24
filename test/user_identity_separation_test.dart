import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/admin_page.dart';
import 'package:tata_saka_app/screens/edit_profil_screen.dart';
import 'package:tata_saka_app/screens/setting_screen.dart';
import 'package:tata_saka_app/services/auth_service.dart';

Widget _buildTestApp(Widget child, {UserProfileProvider? userProf, ContractProvider? contractProv}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => userProf ?? UserProfileProvider()),
      ChangeNotifierProvider(create: (_) => contractProv ?? ContractProvider()),
    ],
    child: MaterialApp(
      home: child,
      routes: {
        '/login': (_) => const Scaffold(body: Text('Login Screen')),
        '/main': (_) => const Scaffold(body: Text('Main Screen')),
        '/admin': (_) => const Scaffold(body: Text('Admin Screen')),
      },
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AuthService.mockIsUsernameTaken = null;
  });

  tearDown(() {
    AuthService.mockIsUsernameTaken = null;
  });

  group('Uji Pemisahan Identitas Username & Nama Lengkap (8 Skenario)', () {
    // ─── SKENARIO 1: Membuat akun baru dengan username dan nama lengkap yang berbeda ───
    testWidgets('Skenario 1: Formulir Tambah Akun memiliki 2 input terpisah untuk Username dan Nama Lengkap', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: const AdminPage(bypassAuthCheck: true),
          routes: {'/login': (_) => const Scaffold()},
        ),
      );
      await tester.pumpAndSettle();

      // Buka dialog Tambah Akun Baru
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Akun'));
      await tester.pumpAndSettle();

      expect(find.text('Tambah Akun Baru'), findsOneWidget);

      // Verifikasi keberadaan field Username (Identitas Login)
      final usernameFieldFinder = find.widgetWithText(TextFormField, 'Username (Identitas Login)');
      expect(usernameFieldFinder, findsOneWidget);

      // Verifikasi keberadaan field Nama Lengkap & Gelar (Identitas Personal)
      final namaLengkapFieldFinder = find.widgetWithText(TextFormField, 'Nama Lengkap & Gelar');
      expect(namaLengkapFieldFinder, findsOneWidget);

      // Keduanya adalah dua widget input yang berbeda dan terpisah
      expect(usernameFieldFinder, isNot(namaLengkapFieldFinder));

      // Isi Username dengan 'budi_kontraktor' dan Nama Lengkap dengan 'Budi Santoso, S.T.'
      await tester.enterText(usernameFieldFinder, 'budi_kontraktor');
      await tester.enterText(namaLengkapFieldFinder, 'Budi Santoso, S.T.');
      await tester.pumpAndSettle();

      expect(find.text('budi_kontraktor'), findsOneWidget);
      expect(find.text('Budi Santoso, S.T.'), findsOneWidget);
    });

    // ─── SKENARIO 2: Login menggunakan username dan password, bukan nama lengkap ───
    test('Skenario 2: Login memetakan Username ke kredensial akun dan Nama Lengkap ke identitas profil', () async {
      final profile = UserProfileProvider();

      // Simulasi user berhasil login dengan data dari Firestore
      profile.loginAs(const RegisteredUser(
        username: 'kontraktor_budi',
        password: 'password123',
        role: 'Kontraktor',
        namaLengkap: 'Budi Santoso, S.T.',
        companyOrAgency: 'PT. Maju Konstruksi',
      ));

      // Kredensial login adalah username
      expect(profile.username, 'kontraktor_budi');
      // Identitas personal adalah namaLengkap
      expect(profile.namaLengkap, 'Budi Santoso, S.T.');
      expect(profile.role, 'Kontraktor');
      expect(profile.companyOrAgency, 'PT. Maju Konstruksi');

      // Memastikan username dan namaLengkap tidak tertukar
      expect(profile.username, isNot(equals(profile.namaLengkap)));
    });

    // ─── SKENARIO 3: Memastikan nama lengkap ditampilkan dengan benar pada profil ───
    testWidgets('Skenario 3: Nama Lengkap ditampilkan pada halaman profil dan form edit profil', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final profile = UserProfileProvider();
      profile.loginAs(const RegisteredUser(
        username: 'konsultan_ahmad',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'Ir. Ahmad Dahlan, M.T.',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));

      await tester.pumpWidget(_buildTestApp(const SettingScreen(), userProf: profile));
      await tester.pumpAndSettle();

      // Nama Lengkap tampil di header profil
      expect(find.text('Ir. Ahmad Dahlan, M.T.'), findsWidgets);

      // Buka EditProfilScreen
      await tester.pumpWidget(_buildTestApp(const EditProfilScreen(), userProf: profile));
      await tester.pumpAndSettle();

      // Field Nama Lengkap berisi 'Ir. Ahmad Dahlan, M.T.' dan dapat diedit
      final namaField = find.widgetWithText(TextFormField, 'Ir. Ahmad Dahlan, M.T.');
      expect(namaField, findsOneWidget);
    });

    // ─── SKENARIO 4: Memastikan username tetap ditampilkan sebagai identitas akun ───
    testWidgets('Skenario 4: Username tetap ditampilkan sebagai identitas akun di SettingScreen & EditProfilScreen', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final profile = UserProfileProvider();
      profile.loginAs(const RegisteredUser(
        username: 'konsultan_ahmad',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'Ir. Ahmad Dahlan, M.T.',
        companyOrAgency: 'CV. Tata Saka Consultant',
      ));

      // Verifikasi di SettingScreen
      await tester.pumpWidget(_buildTestApp(const SettingScreen(), userProf: profile));
      await tester.pumpAndSettle();

      expect(find.text('konsultan_ahmad'), findsOneWidget);

      // Verifikasi di EditProfilScreen: username tampil dan berstatus disabled/read-only
      await tester.pumpWidget(_buildTestApp(const EditProfilScreen(), userProf: profile));
      await tester.pumpAndSettle();

      final usernameField = find.widgetWithText(TextFormField, 'konsultan_ahmad');
      expect(usernameField, findsOneWidget);
      final formFieldWidget = tester.widget<TextFormField>(usernameField);
      expect(formFieldWidget.enabled, isFalse); // Read-only
    });

    // ─── SKENARIO 5: Mencoba membuat akun dengan username yang sudah digunakan (Validasi Duplikat) ───
    testWidgets('Skenario 5: Pembuatan akun dengan username yang sudah digunakan memunculkan pesan validasi', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Pasang mock validator: username 'admin' sudah digunakan
      AuthService.mockIsUsernameTaken = (username, excludeUid) {
        return username.toLowerCase() == 'admin';
      };

      await tester.pumpWidget(
        MaterialApp(
          home: const AdminPage(bypassAuthCheck: true),
          routes: {'/login': (_) => const Scaffold()},
        ),
      );
      await tester.pumpAndSettle();

      // Buka dialog Tambah Akun Baru
      await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Akun'));
      await tester.pumpAndSettle();

      // Masukkan username yang sudah terdaftar
      final usernameField = find.widgetWithText(TextFormField, 'Username (Identitas Login)');
      final nameField = find.widgetWithText(TextFormField, 'Nama Lengkap & Gelar');
      final passField = find.widgetWithText(TextFormField, 'Password');

      await tester.enterText(usernameField, 'admin');
      await tester.enterText(nameField, 'Administrator Utama');
      await tester.enterText(passField, 'admin123');
      await tester.pumpAndSettle();

      // Tekan tombol Buat Akun
      await tester.tap(find.widgetWithText(ElevatedButton, 'Buat Akun'));
      await tester.pumpAndSettle();

      // Harus muncul SnackBar error bahwa username sudah digunakan
      expect(find.text('Username "admin" sudah digunakan. Silakan gunakan username lain.'), findsOneWidget);
    });

    // ─── SKENARIO 6: Mengedit nama lengkap tanpa mengubah username ───
    testWidgets('Skenario 6: Mengedit nama lengkap memperbarui nama tanpa mengubah username', (tester) async {
      final profile = UserProfileProvider();
      profile.loginAs(const RegisteredUser(
        username: 'user_pengawas',
        password: 'password123',
        role: 'Dinas',
        namaLengkap: 'Bambang Sudarsono',
        companyOrAgency: 'Dinas PUPR',
      ));

      expect(profile.username, 'user_pengawas');
      expect(profile.namaLengkap, 'Bambang Sudarsono');

      // Edit nama lengkap
      profile.updateNamaLengkap('Bambang Sudarsono, S.T., M.Eng.');

      // Nama lengkap berubah
      expect(profile.namaLengkap, 'Bambang Sudarsono, S.T., M.Eng.');
      // Username TETAP SAMA
      expect(profile.username, 'user_pengawas');
    });

    // ─── SKENARIO 7: Memastikan akun lama tetap bisa dibaca dan login (Backward Compatibility) ───
    test('Skenario 7: UserAccount.fromDoc menangani data akun lama tanpa field namaLengkap / username terpisah', () {
      // 1. Akun lama hanya punya email & username (tanpa namaLengkap)
      final legacyDoc1 = _createFakeDoc({
        'username': 'lama_kontraktor',
        'email': 'lama@tatasakaconsultant.id',
        'role': 'Kontraktor',
        'companyOrAgency': 'CV. Berkah',
        'isActive': true,
      });
      final acc1 = UserAccount.fromDoc(legacyDoc1);
      expect(acc1.username, 'lama_kontraktor');
      expect(acc1.namaLengkap, 'lama_kontraktor'); // fallback ke username
      expect(acc1.name, 'lama_kontraktor');

      // 2. Akun lama punya email asli & full_name (format legacy Firestore)
      final legacyDoc2 = _createFakeDoc({
        'email': 'hendra@gmail.com',
        'full_name': 'Hendra Wijaya',
        'role': 'Dinas',
        'companyOrAgency': 'Dinas Bina Marga',
        'isActive': true,
      });
      final acc2 = UserAccount.fromDoc(legacyDoc2);
      expect(acc2.username, 'hendra'); // fallback dari email prefix
      expect(acc2.namaLengkap, 'Hendra Wijaya');
      expect(acc2.name, 'Hendra Wijaya');
    });

    // ─── SKENARIO 8: Memastikan setiap role tetap memiliki hak akses seperti sebelumnya ───
    test('Skenario 8: Hak akses dan karakteristik setiap role (Konsultan, Kontraktor, Dinas) tetap terjaga', () {
      final profile = UserProfileProvider();

      // 1. Konsultan: companyOrAgency otomatis 'CV. Tata Saka Consultant'
      profile.loginAs(const RegisteredUser(
        username: 'konsultan1',
        password: 'password123',
        role: 'Konsultan',
        namaLengkap: 'Konsultan Proyek',
        companyOrAgency: 'Lainnya',
      ));
      expect(profile.isKonsultan, isTrue);
      expect(profile.isKontraktor, isFalse);
      expect(profile.isDinas, isFalse);
      expect(profile.companyOrAgency, 'CV. Tata Saka Consultant');

      // 2. Kontraktor
      profile.loginAs(const RegisteredUser(
        username: 'kontraktor1',
        password: 'password123',
        role: 'Kontraktor',
        namaLengkap: 'Mandor Kontraktor',
        companyOrAgency: 'PT. Pilar Konstruksi',
      ));
      expect(profile.isKontraktor, isTrue);
      expect(profile.isKonsultan, isFalse);
      expect(profile.isDinas, isFalse);
      expect(profile.companyOrAgency, 'PT. Pilar Konstruksi');

      // 3. Dinas
      profile.loginAs(const RegisteredUser(
        username: 'dinas1',
        password: 'password123',
        role: 'Dinas',
        namaLengkap: 'Kepala Dinas PU',
        companyOrAgency: 'Dinas PUPR Kabupaten',
      ));
      expect(profile.isDinas, isTrue);
      expect(profile.isKonsultan, isFalse);
      expect(profile.isKontraktor, isFalse);
      expect(profile.companyOrAgency, 'Dinas PUPR Kabupaten');
    });
  });
}

// Helper untuk simulasi DocumentSnapshot Firestore tanpa instance Firebase aktif
DocumentSnapshot<Map<String, dynamic>> _createFakeDoc(Map<String, dynamic> data, {String id = 'doc-id-123'}) {
  return _FakeDocumentSnapshot(data, id);
}

class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic> _data;
  final String _id;
  _FakeDocumentSnapshot(this._data, this._id);

  @override
  String get id => _id;

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
