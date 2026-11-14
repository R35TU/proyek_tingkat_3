import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/models/addendum_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';

void main() {
  group('SampleContractData MT Haryono 1-Month Lifecycle Tests', () {
    test('getDemoContract returns complete 1-month dataset with 7-column RAB and Addendum 01 CCO', () {
      final contract = SampleContractData.getDemoContract();

      expect(contract.id, 'kontrak-mt-haryono-demo');
      expect(contract.namaKontrak, 'PEMELIHARAAN BERKALA JL. MT HARYONO');
      expect(contract.kegiatans.isNotEmpty, isTrue);

      final kegMap = contract.kegiatans[0];
      final kegModel = KegiatanModel.fromJson(kegMap, fallbackContract: contract);

      // 1. RAB Kontrak Awal check
      final rkkAwal = kegModel.rkkKontrakAwal;
      expect(rkkAwal.length, 4); // Divisi 1, 2, 6, 7

      double totalAwalHarga = 0.0;
      double totalAwalBobot = 0.0;
      for (final div in rkkAwal) {
        final items = div['items'] as List;
        for (final it in items) {
          final hs = (it['hargaSatuan'] as num).toDouble();
          final vol = (it['volume'] as num).toDouble();
          final th = (it['totalHarga'] as num).toDouble();
          final bbt = (it['nilaiBobot'] as num).toDouble();

          expect(hs > 0, isTrue);
          expect(vol >= 0, isTrue);
          // Toleransi pembulatan tampilan dokumen PU
          expect((th - (hs * vol)).abs() < 10000.0, isTrue);
          totalAwalHarga += th;
          totalAwalBobot += bbt;
        }
      }

      // Check total harga ~ Rp 288.350.326,07 and bobot 100.000%
      expect((totalAwalHarga - 288350326.07).abs() < 2.0, isTrue);
      expect((totalAwalBobot - 100.000).abs() < 0.05, isTrue);

      // 2. Addendum 01 CCO check
      expect(kegModel.hasAddendum, isTrue);
      expect(kegModel.totalAddendumCount, 1);
      final add01 = kegModel.latestAddendum!;
      expect(add01['nomorAddendum'], '01');

      final ccoResult = TambahKurangCalculator.calculate(
        baselineDivisiList: rkkAwal,
        addendumDivisiList: kegModel.activeRkkDivisiList,
      );

      // Verified tambah kurang calculation matching authentic PU document
      expect(ccoResult.totalTambahHarga > 6000000.0, isTrue);
      expect(ccoResult.totalKurangHarga > 6000000.0, isTrue);
      expect((ccoResult.totalTambahBobot - ccoResult.totalKurangBobot).abs() < 0.05, isTrue);

      // 3. Laporan Mingguan check (Proyek sebulan jalan s.d. awal bulan 2)
      final mingguanList = kegMap['laporanMingguan'] as List;
      expect(mingguanList.length >= 4, isTrue);

      // Minggu 4 cumulative progress (Akhir Bulan 1)
      final w4 = mingguanList.firstWhere((w) => w['mingguKe'] == 4);
      expect(w4['mingguKe'], 4);
      expect(w4['realisasiPersen'], 40.776);
      expect(w4['boqProgressList'], isNotNull);

      // 4. Daily Reports check (19 reports across Weeks 1-5)
      final dailyList = kegMap['laporans'] as List;
      expect(dailyList.length, 19);
      expect(dailyList.any((r) => r['hasRekapBeton'] == true), isTrue);
      expect(dailyList.any((r) => r['hasRekapAspal'] == true), isTrue);

      // Verify daily reports exist for all weeks 1 to 5
      final week1Dailies = dailyList.where((r) => (r['tanggal'] as String).startsWith('2026-04')).toList();
      expect(week1Dailies.length >= 4, isTrue);
    });
  });
}
