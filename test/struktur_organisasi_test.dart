import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';

void main() {
  group('ContractModel Struktur Organisasi Tests', () {
    test('ContractModel serializes and deserializes strukturOrganisasi properly', () {
      final contract = ContractModel(
        id: 'test-c1',
        jenisKegiatan: 'Pengawasan Teknis',
        namaKontrak: 'Pengawasan Teknis Pemeliharaan Jalan',
        nomorSpk: 'SPK-001',
        tglMulaiSpk: '20 April 2026',
        nomorSpmk: 'SPMK-001',
        tglMulaiSpmk: '20 April 2026',
        tglSelesaiSpmk: '18 Juli 2026',
        hariKalender: 90,
        nilaiKontrak: 'Rp 3.000.000.000,00',
        instansiDinas: ['DPUPR Purbalingga'],
        sumberDana: 'APBD',
        deskripsi: 'Pengawasan Teknis Jalan',
        strukturOrganisasi: {
          'siteEngineer': 'SENDAYU GALIH KUSUMA, ST',
          'inspektors': ['RIZAL PRASTOMO', 'BUDI SANTOSO'],
          'administrasi': 'HANGGORO AJI',
        },
      );

      expect(contract.hasStrukturOrganisasi, isTrue);
      expect(contract.siteEngineer, 'SENDAYU GALIH KUSUMA, ST');
      expect(contract.inspektors.length, 2);
      expect(contract.inspektors[0], 'RIZAL PRASTOMO');
      expect(contract.inspektors[1], 'BUDI SANTOSO');
      expect(contract.administrasi, 'HANGGORO AJI');

      // Test json serialization round-trip
      final json = contract.toJson();
      final fromJson = ContractModel.fromJson(json);

      expect(fromJson.siteEngineer, 'SENDAYU GALIH KUSUMA, ST');
      expect(fromJson.inspektors, ['RIZAL PRASTOMO', 'BUDI SANTOSO']);
      expect(fromJson.administrasi, 'HANGGORO AJI');
    });

    test('ContractModel handles empty / null strukturOrganisasi gracefully', () {
      final contract = ContractModel(
        id: 'test-c2',
        jenisKegiatan: 'Pengawasan Teknis',
        namaKontrak: 'Proyek Tanpa Struktur',
        nomorSpk: 'SPK-002',
        tglMulaiSpk: '20 April 2026',
        nomorSpmk: 'SPMK-002',
        tglMulaiSpmk: '20 April 2026',
        tglSelesaiSpmk: '18 Juli 2026',
        hariKalender: 90,
        nilaiKontrak: 'Rp 1.000.000.000',
        instansiDinas: ['DPUPR Purbalingga'],
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
      );

      expect(contract.hasStrukturOrganisasi, isFalse);
      expect(contract.siteEngineer, '');
      expect(contract.inspektors, isEmpty);
      expect(contract.administrasi, '');
    });
  });

  group('DetailKontrakScreen UI Tests', () {
    testWidgets('DetailKontrakScreen renders Struktur Anggota Konsultan below Spesifikasi Kontrak', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'test-c-ui',
        jenisKegiatan: 'Pengawasan Teknis',
        namaKontrak: 'PEMELIHARAAN BERKALA JALAN KARANGMONCOL - RAJAWANA',
        nomorSpk: 'SPK-001',
        tglMulaiSpk: '20 April 2026',
        nomorSpmk: 'SPMK-001',
        tglMulaiSpmk: '20 April 2026',
        tglSelesaiSpmk: '18 Juli 2026',
        hariKalender: 90,
        nilaiKontrak: 'Rp 3.000.000.000,00',
        instansiDinas: ['DPUPR Purbalingga'],
        sumberDana: 'APBD Kab. Purbalingga',
        deskripsi: 'Pekerjaan Pemeliharaan Berkala',
        strukturOrganisasi: {
          'siteEngineer': 'SENDAYU GALIH KUSUMA, ST',
          'inspektors': ['RIZAL PRASTOMO'],
          'administrasi': 'HANGGORO AJI',
        },
      );

      final provider = ContractProvider();
      provider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: MaterialApp(
            home: DetailKontrakScreen(contract: contract),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Spesifikasi Kontrak exists
      expect(find.text('Spesifikasi Kontrak'), findsOneWidget);

      // Scroll down to see Struktur Anggota Konsultan
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -350));
      await tester.pumpAndSettle();

      // Verify Struktur Anggota Konsultan exists right below Spesifikasi Kontrak
      expect(find.text('Struktur Anggota Konsultan'), findsOneWidget);
      expect(find.text('Site Engineer'), findsOneWidget);
      expect(find.text('SENDAYU GALIH KUSUMA, ST'), findsOneWidget);
      expect(find.text('Inspektor'), findsOneWidget);
      expect(find.text('RIZAL PRASTOMO'), findsOneWidget);
      // 'Administrasi' is present in TabBar as well as in the card
      expect(find.text('Administrasi'), findsNWidgets(2));
      expect(find.text('HANGGORO AJI'), findsOneWidget);
    });

    testWidgets('TambahKontrakScreen renders dynamic Inspektor fields (up to 4)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final provider = ContractProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: provider),
          ],
          child: const MaterialApp(
            home: TambahKontrakScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll down to Struktur Anggota Konsultan in form
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(find.text('Struktur Anggota Konsultan'), findsOneWidget);
      expect(find.text('Site Engineer'), findsOneWidget);
      expect(find.text('Inspektor'), findsOneWidget);
      expect(find.text('Administrasi'), findsOneWidget);

      // Tap tambah inspektor up to 4
      final btnTambah = find.text('Tambah Inspektor');
      await tester.ensureVisible(btnTambah);
      await tester.pumpAndSettle();
      await tester.tap(btnTambah);
      await tester.pumpAndSettle();

      expect(find.text('Inspektor 1'), findsOneWidget);
      expect(find.text('Inspektor 2'), findsOneWidget);
    });
  });
}
