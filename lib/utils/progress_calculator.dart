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

  /// Menghitung persentase progres fisik suatu kegiatan (skala 0.0 s.d. 100.0%).
  ///
  /// Alur audit perhitungan:
  /// 1. Real-time dari akumulasi seluruh laporan harian (laporans) terhadap RKK aktif.
  ///    - Untuk setiap item RKK aktif, mencari target volume (volumeCCO jika ada addendum, atau volume awal)
  ///      dan nilaiBobot item.
  ///    - Menjumlahkan volume pekerjaan dari seluruh laporan harian yang cocok (melalui rkkItemId, noMataPembayaran, atau uraian).
  ///    - Menghitung kontribusi bobot item: (volReal / volKontrak) * bobotItem.
  ///    - Menjumlahkan seluruh kontribusi bobot menjadi total progres kegiatan.
  /// 2. Fallback: Menggunakan realisasiPersen dari laporan mingguan terakhir jika laporan harian belum tersedia atau 0.
  /// 3. Fallback: Menggunakan nilai statis progressFisik / progresFisik jika ada.
  /// 4. Jika tidak ada data laporan, mengembalikan 0.0.
  static double calculateKegiatanProgress(Map<String, dynamic> kegMap) {
    final rawRkk = getActiveRkk(kegMap);
    final dailyReports = (kegMap['laporans'] as List?) ?? [];

    if (dailyReports.isNotEmpty && rawRkk.isNotEmpty) {
      double totalProgress = 0.0;
      for (final div in rawRkk) {
        final items = (div['items'] as List?) ?? [];
        final romawi = (div['nomorRomawi'] ?? div['romawi'] ?? 'I').toString();
        for (final rawIt in items) {
          if (rawIt is! Map) continue;
          final it = Map<String, dynamic>.from(rawIt);
          final noMata = (it['noMataPembayaran'] ?? '').toString().trim();
          final uraian = (it['uraian'] ?? it['jenisPekerjaan'] ?? '').toString().trim().toLowerCase();
          final rkkId = '${romawi}_${it['uraian']}';
          final itId = (it['id'] ?? '').toString().trim();
          final volKontrak = (it['volumeCCO'] ?? it['volume'] as num?)?.toDouble() ?? 0.0;
          final bbtKontrak = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
          if (volKontrak <= 0 || bbtKontrak <= 0) continue;

          double volReal = 0.0;
          for (final rep in dailyReports) {
            if (rep is! Map) continue;
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

              final matchId = pId.isNotEmpty && (pId == rkkId || (itId.isNotEmpty && pId == itId));
              final matchNoMata = noMata.isNotEmpty && pNoMata.isNotEmpty && noMata == pNoMata;
              final matchUraian = uraian.isNotEmpty &&
                  pUraian.isNotEmpty &&
                  (pUraian == uraian || uraian.contains(pUraian) || pUraian.contains(uraian));

              if (matchId || matchNoMata || matchUraian) {
                final vStr = (p['volume'] ?? '').toString();
                final vNum = double.tryParse(vStr.split(' ').first.replaceAll(',', '.')) ?? 0.0;
                volReal += vNum;
              }
            }
          }

          final bbtItem = (volReal / volKontrak) * bbtKontrak;
          totalProgress += bbtItem;
        }
      }

      if (totalProgress > 0) {
        return totalProgress.clamp(0.0, 100.0);
      }
    }

    // 2. Fallback: Laporan Mingguan terakhir
    final rawMingguan = kegMap['laporanMingguan'];
    if (rawMingguan != null && rawMingguan is List && rawMingguan.isNotEmpty) {
      final latest = rawMingguan.last;
      if (latest is Map && latest['realisasiPersen'] != null) {
        final val = (latest['realisasiPersen'] as num).toDouble();
        if (val > 0) return val.clamp(0.0, 100.0);
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
  }) {
    if (kegiatans.isEmpty) {
      return (fallbackProgress > 1.0 ? fallbackProgress : fallbackProgress * 100.0).clamp(0.0, 100.0);
    }
    double sum = 0.0;
    for (final keg in kegiatans) {
      sum += calculateKegiatanProgress(keg);
    }
    return (sum / kegiatans.length).clamp(0.0, 100.0);
  }

  /// Menghitung rasio progres kontrak (skala 0.0 s.d. 1.0) untuk progress indicators.
  static double calculateContractProgressRatio(
    List<Map<String, dynamic>> kegiatans, {
    double fallbackProgress = 0.0,
  }) {
    final pct = calculateContractProgressPercent(kegiatans, fallbackProgress: fallbackProgress);
    return (pct / 100.0).clamp(0.0, 1.0);
  }
}
