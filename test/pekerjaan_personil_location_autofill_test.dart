import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/widgets/clean_text_form_field.dart';

void main() {
  Widget createTestWidget({Map<String, dynamic>? editReport}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ContractProvider()),
      ],
      child: MaterialApp(
        home: BuatLaporanScreen(editReport: editReport),
      ),
    );
  }

  Finder findFieldByLabel(String label) {
    return find.descendant(
      of: find.ancestor(
        of: find.text(label),
        matching: find.byType(CleanTextFormField),
      ),
      matching: find.byType(TextFormField),
    );
  }

  testWidgets(
      'Lokasi Penugasan personil auto-fills from Pekerjaan Lokasi / STA and auto-syncs',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify initial state: Pekerjaan #1 and Personil #1 exist
    expect(find.text('Pekerjaan #1'), findsOneWidget);
    expect(find.text('Personil #1'), findsOneWidget);

    final lokPekFinder = findFieldByLabel('Lokasi / STA');
    expect(lokPekFinder, findsOneWidget);

    // 1. Enter location for Pekerjaan #1: 'STA 0+000 – STA 0+500'
    await tester.enterText(lokPekFinder, 'STA 0+000 – STA 0+500');
    await tester.pumpAndSettle();

    // Verify Personil #1 automatically has 'STA 0+000 – STA 0+500' and 'Auto' badge
    expect(find.text('STA 0+000 – STA 0+500'), findsNWidgets(2)); // Pekerjaan #1 + Personil #1
    expect(find.text('Auto'), findsOneWidget);

    // 2. Add Personil #2 via '+ Tambah Personil (Pek. #1)'
    final tambahPersonilBtn = find.text('+ Tambah Personil (Pek. #1)');
    await tester.tap(tambahPersonilBtn);
    await tester.pumpAndSettle();

    // Verify Personil #2 is added and also automatically gets 'STA 0+000 – STA 0+500'
    expect(find.text('Personil #2'), findsOneWidget);
    expect(find.text('STA 0+000 – STA 0+500'), findsNWidgets(3)); // Pekerjaan #1 + Personil #1 + Personil #2
    expect(find.text('Auto'), findsNWidgets(2));

    // 3. Update Pekerjaan #1 location to 'STA 0+500 – STA 1+000'
    await tester.enterText(lokPekFinder, 'STA 0+500 – STA 1+000');
    await tester.pumpAndSettle();

    // Verify both Personil #1 and #2 automatically synced to 'STA 0+500 – STA 1+000'
    expect(find.text('STA 0+500 – STA 1+000'), findsNWidgets(3));

    // 4. Manually customize Personil #2 location to 'STA 0+700'
    final lokasiPenugasanFields = findFieldByLabel('Lokasi Penugasan');
    expect(lokasiPenugasanFields, findsNWidgets(2)); // Personil #1 and Personil #2
    await tester.enterText(lokasiPenugasanFields.last, 'STA 0+700');
    await tester.pumpAndSettle();

    // Verify Personil #2 now has 'STA 0+700' and 'Khusus' badge
    expect(find.text('STA 0+700'), findsOneWidget);
    expect(find.text('Khusus'), findsOneWidget);
    expect(find.text('Auto'), findsOneWidget); // Personil #1 is still Auto

    // 5. Update Pekerjaan #1 location again to 'STA 1+000 – STA 1+500'
    await tester.enterText(lokPekFinder, 'STA 1+000 – STA 1+500');
    await tester.pumpAndSettle();

    // Personil #1 follows to 'STA 1+000 – STA 1+500'
    // Personil #2 preserves custom location 'STA 0+700'
    expect(find.text('STA 1+000 – STA 1+500'), findsNWidgets(2)); // Pekerjaan #1 + Personil #1
    expect(find.text('STA 0+700'), findsOneWidget); // Personil #2 kept
    expect(find.text('Khusus'), findsOneWidget);

    // 6. Reset Personil #2 back to Pekerjaan location by tapping 'Khusus' reset button
    await tester.tap(find.text('Khusus'));
    await tester.pumpAndSettle();

    // Verify Personil #2 is resynced to 'STA 1+000 – STA 1+500' and badge returns to 'Auto'
    expect(find.text('STA 1+000 – STA 1+500'), findsNWidgets(3));
    expect(find.text('Auto'), findsNWidgets(2));
    expect(find.text('Khusus'), findsNothing);
  });

  testWidgets(
      'Auto-fill and sync is scoped strictly per Pekerjaan (Pekerjaan #1 does not affect Pekerjaan #2)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 5000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Set Pekerjaan #1 location
    final lokPekFinder = findFieldByLabel('Lokasi / STA');
    await tester.enterText(lokPekFinder.first, 'STA 0+000 – STA 0+500');
    await tester.pumpAndSettle();

    // Add Pekerjaan #2
    final tambahPekerjaanBtn = find.text('+ Tambah Baris Pekerjaan Baru');
    await tester.tap(tambahPekerjaanBtn);
    await tester.pumpAndSettle();

    expect(find.text('Pekerjaan #2'), findsOneWidget);

    // Now there are 2 'Lokasi / STA' fields
    final lokPekFields = findFieldByLabel('Lokasi / STA');
    expect(lokPekFields, findsNWidgets(2));

    // Set Pekerjaan #2 location to 'STA 2+000 – STA 2+500'
    await tester.enterText(lokPekFields.last, 'STA 2+000 – STA 2+500');
    await tester.pumpAndSettle();

    // Verify Pekerjaan #1 personnel still has 'STA 0+000 – STA 0+500'
    // and Pekerjaan #2 personnel has 'STA 2+000 – STA 2+500'
    expect(find.text('STA 0+000 – STA 0+500'), findsNWidgets(2)); // Pekerjaan #1 + its personil
    expect(find.text('STA 2+000 – STA 2+500'), findsNWidgets(2)); // Pekerjaan #2 + its personil
  });

  testWidgets(
      'Loading existing report maintains default sync vs custom status consistently',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final existingReport = {
      'pekerjaanList': [
        {
          'jenis': 'Saluran U-Ditch',
          'volume': '50',
          'lokasi': 'STA 0+000 – STA 0+500',
          'personils': [
            {
              'role': 'Pelaksana',
              'cacah': '1',
              'lokasi': 'STA 0+000 – STA 0+500',
              'isCustomLokasi': false,
            },
            {
              'role': 'Mandor Khusus',
              'cacah': '1',
              'lokasi': 'STA 0+200',
              'isCustomLokasi': true,
            },
          ],
        },
      ],
    };

    await tester.pumpWidget(createTestWidget(editReport: existingReport));
    await tester.pumpAndSettle();

    // Verify Personil #1 is Auto and Personil #2 is Khusus
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('Khusus'), findsOneWidget);
    expect(find.text('STA 0+200'), findsOneWidget);

    // Change Pekerjaan location to 'STA 0+500 – STA 1+000'
    final lokPekFinder = findFieldByLabel('Lokasi / STA');
    await tester.enterText(lokPekFinder, 'STA 0+500 – STA 1+000');
    await tester.pumpAndSettle();

    // Personil #1 (Auto) updated, Personil #2 (Khusus) kept STA 0+200
    expect(find.text('STA 0+500 – STA 1+000'), findsNWidgets(2)); // Pekerjaan + Personil #1
    expect(find.text('STA 0+200'), findsOneWidget); // Personil #2
    expect(find.text('Khusus'), findsOneWidget);
  });
}
