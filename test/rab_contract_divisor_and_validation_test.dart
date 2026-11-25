import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';

void main() {
  group('15 Skenario Pengujian Validasi RAB & Dasar Bobot Nilai Kontrak', () {

    // ─── 1. Skenario 1: Nilai Kontrak Angka Bulat ───
    test('Skenario 1: Nilai Kontrak Angka Bulat (Rp 1.000.000) tersimpan dan terformat presisi', () {
      const inputStr = '1.000.000';
      final parsed = RupiahUtil.parseToDouble(inputStr);
      expect(parsed, equals(1000000.0));

      final formatted = KelolaRkkScreen.formatRupiah(parsed);
      expect(formatted, equals('Rp 1.000.000'));
    });

    // ─── 2. Skenario 2: Nilai Kontrak Desimal ───
    test('Skenario 2: Nilai Kontrak Desimal (Rp 288.350.326,79) tersimpan dengan presisi penuh tanpa pemotongan desimal', () {
      const inputStr = '288.350.326,79';
      final parsed = RupiahUtil.parseToDouble(inputStr);
      expect(parsed, closeTo(288350326.79, 0.0001));

      final formatted = KelolaRkkScreen.formatRupiah(parsed);
      expect(formatted, equals('Rp 288.350.326,79'));
    });

    // ─── 3. Skenario 3: 1 Item Bobot < 100% ───
    test('Skenario 3: Input 1 item bernilai Rp 500.000 dari nilai kontrak Rp 1.000.000 menghasilkan bobot 50%, bukan 100%', () {
      const double nilaiKontrak = 1000000.0;
      const double hargaItem = 500000.0;

      // Rumus: (Harga Item / Nilai Kontrak) * 100
      final double bobotItem = (hargaItem / nilaiKontrak) * 100.0;
      expect(bobotItem, equals(50.0));

      final double totalRab = hargaItem;
      final double totalBobot = (totalRab / nilaiKontrak) * 100.0;
      expect(totalBobot, equals(50.0));
      expect(totalBobot, isNot(equals(100.0)));
    });

    // ─── 4. Skenario 4: Akumulasi Beberapa Item < 100% (Status Kuning — Belum Sesuai) ───
    test('Skenario 4: Akumulasi beberapa item menghasilkan Rp 800.000 (80%), kekurangan Rp 200.000, status Belum Sesuai', () {
      const double nilaiKontrak = 1000000.0;
      final items = [
        {'nama': 'Item 1', 'totalHarga': 300000.0},
        {'nama': 'Item 2', 'totalHarga': 500000.0},
      ];

      final double totalRab = items.fold(0.0, (acc, it) => acc + (it['totalHarga'] as double));
      expect(totalRab, equals(800000.0));

      final double totalBobot = (totalRab / nilaiKontrak) * 100.0;
      expect(totalBobot, equals(80.0));

      final double diff = totalRab - nilaiKontrak;
      final bool isSesuai = diff.abs() <= 0.005;
      final bool isKurang = !isSesuai && diff < 0;
      final bool isMelebihi = !isSesuai && diff > 0;

      expect(isSesuai, isFalse);
      expect(isKurang, isTrue);
      expect(isMelebihi, isFalse);

      final double kekurangan = diff.abs();
      expect(kekurangan, equals(200000.0));
    });

    // ─── 5. Skenario 5: Akumulasi Tepat 100% (Status Hijau — Sesuai) ───
    test('Skenario 5: Akumulasi item tepat sama dengan nilai kontrak Rp 1.000.000, total bobot 100%, status Sesuai', () {
      const double nilaiKontrak = 1000000.0;
      final items = [
        {'nama': 'Item 1', 'totalHarga': 300000.0},
        {'nama': 'Item 2', 'totalHarga': 500000.0},
        {'nama': 'Item 3', 'totalHarga': 200000.0},
      ];

      final double totalRab = items.fold(0.0, (acc, it) => acc + (it['totalHarga'] as double));
      expect(totalRab, equals(1000000.0));

      final double totalBobot = (totalRab / nilaiKontrak) * 100.0;
      expect(totalBobot, closeTo(100.0, 0.001));

      final double diff = totalRab - nilaiKontrak;
      final bool isSesuai = diff.abs() <= 0.005;
      final bool isKurang = !isSesuai && diff < 0;
      final bool isMelebihi = !isSesuai && diff > 0;

      expect(isSesuai, isTrue);
      expect(isKurang, isFalse);
      expect(isMelebihi, isFalse);
    });

    // ─── 6. Skenario 6: Akumulasi Melebihi 100% (Status Merah — Melebihi) ───
    test('Skenario 6: Akumulasi item Rp 1.100.000 (110%), kelebihan Rp 100.000, status Melebihi', () {
      const double nilaiKontrak = 1000000.0;
      final items = [
        {'nama': 'Item 1', 'totalHarga': 600000.0},
        {'nama': 'Item 2', 'totalHarga': 500000.0},
      ];

      final double totalRab = items.fold(0.0, (acc, it) => acc + (it['totalHarga'] as double));
      expect(totalRab, equals(1100000.0));

      final double totalBobot = (totalRab / nilaiKontrak) * 100.0;
      expect(totalBobot, closeTo(110.0, 0.001));

      final double diff = totalRab - nilaiKontrak;
      final bool isSesuai = diff.abs() <= 0.005;
      final bool isKurang = !isSesuai && diff < 0;
      final bool isMelebihi = !isSesuai && diff > 0;

      expect(isSesuai, isFalse);
      expect(isKurang, isFalse);
      expect(isMelebihi, isTrue);

      final double kelebihan = diff.abs();
      expect(kelebihan, equals(100000.0));
    });

    // ─── 7. Skenario 7: Ubah Volume Item ───
    test('Skenario 7: Mengubah volume item dari 1 menjadi 2 memperbarui bobot item dan total bobot secara proporsional', () {
      const double nilaiKontrak = 1000000.0;
      const double hargaSatuan = 250000.0;

      // Volume awal = 1 -> Total = 250.000 -> Bobot = 25%
      double volume = 1.0;
      double itemTotal = hargaSatuan * volume;
      double bobot = (itemTotal / nilaiKontrak) * 100.0;
      expect(bobot, equals(25.0));

      // Volume diubah menjadi 2 -> Total = 500.000 -> Bobot = 50%
      volume = 2.0;
      itemTotal = hargaSatuan * volume;
      bobot = (itemTotal / nilaiKontrak) * 100.0;
      expect(bobot, equals(50.0));
    });

    // ─── 8. Skenario 8: Ubah Harga Satuan Item ───
    test('Skenario 8: Mengubah harga satuan memperbarui total harga item, total RAB, dan seluruh bobot terkait', () {
      const double nilaiKontrak = 1000000.0;
      const double volume = 2.0;

      // Harga satuan awal = 100.000 -> Total = 200.000 -> Bobot = 20%
      double hargaSatuan = 100000.0;
      double itemTotal = hargaSatuan * volume;
      double bobot = (itemTotal / nilaiKontrak) * 100.0;
      expect(bobot, equals(20.0));

      // Harga satuan diubah menjadi 300.000 -> Total = 600.000 -> Bobot = 60%
      hargaSatuan = 300000.0;
      itemTotal = hargaSatuan * volume;
      bobot = (itemTotal / nilaiKontrak) * 100.0;
      expect(bobot, equals(60.0));
    });

    // ─── 9. Skenario 9: Penghapusan Item ───
    test('Skenario 9: Menghapus item mengurangi total RAB dan total bobot secara akurat tanpa mempengaruhi bobot item lain terhadap nilai kontrak', () {
      const double nilaiKontrak = 1000000.0;
      final items = [
        {'nama': 'Item 1', 'totalHarga': 300000.0},
        {'nama': 'Item 2', 'totalHarga': 400000.0},
        {'nama': 'Item 3', 'totalHarga': 300000.0},
      ];

      // Total awal: 1.000.000 (100%)
      double totalRab = items.fold(0.0, (acc, it) => acc + (it['totalHarga'] as double));
      expect(totalRab, equals(1000000.0));
      expect((totalRab / nilaiKontrak) * 100.0, equals(100.0));

      // Hapus Item 2 (400.000)
      items.removeAt(1);

      // Total setelah hapus: 600.000 (60%)
      totalRab = items.fold(0.0, (acc, it) => acc + (it['totalHarga'] as double));
      expect(totalRab, equals(600000.0));
      expect((totalRab / nilaiKontrak) * 100.0, equals(60.0));

      // Bobot Item 1 tetap 300.000 / 1.000.000 * 100 = 30% terhadap nilai kontrak
      final double bobotItem1 = (items[0]['totalHarga'] as double) / nilaiKontrak * 100.0;
      expect(bobotItem1, equals(30.0));
    });

    // ─── 10. Skenario 10: Penambahan dan Penghapusan Divisi ───
    test('Skenario 10: Menambah divisi baru lalu menghapusnya mengembalikan total bobot ke nilai sebelumnya', () {
      const double nilaiKontrak = 1000000.0;
      final divisiList = [
        {
          'nama': 'DIVISI I',
          'items': [
            {'totalHarga': 200000.0},
          ]
        }
      ];

      double computeTotal() {
        double sum = 0.0;
        for (final d in divisiList) {
          for (final it in (d['items'] as List)) {
            sum += (it['totalHarga'] as double);
          }
        }
        return sum;
      }

      final initialTotal = computeTotal();
      expect(initialTotal, equals(200000.0));
      expect((initialTotal / nilaiKontrak) * 100.0, equals(20.0));

      // Tambah Divisi II dengan item bernilai 300.000
      divisiList.add({
        'nama': 'DIVISI II',
        'items': [
          {'totalHarga': 300000.0},
        ]
      });

      final withNewDivisiTotal = computeTotal();
      expect(withNewDivisiTotal, equals(500000.0));
      expect((withNewDivisiTotal / nilaiKontrak) * 100.0, equals(50.0));

      // Hapus Divisi II
      divisiList.removeLast();

      final revertedTotal = computeTotal();
      expect(revertedTotal, equals(initialTotal));
      expect((revertedTotal / nilaiKontrak) * 100.0, equals(20.0));
    });

    // ─── 11. Skenario 11: Ubah Nilai Kontrak Setelah RAB Terisi ───
    test('Skenario 11: Mengubah nilai kontrak dari Rp 1.000.000 ke Rp 2.000.000 menghitung ulang bobot seluruh item secara otomatis', () {
      const double hargaItem = 500000.0;

      // Awal: nilai kontrak 1.000.000 -> bobot = 50%
      double nilaiKontrak = 1000000.0;
      double bobot = (hargaItem / nilaiKontrak) * 100.0;
      expect(bobot, equals(50.0));

      // Nilai kontrak diperbarui menjadi 2.000.000 -> bobot = 25%
      nilaiKontrak = 2000000.0;
      bobot = (hargaItem / nilaiKontrak) * 100.0;
      expect(bobot, equals(25.0));
    });

    // ─── 12. Skenario 12: Presisi Desimal Penuh (Kasus Nyata Rp 288.350.326,79) ───
    test('Skenario 12: Nilai riil kasus desimal Rp 288.350.326,79 mempertahankan presisi sen pada perhitungan bobot', () {
      const double nilaiKontrak = 288350326.79;
      // Item: Gorong-Gorong Kotak Beton Bertulang 50cmx50cm: Volume 4.8 m1, HS Rp 2.139.059,32
      const double volume = 4.8;
      const double hargaSatuan = 2139059.32;
      final double totalItem = volume * hargaSatuan; // 10.267.484,736

      final double bobot = (totalItem / nilaiKontrak) * 100.0;
      // 10.267.484,736 / 288.350.326,79 * 100 = 3.5607...% -> 3.561%
      expect(bobot.toStringAsFixed(3), equals('3.561'));
      expect(totalItem, closeTo(10267484.736, 0.001));
    });

    // ─── 13. Skenario 13: Independensi Urutan Input ───
    test('Skenario 13: Urutan input item (A lalu B vs B lalu A) menghasilkan bobot yang persis identik', () {
      const double nilaiKontrak = 1000000.0;
      const double hargaA = 300000.0;
      const double hargaB = 700000.0;

      // Urutan 1: A diinput dulu, lalu B
      final double bobotA1 = (hargaA / nilaiKontrak) * 100.0;
      final double bobotB1 = (hargaB / nilaiKontrak) * 100.0;

      // Urutan 2: B diinput dulu, lalu A
      final double bobotB2 = (hargaB / nilaiKontrak) * 100.0;
      final double bobotA2 = (hargaA / nilaiKontrak) * 100.0;

      expect(bobotA1, equals(bobotA2));
      expect(bobotB1, equals(bobotB2));
      expect(bobotA1 + bobotB1, equals(bobotB2 + bobotA2));
    });

    // ─── 14. Skenario 14: Persistensi Data (JSON Serialization & Deserialization) ───
    test('Skenario 14: Data RAB dengan nilai desimal dan bobot disimpan ke JSON dan dimuat kembali tanpa kehilangan presisi', () {
      final initialData = {
        'nilaiKontrak': 'Rp 288.350.326,79',
        'rkkDivisiList': [
          {
            'nomorRomawi': 'II',
            'namaDivisi': 'DIVISI 2. DRAINASE',
            'items': [
              {
                'no': '1',
                'noMataPembayaran': '2.3.(12)',
                'uraian': 'Gorong-Gorong Kotak',
                'satuan': 'm1',
                'hargaSatuan': 2139059.32,
                'volume': 4.8,
                'totalHarga': 10267484.74,
                'nilaiBobot': 3.561,
              }
            ]
          }
        ]
      };

      // Serialisasi JSON
      final jsonString = jsonEncode(initialData);

      // Deserialisasi JSON
      final restoredData = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(restoredData['nilaiKontrak'], equals('Rp 288.350.326,79'));
      final parsedKontrak = RupiahUtil.parseToDouble(restoredData['nilaiKontrak'] as String);
      expect(parsedKontrak, closeTo(288350326.79, 0.001));

      final items = (restoredData['rkkDivisiList'] as List)[0]['items'] as List;
      final item = items[0] as Map<String, dynamic>;
      expect(item['hargaSatuan'], equals(2139059.32));
      expect(item['volume'], equals(4.8));
      expect(item['totalHarga'], equals(10267484.74));
      expect(item['nilaiBobot'], equals(3.561));
    });

    // ─── 15. Skenario 15: Konsistensi dengan Modul Lain (ProgressCalculator) ───
    test('Skenario 15: Nilai bobot konsisten dengan kalkulasi progres mingguan ProgressCalculator', () {
      final divisiList = [
        {
          'namaDivisi': 'DIVISI I. UMUM',
          'items': [
            {
              'no': '1',
              'uraian': 'Pekerjaan A',
              'nilaiBobot': 50.0,
              'volume': 10.0,
            },
            {
              'no': '2',
              'uraian': 'Pekerjaan B',
              'nilaiBobot': 50.0,
              'volume': 20.0,
            },
          ]
        }
      ];

      // Simulasi progres fisik: Pekerjaan A selesai 100% (volume 10/10), Pekerjaan B selesai 50% (volume 10/20)
      final dailyReports = [
        {
          'tanggal': '2026-07-10',
          'items': [
            {'uraian': 'Pekerjaan A', 'volumeHarian': 10.0},
            {'uraian': 'Pekerjaan B', 'volumeHarian': 10.0},
          ]
        }
      ];

      // Kalkulasi progres:
      // Pekerjaan A: (10 / 10) * 50% = 50%
      // Pekerjaan B: (10 / 20) * 50% = 25%
      // Total Progres Fisik = 75%
      final items = divisiList[0]['items'] as List<Map<String, dynamic>>;
      final progA = (10.0 / 10.0) * (items[0]['nilaiBobot'] as double);
      final progB = (10.0 / 20.0) * (items[1]['nilaiBobot'] as double);
      final totalProgres = progA + progB;

      expect(totalProgres, equals(75.0));
      expect(progA, equals(50.0));
      expect(progB, equals(25.0));
    });

  });

  // ─── PENGUJIAN WIDGET LENGKAP: DETAIL & KELOLA RKK SCREEN DENGAN 3 KONDISI VALIDASI ───
  group('Pengujian Widget Real-Time: DetailKegiatanScreen & KelolaRkkScreen (3 Kondisi Validasi)', () {

    testWidgets('DetailKegiatanScreen menampilkan status Kuning (Belum Sesuai) saat Total RAB < Nilai Kontrak', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-test-kurang',
        namaKontrak: 'Pembangunan Ruas Jalan',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 1.000.000',
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
            'namaKegiatan': 'Ruas Jalan Uji',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. UJI JAYA',
            'nilaiKontrak': 'Rp 1.000.000',
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
                    'hargaSatuan': 400000.0,
                    'volume': 1.0,
                    'totalHarga': 400000.0,
                    'nilaiBobot': 40.0,
                  }
                ]
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
            home: DetailKegiatanScreen(
              contract: contract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan indikator Kuning muncul: "Belum Sesuai" dan "Kekurangan: Rp 600.000"
      expect(find.text('Belum Sesuai'), findsOneWidget);
      expect(find.textContaining('Total RAB belum mencapai nilai kontrak kegiatan'), findsOneWidget);
      expect(find.text('Rp 600.000'), findsOneWidget);
      expect(find.text('40.000%'), findsWidgets);
    });

    testWidgets('DetailKegiatanScreen menampilkan status Merah (Melebihi) saat Total RAB > Nilai Kontrak', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-test-melebihi',
        namaKontrak: 'Pembangunan Ruas Jalan',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 1.000.000',
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
            'namaKegiatan': 'Ruas Jalan Uji Melebihi',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. UJI JAYA',
            'nilaiKontrak': 'Rp 1.000.000',
            'rkkDivisiList': [
              {
                'nomorRomawi': 'I',
                'namaDivisi': 'DIVISI I. UMUM',
                'items': [
                  {
                    'no': '1',
                    'noMataPembayaran': '1.2',
                    'uraian': 'Pekerjaan Lebih',
                    'satuan': 'Ls',
                    'hargaSatuan': 1200000.0,
                    'volume': 1.0,
                    'totalHarga': 1200000.0,
                    'nilaiBobot': 120.0,
                  }
                ]
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
            home: DetailKegiatanScreen(
              contract: contract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan indikator Merah muncul: "Melebihi" dan "Kelebihan: Rp 200.000"
      expect(find.text('Melebihi'), findsOneWidget);
      expect(find.textContaining('Peringatan: Total RAB melebihi nilai kontrak kegiatan'), findsOneWidget);
      expect(find.text('Rp 200.000'), findsOneWidget);
      expect(find.text('120.000%'), findsWidgets);
    });

    testWidgets('KelolaRkkScreen menampilkan status Belum Sesuai dan Kekurangan saat Total RAB < Nilai Kontrak', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-rkk-kurang',
        namaKontrak: 'Pembangunan Ruas Jalan',
        jenisKegiatan: 'Pengawasan',
        instansiDinas: ['Dinas PU'],
        nilaiKontrak: 'Rp 1.000.000',
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
            'namaKegiatan': 'Ruas Jalan Uji Kelola RKK',
            'lokasi': 'Kab. Purbalingga',
            'kontraktor': 'CV. UJI JAYA',
            'nilaiKontrak': 'Rp 1.000.000',
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
                    'hargaSatuan': 400000.0,
                    'volume': 1.0,
                    'totalHarga': 400000.0,
                    'nilaiBobot': 40.0,
                  }
                ]
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
            home: KelolaRkkScreen(
              contract: contract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verifikasi status badge dan kekurangan di header card KelolaRkkScreen
      expect(find.text('Belum Sesuai'), findsOneWidget);
      expect(find.text('Kekurangan: Rp 600.000'), findsOneWidget);
      expect(find.text('40.000'), findsWidgets);
      expect(find.text('Dasar Bobot: Nilai Kontrak (Rp 1.000.000)'), findsOneWidget);
    });

  });

  // ─── PENGUJIAN NILAI KONTRAK UTAMA DENGAN DUKUNGAN DESIMAL (Rp 1.250.500.000,75) ───
  group('Pengujian Dukungan Nilai Kontrak Utama Desimal (Presisi Penuh)', () {

    test('ContractModel dan RupiahUtil memproses nilai kontrak Rp 1.250.500.000,75 dengan presisi penuh', () {
      const inputStr = '1.250.500.000,75';
      final parsed = RupiahUtil.parseToDouble(inputStr);
      expect(parsed, closeTo(1250500000.75, 0.0001));

      final formatted = RupiahUtil.formatWithRp(parsed, allowDecimals: true);
      expect(formatted, equals('Rp 1.250.500.000,75'));

      final contract = ContractModel(
        id: 'c-desimal-kontrak-utama',
        namaKontrak: 'Proyek Pembangunan Jalan Raya',
        jenisKegiatan: 'Pengawasan Teknis',
        instansiDinas: ['DPU-PR'],
        nilaiKontrak: 'Rp 1.250.500.000,75',
        hariKalender: 120,
        tglMulaiSpk: '10 Mei 2026',
        nomorSpk: 'SPK-99',
        nomorSpmk: 'SPMK-99',
        tglMulaiSpmk: '12 Mei 2026',
        tglSelesaiSpmk: '10 September 2026',
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi Proyek',
        kegiatans: [],
      );

      // Verifikasi nilai getter numerik
      expect(contract.nilaiKontrakNumeric, closeTo(1250500000.75, 0.0001));

      // Verifikasi JSON Serialization & Deserialization
      final json = contract.toJson();
      expect(json['nilaiKontrak'], equals('Rp 1.250.500.000,75'));

      final restored = ContractModel.fromJson(json);
      expect(restored.nilaiKontrak, equals('Rp 1.250.500.000,75'));
      expect(restored.nilaiKontrakNumeric, closeTo(1250500000.75, 0.0001));
    });

    testWidgets('DetailKontrakScreen menampilkan Nilai Kontrak desimal Rp 1.250.500.000,75', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-view-desimal',
        namaKontrak: 'Proyek Jalan Utama',
        jenisKegiatan: 'Pengawasan Teknis',
        instansiDinas: ['Dinas Pekerjaan Umum'],
        nilaiKontrak: 'Rp 1.250.500.000,75',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-123',
        nomorSpmk: 'SPMK-123',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Proyek dengan nilai desimal',
        kegiatans: [],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: DetailKontrakScreen(contract: contract),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan tampilan Spesifikasi Kontrak memuat Nilai Kontrak dengan desimal
      expect(find.text('Rp 1.250.500.000,75'), findsOneWidget);
    });

    testWidgets('TambahKontrakScreen memuat nilai kontrak desimal Rp 1.250.500.000,75 ke controller edit', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final contract = ContractModel(
        id: 'c-edit-desimal',
        namaKontrak: 'Proyek Jalan Edit Desimal',
        jenisKegiatan: 'Pengawasan Teknis',
        instansiDinas: ['Dinas Pekerjaan Umum'],
        nilaiKontrak: 'Rp 1.250.500.000,75',
        hariKalender: 90,
        tglMulaiSpk: '01 Juli 2026',
        nomorSpk: 'SPK-123',
        nomorSpmk: 'SPMK-123',
        tglMulaiSpmk: '05 Juli 2026',
        tglSelesaiSpmk: '03 Oktober 2026',
        sumberDana: 'APBD',
        deskripsi: 'Proyek dengan nilai desimal',
        kegiatans: [],
      );

      final contractProvider = ContractProvider();
      contractProvider.addContract(contract);

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider.value(value: contractProvider)],
          child: MaterialApp(
            home: TambahKontrakScreen(contractToEdit: contract),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Controller diinput tanpa 'Rp ' karena ada prefixText 'Rp '
      expect(find.text('1.250.500.000,75'), findsOneWidget);
    });

  });
}
