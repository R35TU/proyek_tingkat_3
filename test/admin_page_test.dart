import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/screens/admin_page.dart';

void main() {
  testWidgets('admin page stacks search and add button on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AdminPage()));
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

      await tester.pumpWidget(const MaterialApp(home: AdminPage()));
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
}
