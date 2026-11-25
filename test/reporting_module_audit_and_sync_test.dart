import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';

void main() {
  group('Audit & Sinkronisasi Modul Pelaporan', () {
    // -------------------------------------------------------------------------
    // 1. Validasi Periode Pelaksanaan & Kasus 1 (Blokir Tanggal di Luar Kontrak)
    // -------------------------------------------------------------------------
    test('1. Validasi Periode: Menghitung rentang tanggal SPMK & memblokir tanggal di luar kontrak (Kasus 1)', () {
      final tglSpmkStr = '20 April 2026';
      final jangkaWaktuStr = '90 (Sembilan Puluh) hari kalender';
      final matchDays = RegExp(r'\d+').firstMatch(jangkaWaktuStr);
      final days = matchDays != null ? int.parse(matchDays.group(0)!) : 90;

      final startDt = WeeklyReportModel.parseIndonesianDate(tglSpmkStr);
      expect(startDt, isNotNull);
      expect(startDt!.year, 2026);
      expect(startDt.month, 4);
      expect(startDt.day, 20);

      final endDt = startDt.add(Duration(days: days - 1));
      expect(endDt.year, 2026);
      expect(endDt.month, 7);
      expect(endDt.day, 18); // 90 hari kalender dari 20 April 2026 = 18 Juli 2026

      // Pengujian Kasus 1: Tanggal 24 November 2026 harus DITOLAK
      final kasus1Date = DateTime(2026, 11, 24);
      final isKasus1AfterEnd = kasus1Date.isAfter(endDt);
      expect(isKasus1AfterEnd, isTrue, reason: 'Tanggal 24 November 2026 harus ditolak karena setelah akhir kontrak');

      // Tanggal sebelum mulai SPMK (misal 10 April 2026) harus DITOLAK
      final earlyDate = DateTime(2026, 4, 10);
      final isEarlyBeforeStart = earlyDate.isBefore(startDt);
      expect(isEarlyBeforeStart, isTrue, reason: 'Tanggal sebelum SPMK harus ditolak');

      // Tanggal dalam rentang (misal 22 April 2026 & 23 April 2026) harus DITERIMA
      final validDate1 = DateTime(2026, 4, 22);
      final validDate2 = DateTime(2026, 4, 23);
      expect(!validDate1.isBefore(startDt) && !validDate1.isAfter(endDt), isTrue);
      expect(!validDate2.isBefore(startDt) && !validDate2.isAfter(endDt), isTrue);
    });

    // -------------------------------------------------------------------------
    // 2. Format Tanggal & Sinkronisasi Data Laporan (Kasus 2)
    // -------------------------------------------------------------------------
    test('2. Sinkronisasi Data Laporan: Pencocokan format tanggal ISO dan Indonesia tanpa mismatch', () {
      bool matchDate(dynamic repTgl, DateTime selectedDate) {
        if (repTgl == null) return false;
        final s = repTgl.toString().trim();
        if (s.isEmpty) return false;

        DateTime? repDt = DateTime.tryParse(s) ?? WeeklyReportModel.parseIndonesianDate(s);
        if (repDt == null) {
          final parts = s.split('T').first.split('-');
          if (parts.length == 3) {
            final y = int.tryParse(parts[0]);
            final m = int.tryParse(parts[1]);
            final d = int.tryParse(parts[2]);
            if (y != null && m != null && d != null) {
              repDt = DateTime(y, m, d);
            }
          }
        }

        if (repDt == null) return false;
        return repDt.year == selectedDate.year &&
            repDt.month == selectedDate.month &&
            repDt.day == selectedDate.day;
      }

      final selDate = DateTime(2026, 4, 22);

      // Tanggal tersimpan format Indonesia: '22 April 2026'
      expect(matchDate('22 April 2026', selDate), isTrue);
      // Tanggal tersimpan format ISO: '2026-04-22'
      expect(matchDate('2026-04-22', selDate), isTrue);
      // Tanggal tersimpan format ISO timestamp: '2026-04-22T08:30:00.000'
      expect(matchDate('2026-04-22T08:30:00.000', selDate), isTrue);

      // Tanggal berbeda: '23 April 2026'
      expect(matchDate('23 April 2026', selDate), isFalse);
    });

    // -------------------------------------------------------------------------
    // 3. Rekapitulasi BOQ & Agregasi Realisasi dari Laporan Harian (Kasus 3)
    // -------------------------------------------------------------------------
    test('3. Rekapitulasi BOQ: Agregasi presisi penuh dari Laporan Harian 23 April 2026 (Kasus 3)', () {
      final nilaiKontrakKegiatan = 288350326.79;
      final hargaSatuanAspal = 25958.0;
      final volumeKontrakAspal = 118.79;
      final totalHargaAspal = volumeKontrakAspal * hargaSatuanAspal;
      final bobotKontrakAspal = (totalHargaAspal / nilaiKontrakKegiatan) * 100.0;

      final kegMap = {
        'id': 'keg-ruas-a',
        'namaKegiatan': 'Ruas Jalan A',
        'nilaiKontrak': '288.350.326,79',
        'rkkDivisiList': [
          {
            'nomorRomawi': 'VI',
            'judul': 'PERKERASAN ASPAL',
            'items': [
              {
                'noMataPembayaran': '6.1 (1)(a)',
                'uraian': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
                'satuan': 'liter',
                'hargaSatuan': hargaSatuanAspal,
                'volume': volumeKontrakAspal,
                'nilaiBobot': bobotKontrakAspal,
                'totalHarga': totalHargaAspal,
              }
            ]
          }
        ],
        'laporans': [
          {
            'id': 'rep-2026-04-23',
            'tanggal': '23 April 2026',
            'kegiatanId': 'keg-ruas-a',
            'pekerjaanList': [
              {
                'noMataPembayaran': '6.1 (1)(a)',
                'jenis': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
                'uraian': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
                'volume': '50 liter',
                'satuan': 'liter',
              }
            ]
          }
        ]
      };

      // Minggu 1: 20 April 2026 s/d 25 April 2026
      final weekStart = DateTime(2026, 4, 20);
      final weekEnd = DateTime(2026, 4, 25);

      final boqResult = ProgressCalculator.calculateBoqProgress(
        kegMap: kegMap,
        startDt: weekStart,
        endDt: weekEnd,
      );

      expect(boqResult.divisions, isNotEmpty);
      final divVI = boqResult.divisions.first;
      final itemAspal = (divVI['items'] as List).first as Map<String, dynamic>;

      // Verifikasi volume
      expect(itemAspal['mingguLaluVolume'], 0.0);
      expect(itemAspal['mingguIniVolume'], 50.0);
      expect(itemAspal['sdMingguIniVolume'], 50.0);
      expect((itemAspal['sisaVolume'] as double).toStringAsFixed(2), '68.79');

      // Verifikasi bobot periode ini
      final expectedBobotIni = (50.0 / volumeKontrakAspal) * bobotKontrakAspal;
      expect(itemAspal['mingguIniBobot'], closeTo(expectedBobotIni, 0.0001));
      expect(itemAspal['sdMingguIniBobot'], closeTo(expectedBobotIni, 0.0001));
      expect(boqResult.totalBobotPeriodeIni, closeTo(expectedBobotIni, 0.0001));
      expect(boqResult.totalBobotSdPeriodeIni, closeTo(expectedBobotIni, 0.0001));

      // Verifikasi bahwa sisa bobot adalah bobot kontrak - sdMingguIni
      expect(itemAspal['sisaBobot'], closeTo(bobotKontrakAspal - expectedBobotIni, 0.0001));
    });

    // -------------------------------------------------------------------------
    // 4. Sinkronisasi Realisasi Laporan Bulanan dari Laporan Harian
    // -------------------------------------------------------------------------
    test('4. Realisasi Bulanan: Otomatis mengakumulasi volume dan bobot Laporan Harian', () {
      final contract = ContractModel(
        id: 'c-1',
        jenisKegiatan: 'Pengawasan',
        namaKontrak: 'Pengawasan Jalan Sidodadi',
        nomorSpk: '000.3.2/SPK/2026',
        nomorSpmk: '000.3.2/SPMK/2026',
        tglMulaiSpk: '20 April 2026',
        tglMulaiSpmk: '20 April 2026',
        tglSelesaiSpmk: '18 Juli 2026',
        hariKalender: 90,
        nilaiKontrak: '288.350.326,79',
        instansiDinas: ['DPU-PR Kab. Purbalingga'],
        sumberDana: 'APBD',
        deskripsi: 'Deskripsi',
        progressFisik: 0.0,
      );

      final kegMap = {
        'id': 'keg-1',
        'namaKegiatan': 'Ruas Jalan A',
        'nilaiKontrak': '288.350.326,79',
        'tglSpmkKontraktor': '20 April 2026',
        'jangkaWaktu': '90 hari kalender',
        'rkkDivisiList': [
          {
            'nomorRomawi': 'VI',
            'judul': 'PERKERASAN ASPAL',
            'items': [
              {
                'noMataPembayaran': '6.1 (1)(a)',
                'uraian': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
                'satuan': 'liter',
                'hargaSatuan': 25958.0,
                'volume': 118.79,
                'nilaiBobot': 1.06937,
                'totalHarga': 3083550.82,
              }
            ]
          }
        ],
        'laporans': [
          {
            'id': 'rep-1',
            'tanggal': '23 April 2026',
            'pekerjaanList': [
              {
                'noMataPembayaran': '6.1 (1)(a)',
                'jenis': 'Lapis Resap Pengikat - Aspal Cair/Emulsi',
                'volume': '50 liter',
              }
            ]
          }
        ],
        'laporanMingguan': [] // Belum ada laporan mingguan tersimpan
      };

      final monthlyList = MonthlyReportModel.generateFromWeeklyReports(
        contract: contract,
        kegiatan: kegMap,
      );

      expect(monthlyList, isNotEmpty);
      final bulan1 = monthlyList.first;
      // Bulan 1 harus otomatis memiliki realisasi dari Laporan Harian
      expect(bulan1.realisasiKumulatifPersen, greaterThan(0.0));
      expect(bulan1.divisions, isNotEmpty);

      final divVI = bulan1.divisions.first;
      final item = divVI.items.first;
      expect(item.volumeSdBulanIni, 50.0);
      expect(item.bobotSdBulanIni, greaterThan(0.0));
    });

    // -------------------------------------------------------------------------
    // 5. Pembersihan Hardcoded Signature Fallbacks
    // -------------------------------------------------------------------------
    test('5. Tanda Tangan: Tidak ada nama pejabat atau rekanan yang di-hardcode jika data kosong', () {
      final kegKosong = KegiatanModel(namaKegiatan: 'Kegiatan Baru');
      // Jika penggunaAnggaran kosong, tidak boleh fallback ke 'DRAJAT UJI WAKHYONO'
      expect(kegKosong.penggunaAnggaran, isEmpty);
      // Jika konsultanPengawas tidak diisi, tidak boleh fallback hardcoded
      expect(kegKosong.konsultanPengawas, isEmpty);

      // WeeklyReportModel tanpa ttd
      final emptyWeekly = WeeklyReportModel(
        id: 'w-1',
        pekerjaan: 'Pekerjaan',
        lokasiProyek: 'Lokasi',
        kontraktor: '',
        jangkaWaktu: 90,
        totalMinggu: 13,
        tabelMingguan: [],
        nomorKontrak: '',
        tanggalKontrak: '',
        nilaiKontrak: '0',
        nilaiKontrakNumeric: 0.0,
        tanggalSpmk: '',
        mingguKe: 1,
        periodeAwal: '20 April 2026',
        periodeAkhir: '25 April 2026',
        waktuTerpakai: 7,
        sisaWaktu: 83,
        akhirMasaKontrak: '18 Juli 2026',
        rencanaPersen: 0,
        rencanaNominal: 0,
        realisasiPersen: 0,
        realisasiNominal: 0,
        deviasiPersen: 0,
        deviasiNominal: 0,
        ttdKontraktorNama: null,
        ttdKonsultanNama: null,
        ttdPpkNama: null,
      );

      expect(emptyWeekly.ttdKontraktorNama, isNull);
      expect(emptyWeekly.ttdKonsultanNama, isNull);
      expect(emptyWeekly.ttdPpkNama, isNull);
    });
  });
}
