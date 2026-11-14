import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpResponsiveApp(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            ResponsiveAppFrame(child: child ?? const SizedBox.shrink()),
        home: SizedBox.expand(
          key: const ValueKey('responsive-content'),
          child: const ColoredBox(color: Colors.white),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Responsive app frame', () {
    testWidgets('keeps the mobile viewport width unchanged', (tester) async {
      await pumpResponsiveApp(tester, const Size(700, 900));

      expect(
        tester.getSize(find.byKey(const ValueKey('responsive-content'))).width,
        700,
      );
    });

    testWidgets('centers the application on ultrawide viewports', (
      tester,
    ) async {
      await pumpResponsiveApp(tester, const Size(1920, 1080));

      final rect = tester.getRect(
        find.byKey(const ValueKey('responsive-content')),
      );
      expect(rect.width, ResponsiveBreakpoints.maxAppWidth);
      expect(rect.left, (1920 - ResponsiveBreakpoints.maxAppWidth) / 2);
    });
  });
}
