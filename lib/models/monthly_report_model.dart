import 'dart:math';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/utils/execution_period_helper.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';

class MonthlyBoQItem {
  final String no;
  final String noMataPembayaran;
  final String uraian;
  final String satuan;
  final double volumeCCO;
  final double bobotCCO;

  final double volumeBulanLalu;
  final double bobotBulanLalu;

  final double volumeBulanIni;
  final double bobotBulanIni;

  final double volumeSdBulanIni;
  final double bobotSdBulanIni;

  final double sisaVolume;
  final double sisaBobot;
  final String keterangan;

  MonthlyBoQItem({
    required this.no,
    required this.noMataPembayaran,
    required this.uraian,
    required this.satuan,
    required this.volumeCCO,
    required this.bobotCCO,
    required this.volumeBulanLalu,
    required this.bobotBulanLalu,
    required this.volumeBulanIni,
    required this.bobotBulanIni,
    required this.volumeSdBulanIni,
    required this.bobotSdBulanIni,
    required this.sisaVolume,
    required this.sisaBobot,
    this.keterangan = '',
  });
}

class MonthlyBoQDivision {
  final String kode;
  final String nama;
  final List<MonthlyBoQItem> items;

  MonthlyBoQDivision({
    required this.kode,
    required this.nama,
    required this.items,
  });

  double get subtotalBobotCCO => items.fold(0.0, (s, it) => s + it.bobotCCO);
  double get subtotalBobotBulanLalu => items.fold(0.0, (s, it) => s + it.bobotBulanLalu);
  double get subtotalBobotBulanIni => items.fold(0.0, (s, it) => s + it.bobotBulanIni);
  double get subtotalBobotSdBulanIni => items.fold(0.0, (s, it) => s + it.bobotSdBulanIni);
  double get subtotalBobotSisa => items.fold(0.0, (s, it) => s + it.sisaBobot);
}

class MonthlyReportModel {
  final int bulanKe;
  final String bulanRomawi;
  final String namaBulan;
  final String periodeFormatted;
  final int mingguMulai;
  final int mingguSelesai;
  final List<int> mingguTersedia;
  final String status; // 'Selesai', 'Sedang Berjalan', 'Belum Ada Data'
  final String statusDetail;

  final List<MonthlyBoQDivision> divisions;
  final double totalBobotCCO;
  final double totalBobotBulanLalu;
  final double totalBobotBulanIni;
  final double totalBobotSdBulanIni;
  final double totalBobotSisa;

  final double rencanaFisikPersen;
  final double realisasiKumulatifPersen;
  final double deviasiPersen;

  // Metadata proyek
  final String namaKegiatan;
  final String lokasi;
  final String sumberDana;
  final String pelaksanaKontraktor;
  final String noKontrak;
  final String konsultanPengawas;
  final String noKontrakPengawas;

  // Data Tanda Tangan & Pengesahan Digital (3 Pihak)
  final List<Map<String, dynamic>>? ttdList;
  final String? ttdKontraktorNama;
  final String? ttdKontraktorJabatan;
  final String? ttdKontraktorSignature;
  final String? ttdKontraktorTanggal;

  final String? ttdKonsultanNama;
  final String? ttdKonsultanJabatan;
  final String? ttdKonsultanSignature;
  final String? ttdKonsultanTanggal;

  final String? ttdPpkNama;
  final String? ttdPpkJabatan;
  final String? ttdPpkSignature;
  final String? ttdPpkTanggal;

  MonthlyReportModel({
    required this.bulanKe,
    required this.bulanRomawi,
    required this.namaBulan,
    required this.periodeFormatted,
    required this.mingguMulai,
    required this.mingguSelesai,
    required this.mingguTersedia,
    required this.status,
    required this.statusDetail,
    required this.divisions,
    required this.totalBobotCCO,
    required this.totalBobotBulanLalu,
    required this.totalBobotBulanIni,
    required this.totalBobotSdBulanIni,
    required this.totalBobotSisa,
    required this.rencanaFisikPersen,
    required this.realisasiKumulatifPersen,
    required this.deviasiPersen,
    required this.namaKegiatan,
    required this.lokasi,
    required this.sumberDana,
    required this.pelaksanaKontraktor,
    required this.noKontrak,
    required this.konsultanPengawas,
    required this.noKontrakPengawas,
    this.ttdList,
    this.ttdKontraktorNama,
    this.ttdKontraktorJabatan,
    this.ttdKontraktorSignature,
    this.ttdKontraktorTanggal,
    this.ttdKonsultanNama,
    this.ttdKonsultanJabatan,
    this.ttdKonsultanSignature,
    this.ttdKonsultanTanggal,
    this.ttdPpkNama,
    this.ttdPpkJabatan,
    this.ttdPpkSignature,
    this.ttdPpkTanggal,
  });

  Map<String, dynamic> get ttdKontraktor {
    if (ttdList != null && ttdList!.isNotEmpty) {
      final f = ttdList!.firstWhere(
        (t) =>
            t['pihak'] == 'kontraktor' ||
            (t['jabatan']?.toString().toLowerCase().contains('kontraktor') ?? false),
        orElse: () => ttdList!.first,
      );
      if (f.isNotEmpty) return f;
    }
    return {
      'nama': ttdKontraktorNama ?? '',
      'jabatan': ttdKontraktorJabatan ?? 'Kontraktor Pelaksana',
      'signature': ttdKontraktorSignature,
      'tanggal': ttdKontraktorTanggal ?? '',
    };
  }

  Map<String, dynamic> get ttdKonsultan {
    if (ttdList != null && ttdList!.isNotEmpty) {
      final f = ttdList!.firstWhere(
        (t) =>
            t['pihak'] == 'konsultan' ||
            (t['jabatan']?.toString().toLowerCase().contains('konsultan') ?? false),
        orElse: () => ttdList!.length > 1 ? ttdList![1] : {},
      );
      if (f.isNotEmpty) return f;
    }
    return {
      'nama': ttdKonsultanNama ?? '',
      'jabatan': ttdKonsultanJabatan ?? 'Konsultan Supervisi',
      'signature': ttdKonsultanSignature,
      'tanggal': ttdKonsultanTanggal ?? '',
    };
  }

  Map<String, dynamic> get ttdPpk {
    if (ttdList != null && ttdList!.isNotEmpty) {
      final f = ttdList!.firstWhere(
        (t) =>
            t['pihak'] == 'ppk' ||
            (t['jabatan']?.toString().toLowerCase().contains('ppk') ?? false),
        orElse: () => ttdList!.length > 2 ? ttdList![2] : {},
      );
      if (f.isNotEmpty) return f;
    }
    return {
      'nama': ttdPpkNama ?? '',
      'jabatan': ttdPpkJabatan ?? 'Pejabat Pembuat Komitmen (PPK)',
      'signature': ttdPpkSignature,
      'tanggal': ttdPpkTanggal ?? '',
    };
  }

  MonthlyReportModel copyWithSignatures({
    List<Map<String, dynamic>>? ttdList,
    String? ttdKontraktorNama,
    String? ttdKontraktorJabatan,
    String? ttdKontraktorSignature,
    String? ttdKontraktorTanggal,
    String? ttdKonsultanNama,
    String? ttdKonsultanJabatan,
    String? ttdKonsultanSignature,
    String? ttdKonsultanTanggal,
    String? ttdPpkNama,
    String? ttdPpkJabatan,
    String? ttdPpkSignature,
    String? ttdPpkTanggal,
  }) {
    return MonthlyReportModel(
      bulanKe: bulanKe,
      bulanRomawi: bulanRomawi,
      namaBulan: namaBulan,
      periodeFormatted: periodeFormatted,
      mingguMulai: mingguMulai,
      mingguSelesai: mingguSelesai,
      mingguTersedia: mingguTersedia,
      status: status,
      statusDetail: statusDetail,
      divisions: divisions,
      totalBobotCCO: totalBobotCCO,
      totalBobotBulanLalu: totalBobotBulanLalu,
      totalBobotBulanIni: totalBobotBulanIni,
      totalBobotSdBulanIni: totalBobotSdBulanIni,
      totalBobotSisa: totalBobotSisa,
      rencanaFisikPersen: rencanaFisikPersen,
      realisasiKumulatifPersen: realisasiKumulatifPersen,
      deviasiPersen: deviasiPersen,
      namaKegiatan: namaKegiatan,
      lokasi: lokasi,
      sumberDana: sumberDana,
      pelaksanaKontraktor: pelaksanaKontraktor,
      noKontrak: noKontrak,
      konsultanPengawas: konsultanPengawas,
      noKontrakPengawas: noKontrakPengawas,
      ttdList: ttdList ?? this.ttdList,
      ttdKontraktorNama: ttdKontraktorNama ?? this.ttdKontraktorNama,
      ttdKontraktorJabatan: ttdKontraktorJabatan ?? this.ttdKontraktorJabatan,
      ttdKontraktorSignature: ttdKontraktorSignature ?? this.ttdKontraktorSignature,
      ttdKontraktorTanggal: ttdKontraktorTanggal ?? this.ttdKontraktorTanggal,
      ttdKonsultanNama: ttdKonsultanNama ?? this.ttdKonsultanNama,
      ttdKonsultanJabatan: ttdKonsultanJabatan ?? this.ttdKonsultanJabatan,
      ttdKonsultanSignature: ttdKonsultanSignature ?? this.ttdKonsultanSignature,
      ttdKonsultanTanggal: ttdKonsultanTanggal ?? this.ttdKonsultanTanggal,
      ttdPpkNama: ttdPpkNama ?? this.ttdPpkNama,
      ttdPpkJabatan: ttdPpkJabatan ?? this.ttdPpkJabatan,
      ttdPpkSignature: ttdPpkSignature ?? this.ttdPpkSignature,
      ttdPpkTanggal: ttdPpkTanggal ?? this.ttdPpkTanggal,
    );
  }

  static String toRoman(int number) {
    switch (number) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      case 4:
        return 'IV';
      case 5:
        return 'V';
      case 6:
        return 'VI';
      case 7:
        return 'VII';
      case 8:
        return 'VIII';
      case 9:
        return 'IX';
      case 10:
        return 'X';
      default:
        return number.toString();
    }
  }

  static List<Map<String, dynamic>> _flattenBoqItems(List? boqProgressList) {
    if (boqProgressList == null || boqProgressList.isEmpty) return [];
    final List<Map<String, dynamic>> result = [];
    for (final entry in boqProgressList) {
      if (entry is Map) {
        if (entry['items'] is List) {
          for (final it in (entry['items'] as List)) {
            if (it is Map) result.add(Map<String, dynamic>.from(it));
          }
        } else {
          result.add(Map<String, dynamic>.from(entry));
        }
      }
    }
    return result;
  }

  static double _getSdVolume(Map<String, dynamic>? item) {
    if (item == null) return 0.0;
    final val = item['sdMingguIniVolume'] ??
        item['volumeSdMingguIni'] ??
        item['volumeKumulatif'] ??
        item['volume'];
    if (val is num) return val.toDouble();
    return double.tryParse(val?.toString() ?? '0') ?? 0.0;
  }

  static Map<String, dynamic>? _findMatchingItem(
    List<Map<String, dynamic>> items,
    String noMata,
    String uraian,
  ) {
    final cleanNoMata = noMata.trim();
    final cleanUraian = uraian.toLowerCase().trim();
    for (final it in items) {
      final itemNoMata = (it['noMataPembayaran'] ?? '').toString().trim();
      final itemUraian = (it['uraian'] ?? it['nama'] ?? '').toString().toLowerCase().trim();
      if (cleanNoMata.isNotEmpty && itemNoMata == cleanNoMata) return it;
      if (cleanUraian.isNotEmpty && (itemUraian == cleanUraian || cleanUraian.contains(itemUraian) || itemUraian.contains(cleanUraian))) return it;
    }
    return null;
  }

  static double _calcVolFromDailyReports(
    List dailyReports,
    String noMata,
    String uraian,
    DateTime? maxDate,
  ) {
    if (dailyReports.isEmpty) return 0.0;
    final cleanNoMata = noMata.trim();
    final cleanUraian = uraian.trim().toLowerCase();
    double total = 0.0;

    for (final rep in dailyReports) {
      if (rep is! Map) continue;
      if (maxDate != null) {
        final repTglStr = rep['tanggal']?.toString() ?? '';
        final repDate = WeeklyReportModel.parseIndonesianDate(repTglStr) ?? DateTime.tryParse(repTglStr);
        if (repDate != null) {
          final repDay = DateTime(repDate.year, repDate.month, repDate.day);
          final maxDay = DateTime(maxDate.year, maxDate.month, maxDate.day);
          if (repDay.isAfter(maxDay)) continue;
        }
      }

      final pList = (rep['pekerjaanList'] as List?) ?? [];
      for (final p in pList) {
        if (p is! Map) continue;
        final pNoMata = p['noMataPembayaran']?.toString().trim() ?? '';
        final pUraian = (p['uraian'] ?? p['jenis'])?.toString().trim().toLowerCase() ?? '';
        final matchNoMata = cleanNoMata.isNotEmpty && pNoMata == cleanNoMata;
        final matchUraian = cleanUraian.isNotEmpty && (pUraian == cleanUraian || cleanUraian.contains(pUraian) || pUraian.contains(cleanUraian));

        if (matchNoMata || matchUraian) {
          final vStr = (p['volume'] ?? '').toString();
          final vNum = double.tryParse(vStr.split(' ').first.replaceAll(',', '.')) ?? 0.0;
          total += vNum;
        }
      }
    }

    return total;
  }

  /// Menghasilkan daftar Laporan Bulanan secara otomatis (tiap blok 4 minggu)
  /// berdasarkan data ContractModel dan Kegiatan.
  static List<MonthlyReportModel> generateFromWeeklyReports({
    required ContractModel contract,
    required dynamic kegiatan, // Map<String, dynamic> or KegiatanModel
  }) {
    final Map<String, dynamic> kegMap = (kegiatan is KegiatanModel)
        ? kegiatan.toJson()
        : Map<String, dynamic>.from(kegiatan as Map);

    final kegModel = (kegiatan is KegiatanModel)
        ? kegiatan
        : KegiatanModel.fromJson(kegMap, fallbackContract: contract);

    // Selesaikan periode pelaksanaan otoritatif dari Kegiatan & Kontrak terbaru
    final period = ExecutionPeriodHelper.resolveExecutionPeriod(
      kegMap,
      contract: contract,
    );
    final int totalDays = period.durationDays > 0
        ? period.durationDays
        : (contract.hariKalender > 0 ? contract.hariKalender : 90);

    // Tentukan total minggu kontrak kegiatan berdasarkan periode terbaru
    int totalWeeks = period.totalWeeks;
    if (kegMap['minggu'] != null) {
      final parsed = int.tryParse(kegMap['minggu'].toString());
      if (parsed != null && parsed > 0) totalWeeks = parsed;
    }

    // Ambil seluruh laporan mingguan yang selaras dengan jadwal aktif (jika periodeAwal cocok atau kosong)
    final List rawMingguan = (kegMap['laporanMingguan'] as List?) ?? [];
    final List<WeeklyReportModel> allWeeklyReports = rawMingguan
        .map((w) => (w is WeeklyReportModel)
            ? w
            : WeeklyReportModel.fromJson(Map<String, dynamic>.from(w as Map)))
        .toList();

    final List<WeeklyReportModel> weeklyReports = [];
    for (final w in allWeeklyReports) {
      final range = ExecutionPeriodHelper.calcWeekRange(w.mingguKe, period.startDate, totalDays);
      if (ExecutionPeriodHelper.doesSavedWeeklyMatchRange(w, range)) {
        weeklyReports.add(w);
      }
    }
    weeklyReports.sort((a, b) => a.mingguKe.compareTo(b.mingguKe));

    // Pastikan totalWeeks minimal mengakomodasi minggu terakhir yang selaras
    if (weeklyReports.isNotEmpty && weeklyReports.last.mingguKe > totalWeeks) {
      totalWeeks = weeklyReports.last.mingguKe;
    }

    // Hitung berapa bulan (setiap 4 minggu adalah 1 bulan)
    final int totalMonths = (totalWeeks / 4.0).ceil();
    final List<MonthlyReportModel> monthlyReports = [];

    // Metadata kontrak
    final namaKegiatan = kegModel.namaKegiatan.isNotEmpty
        ? kegModel.namaKegiatan
        : contract.namaKontrak;
    final lokasi = kegModel.lokasi.isNotEmpty
        ? kegModel.lokasi
        : 'Kab. Purbalingga';
    final sumberDana = kegModel.sumberDana.isNotEmpty
        ? kegModel.sumberDana
        : contract.sumberDana;
    final pelaksanaKontraktor = kegModel.kontraktor.isNotEmpty
        ? kegModel.kontraktor
        : (kegMap['kontraktor']?.toString() ?? '');
    final noKontrak = kegModel.noSuratPesanan.isNotEmpty
        ? kegModel.noSuratPesanan
        : (contract.nomorSpk.isNotEmpty ? contract.nomorSpk : contract.nomorSpmk);
    final konsultanPengawas = kegModel.konsultanPengawas.isNotEmpty
        ? kegModel.konsultanPengawas
        : (kegMap['konsultanPengawas']?.toString() ?? '');
    final noKontrakPengawas = kegModel.noSpkKonsultan.isNotEmpty
        ? kegModel.noSpkKonsultan
        : contract.nomorSpmk;

    for (int monthIdx = 1; monthIdx <= totalMonths; monthIdx++) {
      final int startWeek = (monthIdx - 1) * 4 + 1;
      final int endWeek = min(monthIdx * 4, totalWeeks);

      // Cari laporan mingguan yang masuk dalam rentang startWeek..endWeek
      final weeksInMonth = weeklyReports
          .where((w) => w.mingguKe >= startWeek && w.mingguKe <= endWeek)
          .toList();
      final List<int> mingguTersedia = weeksInMonth.map((w) => w.mingguKe).toList();

      // Cari laporan mingguan sebelum bulan ini (s.d. startWeek - 1)
      final weeksBefore = weeklyReports.where((w) => w.mingguKe < startWeek).toList();
      final WeeklyReportModel? latestBefore =
          weeksBefore.isNotEmpty ? weeksBefore.last : null;

      // Periode Tanggal SELALU dihitung dinamis dari tanggal pelaksanaan kegiatan terbaru
      String periodeFormatted;
      DateTime? monthStartDt;
      DateTime? monthEndDt;

      if (period.startDate != null) {
        final spmkDt = period.startDate!;
        final startDayIdx = (startWeek - 1) * 7;
        final endDayIdx = min(endWeek * 7 - 1, totalDays - 1);
        monthStartDt = DateTime(spmkDt.year, spmkDt.month, spmkDt.day + startDayIdx);
        monthEndDt = DateTime(spmkDt.year, spmkDt.month, spmkDt.day + max(startDayIdx, endDayIdx));
        periodeFormatted =
            '${WeeklyReportModel.formatIndonesianDate(monthStartDt)} - ${WeeklyReportModel.formatIndonesianDate(monthEndDt)}';
      } else if (weeksInMonth.isNotEmpty) {
        final firstWeek = weeksInMonth.first;
        final lastWeek = weeksInMonth.last;
        periodeFormatted = '${firstWeek.periodeAwal} - ${lastWeek.periodeAkhir}';
        monthStartDt = WeeklyReportModel.parseIndonesianDate(firstWeek.periodeAwal);
        monthEndDt = WeeklyReportModel.parseIndonesianDate(lastWeek.periodeAkhir);
      } else {
        periodeFormatted = 'Minggu $startWeek s.d. Minggu $endWeek';
      }

      // Hitung agregasi BOQ terpusat dari ProgressCalculator (Sinkron dengan Laporan Harian)
      final boqResult = ProgressCalculator.calculateBoqProgress(
        kegMap: kegMap,
        startDt: monthStartDt,
        endDt: monthEndDt,
        minStartDt: period.startDate,
      );

      // Laporan mingguan referensi s/d akhir bulan berjalan
      final WeeklyReportModel? currentLatestWeek =
          weeksInMonth.isNotEmpty ? weeksInMonth.last : null;
      final prevItems = _flattenBoqItems(latestBefore?.boqProgressList);
      final currItems = _flattenBoqItems(currentLatestWeek?.boqProgressList);

      // Cek apakah ada laporan harian di dalam bulan ini sesudah minggu terakhir yang tersimpan
      bool hasDailyAfterCurrentWeek = false;
      final DateTime? currentWeekEndDt = currentLatestWeek != null
          ? WeeklyReportModel.parseIndonesianDate(currentLatestWeek.periodeAkhir)
          : null;
      if (currentWeekEndDt != null && monthEndDt != null) {
        final cwEndDay = DateTime(currentWeekEndDt.year, currentWeekEndDt.month, currentWeekEndDt.day);
        final mEndDay = DateTime(monthEndDt.year, monthEndDt.month, monthEndDt.day);
        final minStartDay = period.startDate != null
            ? DateTime(period.startDate!.year, period.startDate!.month, period.startDate!.day)
            : null;
        if (mEndDay.isAfter(cwEndDay)) {
          final rawDaily = (kegMap['laporans'] as List?) ?? [];
          for (final rep in rawDaily) {
            if (rep is! Map) continue;
            final tglStr = rep['tanggal']?.toString() ?? rep['tanggalFormatted']?.toString() ?? '';
            final dt = DateTime.tryParse(tglStr) ?? WeeklyReportModel.parseIndonesianDate(tglStr);
            if (dt == null) continue;
            final day = DateTime(dt.year, dt.month, dt.day);
            if (minStartDay != null && day.isBefore(minStartDay)) continue;
            if (day.isAfter(cwEndDay) && !day.isAfter(mEndDay)) {
              hasDailyAfterCurrentWeek = true;
              break;
            }
          }
        }
      }

      final bool hasDailyInMonth = boqResult.totalBobotPeriodeIni > 0;

      // Status bulan (mempertimbangkan laporan mingguan selaras & realisasi harian bulan ini)
      String status;
      String statusDetail;
      if (weeksInMonth.isEmpty) {
        if (hasDailyInMonth) {
          status = 'Sedang Berjalan';
          statusDetail = 'Realisasi Harian (M-$startWeek s.d. M-$endWeek)';
        } else {
          status = 'Belum Ada Data';
          statusDetail = 'Rencana (M-$startWeek s.d. M-$endWeek)';
        }
      } else if (weeksInMonth.length == (endWeek - startWeek + 1)) {
        status = 'Selesai';
        statusDetail = 'Lengkap (M-$startWeek s.d. M-$endWeek)';
      } else {
        final minW = mingguTersedia.reduce(min);
        final maxW = mingguTersedia.reduce(max);
        status = 'Sedang Berjalan';
        statusDetail = (minW == maxW)
            ? 'Sedang Berjalan (M-$minW)'
            : 'Sedang Berjalan (M-$minW s.d. M-$maxW)';
      }

      // Hitung rincian tabel per divisi dan item BoQ
      final List<MonthlyBoQDivision> divisions = [];
      double totalBobotCCO = 0.0;
      double totalBobotBulanLalu = 0.0;
      double totalBobotBulanIni = 0.0;
      double totalBobotSdBulanIni = 0.0;
      double totalBobotSisa = 0.0;

      final bool useSavedCurrWeek =
          currItems.isNotEmpty && !hasDailyAfterCurrentWeek;

      for (int divIndex = 0; divIndex < boqResult.divisions.length; divIndex++) {
        final div = boqResult.divisions[divIndex];
        final String kode = (div['nomorRomawi'] ?? div['kode'] ?? (divIndex + 1).toString()).toString();
        final String namaDivisi = (div['namaDivisi'] ?? div['nama'] ?? 'DIVISI').toString();
        final List rawItems = (div['items'] as List?) ?? [];

        final List<MonthlyBoQItem> boqItems = [];

        for (int itIndex = 0; itIndex < rawItems.length; itIndex++) {
          final it = rawItems[itIndex] as Map;
          final String itemNo = (it['no'] ?? (itIndex + 1).toString()).toString();
          final String noMataPembayaran = (it['noMataPembayaran'] ?? '').toString();
          final String uraian = (it['uraian'] ?? it['nama'] ?? '').toString();
          final String satuan = (it['satuan'] ?? '').toString();
          final double volCCO = (it['volumeCCO'] ?? it['volume'] as num?)?.toDouble() ?? 0.0;
          final double bbtCCO = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;

          final double calcVolLalu =
              (it['mingguLaluVolume'] as num?)?.toDouble() ??
                  (it['bulanLaluVolume'] as num?)?.toDouble() ??
                  0.0;
          final double calcVolIni =
              (it['mingguIniVolume'] as num?)?.toDouble() ??
                  (it['bulanIniVolume'] as num?)?.toDouble() ??
                  0.0;

          final double volBulanLalu = prevItems.isNotEmpty
              ? _getSdVolume(_findMatchingItem(prevItems, noMataPembayaran, uraian))
              : calcVolLalu;

          final double volSdBulanIni;
          if (useSavedCurrWeek) {
            volSdBulanIni = _getSdVolume(
              _findMatchingItem(currItems, noMataPembayaran, uraian),
            );
          } else if (currItems.isEmpty && prevItems.isNotEmpty && !hasDailyInMonth) {
            volSdBulanIni = volBulanLalu;
          } else {
            volSdBulanIni = volBulanLalu + calcVolIni;
          }

          final double volBulanIni = max(0.0, volSdBulanIni - volBulanLalu);

          final double bbtBulanLalu = (volCCO > 0)
              ? (volBulanLalu / volCCO) * bbtCCO
              : 0.0;
          final double bbtBulanIni = (volCCO > 0)
              ? (volBulanIni / volCCO) * bbtCCO
              : 0.0;
          final double bbtSdBulanIni = (volCCO > 0)
              ? (volSdBulanIni / volCCO) * bbtCCO
              : 0.0;

          final double sisaVolume = max(0.0, volCCO - volSdBulanIni);
          final double sisaBobot = max(0.0, bbtCCO - bbtSdBulanIni);

          boqItems.add(
            MonthlyBoQItem(
              no: itemNo,
              noMataPembayaran: noMataPembayaran,
              uraian: uraian,
              satuan: satuan,
              volumeCCO: volCCO,
              bobotCCO: bbtCCO,
              volumeBulanLalu: volBulanLalu,
              bobotBulanLalu: bbtBulanLalu,
              volumeBulanIni: volBulanIni,
              bobotBulanIni: bbtBulanIni,
              volumeSdBulanIni: volSdBulanIni,
              bobotSdBulanIni: bbtSdBulanIni,
              sisaVolume: sisaVolume,
              sisaBobot: sisaBobot,
            ),
          );

          totalBobotCCO += bbtCCO;
          totalBobotBulanLalu += bbtBulanLalu;
          totalBobotBulanIni += bbtBulanIni;
          totalBobotSdBulanIni += bbtSdBulanIni;
          totalBobotSisa += sisaBobot;
        }

        divisions.add(
          MonthlyBoQDivision(
            kode: kode,
            nama: namaDivisi,
            items: boqItems,
          ),
        );
      }

      // Rencana, Realisasi, Deviasi
      double rencanaFisik = 0.0;
      double realisasiKumulatif = totalBobotSdBulanIni;

      if (currentLatestWeek != null) {
        if (currentLatestWeek.rencanaPersen > 0) {
          rencanaFisik = currentLatestWeek.rencanaPersen;
        }
        if (useSavedCurrWeek && currentLatestWeek.realisasiPersen > 0) {
          realisasiKumulatif = currentLatestWeek.realisasiPersen;
        }
      } else if (latestBefore != null) {
        if (latestBefore.rencanaPersen > 0) {
          rencanaFisik = latestBefore.rencanaPersen;
        }
        if (!hasDailyInMonth && latestBefore.realisasiPersen > 0) {
          realisasiKumulatif = latestBefore.realisasiPersen;
        }
      }
      final double deviasi = realisasiKumulatif - rencanaFisik;

      // Tanda tangan tersimpan untuk bulan ini
      final rawBulananList = (kegMap['laporanBulanan'] as List?) ?? [];
      final savedBulanan = rawBulananList.cast<dynamic>().firstWhere(
            (b) => b is Map && (b['bulanKe'] == monthIdx || b['bulanKe']?.toString() == '$monthIdx'),
            orElse: () => null,
          );

      List<Map<String, dynamic>>? ttdList;
      String? ttdKontraktorNama;
      String? ttdKontraktorJabatan;
      String? ttdKontraktorSignature;
      String? ttdKontraktorTanggal;

      String? ttdKonsultanNama;
      String? ttdKonsultanJabatan;
      String? ttdKonsultanSignature;
      String? ttdKonsultanTanggal;

      String? ttdPpkNama;
      String? ttdPpkJabatan;
      String? ttdPpkSignature;
      String? ttdPpkTanggal;

      if (savedBulanan != null) {
        final Map<String, dynamic> bMap = Map<String, dynamic>.from(savedBulanan as Map);
        if (bMap['ttdList'] != null) {
          ttdList = List<Map<String, dynamic>>.from(
              (bMap['ttdList'] as List).map((e) => Map<String, dynamic>.from(e)));
        }
        ttdKontraktorNama = bMap['ttdKontraktorNama']?.toString();
        ttdKontraktorJabatan = bMap['ttdKontraktorJabatan']?.toString();
        ttdKontraktorSignature = bMap['ttdKontraktorSignature']?.toString();
        ttdKontraktorTanggal = bMap['ttdKontraktorTanggal']?.toString();

        ttdKonsultanNama = bMap['ttdKonsultanNama']?.toString();
        ttdKonsultanJabatan = bMap['ttdKonsultanJabatan']?.toString();
        ttdKonsultanSignature = bMap['ttdKonsultanSignature']?.toString();
        ttdKonsultanTanggal = bMap['ttdKonsultanTanggal']?.toString();

        ttdPpkNama = bMap['ttdPpkNama']?.toString();
        ttdPpkJabatan = bMap['ttdPpkJabatan']?.toString();
        ttdPpkSignature = bMap['ttdPpkSignature']?.toString();
        ttdPpkTanggal = bMap['ttdPpkTanggal']?.toString();
      } else {
        ttdKontraktorNama = pelaksanaKontraktor;
        ttdKontraktorJabatan = 'Kontraktor Pelaksana';
        final konsultanName = kegModel.konsultanPengawas.isNotEmpty
            ? kegModel.konsultanPengawas
            : (kegMap['konsultanPengawas']?.toString() ?? '');
        final dinasName = contract.instansiDinas.isNotEmpty
            ? contract.instansiDinas.first
            : '';
        ttdKonsultanNama = contract.siteEngineer;
        ttdKonsultanJabatan = konsultanName.isNotEmpty
            ? 'Konsultan Supervisi\n$konsultanName'
            : 'Konsultan Supervisi';
        ttdPpkNama = kegModel.penggunaAnggaran.isNotEmpty
            ? kegModel.penggunaAnggaran
            : (kegMap['penggunaAnggaran']?.toString() ?? '');
        ttdPpkJabatan = dinasName.isNotEmpty
            ? 'Pejabat Pembuat Komitmen (PPK)\n$dinasName'
            : 'Pejabat Pembuat Komitmen (PPK)';
        ttdPpkTanggal = periodeFormatted.split('-').last.trim();
      }

      monthlyReports.add(
        MonthlyReportModel(
          bulanKe: monthIdx,
          bulanRomawi: toRoman(monthIdx),
          namaBulan: (startWeek == endWeek)
              ? 'Minggu $startWeek'
              : 'Minggu $startWeek - $endWeek',
          periodeFormatted: periodeFormatted,
          mingguMulai: startWeek,
          mingguSelesai: endWeek,
          mingguTersedia: mingguTersedia,
          status: status,
          statusDetail: statusDetail,
          divisions: divisions,
          totalBobotCCO: totalBobotCCO,
          totalBobotBulanLalu: totalBobotBulanLalu,
          totalBobotBulanIni: totalBobotBulanIni,
          totalBobotSdBulanIni: totalBobotSdBulanIni,
          totalBobotSisa: totalBobotSisa,
          rencanaFisikPersen: rencanaFisik,
          realisasiKumulatifPersen: realisasiKumulatif,
          deviasiPersen: deviasi,
          namaKegiatan: namaKegiatan,
          lokasi: lokasi,
          sumberDana: sumberDana,
          pelaksanaKontraktor: pelaksanaKontraktor,
          noKontrak: noKontrak,
          konsultanPengawas: konsultanPengawas,
          noKontrakPengawas: noKontrakPengawas,
          ttdList: ttdList,
          ttdKontraktorNama: ttdKontraktorNama,
          ttdKontraktorJabatan: ttdKontraktorJabatan,
          ttdKontraktorSignature: ttdKontraktorSignature,
          ttdKontraktorTanggal: ttdKontraktorTanggal,
          ttdKonsultanNama: ttdKonsultanNama,
          ttdKonsultanJabatan: ttdKonsultanJabatan,
          ttdKonsultanSignature: ttdKonsultanSignature,
          ttdKonsultanTanggal: ttdKonsultanTanggal,
          ttdPpkNama: ttdPpkNama,
          ttdPpkJabatan: ttdPpkJabatan,
          ttdPpkSignature: ttdPpkSignature,
          ttdPpkTanggal: ttdPpkTanggal,
        ),
      );
    }

    return monthlyReports;
  }
}
