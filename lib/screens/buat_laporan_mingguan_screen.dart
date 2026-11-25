import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/utils/execution_period_helper.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';
import 'package:tata_saka_app/widgets/lembar_laporan_mingguan_widget.dart';
import 'package:tata_saka_app/widgets/lembar_boq_mingguan_widget.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/signature_pad_widget.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

/// Normalisasi status dokumen: nilai lama ('Normal', 'Rencana', dll)
/// dipetakan ke 'Kontrak' agar sesuai pilihan dropdown ('Kontrak'/'Adendum').
String _normalizeStatusDokumen(String s) {
  return s == 'Adendum' ? 'Adendum' : 'Kontrak';
}

class _TtdMingguanItem {
  final TextEditingController peranController;
  final TextEditingController instansiController;
  final TextEditingController namaController;
  final TextEditingController tanggalController;
  String? signatureBase64;

  _TtdMingguanItem({
    required String peran,
    required String instansi,
    required String nama,
    required String tanggal,
    this.signatureBase64,
  })  : peranController = TextEditingController(text: peran),
        instansiController = TextEditingController(text: instansi),
        namaController = TextEditingController(text: nama),
        tanggalController = TextEditingController(text: tanggal);

  void dispose() {
    peranController.dispose();
    instansiController.dispose();
    namaController.dispose();
    tanggalController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'peran': peranController.text.trim(),
      'instansi': instansiController.text.trim(),
      'nama': namaController.text.trim(),
      'tanggal': tanggalController.text.trim(),
      'signature': signatureBase64,
    };
  }
}

class BuatLaporanMingguanScreen extends StatefulWidget {
  final ContractModel? initialContract;
  final int? initialKegiatanIndex;
  final int? initialMingguKe;
  final WeeklyReportModel? editReport;
  final bool isEmbedded;

  const BuatLaporanMingguanScreen({
    super.key,
    this.initialContract,
    this.initialKegiatanIndex,
    this.initialMingguKe,
    this.editReport,
    this.isEmbedded = false,
  });

  @override
  State<BuatLaporanMingguanScreen> createState() => _BuatLaporanMingguanScreenState();
}

class _BuatLaporanMingguanScreenState extends State<BuatLaporanMingguanScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  ContractModel? _selectedContract;
  int? _selectedKegiatanIndex;
  String? _syncedFingerprint;

  // Metadata Controllers
  final TextEditingController _pekerjaanController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  final TextEditingController _kontraktorController = TextEditingController();
  final TextEditingController _jangkaWaktuController = TextEditingController();
  final TextEditingController _nomorKontrakController = TextEditingController();
  final TextEditingController _tanggalKontrakController = TextEditingController();
  final TextEditingController _nilaiKontrakController = TextEditingController();
  final TextEditingController _tanggalSpmkController = TextEditingController();

  // Status Dokumen (Kontrak / Adendum)
  String _statusDokumen = 'Kontrak';

  // Minggu Ke & Periode
  int _mingguKe = 1;
  int _totalMinggu = 1;
  final TextEditingController _periodeAwalController = TextEditingController();
  final TextEditingController _periodeAkhirController = TextEditingController();

  // Progress Rencana & Realisasi
  final TextEditingController _rencanaPersenController = TextEditingController();
  final TextEditingController _realisasiPersenController = TextEditingController();

  // Waktu & Akhir Masa Kontrak
  final TextEditingController _waktuTerpakaiController = TextEditingController();
  final TextEditingController _sisaWaktuController = TextEditingController();
  final TextEditingController _akhirMasaKontrakController = TextEditingController();

  // Calculated values
  double _nilaiKontrakNumeric = 0.0;
  double _rencanaPersen = 0.0;
  double _realisasiPersen = 0.0;
  double _realisasiMingguIni = 0.0;
  double get _deviasiPersen => _realisasiPersen - _rencanaPersen;
  double get _rencanaNominal => (_rencanaPersen / 100) * _nilaiKontrakNumeric;
  double get _realisasiNominal => (_realisasiPersen / 100) * _nilaiKontrakNumeric;
  double get _deviasiNominal => _realisasiNominal - _rencanaNominal;

  // Dynamic table of weeks
  List<WeeklyTableRow> _tabelMingguan = [];

  // Tanda Tangan & Pengesahan Digital Multi-Pihak
  final List<_TtdMingguanItem> _ttdList = [];

  void _addTtdRow({
    String peran = '',
    String instansi = '',
    String nama = '',
    String tanggal = '',
    String? signatureBase64,
  }) {
    setState(() {
      _ttdList.add(
        _TtdMingguanItem(
          peran: peran,
          instansi: instansi,
          nama: nama,
          tanggal: tanggal,
          signatureBase64: signatureBase64,
        ),
      );
    });
  }

  void _removeTtdRow(int index) {
    if (_ttdList.length > 1) {
      setState(() {
        _ttdList[index].dispose();
        _ttdList.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada 1 penandatangan.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Map<String, dynamic>? get _currentKegiatan {
    if (_selectedContract == null) return null;
    if (_selectedContract!.kegiatans.isEmpty) return null;
    final idx = _selectedKegiatanIndex ?? 0;
    if (idx < 0 || idx >= _selectedContract!.kegiatans.length) return null;
    return _selectedContract!.kegiatans[idx];
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _selectedContract = widget.initialContract;
    _selectedKegiatanIndex = widget.initialKegiatanIndex ?? 0;

    if (widget.editReport != null) {
      _loadFromExistingReport(widget.editReport!);
    } else {
      _initFromSelectedKegiatanData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pekerjaanController.dispose();
    _lokasiController.dispose();
    _kontraktorController.dispose();
    _jangkaWaktuController.dispose();
    _nomorKontrakController.dispose();
    _tanggalKontrakController.dispose();
    _nilaiKontrakController.dispose();
    _tanggalSpmkController.dispose();
    _periodeAwalController.dispose();
    _periodeAkhirController.dispose();
    _rencanaPersenController.dispose();
    _realisasiPersenController.dispose();
    _waktuTerpakaiController.dispose();
    _sisaWaktuController.dispose();
    _akhirMasaKontrakController.dispose();
    for (var item in _ttdList) {
      item.dispose();
    }
    _ttdList.clear();
    super.dispose();
  }

  String _computeFingerprint() {
    final c = _selectedContract;
    final k = _currentKegiatan;
    return '${c?.id}|$_selectedKegiatanIndex|${c?.tglMulaiSpmk}|${c?.tglSelesaiSpmk}|${c?.hariKalender}|'
        '${k?['tglSpmkKontraktor']}|${k?['awalPelaksanaan']}|${k?['akhirPelaksanaan']}|'
        '${k?['tglAkhirSpmkKontraktor']}|${k?['jangkaWaktu']}|${k?['masaPelaksanaan']}|'
        '${(k?['laporans'] as List?)?.length}|${(k?['laporanMingguan'] as List?)?.length}';
  }

  void _loadFromExistingReport(WeeklyReportModel r) {
    final c = _selectedContract;
    final keg = _currentKegiatan;
    final period = ExecutionPeriodHelper.resolveExecutionPeriod(keg, contract: c);

    final namaKeg = keg?['namaKegiatan']?.toString().trim() ?? '';
    _pekerjaanController.text = namaKeg.isNotEmpty ? namaKeg : r.pekerjaan;
    _lokasiController.text = (keg?['lokasi']?.toString().trim().isNotEmpty == true)
        ? keg!['lokasi'].toString()
        : r.lokasiProyek;
    _kontraktorController.text = (keg?['kontraktor']?.toString().trim().isNotEmpty == true)
        ? keg!['kontraktor'].toString()
        : r.kontraktor;

    final effectiveDays = (c != null || keg != null) && period.durationDays > 0
        ? period.durationDays
        : r.jangkaWaktu;
    _jangkaWaktuController.text = '$effectiveDays';

    final noSP = keg?['noSuratPesanan']?.toString().trim() ?? '';
    _nomorKontrakController.text = noSP.isNotEmpty
        ? noSP
        : (c != null && c.nomorSpk.isNotEmpty ? c.nomorSpk : r.nomorKontrak);

    final tglSP = keg?['tglSuratPesanan']?.toString().trim() ?? '';
    _tanggalKontrakController.text = tglSP.isNotEmpty
        ? tglSP
        : (c != null && c.tglMulaiSpk.isNotEmpty ? c.tglMulaiSpk : r.tanggalKontrak);

    final kegNilai = keg?['nilaiKontrak']?.toString().trim() ?? '';
    if (kegNilai.isNotEmpty) {
      _nilaiKontrakController.text = RupiahUtil.formatString(kegNilai);
      _nilaiKontrakNumeric = WeeklyReportModel.parseRupiah(_nilaiKontrakController.text);
    } else {
      _nilaiKontrakController.text = r.nilaiKontrak;
      _nilaiKontrakNumeric = r.nilaiKontrakNumeric;
    }

    _tanggalSpmkController.text =
        period.startFormatted.isNotEmpty ? period.startFormatted : r.tanggalSpmk;
    _akhirMasaKontrakController.text =
        period.endFormatted.isNotEmpty ? period.endFormatted : r.akhirMasaKontrak;

    _mingguKe = r.mingguKe;
    _totalMinggu = (c != null || keg != null) ? period.totalWeeks : r.totalMinggu;

    final range = _calcWeekDateRange(
      _mingguKe,
      period.startDate ?? WeeklyReportModel.parseIndonesianDate(_tanggalSpmkController.text),
      effectiveDays,
    );
    _periodeAwalController.text = range.tglMulaiIndo.isNotEmpty ? range.tglMulaiIndo : r.periodeAwal;
    _periodeAkhirController.text = range.tglSelesaiIndo.isNotEmpty ? range.tglSelesaiIndo : r.periodeAkhir;
    _waktuTerpakaiController.text = range.startDt != null ? '${range.elapsedDays}' : '${r.waktuTerpakai}';
    _sisaWaktuController.text = range.startDt != null ? '${range.remainingDays}' : '${r.sisaWaktu}';

    _rencanaPersen = r.rencanaPersen;
    _rencanaPersenController.text = _rencanaPersen > 0 ? _rencanaPersen.toStringAsFixed(3).replaceAll('.', ',') : '';

    if (keg != null) {
      final boqRes = ProgressCalculator.calculateBoqProgress(
        kegMap: keg,
        startDt: range.startDt,
        endDt: range.endDt,
        minStartDt: period.startDate,
      );
      _realisasiMingguIni = boqRes.totalBobotIni;
      _realisasiPersen = boqRes.totalBobotSdIni;
    } else {
      _realisasiPersen = r.realisasiPersen;
      _realisasiMingguIni = 0.0;
    }
    _realisasiPersenController.text = _realisasiPersen > 0 ? _realisasiPersen.toStringAsFixed(3).replaceAll('.', ',') : '0,000';

    _tabelMingguan = r.tabelMingguan.map((e) {
      final wr = _calcWeekDateRange(
        e.mingguKe,
        period.startDate ?? WeeklyReportModel.parseIndonesianDate(_tanggalSpmkController.text),
        effectiveDays,
      );
      return WeeklyTableRow(
        status: _normalizeStatusDokumen(e.status),
        mingguKe: e.mingguKe,
        tglMulai: wr.tglMulaiSlash.isNotEmpty ? wr.tglMulaiSlash : e.tglMulai,
        tglSelesai: wr.tglSelesaiSlash.isNotEmpty ? wr.tglSelesaiSlash : e.tglSelesai,
        rencana: e.rencana,
        realisasi: e.mingguKe == _mingguKe ? _realisasiPersen : e.realisasi,
      );
    }).toList();

    // Set status dari baris minggu saat ini
    final currentRow = _tabelMingguan.firstWhere(
      (tr) => tr.mingguKe == _mingguKe,
      orElse: () => WeeklyTableRow(status: 'Kontrak', mingguKe: _mingguKe, tglMulai: '', tglSelesai: ''),
    );
    _statusDokumen = _normalizeStatusDokumen(currentRow.status);

    // Muat data penandatangan dari laporan tersimpan
    for (var item in _ttdList) {
      item.dispose();
    }
    _ttdList.clear();

    final ttdRaw = r.ttdList;
    if (ttdRaw != null && ttdRaw.isNotEmpty) {
      for (var t in ttdRaw) {
        _addTtdRow(
          peran: t['peran']?.toString() ?? t['jabatan']?.toString() ?? '',
          instansi: t['instansi']?.toString() ?? '',
          nama: t['nama']?.toString() ?? '',
          tanggal: t['tanggal']?.toString() ?? _periodeAkhirController.text,
          signatureBase64: t['signature']?.toString(),
        );
      }
    } else {
      _addTtdRow(
        peran: 'Kontraktor Pelaksana',
        instansi: _kontraktorController.text,
        nama: r.ttdKontraktorNama ?? '',
        tanggal: r.ttdKontraktorTanggal ?? _periodeAkhirController.text,
        signatureBase64: r.ttdKontraktorSignature,
      );
      final namaKonsultan = keg?['konsultanPengawas']?.toString().trim() ?? '';
      final instansiDinas = (c != null && c.instansiDinas.isNotEmpty) ? c.instansiDinas.first : '';
      _addTtdRow(
        peran: 'Konsultan Supervisi',
        instansi: namaKonsultan,
        nama: r.ttdKonsultanNama ?? '',
        tanggal: r.ttdKonsultanTanggal ?? _periodeAkhirController.text,
        signatureBase64: r.ttdKonsultanSignature,
      );
      _addTtdRow(
        peran: 'Pejabat Pembuat Komitmen (PPK)',
        instansi: instansiDinas,
        nama: r.ttdPpkNama ?? '',
        tanggal: r.ttdPpkTanggal ?? _periodeAkhirController.text,
        signatureBase64: r.ttdPpkSignature,
      );
    }
    _syncedFingerprint = _computeFingerprint();
  }

  void _initFromSelectedKegiatanData() {
    final c = _selectedContract;
    final keg = _currentKegiatan;

    if (c != null && keg != null) {
      // 1. Pekerjaan: ambil otomatis dari nama kegiatan
      final namaKeg = keg['namaKegiatan']?.toString().trim() ?? '';
      _pekerjaanController.text = namaKeg.isNotEmpty ? namaKeg : c.namaKontrak;

      // 2. Lokasi proyek & Kontraktor pelaksana: dari kegiatan
      _lokasiController.text = keg['lokasi']?.toString() ?? '';
      _kontraktorController.text = keg['kontraktor']?.toString() ?? '';

      // 3. Nilai Kontrak: ambil dari nilai kontrak kegiatan (bukan kontrak induk konsultan)
      final kegNilai = keg['nilaiKontrak']?.toString().trim() ?? '';
      _nilaiKontrakController.text = RupiahUtil.formatString(kegNilai.isNotEmpty ? kegNilai : c.nilaiKontrak);
      _nilaiKontrakNumeric = WeeklyReportModel.parseRupiah(_nilaiKontrakController.text);

      // 4. Jangka Waktu, Nomor Kontrak, Tanggal Kontrak, SPMK, Akhir Masa Kontrak (Single Source of Truth)
      final period = ExecutionPeriodHelper.resolveExecutionPeriod(keg, contract: c);
      _jangkaWaktuController.text = '${period.durationDays}';

      final noSP = keg['noSuratPesanan']?.toString().trim() ?? '';
      _nomorKontrakController.text = noSP.isNotEmpty ? noSP : (c.nomorSpk.isNotEmpty ? c.nomorSpk : c.nomorSpmk);

      final tglSP = keg['tglSuratPesanan']?.toString().trim() ?? '';
      _tanggalKontrakController.text = tglSP.isNotEmpty ? tglSP : c.tglMulaiSpk;

      _tanggalSpmkController.text = period.startFormatted;
      _akhirMasaKontrakController.text = period.endFormatted;

      _autoBuildWeeklyTableAndState();
    } else if (c != null) {
      final period = ExecutionPeriodHelper.resolveExecutionPeriod(null, contract: c);
      _pekerjaanController.text = c.namaKontrak;
      _lokasiController.text = '';
      _kontraktorController.text = '';
      _jangkaWaktuController.text = '${period.durationDays}';
      _nomorKontrakController.text = c.nomorSpk.isNotEmpty ? c.nomorSpk : c.nomorSpmk;
      _tanggalKontrakController.text = c.tglMulaiSpk;
      _nilaiKontrakController.text = c.nilaiKontrak;
      _nilaiKontrakNumeric = WeeklyReportModel.parseRupiah(c.nilaiKontrak);
      _tanggalSpmkController.text = period.startFormatted;
      _akhirMasaKontrakController.text = period.endFormatted;
      _autoBuildWeeklyTableAndState();
    } else {
      _pekerjaanController.text = '';
      _lokasiController.text = '';
      _kontraktorController.text = '';
      _jangkaWaktuController.text = '90';
      _nomorKontrakController.text = '';
      _tanggalKontrakController.text = '';
      _nilaiKontrakController.text = '';
      _nilaiKontrakNumeric = 0.0;
      _tanggalSpmkController.text = '';
      _akhirMasaKontrakController.text = '';
      _totalMinggu = 13;
      _tabelMingguan = [];
    }

    // Inisialisasi daftar penandatangan default (3 Pihak)
    for (var item in _ttdList) {
      item.dispose();
    }
    _ttdList.clear();

    _addTtdRow(
      peran: 'Kontraktor Pelaksana',
      instansi: _kontraktorController.text.trim(),
      nama: '',
      tanggal: _periodeAkhirController.text.trim(),
    );
    final namaKonsultan = keg?['konsultanPengawas']?.toString().trim() ?? '';
    final instansiDinas = (c != null && c.instansiDinas.isNotEmpty) ? c.instansiDinas.first : '';

    _addTtdRow(
      peran: 'Konsultan Supervisi',
      instansi: namaKonsultan,
      nama: '',
      tanggal: _periodeAkhirController.text.trim(),
    );
    _addTtdRow(
      peran: 'Pejabat Pembuat Komitmen (PPK)',
      instansi: instansiDinas,
      nama: '',
      tanggal: _periodeAkhirController.text.trim(),
    );
    _syncedFingerprint = _computeFingerprint();
  }

  /// Kalkulasi rentang tanggal dan durasi hari per minggu kalender murni (tanpa hari libur).
  WeekDateRange _calcWeekDateRange(int w, DateTime? spmkDt, int totalDays) {
    return ExecutionPeriodHelper.calcWeekRange(w, spmkDt, totalDays);
  }

  Future<void> _pickDateForWeekly(TextEditingController controller, {bool isSpmk = false}) async {
    final firstDate = DateTime(2015);
    final lastDate = DateTime(2040);
    DateTime initial = DateTime.now();
    final parsed = WeeklyReportModel.parseIndonesianDate(controller.text);
    if (parsed != null) {
      initial = parsed;
    }
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navySlate,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        controller.text = WeeklyReportModel.formatIndonesianDate(picked);
        if (isSpmk) {
          final totalDays = int.tryParse(_jangkaWaktuController.text) ?? 90;
          if (totalDays > 0) {
            final endDt = picked.add(Duration(days: totalDays - 1));
            _akhirMasaKontrakController.text = WeeklyReportModel.formatIndonesianDate(endDt);
          }
          _autoBuildWeeklyTableAndState();
        }
      });
    }
  }

  /// Membangun otomatis tabel bobot mingguan (1 s/d totalMinggu) dengan mengompilasi
  /// riwayat laporan mingguan yang selaras dengan jadwal aktif kegiatan ini.
  void _autoBuildWeeklyTableAndState() {
    final keg = _currentKegiatan;
    final period = ExecutionPeriodHelper.resolveExecutionPeriod(
      keg,
      contract: _selectedContract,
    );
    final spmkDt = WeeklyReportModel.parseIndonesianDate(_tanggalSpmkController.text) ??
        period.startDate;
    final totalDays = int.tryParse(_jangkaWaktuController.text) ?? period.durationDays;
    _totalMinggu = totalDays > 0 ? (totalDays / 7).ceil() : 1;
    if (_totalMinggu < 1) _totalMinggu = 1;

    // Ambil riwayat laporan mingguan tersimpan yang selaras dengan jadwal aktif
    final Map<int, WeeklyReportModel> savedReportsByWeek = {};
    if (keg != null && keg['laporanMingguan'] != null) {
      for (var item in (keg['laporanMingguan'] as List<dynamic>)) {
        try {
          final r = WeeklyReportModel.fromJson(Map<String, dynamic>.from(item));
          final wRange = _calcWeekDateRange(r.mingguKe, spmkDt, totalDays);
          if (ExecutionPeriodHelper.doesSavedWeeklyMatchRange(r, wRange)) {
            savedReportsByWeek[r.mingguKe] = r;
          }
        } catch (_) {}
      }
    }

    // Tentukan minggu aktif yang dilaporkan
    if (widget.editReport != null) {
      _mingguKe = widget.editReport!.mingguKe.clamp(1, max(1, _totalMinggu));
    } else if (widget.initialMingguKe != null) {
      _mingguKe = widget.initialMingguKe!.clamp(1, max(1, _totalMinggu));
    } else {
      // Cari minggu pertama yang belum terisi, atau minggu setelah minggu terakhir yang terisi
      int nextWeek = 1;
      for (int w = 1; w <= _totalMinggu; w++) {
        if (!savedReportsByWeek.containsKey(w)) {
          nextWeek = w;
          break;
        }
        if (w == _totalMinggu) nextWeek = _totalMinggu;
      }
      _mingguKe = nextWeek;
    }

    // Bangun baris 1 s/d totalMinggu secara otomatis
    final List<WeeklyTableRow> rows = [];
    for (int w = 1; w <= _totalMinggu; w++) {
      final range = _calcWeekDateRange(w, spmkDt, totalDays);
      String status = 'Kontrak';
      double? rencana;
      double? realisasi;

      if (savedReportsByWeek.containsKey(w)) {
        final saved = savedReportsByWeek[w]!;
        final match = saved.tabelMingguan.firstWhere(
          (tr) => tr.mingguKe == w,
          orElse: () => WeeklyTableRow(
            status: 'Kontrak',
            mingguKe: w,
            tglMulai: range.tglMulaiSlash,
            tglSelesai: range.tglSelesaiSlash,
            rencana: saved.rencanaPersen,
            realisasi: saved.realisasiPersen,
          ),
        );
        status = _normalizeStatusDokumen(match.status);
        rencana = saved.rencanaPersen;
        realisasi = saved.realisasiPersen;
      } else if (widget.editReport != null && widget.editReport!.mingguKe == w) {
        rencana = widget.editReport!.rencanaPersen;
        realisasi = widget.editReport!.realisasiPersen;
        final match = widget.editReport!.tabelMingguan.firstWhere(
          (tr) => tr.mingguKe == w,
          orElse: () => WeeklyTableRow(
            status: 'Kontrak',
            mingguKe: w,
            tglMulai: range.tglMulaiSlash,
            tglSelesai: range.tglSelesaiSlash,
          ),
        );
        status = _normalizeStatusDokumen(match.status);
      }

      // Selalu perbarui realisasi dengan data agregasi terbaru dari Laporan Harian
      if (keg != null) {
        final boqWeek = ProgressCalculator.calculateBoqProgress(
          kegMap: keg,
          startDt: range.startDt,
          endDt: range.endDt,
          minStartDt: spmkDt,
        );
        if (boqWeek.totalBobotSdIni > 0) {
          realisasi = boqWeek.totalBobotSdIni;
        }
      }

      rows.add(WeeklyTableRow(
        status: status,
        mingguKe: w,
        tglMulai: range.tglMulaiSlash,
        tglSelesai: range.tglSelesaiSlash,
        rencana: rencana,
        realisasi: realisasi,
      ));
    }

    _tabelMingguan = rows;
    _syncWeekLogic(_mingguKe);
  }

  /// Sinkronisasi field input atas saat memilih minggu tertentu
  void _syncWeekLogic(int targetWeek) {
    _mingguKe = targetWeek;

    final spmkDt = WeeklyReportModel.parseIndonesianDate(_tanggalSpmkController.text);
    final totalDays = int.tryParse(_jangkaWaktuController.text) ?? 90;

    final range = _calcWeekDateRange(targetWeek, spmkDt, totalDays);
    _periodeAwalController.text = range.tglMulaiIndo;
    _periodeAkhirController.text = range.tglSelesaiIndo;
    _waktuTerpakaiController.text = '${range.elapsedDays}';
    _sisaWaktuController.text = '${range.remainingDays}';

    // Cari baris di tabel mingguan
    WeeklyTableRow? row;
    for (var r in _tabelMingguan) {
      if (r.mingguKe == targetWeek) {
        row = r;
        break;
      }
    }

    if (row != null) {
      _statusDokumen = _normalizeStatusDokumen(row.status);

      if (row.rencana != null) {
        _rencanaPersen = row.rencana!;
        _rencanaPersenController.text = _rencanaPersen.toStringAsFixed(3).replaceAll('.', ',');
      } else {
        _rencanaPersen = 0.0;
        _rencanaPersenController.text = '';
      }
    } else {
      _statusDokumen = 'Kontrak';
      _rencanaPersen = 0.0;
      _rencanaPersenController.text = '';
    }

    // Otomatis hitung agregasi realisasi bobot dari Laporan Harian untuk minggu ini dan s/d minggu ini
    final keg = _currentKegiatan;
    if (keg != null) {
      final boqRes = ProgressCalculator.calculateBoqProgress(
        kegMap: keg,
        startDt: range.startDt,
        endDt: range.endDt,
        minStartDt: spmkDt,
      );
      _realisasiMingguIni = boqRes.totalBobotIni;
      _realisasiPersen = boqRes.totalBobotSdIni;
      _realisasiPersenController.text = _realisasiPersen > 0
          ? _realisasiPersen.toStringAsFixed(3).replaceAll('.', ',')
          : '0,000';
      if (row != null) {
        row.realisasi = _realisasiPersen;
      }
    } else {
      _realisasiMingguIni = 0.0;
      _realisasiPersen = 0.0;
      _realisasiPersenController.text = '0,000';
    }

    if (mounted) {
      setState(() {});
    }
  }

  double _calcAutoRealisasiBobot(DateTime? endDt) {
    final keg = _currentKegiatan;
    if (keg == null) return 0.0;
    final boqRes = ProgressCalculator.calculateBoqProgress(
      kegMap: keg,
      startDt: null,
      endDt: endDt,
    );
    return boqRes.totalBobotSdIni;
  }

  void _onStatusDokumenChanged(String newStatus) {
    setState(() {
      _statusDokumen = newStatus;
      for (var r in _tabelMingguan) {
        if (r.mingguKe == _mingguKe) {
          r.status = newStatus;
          break;
        }
      }
    });
  }

  void _onRencanaInputChanged(String val) {
    final clean = val.replaceAll(',', '.').trim();
    final parsed = double.tryParse(clean);
    setState(() {
      _rencanaPersen = parsed ?? 0.0;
      for (var r in _tabelMingguan) {
        if (r.mingguKe == _mingguKe) {
          r.rencana = parsed;
          break;
        }
      }
    });
  }

  void _onRealisasiInputChanged(String val) {
    // Realisasi dihitung otomatis dari Laporan Harian
  }

  List<Map<String, dynamic>> _buildBoqProgressSnapshot({
    required Map<String, dynamic> keg,
    required DateTime? startDt,
    required DateTime? endDt,
    DateTime? minStartDt,
  }) {
    final boqRes = ProgressCalculator.calculateBoqProgress(
      kegMap: keg,
      startDt: startDt,
      endDt: endDt,
      minStartDt: minStartDt,
    );
    return boqRes.divisiList;
  }

  WeeklyReportModel _buildReportObject() {
    final startDt = WeeklyReportModel.parseIndonesianDate(_periodeAwalController.text.trim());
    final endDt = WeeklyReportModel.parseIndonesianDate(_periodeAkhirController.text.trim());
    final spmkDt = WeeklyReportModel.parseIndonesianDate(_tanggalSpmkController.text.trim());
    final keg = _currentKegiatan;
    final List<Map<String, dynamic>>? boqSnapshot = keg != null
        ? _buildBoqProgressSnapshot(
            keg: keg,
            startDt: startDt,
            endDt: endDt,
            minStartDt: spmkDt,
          )
        : null;

    final cleanTtdList = _ttdList.map((item) => item.toMap()).toList();
    final ttdKontraktor = _ttdList.isNotEmpty ? _ttdList[0] : null;
    final ttdKonsultan = _ttdList.length > 1 ? _ttdList[1] : null;
    final ttdPpk = _ttdList.length > 2 ? _ttdList[2] : null;

    return WeeklyReportModel(
      id: widget.editReport?.id ?? 'weekly-${DateTime.now().millisecondsSinceEpoch}',
      pekerjaan: _pekerjaanController.text.trim(),
      lokasiProyek: _lokasiController.text.trim(),
      kontraktor: _kontraktorController.text.trim(),
      jangkaWaktu: int.tryParse(_jangkaWaktuController.text) ?? 90,
      nomorKontrak: _nomorKontrakController.text.trim(),
      tanggalKontrak: _tanggalKontrakController.text.trim(),
      nilaiKontrak: _nilaiKontrakController.text.trim().startsWith('Rp')
          ? _nilaiKontrakController.text.trim()
          : (_nilaiKontrakController.text.trim().isNotEmpty
              ? 'Rp ${_nilaiKontrakController.text.trim()}'
              : ''),
      nilaiKontrakNumeric: _nilaiKontrakNumeric,
      tanggalSpmk: _tanggalSpmkController.text.trim(),
      mingguKe: _mingguKe,
      totalMinggu: _totalMinggu,
      periodeAwal: _periodeAwalController.text.trim(),
      periodeAkhir: _periodeAkhirController.text.trim(),
      rencanaPersen: _rencanaPersen,
      rencanaNominal: _rencanaNominal,
      realisasiPersen: _realisasiPersen,
      realisasiNominal: _realisasiNominal,
      deviasiPersen: _deviasiPersen,
      deviasiNominal: _deviasiNominal,
      waktuTerpakai: int.tryParse(_waktuTerpakaiController.text) ?? 0,
      sisaWaktu: int.tryParse(_sisaWaktuController.text) ?? 0,
      akhirMasaKontrak: _akhirMasaKontrakController.text.trim(),
      tabelMingguan: _tabelMingguan,
      boqProgressList: boqSnapshot,
      ttdList: cleanTtdList,
      ttdKontraktorNama: ttdKontraktor?.namaController.text.trim(),
      ttdKontraktorJabatan: ttdKontraktor?.peranController.text.trim(),
      ttdKontraktorSignature: ttdKontraktor?.signatureBase64,
      ttdKontraktorTanggal: ttdKontraktor?.tanggalController.text.trim(),
      ttdKonsultanNama: ttdKonsultan?.namaController.text.trim(),
      ttdKonsultanJabatan: ttdKonsultan?.peranController.text.trim(),
      ttdKonsultanSignature: ttdKonsultan?.signatureBase64,
      ttdKonsultanTanggal: ttdKonsultan?.tanggalController.text.trim(),
      ttdPpkNama: ttdPpk?.namaController.text.trim(),
      ttdPpkJabatan: ttdPpk?.peranController.text.trim(),
      ttdPpkSignature: ttdPpk?.signatureBase64,
      ttdPpkTanggal: ttdPpk?.tanggalController.text.trim(),
    );
  }

  void _simpanLaporanMingguan() {
    final provider = Provider.of<ContractProvider>(context, listen: false);

    if (_selectedContract == null && provider.contracts.isNotEmpty) {
      _selectedContract = provider.contracts.first;
    }

    if (_selectedContract == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kegiatan terlebih dahulu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final keg = _currentKegiatan;
    if (keg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kegiatan tidak ditemukan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final reportObj = _buildReportObject();
    final reportMap = reportObj.toJson();

    List<dynamic> existingWeekly = List.from(keg['laporanMingguan'] ?? []);
    final spmkDt = WeeklyReportModel.parseIndonesianDate(_tanggalSpmkController.text);
    final activeRange = _calcWeekDateRange(reportObj.mingguKe, spmkDt, reportObj.jangkaWaktu);
    // Cek apakah laporan untuk minggu & jadwal aktif ini sudah ada
    final idx = existingWeekly.indexWhere((r) {
      if (r is! Map) return false;
      if (r['id'] == reportObj.id) return true;
      if (r['mingguKe'] == reportObj.mingguKe) {
        final parsed = WeeklyReportModel.fromJson(Map<String, dynamic>.from(r));
        return ExecutionPeriodHelper.doesSavedWeeklyMatchRange(parsed, activeRange);
      }
      return false;
    });
    if (idx >= 0) {
      existingWeekly[idx] = reportMap;
    } else {
      existingWeekly.add(reportMap);
    }

    // Urutkan berdasarkan mingguKe
    existingWeekly.sort((a, b) {
      final wA = (a['mingguKe'] is int) ? a['mingguKe'] : int.tryParse(a['mingguKe']?.toString() ?? '1') ?? 1;
      final wB = (b['mingguKe'] is int) ? b['mingguKe'] : int.tryParse(b['mingguKe']?.toString() ?? '1') ?? 1;
      return (wA as int).compareTo(wB as int);
    });

    keg['laporanMingguan'] = existingWeekly;

    // Sinkronisasi progress fisik kegiatan jika realisasi tersedia
    if (reportObj.realisasiPersen > 0) {
      keg['progressFisik'] = reportObj.realisasiPersen / 100.0;
    }

    provider.updateContract(_selectedContract!);

    try {
      final timeline = Provider.of<TimelineProvider>(context, listen: false);
      final kName = keg['namaKegiatan']?.toString() ?? '';
      final kontraktor = keg['kontraktor']?.toString() ?? '';
      final dinas = _selectedContract!.instansiDinas.isNotEmpty
          ? _selectedContract!.instansiDinas.first
          : 'DPU-PR Kab. Purbalingga';
      final isEdit = widget.editReport != null;
      timeline.logEvent(
        actorName: 'CV. Tata Saka Consultant',
        actionType: isEdit ? 'UPDATE' : 'CREATE',
        entityType: 'LAPORAN_MINGGUAN',
        contractId: _selectedContract!.id,
        contractName: _selectedContract!.namaKontrak,
        kegiatanName: kName,
        kontraktorName: kontraktor,
        dinasName: dinas,
        title: isEdit
            ? 'Pembaruan Laporan Mingguan ke-$_mingguKe: $kName'
            : 'Penerbitan Laporan Mingguan ke-$_mingguKe: $kName',
        description:
            'Laporan Mingguan Periode ${reportObj.periodeAwal} s/d ${reportObj.periodeAkhir} dengan progres kumulatif ${reportObj.realisasiPersen.toStringAsFixed(2)}%.',
        metadata: {
          'mingguKe': _mingguKe,
          'realisasi': reportObj.realisasiPersen,
          'rencana': reportObj.rencanaPersen,
          'deviasi': reportObj.deviasiPersen,
        },
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.editReport != null
              ? 'Ringkasan Laporan Mingguan (Minggu $_mingguKe) berhasil diperbarui!'
              : 'Ringkasan Laporan Mingguan (Minggu $_mingguKe) berhasil disimpan!',
        ),
        backgroundColor: AppColors.successGreen,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);
    final contracts = provider.contracts;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final pageTitle = widget.editReport != null ? 'Edit Ringkasan Laporan Mingguan' : 'Ringkasan Laporan Mingguan';

    if (_selectedContract == null && contracts.isNotEmpty && widget.editReport == null) {
      _selectedContract = contracts.first;
      _selectedKegiatanIndex = _selectedContract!.kegiatans.isNotEmpty ? 0 : null;
      _initFromSelectedKegiatanData();
    } else if (_selectedContract != null && contracts.isNotEmpty) {
      final fresh = contracts.cast<ContractModel?>().firstWhere(
        (c) => c?.id == _selectedContract!.id,
        orElse: () => null,
      );
      if (fresh != null) {
        _selectedContract = fresh;
        if (_selectedKegiatanIndex != null &&
            _selectedKegiatanIndex! >= fresh.kegiatans.length) {
          _selectedKegiatanIndex = fresh.kegiatans.isNotEmpty ? 0 : null;
        }
        final fp = _computeFingerprint();
        if (_syncedFingerprint != null && _syncedFingerprint != fp) {
          _syncedFingerprint = fp;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            if (widget.editReport != null) {
              _loadFromExistingReport(widget.editReport!);
            } else {
              _initFromSelectedKegiatanData();
            }
          });
        }
      }
    }

    final saveButton = Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton(
        onPressed: _simpanLaporanMingguan,
        style: TextButton.styleFrom(
          backgroundColor: isDesktop ? AppColors.primaryBlue : const Color(0xFF1F2937),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'Simpan',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
        ),
      ),
    );

    final tabBarWidget = Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF111827),
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: const Color(0xFF1F2937),
        indicatorWeight: 2.5,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: const [
          Tab(icon: Icon(Icons.edit_note, size: 20), text: 'Form Input'),
          Tab(icon: Icon(Icons.description_outlined, size: 20), text: 'Pratinjau Dokumen Fisik'),
        ],
      ),
    );

    final mainBody = Column(
      children: [
        if (isDesktop || widget.isEmbedded) ...[
          tabBarWidget,
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildFormInputTab(contracts),
              _buildPreviewTab(),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return mainBody;
    }

    if (isDesktop) {
      return WebDashboardLayout(
        title: pageTitle,
        activeMenu: 'laporan',
        showBackButton: true,
        actions: [saveButton],
        child: mainBody,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
            }
          },
        ),
        title: Text(
          pageTitle,
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [saveButton],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF111827),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFF1F2937),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.edit_note, size: 20), text: 'Form Input'),
            Tab(icon: Icon(Icons.description_outlined, size: 20), text: 'Pratinjau Dokumen Fisik'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: FORM INPUT INTERAKTIF
          _buildFormInputTab(contracts),

          // TAB 2: PRATINJAU DOKUMEN FISIK ASLI
          _buildPreviewTab(),
        ],
      ),
    );
  }

  Widget _buildFormInputTab(List<ContractModel> contracts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SELECTOR KONTRAK & KEGIATAN
          _buildContractAndKegiatanSelector(contracts),
          const SizedBox(height: 16),

          // 2. KOTAK INFORMASI DATA POKOK KONTRAK KEGIATAN (AUTO-FILLED)
          _buildContractInfoForm(),
          const SizedBox(height: 16),

          // 3. MINGGU KE-, STATUS DOKUMEN & PERIODE
          _buildMingguDanPeriodeSection(),
          const SizedBox(height: 16),

          // 4. BOBOT FISIK RENCANA, REALISASI, DEVIASI DENGAN RUPIAH KEGIATAN
          _buildBobotFisikSection(),
          const SizedBox(height: 16),

          // 5. WAKTU PELAKSANAAN PROYEK (PURE LOGIC AUTO)
          _buildWaktuSection(),
          const SizedBox(height: 24),

          // 6. TANDA TANGAN & PENGESAHAN DOKUMEN (CANVAS MULTI-SIGNERS)
          _buildTandaTanganSection(),
          const SizedBox(height: 24),

          // TOMBOL SIMPAN
          _buildSaveButton(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    final reportObj = _buildReportObject();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF1D4ED8), size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tampilan di bawah adalah pratinjau lembar cetak fisik 1:1 format resmi dokumen dinas PU.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LembarLaporanMingguanWidget(
            report: reportObj,
          ),
          const SizedBox(height: 24),
          LembarBoqMingguanWidget(
            report: reportObj,
            kegiatan: (_selectedContract?.kegiatans.isNotEmpty == true && _selectedKegiatanIndex != null && _selectedKegiatanIndex! < _selectedContract!.kegiatans.length)
                ? _selectedContract!.kegiatans[_selectedKegiatanIndex!]
                : null,
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  // 1. Selector Kontrak & Kegiatan (2 Dropdown Terpisah, Bebas Terpotong di Layar HP)
  Widget _buildContractAndKegiatanSelector(List<ContractModel> contracts) {
    if (contracts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada kontrak yang terdaftar pada sistem. Tambahkan kontrak terlebih dahulu di menu Kontrak.',
                style: TextStyle(color: Color(0xFF92400E), fontSize: 12.5, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    final currentContract = (_selectedContract != null && contracts.any((c) => c.id == _selectedContract!.id))
        ? contracts.firstWhere((c) => c.id == _selectedContract!.id)
        : contracts.first;

    final kegiatans = currentContract.kegiatans;

    return _buildCard(
      title: 'Pilih Kontrak & Kegiatan Proyek',
      badge: 'Terintegrasi',
      children: [
        // Dropdown 1: Kontrak
        const Text(
          'Kontrak *',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.3),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: currentContract.id,
          isExpanded: true,
          decoration: _cleanInputDec('Pilih Kontrak'),
          items: contracts.map((c) {
            return DropdownMenuItem<String>(
              value: c.id,
              child: Text(
                c.namaKontrak,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w500),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              final chosen = contracts.firstWhere((c) => c.id == val);
              setState(() {
                _selectedContract = chosen;
                _selectedKegiatanIndex = chosen.kegiatans.isNotEmpty ? 0 : null;
                _initFromSelectedKegiatanData();
              });
            }
          },
        ),
        const SizedBox(height: 14),

        // Dropdown 2: Kegiatan
        const Text(
          'Kegiatan *',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.3),
        ),
        const SizedBox(height: 6),
        if (kegiatans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text(
              'Belum ada kegiatan pada kontrak ini.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          )
        else
          DropdownButtonFormField<int>(
            value: (_selectedKegiatanIndex != null && _selectedKegiatanIndex! < kegiatans.length)
                ? _selectedKegiatanIndex
                : 0,
            isExpanded: true,
            decoration: _cleanInputDec('Pilih Kegiatan'),
            items: kegiatans.asMap().entries.map((entry) {
              final k = entry.value;
              final namaKeg = (k['namaKegiatan']?.toString().trim().isNotEmpty == true)
                  ? k['namaKegiatan'].toString()
                  : 'Kegiatan ${entry.key + 1}';
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(
                  namaKeg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF111827), fontWeight: FontWeight.w500),
                ),
              );
            }).toList(),
            onChanged: (idx) {
              if (idx != null) {
                setState(() {
                  _selectedKegiatanIndex = idx;
                  _initFromSelectedKegiatanData();
                });
              }
            },
          ),
      ],
    );
  }

  // 2. Data Pokok Kontrak Kegiatan (Auto-Filled)
  Widget _buildContractInfoForm() {
    return _buildCard(
      title: 'Data Pokok Kontrak Kegiatan',
      badge: 'Terintegrasi',
      children: [
        _buildField(
          controller: _pekerjaanController,
          label: 'Pekerjaan (Nama Kegiatan)',
          hintText: 'Otomatis dari kegiatan',
          readOnly: true,
          isBold: true,
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField(
                controller: _lokasiController,
                label: 'Lokasi Proyek',
                hintText: 'Kecamatan / Lokasi',
                readOnly: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                controller: _kontraktorController,
                label: 'Kontraktor Pelaksana',
                hintText: 'Nama Kontraktor',
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField(
                controller: _jangkaWaktuController,
                label: 'Jangka Waktu Kontrak',
                suffixText: 'Hari Kalender',
                keyboardType: TextInputType.number,
                onChanged: (val) {
                  final d = int.tryParse(val) ?? 90;
                  setState(() {
                    _totalMinggu = (d / 7).ceil();
                    if (_totalMinggu < 1) _totalMinggu = 1;
                    _autoBuildWeeklyTableAndState();
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                controller: _nomorKontrakController,
                label: 'Nomor Kontrak (SPK)',
                hintText: 'Nomor SPK Kontrak',
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField(
                controller: _tanggalKontrakController,
                label: 'Tanggal Kontrak (SPK)',
                hintText: '20 April 2026',
                readOnly: true,
                onTap: () => _pickDateForWeekly(_tanggalKontrakController),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF6B7280), size: 18),
                  onPressed: () => _pickDateForWeekly(_tanggalKontrakController),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                controller: _nilaiKontrakController,
                label: 'Nilai Kontrak Kegiatan',
                hintText: '0',
                prefixText: 'Rp ',
                keyboardType: TextInputType.number,
                inputFormatters: [RupiahInputFormatter()],
                onChanged: (val) {
                  setState(() {
                    _nilaiKontrakNumeric = WeeklyReportModel.parseRupiah(val);
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildField(
                controller: _tanggalSpmkController,
                label: 'Tanggal SPMK',
                hintText: '20 April 2026',
                readOnly: true,
                onTap: () => _pickDateForWeekly(_tanggalSpmkController, isSpmk: true),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF6B7280), size: 18),
                  onPressed: () => _pickDateForWeekly(_tanggalSpmkController, isSpmk: true),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildField(
                controller: _akhirMasaKontrakController,
                label: 'Akhir Masa Kontrak',
                hintText: '18 Juli 2026',
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Periode & Status Pelaksanaan (Kalender Murni)
  Widget _buildMingguDanPeriodeSection() {
    final spmkDt = WeeklyReportModel.parseIndonesianDate(_tanggalSpmkController.text);
    final totalDays = int.tryParse(_jangkaWaktuController.text) ?? 90;
    final curRange = _calcWeekDateRange(_mingguKe, spmkDt, totalDays);

    return _buildCard(
      title: 'Periode Pelaksanaan & Status',
      badge: 'Minggu $_mingguKe / $_totalMinggu',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pilihan Minggu Ke
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Laporan Minggu Ke - *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    value: _mingguKe.clamp(1, max(1, _totalMinggu)),
                    isExpanded: true,
                    decoration: _cleanInputDec('Minggu Ke'),
                    items: List.generate(max(1, _totalMinggu), (i) => i + 1).map((w) {
                      return DropdownMenuItem(
                        value: w,
                        child: Text(
                          'Minggu $w dari $_totalMinggu',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF111827)),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        _syncWeekLogic(val);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Status Dokumen (Kontrak / Adendum)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Dokumen *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _statusDokumen,
                    isExpanded: true,
                    decoration: _cleanInputDec('Status Dokumen'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Kontrak',
                        child: Text('Kontrak (Normal)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      ),
                      DropdownMenuItem(
                        value: 'Adendum',
                        child: Text('Adendum', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        _onStatusDokumenChanged(val);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Periode Mulai & Selesai
        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: _periodeAwalController,
                label: 'Periode Awal',
                hintText: '24 Mei 2026',
                readOnly: true,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text('s/d', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF9CA3AF))),
            ),
            Expanded(
              child: _buildField(
                controller: _periodeAkhirController,
                label: 'Periode Akhir',
                hintText: '30 Mei 2026',
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF4B5563)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Durasi minggu ini: ${curRange.daysCount} hari kalender (${curRange.tglMulaiSlash} s/d ${curRange.tglSelesaiSlash})',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Bobot Fisik Rencana, Realisasi, Deviasi
  Widget _buildBobotFisikSection() {
    final isPositive = _deviasiPersen >= 0;

    return _buildCard(
      title: 'Kemajuan Bobot Fisik',
      badge: 'S/D Minggu Ini',
      children: [
        // Rencana Fisik
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RENCANA FISIK S/D MINGGU INI',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF374151), letterSpacing: 0.3),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 95,
                    child: TextFormField(
                      controller: _rencanaPersenController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: _onRencanaInputChanged,
                      decoration: InputDecoration(
                        suffixText: '%',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1F2937), width: 1.5)),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Nominal Rencana Kegiatan:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            WeeklyReportModel.formatRupiah(_rencanaNominal),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Realisasi Fisik
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'REALISASI FISIK S/D MINGGU INI',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF374151), letterSpacing: 0.3),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Text(
                      'Minggu Ini: ${_realisasiMingguIni.toStringAsFixed(3)}% (Otomatis)',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: Color(0xFF1D4ED8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 95,
                    child: TextFormField(
                      controller: _realisasiPersenController,
                      readOnly: true,
                      decoration: InputDecoration(
                        suffixText: '%',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF1F2937), width: 1.5)),
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Nominal Realisasi Kegiatan:', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            WeeklyReportModel.formatRupiah(_realisasiNominal),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF111827)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Deviasi (+/-) - Bersih, Elegan, Profesional
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isPositive ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isPositive ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEVIASI (+/-) [OTOMATIS]',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                        color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isPositive
                          ? '+${WeeklyReportModel.formatPercent(_deviasiPersen, decimalDigits: 2, appendUnit: false)} % (Lebih Cepat)'
                          : '${WeeklyReportModel.formatPercent(_deviasiPersen, decimalDigits: 2, appendUnit: false)} % (Terlambat)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      WeeklyReportModel.formatPercent(_deviasiPersen, decimalDigits: 2, showSign: true),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      WeeklyReportModel.formatRupiah(_deviasiNominal),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                        color: isPositive ? const Color(0xFF166534) : const Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Waktu Pelaksanaan Proyek (Otomatis Penuh Berdasarkan Kalender)
  Widget _buildWaktuSection() {
    final spmkDt = WeeklyReportModel.parseIndonesianDate(_tanggalSpmkController.text);
    final totalDays = int.tryParse(_jangkaWaktuController.text) ?? 90;
    final curRange = _calcWeekDateRange(_mingguKe, spmkDt, totalDays);

    return _buildCard(
      title: 'Waktu Pelaksanaan Proyek',
      badge: 'Hari Kalender',
      children: [
        Row(
          children: [
            // Waktu Terpakai
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WAKTU TERPAKAI S/D MINGGU INI',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${curRange.elapsedDays} Hari Kalender',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hari ke-1 s/d ${curRange.endDayIndex} (${(curRange.elapsedDays / max(1, totalDays) * 100).toStringAsFixed(1)} %)',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Sisa Waktu
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SISA WAKTU PELAKSANAAN',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${curRange.remainingDays} Hari Kalender',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF111827)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dari total $totalDays hari (${(curRange.remainingDays / max(1, totalDays) * 100).toStringAsFixed(1)} %)',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }


  // ─── TANDA TANGAN & PENGESAHAN DOKUMEN DIGITAL (CANVAS MULTI-SIGNERS) ───
  Widget _buildTandaTanganSection() {
    return _buildCard(
      title: 'Tanda Tangan & Pengesahan Digital',
      badge: '${_ttdList.length} Penandatangan',
      children: [
        const Text(
          'Input identitas penandatangan dan bubuhkan tanda tangan digital pada canvas di bawah. Dokumen cetak akan menampilkan tanda tangan yang sudah disimpan.',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),

        ..._ttdList.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;

          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: AppColors.primaryBlue,
                            child: Text(
                              '${idx + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.peranController.text.isNotEmpty
                                  ? item.peranController.text
                                  : 'Penandatangan ${idx + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF0F172A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_ttdList.length > 1)
                      IconButton(
                        tooltip: 'Hapus Penandatangan',
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () => _removeTtdRow(idx),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Baris 1: Peran & Instansi
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: item.peranController,
                        decoration: InputDecoration(
                          labelText: 'Peran / Jabatan',
                          hintText: 'Misal: Kontraktor Pelaksana',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: item.instansiController,
                        decoration: InputDecoration(
                          labelText: 'Instansi / Perusahaan',
                          hintText: 'Misal: PT / CV Penyedia Jasa',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // SignaturePadWidget (Nama, Tanggal, Canvas)
                SignaturePadWidget(
                  nameController: item.namaController,
                  roleController: item.instansiController,
                  dateController: item.tanggalController,
                  initialSignatureBase64: item.signatureBase64,
                  nameLabel: 'Nama Lengkap Penandatangan',
                  roleLabel: 'Instansi / Perusahaan',
                  dateLabel: 'Tanggal Tanda Tangan',
                  onSignatureChanged: (base64) {
                    item.signatureBase64 = base64;
                  },
                ),
              ],
            ),
          );
        }),

        // Tombol Tambah Penandatangan
        OutlinedButton.icon(
          onPressed: () => _addTtdRow(
            peran: 'Pengawas Lapangan',
            instansi: '',
            nama: '',
            tanggal: _periodeAkhirController.text.trim(),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah Penandatangan'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryBlue,
            side: const BorderSide(color: AppColors.primaryBlue),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  // Tombol Simpan Laporan
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _simpanLaporanMingguan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1F2937),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          widget.editReport != null ? 'Perbarui Ringkasan Mingguan' : 'Simpan Ringkasan Mingguan',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  // ─── CARD BUILDER HELPER ───
  Widget _buildCard({
    required String title,
    String? badge,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ─── FIELD BUILDER HELPER ───
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    bool readOnly = false,
    bool isBold = false,
    String? prefixText,
    String? suffixText,
    Widget? suffixIcon,
    VoidCallback? onTap,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: readOnly ? const Color(0xFF4B5563) : const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            suffixText: suffixText,
            suffixStyle: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            suffixIcon: suffixIcon,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            filled: true,
            fillColor: readOnly ? const Color(0xFFF9FAFB) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1F2937), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _cleanInputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF1F2937), width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
