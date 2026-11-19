import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoTimerPicker,
        CupertinoTimerPickerMode,
        CupertinoTheme,
        CupertinoThemeData,
        CupertinoTextThemeData;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/services/storage_service.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/utils/plat_nomor_util.dart';
import 'package:tata_saka_app/widgets/clean_text_form_field.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/signature_pad_widget.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

class BuatLaporanScreen extends StatefulWidget {
  final ContractModel? initialContract;
  final int? initialKegiatanIndex;
  final DateTime? initialDate;
  final Map<String, dynamic>? editReport; // Null jika buat laporan baru
  final bool isEmbedded;

  const BuatLaporanScreen({
    super.key,
    this.initialContract,
    this.initialKegiatanIndex,
    this.initialDate,
    this.editReport,
    this.isEmbedded = false,
  });

  @override
  State<BuatLaporanScreen> createState() => _BuatLaporanScreenState();
}

class _TtdPengawasItem {
  final String id;
  final TextEditingController namaController;
  final TextEditingController jabatanController;
  String? signatureBase64;

  _TtdPengawasItem({
    String? id,
    String nama = '',
    String jabatan = '',
    this.signatureBase64,
  }) : id = id ?? UniqueKey().toString(),
       namaController = TextEditingController(text: nama),
       jabatanController = TextEditingController(text: jabatan);

  void dispose() {
    namaController.dispose();
    jabatanController.dispose();
  }
}

class _BuatLaporanScreenState extends State<BuatLaporanScreen> {
  ContractModel? _selectedContract;
  int? _selectedKegiatanIndex;
  late DateTime _selectedDate;

  // A - D. PEKERJAAN & SUMBER DAYA (No, Jenis, Volume, Lokasi, Materials, Peralatans, Personils)
  final List<Map<String, dynamic>> _pekerjaanList = [];

  // E. CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN (No, Cuaca, Jenis Kejadian, Jam, Lokasi, Tanggung Jwb Kontraktor, Akibat)
  final List<Map<String, dynamic>> _cuacaKejadianList = [];

  // F. INSTRUKSI DAN SARAN-SARAN (Auto Konsultan Supervisi CV. TATA SAKA CONSULTANT)
  final TextEditingController _instruksiKonsultanController =
      TextEditingController();
  final List<Map<String, TextEditingController>> _instruksiList = [];

  // G. TANDA TANGAN (TTD) PENGAWAS (Mendukung Multi-Penandatangan)
  final List<_TtdPengawasItem> _ttdPengawasList = [];

  void _addTtdPengawasRow({
    String nama = '',
    String jabatan = '',
    String? signature,
  }) {
    setState(() {
      _ttdPengawasList.add(
        _TtdPengawasItem(
          nama: nama,
          jabatan: jabatan,
          signatureBase64: signature,
        ),
      );
    });
  }

  void _removeTtdPengawasRow(int index) {
    if (_ttdPengawasList.length > 1) {
      setState(() {
        _ttdPengawasList[index].dispose();
        _ttdPengawasList.removeAt(index);
      });
    }
  }

  // H. DOKUMENTASI FOTO LAPANGAN (Kamera, File, Drag & Drop)
  final List<String> _fotoList = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isDraggingPhoto = false;

  // Field Tambahan / Custom (Murni bebas tanpa suggest nama dan isi)
  final List<Map<String, TextEditingController>> _customFields = [];

  // DOKUMEN REKAPITULASI TAMBAHAN & PERJALANAN DT (OPSIONAL - PEKERJAAN ASPAL)
  bool _enableRekapitulasiAspal = false;
  final TextEditingController _jenisMaterialAspalController =
      TextEditingController();
  final TextEditingController _penyediaAmpController = TextEditingController();
  final TextEditingController _jarakTempuhController = TextEditingController();

  // Rekapitulasi Terpadu Ritase Pengiriman DT Aspal (AMP, Lapangan, dan Tonase)
  final List<Map<String, TextEditingController>> _rekapPengirimanDtList = [];

  // DOKUMEN REKAPITULASI PENGECORAN BETON (OPSIONAL - PEKERJAAN BETON / READY MIX)
  bool _enableRekapitulasiBeton = false;
  final TextEditingController _jenisBetonController = TextEditingController();
  final TextEditingController _penyediaJasaBetonController =
      TextEditingController();
  final List<Map<String, TextEditingController>> _rekapPengecoranBetonList = [];

  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const List<String> _namaHariPanjang = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
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
    // A - D. Pekerjaan & Sumber Daya: baris awal (dengan slot sub-item kosong)
    _pekerjaanList.clear();
    _addPekerjaanRow(jenis: '', volume: '', lokasi: '');

    // E. Cuaca & Kejadian: Kosongkan default (1 baris kosong)
    _addCuacaRow(
      cuaca: '',
      jenisKejadian: '',
      jam: '',
      lokasi: '',
      tanggungJawab: 'Tidak',
      akibat: '',
    );

    // F. Instruksi dan Saran-Saran (Auto Konsultan Supervisi)
    _instruksiKonsultanController.clear();
    _instruksiList.clear();

    // G. Tanda Tangan (TTD) Pengawas
    for (var item in _ttdPengawasList) {
      item.dispose();
    }
    _ttdPengawasList.clear();
    _addTtdPengawasRow(nama: '', jabatan: '');

    // H. Foto Dokumentasi
    _fotoList.clear();

    // Rekapitulasi Aspal & Beton
    _enableRekapitulasiAspal = false;
    _rekapPengirimanDtList.clear();
    _enableRekapitulasiBeton = false;
    _jenisBetonController.clear();
    _penyediaJasaBetonController.clear();
    _rekapPengecoranBetonList.clear();

    // Field custom dibiarkan KOSONG (tanpa sugesti)
  }

  void _loadExistingReport(Map<String, dynamic> r) {
    // A - D. Pekerjaan & Sumber Daya (Material, Alat, Personil)
    final pList = r['pekerjaanList'] as List<dynamic>? ?? [];
    _pekerjaanList.clear();

    if (pList.isNotEmpty) {
      for (int i = 0; i < pList.length; i++) {
        final item = pList[i];
        final matList = (item['materials'] as List<dynamic>?)
            ?.map(
              (m) => Map<String, String>.from(
                (m as Map).map(
                  (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                ),
              ),
            )
            .toList();
        final alatList = (item['peralatans'] as List<dynamic>?)
            ?.map(
              (a) => Map<String, String>.from(
                (a as Map).map(
                  (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                ),
              ),
            )
            .toList();
        final perList = (item['personils'] as List<dynamic>?)
            ?.map(
              (p) => Map<String, String>.from(
                (p as Map).map(
                  (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
                ),
              ),
            )
            .toList();

        // Backward compatibility: If loaded data has no nested sub-items, attach root lists to first pekerjaan
        List<Map<String, String>> finalMats = matList ?? [];
        List<Map<String, String>> finalAlats = alatList ?? [];
        List<Map<String, String>> finalPers = perList ?? [];

        if (matList == null && i == 0) {
          final oldMats = r['materialList'] as List<dynamic>? ?? [];
          finalMats = oldMats
              .map(
                (m) => {
                  'jenis': (m['jenis'] ?? '').toString(),
                  'volume': (m['volume'] ?? '').toString(),
                  'lokasiAwal': (m['lokasiAwal'] ?? m['lokasi'] ?? '')
                      .toString(),
                  'lokasiTujuan': (m['lokasiTujuan'] ?? '').toString(),
                },
              )
              .toList();
        }

        if (alatList == null && i == 0) {
          final oldAlats = r['peralatanList'] as List<dynamic>? ?? [];
          finalAlats = oldAlats
              .map(
                (a) => {
                  'jenis': (a['jenis'] ?? '').toString(),
                  'cacahAktif': (a['cacahAktif'] ?? a['jumlah'] ?? '')
                      .toString(),
                  'jumlah': (a['jumlah'] ?? '').toString(),
                  'noRusak': (a['noRusak'] ?? '').toString(),
                  'jenisRusak': (a['jenisRusak'] ?? '').toString(),
                  'kode': (a['kode'] ?? '').toString(),
                  'rusak': (a['rusak'] ?? a['kondisi'] ?? '').toString(),
                },
              )
              .toList();
        }

        if (perList == null && i == 0) {
          final oldPers = r['personilList'] as List<dynamic>? ?? [];
          finalPers = oldPers
              .map(
                (p) => {
                  'role': (p['role'] ?? '').toString(),
                  'cacah': (p['cacah'] ?? p['count'] ?? '').toString(),
                  'lokasi': (p['lokasi'] ?? '').toString(),
                },
              )
              .toList();
        }

        _addPekerjaanRow(
          jenis: item['jenis'] ?? '',
          volume: item['volume'] ?? '',
          lokasi: item['lokasi'] ?? '',
          noMataPembayaran: item['noMataPembayaran'] ?? '',
          satuan: item['satuan'] ?? '',
          rkkItemId: item['rkkItemId'] ?? '',
          initialMaterials: finalMats,
          initialPeralatans: finalAlats,
          initialPersonils: finalPers,
          addEmptySubRowsIfEmpty: false,
        );
      }
    } else {
      _addPekerjaanRow(
        jenis: r['temuan'] ?? '',
        volume: '',
        lokasi: r['lokasiSta'] ?? '',
      );
    }

    // E. Cuaca
    final cList = r['cuacaKejadianList'] as List<dynamic>? ?? [];
    if (cList.isNotEmpty) {
      for (var item in cList) {
        final rawTj = (item['tanggungJawab'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        final normalizedTj = (rawTj == 'ya' || rawTj.contains('kontraktor'))
            ? 'Ya'
            : 'Tidak';
        _addCuacaRow(
          cuaca: item['cuaca'] ?? '',
          jenisKejadian: item['jenisKejadian'] ?? item['jenis'] ?? '',
          jam: item['jam'] ?? '',
          lokasi: item['lokasi'] ?? '',
          tanggungJawab: normalizedTj,
          akibat: item['akibat'] ?? '',
        );
      }
    } else {
      _addCuacaRow(
        cuaca: '',
        jenisKejadian: '',
        jam: '',
        lokasi: '',
        tanggungJawab: 'Tidak',
        akibat: '',
      );
    }

    // F. Instruksi dan Saran-Saran (Auto Konsultan Supervisi)
    final insList = r['instruksiList'] as List<dynamic>? ?? [];
    final insMap = r['instruksiSaran'] as Map<String, dynamic>?;
    final konsultanUraian =
        r['instruksiKonsultan'] ??
        (insMap?['konsultanUraian']) ??
        (insList.isNotEmpty ? insList.first['uraian'] : r['instruksi']);
    if (konsultanUraian != null && konsultanUraian.toString().isNotEmpty) {
      _instruksiKonsultanController.text = konsultanUraian.toString();
    }

    // G. Tanda Tangan (TTD) Pengawas
    for (var item in _ttdPengawasList) {
      item.dispose();
    }
    _ttdPengawasList.clear();

    final ttdListRaw = r['ttdPengawasList'] as List<dynamic>?;
    if (ttdListRaw != null && ttdListRaw.isNotEmpty) {
      for (var t in ttdListRaw) {
        if (t is Map) {
          _addTtdPengawasRow(
            nama: t['nama']?.toString() ?? '',
            jabatan: t['jabatan']?.toString() ?? '',
            signature: t['signature']?.toString(),
          );
        }
      }
    } else {
      final singleNama = r['ttdNama']?.toString() ?? '';
      final singleJabatan = r['ttdJabatan']?.toString() ?? '';
      final singleSig = r['ttdSignature']?.toString();
      _addTtdPengawasRow(
        nama: singleNama,
        jabatan: singleJabatan,
        signature: singleSig,
      );
    }

    // H. Foto
    final fList = r['fotoList'] as List<dynamic>? ?? [];
    if (fList.isNotEmpty) {
      _fotoList.addAll(List<String>.from(fList));
    }

    // Rekapitulasi Aspal & Data Perjalanan
    _enableRekapitulasiAspal =
        r['hasRekapitulasiAspal'] == true ||
        r['hasRekapSuhuLapangan'] == true ||
        r['hasRekapSuhuAmp'] == true ||
        r['hasRekapTonaseAspal'] == true;

    if (r['jenisMaterialAspal'] != null &&
        r['jenisMaterialAspal'].toString().isNotEmpty) {
      _jenisMaterialAspalController.text = r['jenisMaterialAspal'].toString();
    }
    if (r['penyediaAmp'] != null && r['penyediaAmp'].toString().isNotEmpty) {
      _penyediaAmpController.text = r['penyediaAmp'].toString();
    }
    if (r['jarakTempuh'] != null && r['jarakTempuh'].toString().isNotEmpty) {
      _jarakTempuhController.text = r['jarakTempuh'].toString();
    }

    // Load Rekapitulasi Aspal (Terpadu / Pengiriman DT)
    final pdtList = r['rekapPengirimanDtList'] as List<dynamic>? ?? [];
    if (pdtList.isNotEmpty) {
      _enableRekapitulasiAspal = true;
      for (var item in pdtList) {
        _addRekapPengirimanDtRow(
          nomorKendaraan: PlatNomorUtil.normalize(
            item['nomorKendaraan']?.toString() ?? '',
          ),
          jamPergiAmp: PlatNomorUtil.normalizeTime(
            item['jamPergiAmp']?.toString() ?? '',
          ),
          suhuAmp: item['suhuAmp']?.toString() ?? '',
          jamDatangLap: PlatNomorUtil.normalizeTime(
            item['jamDatangLap']?.toString() ?? '',
          ),
          suhuDatang: item['suhuDatang']?.toString() ?? '',
          waktuAntrian: item['waktuAntrian']?.toString() ?? '5',
          suhuLap:
              item['suhuLap']?.toString() ?? item['suhu']?.toString() ?? '',
          jamMulaiTuang: PlatNomorUtil.normalizeTime(
            item['jamMulaiTuang']?.toString() ?? '',
          ),
          jamSelesaiTuang: PlatNomorUtil.normalizeTime(
            item['jamSelesaiTuang']?.toString() ?? '',
          ),
          suhuPemadatanAkhir: item['suhuPemadatanAkhir']?.toString() ?? '',
          jamPulangLap: PlatNomorUtil.normalizeTime(
            item['jamPulangLap']?.toString() ?? '',
          ),
          jamPulangAmp: PlatNomorUtil.normalizeTime(
            item['jamPulangAmp']?.toString() ?? '',
          ),
          tonaseTiket: item['tonaseTiket']?.toString() ?? '',
          jumlahKumulatif: item['jumlahKumulatif']?.toString() ?? '',
        );
      }
    } else {
      // Fallback: gabungkan data lawas jika laporan lama tersimpan di 3 list terpisah
      final rslList = r['rekapSuhuLapanganList'] as List<dynamic>? ?? [];
      final rsaList = r['rekapSuhuAmpList'] as List<dynamic>? ?? [];
      final rtaList = r['rekapTonaseAspalList'] as List<dynamic>? ?? [];

      final int maxLen = [
        rslList.length,
        rsaList.length,
        rtaList.length,
      ].reduce((a, b) => a > b ? a : b);
      if (maxLen > 0) {
        _enableRekapitulasiAspal = true;
        for (int i = 0; i < maxLen; i++) {
          final lap = i < rslList.length && rslList[i] is Map
              ? rslList[i] as Map
              : null;
          final amp = i < rsaList.length && rsaList[i] is Map
              ? rsaList[i] as Map
              : null;
          final ton = i < rtaList.length && rtaList[i] is Map
              ? rtaList[i] as Map
              : null;

          final plat = PlatNomorUtil.normalize(
            (lap?['nomorKendaraan'] ??
                    amp?['nomorKendaraan'] ??
                    ton?['nomorKendaraan'] ??
                    '')
                .toString(),
          );

          _addRekapPengirimanDtRow(
            nomorKendaraan: plat,
            jamPergiAmp: PlatNomorUtil.normalizeTime(
              amp?['jamPergi']?.toString() ?? '',
            ),
            suhuAmp: amp?['suhuAmp']?.toString() ?? '',
            jamDatangLap: PlatNomorUtil.normalizeTime(
              lap?['jamDatang']?.toString() ?? '',
            ),
            suhuDatang: lap?['suhuDatang']?.toString() ?? '',
            waktuAntrian: lap?['waktuAntrian']?.toString() ?? '5',
            suhuLap:
                lap?['suhu']?.toString() ?? lap?['suhuLap']?.toString() ?? '',
            jamMulaiTuang: PlatNomorUtil.normalizeTime(
              lap?['jamMulaiTuang']?.toString() ?? '',
            ),
            jamSelesaiTuang: PlatNomorUtil.normalizeTime(
              lap?['jamSelesaiTuang']?.toString() ?? '',
            ),
            suhuPemadatanAkhir: lap?['suhuPemadatanAkhir']?.toString() ?? '',
            jamPulangLap: PlatNomorUtil.normalizeTime(
              lap?['jamPulang']?.toString() ?? '',
            ),
            jamPulangAmp: PlatNomorUtil.normalizeTime(
              amp?['jamPulang']?.toString() ?? '',
            ),
            tonaseTiket: ton?['tonaseTiket']?.toString() ?? '',
            jumlahKumulatif: ton?['jumlahKumulatif']?.toString() ?? '',
          );
        }
      }
    }

    // Rekapitulasi Pengecoran Beton (Ready Mix)
    _enableRekapitulasiBeton =
        r['hasRekapBeton'] == true || r['hasRekapitulasiBeton'] == true;
    if (r['jenisBeton'] != null && r['jenisBeton'].toString().isNotEmpty) {
      _jenisBetonController.text = r['jenisBeton'].toString();
    }
    if (r['penyediaJasaBeton'] != null &&
        r['penyediaJasaBeton'].toString().isNotEmpty) {
      _penyediaJasaBetonController.text = r['penyediaJasaBeton'].toString();
    } else if (_currentKegiatan?['kontraktor'] != null) {
      _penyediaJasaBetonController.text = _currentKegiatan!['kontraktor']
          .toString();
    }

    final pBetonList = r['rekapPengecoranBetonList'] as List<dynamic>? ?? [];
    _rekapPengecoranBetonList.clear();
    if (pBetonList.isNotEmpty) {
      _enableRekapitulasiBeton = true;
      for (var item in pBetonList) {
        _addRekapPengecoranBetonRow(
          nomorKendaraan: item['nomorKendaraan']?.toString() ?? '',
          batchingPlant: item['batchingPlant']?.toString() ?? '',
          jamBerangkat: item['jamBerangkat']?.toString() ?? '',
          jamDatang: item['jamDatang']?.toString() ?? '',
          slumpTest: item['slumpTest']?.toString() ?? '',
          volume: item['volume']?.toString() ?? '',
          volumeKumulatif: item['volumeKumulatif']?.toString() ?? '',
        );
      }
    }

    // Custom Fields
    final cfList = r['customFields'] as List<dynamic>? ?? [];
    for (var item in cfList) {
      _addCustomFieldRow(nama: item['nama'] ?? '', isi: item['isi'] ?? '');
    }
  }

  @override
  void dispose() {
    for (var m in _instruksiList) {
      m.values.forEach((c) => c.dispose());
    }

    for (var p in _pekerjaanList) {
      _disposePekerjaanControllers(p);
    }
    for (var m in _cuacaKejadianList) {
      (m['jenisKejadianController'] as TextEditingController?)?.dispose();
      (m['cuacaController'] as TextEditingController?)?.dispose();
      (m['jenisController'] as TextEditingController?)?.dispose();
      (m['jamController'] as TextEditingController?)?.dispose();
      (m['lokasiController'] as TextEditingController?)?.dispose();
      (m['akibatController'] as TextEditingController?)?.dispose();
    }
    for (var m in _customFields) {
      m.values.forEach((c) => c.dispose());
    }
    for (var m in _rekapPengirimanDtList) {
      _disposePengirimanDtControllers(m);
    }
    for (var m in _rekapPengecoranBetonList) {
      _disposeBetonControllers(m);
    }

    _instruksiKonsultanController.dispose();
    for (var item in _ttdPengawasList) {
      item.dispose();
    }
    _ttdPengawasList.clear();
    _jenisMaterialAspalController.dispose();
    _penyediaAmpController.dispose();
    _jarakTempuhController.dispose();
    _jenisBetonController.dispose();
    _penyediaJasaBetonController.dispose();

    super.dispose();
  }

  void _disposePekerjaanControllers(Map<String, dynamic> p) {
    (p['jenis'] as TextEditingController?)?.dispose();
    (p['volume'] as TextEditingController?)?.dispose();
    (p['lokasi'] as TextEditingController?)?.dispose();
    final mats = p['materials'] as List<Map<String, TextEditingController>>?;
    if (mats != null) {
      for (var m in mats) {
        m.values.forEach((c) => c.dispose());
      }
    }
    final alats = p['peralatans'] as List<Map<String, TextEditingController>>?;
    if (alats != null) {
      for (var a in alats) {
        a.values.forEach((c) => c.dispose());
      }
    }
    final pers = p['personils'] as List<Map<String, dynamic>>?;
    if (pers != null) {
      for (var per in pers) {
        (per['roleController'] as TextEditingController?)?.dispose();
        (per['cacahController'] as TextEditingController?)?.dispose();
        (per['lokasiController'] as TextEditingController?)?.dispose();
      }
    }
  }

  // Row Helpers
  /// Menghitung volume kumulatif yang sudah terealisasi pada Laporan Harian sebelumnya
  /// untuk mata pembayaran / uraian pekerjaan tertentu dalam kegiatan yang aktif.
  double _calcSudahDikerjakan({
    String? rkkItemId,
    String? noMataPembayaran,
    String? uraian,
  }) {
    if (_selectedContract == null) return 0.0;
    final keg = _currentKegiatan;
    if (keg == null) return 0.0;
    final reports = (keg['laporans'] as List?) ?? [];

    final currentReportId = widget.editReport?['id'];
    double total = 0.0;

    for (final r in reports) {
      if (r is! Map) continue;
      // Jangan hitung laporan harian saat ini jika sedang dalam mode edit
      if (currentReportId != null && r['id'] == currentReportId) continue;

      final pList = (r['pekerjaanList'] as List?) ?? [];
      for (final p in pList) {
        if (p is! Map) continue;
        final pId = p['rkkItemId']?.toString().trim();
        final pNoMata = p['noMataPembayaran']?.toString().trim();
        final pUraian = (p['uraian'] ?? p['jenis'])?.toString().trim();

        bool match = false;
        if (rkkItemId != null &&
            rkkItemId.isNotEmpty &&
            pId != null &&
            pId.isNotEmpty) {
          match = (rkkItemId == pId);
        }
        if (!match &&
            noMataPembayaran != null &&
            noMataPembayaran.isNotEmpty &&
            pNoMata != null &&
            pNoMata.isNotEmpty) {
          match = (noMataPembayaran == pNoMata);
        }
        if (!match &&
            uraian != null &&
            uraian.isNotEmpty &&
            pUraian != null &&
            pUraian.isNotEmpty) {
          match = (uraian.toLowerCase() == pUraian.toLowerCase());
        }

        if (match) {
          final volRaw = (p['volume'] ?? '0').toString().trim();
          final volClean = volRaw.split(' ').first.replaceAll(',', '.');
          final volVal = double.tryParse(volClean) ?? 0.0;
          total += volVal;
        }
      }
    }
    return total;
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color textColor,
    bool isBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  static String _formatNumber(double n) {
    if (n == n.roundToDouble()) {
      return n.toInt().toString();
    }
    return n.toStringAsFixed(2);
  }

  void _addPekerjaanRow({
    String jenis = '',
    String volume = '',
    String lokasi = '',
    String noMataPembayaran = '',
    String satuan = '',
    String rkkItemId = '',
    double? targetVolume,
    double? hargaSatuan,
    double? nilaiBobot,
    List<Map<String, String>> initialMaterials = const [],
    List<Map<String, String>> initialPeralatans = const [],
    List<Map<String, String>> initialPersonils = const [],
    bool addEmptySubRowsIfEmpty = true,
  }) {
    setState(() {
      final materialsList = <Map<String, TextEditingController>>[];
      for (var m in initialMaterials) {
        materialsList.add({
          'jenis': TextEditingController(text: m['jenis'] ?? ''),
          'volume': TextEditingController(text: m['volume'] ?? ''),
          'lokasiAwal': TextEditingController(text: m['lokasiAwal'] ?? ''),
          'lokasiTujuan': TextEditingController(text: m['lokasiTujuan'] ?? ''),
        });
      }
      if (materialsList.isEmpty && addEmptySubRowsIfEmpty) {
        materialsList.add({
          'jenis': TextEditingController(text: ''),
          'volume': TextEditingController(text: ''),
          'lokasiAwal': TextEditingController(text: ''),
          'lokasiTujuan': TextEditingController(text: ''),
        });
      }

      final peralatansList = <Map<String, TextEditingController>>[];
      for (var p in initialPeralatans) {
        peralatansList.add({
          'jenis': TextEditingController(text: p['jenis'] ?? ''),
          'cacahAktif': TextEditingController(
            text: p['cacahAktif'] ?? p['jumlah'] ?? '',
          ),
          'jumlah': TextEditingController(text: p['jumlah'] ?? ''),
          'noRusak': TextEditingController(text: p['noRusak'] ?? ''),
          'jenisRusak': TextEditingController(text: p['jenisRusak'] ?? ''),
          'kode': TextEditingController(text: p['kode'] ?? ''),
          'rusak': TextEditingController(
            text: p['rusak'] ?? p['kondisi'] ?? '',
          ),
        });
      }
      if (peralatansList.isEmpty && addEmptySubRowsIfEmpty) {
        peralatansList.add({
          'jenis': TextEditingController(text: ''),
          'cacahAktif': TextEditingController(text: ''),
          'jumlah': TextEditingController(text: ''),
          'noRusak': TextEditingController(text: ''),
          'jenisRusak': TextEditingController(text: ''),
          'kode': TextEditingController(text: ''),
          'rusak': TextEditingController(text: ''),
        });
      }

      final personilsList = <Map<String, dynamic>>[];
      for (var per in initialPersonils) {
        personilsList.add({
          'roleController': TextEditingController(text: per['role'] ?? ''),
          'cacahController': TextEditingController(
            text: per['cacah'] ?? per['count'] ?? '',
          ),
          'lokasiController': TextEditingController(text: per['lokasi'] ?? ''),
        });
      }
      if (personilsList.isEmpty && addEmptySubRowsIfEmpty) {
        personilsList.add({
          'roleController': TextEditingController(text: ''),
          'cacahController': TextEditingController(text: ''),
          'lokasiController': TextEditingController(text: ''),
        });
      }

      final volController = TextEditingController(text: volume);
      volController.addListener(() {
        if (mounted) setState(() {});
      });

      _pekerjaanList.add({
        'jenis': TextEditingController(text: jenis),
        'volume': volController,
        'lokasi': TextEditingController(text: lokasi),
        'noMataPembayaran': noMataPembayaran,
        'satuan': satuan,
        'rkkItemId': rkkItemId,
        'targetVolume': targetVolume,
        'hargaSatuan': hargaSatuan,
        'nilaiBobot': nilaiBobot,
        'materials': materialsList,
        'peralatans': peralatansList,
        'personils': personilsList,
      });
    });
  }

  void _addMaterialToPekerjaan(
    int pIdx, {
    String jenis = '',
    String volume = '',
    String lokasiAwal = '',
    String lokasiTujuan = '',
  }) {
    setState(() {
      final materials =
          _pekerjaanList[pIdx]['materials']
              as List<Map<String, TextEditingController>>;
      materials.add({
        'jenis': TextEditingController(text: jenis),
        'volume': TextEditingController(text: volume),
        'lokasiAwal': TextEditingController(text: lokasiAwal),
        'lokasiTujuan': TextEditingController(text: lokasiTujuan),
      });
    });
  }

  void _addPeralatanToPekerjaan(
    int pIdx, {
    String jenis = '',
    String cacahAktif = '',
    String jumlah = '',
    String noRusak = '',
    String jenisRusak = '',
    String kode = '',
    String rusak = '',
  }) {
    setState(() {
      final peralatans =
          _pekerjaanList[pIdx]['peralatans']
              as List<Map<String, TextEditingController>>;
      peralatans.add({
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

  void _addPersonilToPekerjaan(
    int pIdx, {
    String role = '',
    String cacah = '',
    String lokasi = '',
  }) {
    setState(() {
      final personils =
          _pekerjaanList[pIdx]['personils'] as List<Map<String, dynamic>>;
      personils.add({
        'roleController': TextEditingController(text: role),
        'cacahController': TextEditingController(text: cacah),
        'lokasiController': TextEditingController(text: lokasi),
      });
    });
  }

  void _addCuacaRow({
    String cuaca = '',
    String jenisKejadian = '',
    String jam = '',
    String lokasi = '',
    String tanggungJawab = 'Tidak',
    String akibat = '',
    String jenis = '',
  }) {
    setState(() {
      final initialJenis = jenisKejadian.isNotEmpty ? jenisKejadian : jenis;
      _cuacaKejadianList.add({
        'cuacaController': TextEditingController(text: cuaca),
        'jenisKejadianController': TextEditingController(text: initialJenis),
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

  // Helper Rekap Terpadu Ritase Pengiriman DT Aspal
  void _addRekapPengirimanDtRow({
    String nomorKendaraan = '',
    String jamPergiAmp = '',
    String suhuAmp = '',
    String jamDatangLap = '',
    String suhuDatang = '',
    String waktuAntrian = '5',
    String suhuLap = '',
    String jamMulaiTuang = '',
    String jamSelesaiTuang = '',
    String suhuPemadatanAkhir = '',
    String jamPulangLap = '',
    String jamPulangAmp = '',
    String tonaseTiket = '',
    String jumlahKumulatif = '',
  }) {
    setState(() {
      final ctrlPlat = TextEditingController(
        text: PlatNomorUtil.normalize(nomorKendaraan),
      );
      final ctrlTonase = TextEditingController(text: tonaseTiket);
      final ctrlKumulatif = TextEditingController(text: jumlahKumulatif);

      ctrlTonase.addListener(() {
        _recalculateTonaseKumulatif();
      });

      _rekapPengirimanDtList.add({
        'nomorKendaraan': ctrlPlat,
        'jamPergiAmp': TextEditingController(text: jamPergiAmp),
        'suhuAmp': TextEditingController(text: suhuAmp),
        'jamDatangLap': TextEditingController(text: jamDatangLap),
        'suhuDatang': TextEditingController(text: suhuDatang),
        'waktuAntrian': TextEditingController(
          text: waktuAntrian.isNotEmpty ? waktuAntrian : '5',
        ),
        'suhuLap': TextEditingController(text: suhuLap),
        'jamMulaiTuang': TextEditingController(text: jamMulaiTuang),
        'jamSelesaiTuang': TextEditingController(text: jamSelesaiTuang),
        'suhuPemadatanAkhir': TextEditingController(text: suhuPemadatanAkhir),
        'jamPulangLap': TextEditingController(text: jamPulangLap),
        'jamPulangAmp': TextEditingController(text: jamPulangAmp),
        'tonaseTiket': ctrlTonase,
        'jumlahKumulatif': ctrlKumulatif,
      });

      if (tonaseTiket.isNotEmpty && jumlahKumulatif.isEmpty) {
        _recalculateTonaseKumulatif();
      }
    });
  }

  void _disposePengirimanDtControllers(Map<String, TextEditingController> m) {
    for (var c in m.values) {
      c.dispose();
    }
  }

  void _recalculateTonaseKumulatif() {
    double runningTotal = 0;
    for (var row in _rekapPengirimanDtList) {
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

  void _addRekapPengecoranBetonRow({
    String nomorKendaraan = '',
    String batchingPlant = '',
    String jamBerangkat = '',
    String jamDatang = '',
    String slumpTest = '',
    String volume = '',
    String volumeKumulatif = '',
  }) {
    setState(() {
      final ctrlPlat = TextEditingController(
        text: PlatNomorUtil.normalize(nomorKendaraan),
      );
      final ctrlVolume = TextEditingController(text: volume);
      final ctrlKumulatif = TextEditingController(text: volumeKumulatif);

      ctrlVolume.addListener(() {
        _recalculateBetonVolumeKumulatif();
      });

      _rekapPengecoranBetonList.add({
        'nomorKendaraan': ctrlPlat,
        'batchingPlant': TextEditingController(text: batchingPlant),
        'jamBerangkat': TextEditingController(
          text: PlatNomorUtil.normalizeTime(jamBerangkat),
        ),
        'jamDatang': TextEditingController(
          text: PlatNomorUtil.normalizeTime(jamDatang),
        ),
        'slumpTest': TextEditingController(text: slumpTest),
        'volume': ctrlVolume,
        'volumeKumulatif': ctrlKumulatif,
      });

      if (volume.isNotEmpty && volumeKumulatif.isEmpty) {
        _recalculateBetonVolumeKumulatif();
      }
    });
  }

  void _disposeBetonControllers(Map<String, TextEditingController> m) {
    for (var c in m.values) {
      c.dispose();
    }
  }

  void _recalculateBetonVolumeKumulatif() {
    double runningTotal = 0;
    for (var row in _rekapPengecoranBetonList) {
      final vText = row['volume']?.text.trim().replaceAll(',', '.') ?? '';
      final vVal = double.tryParse(vText) ?? 0;
      runningTotal += vVal;
      if (vVal > 0 || vText.isNotEmpty) {
        final formatted = (runningTotal % 1 == 0)
            ? runningTotal.toInt().toString()
            : runningTotal.toStringAsFixed(2);
        row['volumeKumulatif']?.text = formatted;
      }
    }
  }

  Future<void> _pickDate() async {
    final firstDate = DateTime(2015);
    final lastDate = DateTime(2040);
    DateTime initial = _selectedDate;
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

  /// Unggah foto & TTD base64 ke Cloudflare R2, ganti isi list dengan URL publik.
  /// Gagal unggah → biarkan base64 (laporan tetap tersimpan).
  Future<void> _uploadMediaKeR2(String folderBase) async {
    final folder = 'laporan-harian/$folderBase';
    final stamp = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < _fotoList.length; i++) {
      if (!_fotoList[i].startsWith('data:')) continue;
      final ext = _fotoList[i].contains('image/png') ? 'png' : 'jpg';
      try {
        _fotoList[i] = await StorageService.uploadBase64Image(
          base64String: _fotoList[i],
          remotePath: '$folder/foto-$stamp-$i.$ext',
        );
      } catch (_) {}
    }
    for (int i = 0; i < _ttdPengawasList.length; i++) {
      final s = _ttdPengawasList[i].signatureBase64;
      if (s == null || !s.startsWith('data:')) continue;
      try {
        _ttdPengawasList[i].signatureBase64 =
            await StorageService.uploadBase64Image(
              base64String: s,
              remotePath: '$folder/ttd-$stamp-$i.png',
            );
      } catch (_) {}
    }
  }

  Future<void> _simpanLaporan() async {
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
    final reportId = isEdit
        ? widget.editReport!['id']
        : DateTime.now().millisecondsSinceEpoch.toString();

    final keg = _currentKegiatan!;
    final String lokasiKegiatan = keg['lokasi'] ?? '-';
    final String sumberDanaKontrak = _selectedContract!.sumberDana;
    final String namaKontraktor = keg['kontraktor'] ?? '-';

    final rkkFlatItems = _getRkkFlatItems();

    // Validasi Kunci Ketat: Blokir jika volume melebihi sisa kontrak sebelum ada Addendum CCO
    for (int i = 0; i < _pekerjaanList.length; i++) {
      final p = _pekerjaanList[i];
      final jenisPek =
          (p['jenis'] as TextEditingController?)?.text.trim() ?? '';
      final volText =
          (p['volume'] as TextEditingController?)?.text.trim().replaceAll(
            ',',
            '.',
          ) ??
          '';
      final inputVol = double.tryParse(volText.split(' ').first) ?? 0.0;
      final noMata = (p['noMataPembayaran'] ?? '').toString();
      final satuan = (p['satuan'] ?? '').toString();
      final rkkId = (p['rkkItemId'] ?? '').toString();

      double targetVol = 0.0;
      if (p['targetVolume'] != null) {
        targetVol = (p['targetVolume'] as num).toDouble();
      } else if (rkkFlatItems.isNotEmpty) {
        final match = rkkFlatItems.firstWhere(
          (it) =>
              it['id'] == rkkId ||
              it['uraian'].toString().toLowerCase() == jenisPek.toLowerCase(),
          orElse: () => {},
        );
        if (match.isNotEmpty) {
          targetVol =
              double.tryParse(
                (match['volumeCCO'] ?? match['volume'] ?? 0).toString(),
              ) ??
              0.0;
        }
      }

      if (targetVol > 0) {
        final sudahDikerjakan = _calcSudahDikerjakan(
          rkkItemId: rkkId,
          noMataPembayaran: noMata,
          uraian: jenisPek,
        );
        final akumulasi = sudahDikerjakan + inputVol;
        final sisa = targetVol - sudahDikerjakan;

        if (akumulasi > targetVol + 0.0001) {
          final lebih = akumulasi - targetVol;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: const [
                  Icon(Icons.block, color: Color(0xFFDC2626), size: 28),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Penyimpanan Dikunci',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Volume pekerjaan "$jenisPek" melebihi batas kuantitas kontrak/CCO.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Target Kontrak/CCO: ${_formatNumber(targetVol)} $satuan',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '• Realisasi Sebelumnya: ${_formatNumber(sudahDikerjakan)} $satuan',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Sisa Kontrak: ${_formatNumber(sisa > 0 ? sisa : 0)} $satuan',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF047857),
                          ),
                        ),
                        Text(
                          '• Input Hari Ini: ${_formatNumber(inputVol)} $satuan',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Divider(height: 16),
                        Text(
                          '• Akumulasi: ${_formatNumber(akumulasi)} $satuan (Lebih +${_formatNumber(lebih)} $satuan)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Sesuai ketentuan, penambahan volume harus melalui Addendum CCO terlebih dahulu.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Tutup & Perbaiki Volume',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
          return;
        }
      }
    }

    // Unggah foto & TTD ke Cloudflare R2 (ganti base64 → URL) sebelum menyusun payload.
    final kegIdRaw = (keg['id'] ?? keg['namaKegiatan'] ?? 'keg').toString();
    final kegId = kegIdRaw.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    await _uploadMediaKeR2('${_selectedContract!.id}/$kegId/$reportId');
    if (!mounted) return;

    // A. Clean Pekerjaan (dengan sub-items Material, Peralatan, Personil)
    final cleanPekerjaan = _pekerjaanList
        .asMap()
        .entries
        .map((e) {
          final pIdx = e.key + 1;
          final p = e.value;
          final jenisPek =
              (p['jenis'] as TextEditingController?)?.text.trim() ?? '';
          final volPek =
              (p['volume'] as TextEditingController?)?.text.trim() ?? '';
          final lokPek =
              (p['lokasi'] as TextEditingController?)?.text.trim() ?? '';

          final mats =
              (p['materials'] as List<Map<String, TextEditingController>>?) ??
              [];
          final cleanMats = mats
              .asMap()
              .entries
              .map(
                (me) => {
                  'no': '$pIdx.${me.key + 1}',
                  'pekerjaanNama': jenisPek,
                  'pekerjaanIndex': '$pIdx',
                  'jenis': me.value['jenis']?.text.trim() ?? '',
                  'volume': me.value['volume']?.text.trim() ?? '',
                  'lokasiAwal': me.value['lokasiAwal']?.text.trim() ?? '',
                  'lokasiTujuan': me.value['lokasiTujuan']?.text.trim() ?? '',
                },
              )
              .where((m) => m['jenis']!.isNotEmpty)
              .toList();

          final alats =
              (p['peralatans'] as List<Map<String, TextEditingController>>?) ??
              [];
          final cleanAlats = alats
              .asMap()
              .entries
              .map(
                (ae) => {
                  'no': '$pIdx.${ae.key + 1}',
                  'pekerjaanNama': jenisPek,
                  'pekerjaanIndex': '$pIdx',
                  'jenis': ae.value['jenis']?.text.trim() ?? '',
                  'cacahAktif': ae.value['cacahAktif']?.text.trim() ?? '',
                  'jumlah': ae.value['jumlah']?.text.trim() ?? '',
                  'noRusak': ae.value['noRusak']?.text.trim() ?? '',
                  'jenisRusak': ae.value['jenisRusak']?.text.trim() ?? '',
                  'kode': ae.value['kode']?.text.trim() ?? '',
                  'rusak': ae.value['rusak']?.text.trim() ?? '',
                },
              )
              .where(
                (m) => m['jenis']!.isNotEmpty || m['jenisRusak']!.isNotEmpty,
              )
              .toList();

          final pers = (p['personils'] as List<Map<String, dynamic>>?) ?? [];
          final cleanPers = pers
              .asMap()
              .entries
              .map(
                (pe) => {
                  'no': '$pIdx.${pe.key + 1}',
                  'pekerjaanNama': jenisPek,
                  'pekerjaanIndex': '$pIdx',
                  'role':
                      (pe.value['roleController'] as TextEditingController?)
                          ?.text
                          .trim() ??
                      '',
                  'cacah':
                      (pe.value['cacahController'] as TextEditingController?)
                          ?.text
                          .trim() ??
                      '',
                  'lokasi':
                      (pe.value['lokasiController'] as TextEditingController?)
                          ?.text
                          .trim() ??
                      '',
                },
              )
              .where((m) => m['role']!.isNotEmpty)
              .toList();

          return {
            'no': pIdx.toString(),
            'jenis': jenisPek,
            'uraian': jenisPek,
            'volume': volPek,
            'lokasi': lokPek,
            'noMataPembayaran': p['noMataPembayaran'] ?? '',
            'satuan': p['satuan'] ?? '',
            'rkkItemId': p['rkkItemId'] ?? '',
            'targetVolume': p['targetVolume'],
            'hargaSatuan': p['hargaSatuan'],
            'nilaiBobot': p['nilaiBobot'],
            'materials': cleanMats,
            'peralatans': cleanAlats,
            'personils': cleanPers,
          };
        })
        .where((m) => (m['jenis'] as String).isNotEmpty)
        .toList();

    // B, C, D: Flattened Aggregated Lists for root & backward compatibility
    final List<Map<String, String>> cleanMaterial = [];
    final List<Map<String, String>> cleanPeralatan = [];
    final List<Map<String, String>> cleanPersonil = [];

    int matNo = 1;
    int alatNo = 1;
    int persNo = 1;

    for (var p in cleanPekerjaan) {
      final mats = p['materials'] as List<Map<String, String>>;
      for (var m in mats) {
        cleanMaterial.add({...m, 'no': '${matNo++}'});
      }
      final alats = p['peralatans'] as List<Map<String, String>>;
      for (var a in alats) {
        cleanPeralatan.add({...a, 'no': '${alatNo++}'});
      }
      final pers = p['personils'] as List<Map<String, String>>;
      for (var pr in pers) {
        cleanPersonil.add({...pr, 'no': '${persNo++}'});
      }
    }

    // E. Clean Cuaca & Kejadian
    final cleanCuaca = _cuacaKejadianList
        .asMap()
        .entries
        .map((e) {
          final jk =
              (e.value['jenisKejadianController'] as TextEditingController?)
                  ?.text
                  .trim() ??
              (e.value['jenisController'] as TextEditingController?)?.text
                  .trim() ??
              '';
          final cuacaVal =
              (e.value['cuacaController'] as TextEditingController?)?.text
                  .trim() ??
              '';
          return {
            'no': (e.key + 1).toString(),
            'jenisKejadian': jk,
            'cuaca': cuacaVal,
            'jenis': jk.isNotEmpty ? jk : cuacaVal,
            'jam': (e.value['jamController'] as TextEditingController).text
                .trim(),
            'lokasi': (e.value['lokasiController'] as TextEditingController)
                .text
                .trim(),
            'tanggungJawab': e.value['tanggungJawab'] as String? ?? 'Tidak',
            'akibat': (e.value['akibatController'] as TextEditingController)
                .text
                .trim(),
          };
        })
        .where((m) => m['jenisKejadian']!.isNotEmpty || m['cuaca']!.isNotEmpty)
        .toList();

    // F. Clean Instruksi (Konsultan Supervisi CV. TATA SAKA CONSULTANT)
    final String instruksiText = _instruksiKonsultanController.text.trim();
    final cleanInstruksi = instruksiText.isNotEmpty
        ? [
            {
              'no': '1',
              'pihak': 'Konsultan Supervisi (CV. TATA SAKA CONSULTANT)',
              'uraian': instruksiText,
            },
          ]
        : <Map<String, String>>[];

    // Clean Custom Fields (tanpa sugesti nama/isi)
    final cleanCustomFields = _customFields
        .map(
          (c) => {
            'nama': c['nama']?.text.trim() ?? '',
            'isi': c['isi']?.text.trim() ?? '',
          },
        )
        .where((c) => c['nama']!.isNotEmpty)
        .toList();

    // Clean Rekapitulasi Terpadu Pengiriman DT Aspal & Ekspor Lembar Dokumen Resmi
    final List<Map<String, String>> cleanRekapSuhuLapangan = [];
    final List<Map<String, String>> cleanRekapSuhuAmp = [];
    final List<Map<String, String>> cleanRekapTonaseAspal = [];
    final List<Map<String, dynamic>> cleanRekapPengirimanDt = [];

    if (_enableRekapitulasiAspal) {
      for (int i = 0; i < _rekapPengirimanDtList.length; i++) {
        final m = _rekapPengirimanDtList[i];
        final plat = PlatNomorUtil.normalize(
          m['nomorKendaraan']?.text.trim() ?? '',
        );
        final idxStr = '${i + 1}';

        final jamPergiAmp = PlatNomorUtil.normalizeTime(
          m['jamPergiAmp']?.text.trim() ?? '',
        );
        final jamPulangAmp = PlatNomorUtil.normalizeTime(
          m['jamPulangAmp']?.text.trim() ?? '',
        );
        final jamDatangLap = PlatNomorUtil.normalizeTime(
          m['jamDatangLap']?.text.trim() ?? '',
        );
        final jamMulaiTuang = PlatNomorUtil.normalizeTime(
          m['jamMulaiTuang']?.text.trim() ?? '',
        );
        final jamSelesaiTuang = PlatNomorUtil.normalizeTime(
          m['jamSelesaiTuang']?.text.trim() ?? '',
        );
        final jamPulangLap = PlatNomorUtil.normalizeTime(
          m['jamPulangLap']?.text.trim() ?? '',
        );

        cleanRekapPengirimanDt.add({
          'no': idxStr,
          'nomorKendaraan': plat,
          'jamPergiAmp': jamPergiAmp,
          'suhuAmp': m['suhuAmp']?.text.trim() ?? '',
          'jamDatangLap': jamDatangLap,
          'suhuDatang': m['suhuDatang']?.text.trim() ?? '',
          'waktuAntrian': m['waktuAntrian']?.text.trim() ?? '',
          'suhuLap': m['suhuLap']?.text.trim() ?? '',
          'jamMulaiTuang': jamMulaiTuang,
          'jamSelesaiTuang': jamSelesaiTuang,
          'suhuPemadatanAkhir': m['suhuPemadatanAkhir']?.text.trim() ?? '',
          'jamPulangLap': jamPulangLap,
          'jamPulangAmp': jamPulangAmp,
          'tonaseTiket': m['tonaseTiket']?.text.trim() ?? '',
          'jumlahKumulatif': m['jumlahKumulatif']?.text.trim() ?? '',
        });

        cleanRekapSuhuAmp.add({
          'no': idxStr,
          'nomorKendaraan': plat,
          'jamPergi': jamPergiAmp,
          'suhuAmp': m['suhuAmp']?.text.trim() ?? '',
          'jamPulang': jamPulangAmp,
        });

        cleanRekapSuhuLapangan.add({
          'no': idxStr,
          'nomorKendaraan': plat,
          'jamDatang': jamDatangLap,
          'suhuDatang': m['suhuDatang']?.text.trim() ?? '',
          'waktuAntrian': m['waktuAntrian']?.text.trim() ?? '',
          'suhu': m['suhuLap']?.text.trim() ?? '',
          'suhuLap': m['suhuLap']?.text.trim() ?? '',
          'jamMulaiTuang': jamMulaiTuang,
          'jamSelesaiTuang': jamSelesaiTuang,
          'suhuPemadatanAkhir': m['suhuPemadatanAkhir']?.text.trim() ?? '',
          'jamPulang': jamPulangLap,
        });

        cleanRekapTonaseAspal.add({
          'no': idxStr,
          'nomorKendaraan': plat,
          'tonaseTiket': m['tonaseTiket']?.text.trim() ?? '',
          'jumlahKumulatif': m['jumlahKumulatif']?.text.trim() ?? '',
        });
      }
    }

    final List<Map<String, dynamic>> cleanRekapPengecoranBeton = [];
    if (_enableRekapitulasiBeton) {
      for (int i = 0; i < _rekapPengecoranBetonList.length; i++) {
        final m = _rekapPengecoranBetonList[i];
        final plat = PlatNomorUtil.normalize(
          m['nomorKendaraan']?.text.trim() ?? '',
        );
        final jamBerangkat = PlatNomorUtil.normalizeTime(
          m['jamBerangkat']?.text.trim() ?? '',
        );
        final jamDatang = PlatNomorUtil.normalizeTime(
          m['jamDatang']?.text.trim() ?? '',
        );

        cleanRekapPengecoranBeton.add({
          'no': '${i + 1}',
          'nomorKendaraan': plat,
          'batchingPlant': m['batchingPlant']?.text.trim() ?? '',
          'jamBerangkat': jamBerangkat,
          'jamDatang': jamDatang,
          'slumpTest': m['slumpTest']?.text.trim() ?? '',
          'volume': m['volume']?.text.trim() ?? '',
          'volumeKumulatif': m['volumeKumulatif']?.text.trim() ?? '',
        });
      }
    }

    // G. Tanda Tangan (TTD) Digital Pengawas (Bisa lebih dari 1 orang)
    final cleanTtdList = _ttdPengawasList.map((item) {
      return {
        'nama': item.namaController.text.trim(),
        'jabatan': item.jabatanController.text.trim(),
        'signature': item.signatureBase64,
      };
    }).toList();

    final firstTtd = cleanTtdList.isNotEmpty
        ? cleanTtdList.first
        : {'nama': '', 'jabatan': '', 'signature': null};

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
      'ttdPengawasList': cleanTtdList,
      'ttdNama': firstTtd['nama'] ?? '',
      'ttdJabatan': firstTtd['jabatan'] ?? '',
      'ttdSignature': firstTtd['signature'],

      // Field Kustom Dinamis
      'customFields': cleanCustomFields,

      // Dokumen Rekapitulasi Tambahan & Perjalanan DT (Opsional Halaman Terpisah)
      'hasRekapitulasiAspal': _enableRekapitulasiAspal,
      'hasRekapPerjalananDt': _enableRekapitulasiAspal,
      'jenisMaterialAspal': _jenisMaterialAspalController.text.trim(),
      'penyediaAmp': _penyediaAmpController.text.trim(),
      'jarakTempuh': _jarakTempuhController.text.trim(),

      'rekapPengirimanDtList': cleanRekapPengirimanDt,

      'hasRekapSuhuLapangan':
          _enableRekapitulasiAspal && cleanRekapSuhuLapangan.isNotEmpty,
      'rekapSuhuLapanganList': cleanRekapSuhuLapangan,

      'hasRekapSuhuAmp':
          _enableRekapitulasiAspal && cleanRekapSuhuAmp.isNotEmpty,
      'rekapSuhuAmpList': cleanRekapSuhuAmp,

      'hasRekapTonaseAspal':
          _enableRekapitulasiAspal && cleanRekapTonaseAspal.isNotEmpty,
      'rekapTonaseAspalList': cleanRekapTonaseAspal,

      // Dokumen Rekapitulasi Pengecoran Beton Ready Mix (Opsional Halaman Terpisah)
      'hasRekapBeton':
          _enableRekapitulasiBeton && cleanRekapPengecoranBeton.isNotEmpty,
      'hasRekapitulasiBeton': _enableRekapitulasiBeton,
      'jenisBeton': _jenisBetonController.text.trim(),
      'penyediaJasaBeton': _penyediaJasaBetonController.text.trim().isNotEmpty
          ? _penyediaJasaBetonController.text.trim()
          : namaKontraktor,
      'rekapPengecoranBetonList': cleanRekapPengecoranBeton,

      // Backward Compatibility & Kartu
      'temuan': cleanPekerjaan.isNotEmpty
          ? cleanPekerjaan
                .map((p) => '${p['jenis']} (${p['volume']})')
                .join(', ')
          : 'Pekerjaan sesuai buku harian standar.',
      'cuaca': cleanCuaca.isNotEmpty
          ? (cleanCuaca.first['cuaca']!.isNotEmpty
                ? cleanCuaca.first['cuaca']!
                : (cleanCuaca.first['jenisKejadian']!.isNotEmpty
                      ? cleanCuaca.first['jenisKejadian']!
                      : 'Normal'))
          : 'Normal',
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

    Provider.of<ContractProvider>(
      context,
      listen: false,
    ).updateContract(_selectedContract!);

    try {
      final timeline = Provider.of<TimelineProvider>(context, listen: false);
      final kName = keg['namaKegiatan']?.toString() ?? '';
      final kontraktor = keg['kontraktor']?.toString() ?? '';
      final dinas = _selectedContract!.instansiDinas.isNotEmpty
          ? _selectedContract!.instansiDinas.first
          : 'DPU-PR Kab. Purbalingga';
      timeline.logEvent(
        actorName: 'CV. Tata Saka Consultant',
        actionType: isEdit ? 'UPDATE' : 'CREATE',
        entityType: 'LAPORAN_HARIAN',
        contractId: _selectedContract!.id,
        contractName: _selectedContract!.namaKontrak,
        kegiatanName: kName,
        kontraktorName: kontraktor,
        dinasName: dinas,
        customTimestamp: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          DateTime.now().hour,
          DateTime.now().minute,
        ),
        title: isEdit
            ? 'Pembaruan Laporan Harian: $kName ($dateFormatted)'
            : 'Pembuatan Laporan Harian: $kName ($dateFormatted)',
        description:
            'Buku Harian Standar tanggal $dateFormatted telah ${isEdit ? "diperbarui" : "disusun"} untuk kontraktor $kontraktor.',
        metadata: {'tanggal': dateFormatted},
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isEdit
              ? 'Buku Harian Standar ($dateFormatted) berhasil diperbarui!'
              : 'Buku Harian Standar ($dateFormatted) berhasil disimpan!',
        ),
        backgroundColor: AppColors.successGreen,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // Role Dinas: hanya pemantau — pembuatan/pengeditan laporan diblokir.
    final userProf = Provider.of<UserProfileProvider>(context, listen: false);
    if (userProf.isDinas) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.visibility_outlined,
                  color: AppColors.textLight, size: 56),
              const SizedBox(height: 16),
              const Text(
                'Akses Dibatasi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark),
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Role Dinas bersifat pemantau. Pembuatan dan pengeditan '
                  'laporan hanya dapat dilakukan oleh Konsultan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5, color: AppColors.textLight),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Kembali'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      );
    }
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

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final pageTitle = widget.editReport != null
        ? 'Edit Buku Harian Standar'
        : 'Form Buku Harian Standar';

    final saveButton = Padding(
      padding: const EdgeInsets.only(right: 12),
      child: TextButton(
        onPressed: _simpanLaporan,
        style: TextButton.styleFrom(
          backgroundColor: isDesktop ? AppColors.primaryBlue : const Color(0xFF1F2937),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Simpan',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 13,
          ),
        ),
      ),
    );

    final mainBody = SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TANGGAL PENGAWASAN
            _buildOfficialHeader(dateFormatted, lokasiAuto, sumberDanaAuto),
            const SizedBox(height: 16),

            // 2. PILIH KONTRAK & KEGIATAN
            _buildContractAndKegiatanSelector(
              contracts,
              lokasiAuto,
              sumberDanaAuto,
            ),
            const SizedBox(height: 16),

            // 3. A - D. PEKERJAAN & SUMBER DAYA (MATERIAL, ALAT, PERSONIL)
            _buildSectionA_Pekerjaan(),
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

            // 11. DOKUMEN REKAPITULASI (OPSIONAL - PEKERJAAN BETON / READY MIX)
            _buildSectionRekapitulasiBetonOpsional(),
            const SizedBox(height: 16),

            // 12. FIELD TAMBAHAN / CUSTOM
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.editReport != null
                      ? 'Perbarui Buku Harian Standar'
                      : 'Simpan Buku Harian Standar',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/main',
                (route) => false,
              );
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
      ),
      body: mainBody,
    );
  }

  // ─── 1. TANGGAL PENGAWASAN ───
  Widget _buildOfficialHeader(
    String dateFormatted,
    String lokasi,
    String sumberDana,
  ) {
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
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                backgroundColor: const Color(0xFFF9FAFB),
              ),
              child: const Text(
                'Ubah Tanggal',
                style: TextStyle(
                  color: Color(0xFF374151),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── 2. KONTRAK & KEGIATAN ───
  Widget _buildContractAndKegiatanSelector(
    List<ContractModel> contracts,
    String lokasi,
    String sumberDana,
  ) {
    return _buildCard(
      title: 'Pilih Kontrak & Kegiatan',
      children: [
        // Dropdown Kontrak
        const Text(
          'Kontrak *',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<ContractModel>(
          value: _selectedContract,
          isExpanded: true,
          decoration: _cleanInputDec('Pilih Kontrak'),
          items: contracts
              .map(
                (c) => DropdownMenuItem(
                  value: c,
                  child: Text(
                    c.namaKontrak,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            setState(() {
              _selectedContract = val;
              _selectedKegiatanIndex = (val?.kegiatans.isNotEmpty ?? false)
                  ? 0
                  : null;
            });
          },
        ),
        const SizedBox(height: 14),

        // Dropdown Kegiatan
        const Text(
          'Kegiatan *',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.3,
          ),
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
            child: const Text(
              'Belum ada kegiatan pada kontrak ini.',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          )
        else
          DropdownButtonFormField<int>(
            value:
                (_selectedKegiatanIndex != null &&
                    _selectedKegiatanIndex! <
                        _selectedContract!.kegiatans.length)
                ? _selectedKegiatanIndex
                : 0,
            isExpanded: true,
            decoration: _cleanInputDec('Pilih Kegiatan'),
            items: _selectedContract!.kegiatans.asMap().entries.map((entry) {
              final k = entry.value;
              return DropdownMenuItem<int>(
                value: entry.key,
                child: Text(
                  k['namaKegiatan'] ?? 'Kegiatan ${entry.key + 1}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
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
              _buildDocMetaRow(
                'Lokasi Kegiatan',
                lokasi.isNotEmpty ? lokasi : '-',
              ),
              const SizedBox(height: 6),
              _buildDocMetaRow(
                'Sumber Dana',
                sumberDana.isNotEmpty ? sumberDana : '-',
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _getRkkFlatItems() {
    if (_selectedContract == null || _selectedContract!.kegiatans.isEmpty)
      return [];
    final idx = _selectedKegiatanIndex ?? 0;
    if (idx < 0 || idx >= _selectedContract!.kegiatans.length) return [];
    final keg = _selectedContract!.kegiatans[idx];

    // Mengambil RKK yang sedang aktif: dari Addendum CCO terakhir jika ada, atau Kontrak Awal
    List<dynamic> rawRkk = keg['rkkDivisiList'] as List? ?? [];
    final addendums = keg['addendums'] as List? ?? [];
    if (addendums.isNotEmpty) {
      final latest = addendums.last;
      final addendumDivList = latest['rkkDivisiList'] as List?;
      if (addendumDivList != null && addendumDivList.isNotEmpty) {
        rawRkk = addendumDivList;
      }
    }

    final List<Map<String, dynamic>> flat = [];
    for (final div in rawRkk) {
      final romawi = div['nomorRomawi']?.toString() ?? 'I';
      final namaDiv = div['namaDivisi']?.toString() ?? 'DIVISI';
      final items = div['items'] as List? ?? [];
      for (final it in items) {
        final vol = it['volumeCCO'] ?? it['volume'];
        flat.add({
          'id': '${romawi}_${it['uraian']}',
          'divisiRomawi': romawi,
          'divisiNama': namaDiv,
          'noMataPembayaran': it['noMataPembayaran']?.toString() ?? '',
          'uraian': it['uraian']?.toString() ?? '',
          'satuan': it['satuan']?.toString() ?? 'm3',
          'volume': it['volume'] ?? vol,
          'volumeCCO': vol,
          'hargaSatuan': it['hargaSatuan'],
          'totalHarga': it['totalHarga'],
          'nilaiBobot': it['nilaiBobot'],
        });
      }
    }
    return flat;
  }

  // ─── 3. A - D. PEKERJAAN & SUMBER DAYA (MATERIAL, ALAT, PERSONIL) ───
  Widget _buildSectionA_Pekerjaan() {
    final rkkFlatItems = _getRkkFlatItems();

    return _buildCard(
      title: 'A - D. PEKERJAAN & SUMBER DAYA',
      badge: '${_pekerjaanList.length} Pekerjaan',
      children: [
        ..._pekerjaanList.asMap().entries.map((entry) {
          final pIdx = entry.key;
          final p = entry.value;
          final jenisPekCtrl = p['jenis'] as TextEditingController;
          final volPekCtrl = p['volume'] as TextEditingController;
          final lokPekCtrl = p['lokasi'] as TextEditingController;
          final materials =
              p['materials'] as List<Map<String, TextEditingController>>;
          final peralatans =
              p['peralatans'] as List<Map<String, TextEditingController>>;
          final personils = p['personils'] as List<Map<String, dynamic>>;

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Card Pekerjaan
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(11),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Pekerjaan #${pIdx + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_pekerjaanList.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          tooltip: 'Hapus Pekerjaan #${pIdx + 1}',
                          onPressed: () {
                            setState(() {
                              _disposePekerjaanControllers(p);
                              _pekerjaanList.removeAt(pIdx);
                            });
                          },
                        ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sub-Header A. PEKERJAAN
                      const Text(
                        'A. PEKERJAAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dropdown RKK Pekerjaan (Jika Kegiatan memiliki RKK)
                      if (rkkFlatItems.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text(
                              'Pilih dari RKK Kontrak *',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                            const Spacer(),
                            if (p['satuan'] != null &&
                                (p['satuan'] as String).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.slateLighter,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.border,
                                    width: 0.6,
                                  ),
                                ),
                                child: Text(
                                  'Satuan: ${p['satuan']}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.navySlate,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value:
                              (p['rkkItemId'] != null &&
                                  rkkFlatItems.any(
                                    (it) => it['id'] == p['rkkItemId'],
                                  ))
                              ? p['rkkItemId'] as String
                              : (rkkFlatItems.any(
                                      (it) =>
                                          it['uraian']
                                              .toString()
                                              .toLowerCase() ==
                                          jenisPekCtrl.text.toLowerCase(),
                                    )
                                    ? rkkFlatItems.firstWhere(
                                            (it) =>
                                                it['uraian']
                                                    .toString()
                                                    .toLowerCase() ==
                                                jenisPekCtrl.text.toLowerCase(),
                                          )['id']
                                          as String
                                    : (jenisPekCtrl.text.isNotEmpty
                                          ? jenisPekCtrl.text
                                          : null)),
                          isExpanded: true,
                          decoration: _cleanInputDec(
                            'Pilih item pekerjaan dari daftar RKK',
                          ),
                          items: [
                            ...rkkFlatItems.map((item) {
                              return DropdownMenuItem<String>(
                                value: item['id'] as String,
                                child: Text(
                                  item['uraian'] as String,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }),
                            if (jenisPekCtrl.text.isNotEmpty &&
                                !rkkFlatItems.any(
                                  (it) =>
                                      it['id'] == p['rkkItemId'] ||
                                      it['uraian'].toString().toLowerCase() ==
                                          jenisPekCtrl.text.toLowerCase(),
                                ))
                              DropdownMenuItem<String>(
                                value: jenisPekCtrl.text,
                                child: Text(
                                  jenisPekCtrl.text,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                          onChanged: (selectedId) {
                            setState(() {
                              p['rkkItemId'] = selectedId;
                              if (selectedId != null) {
                                final matchedList = rkkFlatItems.where(
                                  (it) => it['id'] == selectedId,
                                );
                                if (matchedList.isNotEmpty) {
                                  final matched = matchedList.first;
                                  jenisPekCtrl.text = matched['uraian'] ?? '';
                                  p['satuan'] = matched['satuan'] ?? '';
                                  p['noMataPembayaran'] =
                                      matched['noMataPembayaran'] ?? '';
                                  p['targetVolume'] =
                                      double.tryParse(
                                        (matched['volumeCCO'] ??
                                                matched['volume'] ??
                                                0)
                                            .toString(),
                                      ) ??
                                      0.0;
                                  p['volumeCCO'] = matched['volumeCCO'];
                                  p['hargaSatuan'] = matched['hargaSatuan'];
                                  p['nilaiBobot'] = matched['nilaiBobot'];
                                }
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 8),

                        // Badges: Mata Pembayaran & Satuan terkunci
                        if ((p['satuan'] != null &&
                                (p['satuan'] as String).isNotEmpty) ||
                            (p['noMataPembayaran'] != null &&
                                (p['noMataPembayaran'] as String)
                                    .isNotEmpty)) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (p['noMataPembayaran'] != null &&
                                  (p['noMataPembayaran'] as String).isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFCBD5E1),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'Mata Pembayaran: ${p['noMataPembayaran']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              if (p['satuan'] != null &&
                                  (p['satuan'] as String).isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFBFDBFE),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'Satuan: ${p['satuan']}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1D4ED8),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                        ],
                      ] else ...[
                        _buildField(
                          controller: jenisPekCtrl,
                          label: 'Jenis Pekerjaan',
                          hintText: 'Contoh: Pekerjaan Galian Tanah / Pemasangan U-Ditch',
                          isBold: true,
                        ),
                        const SizedBox(height: 10),
                      ],

                      // Volume Input
                      _buildField(
                        controller: volPekCtrl,
                        label: 'Volume Realisasi Hari Ini *',
                        hintText:
                            (p['satuan'] != null &&
                                (p['satuan'] as String).isNotEmpty)
                            ? 'Contoh: 0.30 (${p['satuan']})'
                            : 'Contoh: 0.30',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        suffixText:
                            (p['satuan'] != null &&
                                (p['satuan'] as String).isNotEmpty)
                            ? p['satuan'] as String
                            : null,
                      ),

                      // Status Card Target & Akumulasi Realisasi
                      () {
                        final String satuan = (p['satuan'] ?? '').toString();
                        final String noMata = (p['noMataPembayaran'] ?? '')
                            .toString();
                        final String rkkId = (p['rkkItemId'] ?? '').toString();
                        final String jenisStr = jenisPekCtrl.text.trim();

                        double targetVol = 0.0;
                        if (p['targetVolume'] != null) {
                          targetVol = (p['targetVolume'] as num).toDouble();
                        } else if (rkkFlatItems.isNotEmpty) {
                          final match = rkkFlatItems.firstWhere(
                            (it) =>
                                it['id'] == rkkId ||
                                it['uraian'].toString().toLowerCase() ==
                                    jenisStr.toLowerCase(),
                            orElse: () => {},
                          );
                          if (match.isNotEmpty) {
                            targetVol =
                                double.tryParse(
                                  (match['volumeCCO'] ?? match['volume'] ?? 0)
                                      .toString(),
                                ) ??
                                0.0;
                          }
                        }

                        if (targetVol <= 0) return const SizedBox.shrink();

                        final sudahDikerjakan = _calcSudahDikerjakan(
                          rkkItemId: rkkId,
                          noMataPembayaran: noMata,
                          uraian: jenisStr,
                        );

                        final inputVolStr = volPekCtrl.text.trim().replaceAll(
                          ',',
                          '.',
                        );
                        final inputVol =
                            double.tryParse(inputVolStr.split(' ').first) ??
                            0.0;

                        final sisaSebelumHariIni =
                            (targetVol - sudahDikerjakan);
                        final akumulasiTotal = sudahDikerjakan + inputVol;
                        final persenAkumulasi = targetVol > 0
                            ? (akumulasiTotal / targetVol) * 100
                            : 0.0;
                        final bool isOver =
                            targetVol > 0 &&
                            akumulasiTotal > (targetVol + 0.0001);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isOver
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isOver
                                      ? const Color(0xFFF87171)
                                      : const Color(0xFFE2E8F0),
                                  width: isOver ? 1.2 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Status Target & Akumulasi Pekerjaan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: isOver
                                              ? const Color(0xFFB91C1C)
                                              : const Color(0xFF334155),
                                        ),
                                      ),
                                      Text(
                                        '${persenAkumulasi.toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isOver
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF0F766E),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: targetVol > 0
                                          ? (akumulasiTotal / targetVol).clamp(
                                              0.0,
                                              1.0,
                                            )
                                          : 0.0,
                                      backgroundColor: const Color(0xFFE2E8F0),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isOver
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFF10B981),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricTile(
                                          label: 'Target Kontrak',
                                          value:
                                              '${_formatNumber(targetVol)} $satuan',
                                          textColor: const Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildMetricTile(
                                          label: 'Sudah Dikerjakan',
                                          value:
                                              '${_formatNumber(sudahDikerjakan)} $satuan',
                                          textColor: const Color(0xFF475569),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildMetricTile(
                                          label: 'Sisa Target',
                                          value:
                                              '${_formatNumber(sisaSebelumHariIni > 0 ? sisaSebelumHariIni : 0)} $satuan',
                                          textColor: const Color(0xFF0D9488),
                                          isBold: true,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: _buildMetricTile(
                                          label: 'Akumulasi Realisasi',
                                          value:
                                              '${_formatNumber(akumulasiTotal)} $satuan',
                                          textColor: isOver
                                              ? const Color(0xFFDC2626)
                                              : const Color(0xFF1E293B),
                                          isBold: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (isOver) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: const Color(0xFFFCA5A5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Color(0xFFDC2626),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              '⛔ Melebihi target kontrak sebesar +${_formatNumber(akumulasiTotal - targetVol)} $satuan. '
                                              'Penyimpanan dikunci sebelum Addendum CCO diterbitkan.',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF991B1B),
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }(),

                      const SizedBox(height: 10),
                      _buildField(
                        controller: lokPekCtrl,
                        label: 'Lokasi / STA',
                        hintText: 'Contoh: STA 0+150 - STA 0+200',
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 14),

                      // Sub-Header B. MATERIAL DIGUNAKAN
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'B. MATERIAL DIGUNAKAN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Text(
                            '${materials.length} Bahan',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (materials.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Text(
                            'Tidak ada material digunakan untuk pekerjaan ini (opsional).',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...materials.asMap().entries.map((mEntry) {
                          final mIdx = mEntry.key;
                          final m = mEntry.value;
                          return _buildNestedItemCard(
                            title: 'Material #${mIdx + 1}',
                            onDelete: () {
                              setState(() {
                                m.values.forEach((c) => c.dispose());
                                materials.removeAt(mIdx);
                              });
                            },
                            children: [
                              _buildField(
                                controller: m['jenis']!,
                                label: 'Jenis Material',
                                hintText: 'Contoh: Pasir Pasang / Semen Gresik / U-Ditch 40x40',
                                isBold: true,
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: m['volume']!,
                                label: 'Cacah Volume',
                                hintText: 'Contoh: 15 m³ / 20 Unit / 50 Sak',
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: m['lokasiAwal']!,
                                label: 'Lokasi Awal (Asal)',
                                hintText:
                                    'Contoh: Quarry / Basecamp / Gudang Utama',
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: m['lokasiTujuan']!,
                                label: 'Lokasi Tujuan',
                                hintText: 'Contoh: STA 0+150',
                              ),
                            ],
                          );
                        }),
                      const SizedBox(height: 8),
                      _buildSubAddButton(
                        '+ Tambah Material (Pek. #${pIdx + 1})',
                        () => _addMaterialToPekerjaan(pIdx),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 14),

                      // Sub-Header C. JENIS PERALATAN YANG DIGUNAKAN
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'C. JENIS PERALATAN YANG DIGUNAKAN',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Text(
                            '${peralatans.length} Alat',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (peralatans.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Text(
                            'Tidak ada peralatan khusus yang digunakan (opsional).',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...peralatans.asMap().entries.map((aEntry) {
                          final aIdx = aEntry.key;
                          final a = aEntry.value;
                          return _buildNestedItemCard(
                            title: 'Peralatan #${aIdx + 1}',
                            onDelete: () {
                              setState(() {
                                a.values.forEach((c) => c.dispose());
                                peralatans.removeAt(aIdx);
                              });
                            },
                            children: [
                              _buildField(
                                controller: a['jenis']!,
                                label: 'Jenis Peralatan',
                                hintText: 'Contoh: Excavator PC200, Dump Truck',
                                isBold: true,
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: a['cacahAktif']!,
                                label: 'Cacah Aktif',
                                hintText: 'Contoh: 1 Unit',
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: a['jumlah']!,
                                label: 'Jumlah Total',
                                hintText: 'Contoh: 2 Unit',
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: a['kode']!,
                                label: 'Kode Alat (Opsional)',
                                hintText: 'Contoh: EX-01',
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: a['rusak']!,
                                label: 'Kondisi Kerusakan (Jika Ada)',
                                hintText: 'Contoh: Normal / Sedang Perbaikan',
                              ),
                            ],
                          );
                        }),
                      const SizedBox(height: 8),
                      _buildSubAddButton(
                        '+ Tambah Peralatan (Pek. #${pIdx + 1})',
                        () => _addPeralatanToPekerjaan(pIdx),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE5E7EB)),
                      const SizedBox(height: 14),

                      // Sub-Header D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Text(
                            '${personils.length} Personil',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (personils.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: const Text(
                            'Tidak ada personil spesifik (opsional).',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        ...personils.asMap().entries.map((pEntry) {
                          final persIdx = pEntry.key;
                          final pers = pEntry.value;
                          final roleCtrl =
                              pers['roleController'] as TextEditingController;
                          final cacahCtrl =
                              pers['cacahController'] as TextEditingController;
                          final lokasiCtrl =
                              pers['lokasiController'] as TextEditingController;

                          return _buildNestedItemCard(
                            title: 'Personil #${persIdx + 1}',
                            onDelete: () {
                              setState(() {
                                roleCtrl.dispose();
                                cacahCtrl.dispose();
                                lokasiCtrl.dispose();
                                personils.removeAt(persIdx);
                              });
                            },
                            children: [
                              _buildField(
                                controller: roleCtrl,
                                label: 'Personil Proyek / Jabatan',
                                hintText: 'Contoh: Pelaksana Lapangan, Mandor, Pekerja',
                                isBold: true,
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: cacahCtrl,
                                label: 'Cacah (Jumlah Orang)',
                                hintText: 'Contoh: 4 Orang',
                              ),
                              const SizedBox(height: 8),
                              _buildField(
                                controller: lokasiCtrl,
                                label: 'Lokasi Penugasan',
                                hintText: 'Contoh: STA 0+150',
                              ),
                            ],
                          );
                        }),
                      const SizedBox(height: 8),
                      _buildSubAddButton(
                        '+ Tambah Personil (Pek. #${pIdx + 1})',
                        () => _addPersonilToPekerjaan(pIdx),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        _buildAddButton(
          '+ Tambah Baris Pekerjaan Baru',
          () => _addPekerjaanRow(),
        ),
      ],
    );
  }

  Widget _buildSubAddButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.add, size: 14, color: Color(0xFF374151)),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }

  Widget _buildNestedItemCard({
    required String title,
    required VoidCallback onDelete,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              InkWell(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(Icons.close, size: 14, color: Color(0xFF9CA3AF)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
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
            final jenisKejadianCtrl =
                (m['jenisKejadianController'] ?? m['jenisController'])
                    as TextEditingController;
            final cuacaCtrl = m['cuacaController'] as TextEditingController;
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
                  controller: cuacaCtrl,
                  label: 'Cuaca',
                  hintText: 'Contoh: Cerah / Berawan / Hujan Deras / Gerimis',
                  isBold: true,
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: jenisKejadianCtrl,
                  label: 'Jenis Kejadian',
                  hintText: 'Contoh: Genangan Air / Longsor / Banjir',
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
                      value:
                          (m['tanggungJawab'] == 'Ya' ||
                              m['tanggungJawab'] == 'Tidak')
                          ? m['tanggungJawab']
                          : 'Tidak',
                      isExpanded: true,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: Color(0xFF1F2937),
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Tidak',
                          child: Text(
                            'Tidak (Force Majeure / Alami)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'Ya',
                          child: Text(
                            'Ya (Tanggung Jawab Kontraktor)',
                            style: TextStyle(fontSize: 12),
                          ),
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
          () => _addCuacaRow(
            cuaca: '',
            jenisKejadian: '',
            jam: '',
            lokasi: '',
            tanggungJawab: 'Tidak',
            akibat: '',
          ),
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
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            letterSpacing: 0.3,
          ),
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
      badge: '${_ttdPengawasList.length} Pengawas',
      children: [
        ..._ttdPengawasList.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;

          return Container(
            key: ValueKey(item.id),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(9),
                    ),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.navySlate,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'Pengawas #${idx + 1}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (_ttdPengawasList.length > 1)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFDC2626),
                            size: 20,
                          ),
                          tooltip: 'Hapus Penandatangan #${idx + 1}',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _removeTtdPengawasRow(idx),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: SignaturePadWidget(
                    nameController: item.namaController,
                    roleController: item.jabatanController,
                    initialSignatureBase64: item.signatureBase64,
                    onSignatureChanged: (b64) {
                      item.signatureBase64 = b64;
                    },
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _addTtdPengawasRow(nama: '', jabatan: ''),
            icon: const Icon(Icons.add, size: 16, color: AppColors.navySlate),
            label: const Text(
              'Tambah Penandatangan Pengawas',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.navySlate,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              side: const BorderSide(color: AppColors.navySlate, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
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
              color: _isDraggingPhoto
                  ? const Color(0xFFEFF6FF)
                  : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isDraggingPhoto
                    ? const Color(0xFF2563EB)
                    : const Color(0xFFD1D5DB),
                width: _isDraggingPhoto ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _isDraggingPhoto
                      ? Icons.file_download_outlined
                      : Icons.cloud_upload_outlined,
                  size: 36,
                  color: _isDraggingPhoto
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(height: 8),
                Text(
                  _isDraggingPhoto
                      ? 'Lepaskan file foto di sini...'
                      : 'Tarik & lepas file foto ke sini',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _isDraggingPhoto
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF374151),
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
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        size: 16,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Ambil Kamera',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1F2937),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _pilihFotoDariGaleri,
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        size: 16,
                        color: Color(0xFF1F2937),
                      ),
                      label: const Text(
                        'Pilih File / Galeri',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD1D5DB)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
          SnackBar(
            content: Text('Gagal mengambil foto kamera: $e'),
            backgroundColor: Colors.red,
          ),
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
          SnackBar(
            content: Text('Gagal memilih foto: $e'),
            backgroundColor: Colors.red,
          ),
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
            content: Text(
              '$addedCount foto berhasil ditambahkan via drag and drop',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildPhotoThumbnail(int idx, String fotoStr) {
    final bool isBase64 =
        fotoStr.startsWith('data:image') ||
        (!fotoStr.startsWith('Foto ') && fotoStr.length > 50);

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
                      const Icon(
                        Icons.image_outlined,
                        color: Color(0xFF4B5563),
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          fotoStr,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
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
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
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

  Widget _buildImageFromBase64(
    String b64, {
    BoxFit fit = BoxFit.cover,
    double? width,
    double? height,
  }) {
    if (b64.startsWith('http')) {
      return Image.network(
        b64,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 24, color: Colors.grey),
        ),
      );
    }
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
      return const Center(
        child: Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
  }

  void _showPhotoPreviewDialog(int idx, String fotoStr) {
    final bool isBase64 =
        fotoStr.startsWith('data:image') ||
        (!fotoStr.startsWith('Foto ') && fotoStr.length > 50);

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
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
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
                          const Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fotoStr,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateInputField({
    required TextEditingController controller,
    required String label,
  }) {
    return Focus(
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
      ),
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
                    if (_rekapPengirimanDtList.isEmpty)
                      _addRekapPengirimanDtRow();
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
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // REKAPITULASI TERPADU RITASE PENGIRIMAN DT ASPAL
          _buildRekapSectionCard(
            title: 'Rekapitulasi Ritase Pengiriman DT Aspal',
            subtitle: 'Satu kesatuan data kendaraan DT, AMP, Lapangan, dan Tonase tiket',
            badge: '${_rekapPengirimanDtList.length} Ritase',
            body: _buildRekapPengirimanDtContent(),
          ),
          const SizedBox(height: 14),

          // DATA PERJALANAN DT (AMP - LAPANGAN - AMP)
          _buildDataPerjalananDtSection(),
        ],
      ],
    );
  }

  Widget _buildSubSectionBadge(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.primaryBlue),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
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
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          Padding(padding: const EdgeInsets.all(12), child: body),
        ],
      ),
    );
  }

  Widget _buildRekapPengirimanDtContent() {
    return Column(
      children: [
        ..._rekapPengirimanDtList.asMap().entries.map((entry) {
          final idx = entry.key;
          final m = entry.value;

          return _buildItemCard(
            title: 'Ritase / Pengiriman DT #${idx + 1}',
            onDelete: () {
              setState(() {
                final removed = _rekapPengirimanDtList.removeAt(idx);
                _disposePengirimanDtControllers(removed);
                _recalculateTonaseKumulatif();
              });
            },
            children: [
              // 1. IDENTITAS KENDARAAN (HANYA DIISI 1 KALI)
              _buildSubSectionBadge(
                '1. IDENTITAS KENDARAAN (DT)',
                Icons.local_shipping_outlined,
              ),
              const SizedBox(height: 8),
              _buildPlateInputField(
                controller: m['nomorKendaraan']!,
                label: 'Nomor Kendaraan / Plat DT',
              ),
              const SizedBox(height: 14),

              // 2. DATA DI PABRIK (AMP)
              _buildSubSectionBadge(
                '2. DATA DI PABRIK (AMP)',
                Icons.factory_outlined,
              ),
              const SizedBox(height: 8),
              _buildTimePickerField(
                controller: m['jamPergiAmp']!,
                label: 'Jam Berangkat dari AMP',
                hintText: 'Pilih jam (HH:mm:ss)',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['suhuAmp']!,
                label: 'Suhu di AMP (°C)',
                hintText: 'Contoh: 155',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTimePickerField(
                controller: m['jamPulangAmp']!,
                label: 'Jam Tiba Kembali ke AMP',
                hintText: 'Pilih jam (HH:mm:ss)',
              ),
              const SizedBox(height: 14),

              // 3. DATA DI LOKASI PROYEK (LAPANGAN)
              _buildSubSectionBadge(
                '3. DATA DI LOKASI PROYEK (LAPANGAN)',
                Icons.location_on_outlined,
              ),
              const SizedBox(height: 8),
              _buildTimePickerField(
                controller: m['jamDatangLap']!,
                label: 'Jam Datang di Lapangan',
                hintText: 'Pilih jam (HH:mm:ss)',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['suhuDatang']!,
                label: 'Suhu Datang (°C)',
                hintText: 'Contoh: 150',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['waktuAntrian']!,
                label: 'Waktu Antrian (Menit)',
                hintText: 'Contoh: 5 (bisa diubah sesuai antrian)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTimePickerField(
                controller: m['jamMulaiTuang']!,
                label: 'Jam Mulai Tuang ke Finisher',
                hintText: 'Pilih jam (HH:mm:ss)',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['suhuLap']!,
                label: 'Suhu Hampar di Lapangan (°C)',
                hintText: 'Contoh: 145',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTimePickerField(
                controller: m['jamSelesaiTuang']!,
                label: 'Jam Selesai Tuang',
                hintText: 'Pilih jam (HH:mm:ss)',
              ),
              const SizedBox(height: 10),
              _buildField(
                controller: m['suhuPemadatanAkhir']!,
                label: 'Suhu Pemadatan Akhir (°C)',
                hintText: 'Contoh: 95',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              _buildTimePickerField(
                controller: m['jamPulangLap']!,
                label: 'Jam Pulang dari Lapangan',
                hintText: 'Pilih jam (HH:mm:ss)',
              ),
              const SizedBox(height: 14),

              // 4. DATA TONASE TIKET
              _buildSubSectionBadge(
                '4. DATA TONASE TIKET',
                Icons.receipt_long_outlined,
              ),
              const SizedBox(height: 8),
              _buildField(
                controller: m['tonaseTiket']!,
                label: 'Tonase Tiket (Ton)',
                hintText: 'Contoh: 8.5',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
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
          '+ Tambah Ritase / Pengiriman DT',
          () => _addRekapPengirimanDtRow(),
        ),
      ],
    );
  }

  // ─── 4. DOKUMEN DATA PERJALANAN DT (OTOMATIS) ───
  Widget _buildDataPerjalananDtSection() {
    final rows = _computeDataPerjalananRows();
    final double totalTonase = rows.fold(
      0.0,
      (sum, r) => sum + (r['beratAc'] as double),
    );

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
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
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
                      const Text(
                        'Total Rit',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${rows.length} Rit',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
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
                      const Text(
                        'Total Berat AC',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${PlatNomorUtil.formatDecimal(totalTonase, fractionDigits: 2)} Ton',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
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
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${PlatNomorUtil.formatDecimal(r['beratAc'] as double, fractionDigits: 2)} Ton',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'AMP ${r['jamDariAmp']} ➔ Lap. ${r['jamTibaLokasi']} (${PlatNomorUtil.formatDecimal(r['waktuBerangkatJam'] as double, fractionDigits: 2)} Jam • ${PlatNomorUtil.formatDecimal(r['kecepatanBerangkat'] as double, fractionDigits: 1)} km/jam)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Suhu: ${PlatNomorUtil.formatDecimal(r['suhuAmp'] as double, fractionDigits: 0)}°C ➔ ${PlatNomorUtil.formatDecimal(r['suhuLokasi'] as double, fractionDigits: 0)}°C (Turun: ${PlatNomorUtil.formatDecimal(r['selisihSuhu'] as double, fractionDigits: 0)}°C)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF4B5563),
                      ),
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
    final double jarakKm =
        double.tryParse(_jarakTempuhController.text.replaceAll(',', '.')) ??
        35.5;

    final List<Map<String, String>> lapanganList = _rekapPengirimanDtList
        .map(
          (m) => {
            'nomorKendaraan': m['nomorKendaraan']?.text.trim() ?? '',
            'jamDatang': PlatNomorUtil.normalizeTime(
              m['jamDatangLap']?.text.trim() ?? '',
            ),
            'suhuDatang': m['suhuDatang']?.text.trim() ?? '',
            'waktuAntrian': m['waktuAntrian']?.text.trim() ?? '',
            'suhu': m['suhuLap']?.text.trim() ?? '',
            'suhuLap': m['suhuLap']?.text.trim() ?? '',
            'jamMulaiTuang': PlatNomorUtil.normalizeTime(
              m['jamMulaiTuang']?.text.trim() ?? '',
            ),
            'jamSelesaiTuang': PlatNomorUtil.normalizeTime(
              m['jamSelesaiTuang']?.text.trim() ?? '',
            ),
            'suhuPemadatanAkhir': m['suhuPemadatanAkhir']?.text.trim() ?? '',
            'jamPulang': PlatNomorUtil.normalizeTime(
              m['jamPulangLap']?.text.trim() ?? '',
            ),
          },
        )
        .toList();

    final List<Map<String, String>> ampList = _rekapPengirimanDtList
        .map(
          (m) => {
            'nomorKendaraan': m['nomorKendaraan']?.text.trim() ?? '',
            'jamPergi': PlatNomorUtil.normalizeTime(
              m['jamPergiAmp']?.text.trim() ?? '',
            ),
            'suhuAmp': m['suhuAmp']?.text.trim() ?? '',
            'jamPulang': PlatNomorUtil.normalizeTime(
              m['jamPulangAmp']?.text.trim() ?? '',
            ),
          },
        )
        .toList();

    final List<Map<String, String>> tonaseList = _rekapPengirimanDtList
        .map(
          (m) => {
            'nomorKendaraan': m['nomorKendaraan']?.text.trim() ?? '',
            'tonaseTiket': m['tonaseTiket']?.text.trim() ?? '',
            'jumlahKumulatif': m['jumlahKumulatif']?.text.trim() ?? '',
          },
        )
        .toList();

    return PlatNomorUtil.computeDataPerjalananRows(
      lapanganList: lapanganList,
      ampList: ampList,
      tonaseList: tonaseList,
      jarakKm: jarakKm,
    );
  }

  // ─── 11. DOKUMEN REKAPITULASI PENGECORAN BETON READY MIX (OPSIONAL) ───
  Widget _buildSectionRekapitulasiBetonOpsional() {
    final double totalKubikasi = _rekapPengecoranBetonList.fold(
      0.0,
      (sum, r) =>
          sum +
          (double.tryParse(
                (r['volume']?.text.trim() ?? '').replaceAll(',', '.'),
              ) ??
              0.0),
    );
    final String formattedTotal = totalKubikasi % 1 == 0
        ? totalKubikasi.toInt().toString()
        : totalKubikasi.toStringAsFixed(2).replaceAll('.', ',');

    final namaKegiatanOtomatis = _currentKegiatan?['namaKegiatan'] ?? '-';

    return _buildCard(
      title: 'DOKUMEN REKAPITULASI PENGECORAN BETON',
      badge: _enableRekapitulasiBeton ? 'Aktif' : 'Nonaktif',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Aktifkan Dokumen Pengawasan Beton',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Mengaktifkan form rekapitulasi pengiriman ready mix, slump test, dan volume kubikasi',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _enableRekapitulasiBeton,
              onChanged: (val) {
                setState(() {
                  _enableRekapitulasiBeton = val;
                  if (val && _rekapPengecoranBetonList.isEmpty) {
                    _addRekapPengecoranBetonRow();
                  }
                  if (val &&
                      _penyediaJasaBetonController.text.isEmpty &&
                      _currentKegiatan?['kontraktor'] != null) {
                    _penyediaJasaBetonController.text =
                        _currentKegiatan!['kontraktor'].toString();
                  }
                });
              },
              activeThumbColor: const Color(0xFF1F2937),
            ),
          ],
        ),
        if (_enableRekapitulasiBeton) ...[
          const SizedBox(height: 12),
          // Informasi Header Pengecoran Beton
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
                  'Informasi Header Pengecoran Beton',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: TextEditingController(text: namaKegiatanOtomatis),
                  label: 'Kegiatan (Otomatis)',
                  hintText: 'Nama Kegiatan Proyek',
                  readOnly: true,
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: _penyediaJasaBetonController,
                  label: 'Penyedia Jasa (Kontraktor)',
                  hintText: 'Contoh: PT. ADHI KARYA / CV. LANGGENG',
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: _jenisBetonController,
                  label: 'Jenis Beton',
                  hintText: "Contoh: Fc' 20 MPa / K-250 / Rigid Pavement",
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Header List & Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Data Pengiriman Truck Mixer (${_rekapPengecoranBetonList.length} Unit)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF1F2937),
                ),
              ),
              if (totalKubikasi > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slateLighter,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'Total: $formattedTotal m³',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navySlate,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // List of Mixer Trucks
          ..._rekapPengecoranBetonList.asMap().entries.map((entry) {
            final idx = entry.key;
            final m = entry.value;

            return _buildItemCard(
              title: 'Truck Mixer #${idx + 1}',
              onDelete: () {
                setState(() {
                  final removed = _rekapPengecoranBetonList.removeAt(idx);
                  _disposeBetonControllers(removed);
                  _recalculateBetonVolumeKumulatif();
                });
              },
              children: [
                _buildPlateInputField(
                  controller: m['nomorKendaraan']!,
                  label: 'Nomor Kendaraan / Plat Truck Mixer',
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: m['batchingPlant']!,
                  label: 'Batching Plant Ready Mix',
                  hintText: 'Contoh: PT. VARIA USAHA BETON / SCG',
                ),
                const SizedBox(height: 10),
                _buildTimePickerField(
                  controller: m['jamBerangkat']!,
                  label: 'Jam Berangkat dari Batching Plant',
                  hintText: 'Pilih jam (HH:mm:ss)',
                ),
                const SizedBox(height: 10),
                _buildTimePickerField(
                  controller: m['jamDatang']!,
                  label: 'Jam Datang di Lapangan',
                  hintText: 'Pilih jam (HH:mm:ss)',
                ),
                const SizedBox(height: 10),
                _buildField(
                  controller: m['slumpTest']!,
                  label: 'Slump Test',
                  hintText: 'Contoh: 10 ± 2 cm / 12 cm',
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: _buildField(
                        controller: m['volume']!,
                        label: 'Volume Cor (m³ / Kubik)',
                        hintText: 'Contoh: 6.0',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 5,
                      child: _buildField(
                        controller: m['volumeKumulatif']!,
                        label: 'Kumulatif (m³)',
                        hintText: 'Otomatis',
                        readOnly: true,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }),
          const SizedBox(height: 8),

          _buildAddButton(
            '+ Tambah Baris Pengiriman Beton (Truck Mixer)',
            () => _addRekapPengecoranBetonRow(),
          ),
        ],
      ],
    );
  }

  // ─── 12. FIELD TAMBAHAN / KUSTOM ───
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
        _buildAddButton('+ Tambah Field Kustom', () => _addCustomFieldRow()),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
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
    String? suffixText,
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
      suffixIcon: suffixText != null
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                suffixText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.slate,
                ),
              ),
            )
          : null,
    );
  }

  /// Kolom input waktu yang menggunakan picker roda putar (scroll ala jam weker/alarm)
  /// Menjamin seluruh input waktu seragam dalam format 24 jam (HH:mm:ss).
  Widget _buildTimePickerField({
    required TextEditingController controller,
    required String label,
    String hintText = 'Pilih jam (HH:mm:ss)',
  }) {
    return CleanTextFormField(
      controller: controller,
      label: label,
      hintText: hintText,
      readOnly: true,
      onTap: () => _showTimePickerModal(
        context: context,
        controller: controller,
        title: label,
      ),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Hapus Jam',
              onPressed: () {
                setState(() {
                  controller.clear();
                });
              },
            ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(
              Icons.access_time_rounded,
              size: 20,
              color: Color(0xFF1E3A8A),
            ),
            padding: const EdgeInsets.only(right: 8),
            constraints: const BoxConstraints(),
            tooltip: 'Buka Pemilih Waktu',
            onPressed: () => _showTimePickerModal(
              context: context,
              controller: controller,
              title: label,
            ),
          ),
        ],
      ),
    );
  }

  /// Modal Bottom Sheet dengan CupertinoTimerPicker 24 jam (Jam, Menit, Detik ala alarm/stopwatch)
  Future<void> _showTimePickerModal({
    required BuildContext context,
    required TextEditingController controller,
    required String title,
  }) async {
    Duration initialDuration = Duration.zero;
    final text = controller.text.trim();
    final normalized = PlatNomorUtil.normalizeTime(text);
    final match = RegExp(r'^(\d{1,2}):(\d{2}):(\d{2})').firstMatch(normalized);
    if (match != null) {
      final h = int.parse(match.group(1)!);
      final m = int.parse(match.group(2)!);
      final s = int.parse(match.group(3)!);
      initialDuration = Duration(hours: h, minutes: m, seconds: s);
    } else {
      final now = DateTime.now();
      initialDuration = Duration(
        hours: now.hour,
        minutes: now.minute,
        seconds: 0,
      );
    }

    Duration selectedDuration = initialDuration;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: 310,
            child: Column(
              children: [
                // Header Bar dengan tombol Batal, Judul, dan Selesai
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          final h = selectedDuration.inHours.toString().padLeft(
                            2,
                            '0',
                          );
                          final m = (selectedDuration.inMinutes % 60)
                              .toString()
                              .padLeft(2, '0');
                          final s = (selectedDuration.inSeconds % 60)
                              .toString()
                              .padLeft(2, '0');
                          controller.text = '$h:$m:$s';
                          setState(() {});
                          Navigator.pop(sheetContext);
                        },
                        child: const Text(
                          'Selesai',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE5E7EB)),

                // Wheel Scroll Picker (CupertinoTimerPicker 24 jam dengan Detik: HH:mm:ss)
                Expanded(
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      brightness: Brightness.light,
                      textTheme: CupertinoTextThemeData(
                        pickerTextStyle: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    child: CupertinoTimerPicker(
                      mode: CupertinoTimerPickerMode.hms,
                      initialTimerDuration: initialDuration,
                      onTimerDurationChanged: (Duration newDuration) {
                        selectedDuration = newDuration;
                      },
                    ),
                  ),
                ),

                // Tombol Kosongkan jika ingin menghapus nilai jam
                if (controller.text.isNotEmpty) ...[
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  TextButton.icon(
                    onPressed: () {
                      controller.clear();
                      setState(() {});
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(
                      Icons.clear,
                      size: 16,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'Kosongkan Waktu',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        );
      },
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ),
          const Text(
            ': ',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
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
