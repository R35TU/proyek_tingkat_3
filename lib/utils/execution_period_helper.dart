import 'dart:math';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/utils/indonesian_terbilang.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';

/// Hasil resolusi periode pelaksanaan otoritatif (Single Source of Truth)
/// untuk satu kegiatan, digunakan seragam oleh Laporan Harian, Mingguan, dan Bulanan.
class ExecutionPeriod {
  final DateTime? startDate;
  final DateTime? endDate;
  final int durationDays;
  final int totalWeeks;

  const ExecutionPeriod({
    this.startDate,
    this.endDate,
    required this.durationDays,
    required this.totalWeeks,
  });

  String get startFormatted =>
      startDate != null ? WeeklyReportModel.formatIndonesianDate(startDate!) : '';

  String get endFormatted =>
      endDate != null ? WeeklyReportModel.formatIndonesianDate(endDate!) : '';
}

/// Rentang tanggal kalender murni untuk 1 minggu pelaksanaan.
class WeekDateRange {
  final int weekNum;
  final int startDayIndex; // 1-based
  final int endDayIndex; // 1-based
  final int daysCount;
  final DateTime? startDt;
  final DateTime? endDt;
  final String tglMulaiSlash; // dd/MM/yyyy
  final String tglSelesaiSlash; // dd/MM/yyyy
  final String tglMulaiIndo; // d MMMM yyyy
  final String tglSelesaiIndo; // d MMMM yyyy
  final int elapsedDays;
  final int remainingDays;

  const WeekDateRange({
    required this.weekNum,
    required this.startDayIndex,
    required this.endDayIndex,
    required this.daysCount,
    this.startDt,
    this.endDt,
    required this.tglMulaiSlash,
    required this.tglSelesaiSlash,
    required this.tglMulaiIndo,
    required this.tglSelesaiIndo,
    required this.elapsedDays,
    required this.remainingDays,
  });
}

enum WeeklyPeriodStatus {
  onProgress,
  completed,
  upcoming,
}

/// Representasi ringkasan satu periode minggu pada daftar Laporan Mingguan.
class WeeklyPeriodSummary {
  final int mingguKe;
  final int totalMinggu;
  final DateTime? startDate;
  final DateTime? endDate;
  final String periodeAwal;
  final String periodeAkhir;
  final String periodeFormatted;
  final int daysCount;
  final int waktuTerpakai;
  final int sisaWaktu;
  final String akhirMasaKontrak;

  final WeeklyPeriodStatus status;
  final String statusLabel;
  final String statusDetail;

  final double rencanaPersen;
  final double realisasiMingguIniPersen;
  final double realisasiSdMingguIniPersen;
  final double deviasiPersen;
  final double nilaiKontrakNumeric;

  final bool hasSavedReport;
  final bool hasDailyReportsInWeek;
  final WeeklyReportModel? savedReport;
  final BoqAggregationResult boqResult;

  const WeeklyPeriodSummary({
    required this.mingguKe,
    required this.totalMinggu,
    this.startDate,
    this.endDate,
    required this.periodeAwal,
    required this.periodeAkhir,
    required this.periodeFormatted,
    required this.daysCount,
    required this.waktuTerpakai,
    required this.sisaWaktu,
    required this.akhirMasaKontrak,
    required this.status,
    required this.statusLabel,
    required this.statusDetail,
    required this.rencanaPersen,
    required this.realisasiMingguIniPersen,
    required this.realisasiSdMingguIniPersen,
    required this.deviasiPersen,
    required this.nilaiKontrakNumeric,
    required this.hasSavedReport,
    required this.hasDailyReportsInWeek,
    this.savedReport,
    required this.boqResult,
  });

  double get rencanaNominal => (rencanaPersen / 100.0) * nilaiKontrakNumeric;
  double get realisasiNominal =>
      (realisasiSdMingguIniPersen / 100.0) * nilaiKontrakNumeric;
  double get deviasiNominal => realisasiNominal - rencanaNominal;
}

/// Analisis dampak perubahan tanggal kontrak terhadap kegiatan dan laporan historis.
class ContractDateSyncAnalysis {
  final bool datesChanged;
  final int totalKegiatans;
  final int dailyReportsOutsideCount;
  final int weeklyReportsOutsideCount;
  final String oldPeriodLabel;
  final String newPeriodLabel;

  const ContractDateSyncAnalysis({
    required this.datesChanged,
    required this.totalKegiatans,
    required this.dailyReportsOutsideCount,
    required this.weeklyReportsOutsideCount,
    required this.oldPeriodLabel,
    required this.newPeriodLabel,
  });

  bool get hasHistoricalReportsOutside =>
      dailyReportsOutsideCount > 0 || weeklyReportsOutsideCount > 0;
}

/// Utility terpusat sebagai Single Source of Truth untuk perhitungan periode
/// pelaksanaan, sinkronisasi tanggal kontrak -> kegiatan, dan generator daftar
/// periode mingguan secara dinamis.
class ExecutionPeriodHelper {
  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _parseDate(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    final dt = DateTime.tryParse(s) ?? WeeklyReportModel.parseIndonesianDate(s);
    return dt != null ? _dayOnly(dt) : null;
  }

  static int? _extractDays(dynamic raw) {
    final s = raw?.toString().trim() ?? '';
    if (s.isEmpty) return null;
    final m = RegExp(r'\d+').firstMatch(s);
    if (m == null) return null;
    final v = int.tryParse(m.group(0)!);
    return (v != null && v > 0) ? v : null;
  }

  /// Menyelesaikan periode pelaksanaan efektif sebuah kegiatan (atau kontrak).
  /// Memastikan Laporan Harian, Mingguan, dan Bulanan selalu menggunakan sumber
  /// tanggal mulai, jangka waktu, dan tanggal akhir yang konsisten.
  static ExecutionPeriod resolveExecutionPeriod(
    Map<String, dynamic>? kegMap, {
    ContractModel? contract,
  }) {
    final cStartDt = _parseDate(contract?.tglMulaiSpmk);
    final cEndDt = _parseDate(contract?.tglSelesaiSpmk);
    final cDays = (contract != null && contract.hariKalender > 0)
        ? contract.hariKalender
        : null;

    if (kegMap == null) {
      int days = cDays ?? 0;
      DateTime? endDt = cEndDt;
      if (days <= 0 && cStartDt != null && endDt != null && !endDt.isBefore(cStartDt)) {
        days = endDt.difference(cStartDt).inDays + 1;
      }
      if (days <= 0) days = 90;
      if (cStartDt != null && (endDt == null || endDt.isBefore(cStartDt))) {
        endDt = DateTime(cStartDt.year, cStartDt.month, cStartDt.day + days - 1);
      }
      final totalWeeks = days > 0 ? (days / 7.0).ceil() : 1;
      return ExecutionPeriod(
        startDate: cStartDt,
        endDate: endDt,
        durationDays: days,
        totalWeeks: max(1, totalWeeks),
      );
    }

    final spmkKontraktorDt = _parseDate(kegMap['tglSpmkKontraktor']);
    final awalPelaksanaanDt = _parseDate(kegMap['awalPelaksanaan']);
    final spmkKonsultanDt = _parseDate(kegMap['tglSpmkKonsultan']);

    // Jika keduanya ada dan berbeda namun salah satunya cocok dengan tanggal
    // kontrak terbaru, utamakan yang selaras agar perubahan sebelumnya tidak tertahan.
    DateTime? startDt;
    if (spmkKontraktorDt != null &&
        awalPelaksanaanDt != null &&
        spmkKontraktorDt != awalPelaksanaanDt) {
      if (cStartDt != null && awalPelaksanaanDt == cStartDt) {
        startDt = awalPelaksanaanDt;
      } else if (cStartDt != null && spmkKontraktorDt == cStartDt) {
        startDt = spmkKontraktorDt;
      } else {
        startDt = spmkKontraktorDt;
      }
    } else {
      startDt = spmkKontraktorDt ?? awalPelaksanaanDt ?? spmkKonsultanDt ?? cStartDt;
    }

    final daysK = _extractDays(kegMap['jangkaWaktu']);
    final daysM = _extractDays(kegMap['masaPelaksanaan']);
    int? days;
    if (startDt != null &&
        startDt == awalPelaksanaanDt &&
        awalPelaksanaanDt != spmkKontraktorDt &&
        daysM != null) {
      days = daysM;
    } else {
      days = daysK ?? daysM ?? cDays;
    }

    final akhirSpmkDt = _parseDate(kegMap['tglAkhirSpmkKontraktor']);
    final akhirPelaksanaanDt = _parseDate(kegMap['akhirPelaksanaan']);
    DateTime? endCandidate;
    if (akhirSpmkDt != null &&
        akhirPelaksanaanDt != null &&
        akhirSpmkDt != akhirPelaksanaanDt) {
      if (cEndDt != null && akhirPelaksanaanDt == cEndDt) {
        endCandidate = akhirPelaksanaanDt;
      } else if (cEndDt != null && akhirSpmkDt == cEndDt) {
        endCandidate = akhirSpmkDt;
      } else {
        endCandidate = akhirSpmkDt;
      }
    } else {
      endCandidate = akhirSpmkDt ?? akhirPelaksanaanDt ?? cEndDt;
    }

    DateTime? endDt;
    if (startDt != null) {
      if (days != null && days > 0) {
        endDt = DateTime(startDt.year, startDt.month, startDt.day + days - 1);
      } else if (endCandidate != null && !endCandidate.isBefore(startDt)) {
        endDt = endCandidate;
        days = endCandidate.difference(startDt).inDays + 1;
      }
    } else {
      endDt = endCandidate;
    }

    final effectiveDays = (days != null && days > 0) ? days : 90;
    final totalWeeks = max(1, (effectiveDays / 7.0).ceil());

    return ExecutionPeriod(
      startDate: startDt,
      endDate: endDt,
      durationDays: effectiveDays,
      totalWeeks: totalWeeks,
    );
  }

  /// Menghitung rentang tanggal kalender murni untuk minggu ke-[w].
  static WeekDateRange calcWeekRange(int w, DateTime? startDt, int totalDays) {
    final safeDays = totalDays > 0 ? totalDays : 90;
    final startDay = (w - 1) * 7 + 1;
    final endDay = min(w * 7, safeDays);
    final days = max(1, endDay - startDay + 1);

    if (startDt != null) {
      final start = DateTime(startDt.year, startDt.month, startDt.day + startDay - 1);
      final end = DateTime(startDt.year, startDt.month, startDt.day + endDay - 1);
      return WeekDateRange(
        weekNum: w,
        startDayIndex: startDay,
        endDayIndex: endDay,
        daysCount: days,
        startDt: start,
        endDt: end,
        tglMulaiSlash: WeeklyReportModel.formatDateSlash(start),
        tglSelesaiSlash: WeeklyReportModel.formatDateSlash(end),
        tglMulaiIndo: WeeklyReportModel.formatIndonesianDate(start),
        tglSelesaiIndo: WeeklyReportModel.formatIndonesianDate(end),
        elapsedDays: endDay,
        remainingDays: max(0, safeDays - endDay),
      );
    }

    return WeekDateRange(
      weekNum: w,
      startDayIndex: startDay,
      endDayIndex: endDay,
      daysCount: days,
      startDt: null,
      endDt: null,
      tglMulaiSlash: '',
      tglSelesaiSlash: '',
      tglMulaiIndo: '',
      tglSelesaiIndo: '',
      elapsedDays: endDay,
      remainingDays: max(0, safeDays - endDay),
    );
  }

  /// Memeriksa apakah laporan mingguan tersimpan sesuai dengan rentang tanggal jadwal aktif.
  /// Mencegah laporan historis dari jadwal kontrak lama dianggap selesai pada jadwal baru.
  static bool doesSavedWeeklyMatchRange(
    WeeklyReportModel report,
    WeekDateRange range,
  ) {
    if (range.startDt == null) return true;
    final repStart = _parseDate(report.periodeAwal);
    if (repStart == null) return true;
    return repStart == _dayOnly(range.startDt!);
  }

  /// Format rentang tanggal ringkas untuk daftar periode mingguan.
  static String formatRangeDisplay(DateTime? start, DateTime? end, int weekNum) {
    if (start == null || end == null) {
      return 'Minggu ke-$weekNum (Menunggu Tanggal SPMK)';
    }
    final startStr = start.year == end.year
        ? '${start.day} ${WeeklyReportModel.namaBulan[start.month - 1]}'
        : WeeklyReportModel.formatIndonesianDate(start);
    final endStr = WeeklyReportModel.formatIndonesianDate(end);
    return '$startStr s/d $endStr';
  }

  /// Menghasilkan daftar lengkap periode mingguan beserta status & agregasi
  /// realisasi otomatis dari Laporan Harian.
  static List<WeeklyPeriodSummary> generateWeeklyPeriods({
    required ContractModel contract,
    required Map<String, dynamic> kegMap,
    DateTime? referenceDate,
  }) {
    final period = resolveExecutionPeriod(kegMap, contract: contract);
    final now = referenceDate ?? DateTime.now();
    final today = _dayOnly(now);

    final kegNilai = kegMap['nilaiKontrak']?.toString().trim() ?? '';
    final effectiveNilaiStr =
        kegNilai.isNotEmpty ? kegNilai : contract.nilaiKontrak;
    final nilaiNumeric = WeeklyReportModel.parseRupiah(effectiveNilaiStr);

    final rawMingguan = (kegMap['laporanMingguan'] as List?) ?? [];
    final savedReports = <WeeklyReportModel>[];
    for (final item in rawMingguan) {
      if (item is Map) {
        try {
          savedReports.add(
            WeeklyReportModel.fromJson(Map<String, dynamic>.from(item)),
          );
        } catch (_) {}
      } else if (item is WeeklyReportModel) {
        savedReports.add(item);
      }
    }

    // Kumpulkan tanggal laporan harian untuk deteksi cepat hasDailyReportsInWeek
    final dailyDates = <DateTime>[];
    final rawLaporans = (kegMap['laporans'] as List?) ?? [];
    for (final rep in rawLaporans) {
      if (rep is! Map) continue;
      final d = _parseDate(rep['tanggal']) ??
          _parseDate(rep['tanggalFormatted']) ??
          _parseDate(rep['createdAt']);
      if (d != null) dailyDates.add(d);
    }

    final List<WeeklyPeriodSummary> result = [];
    final akhirKontrakStr = period.endFormatted;

    for (int w = 1; w <= period.totalWeeks; w++) {
      final range = calcWeekRange(w, period.startDate, period.durationDays);

      // Cari laporan mingguan tersimpan yang cocok dengan minggu dan jadwal aktif
      WeeklyReportModel? matchedSaved;
      for (final r in savedReports) {
        if (r.mingguKe == w && doesSavedWeeklyMatchRange(r, range)) {
          matchedSaved = r;
          break;
        }
      }

      final hasSaved = matchedSaved != null;

      bool hasDailyInWeek = false;
      if (range.startDt != null && range.endDt != null) {
        for (final d in dailyDates) {
          if (!d.isBefore(range.startDt!) && !d.isAfter(range.endDt!)) {
            hasDailyInWeek = true;
            break;
          }
        }
      }

      // Hitung agregasi BOQ & realisasi langsung dari Laporan Harian
      final boqRes = ProgressCalculator.calculateBoqProgress(
        kegMap: kegMap,
        startDt: range.startDt,
        endDt: range.endDt,
        minStartDt: period.startDate,
      );

      final realisasiMingguIni = boqRes.totalBobotPeriodeIni;
      final realisasiSdMingguIni = boqRes.totalBobotSdPeriodeIni;
      final rencana = matchedSaved?.rencanaPersen ?? 0.0;
      final deviasi = realisasiSdMingguIni - rencana;

      // Penentuan status berdasarkan tanggal periode DAN kondisi laporan
      final WeeklyPeriodStatus status;
      final String statusLabel;
      final String statusDetail;

      if (range.startDt == null || range.endDt == null) {
        status = WeeklyPeriodStatus.upcoming;
        statusLabel = 'Upcoming';
        statusDetail = 'Periode menunggu penetapan tanggal SPMK';
      } else if (today.isBefore(range.startDt!)) {
        status = WeeklyPeriodStatus.upcoming;
        statusLabel = 'Upcoming';
        statusDetail = 'Periode belum dimulai';
      } else if (!today.isAfter(range.endDt!)) {
        status = WeeklyPeriodStatus.onProgress;
        statusLabel = 'On Progress';
        if (hasSaved) {
          statusDetail = 'Sedang berlangsung • Laporan mingguan sudah diisi';
        } else if (hasDailyInWeek) {
          statusDetail = 'Sedang berlangsung • Ada realisasi harian';
        } else {
          statusDetail = 'Sedang berlangsung';
        }
      } else {
        if (hasSaved) {
          status = WeeklyPeriodStatus.completed;
          statusLabel = 'Completed';
          statusDetail = 'Periode selesai & laporan mingguan tersimpan';
        } else {
          status = WeeklyPeriodStatus.onProgress;
          statusLabel = 'On Progress';
          statusDetail = hasDailyInWeek
              ? 'Periode berakhir • Menunggu pelengkapan rencana/pengesahan'
              : 'Periode berakhir • Belum dilengkapi';
        }
      }

      result.add(
        WeeklyPeriodSummary(
          mingguKe: w,
          totalMinggu: period.totalWeeks,
          startDate: range.startDt,
          endDate: range.endDt,
          periodeAwal: range.tglMulaiIndo,
          periodeAkhir: range.tglSelesaiIndo,
          periodeFormatted: formatRangeDisplay(range.startDt, range.endDt, w),
          daysCount: range.daysCount,
          waktuTerpakai: range.elapsedDays,
          sisaWaktu: range.remainingDays,
          akhirMasaKontrak: akhirKontrakStr,
          status: status,
          statusLabel: statusLabel,
          statusDetail: statusDetail,
          rencanaPersen: rencana,
          realisasiMingguIniPersen: realisasiMingguIni,
          realisasiSdMingguIniPersen: realisasiSdMingguIni,
          deviasiPersen: deviasi,
          nilaiKontrakNumeric: nilaiNumeric,
          hasSavedReport: hasSaved,
          hasDailyReportsInWeek: hasDailyInWeek,
          savedReport: matchedSaved,
          boqResult: boqRes,
        ),
      );
    }

    return result;
  }

  /// Menganalisis perubahan tanggal kontrak dan dampaknya terhadap kegiatan & laporan historis.
  static ContractDateSyncAnalysis analyzeContractDateChange(
    ContractModel oldContract,
    ContractModel newContract,
  ) {
    final datesChanged = oldContract.tglMulaiSpmk.trim() != newContract.tglMulaiSpmk.trim() ||
        oldContract.tglSelesaiSpmk.trim() != newContract.tglSelesaiSpmk.trim() ||
        oldContract.hariKalender != newContract.hariKalender ||
        oldContract.tglMulaiSpk.trim() != newContract.tglMulaiSpk.trim();

    final newStart = _parseDate(newContract.tglMulaiSpmk);
    final newEnd = _parseDate(newContract.tglSelesaiSpmk) ??
        (newStart != null && newContract.hariKalender > 0
            ? DateTime(newStart.year, newStart.month, newStart.day + newContract.hariKalender - 1)
            : null);

    int dailyOutside = 0;
    int weeklyOutside = 0;

    if (newStart != null && newEnd != null) {
      for (final keg in newContract.kegiatans) {
        final laporans = (keg['laporans'] as List?) ?? [];
        for (final rep in laporans) {
          if (rep is! Map) continue;
          final d = _parseDate(rep['tanggal']) ?? _parseDate(rep['tanggalFormatted']);
          if (d != null && (d.isBefore(newStart) || d.isAfter(newEnd))) {
            dailyOutside++;
          }
        }
        final mingguan = (keg['laporanMingguan'] as List?) ?? [];
        for (final w in mingguan) {
          if (w is! Map) continue;
          final ws = _parseDate(w['periodeAwal']);
          final we = _parseDate(w['periodeAkhir']);
          if ((ws != null && (ws.isBefore(newStart) || ws.isAfter(newEnd))) ||
              (we != null && (we.isBefore(newStart) || we.isAfter(newEnd)))) {
            weeklyOutside++;
          }
        }
      }
    }

    return ContractDateSyncAnalysis(
      datesChanged: datesChanged,
      totalKegiatans: newContract.kegiatans.length,
      dailyReportsOutsideCount: dailyOutside,
      weeklyReportsOutsideCount: weeklyOutside,
      oldPeriodLabel:
          '${oldContract.tglMulaiSpmk} s/d ${oldContract.tglSelesaiSpmk} (${oldContract.hariKalender} hari)',
      newPeriodLabel:
          '${newContract.tglMulaiSpmk} s/d ${newContract.tglSelesaiSpmk} (${newContract.hariKalender} hari)',
    );
  }

  /// Mensinkronkan tanggal pelaksanaan kontrak terbaru ke seluruh kegiatan di dalamnya
  /// TANPA menghapus atau merusak data laporan historis (`laporans`, `laporanMingguan`),
  /// RKK, addendum, maupun folder administrasi.
  static ContractModel syncContractDatesToKegiatans({
    required ContractModel oldContract,
    required ContractModel newContract,
    bool forceSyncAll = true,
  }) {
    final newStartSpmk = newContract.tglMulaiSpmk.trim();
    final newEndSpmk = newContract.tglSelesaiSpmk.trim().isNotEmpty
        ? newContract.tglSelesaiSpmk.trim()
        : KegiatanModel.calculateTanggalAkhirSpmk(
            newStartSpmk,
            '${newContract.hariKalender}',
          );
    final newDurasiFormatted = newContract.hariKalender > 0
        ? IndonesianTerbilang.formatHariKalender(newContract.hariKalender)
        : '';
    final newWaktuBerjalan = KegiatanModel.calculateWaktuBerjalan(newStartSpmk);

    final updatedKegiatans = newContract.kegiatans.map((rawKeg) {
      final keg = Map<String, dynamic>.from(rawKeg);

      final matchesOldStart = keg['tglSpmkKontraktor']?.toString().trim() == oldContract.tglMulaiSpmk.trim() ||
          keg['awalPelaksanaan']?.toString().trim() == oldContract.tglMulaiSpmk.trim() ||
          (keg['tglSpmkKontraktor']?.toString().trim().isEmpty ?? true);

      if (forceSyncAll || matchesOldStart) {
        if (newStartSpmk.isNotEmpty) {
          keg['tglSpmkKonsultan'] = newStartSpmk;
          keg['awalPelaksanaan'] = newStartSpmk;
          keg['tglSpmkKontraktor'] = newStartSpmk;
          keg['waktuBerjalan'] = newWaktuBerjalan;
        }
        if (newEndSpmk.isNotEmpty) {
          keg['akhirPelaksanaan'] = newEndSpmk;
          keg['tglAkhirSpmkKontraktor'] = newEndSpmk;
        }
        if (newDurasiFormatted.isNotEmpty) {
          keg['masaPelaksanaan'] = newDurasiFormatted;
          keg['jangkaWaktu'] = newDurasiFormatted;
        }
        if (newContract.tglMulaiSpk.trim().isNotEmpty &&
            (forceSyncAll ||
                keg['tglSpkKonsultan']?.toString().trim() == oldContract.tglMulaiSpk.trim() ||
                (keg['tglSpkKonsultan']?.toString().trim().isEmpty ?? true))) {
          keg['tglSpkKonsultan'] = newContract.tglMulaiSpk.trim();
        }
        if (newContract.tglMulaiSpk.trim().isNotEmpty &&
            (forceSyncAll ||
                keg['tglSuratPesanan']?.toString().trim() == oldContract.tglMulaiSpk.trim() ||
                (keg['tglSuratPesanan']?.toString().trim().isEmpty ?? true))) {
          keg['tglSuratPesanan'] = newContract.tglMulaiSpk.trim();
        }
      }
      return keg;
    }).toList();

    return ContractModel(
      id: newContract.id,
      jenisKegiatan: newContract.jenisKegiatan,
      namaKontrak: newContract.namaKontrak,
      nomorSpk: newContract.nomorSpk,
      tglMulaiSpk: newContract.tglMulaiSpk,
      nomorSpmk: newContract.nomorSpmk,
      tglMulaiSpmk: newStartSpmk,
      tglSelesaiSpmk: newEndSpmk,
      hariKalender: newContract.hariKalender,
      nilaiKontrak: newContract.nilaiKontrak,
      instansiDinas: newContract.instansiDinas,
      dinasUid: newContract.dinasUid,
      sumberDana: newContract.sumberDana,
      deskripsi: newContract.deskripsi,
      progressFisik: newContract.progressFisik,
      folders: newContract.folders,
      kegiatans: updatedKegiatans,
      strukturOrganisasi: newContract.strukturOrganisasi,
    );
  }
}
