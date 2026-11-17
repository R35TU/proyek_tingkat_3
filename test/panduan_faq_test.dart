import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/screens/panduan_faq_screen.dart';

void main() {
  testWidgets('panduan faq menampilkan 3 tab peran dan FAQ bisa dibuka', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PanduanFaqScreen()));
    await tester.pumpAndSettle();

    // Judul halaman & 3 tab peran tersedia.
    expect(find.text('Panduan & FAQ'), findsOneWidget);
    expect(find.text('Konsultan'), findsOneWidget);
    expect(find.text('Kontraktor'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tab Konsultan (default): kartu intro + section pertama muncul.
    expect(find.text('Panduan Konsultan'), findsOneWidget);
    expect(find.text('Akses Awal & Unduh Aplikasi'), findsOneWidget);
    expect(find.text('LANGKAH PENGGUNAAN'), findsOneWidget);

    // Scroll ke bawah sampai bagian FAQ terlihat.
    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, -3000),
      2000,
    );
    await tester.pumpAndSettle();
    expect(
      find.text('PERTANYAAN YANG SERING DIAJUKAN (FAQ)'),
      findsWidgets,
    );

    // FAQ: jawaban muncul setelah tile pertama di-tap.
    await tester.tap(find.byType(ExpansionTile).first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Masuk ke menu Laporan'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('panduan faq tab Kontraktor & Admin bisa dibuka', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PanduanFaqScreen()));
    await tester.pumpAndSettle();

    // Pindah ke tab Kontraktor: kartu intro & section pertama muncul.
    await tester.tap(find.text('Kontraktor'));
    await tester.pumpAndSettle();
    expect(find.text('Panduan Kontraktor'), findsOneWidget);
    expect(find.text('Login ke Sistem'), findsWidgets);
    expect(tester.takeException(), isNull);

    // Pindah ke tab Admin.
    await tester.tap(find.text('Admin'));
    await tester.pumpAndSettle();
    expect(find.text('Panduan Admin'), findsOneWidget);
    expect(
      find.text('Mengenal Halaman Dashboard Admin'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('panduan faq role konsultan: tanpa tab, konten konsultan saja', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: PanduanFaqScreen(role: 'konsultan')),
    );
    await tester.pumpAndSettle();

    // Tidak ada tab peran; langsung konten konsultan.
    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Panduan Konsultan'), findsOneWidget);
    expect(find.text('Akses Awal & Unduh Aplikasi'), findsOneWidget);
    expect(find.text('Panduan Kontraktor'), findsNothing);
    expect(find.text('Panduan Admin'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('panduan faq role kontraktor: konten kontraktor saja', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: PanduanFaqScreen(role: 'kontraktor')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Panduan Kontraktor'), findsOneWidget);
    expect(
      find.text('Mengenal Halaman Dashboard Kontraktor'),
      findsOneWidget,
    );
    expect(find.text('Panduan Konsultan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('panduan faq role admin: konten admin saja', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: PanduanFaqScreen(role: 'admin')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsNothing);
    expect(find.text('Panduan Admin'), findsOneWidget);
    expect(
      find.text('Menambah, Mengedit, & Menghapus Akun Pengguna'),
      findsOneWidget,
    );
    expect(find.text('Panduan Konsultan'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('panduan faq role dinas: tetap tampilan 3 tab (belum ada guidebook)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: PanduanFaqScreen(role: 'dinas')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TabBar), findsOneWidget);
    expect(find.text('Konsultan'), findsOneWidget);
    expect(find.text('Kontraktor'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Panduan Konsultan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
