import 'dart:convert';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/utils/plat_nomor_util.dart';
import 'package:tata_saka_app/widgets/clean_text_form_field.dart';
import 'package:tata_saka_app/widgets/signature_pad_widget.dart';

class BuatLaporanScreen extends StatefulWidget {
  final ContractModel? initialContract;
  final int? initialKegiatanIndex;
  final DateTime? initialDate;
  final Map<String, dynamic>? editReport; // Null jika buat laporan baru

  const BuatLaporanScreen({
    super.key,
    this.initialContract,
    this.initialKegiatanIndex,
    this.initialDate,
    this.editReport,
  });

  @override
  State<BuatLaporanScreen> createState() => _BuatLaporanScreenState();
}

class _BuatLaporanScreenState extends State<BuatLaporanScreen> {
  ContractModel? _selectedContract;
  int? _selectedKegiatanIndex;
  late DateTime _selectedDate;

  // A. PEKERJAAN (No, Jenis Pekerjaan, Volume, Lokasi)
  final List<Map<String, TextEditingController>> _pekerjaanList = [];

  // B. MATERIAL DIGUNAKAN (No, Jenis, Cacah Volume, Lokasi Awal, Lokasi Tujuan)
  final List<Map<String, TextEditingController>> _materialList = [];

  // C. JENIS PERALATAN (No, Jenis Peralatan, Cacah aktif, Jumlah, Kode, Rusak/Kondisi)
  final List<Map<String, TextEditingController>> _peralatanList = [];

  // D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR (No, Personil proyek, Cacah, Lokasi)
  final List<Map<String, dynamic>> _personilList = [];

  // E. CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN (No, Jenis, Jam, Lokasi, Tanggung Jwb Kontraktor, Akibat)
  final List<Map<String, dynamic>> _cuacaKejadianList = [];

  // F. INSTRUKSI DAN SARAN-SARAN (Auto Konsultan Supervisi CV. TATA SAKA CONSULTANT)
  final TextEditingController _instruksiKonsultanController = TextEditingController();
  final List<Map<String, TextEditingController>> _instruksiList = [];

  // G. TANDA TANGAN (TTD) PENGAWAS
  final TextEditingController _ttdNamaController = TextEditingController();
  final TextEditingController _ttdJabatanController = TextEditingController();
  String? _ttdSignatureBase64;

  // H. DOKUMENTASI FOTO LAPANGAN (Kamera, File, Drag & Drop)
  final List<String> _fotoList = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isDraggingPhoto = false;

  // Field Tambahan / Custom (Murni bebas tanpa suggest nama dan isi)
  final List<Map<String, TextEditingController>> _customFields = [];

  // DOKUMEN REKAPITULASI TAMBAHAN & PERJALANAN DT (OPSIONAL - PEKERJAAN ASPAL)
  bool _enableRekapitulasiAspal = false;
  final TextEditingController _jenisMaterialAspalController = TextEditingController();
  final TextEditingController _penyediaAmpController = TextEditingController();
  final TextEditingController _jarakTempuhController = TextEditingController();

  bool get _enableRekapSuhuLapangan => _enableRekapitulasiAspal;
  bool get _enableRekapSuhuAmp => _enableRekapitulasiAspal;
  bool get _enableRekapTonaseAspal => _enableRekapitulasiAspal;

  // 1. Rekapitulasi Waktu Tempuh DT & Suhu di Lapangan
  final List<Map<String, TextEditingController>> _rekapSuhuLapanganList = [];

  // 2. Rekapitulasi Waktu Tempuh DT & Suhu di AMP
  final List<Map<String, TextEditingController>> _rekapSuhuAmpList = [];

  // 3. Rekapitulasi Tonase Aspal
  final List<Map<String, TextEditingController>> _rekapTonaseAspalList = [];

  static const List<String> _namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  static const List<String> _namaHariPanjang = [
    'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
  ];

  @override
  void initState() {
    super.initState();

    final isEdit = widget.editReport != null;
    final r = widget.editReport;

    if (isEdit && r!['tanggal'] != null) {
      try {
        _selectedDate = DateTime.parse(r['tanggal']);
      } catch (_) {
        _selectedDate = widget.initialDate ?? DateTime.now();
      }
    } else {
      _selectedDate = widget.initialDate ?? DateTime.now();
    }

    _selectedContract = widget.initialContract;
    _selectedKegiatanIndex = widget.initialKegiatanIndex;

    if (isEdit) {
      _loadExistingReport(r!);
    } else {
      _loadInitialBlankTemplate();
    }
  }

  void _loadInitialBlankTemplate() {
    // A. Pekerjaan: baris awal
    _addPekerjaanRow(jenis: '', volume: '', lokasi: '');

    // B. Material: baris awal
    _addMaterialRow(jenis: '', volume: '', lokasiAwal: '', lokasiTujuan: '');

    // C. Peralatan: baris awal
    _addPeralatanRow(jenis: '', cacahAktif: '', jumlah: '', kode: '', rusak: '');

    // D. Personil: Kosongkan default (1 baris kosong)
    _addPersonilRow(role: '', cacah: '', lokasi: '');

    // E. Cuaca & Kejadian: Kosongkan default (1 baris kosong)
    _addCuacaRow(jenis: '', jam: '', lokasi: '', tanggungJawab: 'Tidak', akibat: '');

    // F. Instruksi dan Saran-Saran (Auto Konsultan Supervisi)
    _instruksiKonsultanController.clear();
    _instruksiList.clear();

    // G. Tanda Tangan (TTD) Pengawas
    _ttdNamaController.text = '';
    _ttdJabatanController.text = '';
    _ttdSignatureBase64 = null;

    // H. Foto Dokumentasi
    _fotoList.clear();

    // Field custom dibiarkan KOSONG (tanpa sugesti)
  }

  void _loadExistingReport(Map<String, dynamic> r) {
    // A. Pekerjaan
    final pList = r['pekerjaanList'] as List<dynamic>? ?? [];
    if (pList.isNotEmpty) {
      for (var item in pList) {
        _addPekerjaanRow(
          jenis: item['jenis'] ?? '',
          volume: item['volume'] ?? '',
          lokasi: item['lokasi'] ?? '',
        );
      }
    } else {
      _addPekerjaanRow(jenis: r['temuan'] ?? '', volume: '', lokasi: r['lokasiSta'] ?? '');
    }

    // B. Material
    final mList = r['materialList'] as List<dynamic>? ?? [];
    if (mList.isNotEmpty) {
      for (var item in mList) {
        _addMaterialRow(
          jenis: item['jenis'] ?? '',
          volume: item['volume'] ?? '',
          lokasiAwal: item['lokasiAwal'] ?? item['lokasi'] ?? '',
          lokasiTujuan: item['lokasiTujuan'] ?? '',
        );
      }
    } else {
      _addMaterialRow(jenis: '', volume: '', lokasiAwal: '', lokasiTujuan: '');
    }

    // C. Peralatan
    final alList = r['peralatanList'] as List<dynamic>? ?? [];
    if (alList.isNotEmpty) {
      for (var item in alList) {
        _addPeralatanRow(
          jenis: item['jenis'] ?? '',
          cacahAktif: item['cacahAktif'] ?? item['jumlah'] ?? '',
          jumlah: item['jumlah'] ?? '',
          noRusak: item['noRusak'] ?? '',
          jenisRusak: item['jenisRusak'] ?? '',
          kode: item['kode'] ?? '',
          rusak: item['rusak'] ?? item['kondisi'] ?? '',
        );
      }
    } else {
      _addPeralatanRow();
    }

    // D. Personil
    final perList = r['personilList'] as List<dynamic>? ?? [];
    if (perList.isNotEmpty) {
      for (var item in perList) {
        _addPersonilRow(
          role: item['role'] ?? '',
          cacah: (item['cacah'] ?? item['count'] ?? '').toString(),
          lokasi: item['lokasi'] ?? '',
        );
      }
    } else {
      _addPersonilRow(role: '', cacah: '', lokasi: '');
    }

    // E. Cuaca
    final cList = r['cuacaKejadianList'] as List<dynamic>? ?? [];
    if (cList.isNotEmpty) {
      for (var item in cList) {
        _addCuacaRow(
          jenis: item['jenis'] ?? '',
          jam: item['jam'] ?? '',
          lokasi: item['lokasi'] ?? '',
          tanggungJawab: item['tanggungJawab'] ?? 'Tidak',
          akibat: item['akibat'] ?? '',
        );
      }
    } else {
      _addCuacaRow(jenis: '', jam: '', lokasi: '', tanggungJawab: 'Tidak', akibat: '');
    }

    // F. Instruksi dan Saran-Saran (Auto Konsultan Supervisi)
    final insList = r['instruksiList'] as List<dynamic>? ?? [];
    final insMap = r['instruksiSaran'] as Map<String, dynamic>?;
    final konsultanUraian = r['instruksiKonsultan'] ??
        (insMap?['konsultanUraian']) ??
        (insList.isNotEmpty ? insList.first['uraian'] : r['instruksi']);
    if (konsultanUraian != null && konsultanUraian.toString().isNotEmpty) {
      _instruksiKonsultanController.text = konsultanUraian.toString();
    }

    // G. Tanda Tangan (TTD)
    if (r['ttdNama'] != null && r['ttdNama'].toString().isNotEmpty) {
      _ttdNamaController.text = r['ttdNama'].toString();
    }
    if (r['ttdJabatan'] != null && r['ttdJabatan'].toString().isNotEmpty) {
      _ttdJabatanController.text = r['ttdJabatan'].toString();
    }
    _ttdSignatureBase64 = r['ttdSignature']?.toString();

    // H. Foto
    final fList = r['fotoList'] as List<dynamic>? ?? [];
    if (fList.isNotEmpty) {
      _fotoList.addAll(List<String>.from(fList));
    }

    // Rekapitulasi Aspal & Data Perjalanan
    _enableRekapitulasiAspal = r['hasRekapitulasiAspal'] == true ||
        r['hasRekapSuhuLapangan'] == true ||
        r['hasRekapSuhuAmp'] == true ||
        r['hasRekapTonaseAspal'] == true;

    if (r['jenisMaterialAspal'] != null && r['jenisMaterialAspal'].toString().isNotEmpty) {
      _jenisMaterialAspalController.text = r['jenisMaterialAspal'].toString();
    }
    if (r['penyediaAmp'] != null && r['penyediaAmp'].toString().isNotEmpty) {
      _penyediaAmpController.text = r['penyediaAmp'].toString();
    }
    if (r['jarakTempuh'] != null && r['jarakTempuh'].toString().isNotEmpty) {
      _jarakTempuhController.text = r['jarakTempuh'].toString();
    }

    // Rekapitulasi 1: Suhu di Lapangan
    final rslList = r['rekapSuhuLapanganList'] as List<dynamic>? ?? [];
    if (rslList.isNotEmpty) {
      _enableRekapitulasiAspal = true;
      for (var item in rslList) {
        _addRekapSuhuLapanganRow(
          nomorKendaraan: PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
          jamDatang: item['jamDatang'] ?? '',
          suhu: item['suhu'] ?? '',
          jamMulaiTuang: item['jamMulaiTuang'] ?? '',
          jamSelesaiTuang: item['jamSelesaiTuang'] ?? '',
          jamPulang: item['jamPulang'] ?? '',
        );
      }
    }

    // Rekapitulasi 2: Suhu di AMP
    final rsaList = r['rekapSuhuAmpList'] as List<dynamic>? ?? [];
    if (rsaList.isNotEmpty) {
      _enableRekapitulasiAspal = true;
      for (var item in rsaList) {
        _addRekapSuhuAmpRow(
          nomorKendaraan: PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
          jamPergi: item['jamPergi'] ?? '',
          suhuAmp: item['suhuAmp'] ?? '',
          jamPulang: item['jamPulang'] ?? '',
        );
      }
    }

    // Rekapitulasi 3: Tonase Aspal
    final rtaList = r['rekapTonaseAspalList'] as List<dynamic>? ?? [];
    if (rtaList.isNotEmpty) {
      _enableRekapitulasiAspal = true;
      for (var item in rtaList) {
        _addRekapTonaseAspalRow(
          nomorKendaraan: PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
          tonaseTiket: item['tonaseTiket'] ?? '',
          jumlahKumulatif: item['jumlahKumulatif'] ?? '',
        );
      }
    }

    // Custom Fields
    final cfList = r['customFields'] as List<dynamic>? ?? [];
    for (var item in cfList) {
      _addCustomFieldRow(
        nama: item['nama'] ?? '',
        isi: item['isi'] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (var m in _instruksiList) {
      m.values.forEach((c) => c.dispose());
    }

    for (var m in _pekerjaanList) {
      m.values.forEach((c) => c.dispose());
    }
    for (var m in _materialList) {
      m.values.forEach((c) => c.dispose());
    }
    for (var m in _peralatanList) {
      m.values.forEach((c) => c.dispose());
    }
    for (var m in _personilList) {
      (m['roleController'] as TextEditingController).dispose();
      (m['cacahController'] as TextEditingController).dispose();
      (m['lokasiController'] as TextEditingController).dispose();
    }
    for (var m in _cuacaKejadianList) {
      (m['jenisController'] as TextEditingController).dispose();
      (m['jamController'] as TextEditingController).dispose();
      (m['lokasiController'] as TextEditingController).dispose();
      (m['akibatController'] as TextEditingController).dispose();
    }
    for (var m in _customFields) {
      m.values.forEach((c) => c.dispose());
    }
    for (var m in _rekapSuhuLapanganList) {
      m.values.forEach((c) => c.dispose());
    }
    for (var m in _rekapSuhuAmpList) {
      m.values.forEach((c) => c.dispose());
    }
    for (var m in _rekapTonaseAspalList) {
      m.values.forEach((c) => c.dispose());
    }

    _instruksiKonsultanController.dispose();
    _ttdNamaController.dispose();
    _ttdJabatanController.dispose();
    _jenisMaterialAspalController.dispose();
    _penyediaAmpController.dispose();
    _jarakTempuhController.dispose();

    super.dispose();
  }

  // Row Helpers
  void _addPekerjaanRow({String jenis = '', String volume = '', String lokasi = ''}) {
    setState(() {
      _pekerjaanList.add({
        'jenis': TextEditingController(text: jenis),
        'volume': TextEditingController(text: volume),
        'lokasi': TextEditingController(text: lokasi),
      });
    });
  }

  void _addMaterialRow({String jenis = '', String volume = '', String lokasiAwal = '', String lokasiTujuan = ''}) {
    setState(() {
      _materialList.add({
        'jenis': TextEditingController(text: jenis),
        'volume': TextEditingController(text: volume),
        'lokasiAwal': TextEditingController(text: lokasiAwal),
        'lokasiTujuan': TextEditingController(text: lokasiTujuan),
      });
    });
  }

  void _addPeralatanRow({
    String jenis = '',
    String cacahAktif = '',
    String jumlah = '',
    String noRusak = '',
    String jenisRusak = '',
    String kode = '',
    String rusak = '',
  }) {
    setState(() {
      _peralatanList.add({
        'jenis': TextEditingController(text: jenis),
        'cacahAktif': TextEditingController(text: cacahAktif),
        'jumlah': TextEditingController(text: jumlah),
        'noRusak': TextEditingController(text: noRusak),
        'jenisRusak': TextEditingController(text: jenisRusak),
        'kode': TextEditingController(text: kode),
        'rusak': TextEditingController(text: rusak),
      });
    });
  }

  void _addPersonilRow({String role = '', String cacah = '', String lokasi = ''}) {
    setState(() {
      _personilList.add({
        'roleController': TextEditingController(text: role),
        'cacahController': TextEditingController(text: cacah),
        'lokasiController': TextEditingController(text: lokasi),
      });
    });
  }

  void _addCuacaRow({String jenis = '', String jam = '', String lokasi = '', String tanggungJawab = 'Tidak', String akibat = ''}) {
    setState(() {
      _cuacaKejadianList.add({
        'jenisController': TextEditingController(text: jenis),
        'jamController': TextEditingController(text: jam),
        'lokasiController': TextEditingController(text: lokasi),
        'tanggungJawab': tanggungJawab,
        'akibatController': TextEditingController(text: akibat),
      });
    });
  }

  void _addCustomFieldRow({String nama = '', String isi = ''}) {
    setState(() {
      _customFields.add({
        'nama': TextEditingController(text: nama),
        'isi': TextEditingController(text: isi),
      });
    });
  }

  // Helper Rekap 1: Waktu Tempuh DT & Suhu di Lapangan
  void _addRekapSuhuLapanganRow({
    String nomorKendaraan = '',
    String jamDatang = '',
    String suhu = '',
    String jamMulaiTuang = '',
    String jamSelesaiTuang = '',
    String jamPulang = '',
  }) {
    setState(() {
      final ctrlPlat = TextEditingController(text: PlatNomorUtil.normalize(nomorKendaraan));
      ctrlPlat.addListener(() {
        if (mounted) setState(() {});
      });

      _rekapSuhuLapanganList.add({
        'nomorKendaraan': ctrlPlat,
        'jamDatang': TextEditingController(text: jamDatang),
        'suhu': TextEditingController(text: suhu),
        'jamMulaiTuang': TextEditingController(text: jamMulaiTuang),
        'jamSelesaiTuang': TextEditingController(text: jamSelesaiTuang),
        'jamPulang': TextEditingController(text: jamPulang),
      });
    });
  }

  // Helper Rekap 2: Waktu Tempuh DT & Suhu di AMP
  void _addRekapSuhuAmpRow({
    String nomorKendaraan = '',
    String jamPergi = '',
    String suhuAmp = '',
    String jamPulang = '',
  }) {
    setState(() {
      final ctrlPlat = TextEditingController(text: PlatNomorUtil.normalize(nomorKendaraan));
      ctrlPlat.addListener(() {
        if (mounted) setState(() {});
      });

      _rekapSuhuAmpList.add({
        'nomorKendaraan': ctrlPlat,
        'jamPergi': TextEditingController(text: jamPergi),
        'suhuAmp': TextEditingController(text: suhuAmp),
        'jamPulang': TextEditingController(text: jamPulang),
      });
    });
  }

  // Helper Rekap 3: Tonase Aspal (Dengan Auto-Kalkulasi Kumulatif)
  void _addRekapTonaseAspalRow({
    String nomorKendaraan = '',
    String tonaseTiket = '',
    String jumlahKumulatif = '',
  }) {
    setState(() {
      final ctrlPlat = TextEditingController(text: PlatNomorUtil.normalize(nomorKendaraan));
      ctrlPlat.addListener(() {
        if (mounted) setState(() {});
      });

      final ctrlTonase = TextEditingController(text: tonaseTiket);
      final ctrlKumulatif = TextEditingController(text: jumlahKumulatif);

      ctrlTonase.addListener(() {
        _recalculateTonaseKumulatif();
      });

      _rekapTonaseAspalList.add({
        'nomorKendaraan': ctrlPlat,
        'tonaseTiket': ctrlTonase,
        'jumlahKumulatif': ctrlKumulatif,
      });

      if (tonaseTiket.isNotEmpty && jumlahKumulatif.isEmpty) {
        _recalculateTonaseKumulatif();
      }
    });
  }

  void _recalculateTonaseKumulatif() {
    double runningTotal = 0;
    for (var row in _rekapTonaseAspalList) {
      final tText = row['tonaseTiket']?.text.trim().replaceAll(',', '.') ?? '';
      final tVal = double.tryParse(tText) ?? 0;
      runningTotal += tVal;
      if (tVal > 0 || tText.isNotEmpty) {
        final formatted = (runningTotal % 1 == 0)
            ? runningTotal.toInt().toString()
            : runningTotal.toStringAsFixed(2);
        row['jumlahKumulatif']?.text = formatted;
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Map<String, dynamic>? get _currentKegiatan {
    if (_selectedContract != null &&
        _selectedKegiatanIndex != null &&
        _selectedContract!.kegiatans.isNotEmpty &&
        _selectedKegiatanIndex! < _selectedContract!.kegiatans.length) {
      return _selectedContract!.kegiatans[_selectedKegiatanIndex!];
    }
    return null;
  }

  void _simpanLaporan() {
    if (_selectedContract == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kontrak terlebih dahulu')),
      );
      return;
    }

    if (_selectedKegiatanIndex == null ||
        _selectedContract!.kegiatans.isEmpty ||
        _selectedKegiatanIndex! >= _selectedContract!.kegiatans.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kegiatan terlebih dahulu')),
      );
      return;
    }

    final dateKey =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final dateFormatted =
        '${_namaHariPanjang[_selectedDate.weekday - 1]}, ${_selectedDate.day.toString().padLeft(2, '0')} ${_namaBulan[_selectedDate.month - 1]} ${_selectedDate.year}';

    final isEdit = widget.editReport != null;
    final reportId = isEdit ? widget.editReport!['id'] : DateTime.now().millisecondsSinceEpoch.toString();

    final keg = _currentKegiatan!;
    final String lokasiKegiatan = keg['lokasi'] ?? '-';
    final String sumberDanaKontrak = _selectedContract!.sumberDana;
    final String namaKontraktor = keg['kontraktor'] ?? '-';

    // A. Clean Pekerjaan (No, Jenis Pekerjaan, Volume, Lokasi)
    final cleanPekerjaan = _pekerjaanList.asMap().entries.map((e) => {
      'no': (e.key + 1).toString(),
      'jenis': e.value['jenis']?.text.trim() ?? '',
      'volume': e.value['volume']?.text.trim() ?? '',
      'lokasi': e.value['lokasi']?.text.trim() ?? '',
    }).where((m) => m['jenis']!.isNotEmpty).toList();

    // B. Clean Material (No, Jenis, Cacah Volume, Lokasi Awal, Lokasi Tujuan)
    final cleanMaterial = _materialList.asMap().entries.map((e) => {
      'no': (e.key + 1).toString(),
      'jenis': e.value['jenis']?.text.trim() ?? '',
      'volume': e.value['volume']?.text.trim() ?? '',
      'lokasiAwal': e.value['lokasiAwal']?.text.trim() ?? '',
      'lokasiTujuan': e.value['lokasiTujuan']?.text.trim() ?? '',
    }).where((m) => m['jenis']!.isNotEmpty).toList();

    // C. Clean Peralatan (No, Jenis Peralatan, Cacah aktif, Jumlah, No, Jenis, Kode, Rusak)
    final cleanPeralatan = _peralatanList.asMap().entries.map((e) => {
      'no': (e.key + 1).toString(),
      'jenis': e.value['jenis']?.text.trim() ?? '',
      'cacahAktif': e.value['cacahAktif']?.text.trim() ?? '',
      'jumlah': e.value['jumlah']?.text.trim() ?? '',
      'noRusak': e.value['noRusak']?.text.trim() ?? '',
      'jenisRusak': e.value['jenisRusak']?.text.trim() ?? '',
      'kode': e.value['kode']?.text.trim() ?? '',
      'rusak': e.value['rusak']?.text.trim() ?? '',
    }).where((m) => m['jenis']!.isNotEmpty || m['jenisRusak']!.isNotEmpty).toList();

    // D. Clean Personil (No, Personil proyek, Cacah, Lokasi)
    final cleanPersonil = _personilList.asMap().entries.map((e) => {
      'no': (e.key + 1).toString(),
      'role': (e.value['roleController'] as TextEditingController).text.trim(),
      'cacah': (e.value['cacahController'] as TextEditingController).text.trim(),
      'lokasi': (e.value['lokasiController'] as TextEditingController).text.trim(),
    }).toList();

    // E. Clean Cuaca & Kejadian
    final cleanCuaca = _cuacaKejadianList.asMap().entries.map((e) => {
      'no': (e.key + 1).toString(),
      'jenis': (e.value['jenisController'] as TextEditingController).text.trim(),
      'jam': (e.value['jamController'] as TextEditingController).text.trim(),
      'lokasi': (e.value['lokasiController'] as TextEditingController).text.trim(),
      'tanggungJawab': e.value['tanggungJawab'] as String? ?? 'Tidak',
      'akibat': (e.value['akibatController'] as TextEditingController).text.trim(),
    }).where((m) => m['jenis']!.isNotEmpty).toList();

    // F. Clean Instruksi (Konsultan Supervisi CV. TATA SAKA CONSULTANT)
    final String instruksiText = _instruksiKonsultanController.text.trim();
    final cleanInstruksi = instruksiText.isNotEmpty
        ? [
            {
              'no': '1',
              'pihak': 'Konsultan Supervisi (CV. TATA SAKA CONSULTANT)',
              'uraian': instruksiText,
            }
          ]
        : <Map<String, String>>[];

    // Clean Custom Fields (tanpa sugesti nama/isi)
    final cleanCustomFields = _customFields.map((c) => {
      'nama': c['nama']?.text.trim() ?? '',
      'isi': c['isi']?.text.trim() ?? '',
    }).where((c) => c['nama']!.isNotEmpty).toList();

    // Clean Rekapitulasi 1: Suhu Lapangan
    final cleanRekapSuhuLapangan = _enableRekapSuhuLapangan
        ? _rekapSuhuLapanganList.asMap().entries.map((e) => {
            'no': (e.key + 1).toString(),
            'nomorKendaraan': PlatNomorUtil.normalize(e.value['nomorKendaraan']?.text.trim() ?? ''),
            'jamDatang': e.value['jamDatang']?.text.trim() ?? '',
            'suhu': e.value['suhu']?.text.trim() ?? '',
            'jamMulaiTuang': e.value['jamMulaiTuang']?.text.trim() ?? '',
            'jamSelesaiTuang': e.value['jamSelesaiTuang']?.text.trim() ?? '',
            'jamPulang': e.value['jamPulang']?.text.trim() ?? '',
          }).where((m) => m['nomorKendaraan']!.isNotEmpty || m['jamDatang']!.isNotEmpty).toList()
        : <Map<String, String>>[];

    // Clean Rekapitulasi 2: Suhu AMP
    final cleanRekapSuhuAmp = _enableRekapSuhuAmp
        ? _rekapSuhuAmpList.asMap().entries.map((e) => {
            'no': (e.key + 1).toString(),
            'nomorKendaraan': PlatNomorUtil.normalize(e.value['nomorKendaraan']?.text.trim() ?? ''),
            'jamPergi': e.value['jamPergi']?.text.trim() ?? '',
            'suhuAmp': e.value['suhuAmp']?.text.trim() ?? '',
            'jamPulang': e.value['jamPulang']?.text.trim() ?? '',
          }).where((m) => m['nomorKendaraan']!.isNotEmpty || m['jamPergi']!.isNotEmpty).toList()
        : <Map<String, String>>[];

    // Clean Rekapitulasi 3: Tonase Aspal
    final cleanRekapTonaseAspal = _enableRekapTonaseAspal
        ? _rekapTonaseAspalList.asMap().entries.map((e) => {
            'no': (e.key + 1).toString(),
            'nomorKendaraan': PlatNomorUtil.normalize(e.value['nomorKendaraan']?.text.trim() ?? ''),
            'tonaseTiket': e.value['tonaseTiket']?.text.trim() ?? '',
            'jumlahKumulatif': e.value['jumlahKumulatif']?.text.trim() ?? '',
          }).where((m) => m['nomorKendaraan']!.isNotEmpty || m['tonaseTiket']!.isNotEmpty).toList()
        : <Map<String, String>>[];

    final Map<String, dynamic> reportData = {
      'id': reportId,
      'tanggal': dateKey,
      'tanggalFormatted': dateFormatted,
      'namaKontrak': _selectedContract!.namaKontrak,
      'namaKegiatan': keg['namaKegiatan'] ?? '',
      'lokasi': lokasiKegiatan,
      'lokasiSta': lokasiKegiatan,
      'sumberDana': sumberDanaKontrak,
      'kontraktor': namaKontraktor,

      // Format Dokumen Buku Harian Standar
      'pekerjaanList': cleanPekerjaan,
      'materialList': cleanMaterial,
      'peralatanList': cleanPeralatan,
      'personilList': cleanPersonil,
      'cuacaKejadianList': cleanCuaca,
      'instruksiList': cleanInstruksi,
      'instruksiKonsultan': instruksiText,
      'instruksiSaran': {
        'kontraktorUraian': '',
        'dinasUraian': '',
        'konsultanUraian': instruksiText,
      },

      // G. Tanda Tangan (TTD) Digital Pengawas
      'ttdNama': _ttdNamaController.text.trim(),
      'ttdJabatan': _ttdJabatanController.text.trim(),
      'ttdSignature': _ttdSignatureBase64,

      // Field Kustom Dinamis
      'customFields': cleanCustomFields,

      // Dokumen Rekapitulasi Tambahan & Perjalanan DT (Opsional Halaman Terpisah)
      'hasRekapitulasiAspal': _enableRekapitulasiAspal,
      'hasRekapPerjalananDt': _enableRekapitulasiAspal,
      'jenisMaterialAspal': _jenisMaterialAspalController.text.trim(),
      'penyediaAmp': _penyediaAmpController.text.trim(),
      'jarakTempuh': _jarakTempuhController.text.trim(),

      'hasRekapSuhuLapangan': _enableRekapitulasiAspal && cleanRekapSuhuLapangan.isNotEmpty,
      'rekapSuhuLapanganList': cleanRekapSuhuLapangan,

      'hasRekapSuhuAmp': _enableRekapitulasiAspal && cleanRekapSuhuAmp.isNotEmpty,
      'rekapSuhuAmpList': cleanRekapSuhuAmp,

      'hasRekapTonaseAspal': _enableRekapitulasiAspal && cleanRekapTonaseAspal.isNotEmpty,
      'rekapTonaseAspalList': cleanRekapTonaseAspal,

      // Backward Compatibility & Kartu
      'temuan': cleanPekerjaan.isNotEmpty
          ? cleanPekerjaan.map((p) => '${p['jenis']} (${p['volume']})').join(', ')
          : 'Pekerjaan sesuai buku harian standar.',
      'cuaca': cleanCuaca.isNotEmpty ? cleanCuaca.first['jenis'] : 'Normal',
      'instruksi': instruksiText,
      'rekomendasi': '',
      'auditor': 'CV. Tata Saka Consultant',
      'status': 'Terverifikasi',
      'fotoCount': _fotoList.length,
      'fotoList': _fotoList,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    final List<dynamic> existingReports = List.from(keg['laporans'] ?? []);
    if (isEdit) {
      final idx = existingReports.indexWhere((r) => r['id'] == reportId);
      if (idx != -1) {
        existingReports[idx] = reportData;
      } else {
        existingReports.add(reportData);
      }
    } else {
      existingReports.add(reportData);
    }

    keg['laporans'] = existingReports;
    _selectedContract!.kegiatans[_selectedKegiatanIndex!] = keg;

    Provider.of<ContractProvider>(context, listen: false).updateContract(_selectedContract!);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEdit
            ? 'Buku Harian Standar ($dateFormatted) berhasil diperbarui!'
            : 'Buku Harian Standar ($dateFormatted) berhasil disimpan!'),
        backgroundColor: AppColors.successGreen,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ContractProvider>(context);
    final contracts = provider.contracts;

    if (_selectedContract == null && contracts.isNotEmpty) {
      _selectedContract = contracts.first;
      if (_selectedContract!.kegiatans.isNotEmpty) {
        _selectedKegiatanIndex = 0;
      }
    }

    final dateFormatted =
        '${_namaHariPanjang[_selectedDate.weekday - 1]}, ${_selectedDate.day.toString().padLeft(2, '0')} ${_namaBulan[_selectedDate.month - 1]} ${_selectedDate.year}';

    final currentKeg = _currentKegiatan;
    final String lokasiAuto = currentKeg?['lokasi'] ?? '-';
    final String sumberDanaAuto = _selectedContract?.sumberDana ?? '-';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.editReport != null ? 'Edit Buku Harian Standar' : 'Form Buku Harian Standar',
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _simpanLaporan,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TANGGAL PENGAWASAN
            _buildOfficialHeader(dateFormatted, lokasiAuto, sumberDanaAuto),
            const SizedBox(height: 16),

            // 2. PILIH KONTRAK & KEGIATAN
            _buildContractAndKegiatanSelector(contracts, lokasiAuto, sumberDanaAuto),
            const SizedBox(height: 16),

            // 3. A. PEKERJAAN
            _buildSectionA_Pekerjaan(),
            const SizedBox(height: 16),

            // 4. B. MATERIAL DIGUNAKAN
            _buildSectionB_Material(),
            const SizedBox(height: 16),

            // 5. C. JENIS PERALATAN YANG DIGUNAKAN
            _buildSectionC_Peralatan(),
            const SizedBox(height: 16),

            // 6. D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR
            _buildSectionD_Personil(),
            const SizedBox(height: 16),

            // 7. E. CUACA / BENCANA / KEJADIAN PENGHAMBAT PEKERJAAN
            _buildSectionE_Cuaca(),
            const SizedBox(height: 16),

            // 8. F. INSTRUKSI DAN SARAN-SARAN
            _buildSectionFInstruksi(),
            const SizedBox(height: 16),

            // 9. G. TANDA TANGAN (TTD) PENGAWAS
            _buildSectionG_TandaTangan(),
            const SizedBox(height: 16),

            // 10. H. DOKUMENTASI FOTO LAPANGAN
            _buildSectionFoto(),
            const SizedBox(height: 16),

            // 10. DOKUMEN REKAPITULASI (OPSIONAL - PEKERJAAN ASPAL)
            _buildSectionRekapitulasiOpsional(),
            const SizedBox(height: 16),

            // 11. FIELD TAMBAHAN / CUSTOM
            _buildSectionCustomFields(),
            const SizedBox(height: 28),

            // TOMBOL SIMPAN BAWAH
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _simpanLaporan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  widget.editReport != null ? 'Perbarui Buku Harian Standar' : 'Simpan Buku Harian Standar',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  // ─── 1. TANGGAL PENGAWASAN ───
  Widget _buildOfficialHeader(String dateFormatted, String lokasi, String sumberDana) {
    return _buildCard(
      title: 'Hari / Tanggal Pengawasan',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal Pelaksanaan',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF6B7280)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormatted,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: _pickDate,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
              child: const Text(
                'Ubah Tanggal',
                style: TextStyle(color: Color(0xFF374151), fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 2. KONTRAK & KEGIATAN ───
  Widget _buildContractAndKegiatanSelector(List<ContractModel> contracts, String lokasi, String sumberDana) {
    return _buildCard(
      title: 'Pilih Kontrak & Kegiatan',
      children: [
        // Dropdown Kontrak
        const Text(
          'Kontrak *',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.3),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<ContractModel>(
          value: _selectedContract,
          isExpanded: true,
          decoration: _cleanInputDec('Pilih Kontrak'),
          items: contracts.map((c) => DropdownMenuItem(value: c, child: Text(c.namaKontrak, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedContract = val;
              _selectedKegiatanIndex = (val?.kegiatans.isNotEmpty ?? false) ? 0 : null;
            });
          },
        ),
        const SizedBox(height: 14),

        // Dropdown Kegiatan
        const Text(
          'Kegiatan *',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.3),
        ),
        const SizedBox(height: 6),
        if (_selectedContract == null || _selectedContract!.kegiatans.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Text('Belum ada kegiatan pada kontrak ini.', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          )
        else
          DropdownButtonFormField<int>(
            value: (_selectedKegiatanIndex != null && _selectedKegiatanIndex! < _selectedContract!.kegiatans.length)
                ? _selectedKegiatanIndex
                : 0,
            isExpanded: true,
            decoration: _cleanInputDec('Pilih Kegiatan'),
            items: _selectedContract!.kegiatans.asMap().entries.map((entry) {
              final k = entry.value;
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(k['namaKegiatan'] ?? 'Kegiatan ${entry.key + 1}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (idx) {
              setState(() {
                _selectedKegiatanIndex = idx;
              });
            },
          ),
        const SizedBox(height: 14),

        // Metadata box (Lokasi & Sumber Dana)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDocMetaRow('Lokasi Kegiatan', lokasi.isNotEmpty ? lokasi : '-'),
              const SizedBox(height: 6),
              _buildDocMetaRow('Sumber Dana', sumberDana.isNotEmpty ? sumberDana : '-'),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 3. A. PEKERJAAN ───
  Widget _buildSectionA_Pekerjaan() {
    return _buildCard(
      title: 'A. PEKERJAAN',
      badge: '${_pekerjaanList.length} Baris',
      children: [
        ..._pekerjaanList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          return _buildItemCard(
            title: 'Pekerjaan #${idx + 1}',
            onDelete: () {
              setState(() {
                _pekerjaanList.removeAt(idx);
              });
            },
            children: [
              _buildField(
                controller: m['jenis']!,
                label: 'Jenis Pekerjaan',
                hintText: 'Contoh: Pekerjaan Galian Tanah / Pemasangan U-Ditch',
                isBold: true,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['volume']!,
                label: 'Volume',
                hintText: 'Contoh: 35 m³ / 120 m²',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['lokasi']!,
                label: 'Lokasi / STA',
                hintText: 'Contoh: STA 0+150 - STA 0+200',
              ),
            ],
          );
        }),
        _buildAddButton('+ Tambah Baris Pekerjaan', () => _addPekerjaanRow()),
      ],
    );
  }

  // ─── 4. B. MATERIAL DIGUNAKAN ───
  Widget _buildSectionB_Material() {
    return _buildCard(
      title: 'B. MATERIAL DIGUNAKAN',
      badge: '${_materialList.length} Baris',
      children: [
        ..._materialList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          return _buildItemCard(
            title: 'Material #${idx + 1}',
            onDelete: () {
              setState(() {
                _materialList.removeAt(idx);
              });
            },
            children: [
              _buildField(
                controller: m['jenis']!,
                label: 'Jenis Material',
                hintText: 'Contoh: Pasir Pasang / Semen Gresik / Aspal AC-WC',
                isBold: true,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['volume']!,
                label: 'Cacah Volume',
                hintText: 'Contoh: 15 m³ / 20 Ton / 50 Sak',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['lokasiAwal']!,
                label: 'Lokasi Awal (Asal)',
                hintText: 'Contoh: Quarry / Basecamp / Gudang Utama',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['lokasiTujuan']!,
                label: 'Lokasi Tujuan',
                hintText: 'Contoh: STA 0+150',
              ),
            ],
          );
        }),
        _buildAddButton('+ Tambah Baris Material', () => _addMaterialRow()),
      ],
    );
  }

  // ─── 5. C. JENIS PERALATAN YANG DIGUNAKAN ───
  Widget _buildSectionC_Peralatan() {
    return _buildCard(
      title: 'C. JENIS PERALATAN YANG DIGUNAKAN',
      badge: '${_peralatanList.length} Baris',
      children: [
        ..._peralatanList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;
          return _buildItemCard(
            title: 'Peralatan #${idx + 1}',
            onDelete: () {
              setState(() {
                _peralatanList.removeAt(idx);
              });
            },
            children: [
              // 1. Peralatan Aktif
              const Text(
                'PERALATAN AKTIF DIGUNAKAN',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF374151), letterSpacing: 0.3),
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: m['jenis']!,
                label: 'Jenis Peralatan',
                hintText: 'Contoh: Excavator PC200, Tandem Roller, Dump Truck',
                isBold: true,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['cacahAktif']!,
                label: 'Cacah Aktif',
                hintText: 'Contoh: 1 Unit',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jumlah']!,
                label: 'Jumlah Total',
                hintText: 'Contoh: 2 Unit',
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 12),

              // 2. Peralatan Rusak / Teridentifikasi
              const Text(
                'PERALATAN RUSAK / TERIDENTIFIKASI (JIKA ADA)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF6B7280), letterSpacing: 0.3),
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: m['noRusak']!,
                label: 'No. Urut Rusak',
                hintText: 'Contoh: 1',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['kode']!,
                label: 'Kode Alat',
                hintText: 'Contoh: EX-01',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jenisRusak']!,
                label: 'Jenis Alat Rusak',
                hintText: 'Contoh: Dump Truck Isuzu',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['rusak']!,
                label: 'Kondisi Kerusakan',
                hintText: 'Contoh: Ban pecah / hidrolik bocor, sedang perbaikan',
              ),
            ],
          );
        }),
        _buildAddButton('+ Tambah Baris Peralatan', () => _addPeralatanRow()),
      ],
    );
  }

  // ─── 6. D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR ───
  Widget _buildSectionD_Personil() {
    return _buildCard(
      title: 'D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR',
      badge: '${_personilList.length} Personil',
      children: [
        ..._personilList.asMap().entries.map((entry) {
          final idx = entry.key;
          final p = entry.value;
          final roleCtrl = p['roleController'] as TextEditingController;
          final cacahCtrl = p['cacahController'] as TextEditingController;
          final lokasiCtrl = p['lokasiController'] as TextEditingController;

          return _buildItemCard(
            title: 'Personil #${idx + 1}',
            onDelete: () {
              setState(() {
                _personilList.removeAt(idx);
              });
            },
            children: [
              _buildField(
                controller: roleCtrl,
                label: 'Personil Proyek / Jabatan',
                hintText: 'Contoh: Pelaksana Lapangan, Mandor, Pekerja Kasar',
                isBold: true,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: cacahCtrl,
                label: 'Cacah (Jumlah Orang)',
                hintText: 'Contoh: 4 Orang',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: lokasiCtrl,
                label: 'Lokasi Penugasan',
                hintText: 'Contoh: STA 0+150 - 0+300',
              ),
            ],
          );
        }),
        _buildAddButton('+ Tambah Baris Personil', () => _addPersonilRow(role: '', cacah: '', lokasi: '')),
      ],
    );
  }

  // ─── 7. E. CUACA / BENCANA / KEJADIAN PENGHAMBAT PEKERJAAN ───
  Widget _buildSectionE_Cuaca() {
    return _buildCard(
      title: 'E. CUACA / BENCANA / KEJADIAN PENGHAMBAT PEKERJAAN',
      badge: '${_cuacaKejadianList.length} Baris',
      children: [
        if (_cuacaKejadianList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Text(
                'Tidak ada catatan kejadian / cuaca penghambat.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
          )
        else
          ..._cuacaKejadianList.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;
            final jenisCtrl = m['jenisController'] as TextEditingController;
            final jamCtrl = m['jamController'] as TextEditingController;
            final lokasiCtrl = m['lokasiController'] as TextEditingController;
            final akibatCtrl = m['akibatController'] as TextEditingController;

            return _buildItemCard(
              title: 'Kejadian / Hambatan #${idx + 1}',
              onDelete: () {
                setState(() {
                  _cuacaKejadianList.removeAt(idx);
                });
              },
              children: [
                _buildField(
                  controller: jenisCtrl,
                  label: 'Jenis Kejadian / Cuaca',
                  hintText: 'Contoh: Hujan Deras / Genangan Air / Longsor',
                  isBold: true,
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: jamCtrl,
                  label: 'Jam Kejadian',
                  hintText: 'Contoh: 14:00 - 16:30',
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: lokasiCtrl,
                  label: 'Lokasi Kejadian',
                  hintText: 'Contoh: STA 0+200',
                ),
                const SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggung Jawab Kontraktor?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: m['tanggungJawab'],
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Tidak',
                          child: Text('Tidak (Force Majeure / Alami)', style: TextStyle(fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: 'Ya',
                          child: Text('Ya (Tanggung Jawab Kontraktor)', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          m['tanggungJawab'] = val ?? 'Tidak';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: akibatCtrl,
                  label: 'Akibat terhadap Pekerjaan',
                  hintText: 'Contoh: Pekerjaan penghamparan aspal dihentikan sementara',
                ),
              ],
            );
          }),
        const SizedBox(height: 10),
        _buildAddButton(
          '+ Tambah Baris Cuaca / Hambatan',
          () => _addCuacaRow(jenis: '', jam: '', lokasi: '', tanggungJawab: 'Tidak', akibat: ''),
        ),
      ],
    );
  }

  // ─── 8. F. INSTRUKSI DAN SARAN-SARAN (KONSULTAN SUPERVISI AUTO) ───
  Widget _buildSectionFInstruksi() {
    return _buildCard(
      title: 'F. INSTRUKSI DAN SARAN-SARAN',
      badge: 'Konsultan Supervisi',
      children: [
        const Text(
          'Instruksi dan Saran - Saran',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF374151), letterSpacing: 0.3),
        ),
        const SizedBox(height: 6),
        CleanTextFormField(
          controller: _instruksiKonsultanController,
          maxLines: 4,
          hintText: 'Tuliskan instruksi atau saran teknis untuk kontraktor pelaksana di lapangan...',
          style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        ),
      ],
    );
  }

  // ─── 9. G. TANDA TANGAN (TTD) PENGAWAS ───
  Widget _buildSectionG_TandaTangan() {
    return _buildCard(
      title: 'G. TANDA TANGAN PENGAWAS (TTD)',
      badge: 'Pengesahan',
      children: [
        SignaturePadWidget(
          nameController: _ttdNamaController,
          roleController: _ttdJabatanController,
          initialSignatureBase64: _ttdSignatureBase64,
          onSignatureChanged: (b64) {
            _ttdSignatureBase64 = b64;
          },
        ),
      ],
    );
  }

  // ─── 10. H. DOKUMENTASI FOTO LAPANGAN (KAMERA, FILE, DRAG & DROP) ───
  Widget _buildSectionFoto() {
    return _buildCard(
      title: 'H. DOKUMENTASI FOTO LAPANGAN',
      badge: '${_fotoList.length} Foto',
      children: [
        DropTarget(
          onDragDone: (detail) => _handleDroppedFiles(detail.files),
          onDragEntered: (detail) => setState(() => _isDraggingPhoto = true),
          onDragExited: (detail) => setState(() => _isDraggingPhoto = false),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isDraggingPhoto ? const Color(0xFFEFF6FF) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isDraggingPhoto ? const Color(0xFF2563EB) : const Color(0xFFD1D5DB),
                width: _isDraggingPhoto ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _isDraggingPhoto ? Icons.file_download_outlined : Icons.cloud_upload_outlined,
                  size: 36,
                  color: _isDraggingPhoto ? const Color(0xFF2563EB) : const Color(0xFF6B7280),
                ),
                const SizedBox(height: 8),
                Text(
                  _isDraggingPhoto ? 'Lepaskan file foto di sini...' : 'Tarik & lepas file foto ke sini',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isDraggingPhoto ? const Color(0xFF1D4ED8) : const Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Format JPG, PNG, WEBP langsung dari perangkat',
                  style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _ambilFotoKamera,
                      icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Colors.white),
                      label: const Text('Ambil Kamera', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pilihFotoDariGaleri,
                      icon: const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF1F2937)),
                      label: const Text('Pilih File / Galeri', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        if (_fotoList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada foto dokumentasi yang diunggah.',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _fotoList.asMap().entries.map((entry) {
              final idx = entry.key;
              final fotoStr = entry.value;
              return _buildPhotoThumbnail(idx, fotoStr);
            }).toList(),
          ),
      ],
    );
  }

  Future<void> _ambilFotoKamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        final b64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _fotoList.add(b64);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil foto kamera: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _pilihFotoDariGaleri() async {
    try {
      final List<XFile> photos = await _imagePicker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photos.isNotEmpty) {
        for (final p in photos) {
          final bytes = await p.readAsBytes();
          final ext = p.name.split('.').last.toLowerCase();
          final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
          final b64 = 'data:$mime;base64,${base64Encode(bytes)}';
          _fotoList.add(b64);
        }
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memilih foto: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleDroppedFiles(List<XFile> files) async {
    int addedCount = 0;
    for (final file in files) {
      final ext = file.name.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'heic', 'bmp'].contains(ext)) {
        final bytes = await file.readAsBytes();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        final b64 = 'data:$mime;base64,${base64Encode(bytes)}';
        _fotoList.add(b64);
        addedCount++;
      }
    }
    if (addedCount > 0) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$addedCount foto berhasil ditambahkan via drag and drop'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildPhotoThumbnail(int idx, String fotoStr) {
    final bool isBase64 = fotoStr.startsWith('data:image') || (!fotoStr.startsWith('Foto ') && fotoStr.length > 50);

    return Stack(
      children: [
        GestureDetector(
          onTap: () => _showPhotoPreviewDialog(idx, fotoStr),
          child: Container(
            width: 105,
            height: 95,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFCBD5E1)),
            ),
            clipBehavior: Clip.antiAlias,
            child: isBase64
                ? _buildImageFromBase64(fotoStr)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_outlined, color: Color(0xFF4B5563), size: 28),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          fotoStr,
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        Positioned(
          top: 4,
          left: 4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '#${idx + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Positioned(
          top: 3,
          right: 3,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _fotoList.removeAt(idx);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageFromBase64(String b64, {BoxFit fit = BoxFit.cover, double? width, double? height}) {
    try {
      String clean = b64;
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      final bytes = base64Decode(clean.trim());
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
        ),
      );
    } catch (_) {
      return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
    }
  }

  void _showPhotoPreviewDialog(int idx, String fotoStr) {
    final bool isBase64 = fotoStr.startsWith('data:image') || (!fotoStr.startsWith('Foto ') && fotoStr.length > 50);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF1F2937),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Foto Dokumentasi Lapangan #${idx + 1}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 18),
                    onPressed: () => Navigator.pop(ctx),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
                maxWidth: 600,
              ),
              child: isBase64
                  ? _buildImageFromBase64(fotoStr, fit: BoxFit.contain)
                  : Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image, size: 60, color: Colors.blueGrey),
                          const SizedBox(height: 12),
                          Text(fotoStr, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPER SINKRONISASI PLAT & DATA PERJALANAN ───
  Set<String> _getKnownPlateNumbers() {
    final Set<String> plates = {};
    for (var m in _rekapSuhuLapanganList) {
      final raw = m['nomorKendaraan']?.text.trim() ?? '';
      if (raw.isNotEmpty) {
        final p = PlatNomorUtil.normalize(raw);
        if (p.isNotEmpty) plates.add(p);
      }
    }
    for (var m in _rekapSuhuAmpList) {
      final raw = m['nomorKendaraan']?.text.trim() ?? '';
      if (raw.isNotEmpty) {
        final p = PlatNomorUtil.normalize(raw);
        if (p.isNotEmpty) plates.add(p);
      }
    }
    for (var m in _rekapTonaseAspalList) {
      final raw = m['nomorKendaraan']?.text.trim() ?? '';
      if (raw.isNotEmpty) {
        final p = PlatNomorUtil.normalize(raw);
        if (p.isNotEmpty) plates.add(p);
      }
    }
    return plates;
  }

  Widget _buildPlateInputField({
    required TextEditingController controller,
    required String label,
  }) {
    final knownPlates = _getKnownPlateNumbers();
    final currentText = controller.text.trim();
    final currentPlate = PlatNomorUtil.normalize(currentText);

    // Tampilkan suggestion plat:
    // Jika field kosong, tampilkan semua plat yang sudah pernah diketik di form.
    // Jika field sudah terisi sebagian, tampilkan yang mengandung teks tersebut.
    // Sembunyikan jika sudah persis sama dengan isi field saat ini.
    final suggestions = knownPlates.where((p) {
      if (p.toUpperCase() == currentPlate.toUpperCase()) return false;
      if (currentText.isEmpty) return true;
      final cleanFilter = currentText.toUpperCase().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), '');
      final cleanCandidate = p.toUpperCase().replaceAll(' ', '');
      return cleanCandidate.contains(cleanFilter);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              final norm = PlatNomorUtil.normalize(controller.text);
              if (norm.isNotEmpty && norm != controller.text) {
                setState(() {
                  controller.text = norm;
                });
              }
            }
          },
          child: _buildField(
            controller: controller,
            label: label,
            hintText: 'Contoh: R 8076 OE',
            isBold: true,
            onChanged: (val) {
              setState(() {});
            },
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.touch_app_outlined, size: 14, color: Color(0xFF16A34A)),
                    SizedBox(width: 5),
                    Text(
                      'Pilih Cepat Plat Terdaftar:',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: suggestions.map((p) => InkWell(
                    onTap: () {
                      setState(() {
                        controller.text = p;
                        controller.selection = TextSelection.fromPosition(
                          TextPosition(offset: p.length),
                        );
                      });
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF16A34A), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_shipping, size: 13, color: Color(0xFF16A34A)),
                          const SizedBox(width: 5),
                          Text(
                            p,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── 10. DOKUMEN REKAPITULASI & DATA PERJALANAN ASPAL ───
  Widget _buildSectionRekapitulasiOpsional() {
    return _buildCard(
      title: 'DOKUMEN REKAPITULASI & PERJALANAN ASPAL',
      badge: _enableRekapitulasiAspal ? 'Aktif' : 'Nonaktif',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Aktifkan Dokumen Pengawasan Aspal',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mengaktifkan form Suhu Lapangan, Suhu AMP, Tonase, dan Lembar Data Perjalanan DT',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _enableRekapitulasiAspal,
              onChanged: (val) {
                setState(() {
                  _enableRekapitulasiAspal = val;
                  if (val) {
                    if (_rekapSuhuLapanganList.isEmpty) _addRekapSuhuLapanganRow();
                    if (_rekapSuhuAmpList.isEmpty) _addRekapSuhuAmpRow();
                    if (_rekapTonaseAspalList.isEmpty) _addRekapTonaseAspalRow();
                  }
                });
              },
              activeThumbColor: const Color(0xFF1F2937),
            ),
          ],
        ),
        if (_enableRekapitulasiAspal) ...[
          const SizedBox(height: 12),
          // Informasi Proyek Pengaspalan
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
                  'Informasi Header Pengaspalan',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: _jenisMaterialAspalController,
                  label: 'Jenis Material Aspal',
                  hintText: 'Contoh: AC - WC / AC - BC / HRS',
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: _penyediaAmpController,
                  label: 'Penyedia / Batching Plant AMP',
                  hintText: 'Contoh: CV. SATYA WIGUNA',
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: _jarakTempuhController,
                  label: 'Jarak Tempuh AMP ke Proyek (km)',
                  hintText: 'Contoh: 35.5',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. REKAPITULASI WAKTU TEMPUH DT & SUHU DI LAPANGAN
          _buildRekapSectionCard(
            title: '1. Rekapitulasi Waktu Tempuh DT & Suhu di Lapangan',
            subtitle: 'Kedatangan DT, suhu hampar, jam tuang finisher, dan jam pulang',
            badge: '${_rekapSuhuLapanganList.length} Baris',
            body: _buildRekapSuhuLapanganContent(),
          ),
          const SizedBox(height: 14),

          // 2. REKAPITULASI WAKTU TEMPUH DT & SUHU DI AMP
          _buildRekapSectionCard(
            title: '2. Rekapitulasi Waktu Tempuh DT & Suhu di AMP',
            subtitle: 'Berangkat dari AMP, suhu di AMP, dan jam pulang ke AMP',
            badge: '${_rekapSuhuAmpList.length} Baris',
            body: _buildRekapSuhuAmpContent(),
          ),
          const SizedBox(height: 14),

          // 3. REKAPITULASI TONASE ASPAL
          _buildRekapSectionCard(
            title: '3. Rekapitulasi Tonase Aspal',
            subtitle: 'Nomor kendaraan, tonase tiket, dan kalkulasi otomatis kumulatif',
            badge: '${_rekapTonaseAspalList.length} Baris',
            body: _buildRekapTonaseAspalContent(),
          ),
          const SizedBox(height: 14),

          // 4. DATA PERJALANAN DT (AMP - LAPANGAN - AMP)
          _buildDataPerjalananDtSection(),
        ],
      ],
    );
  }

  Widget _buildRekapSectionCard({
    required String title,
    required String subtitle,
    required String badge,
    required Widget body,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: body,
          ),
        ],
      ),
    );
  }

  Widget _buildRekapSuhuLapanganContent() {
    return Column(
      children: [
        ..._rekapSuhuLapanganList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;

          return _buildItemCard(
            title: 'Kendaraan DT Lapangan #${idx + 1}',
            onDelete: () {
              setState(() {
                _rekapSuhuLapanganList.removeAt(idx);
              });
            },
            children: [
              _buildPlateInputField(
                controller: m['nomorKendaraan']!,
                label: 'Nomor Kendaraan (DT)',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jamDatang']!,
                label: 'Jam Datang di Lapangan',
                hintText: 'Contoh: 08:30 WIB',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['suhu']!,
                label: 'Suhu Hampar (°C)',
                hintText: 'Contoh: 145',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jamMulaiTuang']!,
                label: 'Jam Mulai Tuang ke Finisher',
                hintText: 'Contoh: 08:45 WIB',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jamSelesaiTuang']!,
                label: 'Jam Selesai Tuang',
                hintText: 'Contoh: 09:15 WIB',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jamPulang']!,
                label: 'Jam Pulang Lapangan',
                hintText: 'Contoh: 09:30 WIB',
              ),
            ],
          );
        }),
        const SizedBox(height: 6),
        _buildAddButton(
          '+ Tambah Baris Suhu Lapangan',
          () => _addRekapSuhuLapanganRow(),
        ),
      ],
    );
  }

  Widget _buildRekapSuhuAmpContent() {
    return Column(
      children: [
        ..._rekapSuhuAmpList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;

          return _buildItemCard(
            title: 'Pengiriman AMP #${idx + 1}',
            onDelete: () {
              setState(() {
                _rekapSuhuAmpList.removeAt(idx);
              });
            },
            children: [
              _buildPlateInputField(
                controller: m['nomorKendaraan']!,
                label: 'Nomor Kendaraan (DT)',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jamPergi']!,
                label: 'Jam Berangkat dari AMP',
                hintText: 'Contoh: 07:30 WIB',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['suhuAmp']!,
                label: 'Suhu di AMP (°C)',
                hintText: 'Contoh: 155',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jamPulang']!,
                label: 'Jam Pulang ke AMP',
                hintText: 'Contoh: 10:15 WIB',
              ),
            ],
          );
        }),
        const SizedBox(height: 6),
        _buildAddButton(
          '+ Tambah Baris Suhu AMP',
          () => _addRekapSuhuAmpRow(),
        ),
      ],
    );
  }

  Widget _buildRekapTonaseAspalContent() {
    return Column(
      children: [
        ..._rekapTonaseAspalList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;

          return _buildItemCard(
            title: 'Tiket Tonase Aspal #${idx + 1}',
            onDelete: () {
              setState(() {
                _rekapTonaseAspalList.removeAt(idx);
                _recalculateTonaseKumulatif();
              });
            },
            children: [
              _buildPlateInputField(
                controller: m['nomorKendaraan']!,
                label: 'Nomor Kendaraan (DT)',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['tonaseTiket']!,
                label: 'Tonase Tiket (Ton)',
                hintText: 'Contoh: 8.5',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['jumlahKumulatif']!,
                label: 'Kumulatif (Ton) - Dihitung Otomatis',
                hintText: '0.00',
                readOnly: true,
                isBold: true,
              ),
            ],
          );
        }),
        const SizedBox(height: 6),
        _buildAddButton(
          '+ Tambah Baris Tonase Aspal',
          () => _addRekapTonaseAspalRow(),
        ),
      ],
    );
  }

  // ─── 4. DOKUMEN DATA PERJALANAN DT (OTOMATIS) ───
  Widget _buildDataPerjalananDtSection() {
    final rows = _computeDataPerjalananRows();
    final double totalTonase = rows.fold(0.0, (sum, r) => sum + (r['beratAc'] as double));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1F2937), width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      '4. Dokumen Data Perjalanan DT (AMP - Lapangan - AMP)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Hasil pengawinan otomatis dari data Lapangan, AMP, dan Tonase',
                      style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Text(
                  '${rows.length} Rit Terhitung',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),

          // Ringkasan Statistik Singkat
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Rit', style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
                      const SizedBox(height: 2),
                      Text('${rows.length} Rit', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      const Text('Total Berat AC', style: TextStyle(fontSize: 10.5, color: Color(0xFF6B7280))),
                      const SizedBox(height: 2),
                      Text('${PlatNomorUtil.formatDecimal(totalTonase, fractionDigits: 2)} Ton', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827))),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (rows.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Center(
                child: Text(
                  'Belum ada data perjalanan dump truck.\nMasukkan plat nomor dan jam pada tabel 1, 2, atau 3 di atas.',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 11.5),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...rows.asMap().entries.map((entry) {
              final idx = entry.key;
              final r = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#${idx + 1}  ${r['plate']} (Rit ${r['rit']})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${PlatNomorUtil.formatDecimal(r['beratAc'] as double, fractionDigits: 2)} Ton',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AMP ${r['jamDariAmp']} ➔ Lap. ${r['jamTibaLokasi']} (${PlatNomorUtil.formatDecimal(r['waktuBerangkatJam'] as double, fractionDigits: 2)} Jam • ${PlatNomorUtil.formatDecimal(r['kecepatanBerangkat'] as double, fractionDigits: 1)} km/jam)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF374151)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Suhu: ${PlatNomorUtil.formatDecimal(r['suhuAmp'] as double, fractionDigits: 0)}°C ➔ ${PlatNomorUtil.formatDecimal(r['suhuLokasi'] as double, fractionDigits: 0)}°C (Turun: ${PlatNomorUtil.formatDecimal(r['selisihSuhu'] as double, fractionDigits: 0)}°C)',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _computeDataPerjalananRows() {
    final double jarakKm = double.tryParse(_jarakTempuhController.text.replaceAll(',', '.')) ?? 35.5;
    return PlatNomorUtil.computeDataPerjalananRows(
      lapanganList: _rekapSuhuLapanganList,
      ampList: _rekapSuhuAmpList,
      tonaseList: _rekapTonaseAspalList,
      jarakKm: jarakKm,
    );
  }

  // ─── 11. FIELD TAMBAHAN / KUSTOM ───
  Widget _buildSectionCustomFields() {
    return _buildCard(
      title: 'FIELD TAMBAHAN / KUSTOM',
      badge: '${_customFields.length} Field',
      children: [
        if (_customFields.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Center(
              child: Text(
                'Belum ada field tambahan.',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ),
          )
        else
          ..._customFields.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;

            return _buildItemCard(
              title: 'Field Kustom #${idx + 1}',
              onDelete: () {
                setState(() {
                  _customFields.removeAt(idx);
                });
              },
              children: [
                _buildField(
                  controller: m['nama']!,
                  label: 'Nama / Judul Field',
                  hintText: 'Contoh: Suhu Rata-rata / Catatan Khusus Lapangan',
                  isBold: true,
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: m['isi']!,
                  label: 'Isi / Keterangan Field',
                  hintText: 'Tuliskan rincian atau nilai catatan...',
                  maxLines: 3,
                ),
              ],
            );
          }),
        const SizedBox(height: 10),
        _buildAddButton(
          '+ Tambah Field Kustom',
          () => _addCustomFieldRow(),
        ),
      ],
    );
  }

  // ─── REUSABLE DOCUMENT UI HELPERS ───
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

  Widget _buildItemCard({
    required String title,
    required VoidCallback onDelete,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool isBold = false,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return CleanTextFormField(
      controller: controller,
      label: label,
      hintText: hintText,
      isBold: isBold,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }

  Widget _buildDocMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD1D5DB)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
        ),
      ),
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