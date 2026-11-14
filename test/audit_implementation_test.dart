import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';

void main() {
  group('Audit Implementation & Clarification Validation Tests', () {
    test('1. Progres Fisik Harian Real-Time mengalkulasi seluruh Laporan Harian terhadap active RKK', () {
      final rkkDivisiList = [
        {
          'nomorRomawi': 'II',
          'namaDivisi': 'DIVISI 2. DRAINASE',
          'items': [
            {
              'id': 'it-1',
              'no': '1',
              'noMataPembayaran': '2.3.(12)',
              'uraian': 'Gorong-gorong Kotak 50x50cm',
              'satuan': 'm1',
              'hargaSatuan': 2139059.32,
              'volume': 4.8,
              'volumeCCO': 4.8,
              'totalHarga': 10267484.74,
              'nilaiBobot': 100.0,
            }
          ]
        }
      ];

      final kegMap = <String, dynamic>{
        'namaKegiatan': 'Ruas Jalan A',
        'nilaiKontrak': 'Rp 10.267.484,74',
        'rkkDivisiList': rkkDivisiList,
        'rkkKontrakAwal': rkkDivisiList,
        'addendums': [],
        'laporans': [
          {
            'nomor': '01',
            'tanggal': 'Senin, 20 April 2026',
            'pekerjaanList': [
              {
                'rkkItemId': 'it-1',
                'noMataPembayaran': '2.3.(12)',
                'jenisPekerjaan': 'Gorong-gorong Kotak 50x50cm',
                'volume': '2.4',
              }
            ]
          },
          {
            'nomor': '02',
            'tanggal': 'Selasa, 21 April 2026',
            'pekerjaanList': [
              {
                'rkkItemId': 'it-1',
                'noMataPembayaran': '2.3.(12)',
                'jenisPekerjaan': 'Gorong-gorong Kotak 50x50cm',
                'volume': '1.2',
              }
            ]
          },
        ],
        'laporanMingguan': [],
      };

      final keg = KegiatanModel.fromJson(kegMap);

      // Hitung realisasi harian kumulatif
      double totalRealisasiBobot = 0.0;
      final activeRkk = keg.activeRkkDivisiList;
      for (final rep in keg.laporans) {
        final pList = (rep['pekerjaanList'] as List? ?? []);
        for (final p in pList) {
          final vol = double.tryParse((p['volume'] ?? '0').toString()) ?? 0.0;
          final itId = (p['rkkItemId'] ?? '').toString();
          for (final div in activeRkk) {
            for (final it in (div['items'] as List)) {
              if (it['id'] == itId) {
                final targetVol = (it['volumeCCO'] ?? it['volume'] as num?)?.toDouble() ?? 0.0;
                final bobotItem = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
                if (targetVol > 0) {
                  totalRealisasiBobot += (vol / targetVol) * bobotItem;
                }
              }
            }
          }
        }
      }

      // Total terpasang = 2.4 + 1.2 = 3.6 dari 4.8 m1 -> 75%
      expect(totalRealisasiBobot, closeTo(75.0, 0.01));
    });

    test('2. Snapshot BoQ 8-kolom dan fallback Laporan Bulanan bekerja secara dinamis', () {
      final contract = ContractModel(
        id: 'c-1',
        jenisKegiatan: 'Pengawasan',
        namaKontrak: 'Paket Pemeliharaan',
        nomorSpk: '001/SPK/2026',
        tglMulaiSpk: '20 April 2026',
        nomorSpmk: '001/SPMK/2026',
        tglMulaiSpmk: '20 April 2026',
        tglSelesaiSpmk: '20 Juli 2026',
        nilaiKontrak: 'Rp 10.267.484,74',
        instansiDinas: ['DPU-PR'],
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        hariKalender: 90,
      );

      final rkkDivisiList = [
        {
          'nomorRomawi': 'II',
          'namaDivisi': 'DIVISI 2. DRAINASE',
          'items': [
            {
              'id': 'it-1',
              'no': '1',
              'noMataPembayaran': '2.3.(12)',
              'uraian': 'Gorong-gorong Kotak 50x50cm',
              'satuan': 'm1',
              'hargaSatuan': 2139059.32,
              'volume': 4.8,
              'volumeCCO': 4.8,
              'totalHarga': 10267484.74,
              'nilaiBobot': 100.0,
            }
          ]
        }
      ];

      final kegMap = <String, dynamic>{
        'namaKegiatan': 'Ruas Jalan A',
        'nilaiKontrak': 'Rp 10.267.484,74',
        'rkkDivisiList': rkkDivisiList,
        'rkkKontrakAwal': rkkDivisiList,
        'addendums': [],
        'laporans': [
          {
            'nomor': '01',
            'tanggal': 'Senin, 20 April 2026',
            'pekerjaanList': [
              {
                'rkkItemId': 'it-1',
                'noMataPembayaran': '2.3.(12)',
                'uraian': 'Gorong-gorong Kotak 50x50cm',
                'volume': '2.4',
              }
            ]
          }
        ],
        'laporanMingguan': [
          {
            'nomorMinggu': '1',
            'periode': '20 April 2026 - 26 April 2026',
            'rencanaPersen': 25.0,
            'realisasiPersen': 50.0,
            'deviasiPersen': 25.0,
            // boqProgressList kosong untuk menguji fallback dinamis
            'boqProgressList': [],
          }
        ],
      };

      final monthlyReports = MonthlyReportModel.generateFromWeeklyReports(
        contract: contract,
        kegiatan: kegMap,
      );

      expect(monthlyReports.isNotEmpty, isTrue);
      final m1 = monthlyReports.first;
      expect(m1.bulanKe, 1);
      expect(m1.divisions.isNotEmpty, isTrue);
      final item = m1.divisions.first.items.first;
      // Volume terpasang 2.4 otomatis terdeteksi via dynamic fallback
      expect(item.volumeSdBulanIni, 2.4);
      expect(item.sisaVolume, closeTo(2.4, 0.01));
    });

    test('3. Master RAB Kontrak Awal tetap utuh setelah terbit Addendum CCO 01', () {
      final initialRkk = [
        {
          'nomorRomawi': 'II',
          'namaDivisi': 'DIVISI 2. DRAINASE',
          'items': [
            {
              'id': 'it-1',
              'no': '1',
              'noMataPembayaran': '2.3.(12)',
              'uraian': 'Gorong-gorong Kotak 50x50cm',
              'satuan': 'm1',
              'hargaSatuan': 2000000.0,
              'volume': 4.0,
              'volumeCCO': 4.0,
              'totalHarga': 8000000.0,
              'nilaiBobot': 100.0,
            }
          ]
        }
      ];

      final cco01Rkk = [
        {
          'nomorRomawi': 'II',
          'namaDivisi': 'DIVISI 2. DRAINASE',
          'items': [
            {
              'id': 'it-1',
              'no': '1',
              'noMataPembayaran': '2.3.(12)',
              'uraian': 'Gorong-gorong Kotak 50x50cm',
              'satuan': 'm1',
              'hargaSatuan': 2000000.0,
              'volume': 4.8,
              'volumeCCO': 4.8,
              'totalHarga': 9600000.0,
              'nilaiBobot': 100.0,
            }
          ]
        }
      ];

      final kegMap = <String, dynamic>{
        'namaKegiatan': 'Ruas Jalan A',
        'nilaiKontrak': 'Rp 9.600.000,00',
        'rkkDivisiList': cco01Rkk, // Operasional aktif mengacu ke CCO 01
        'rkkKontrakAwal': initialRkk, // Master RAB awal tetap 4.0 m1
        'addendums': [
          {
            'id': 'add-01',
            'nomorAddendum': '01',
            'judul': 'Daftar Perhitungan Tambah Kurang Ke - 01',
            'rkkDivisiList': cco01Rkk,
          }
        ],
      };

      final keg = KegiatanModel.fromJson(kegMap);

      expect(keg.hasAddendum, isTrue);
      expect(keg.rkkKontrakAwal.first['items'][0]['volume'], 4.0);
      expect(keg.activeRkkDivisiList.first['items'][0]['volumeCCO'], 4.8);
    });
  });
}
