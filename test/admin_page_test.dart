import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/screens/admin_page.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';

Widget _buildAdminTestApp() {
  return MaterialApp(
    home: const AdminPage(bypassAuthCheck: true),
    routes: {
      '/login': (_) => const Scaffold(),
    },
  );
}

void main() {
  testWidgets('admin page stacks search and add button on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildAdminTestApp());
    await tester.pumpAndSettle();

    final searchRect = tester.getRect(find.byType(TextField));
    final addButtonRect = tester.getRect(
      find.widgetWithText(ElevatedButton, 'Tambah Akun'),
    );

    expect(addButtonRect.top, greaterThan(searchRect.bottom));
    expect(tester.takeException(), isNull);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Akun Baru'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'admin page places search and add button side by side on desktop',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_buildAdminTestApp());
      await tester.pumpAndSettle();

      final searchRect = tester.getRect(find.byType(TextField));
      final addButtonRect = tester.getRect(
        find.widgetWithText(ElevatedButton, 'Tambah Akun'),
      );

      expect(addButtonRect.left, greaterThan(searchRect.right));
      expect(addButtonRect.center.dy, closeTo(searchRect.center.dy, 1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Form Tambah Akun: role Konsultan tidak menampilkan input perusahaan, Kontraktor/Dinas menampilkannya', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_buildAdminTestApp());
    await tester.pumpAndSettle();

    // Buka dialog Tambah Akun Baru
    await tester.tap(find.widgetWithText(ElevatedButton, 'Tambah Akun'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Akun Baru'), findsOneWidget);

    // Default role adalah 'Konsultan'
    // Input perusahaan TIDAK boleh ada di formulir untuk Konsultan
    expect(find.text('Nama Instansi / Perusahaan (CV/PT/Dinas)'), findsNothing);
    expect(find.text('Nama Perusahaan Kontraktor (CV/PT)'), findsNothing);
    expect(find.text('Nama Dinas / Instansi Terkait'), findsNothing);

    // Ganti role ke 'Kontraktor'
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kontraktor').last);
    await tester.pumpAndSettle();

    // Input perusahaan Kontraktor HARUS muncul
    expect(find.text('Nama Perusahaan Kontraktor (CV/PT)'), findsOneWidget);

    // Ganti role ke 'Dinas'
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinas').last);
    await tester.pumpAndSettle();

    // Input dinas HARUS muncul
    expect(find.text('Nama Dinas / Instansi Terkait'), findsOneWidget);

    // Ganti kembali ke 'Konsultan'
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Konsultan').last);
    await tester.pumpAndSettle();

    // Input perusahaan otomatis HILANG kembali
    expect(find.text('Nama Perusahaan Kontraktor (CV/PT)'), findsNothing);
    expect(find.text('Nama Dinas / Instansi Terkait'), findsNothing);
  });

  test('UserProfileProvider konsisten mengembalikan CV. Tata Saka Consultant untuk role Konsultan', () {
    final profile = UserProfileProvider();

    profile.loginAs(const RegisteredUser(
      username: 'konsultan_user',
      password: 'password123',
      role: 'Konsultan',
      namaLengkap: 'Budi Santoso, S.T.',
      companyOrAgency: 'Any Company', // Nilai apapun
    ));

    // Identitas konsultan SELALU 'CV. Tata Saka Consultant'
    expect(profile.companyOrAgency, 'CV. Tata Saka Consultant');
    expect(profile.isKonsultan, isTrue);

    // Jika role Kontraktor, menggunakan nama perusahaannya
    profile.loginAs(const RegisteredUser(
      username: 'kontraktor_user',
      password: 'password123',
      role: 'Kontraktor',
      namaLengkap: 'Joko Widodo',
      companyOrAgency: 'CV. Permata',
    ));
    expect(profile.companyOrAgency, 'CV. Permata');
    expect(profile.isKonsultan, isFalse);
  });
}
