import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/utils/indonesian_terbilang.dart';

class KegiatanModel {
  String namaKegiatan;
  String lokasi;
  String sumberDana;

  // KONSULTAN PENGAWAS
  String konsultanPengawas;
  String noSpkKonsultan;
  String tglSpkKonsultan;
  String noSpmkKonsultan;
  String tglSpmkKonsultan;
  String awalPelaksanaan;
  String akhirPelaksanaan;
  String masaPelaksanaan;
  String waktuBerjalan;

  // PENYEDIA JASA / KONTRAKTOR PELAKSANA
  String kontraktor;
  String noSuratPesanan;
  String tglSuratPesanan;
  String noSpmkKontraktor;
  String tglSpmkKontraktor;
  String nilaiKontrak;
  String jangkaWaktu;

  // STRUKTUR ORGANISASI KEGIATAN
  String penggunaAnggaran;
  String stafTeknis1;
  String stafTeknis2;
  String siteEngineerKegiatan;
  String direkturPenyedia;

  // STRUKTUR ORGANISASI PENYEDIA JASA
  String direkturKontraktor;
  String pelaksanaLapangan;
  String petugasK3;

  // Dokumen & Laporan
  List<Map<String, dynamic>> folders;
  List<dynamic> laporans;
  List<dynamic> laporanMingguan;

  KegiatanModel({
    required this.namaKegiatan,
    this.lokasi = '',
    this.sumberDana = '',
    this.konsultanPengawas = 'CV. TATA SAKA CONSULTANT',
    this.noSpkKonsultan = '',
    this.tglSpkKonsultan = '',
    this.noSpmkKonsultan = '',
    this.tglSpmkKonsultan = '',
    this.awalPelaksanaan = '',
    this.akhirPelaksanaan = '',
    this.masaPelaksanaan = '',
    this.waktuBerjalan = '',
    this.kontraktor = '',
    this.noSuratPesanan = '',
    this.tglSuratPesanan = '',
    this.noSpmkKontraktor = '',
    this.tglSpmkKontraktor = '',
    this.nilaiKontrak = '',
    this.jangkaWaktu = '',
    this.penggunaAnggaran = '',
    this.stafTeknis1 = '',
    this.stafTeknis2 = '',
    this.siteEngineerKegiatan = '',
    this.direkturPenyedia = '',
    this.direkturKontraktor = '',
    this.pelaksanaLapangan = '',
    this.petugasK3 = '',
    List<Map<String, dynamic>>? folders,
    List<dynamic>? laporans,
    List<dynamic>? laporanMingguan,
  })  : folders = folders ?? [
          {'name': 'Laporan Harian', 'isExpanded': false, 'documents': []},
          {'name': 'Laporan Mingguan', 'isExpanded': false, 'documents': []},
          {'name': 'Foto Progres', 'isExpanded': false, 'documents': []},
        ],
        laporans = laporans ?? [],
        laporanMingguan = laporanMingguan ?? [];

  /// Menghitung Waktu yang Telah Berjalan secara dinamis berdasarkan Awal Pelaksanaan vs Hari ini
  static String calculateWaktuBerjalan(String awalPelaksanaanStr) {
    final awalDt = WeeklyReportModel.parseIndonesianDate(awalPelaksanaanStr);
    if (awalDt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(awalDt.year, awalDt.month, awalDt.day);

    if (today.isBefore(start)) {
      return '0 (Nol) Minggu';
    }

    final diffDays = today.difference(start).inDays + 1;
    final weeks = (diffDays / 7).ceil();
    return IndonesianTerbilang.formatMinggu(weeks);
  }

  /// Format gabungan resmi: "000.3.2/.../2026 Tanggal 26 Mei 2026"
  String get spkKonsultanFull {
    final no = noSpkKonsultan.trim();
    final tgl = tglSpkKonsultan.trim();
    if (no.isEmpty && tgl.isEmpty) return '-';
    if (tgl.isEmpty) return no;
    if (no.isEmpty) return 'Tanggal $tgl';
    return '$no Tanggal $tgl';
  }

  /// Format gabungan resmi SPMK Konsultan: "000.3.2/.../2026 Tanggal 18 Juni 2026"
  String get spmkKonsultanFull {
    final no = noSpmkKonsultan.trim();
    final tgl = tglSpmkKonsultan.trim();
    if (no.isEmpty && tgl.isEmpty) return '-';
    if (tgl.isEmpty) return no;
    if (no.isEmpty) return 'Tanggal $tgl';
    return '$no Tanggal $tgl';
  }

  /// Format gabungan resmi Surat Pesanan Kontraktor: "EP-01... Tanggal 18 Juni 2026"
  String get suratPesananFull {
    final no = noSuratPesanan.trim();
    final tgl = tglSuratPesanan.trim();
    if (no.isEmpty && tgl.isEmpty) return '-';
    if (tgl.isEmpty) return no;
    if (no.isEmpty) return 'Tanggal $tgl';
    return '$no Tanggal $tgl';
  }

  /// Format gabungan resmi SPMK Kontraktor: "000.3.3 / ... Tanggal 18 Juni 2026"
  String get spmkKontraktorFull {
    final no = noSpmkKontraktor.trim();
    final tgl = tglSpmkKontraktor.trim();
    if (no.isEmpty && tgl.isEmpty) return '-';
    if (tgl.isEmpty) return no;
    if (no.isEmpty) return 'Tanggal $tgl';
    return '$no Tanggal $tgl';
  }

  /// Format gabungan staf teknis: "MUBALLIGH, ST.,M.Sc. & BILAL A.Md"
  String get stafTeknisDisplay {
    final s1 = stafTeknis1.trim();
    final s2 = stafTeknis2.trim();
    if (s1.isNotEmpty && s2.isNotEmpty) {
      return '$s1 & $s2';
    } else if (s1.isNotEmpty) {
      return s1;
    } else {
      return s2;
    }
  }

  String get stafTeknisLabel {
    final s1 = stafTeknis1.trim();
    final s2 = stafTeknis2.trim();
    if (s1.isNotEmpty && s2.isNotEmpty) {
      return 'Staf Teknis 1 & 2 DPU-PR';
    }
    return 'Staf Teknis DPU-PR';
  }

  factory KegiatanModel.fromJson(Map<String, dynamic> json, {ContractModel? fallbackContract}) {
    final namaKegiatan = json['namaKegiatan'] ?? '';
    final lokasi = json['lokasi'] ?? '';
    final sumberDana = (json['sumberDana'] != null && json['sumberDana'].toString().isNotEmpty)
        ? json['sumberDana'].toString()
        : (fallbackContract?.sumberDana ?? '');

    final konsultanPengawas = (json['konsultanPengawas'] != null && json['konsultanPengawas'].toString().isNotEmpty)
        ? json['konsultanPengawas'].toString()
        : 'CV. TATA SAKA CONSULTANT';

    final noSpkKonsultan = (json['noSpkKonsultan'] != null && json['noSpkKonsultan'].toString().isNotEmpty)
        ? json['noSpkKonsultan'].toString()
        : (fallbackContract?.nomorSpk ?? '');

    final tglSpkKonsultan = (json['tglSpkKonsultan'] != null && json['tglSpkKonsultan'].toString().isNotEmpty)
        ? json['tglSpkKonsultan'].toString()
        : (fallbackContract?.tglMulaiSpk ?? '');

    final noSpmkKonsultan = (json['noSpmkKonsultan'] != null && json['noSpmkKonsultan'].toString().isNotEmpty)
        ? json['noSpmkKonsultan'].toString()
        : (fallbackContract?.nomorSpmk ?? '');

    final tglSpmkKonsultan = (json['tglSpmkKonsultan'] != null && json['tglSpmkKonsultan'].toString().isNotEmpty)
        ? json['tglSpmkKonsultan'].toString()
        : (fallbackContract?.tglMulaiSpmk ?? '');

    final awalPelaksanaan = (json['awalPelaksanaan'] != null && json['awalPelaksanaan'].toString().isNotEmpty)
        ? json['awalPelaksanaan'].toString()
        : (fallbackContract?.tglMulaiSpmk ?? '');

    final akhirPelaksanaan = (json['akhirPelaksanaan'] != null && json['akhirPelaksanaan'].toString().isNotEmpty)
        ? json['akhirPelaksanaan'].toString()
        : (fallbackContract?.tglSelesaiSpmk ?? '');

    final masaPelaksanaan = (json['masaPelaksanaan'] != null && json['masaPelaksanaan'].toString().isNotEmpty)
        ? json['masaPelaksanaan'].toString()
        : (fallbackContract != null && fallbackContract.hariKalender > 0
            ? IndonesianTerbilang.formatHariKalender(fallbackContract.hariKalender)
            : '');

    final waktuBerjalan = (json['waktuBerjalan'] != null && json['waktuBerjalan'].toString().isNotEmpty)
        ? json['waktuBerjalan'].toString()
        : calculateWaktuBerjalan(awalPelaksanaan);

    final kontraktor = json['kontraktor'] ?? '';
    final noSuratPesanan = json['noSuratPesanan'] ?? '';
    final tglSuratPesanan = json['tglSuratPesanan'] ?? '';
    final noSpmkKontraktor = json['noSpmkKontraktor'] ?? '';
    final tglSpmkKontraktor = json['tglSpmkKontraktor'] ?? '';
    final nilaiKontrak = json['nilaiKontrak'] ?? '';

    final jangkaWaktu = (json['jangkaWaktu'] != null && json['jangkaWaktu'].toString().isNotEmpty)
        ? json['jangkaWaktu'].toString()
        : (fallbackContract != null && fallbackContract.hariKalender > 0
            ? IndonesianTerbilang.formatHariKalender(fallbackContract.hariKalender)
            : '');

    // Struktur Organisasi Kegiatan
    final penggunaAnggaran = json['penggunaAnggaran'] ??
        json['strukturOrganisasiKegiatan']?['penggunaAnggaran'] ??
        '';
    final stafTeknis1 = json['stafTeknis1'] ??
        json['stafTeknis'] ??
        json['strukturOrganisasiKegiatan']?['stafTeknis1'] ??
        json['strukturOrganisasiKegiatan']?['stafTeknis'] ??
        '';
    final stafTeknis2 = json['stafTeknis2'] ??
        json['strukturOrganisasiKegiatan']?['stafTeknis2'] ??
        '';
    final siteEngineerKegiatan = json['siteEngineerKegiatan'] ??
        json['siteEngineer'] ??
        json['strukturOrganisasiKegiatan']?['siteEngineer'] ??
        (fallbackContract?.siteEngineer ?? '');
    final direkturPenyedia = json['direkturPenyedia'] ??
        json['strukturOrganisasiKegiatan']?['direkturPenyedia'] ??
        json['direkturKontraktor'] ??
        json['direktur'] ??
        '';

    // Struktur Organisasi Penyedia Jasa
    final direkturKontraktor = json['direkturKontraktor'] ??
        json['direktur'] ??
        json['strukturPenyediaJasa']?['direktur'] ??
        direkturPenyedia;
    final pelaksanaLapangan = json['pelaksanaLapangan'] ??
        json['strukturPenyediaJasa']?['pelaksanaLapangan'] ??
        '';
    final petugasK3 = json['petugasK3'] ??
        json['ahliK3'] ??
        json['strukturPenyediaJasa']?['petugasK3'] ??
        '';

    return KegiatanModel(
      namaKegiatan: namaKegiatan,
      lokasi: lokasi,
      sumberDana: sumberDana,
      konsultanPengawas: konsultanPengawas,
      noSpkKonsultan: noSpkKonsultan,
      tglSpkKonsultan: tglSpkKonsultan,
      noSpmkKonsultan: noSpmkKonsultan,
      tglSpmkKonsultan: tglSpmkKonsultan,
      awalPelaksanaan: awalPelaksanaan,
      akhirPelaksanaan: akhirPelaksanaan,
      masaPelaksanaan: masaPelaksanaan,
      waktuBerjalan: waktuBerjalan,
      kontraktor: kontraktor,
      noSuratPesanan: noSuratPesanan,
      tglSuratPesanan: tglSuratPesanan,
      noSpmkKontraktor: noSpmkKontraktor,
      tglSpmkKontraktor: tglSpmkKontraktor,
      nilaiKontrak: nilaiKontrak,
      jangkaWaktu: jangkaWaktu,
      penggunaAnggaran: penggunaAnggaran,
      stafTeknis1: stafTeknis1,
      stafTeknis2: stafTeknis2,
      siteEngineerKegiatan: siteEngineerKegiatan,
      direkturPenyedia: direkturPenyedia,
      direkturKontraktor: direkturKontraktor,
      pelaksanaLapangan: pelaksanaLapangan,
      petugasK3: petugasK3,
      folders: json['folders'] != null ? List<Map<String, dynamic>>.from(json['folders']) : null,
      laporans: json['laporans'] != null ? List<dynamic>.from(json['laporans']) : null,
      laporanMingguan: json['laporanMingguan'] != null ? List<dynamic>.from(json['laporanMingguan']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'namaKegiatan': namaKegiatan,
      'lokasi': lokasi,
      'sumberDana': sumberDana,
      'konsultanPengawas': konsultanPengawas,
      'noSpkKonsultan': noSpkKonsultan,
      'tglSpkKonsultan': tglSpkKonsultan,
      'noSpmkKonsultan': noSpmkKonsultan,
      'tglSpmkKonsultan': tglSpmkKonsultan,
      'awalPelaksanaan': awalPelaksanaan,
      'akhirPelaksanaan': akhirPelaksanaan,
      'masaPelaksanaan': masaPelaksanaan,
      'waktuBerjalan': waktuBerjalan,
      'kontraktor': kontraktor,
      'noSuratPesanan': noSuratPesanan,
      'tglSuratPesanan': tglSuratPesanan,
      'noSpmkKontraktor': noSpmkKontraktor,
      'tglSpmkKontraktor': tglSpmkKontraktor,
      'nilaiKontrak': nilaiKontrak,
      'jangkaWaktu': jangkaWaktu,
      'penggunaAnggaran': penggunaAnggaran,
      'stafTeknis1': stafTeknis1,
      'stafTeknis2': stafTeknis2,
      'siteEngineerKegiatan': siteEngineerKegiatan,
      'direkturPenyedia': direkturPenyedia,
      'direkturKontraktor': direkturKontraktor,
      'pelaksanaLapangan': pelaksanaLapangan,
      'petugasK3': petugasK3,
      'strukturOrganisasiKegiatan': {
        'penggunaAnggaran': penggunaAnggaran,
        'stafTeknis1': stafTeknis1,
        'stafTeknis2': stafTeknis2,
        'siteEngineer': siteEngineerKegiatan,
        'direkturPenyedia': direkturPenyedia,
      },
      'strukturPenyediaJasa': {
        'direktur': direkturKontraktor,
        'pelaksanaLapangan': pelaksanaLapangan,
        'petugasK3': petugasK3,
      },
      'folders': folders,
      'laporans': laporans,
      'laporanMingguan': laporanMingguan,
    };
  }
}
