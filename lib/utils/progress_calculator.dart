import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/utils/execution_period_helper.dart';

/// Hasil agregasi rekapitulasi BOQ (14 kolom) berbasis laporan harian.
class BoqAggregationResult {
  final List<Map<String, dynamic>> divisions;
  final double totalBobotKontrak;
  final double totalBobotPeriodeLalu;
  final double totalBobotPeriodeIni;
  final double totalBobotSdPeriodeIni;
  final double totalBobotSisa;

  BoqAggregationResult({
    required this.divisions,
    required this.totalBobotKontrak,
    required this.totalBobotPeriodeLalu,
    required this.totalBobotPeriodeIni,
    required this.totalBobotSdPeriodeIni,
    required this.totalBobotSisa,
  });

  List<Map<String, dynamic>> get divisiList => divisions;
  double get totalBobotIni => totalBobotPeriodeIni;
  double get totalBobotSdIni => totalBobotSdPeriodeIni;
}

/// Utility terpusat untuk audit dan perhitungan persentase progres fisik proyek.
///
/// Memastikan rumus dan sumber data antara:
/// - Dashboard (Tingkat Kontrak & Tingkat Kegiatan)
/// - Detail Kegiatan (Tingkat Kegiatan)
/// - Daftar Kontrak & Detail Kontrak
/// menggunakan Single Source of Truth yang sama dan 100% konsisten.
class ProgressCalculator {
  /// Mengambil RKK yang sedang aktif dari Map kegiatan.
  /// Urutan prioritas:
  /// 1. Addendum CCO terakhir (jika ada addendum dengan rkkDivisiList)
  /// 2. Baseline Kontrak Awal (rkkKontrakAwal)
  /// 3. Default (rkkDivisiList)
  static List<Map<String, dynamic>> getActiveRkk(Map<String, dynamic> kegMap) {
    final adds = (kegMap['addendums'] as List?) ?? [];
    if (adds.isNotEmpty && adds.last is Map) {
      final divList = adds.last['rkkDivisiList'] as List?;
      if (divList != null && divList.isNotEmpty) {
        return divList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    }
    final awal = (kegMap['rkkKontrakAwal'] as List?) ?? [];
    if (awal.isNotEmpty) {
      return awal.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    final def = (kegMap['rkkDivisiList'] as List?) ?? [];
    return def.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static DateTime _dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? _parseReportDate(Map<dynamic, dynamic> rep) {
    final repTglStr = rep['tanggal']?.toString() ?? '';
    if (repTglStr.isNotEmpty) {
      final dt = DateTime.tryParse(repTglStr) ??
          WeeklyReportModel.parseIndonesianDate(repTglStr);
      if (dt != null) return dt;
    }
    final fStr = rep['tanggalFormatted']?.toString() ?? '';
    if (fStr.isNotEmpty) {
      final dt = WeeklyReportModel.parseIndonesianDate(fStr);
      if (dt != null) return dt;
    }
    final cStr = rep['createdAt']?.toString() ?? '';
    if (cStr.isNotEmpty) {
      return DateTime.tryParse(cStr) ??
          WeeklyReportModel.parseIndonesianDate(cStr);
    }
    return null;
  }

  static bool _hasExplicitExecutionBounds(
    Map<String, dynamic> kegMap,
    ContractModel? contract,
  ) {
    if (contract != null &&
        (contract.tglMulaiSpmk.trim().isNotEmpty ||
            contract.tglSelesaiSpmk.trim().isNotEmpty)) {
      return true;
    }
    const keys = [
      'tglSpmkKontraktor',
      'awalPelaksanaan',
      'tglSpmkKonsultan',
      'tglAkhirSpmkKontraktor',
      'akhirPelaksanaan',
    ];
    return keys.any((k) => (kegMap[k]?.toString().trim() ?? '').isNotEmpty);
  }

  static double _resolveMatchedDailyVolume(
    Map<dynamic, dynamic> rep, {
    required String rkkId,
    required String itId,
    required String noMata,
    required String uraian,
  }) {
    double matchedVol = 0.0;
    final pList = (rep['pekerjaanList'] as List?) ?? [];
    for (final p in pList) {
      if (p is! Map) continue;
      final pId = (p['rkkItemId'] ?? '').toString().trim();
      final pNoMata = (p['noMataPembayaran'] ?? '').toString().trim();
      final pUraian = (p['uraian'] ?? p['jenis'] ?? p['jenisPekerjaan'])
              ?.toString()
              .trim()
              .toLowerCase() ??
          '';

      final matchId =
          pId.isNotEmpty && (pId == rkkId || (itId.isNotEmpty && pId == itId));
      final matchNoMata =
          noMata.isNotEmpty && pNoMata.isNotEmpty && noMata == pNoMata;
      final matchUraian = uraian.isNotEmpty &&
          pUraian.isNotEmpty &&
          (pUraian == uraian ||
              uraian.contains(pUraian) ||
              pUraian.contains(uraian));

      if (matchId || matchNoMata || matchUraian) {
        final vStr = (p['volume'] ?? '').toString();
        final vNum =
            double.tryParse(vStr.split(' ').first.replaceAll(',', '.')) ?? 0.0;
        matchedVol += vNum;
      }
    }
    return matchedVol;
  }

  /// Menghitung persentase progres fisik suatu kegiatan (skala 0.0 s.d. 100.0%).
  ///
  /// Alur audit perhitungan:
  /// 1. Jika RKK aktif tersedia, progres SELALU dihitung real-time dari akumulasi
  ///    laporan harian (`laporans`) yang berada dalam periode pelaksanaan aktif.
  ///    Tidak menggunakan fallback laporan mingguan/statis yang sudah usang.
  /// 2. Jika RKK belum tersedia, fallback ke laporan mingguan yang selaras
  ///    dengan jadwal aktif, lalu ke nilai manual `progressFisik`/`progresFisik`.
  static double calculateKegiatanProgress(
    Map<String, dynamic> kegMap, {
    ContractModel? contract,
  }) {
    final rawRkk = getActiveRkk(kegMap);
    final dailyReports = (kegMap['laporans'] as List?) ?? [];
    final hasBounds = _hasExplicitExecutionBounds(kegMap, contract);
    final period = hasBounds
        ? ExecutionPeriodHelper.resolveExecutionPeriod(kegMap, contract: contract)
        : null;
    final DateTime? minStartDay =
        period?.startDate != null ? _dayOnly(period!.startDate!) : null;
    final DateTime? maxEndDay =
        period?.endDate != null ? _dayOnly(period!.endDate!) : null;

    if (rawRkk.isNotEmpty) {
      double totalProgress = 0.0;
      for (final div in rawRkk) {
        final items = (div['items'] as List?) ?? [];
        final romawi = (div['nomorRomawi'] ?? div['romawi'] ?? 'I').toString();
        for (final rawIt in items) {
          if (rawIt is! Map) continue;
          final it = Map<String, dynamic>.from(rawIt);
          final noMata = (it['noMataPembayaran'] ?? '').toString().trim();
          final uraian = (it['uraian'] ?? it['jenisPekerjaan'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          final rkkId = '${romawi}_${it['uraian']}';
          final itId = (it['id'] ?? '').toString().trim();
          final volKontrak =
              (it['volumeCCO'] ?? it['volume'] as num?)?.toDouble() ?? 0.0;
          final bbtKontrak = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
          if (volKontrak <= 0 || bbtKontrak <= 0) continue;

          double volReal = 0.0;
          for (final rep in dailyReports) {
            if (rep is! Map) continue;
            final repDate = _parseReportDate(rep);
            if (repDate != null && (minStartDay != null || maxEndDay != null)) {
              final repDay = _dayOnly(repDate);
              if (minStartDay != null && repDay.isBefore(minStartDay)) {
                continue;
              }
              if (maxEndDay != null && repDay.isAfter(maxEndDay)) {
                continue;
              }
            }
            volReal += _resolveMatchedDailyVolume(
              rep,
              rkkId: rkkId,
              itId: itId,
              noMata: noMata,
              uraian: uraian,
            );
          }

          totalProgress += (volReal / volKontrak) * bbtKontrak;
        }
      }

      return totalProgress.clamp(0.0, 100.0);
    }

    // 2. Fallback (hanya saat RKK belum diisi): Laporan Mingguan selaras jadwal aktif
    final rawMingguan = kegMap['laporanMingguan'];
    if (rawMingguan != null && rawMingguan is List && rawMingguan.isNotEmpty) {
      final parsedWeekly = rawMingguan
          .whereType<Map>()
          .map((e) => WeeklyReportModel.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => a.mingguKe.compareTo(b.mingguKe));

      for (int i = parsedWeekly.length - 1; i >= 0; i--) {
        final w = parsedWeekly[i];
        if (period != null && period.startDate != null) {
          final wRange = ExecutionPeriodHelper.calcWeekRange(
            w.mingguKe,
            period.startDate,
            period.durationDays,
          );
          if (!ExecutionPeriodHelper.doesSavedWeeklyMatchRange(w, wRange)) {
            continue;
          }
        }
        if (w.realisasiPersen > 0) return w.realisasiPersen.clamp(0.0, 100.0);
      }
    }

    // 3. Fallback: Nilai manual progressFisik jika tersedia
    if (kegMap['progressFisik'] != null) {
      final p = (kegMap['progressFisik'] as num).toDouble();
      if (p > 0) return (p > 1.0 ? p : p * 100.0).clamp(0.0, 100.0);
    }
    if (kegMap['progresFisik'] != null) {
      final p = (kegMap['progresFisik'] as num).toDouble();
      if (p > 0) return (p > 1.0 ? p : p * 100.0).clamp(0.0, 100.0);
    }

    return 0.0;
  }

  /// Menghitung persentase progres kontrak (skala 0.0 s.d. 100.0%).
  ///
  /// Menghitung rata-rata dari seluruh kegiatan di bawah kontrak.
  /// Menjamin seluruh kegiatan diperhitungkan secara merata.
  /// Jika belum ada kegiatan, mengembalikan fallbackProgress (dalam skala 0..100).
  static double calculateContractProgressPercent(
    List<Map<String, dynamic>> kegiatans, {
    double fallbackProgress = 0.0,
    ContractModel? contract,
  }) {
    if (kegiatans.isEmpty) {
      return (fallbackProgress > 1.0 ? fallbackProgress : fallbackProgress * 100.0).clamp(0.0, 100.0);
    }
    double sum = 0.0;
    for (final keg in kegiatans) {
      sum += calculateKegiatanProgress(keg, contract: contract);
    }
    return (sum / kegiatans.length).clamp(0.0, 100.0);
  }

  /// Menghitung rasio progres kontrak (skala 0.0 s.d. 1.0) untuk progress indicators.
  static double calculateContractProgressRatio(
    List<Map<String, dynamic>> kegiatans, {
    double fallbackProgress = 0.0,
    ContractModel? contract,
  }) {
    final pct = calculateContractProgressPercent(
      kegiatans,
      fallbackProgress: fallbackProgress,
      contract: contract,
    );
    return (pct / 100.0).clamp(0.0, 1.0);
  }

  /// Menghitung rekapitulasi BOQ (14 kolom) secara terpusat untuk periode tertentu (mingguan atau bulanan).
  ///
  /// Menghitung:
  /// - Volume & Bobot Kontrak (dari RAB aktif)
  /// - Volume & Bobot Periode Lalu (laporan harian sebelum startDt)
  /// - Volume & Bobot Periode Berjalan (laporan harian dalam [startDt, endDt])
  /// - Volume & Bobot s/d Periode Berjalan (lalu + berjalan)
  /// - Sisa Volume & Sisa Bobot (kontrak - s/d berjalan)
  static BoqAggregationResult calculateBoqProgress({
    required Map<String, dynamic> kegMap,
    required DateTime? startDt,
    required DateTime? endDt,
    DateTime? minStartDt,
  }) {
    final rawRkk = getActiveRkk(kegMap);
    final dailyReports = (kegMap['laporans'] as List?) ?? [];

    double totalBobotKontrak = 0.0;
    double totalBobotPeriodeLalu = 0.0;
    double totalBobotPeriodeIni = 0.0;
    double totalBobotSdPeriodeIni = 0.0;
    double totalBobotSisa = 0.0;

    final startDayOnly = startDt != null
        ? DateTime(startDt.year, startDt.month, startDt.day)
        : null;
    final endDayOnly = endDt != null
        ? DateTime(endDt.year, endDt.month, endDt.day)
        : null;
    final minStartDayOnly = minStartDt != null
        ? DateTime(minStartDt.year, minStartDt.month, minStartDt.day)
        : null;

    final List<Map<String, dynamic>> computedDivisions = [];

    for (final rawDiv in rawRkk) {
      final div = Map<String, dynamic>.from(rawDiv);
      final rawItems = (div['items'] as List?) ?? [];
      final romawi = (div['nomorRomawi'] ?? div['romawi'] ?? 'I').toString();
      final List<Map<String, dynamic>> computedItems = [];

      for (final rawIt in rawItems) {
        if (rawIt is! Map) continue;
        final it = Map<String, dynamic>.from(rawIt);
        final noMata = (it['noMataPembayaran'] ?? '').toString().trim();
        final uraian = (it['uraian'] ?? it['jenisPekerjaan'] ?? '').toString().trim().toLowerCase();
        final rkkId = '${romawi}_${it['uraian']}';
        final itId = (it['id'] ?? '').toString().trim();
        final volKontrak = (it['volumeCCO'] ?? it['volume'] as num?)?.toDouble() ?? 0.0;
        final bbtKontrak = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;

        double volLalu = 0.0;
        double volIni = 0.0;

        for (final rep in dailyReports) {
          if (rep is! Map) continue;
          final repDate = _parseReportDate(rep);

          bool isLalu = false;
          bool isIni = false;

          if (repDate != null) {
            final repDay = _dayOnly(repDate);
            // Abaikan laporan historis yang tanggalnya berada sebelum tanggal mulai pelaksanaan aktif
            // agar tidak bocor sebagai 'Periode Lalu' saat tanggal kontrak/kegiatan dimajukan.
            if (minStartDayOnly != null && repDay.isBefore(minStartDayOnly)) {
              continue;
            }
            if (startDayOnly != null && endDayOnly != null) {
              if (repDay.isBefore(startDayOnly)) {
                isLalu = true;
              } else if (!repDay.isAfter(endDayOnly)) {
                isIni = true;
              }
            } else if (endDayOnly != null) {
              if (!repDay.isAfter(endDayOnly)) {
                isIni = true;
              }
            } else {
              isIni = true;
            }
          } else if (startDayOnly == null && endDayOnly == null) {
            isIni = true;
          }

          final matchedVol = _resolveMatchedDailyVolume(
            rep,
            rkkId: rkkId,
            itId: itId,
            noMata: noMata,
            uraian: uraian,
          );
          if (isIni) {
            volIni += matchedVol;
          } else if (isLalu) {
            volLalu += matchedVol;
          }
        }

        final volSdIni = volLalu + volIni;
        final bbtLalu = volKontrak > 0 ? (volLalu / volKontrak) * bbtKontrak : 0.0;
        final bbtIni = volKontrak > 0 ? (volIni / volKontrak) * bbtKontrak : 0.0;
        final bbtSdIni = bbtLalu + bbtIni;
        final volSisa = (volKontrak - volSdIni).clamp(0.0, volKontrak);
        final bbtSisa = (bbtKontrak - bbtSdIni).clamp(0.0, bbtKontrak);

        it['mingguLaluVolume'] = volLalu;
        it['mingguLaluBobot'] = bbtLalu;
        it['mingguIniVolume'] = volIni;
        it['mingguIniBobot'] = bbtIni;
        it['sdMingguIniVolume'] = volSdIni;
        it['sdMingguIniBobot'] = bbtSdIni;
        it['sisaVolume'] = volSisa;
        it['sisaBobot'] = bbtSisa;

        // Kompatibilitas bulanan
        it['bulanLaluVolume'] = volLalu;
        it['bulanLaluBobot'] = bbtLalu;
        it['bulanIniVolume'] = volIni;
        it['bulanIniBobot'] = bbtIni;
        it['sdBulanIniVolume'] = volSdIni;
        it['sdBulanIniBobot'] = bbtSdIni;

        computedItems.add(it);

        totalBobotKontrak += bbtKontrak;
        totalBobotPeriodeLalu += bbtLalu;
        totalBobotPeriodeIni += bbtIni;
        totalBobotSdPeriodeIni += bbtSdIni;
        totalBobotSisa += bbtSisa;
      }

      div['items'] = computedItems;
      computedDivisions.add(div);
    }

    return BoqAggregationResult(
      divisions: computedDivisions,
      totalBobotKontrak: totalBobotKontrak,
      totalBobotPeriodeLalu: totalBobotPeriodeLalu,
      totalBobotPeriodeIni: totalBobotPeriodeIni,
      totalBobotSdPeriodeIni: totalBobotSdPeriodeIni,
      totalBobotSisa: totalBobotSisa,
    );
  }
}
