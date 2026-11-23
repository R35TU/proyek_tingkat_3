import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';
import 'package:tata_saka_app/models/addendum_model.dart';

void main() {
  group('Verifikasi Logika Perhitungan Bobot RAB & Pengelolaan Nilai Kontrak', () {
    // Data riil dari kasus user (Screenshots)
    // Divisi I: Rp 22.180.500
    // Divisi VI: Rp 346.868.474,90
    // Divisi X: Rp 15.501.314,34
    // Total RAB = Rp 384.550.289,24
    late List<Map<String, dynamic>> userRkkSample;

    setUp(() {
      userRkkSample = [
        {
          'nomorRomawi': 'I',
          'namaDivisi': 'DIVISI I. UMUM',
          'items': [
            {
              'no': '1',
              'noMataPembayaran': '1.2',
              'uraian': 'Mobilisasi',
              'satuan': 'Ls',
              'hargaSatuan': 15552000.0,
              'volume': 1.0,
              'totalHarga': 15552000.0,
              'nilaiBobot': 0.0,
            },
            {
              'no': '2',
              'noMataPembayaran': '1.8.(1)',
              'uraian': 'Manajemen dan Keselamatan lalu lintas',
              'satuan': 'Ls',
              'hargaSatuan': 5150000.0,
              'volume': 1.0,
              'totalHarga': 5150000.0,
              'nilaiBobot': 0.0,
            },
            {
              'no': '3',
              'noMataPembayaran': '1.19',
              'uraian': 'Keselamatan dan Kesehatan Kerja (SMK3)',
              'satuan': 'Ls',
              'hargaSatuan': 1478500.0,
              'volume': 1.0,
              'totalHarga': 1478500.0,
              'nilaiBobot': 0.0,
            },
          ],
        },
        {
          'nomorRomawi': 'VI',
          'namaDivisi': 'DIVISI 6. PERKERASAN ASPAL',
          'items': [
            {
              'no': '1',
              'noMataPembayaran': '6.1(2a)',
              'uraian': 'Lapis Perekat-Aspal Cair/Emulsi',
              'satuan': 'liter',
              'hargaSatuan': 25958.0,
              'volume': 424.35,
              'totalHarga': 11015277.30,
              'nilaiBobot': 0.0,
            },
            {
              'no': '2',
              'noMataPembayaran': '6.3(5a)',
              'uraian': 'laston Lapis Aus (AC-WC)',
              'satuan': 'Ton',
              'hargaSatuan': 1963921.0,
              'volume': 158.4,
              'totalHarga': 311085086.40,
              'nilaiBobot': 0.0,
            },
            {
              'no': '3',
              'noMataPembayaran': '6.3(6a)',
              'uraian': 'laston Lapis Antara (AC-BC)',
              'satuan': 'Ton',
              'hargaSatuan': 1922990.0,
              'volume': 12.88,
              'totalHarga': 24768111.20,
              'nilaiBobot': 0.0,
            },
          ],
        },
        {
          'nomorRomawi': 'X',
          'namaDivisi': 'DIVISI 10. PEMELIHARAAN KINERJA',
          'items': [
            {
              'no': '1',
              'noMataPembayaran': '10.1(9)',
              'uraian': 'Perbaikan Campuran Aspal Panas',
              'satuan': 'm3',
              'hargaSatuan': 5065789.0,
              'volume': 3.06,
              'totalHarga': 15501314.34,
              'nilaiBobot': 0.0,
            },
          ],
        },
      ];
    });

    testWidgets('1. Perhitungan Bobot Menggunakan Total Nilai RAB Sebagai Pembagi Konsisten', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-bobot-check',
        namaKontrak: 'Pemeliharaan Berkala Jalan Ketuhu',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 384.550.289,24',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Pemeliharaan Berkala Jalan Ketuhu',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. KONTRAKTOR JALAN',
            'nilaiKontrak': 'Rp 384.550.289,24',
            'rkkDivisiList': userRkkSample,
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: KelolaRkkScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Total RAB adalah Rp 384.550.289,24
      expect(find.text('Rp 384.550.289,24'), findsWidgets);

      // 2. Total Bobot adalah 100.000% (bukan 1042.479%!)
      expect(find.text('100.000'), findsWidgets);
      expect(find.text('1042.479'), findsNothing);
      expect(find.text('Sesuai 100%'), findsOneWidget);

      // 3. Bobot Item 1 (Mobilisasi): 15.552.000 / 384.550.289,24 * 100 = 4.044%
      expect(find.text('Bobot: 4.044%'), findsOneWidget);

      // 4. Bobot Item 2 (Manajemen Lalu Lintas): 5.150.000 / 384.550.289,24 * 100 = 1.339% (BUKAN 33.115%!)
      expect(find.text('Bobot: 1.339%'), findsOneWidget);
      expect(find.text('Bobot: 33.115%'), findsNothing);

      // 5. Bobot Item 3 (SMK3): 1.478.500 / 384.550.289,24 * 100 = 0.384% (BUKAN 7.142%!)
      expect(find.text('Bobot: 0.384%'), findsOneWidget);
      expect(find.text('Bobot: 7.142%'), findsNothing);

      // 6. Subtotal Divisi I: 22.180.500 / 384.550.289,24 * 100 = 5.768% (BUKAN 44.301%!)
      expect(find.textContaining('Bobot: 5.768%'), findsOneWidget);
      expect(find.textContaining('44.301%'), findsNothing);

      // 7. Divisi VI: Lapis Aus (AC-WC) Rp 311.085.086,40 bobotnya 80.896% (BUKAN 937.122%!)
      expect(find.text('Bobot: 80.896%'), findsOneWidget);
      expect(find.textContaining('937.122%'), findsNothing);
    });

    testWidgets('2. Nilai Kontrak Awal Tetap Menjadi Acuan dan Tidak Berubah Otomatis Saat Tambah/Edit/Simpan', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const initialFixedContractValue = 'Rp 500.000.000';

      final contract = ContractModel(
        id: 'c-contract-fix-test',
        namaKontrak: 'PEMBANGUNAN JEMBATAN KABUPATEN',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: initialFixedContractValue,
        hariKalender: 120,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 November 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Jembatan Sungai Gintung',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. KARYA JAYA',
            'nilaiKontrak': initialFixedContractValue,
            'rkkDivisiList': [
              {
                'nomorRomawi': 'I',
                'namaDivisi': 'DIVISI I. UMUM',
                'items': [
                  {
                    'no': '1',
                    'noMataPembayaran': '1.2',
                    'uraian': 'Mobilisasi',
                    'satuan': 'Ls',
                    'hargaSatuan': 15552000.0,
                    'volume': 1.0,
                    'totalHarga': 15552000.0,
                    'nilaiBobot': 3.110,
                  }
                ],
              }
            ],
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: KelolaRkkScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nilai Kontrak Awal tetap ditampilkan sebagai acuan tetap
      expect(find.textContaining('Nilai Kontrak: Rp 500.000.000'), findsOneWidget);

      // Simpan RKK
      final saveBtn = find.text('Simpan');
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Pastikan nilaiKontrak pada kegiatan TIDAK berubah menjadi Rp 15.552.000!
      final savedKeg = contract.kegiatans[0];
      expect(savedKeg['nilaiKontrak'], equals(initialFixedContractValue));
    });

    testWidgets('3. DetailKegiatanScreen Menampilkan Tabel RAB dengan Bobot Konsisten 100.000%', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-detail-check',
        namaKontrak: 'Pemeliharaan Berkala Jalan Ketuhu',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 384.550.289,24',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Pemeliharaan Berkala Jalan Ketuhu',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. KONTRAKTOR JALAN',
            'nilaiKontrak': 'Rp 384.550.289,24',
            'rkkDivisiList': userRkkSample,
          }
        ],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: DetailKegiatanScreen(contract: contract, kegiatanIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll ke tabel RAB
      await tester.scrollUntilVisible(
        find.text('JUMLAH TOTAL HARGA PEKERJAAN'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      // Verifikasi baris Total memiliki bobot 100.000% (bukan 1042.479%)
      expect(find.text('100.000%'), findsWidgets);
      expect(find.textContaining('1042.479%'), findsNothing);

      // Verifikasi baris JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN) terbulat ke bawah kelipatan Rp 1.000
      // 384.550.289,24 dibulatkan menjadi 384.550.000,00
      expect(find.text('JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN)'), findsOneWidget);
      expect(find.text('384.550.000,00'), findsOneWidget);
    });

    test('4. Logika Floor to Nearest Thousand dan Format Desimal Berjalan Konsisten', () {
      // Contoh dari instruksi user:
      // Rp1.234.999,00 -> Rp1.234.000,00
      // Rp1.234.500,00 -> Rp1.234.000,00
      // Rp1.234.001,00 -> Rp1.234.000,00
      // Rp1.999.999,00 -> Rp1.999.000,00
      expect(RupiahUtil.floorToNearestThousand(1234999.00), 1234000.0);
      expect(RupiahUtil.floorToNearestThousand(1234500.00), 1234000.0);
      expect(RupiahUtil.floorToNearestThousand(1234001.00), 1234000.0);
      expect(RupiahUtil.floorToNearestThousand(1999999.00), 1999000.0);

      // Kasus kegiatan riil:
      // Pemeliharaan Berkala Jalan Ketuhu: 384.550.289,24 -> 384.550.000,00
      expect(RupiahUtil.floorToNearestThousand(384550289.24), 384550000.0);
      // Ruas Jalan A: 288.350.703,03 -> 288.350.000,00
      expect(RupiahUtil.floorToNearestThousand(288350703.03), 288350000.0);

      // Format tampilan dengan desimal sen ',00'
      final fmtKetuhu = KelolaRkkScreen.formatRupiah(384550000.0, forceDecimals: true);
      expect(fmtKetuhu, 'Rp 384.550.000,00');

      final fmtRuasA = KelolaRkkScreen.formatRupiah(288350000.0, forceDecimals: true);
      expect(fmtRuasA, 'Rp 288.350.000,00');
    });

    testWidgets('5. DetailKegiatanScreen Menampilkan Pembulatan Kelipatan Rp1.000 pada Kedua Kegiatan (Ruas Jalan A & Jalan Ketuhu)', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final demoContract = SampleContractData.getDemoContract();
      final contractProvider = ContractProvider();
      contractProvider.addContract(demoContract);

      // Uji Kegiatan 0 (Ruas Jalan A: unrounded 288.350.703,03 -> dibulatkan 288.350.000,00)
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: DetailKegiatanScreen(
              key: const ValueKey('ruas-a-screen'),
              contract: demoContract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN)'), findsOneWidget);
      expect(find.text('288.350.000,00'), findsOneWidget);

      // Uji Kegiatan 1 (Jalan Ketuhu jika ditambahkan ke demoContract atau kegiatan baru)
      final ketuhuContract = ContractModel(
        id: 'c-ketuhu',
        namaKontrak: 'Pemeliharaan Berkala Jalan Ketuhu',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 384.550.289,24',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-01',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        kegiatans: [
          {
            'namaKegiatan': 'Pemeliharaan Berkala Jalan Ketuhu',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. KONTRAKTOR JALAN',
            'nilaiKontrak': 'Rp 384.550.289,24',
            'rkkDivisiList': userRkkSample,
          }
        ],
      );
      contractProvider.addContract(ketuhuContract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: DetailKegiatanScreen(
              key: const ValueKey('ketuhu-screen'),
              contract: ketuhuContract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN)'), findsOneWidget);
      // Di Kegiatan Jalan Ketuhu, sekarang juga tampil 384.550.000,00 (BUKAN 384.550.289,24!)
      expect(find.text('384.550.000,00'), findsOneWidget);
    });

    testWidgets('6. Konsistensi Nilai Asli: Nilai Nominal Asli Sebelum Pembulatan Adalah Single Source of Truth untuk Seluruh Sistem', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Contoh sesuai skenario user:
      // Item 1: Total Rp 1.234.567,89 (Volume 10, HS 123456.789)
      // Item 2: Total Rp 8.765.432,11 (Volume 10, HS 876543.211)
      // Total Proyek Asli = Rp 10.000.000,00
      // Contoh lain dengan total berdesimal:
      // Item 1: Rp 1.234.567,89 (Volume 1)
      // Item 2: Rp 3.765.432,11 (Volume 1)
      // Total Asli = Rp 5.000.000,00
      // Kasus total acak dengan desimal dan sisa ratusan perak:
      // Item 1: Total Rp 1.234.567,89 (Volume: 10, HS: 123456.789)
      // Item 2: Total Rp 2.345.678,50 (Volume: 10, HS: 234567.850)
      // Total Asli = Rp 3.580.246,39
      // Dibulatkan pada tampilan = Rp 3.580.000,00
      final rawItem1Total = 1234567.89;
      final rawItem2Total = 2345678.50;
      final rawTotalAsli = rawItem1Total + rawItem2Total; // 3580246.39
      final rawBobot1 = (rawItem1Total / rawTotalAsli) * 100.0; // 34.4827...%
      final rawBobot2 = (rawItem2Total / rawTotalAsli) * 100.0; // 65.5172...%

      final customRkkSample = [
        {
          'nomorRomawi': 'I',
          'namaDivisi': 'DIVISI I. UMUM',
          'items': [
            {
              'id': 'I_Pekerjaan_A',
              'no': '1',
              'noMataPembayaran': '1.1',
              'uraian': 'Pekerjaan Presisi A',
              'satuan': 'm',
              'hargaSatuan': 123456.789,
              'volume': 10.0,
              'totalHarga': rawItem1Total,
              'nilaiBobot': rawBobot1,
            },
            {
              'id': 'I_Pekerjaan_B',
              'no': '2',
              'noMataPembayaran': '1.2',
              'uraian': 'Pekerjaan Presisi B',
              'satuan': 'm',
              'hargaSatuan': 234567.850,
              'volume': 10.0,
              'totalHarga': rawItem2Total,
              'nilaiBobot': rawBobot2,
            },
          ],
        }
      ];

      final kegMap = {
        'namaKegiatan': 'Pengujian Presisi Asli',
        'lokasi': 'Kab. Purbalingga',
        'kontraktor': 'CV. DATA ASLI',
        'nilaiKontrak': 'Rp 3.580.246,39',
        'rkkDivisiList': customRkkSample,
        'rkkKontrakAwal': customRkkSample,
        'laporans': [
          {
            'tanggal': '01 Juli 2026',
            'pekerjaanList': [
              {
                'rkkItemId': 'I_Pekerjaan_A',
                'noMataPembayaran': '1.1',
                'uraian': 'Pekerjaan Presisi A',
                'volume': '5.0 m', // 50% dari volume kontrak 10.0 m
              }
            ],
          }
        ],
      };

      final precisionContract = ContractModel(
        id: 'c-precision-audit',
        namaKontrak: 'Kontrak Presisi Penuh',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 3.580.246,39',
        hariKalender: 60,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-AUDIT-01',
        nomorSpmk: 'SPMK-AUDIT-01',
        tglMulaiSpmk: '01 Juli 2026',
        tglSelesaiSpmk: '30 Agustus 2026',
        sumberDana: 'APBD',
        deskripsi: 'Audit Presisi Penuh',
        kegiatans: [kegMap],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(precisionContract);

      // A. Verifikasi Tampilan Tabel RAB di DetailKegiatanScreen:
      // JUMLAH TOTAL HARGA PEKERJAAN tetap menampilkan nilai asli '3.580.246,39'
      // JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN) menampilkan '3.580.000,00'
      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: DetailKegiatanScreen(
              key: const ValueKey('precision-screen'),
              contract: precisionContract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('JUMLAH TOTAL HARGA PEKERJAAN'), findsOneWidget);
      expect(find.text('3.580.246,39'), findsWidgets); // Nilai asli presisi penuh (Subtotal Divisi & Total Pekerjaan)
      expect(find.text('JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN)'), findsOneWidget);
      expect(find.text('3.580.000,00'), findsOneWidget); // Pembulatan khusus baris tampilan display tabel

      // B. Verifikasi Perhitungan Progres di ProgressCalculator:
      // Progres harus dihitung berdasarkan nilai data asli (rawBobot1):
      // Volume terealisasi = 5.0 dari 10.0 (50%)
      // Kontribusi progres = 50% * rawBobot1 = 50% * 34.4827...% = 17.2413...%
      final calculatedProgress = ProgressCalculator.calculateKegiatanProgress(kegMap);
      final expectedProgress = 0.5 * rawBobot1;
      expect((calculatedProgress - expectedProgress).abs() < 0.0001, isTrue);

      // Jika sistem salah menggunakan nilai dibulatkan (3.580.000), bobot item 1 akan menjadi:
      // (1.234.567,89 / 3.580.000) * 100 = 34.4851% -> progress = 17.2425% (Selisih!)
      final wrongProgressIfUsingFloored = 0.5 * ((rawItem1Total / 3580000.0) * 100.0);
      expect((calculatedProgress - wrongProgressIfUsingFloored).abs() > 0.001, isTrue);

      // C. Verifikasi TambahKurangCalculator:
      // Pagu pembagi bobot default menggunakan t0 asli (3.580.246,39), BUKAN 3.580.000,00
      final report = TambahKurangCalculator.calculate(
        baselineDivisiList: customRkkSample,
        addendumDivisiList: customRkkSample,
        customPaguDibulatkan: 3580246.39,
      );

      // Total bobot baseline dan addendum tepat 100% menggunakan nilai asli
      expect((report.totalBaselineBobot - 100.0).abs() < 0.001, isTrue);
      // Tampilan dibulatkan tetap menghasilkan 3.580.000,00
      expect(report.totalDibulatkan, 3580000.0);
    });
  });
}
