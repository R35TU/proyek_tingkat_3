import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/addendum_model.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/kelola_addendum_screen.dart';
import 'package:tata_saka_app/widgets/lembar_tambah_kurang_widget.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';

ContractModel _createTestContract({
  required String id,
  required List<Map<String, dynamic>> kegiatans,
}) {
  return ContractModel(
    id: id,
    jenisKegiatan: 'Pengawasan Teknis',
    namaKontrak: 'Paket Jalan MT Haryono',
    nomorSpk: '602.1/01/SPK/2026',
    tglMulaiSpk: '20 April 2026',
    nomorSpmk: '602.1/01/SPMK/2026',
    tglMulaiSpmk: '20 April 2026',
    tglSelesaiSpmk: '20 Juli 2026',
    hariKalender: 90,
    nilaiKontrak: 'Rp 288.350.000,00',
    instansiDinas: ['DPU-PR Kab. Purbalingga'],
    sumberDana: 'APBD Kab. Purbalingga',
    deskripsi: 'Pengawasan Teknis Jalan MT Haryono',
    kegiatans: kegiatans,
  );
}

void main() {
  group('Addendum & Tambah Kurang (CCO) Unit & Logic Tests', () {
    test('TambahKurangCalculator correctly calculates Tambah, Kurang, Tetap matching reference RAB', () {
      final baselineDivisiList = [
        {
          'nomorRomawi': 'I',
          'namaDivisi': 'DIVISI 1 UMUM',
          'items': [
            {
              'no': '1',
              'noMataPembayaran': '1.2',
              'uraian': 'Mobilisasi',
              'satuan': 'Ls',
              'hargaSatuan': 12900000.0,
              'volume': 1.00,
              'totalHarga': 12900000.0,
              'nilaiBobot': 4.474,
            },
            {
              'no': '4',
              'noMataPembayaran': 'Taksir',
              'uraian': 'Bongkaran',
              'satuan': 'Ls',
              'hargaSatuan': 1352000.0,
              'volume': 1.00,
              'totalHarga': 1352000.0,
              'nilaiBobot': 0.469,
            },
          ],
        },
        {
          'nomorRomawi': 'II',
          'namaDivisi': 'DIVISI 2. DRAINASE',
          'items': [
            {
              'no': '2',
              'noMataPembayaran': '2.3.(24)',
              'uraian': 'Saluran berbentuk U Tipe DS 2',
              'satuan': 'm1',
              'hargaSatuan': 661011.25,
              'volume': 121.00,
              'totalHarga': 79982361.25,
              'nilaiBobot': 27.738,
            },
          ],
        },
        {
          'nomorRomawi': 'VII',
          'namaDivisi': 'DIVISI 7 STRUKTUR',
          'items': [
            {
              'no': '1',
              'noMataPembayaran': '7.1(8)',
              'uraian': 'Beton fc\' 15Mpa',
              'satuan': 'm3',
              'hargaSatuan': 1655793.06,
              'volume': 1.13,
              'totalHarga': 1862767.20,
              'nilaiBobot': 0.646,
            },
            {
              'no': '3',
              'noMataPembayaran': '3.9.8.3',
              'uraian': 'Pasangan Keramik 40 x 40 cm (Bekas Bongkaran)',
              'satuan': 'm2',
              'hargaSatuan': 167594.80,
              'volume': 4.50,
              'totalHarga': 754176.60,
              'nilaiBobot': 0.262,
            },
          ],
        },
      ];

      // Addendum Target Volumes:
      // Mobilisasi: 1.00 (Tetap)
      // Bongkaran: 0.00 (Kurang 1.00)
      // Saluran U: 115.00 (Kurang 6.00)
      // Beton: 4.79 (Tambah 3.66)
      // Keramik: 0.00 (Kurang 4.50)
      final addendumDivisiList = [
        {
          'nomorRomawi': 'I',
          'namaDivisi': 'DIVISI 1 UMUM',
          'items': [
            {
              'no': '1',
              'noMataPembayaran': '1.2',
              'uraian': 'Mobilisasi',
              'satuan': 'Ls',
              'hargaSatuan': 12900000.0,
              'volume': 1.00,
              'totalHarga': 12900000.0,
            },
            {
              'no': '4',
              'noMataPembayaran': 'Taksir',
              'uraian': 'Bongkaran',
              'satuan': 'Ls',
              'hargaSatuan': 1352000.0,
              'volume': 0.00,
              'totalHarga': 0.0,
            },
          ],
        },
        {
          'nomorRomawi': 'II',
          'namaDivisi': 'DIVISI 2. DRAINASE',
          'items': [
            {
              'no': '2',
              'noMataPembayaran': '2.3.(24)',
              'uraian': 'Saluran berbentuk U Tipe DS 2',
              'satuan': 'm1',
              'hargaSatuan': 661011.25,
              'volume': 115.00,
              'totalHarga': 76016293.75,
            },
          ],
        },
        {
          'nomorRomawi': 'VII',
          'namaDivisi': 'DIVISI 7 STRUKTUR',
          'items': [
            {
              'no': '1',
              'noMataPembayaran': '7.1(8)',
              'uraian': 'Beton fc\' 15Mpa',
              'satuan': 'm3',
              'hargaSatuan': 1655793.06,
              'volume': 4.79,
              'totalHarga': 7935388.25,
            },
            {
              'no': '3',
              'noMataPembayaran': '3.9.8.3',
              'uraian': 'Pasangan Keramik 40 x 40 cm (Bekas Bongkaran)',
              'satuan': 'm2',
              'hargaSatuan': 167594.80,
              'volume': 0.00,
              'totalHarga': 0.0,
            },
          ],
        },
      ];

      final reportResult = TambahKurangCalculator.calculate(
        baselineDivisiList: baselineDivisiList,
        addendumDivisiList: addendumDivisiList,
      );

      expect(reportResult.divisiResults.length, 3);

      // Check Divisi 1: Mobilisasi (Tetap) and Bongkaran (Kurang)
      final div1 = reportResult.divisiResults[0];
      expect(div1.items[0].keterangan, 'Tetap');
      expect(div1.items[0].tambahVolume, 0.0);
      expect(div1.items[0].kurangVolume, 0.0);

      expect(div1.items[1].keterangan, 'Kurang');
      expect(div1.items[1].kurangVolume, 1.0);
      expect(div1.items[1].kurangTotalHarga, 1352000.0);

      // Check Divisi 2: Saluran U (Kurang 6.00)
      final div2 = reportResult.divisiResults[1];
      expect(div2.items[0].keterangan, 'Kurang');
      expect(div2.items[0].kurangVolume, 6.00);
      expect((div2.items[0].kurangTotalHarga - 3966067.50).abs() < 1.0, isTrue);

      // Check Divisi 7: Beton (Tambah 3.66) & Keramik (Kurang 4.50)
      final div7 = reportResult.divisiResults[2];
      expect(div7.items[0].keterangan, 'Tambah');
      expect((div7.items[0].tambahVolume - 3.66).abs() < 0.01, isTrue);
      expect((div7.items[0].tambahTotalHarga - (3.66 * 1655793.06)).abs() < 1.0, isTrue);

      expect(div7.items[1].keterangan, 'Kurang');
      expect(div7.items[1].kurangVolume, 4.50);
      expect(div7.items[1].kurangTotalHarga, 754176.60);

      // Total Tambah and Total Kurang should be populated
      expect(reportResult.totalTambahHarga > 0, isTrue);
      expect(reportResult.totalKurangHarga > 0, isTrue);
      expect(reportResult.totalTambahBobot > 0, isTrue);
      expect(reportResult.totalKurangBobot > 0, isTrue);
    });

    test('TambahKurangCalculator with customPaguDibulatkan matches official Dinas PU document down to the cent', () {
      final demoContract = SampleContractData.getDemoContract();
      final ruasA = demoContract.kegiatans[0];
      final baseline = (ruasA['rkkKontrakAwal'] as List).map((e) => Map<String, dynamic>.from(e)).toList();
      final addendum = (ruasA['addendums'][0]['rkkDivisiList'] as List).map((e) => Map<String, dynamic>.from(e)).toList();

      final report = TambahKurangCalculator.calculate(
        baselineDivisiList: baseline,
        addendumDivisiList: addendum,
        customPaguDibulatkan: 288350000.0,
      );

      // 1. Pembulatan resmi
      expect(report.totalDibulatkan, 288350000.0);

      // 2. Kontrak Awal & Addendum Bobot
      expect(report.totalBaselineBobot, 100.000);
      expect(report.totalAddendumBobot, 100.000);

      // 3. Pekerjaan Tambah (Beton fc 15Mpa)
      expect((report.totalTambahHarga - 6072621.06).abs() < 0.1, isTrue);
      expect(report.totalTambahBobot.toStringAsFixed(3), '2.106');

      // 4. Pekerjaan Kurang (Bongkaran + Saluran U + Keramik)
      expect((report.totalKurangHarga - 6072244.10).abs() < 0.1, isTrue);
      expect(report.totalKurangBobot.toStringAsFixed(3), '2.106');

      // 5. Net tambah kurang seimbang pada pagu dibulatkan
      expect((report.totalTambahBobot - report.totalKurangBobot).abs() < 0.001, isTrue);
    });

    test('KegiatanModel correctly resolves activeRkkDivisiList and addendum metadata', () {
      final sampleRkk = KegiatanModel.defaultSampleRkk();
      final kegiatan = KegiatanModel(
        namaKegiatan: 'Pemeliharaan Berkala Jalan MT Haryono',
        rkkDivisiList: sampleRkk,
      );

      // Before addendum
      expect(kegiatan.hasAddendum, isFalse);
      expect(kegiatan.totalAddendumCount, 0);
      expect(kegiatan.activeRkkDivisiList.length, sampleRkk.length);

      // Add Addendum 01
      final addendumList = [
        {
          'id': 'addendum-01-test',
          'nomorAddendum': '01',
          'judul': 'Daftar Perhitungan Tambah Kurang Ke - 01',
          'nomorSpkAddendum': '602.1/01/ADD-01/2026',
          'tanggalAddendum': '15 Agustus 2026',
          'rkkDivisiList': [
            {
              'nomorRomawi': 'I',
              'namaDivisi': 'DIVISI 1 UMUM (ADDENDUM)',
              'items': [
                {
                  'no': '1',
                  'noMataPembayaran': '1.2',
                  'uraian': 'Mobilisasi',
                  'satuan': 'Ls',
                  'hargaSatuan': 12900000.0,
                  'volume': 1.00,
                  'totalHarga': 12900000.0,
                  'nilaiBobot': 4.474,
                }
              ],
            }
          ],
        }
      ];

      final kegiatanWithAddendum = KegiatanModel(
        namaKegiatan: 'Pemeliharaan Berkala Jalan MT Haryono',
        rkkDivisiList: sampleRkk,
        addendums: addendumList,
      );

      expect(kegiatanWithAddendum.hasAddendum, isTrue);
      expect(kegiatanWithAddendum.totalAddendumCount, 1);
      expect(kegiatanWithAddendum.latestAddendum?['nomorAddendum'], '01');
      // activeRkkDivisiList should now point to Addendum 01's list
      expect(kegiatanWithAddendum.activeRkkDivisiList.length, 1);
      expect(kegiatanWithAddendum.activeRkkDivisiList[0]['namaDivisi'], 'DIVISI 1 UMUM (ADDENDUM)');
    });
  });

  group('Addendum UI Widgets & Screens Tests', () {
    testWidgets('LembarTambahKurangWidget renders 18 columns and signatures', (tester) async {
      final sampleRkk = KegiatanModel.defaultSampleRkk();
      final kegiatan = KegiatanModel(
        namaKegiatan: 'Pemeliharaan Berkala Jalan Paket 2',
        lokasi: 'Kab. Purbalingga',
        kontraktor: 'CV. DIVAN INSAN CEMERLANG',
        penggunaAnggaran: 'DRAJAT UJI WAKHYONO, S.T., M.T.',
        direkturKonsultan: 'NURKHOLIS WIJANTO',
        rkkDivisiList: sampleRkk,
      );

      final addendumData = {
        'id': 'addendum-01',
        'nomorAddendum': '01',
        'judul': 'DAFTAR PERHITUNGAN TAMBAH KURANG KE - 01',
        'rkkDivisiList': sampleRkk,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LembarTambahKurangWidget(
                kegiatan: kegiatan,
                addendumData: addendumData,
                baselineDivisiList: sampleRkk,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check official titles and headers
      expect(find.text('DAFTAR PERHITUNGAN TAMBAH KURANG KE - 01'), findsOneWidget);
      expect(find.text('KONTRAK AWAL'), findsOneWidget);
      expect(find.text('ADDENDUM 01'), findsOneWidget);
      expect(find.text('PEKERJAAN TAMBAH KURANG'), findsOneWidget);
      expect(find.text('KET.'), findsOneWidget);

      // Check footer totals and signatures
      expect(find.text('Jumlah Total Harga Pekerjaan ( Dibulatkan )'), findsOneWidget);
      expect(find.textContaining('DRAJAT UJI WAKHYONO'), findsOneWidget);
      expect(find.textContaining('CV. DIVAN INSAN CEMERLANG'), findsWidgets);
    });

    testWidgets('KelolaAddendumScreen displays status and navigates to FormAddendumScreen', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleRkk = KegiatanModel.defaultSampleRkk();
      final contract = _createTestContract(
        id: 'test-contract-cco',
        kegiatans: [
          {
            'namaKegiatan': 'Pemeliharaan Jalan MT Haryono',
            'rkkDivisiList': sampleRkk,
            'rkkKontrakAwal': sampleRkk,
            'addendums': [],
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.contracts.add(contract);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: contractProvider,
          child: MaterialApp(
            home: KelolaAddendumScreen(
              contract: contract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show initial state with Kontrak Awal
      expect(find.text('Kontrak Awal (RAB Original)'), findsOneWidget);
      expect(find.text('Buat Addendum 01 (CCO)'), findsWidgets);
      expect(find.text('Belum Ada Addendum / CCO'), findsOneWidget);

      // Tap to open FormAddendumScreen
      await tester.tap(find.text('Buat Addendum 01 (CCO)').first);
      await tester.pumpAndSettle();

      // FormAddendumScreen should be displayed
      expect(find.text('Buat Addendum Baru (CCO)'), findsOneWidget);
      expect(find.text('Volume Baru (CCO)'), findsWidgets);
      expect(find.text('Simpan Addendum'), findsOneWidget);
    });

    testWidgets('DetailKegiatanScreen displays active Addendum info and Lembar Tambah Kurang action', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleRkk = KegiatanModel.defaultSampleRkk();
      final contract = _createTestContract(
        id: 'test-contract-detail-addendum',
        kegiatans: [
          {
            'namaKegiatan': 'Pemeliharaan Jalan MT Haryono',
            'rkkDivisiList': sampleRkk,
            'rkkKontrakAwal': sampleRkk,
            'addendums': [
              {
                'id': 'addendum-01',
                'nomorAddendum': '01',
                'judul': 'Daftar Perhitungan Tambah Kurang Ke - 01',
                'rkkDivisiList': sampleRkk,
              }
            ],
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.contracts.add(contract);

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: contractProvider,
          child: MaterialApp(
            home: DetailKegiatanScreen(
              contract: contract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show Addendum 01 badge
      expect(find.text('Addendum 01'), findsOneWidget);
      expect(find.textContaining('Kelola Addendum (1)'), findsOneWidget);
      expect(find.textContaining('RINCIAN KUANTITAS KONTRAK (ADDENDUM 01)'), findsOneWidget);
      expect(find.text('Lembar Tambah Kurang'), findsOneWidget);

      // Tap Lembar Tambah Kurang to open bottom sheet
      await tester.tap(find.text('Lembar Tambah Kurang'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Lembar Perhitungan Tambah Kurang (01)'), findsOneWidget);
      expect(find.text('DAFTAR PERHITUNGAN TAMBAH KURANG KE - 01'), findsOneWidget);
    });
  });
}
