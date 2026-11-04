import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/form_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';

Widget _buildTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ContractProvider()),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'),
        Locale('en', 'US'),
      ],
      locale: const Locale('id', 'ID'),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('Test showDatePicker in BuatLaporanScreen opens without red screen', (tester) async {
    await tester.pumpWidget(_buildTestApp(const BuatLaporanScreen()));
    await tester.pumpAndSettle();

    final ubahTanggalBtn = find.text('Ubah Tanggal');
    expect(ubahTanggalBtn, findsOneWidget);

    await tester.tap(ubahTanggalBtn);
    await tester.pumpAndSettle();

    // Verify DatePickerDialog appears with OK / Batal
    expect(find.byType(DatePickerDialog), findsOneWidget);

    // Tap OK or Batal to dismiss
    final batalBtn = find.text('Batal');
    if (batalBtn.evaluate().isNotEmpty) {
      await tester.tap(batalBtn);
    } else {
      await tester.tap(find.text('BATAL'));
    }
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('Test showDatePicker in FormKegiatanScreen opens without red screen', (tester) async {
    final contract = SampleContractData.getDemoContract();
    await tester.pumpWidget(_buildTestApp(FormKegiatanScreen(contract: contract)));
    await tester.pumpAndSettle();

    final dateIcon = find.byIcon(Icons.calendar_month).first;
    await tester.ensureVisible(dateIcon);
    await tester.tap(dateIcon);
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);

    final batalBtn = find.text('Batal');
    if (batalBtn.evaluate().isNotEmpty) {
      await tester.tap(batalBtn);
    } else {
      await tester.tap(find.text('BATAL'));
    }
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });

  testWidgets('Test showDatePicker in TambahKontrakScreen opens without red screen', (tester) async {
    await tester.pumpWidget(_buildTestApp(const TambahKontrakScreen()));
    await tester.pumpAndSettle();

    // Tap on Tgl Mulai SPK field
    final tglSpkField = find.widgetWithText(TextFormField, 'Tanggal Mulai SPK');
    expect(tglSpkField, findsOneWidget);
    await tester.tap(tglSpkField);
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
