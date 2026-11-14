import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/form_kegiatan_screen.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';

Widget _wrapWithApp(Widget child) {
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
      home: child,
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets('FormKegiatanScreen has 2 cards and only 1 Direktur input without Site Engineer', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final contract = SampleContractData.getDemoContract();
    await tester.pumpWidget(_wrapWithApp(FormKegiatanScreen(contract: contract)));
    await tester.pumpAndSettle();

    // Scroll down to see the structure cards
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
    await tester.pumpAndSettle();

    // Exactly 1 Direktur field in the form
    expect(find.text('Direktur Penyedia Jasa'), findsOneWidget);
    expect(find.text('Direktur Konsultan'), findsNothing);

    // Site Engineer is removed from Kegiatan form
    expect(find.text('Site Engineer (CV. Tata Saka Consultant)'), findsNothing);

    // Exactly 2 structure sections in the form
    expect(find.text('STRUKTUR ORGANISASI KEGIATAN'), findsOneWidget);
    expect(find.text('STRUKTUR ORGANISASI PENYEDIA JASA'), findsOneWidget);
    expect(find.text('STRUKTUR ORGANISASI KONSULTAN'), findsNothing);
  });

  testWidgets('DetailKegiatanScreen outputs Direktur Penyedia Jasa and no Site Engineer', (tester) async {
    tester.view.physicalSize = const Size(500, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final contract = SampleContractData.getDemoContract();

    await tester.pumpWidget(_wrapWithApp(
      DetailKegiatanScreen(
        contract: contract,
        kegiatanIndex: 0,
      ),
    ));
    await tester.pumpAndSettle();

    // Exactly 2 sections: STRUKTUR ORGANISASI KEGIATAN and STRUKTUR ORGANISASI PENYEDIA JASA
    expect(find.text('STRUKTUR ORGANISASI KEGIATAN'), findsOneWidget);
    expect(find.text('STRUKTUR ORGANISASI PENYEDIA JASA'), findsOneWidget);
    expect(find.text('STRUKTUR ORGANISASI KONSULTAN'), findsNothing);

    // Direktur Penyedia Jasa in Kegiatan, Direktur in Penyedia Jasa
    expect(find.text('Direktur Penyedia Jasa'), findsOneWidget);
    expect(find.text('Direktur'), findsOneWidget);

    // Site Engineer is removed from Struktur Organisasi Kegiatan
    expect(find.text('Site Engineer'), findsNothing);
  });
}
