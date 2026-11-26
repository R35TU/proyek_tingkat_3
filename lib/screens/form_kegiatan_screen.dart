import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/utils/indonesian_terbilang.dart';
import 'package:flutter/services.dart';
import '../utils/rupiah_input_formatter.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

class FormKegiatanScreen extends StatefulWidget {
  final ContractModel contract;
  final Map<String, dynamic>? initialKegiatan;
  final int? kegiatanIndex;

  const FormKegiatanScreen({
    super.key,
    required this.contract,
    this.initialKegiatan,
    this.kegiatanIndex,
  });

  @override
  State<FormKegiatanScreen> createState() => _FormKegiatanScreenState();
}

class _FormKegiatanScreenState extends State<FormKegiatanScreen> {
  final _formKey = GlobalKey<FormState>();

  // 1. DATA POKOK KEGIATAN
  late TextEditingController _namaKegiatanCtrl;
  late TextEditingController _lokasiCtrl;
  late TextEditingController _sumberDanaCtrl;

  // 2. KONSULTAN PENGAWAS
  late TextEditingController _konsultanPengawasCtrl;
  late TextEditingController _noSpkKonsultanCtrl;
  late TextEditingController _tglSpkKonsultanCtrl;
  late TextEditingController _noSpmkKonsultanCtrl;
  late TextEditingController _tglSpmkKonsultanCtrl;
  late TextEditingController _awalPelaksanaanCtrl;
  late TextEditingController _akhirPelaksanaanCtrl;
  late TextEditingController _masaPelaksanaanCtrl;
  late TextEditingController _waktuBerjalanCtrl;

  // 3. PENYEDIA JASA / KONTRAKTOR PELAKSANA
  late TextEditingController _kontraktorCtrl;
  late TextEditingController _noSuratPesananCtrl;
  late TextEditingController _tglSuratPesananCtrl;
  late TextEditingController _noSpmkKontraktorCtrl;
  late TextEditingController _tglSpmkKontraktorCtrl;
  late TextEditingController _nilaiKontrakCtrl;
  late TextEditingController _jangkaWaktuCtrl;
  late TextEditingController _tglAkhirSpmkCtrl;

  // 4. STRUKTUR ORGANISASI KEGIATAN
  late TextEditingController _penggunaAnggaranCtrl;
  late TextEditingController _stafTeknis1Ctrl;
  late TextEditingController _stafTeknis2Ctrl;

  // 5. STRUKTUR ORGANISASI KONSULTAN
  late TextEditingController _direkturKonsultanCtrl;
  late TextEditingController _siteEngineerKegiatanCtrl;

  // 6. STRUKTUR ORGANISASI PENYEDIA JASA
  late TextEditingController _pelaksanaLapanganCtrl;
  late TextEditingController _petugasK3Ctrl;

  // Kontraktor user selection from Firestore
  String? _selectedKontraktorUid;
  List<Map<String, dynamic>> _kontraktorUsers = [];
  bool _loadingKontraktorUsers = true;

  bool get isEditing => widget.initialKegiatan != null;
  bool _section2DatesEdited = false;
  bool _section3DatesEdited = false;
  bool _isSyncingDates = false;

  @override
  void initState() {
    super.initState();
    final c = widget.contract;
    final init = widget.initialKegiatan;

    // Helper default duration text
    final defaultDurasi = c.hariKalender > 0
        ? IndonesianTerbilang.formatHariKalender(c.hariKalender)
        : '';

    // 1. Data Pokok
    _namaKegiatanCtrl = TextEditingController(text: init?['namaKegiatan'] ?? '');
    _lokasiCtrl = TextEditingController(text: init?['lokasi'] ?? '');
    _sumberDanaCtrl = TextEditingController(
      text: (init?['sumberDana']?.toString().isNotEmpty == true)
          ? init!['sumberDana']
          : c.sumberDana,
    );

    // 2. Konsultan Pengawas
    _konsultanPengawasCtrl = TextEditingController(
      text: (init?['konsultanPengawas']?.toString().isNotEmpty == true)
          ? init!['konsultanPengawas']
          : 'CV. TATA SAKA CONSULTANT',
    );
    _noSpkKonsultanCtrl = TextEditingController(
      text: (init?['noSpkKonsultan']?.toString().isNotEmpty == true)
          ? init!['noSpkKonsultan']
          : c.nomorSpk,
    );
    _tglSpkKonsultanCtrl = TextEditingController(
      text: (init?['tglSpkKonsultan']?.toString().isNotEmpty == true)
          ? init!['tglSpkKonsultan']
          : c.tglMulaiSpk,
    );
    _noSpmkKonsultanCtrl = TextEditingController(
      text: (init?['noSpmkKonsultan']?.toString().isNotEmpty == true)
          ? init!['noSpmkKonsultan']
          : c.nomorSpmk,
    );
    _tglSpmkKonsultanCtrl = TextEditingController(
      text: (init?['tglSpmkKonsultan']?.toString().isNotEmpty == true)
          ? init!['tglSpmkKonsultan']
          : c.tglMulaiSpmk,
    );
    _awalPelaksanaanCtrl = TextEditingController(
      text: (init?['awalPelaksanaan']?.toString().isNotEmpty == true)
          ? init!['awalPelaksanaan']
          : c.tglMulaiSpmk,
    );
    _akhirPelaksanaanCtrl = TextEditingController(
      text: (init?['akhirPelaksanaan']?.toString().isNotEmpty == true)
          ? init!['akhirPelaksanaan']
          : c.tglSelesaiSpmk,
    );
    _masaPelaksanaanCtrl = TextEditingController(
      text: (init?['masaPelaksanaan']?.toString().isNotEmpty == true)
          ? init!['masaPelaksanaan']
          : defaultDurasi,
    );

    // Hitung waktu berjalan otomatis berdasarkan awal pelaksanaan
    String initWaktuBerjalan = init?['waktuBerjalan'] ?? '';
    if (initWaktuBerjalan.isEmpty) {
      initWaktuBerjalan = KegiatanModel.calculateWaktuBerjalan(_awalPelaksanaanCtrl.text);
    }
    _waktuBerjalanCtrl = TextEditingController(text: initWaktuBerjalan);

    // 3. Penyedia Jasa / Kontraktor
    _kontraktorCtrl = TextEditingController(text: init?['kontraktor'] ?? '');
    _noSuratPesananCtrl = TextEditingController(text: init?['noSuratPesanan'] ?? '');
    _tglSuratPesananCtrl = TextEditingController(
      text: (init?['tglSuratPesanan']?.toString().isNotEmpty == true)
          ? init!['tglSuratPesanan']
          : c.tglMulaiSpk,
    );
    _noSpmkKontraktorCtrl = TextEditingController(text: init?['noSpmkKontraktor'] ?? '');
    _tglSpmkKontraktorCtrl = TextEditingController(
      text: (init?['tglSpmkKontraktor']?.toString().isNotEmpty == true)
          ? init!['tglSpmkKontraktor']
          : c.tglMulaiSpmk,
    );
    _nilaiKontrakCtrl = TextEditingController(
      text: RupiahUtil.formatString(init?['nilaiKontrak'] ?? '', allowDecimals: true),
    );
    _jangkaWaktuCtrl = TextEditingController(
      text: (init?['jangkaWaktu']?.toString().isNotEmpty == true)
          ? init!['jangkaWaktu']
          : defaultDurasi,
    );
    _tglAkhirSpmkCtrl = TextEditingController(
      text: (init?['tglAkhirSpmkKontraktor']?.toString().isNotEmpty == true)
          ? init!['tglAkhirSpmkKontraktor'].toString()
          : KegiatanModel.calculateTanggalAkhirSpmk(
              _tglSpmkKontraktorCtrl.text,
              _jangkaWaktuCtrl.text,
            ),
    );
    _jangkaWaktuCtrl.addListener(_updateTglAkhirSpmk);
    _tglSpmkKontraktorCtrl.addListener(_updateTglAkhirSpmk);

    // 4. Struktur Organisasi Kegiatan
    _penggunaAnggaranCtrl = TextEditingController(
      text: init?['penggunaAnggaran'] ??
          init?['strukturOrganisasiKegiatan']?['penggunaAnggaran'] ??
          '',
    );
    _stafTeknis1Ctrl = TextEditingController(
      text: init?['stafTeknis1'] ??
          init?['stafTeknis'] ??
          init?['strukturOrganisasiKegiatan']?['stafTeknis1'] ??
          init?['strukturOrganisasiKegiatan']?['stafTeknis'] ??
          '',
    );
    _stafTeknis2Ctrl = TextEditingController(
      text: init?['stafTeknis2'] ??
          init?['strukturOrganisasiKegiatan']?['stafTeknis2'] ??
          '',
    );
    final String initialSiteEngineer = (init?['siteEngineerKegiatan']?.toString().isNotEmpty == true)
        ? init!['siteEngineerKegiatan']
        : ((init?['siteEngineer']?.toString().isNotEmpty == true)
            ? init!['siteEngineer']
            : ((init?['strukturOrganisasiKegiatan']?['siteEngineer']?.toString().isNotEmpty == true)
                ? init!['strukturOrganisasiKegiatan']['siteEngineer']
                : ((init?['strukturOrganisasiKonsultan']?['siteEngineer']?.toString().isNotEmpty == true)
                    ? init!['strukturOrganisasiKonsultan']['siteEngineer']
                    : c.siteEngineer)));
    _siteEngineerKegiatanCtrl = TextEditingController(text: initialSiteEngineer);

    // 5. Struktur Organisasi Konsultan (Hanya 1 input Direktur Konsultan)
    final String initialDirektur = (init?['direkturKonsultan']?.toString().isNotEmpty == true)
        ? init!['direkturKonsultan']
        : ((init?['direkturPenyedia']?.toString().isNotEmpty == true)
            ? init!['direkturPenyedia']
            : ((init?['direkturKontraktor']?.toString().isNotEmpty == true)
                ? init!['direkturKontraktor']
                : ((init?['direktur']?.toString().isNotEmpty == true)
                    ? init!['direktur']
                    : ((init?['strukturOrganisasiKonsultan']?['direkturKonsultan']?.toString().isNotEmpty == true)
                        ? init!['strukturOrganisasiKonsultan']['direkturKonsultan']
                        : ((init?['strukturOrganisasiKegiatan']?['direkturPenyedia']?.toString().isNotEmpty == true)
                            ? init!['strukturOrganisasiKegiatan']['direkturPenyedia']
                            : '')))));
    _direkturKonsultanCtrl = TextEditingController(text: initialDirektur);

    // 6. Struktur Organisasi Penyedia Jasa
    _pelaksanaLapanganCtrl = TextEditingController(
      text: init?['pelaksanaLapangan'] ??
          init?['strukturPenyediaJasa']?['pelaksanaLapangan'] ??
          '',
    );
    _petugasK3Ctrl = TextEditingController(
      text: init?['petugasK3'] ??
          init?['ahliK3'] ??
          init?['strukturPenyediaJasa']?['petugasK3'] ??
          '',
    );

    // Listener untuk live update preview
    _noSpkKonsultanCtrl.addListener(_onFieldChanged);
    _tglSpkKonsultanCtrl.addListener(_onFieldChanged);
    _noSpmkKonsultanCtrl.addListener(_onFieldChanged);
    _tglSpmkKonsultanCtrl.addListener(_onFieldChanged);
    _noSuratPesananCtrl.addListener(_onFieldChanged);
    _tglSuratPesananCtrl.addListener(_onFieldChanged);
    _noSpmkKontraktorCtrl.addListener(_onFieldChanged);
    _tglSpmkKontraktorCtrl.addListener(_onFieldChanged);

    // Load kontraktor users from Firestore and pre-select if editing
    _selectedKontraktorUid = init?['kontraktorUid'] as String?;
    if (_selectedKontraktorUid != null && _selectedKontraktorUid!.isEmpty) {
      _selectedKontraktorUid = null;
    }
    _loadKontraktorUsers();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  Future<void> _loadKontraktorUsers() async {
    try {
      // Filter di server agar hanya akun kontraktor yang dibaca (role
      // tersimpan berkapital: 'Kontraktor' / 'kontraktor').
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', whereIn: const ['Kontraktor', 'kontraktor'])
          .get();
      if (mounted) {
        setState(() {
          _kontraktorUsers = snapshot.docs
              .where((doc) {
                final data = doc.data();
                final isActive = data['isActive'] ?? true;
                return isActive != false;
              })
              .map((doc) {
                final data = doc.data();
                return {
                  'uid': doc.id,
                  'namaLengkap': (data['namaLengkap'] ?? '').toString().trim(),
                  'companyOrAgency': (data['companyOrAgency'] ?? '').toString().trim(),
                };
              })
              .toList();

          // Auto-match if editing and UID was not previously saved but company name matches
          if (_selectedKontraktorUid == null && _kontraktorCtrl.text.isNotEmpty) {
            final cleanCtrl = _kontraktorCtrl.text.trim().toLowerCase();
            final matched = _kontraktorUsers.cast<Map<String, dynamic>?>().firstWhere(
              (u) {
                final comp = (u?['companyOrAgency'] ?? '').toString().toLowerCase();
                final name = (u?['namaLengkap'] ?? '').toString().toLowerCase();
                return (comp.isNotEmpty && (cleanCtrl.contains(comp) || comp.contains(cleanCtrl))) ||
                    (name.isNotEmpty && (cleanCtrl.contains(name) || name.contains(cleanCtrl)));
              },
              orElse: () => null,
            );
            if (matched != null) {
              _selectedKontraktorUid = matched['uid'] as String?;
            }
          }
          _loadingKontraktorUsers = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading kontraktor users: $e');
      if (mounted) {
        setState(() => _loadingKontraktorUsers = false);
      }
    }
  }

  @override
  void dispose() {
    _namaKegiatanCtrl.dispose();
    _lokasiCtrl.dispose();
    _sumberDanaCtrl.dispose();
    _konsultanPengawasCtrl.dispose();
    _noSpkKonsultanCtrl.dispose();
    _tglSpkKonsultanCtrl.dispose();
    _noSpmkKonsultanCtrl.dispose();
    _tglSpmkKonsultanCtrl.dispose();
    _awalPelaksanaanCtrl.dispose();
    _akhirPelaksanaanCtrl.dispose();
    _masaPelaksanaanCtrl.dispose();
    _waktuBerjalanCtrl.dispose();
    _kontraktorCtrl.dispose();
    _noSuratPesananCtrl.dispose();
    _tglSuratPesananCtrl.dispose();
    _noSpmkKontraktorCtrl.dispose();
    _tglSpmkKontraktorCtrl.dispose();
    _nilaiKontrakCtrl.dispose();
    _jangkaWaktuCtrl.removeListener(_updateTglAkhirSpmk);
    _jangkaWaktuCtrl.dispose();
    _tglSpmkKontraktorCtrl.removeListener(_updateTglAkhirSpmk);
    _tglAkhirSpmkCtrl.dispose();
    _penggunaAnggaranCtrl.dispose();
    _stafTeknis1Ctrl.dispose();
    _stafTeknis2Ctrl.dispose();
    _direkturKonsultanCtrl.dispose();
    _siteEngineerKegiatanCtrl.dispose();
    _pelaksanaLapanganCtrl.dispose();
    _petugasK3Ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateFor(TextEditingController controller, {bool updateWaktuBerjalan = false}) async {
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

    if (picked != null) {
      final formatted = WeeklyReportModel.formatIndonesianDate(picked);
      setState(() {
        controller.text = formatted;
        if (controller == _awalPelaksanaanCtrl || controller == _akhirPelaksanaanCtrl) {
          _syncFromSection2DatePicked(controller, picked, formatted);
        } else if (controller == _tglSpmkKontraktorCtrl) {
          _syncFromSection3Change();
        } else if (updateWaktuBerjalan) {
          _waktuBerjalanCtrl.text = KegiatanModel.calculateWaktuBerjalan(formatted);
        }
      });
    }
  }

  int? _extractDaysCount(String text) {
    final m = RegExp(r'\d+').firstMatch(text.trim());
    if (m == null) return null;
    final v = int.tryParse(m.group(0)!);
    return (v != null && v > 0) ? v : null;
  }

  void _syncFromSection2DatePicked(
    TextEditingController controller,
    DateTime picked,
    String formatted,
  ) {
    if (_isSyncingDates) return;
    _section2DatesEdited = true;
    _isSyncingDates = true;
    try {
      if (controller == _awalPelaksanaanCtrl) {
        final days = _extractDaysCount(_masaPelaksanaanCtrl.text) ??
            _extractDaysCount(_jangkaWaktuCtrl.text) ??
            (widget.contract.hariKalender > 0 ? widget.contract.hariKalender : null);
        if (days != null && days > 0) {
          final endDt = DateTime(picked.year, picked.month, picked.day + days - 1);
          _akhirPelaksanaanCtrl.text = WeeklyReportModel.formatIndonesianDate(endDt);
        }
        _waktuBerjalanCtrl.text = KegiatanModel.calculateWaktuBerjalan(formatted);
        if (!_section3DatesEdited) {
          _tglSpmkKonsultanCtrl.text = formatted;
          _tglSpmkKontraktorCtrl.text = formatted;
          if (_jangkaWaktuCtrl.text.trim().isEmpty && _masaPelaksanaanCtrl.text.trim().isNotEmpty) {
            _jangkaWaktuCtrl.text = _masaPelaksanaanCtrl.text.trim();
          }
          _updateTglAkhirSpmk();
        }
      } else if (controller == _akhirPelaksanaanCtrl) {
        final awalDt = WeeklyReportModel.parseIndonesianDate(_awalPelaksanaanCtrl.text);
        if (awalDt != null) {
          final startOnly = DateTime(awalDt.year, awalDt.month, awalDt.day);
          final endOnly = DateTime(picked.year, picked.month, picked.day);
          final diffDays = endOnly.difference(startOnly).inDays + 1;
          if (diffDays > 0) {
            final formattedDur = IndonesianTerbilang.formatHariKalender(diffDays);
            _masaPelaksanaanCtrl.text = formattedDur;
            if (!_section3DatesEdited) {
              _jangkaWaktuCtrl.text = formattedDur;
              _tglAkhirSpmkCtrl.text = formatted;
            }
          }
        }
      }
    } finally {
      _isSyncingDates = false;
    }
  }

  void _syncFromSection2DurationChanged(String val) {
    if (_isSyncingDates) return;
    _section2DatesEdited = true;
    _isSyncingDates = true;
    try {
      final calcEnd = KegiatanModel.calculateTanggalAkhirSpmk(
        _awalPelaksanaanCtrl.text,
        val,
      );
      if (calcEnd.isNotEmpty) {
        _akhirPelaksanaanCtrl.text = calcEnd;
      }
      if (!_section3DatesEdited) {
        _jangkaWaktuCtrl.text = val;
        _updateTglAkhirSpmk();
      }
    } finally {
      _isSyncingDates = false;
    }
  }

  void _syncFromSection3Change() {
    if (_isSyncingDates) return;
    _section3DatesEdited = true;
    _isSyncingDates = true;
    try {
      _updateTglAkhirSpmk();
      if (!_section2DatesEdited) {
        final spmkText = _tglSpmkKontraktorCtrl.text.trim();
        final akhirText = _tglAkhirSpmkCtrl.text.trim();
        final durasiText = _jangkaWaktuCtrl.text.trim();
        if (spmkText.isNotEmpty) {
          _tglSpmkKonsultanCtrl.text = spmkText;
          _awalPelaksanaanCtrl.text = spmkText;
          _waktuBerjalanCtrl.text = KegiatanModel.calculateWaktuBerjalan(spmkText);
        }
        if (akhirText.isNotEmpty) {
          _akhirPelaksanaanCtrl.text = akhirText;
        }
        if (durasiText.isNotEmpty) {
          _masaPelaksanaanCtrl.text = durasiText;
        }
      }
    } finally {
      _isSyncingDates = false;
    }
  }

  void _updateTglAkhirSpmk() {
    final calculated = KegiatanModel.calculateTanggalAkhirSpmk(
      _tglSpmkKontraktorCtrl.text,
      _jangkaWaktuCtrl.text,
    );
    if (_tglAkhirSpmkCtrl.text != calculated) {
      _tglAkhirSpmkCtrl.text = calculated;
    }
  }





  void _simpan() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi field wajib bertanda bintang (*)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final Map<String, dynamic> kegiatanData = {
      if (widget.initialKegiatan != null) ...widget.initialKegiatan!,
      'namaKegiatan': _namaKegiatanCtrl.text.trim(),
      'lokasi': _lokasiCtrl.text.trim(),
      'sumberDana': _sumberDanaCtrl.text.trim(),
      'konsultanPengawas': _konsultanPengawasCtrl.text.trim(),
      'noSpkKonsultan': _noSpkKonsultanCtrl.text.trim(),
      'tglSpkKonsultan': _tglSpkKonsultanCtrl.text.trim(),
      'noSpmkKonsultan': _noSpmkKonsultanCtrl.text.trim(),
      'tglSpmkKonsultan': _tglSpmkKonsultanCtrl.text.trim(),
      'awalPelaksanaan': _awalPelaksanaanCtrl.text.trim(),
      'akhirPelaksanaan': _akhirPelaksanaanCtrl.text.trim(),
      'masaPelaksanaan': _masaPelaksanaanCtrl.text.trim(),
      'waktuBerjalan': _waktuBerjalanCtrl.text.trim(),
      'kontraktor': _kontraktorCtrl.text.trim(),
      'kontraktorUid': _selectedKontraktorUid ?? '',
      'noSuratPesanan': _noSuratPesananCtrl.text.trim(),
      'tglSuratPesanan': _tglSuratPesananCtrl.text.trim(),
      'noSpmkKontraktor': _noSpmkKontraktorCtrl.text.trim(),
      'tglSpmkKontraktor': _tglSpmkKontraktorCtrl.text.trim(),
      'nilaiKontrak': _nilaiKontrakCtrl.text.trim().isNotEmpty
          ? 'Rp ${_nilaiKontrakCtrl.text.trim()}'
          : '',
      'jangkaWaktu': _jangkaWaktuCtrl.text.trim(),
      'tglAkhirSpmkKontraktor': _tglAkhirSpmkCtrl.text.trim().isNotEmpty
          ? _tglAkhirSpmkCtrl.text.trim()
          : KegiatanModel.calculateTanggalAkhirSpmk(
              _tglSpmkKontraktorCtrl.text.trim(),
              _jangkaWaktuCtrl.text.trim(),
            ),
      'penggunaAnggaran': _penggunaAnggaranCtrl.text.trim(),
      'stafTeknis1': _stafTeknis1Ctrl.text.trim(),
      'stafTeknis2': _stafTeknis2Ctrl.text.trim(),
      'direkturKonsultan': _direkturKonsultanCtrl.text.trim(),
      'direkturPenyedia': _direkturKonsultanCtrl.text.trim(),
      'direkturKontraktor': _direkturKonsultanCtrl.text.trim(),
      'siteEngineerKegiatan': _siteEngineerKegiatanCtrl.text.trim(),
      'pelaksanaLapangan': _pelaksanaLapanganCtrl.text.trim(),
      'petugasK3': _petugasK3Ctrl.text.trim(),
      'strukturOrganisasiKegiatan': {
        'penggunaAnggaran': _penggunaAnggaranCtrl.text.trim(),
        'stafTeknis1': _stafTeknis1Ctrl.text.trim(),
        'stafTeknis2': _stafTeknis2Ctrl.text.trim(),
      },
      'strukturOrganisasiKonsultan': {
        'direkturKonsultan': _direkturKonsultanCtrl.text.trim(),
        'siteEngineer': _siteEngineerKegiatanCtrl.text.trim(),
      },
      'strukturPenyediaJasa': {
        'pelaksanaLapangan': _pelaksanaLapanganCtrl.text.trim(),
        'petugasK3': _petugasK3Ctrl.text.trim(),
      },
    };

    Navigator.pop(context, kegiatanData);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final pageTitle = isEditing ? 'Edit Data Kegiatan' : 'Tambah Kegiatan Baru';

    final headerActions = [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: TextButton(
          onPressed: _simpan,
          child: Text(
            'Simpan',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDesktop ? Colors.white : const Color(0xFF111827),
              fontSize: 14,
            ),
          ),
        ),
      ),
    ];

    final mainBody = Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. DATA POKOK KEGIATAN
            _buildSection1DataPokok(),
            const SizedBox(height: 16),

            // 2. KONSULTAN PENGAWAS
            _buildSection2KonsultanPengawas(),
            const SizedBox(height: 16),

            // 3. PENYEDIA JASA / KONTRAKTOR PELAKSANA
            _buildSection3KontraktorPelaksana(),
            const SizedBox(height: 16),

            // 4. STRUKTUR ORGANISASI KEGIATAN
            _buildSection4StrukturKegiatan(),
            const SizedBox(height: 16),

            // 5. STRUKTUR ORGANISASI PENYEDIA JASA
            _buildSection5StrukturPenyediaJasa(),
            const SizedBox(height: 28),

            // TOMBOL SIMPAN
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1F2937),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: Text(
                  isEditing ? 'Perbarui Data Kegiatan' : 'Simpan Data Kegiatan',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );

    if (isDesktop) {
      return WebDashboardLayout(
        title: '$pageTitle: ${widget.contract.namaKontrak}',
        activeMenu: 'kontrak',
        showBackButton: true,
        actions: headerActions,
        child: mainBody,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pageTitle,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              widget.contract.namaKontrak,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
            ),
          ],
        ),
        actions: headerActions,
      ),
      body: mainBody,
    );
  }

  // 1. DATA POKOK KEGIATAN
  Widget _buildSection1DataPokok() {
    return _buildCard(
      title: 'Data Pokok Kegiatan',
      children: [
        _buildField(
          controller: _namaKegiatanCtrl,
          label: 'Nama Kegiatan *',
          maxLines: 2,
          isBold: true,
          validator: (val) => val == null || val.trim().isEmpty ? 'Nama kegiatan wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _lokasiCtrl,
          label: 'Lokasi Kegiatan *',
          validator: (val) => val == null || val.trim().isEmpty ? 'Lokasi kegiatan wajib diisi' : null,
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _sumberDanaCtrl,
          label: 'Sumber Dana',
        ),
      ],
    );
  }

  // 2. KONSULTAN PENGAWAS
  Widget _buildSection2KonsultanPengawas() {
    return _buildCard(
      title: 'Konsultan Pengawas',
      children: [
        _buildField(
          controller: _konsultanPengawasCtrl,
          label: 'Konsultan Pengawas',
          isBold: true,
        ),
        const SizedBox(height: 16),

        // No. SPK
        _buildDocGroup(
          label: 'No. SPK / Kontrak Pengawas',
          docController: _noSpkKonsultanCtrl,
          dateController: _tglSpkKonsultanCtrl,
        ),
        const SizedBox(height: 14),

        // No. SPMK
        _buildDocGroup(
          label: 'No. SPMK Pengawas',
          docController: _noSpmkKonsultanCtrl,
          dateController: _tglSpmkKonsultanCtrl,
        ),
        const SizedBox(height: 16),

        // Awal & Akhir Pelaksanaan
        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: _awalPelaksanaanCtrl,
                label: 'Awal Pelaksanaan',
                fontSize: 12,
                readOnly: true,
                onTap: () => _pickDateFor(_awalPelaksanaanCtrl, updateWaktuBerjalan: true),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF6B7280), size: 18),
                  onPressed: () => _pickDateFor(_awalPelaksanaanCtrl, updateWaktuBerjalan: true),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildField(
                controller: _akhirPelaksanaanCtrl,
                label: 'Akhir Pelaksanaan',
                fontSize: 12,
                readOnly: true,
                onTap: () => _pickDateFor(_akhirPelaksanaanCtrl),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF6B7280), size: 18),
                  onPressed: () => _pickDateFor(_akhirPelaksanaanCtrl),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Masa Pelaksanaan
        _buildField(
          controller: _masaPelaksanaanCtrl,
          label: 'Masa Pelaksanaan',
          onChanged: (val) => setState(() => _syncFromSection2DurationChanged(val)),
        ),
      ],
    );
  }

  // 3. PENYEDIA JASA / KONTRAKTOR PELAKSANA
  Widget _buildSection3KontraktorPelaksana() {
    return _buildCard(
      title: 'Penyedia Jasa / Kontraktor Pelaksana',
      children: [
        // Dropdown to select kontraktor user from Firestore
        const Text(
          'Tautkan Akun Kontraktor Terdaftar (Admin)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        if (_loadingKontraktorUsers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                ),
                SizedBox(width: 10),
                Text(
                  'Memuat daftar akun kontraktor...',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          )
        else if (_kontraktorUsers.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum ada akun kontraktor aktif di menu Admin. Silakan ketik nama kontraktor manual.',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: _kontraktorUsers.any((u) => u['uid'] == _selectedKontraktorUid)
                ? _selectedKontraktorUid
                : null,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
              ),
              fillColor: Colors.white,
              filled: true,
              hintText: 'Pilih akun kontraktor agar terhubung ke dashboard-nya',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text(
                  '— Tanpa Tautan Akun (Input Manual) —',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                ),
              ),
              ..._kontraktorUsers.map((user) {
                final label = '${user['namaLengkap']} (${user['companyOrAgency']})';
                return DropdownMenuItem<String>(
                  value: user['uid'] as String,
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 12.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }),
            ],
            onChanged: (uid) {
              setState(() {
                _selectedKontraktorUid = uid;
                if (uid != null) {
                  final user = _kontraktorUsers.firstWhere(
                    (u) => u['uid'] == uid,
                    orElse: () => <String, dynamic>{},
                  );
                  if (user.isNotEmpty) {
                    _kontraktorCtrl.text = user['companyOrAgency'] ?? '';
                  }
                }
              });
            },
          ),
        const SizedBox(height: 14),
        _buildField(
          controller: _kontraktorCtrl,
          label: 'Kontraktor Pelaksana *',
          isBold: true,
          validator: (val) => val == null || val.trim().isEmpty ? 'Kontraktor pelaksana wajib diisi' : null,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: UserProfileProvider.registeredContractors.map((company) {
            final isSelected = _kontraktorCtrl.text.trim().toLowerCase() == company.toLowerCase();
            return ActionChip(
              avatar: Icon(
                isSelected ? Icons.check_circle : Icons.business,
                size: 14,
                color: isSelected ? Colors.white : AppColors.primaryBlue,
              ),
              label: Text(
                company,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
              backgroundColor: isSelected ? AppColors.primaryBlue : AppColors.cardBackground,
              side: BorderSide(
                color: isSelected ? AppColors.primaryBlue : AppColors.border,
              ),
              onPressed: () {
                setState(() {
                  _kontraktorCtrl.text = company;
                  // Try to match a registered kontraktor user by company name
                  final matchedUser = _kontraktorUsers.cast<Map<String, dynamic>?>().firstWhere(
                    (u) => (u?['companyOrAgency'] ?? '').toString().toLowerCase() == company.toLowerCase(),
                    orElse: () => null,
                  );
                  _selectedKontraktorUid = matchedUser?['uid'] as String?;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Nilai Kontrak
        _buildField(
          controller: _nilaiKontrakCtrl,
          label: 'Nilai Kontrak Kegiatan *',
          isBold: true,
          prefixText: 'Rp ',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [RupiahInputFormatter(allowDecimals: true)],
          validator: (val) => val == null || val.trim().isEmpty ? 'Nilai kontrak kegiatan wajib diisi' : null,
        ),
        const SizedBox(height: 16),

        // No. Surat Pesanan
        _buildDocGroup(
          label: 'No. Surat Pesanan / SPK Kontraktor',
          docController: _noSuratPesananCtrl,
          dateController: _tglSuratPesananCtrl,
        ),
        const SizedBox(height: 14),

        // No. SPMK Kontraktor
        _buildDocGroup(
          label: 'No. SPMK Kontraktor Pelaksana',
          docController: _noSpmkKontraktorCtrl,
          dateController: _tglSpmkKontraktorCtrl,
        ),
        const SizedBox(height: 14),

        // Jangka Waktu
        _buildField(
          controller: _jangkaWaktuCtrl,
          label: 'Jangka Waktu Pelaksanaan',
          onChanged: (_) => setState(() => _syncFromSection3Change()),
        ),
        const SizedBox(height: 14),

        // Tanggal Akhir SPMK (Dihitung Otomatis)
        _buildField(
          controller: _tglAkhirSpmkCtrl,
          label: 'Tanggal Akhir SPMK',
          readOnly: true,
          suffixIcon: const Icon(Icons.calendar_month, color: Color(0xFF6B7280), size: 18),
        ),
      ],
    );
  }

  // 4. STRUKTUR ORGANISASI KEGIATAN
  Widget _buildSection4StrukturKegiatan() {
    return _buildCard(
      title: 'Struktur Organisasi Kegiatan',
      children: [
        _buildField(
          controller: _penggunaAnggaranCtrl,
          label: 'Pengguna Anggaran / PPK',
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _stafTeknis1Ctrl,
          label: 'Staf Teknis 1',
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _stafTeknis2Ctrl,
          label: 'Staf Teknis 2',
        ),
      ],
    );
  }

  // 5. STRUKTUR ORGANISASI PENYEDIA JASA
  Widget _buildSection5StrukturPenyediaJasa() {
    return _buildCard(
      title: 'Struktur Organisasi Penyedia Jasa',
      children: [
        _buildField(
          controller: _direkturKonsultanCtrl,
          label: 'Direktur Penyedia Jasa',
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _pelaksanaLapanganCtrl,
          label: 'Pelaksana Lapangan',
        ),
        const SizedBox(height: 14),
        _buildField(
          controller: _petugasK3Ctrl,
          label: 'Ahli / Petugas K3',
        ),
      ],
    );
  }

  // ─── HELPER: Document Number + Date group ───
  Widget _buildDocGroup({
    required String label,
    required TextEditingController docController,
    required TextEditingController dateController,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: docController,
          decoration: InputDecoration(
            labelText: 'Nomor',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
            ),
            fillColor: Colors.white,
            filled: true,
          ),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: dateController,
          readOnly: true,
          onTap: () => _pickDateFor(dateController),
          decoration: InputDecoration(
            labelText: 'Tanggal',
            hintText: 'Pilih tanggal...',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
            ),
            fillColor: Colors.white,
            filled: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_month, color: Color(0xFF6B7280), size: 18),
              onPressed: () => _pickDateFor(dateController),
            ),
          ),
          style: const TextStyle(fontSize: 12.5),
        ),
      ],
    );
  }

  // ─── HELPER: Single text field ───
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    bool isBold = false,
    bool readOnly = false,
    VoidCallback? onTap,
    ValueChanged<String>? onChanged,
    double fontSize = 13,
    String? prefixText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      readOnly: readOnly,
      onTap: onTap,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: Color(0xFF111827),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF374151), width: 1.5),
        ),
        fillColor: Colors.white,
        filled: true,
      ),
      style: TextStyle(
        fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
        fontSize: fontSize,
        color: const Color(0xFF111827),
      ),
    );
  }

  // ─── HELPER: Section card ───
  Widget _buildCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD1D5DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB))),
            ),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF374151),
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

