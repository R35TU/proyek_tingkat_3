import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/buat_laporan_mingguan_screen.dart';
import 'package:tata_saka_app/widgets/lembar_laporan_mingguan_widget.dart';
import 'package:tata_saka_app/widgets/lembar_boq_mingguan_widget.dart';
import 'package:tata_saka_app/utils/plat_nomor_util.dart';
import 'package:pdf/pdf.dart';
import 'package:tata_saka_app/screens/pdf_viewer_screen.dart';
import 'package:tata_saka_app/services/pdf_report_service.dart';
import 'package:tata_saka_app/widgets/horizontal_drag_scroll_area.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

class DetailDataLaporanScreen extends StatefulWidget {
  final ContractModel contract;
  final int kegiatanIndex;
  final int initialTab; // 0 for Harian, 1 for Mingguan

  const DetailDataLaporanScreen({
    super.key,
    required this.contract,
    this.kegiatanIndex = 0,
    this.initialTab = 0,
  });

  @override
  State<DetailDataLaporanScreen> createState() => _DetailDataLaporanScreenState();
}

class _DetailDataLaporanScreenState extends State<DetailDataLaporanScreen> {
  late int _currentKegiatanIndex;
  late int _selectedTab;
  late DateTime _selectedDate;
  late DateTime _currentWeekMonday;

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

  static const List<String> _namaHariSingkat = [
    'Sen',
    'Sel',
    'Rab',
    'Kam',
    'Jum',
    'Sab',
    'Min',
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
    _currentKegiatanIndex = widget.kegiatanIndex;
    _selectedTab = widget.initialTab;

    // Check if contract has existing reports to set initial selected date
    DateTime initialDate = DateTime.now();
    if (widget.contract.kegiatans.isNotEmpty &&
        _currentKegiatanIndex < widget.contract.kegiatans.length) {
      final keg = widget.contract.kegiatans[_currentKegiatanIndex];
      final List<dynamic> reports = (keg['laporans'] as List<dynamic>?) ?? [];
      if (reports.isNotEmpty) {
        DateTime? latestDate;
        for (final r in reports) {
          final dStr = r['tanggal']?.toString() ?? r['createdAt']?.toString();
          if (dStr != null) {
            final p = DateTime.tryParse(dStr);
            if (p != null) {
              if (latestDate == null || p.isAfter(latestDate)) {
                latestDate = p;
              }
            }
          }
        }
        if (latestDate != null) {
          initialDate = latestDate;
        }
      }
    }

    _selectedDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
    _currentWeekMonday = _getMondayOfWeek(_selectedDate);
  }

  void _initSampleReportIfEmpty() {
    return; // Dikosongkan agar tidak memaksa data dummy laporan harian.
  }

  void _unusedLegacySampleReport() {
    final keg = _currentKegiatan;
    if (keg == null) return;

    List<dynamic> reports = keg['laporans'] ?? [];
    final bool needsUpdate = false;
    if (needsUpdate) {
      // Seed sample report matching the physical document of Buku Harian Standar
      final sample = {
        'id': 'sample-oct4',
        'tanggal': '2026-10-04',
        'tanggalFormatted': 'Minggu, 04 Oktober 2026',
        'namaKontrak': widget.contract.namaKontrak,
        'namaKegiatan': keg['namaKegiatan'] ?? widget.contract.namaKontrak,
        'lokasi': keg['lokasi'] ?? 'Kab. Purbalingga',
        'lokasiSta': keg['lokasi'] ?? 'Kab. Purbalingga',
        'sumberDana': widget.contract.sumberDana,
        'kontraktor': keg['kontraktor'] ?? 'CV. LANGGENG',

        // A. PEKERJAAN DENGAN SATU KESATUAN SUMBER DAYA (MATERIAL, ALAT, PERSONIL)
        'pekerjaanList': [
          {
            'no': '1',
            'jenis': 'Pekerjaan Galian Tanah untuk Saluran',
            'volume': '35 m³',
            'lokasi': 'STA 0+150 - 0+300',
            'materials': [],
            'peralatans': [
              {
                'no': '1.1',
                'jenis': 'Excavator Mini PC 50',
                'cacahAktif': '1 Unit',
                'jumlah': '1 Unit',
                'noRusak': '-',
                'jenisRusak': '-',
                'kode': '-',
                'rusak': '-',
              },
            ],
            'personils': [
              {'no': '1.1', 'role': 'Pelaksana', 'cacah': '1', 'lokasi': 'STA 0+150'},
              {'no': '1.2', 'role': 'Pekerja Galian', 'cacah': '4', 'lokasi': 'STA 0+150'},
            ],
          },
          {
            'no': '2',
            'jenis': 'Pemasangan U-Ditch Precast 40x40',
            'volume': '20 Unit',
            'lokasi': 'STA 0+150 - 0+170',
            'materials': [
              {
                'no': '2.1',
                'jenis': 'U-Ditch Precast 40x40 cm',
                'volume': '20 Buah',
                'lokasiAwal': 'Basecamp',
                'lokasiTujuan': 'STA 0+150',
              },
              {
                'no': '2.2',
                'jenis': 'Pasir Urug / Pasang',
                'volume': '4 m³',
                'lokasiAwal': 'Quarry',
                'lokasiTujuan': 'STA 0+150',
              },
            ],
            'peralatans': [
              {
                'no': '2.1',
                'jenis': 'Dump Truck 5 Ton',
                'cacahAktif': '1 Unit',
                'jumlah': '1 Unit',
                'noRusak': '1',
                'jenisRusak': 'Dump Truck',
                'kode': 'DT-02',
                'rusak': 'Hidrolik Bocor',
              },
            ],
            'personils': [
              {'no': '2.1', 'role': 'Kepala Tukang Precast', 'cacah': '1', 'lokasi': 'STA 0+150'},
              {'no': '2.2', 'role': 'Tukang Pasang', 'cacah': '4', 'lokasi': 'STA 0+150'},
              {'no': '2.3', 'role': 'Pekerja Bantu', 'cacah': '4', 'lokasi': 'STA 0+150'},
            ],
          },
        ],

        // B. MATERIAL DIGUNAKAN
        'materialList': [
          {
            'no': '1',
            'jenis': 'U-Ditch Precast 40x40 cm',
            'volume': '20 Buah',
            'lokasiAwal': 'Basecamp',
            'lokasiTujuan': 'STA 0+150',
          },
          {
            'no': '2',
            'jenis': 'Pasir Urug / Pasang',
            'volume': '4 m³',
            'lokasiAwal': 'Quarry',
            'lokasiTujuan': 'STA 0+150',
          },
        ],

        // C. JENIS PERALATAN YANG DIGUNAKAN
        'peralatanList': [
          {
            'no': '1',
            'jenis': 'Excavator Mini PC 50',
            'cacahAktif': '1 Unit',
            'jumlah': '1 Unit',
            'noRusak': '-',
            'jenisRusak': '-',
            'kode': '-',
            'rusak': '-',
          },
          {
            'no': '2',
            'jenis': 'Dump Truck 5 Ton',
            'cacahAktif': '1 Unit',
            'jumlah': '1 Unit',
            'noRusak': '1',
            'jenisRusak': 'Dump Truck',
            'kode': 'DT-02',
            'rusak': 'Hidrolik Bocor',
          },
        ],

        // D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR
        'personilList': [
          {'no': '1', 'role': 'Pengawas DPU', 'cacah': '1', 'lokasi': 'Ruas Jalan'},
          {'no': '2', 'role': 'Konsultan Pengawas', 'cacah': '2', 'lokasi': 'STA 0+150'},
          {'no': '3', 'role': 'Pelaksana', 'cacah': '1', 'lokasi': 'STA 0+150'},
          {'no': '4', 'role': 'Logistik', 'cacah': '1', 'lokasi': 'Basecamp'},
          {'no': '5', 'role': 'Kepala Tukang', 'cacah': '1', 'lokasi': 'STA 0+150'},
          {'no': '6', 'role': 'Tukang', 'cacah': '4', 'lokasi': 'STA 0+150'},
          {'no': '7', 'role': 'Pekerja', 'cacah': '8', 'lokasi': 'STA 0+150'},
        ],

        // E. CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN
        'cuacaKejadianList': [
          {'no': '1', 'jenisKejadian': 'Hujan Lebat', 'cuaca': 'Hujan Lebat', 'jenis': 'Hujan Lebat', 'jam': '-', 'lokasi': '-', 'tanggungJawab': 'Tidak', 'akibat': '-'},
          {'no': '2', 'jenisKejadian': 'Pekerjaan Tertunda', 'cuaca': 'Gerimis', 'jenis': 'Gerimis', 'jam': '14:00 - 15:00', 'lokasi': 'STA 0+150', 'tanggungJawab': 'Tidak', 'akibat': 'Pekerjaan dihentikan sementara'},
          {'no': '3', 'jenisKejadian': 'Genangan Air', 'cuaca': 'Hujan', 'jenis': 'Banjir / genangan air', 'jam': '-', 'lokasi': '-', 'tanggungJawab': 'Tidak', 'akibat': '-'},
          {'no': '4', 'jenisKejadian': 'Longsor', 'cuaca': 'Hujan Lebat', 'jenis': 'Longsor', 'jam': '-', 'lokasi': '-', 'tanggungJawab': 'Tidak', 'akibat': '-'},
        ],

        // F. INSTRUKSI DAN SARAN-SARAN
        'instruksiList': [
          {
            'no': '1',
            'pihak': 'Kontraktor Pelaksana (CV. Langgeng)',
            'uraian': 'Lanjutkan pekerjaan galian tanah dan rapikan buangan material di bahu jalan sebelum malam.',
          },
          {
            'no': '2',
            'pihak': 'Petugas Teknis Dinas PU',
            'uraian': 'Pemasangan precast harus memperhatikan kemiringan elevasi saluran agar air mengalir lancar.',
          },
          {
            'no': '3',
            'pihak': 'Konsultan Supervisi (CV. Tata Saka Consultant)',
            'uraian': 'Pekerjaan pemasangan U-Ditch disetujui, pastikan pemadatan dasar pasir urug.',
          },
        ],

        // Custom Fields
        'customFields': [
          {
            'nama': 'Catatan Khusus K3',
            'isi': 'Seluruh pekerja wajib memakai helm dan rompi keselamatan saat alat berat excavator beroperasi.',
          },
        ],

        // Dokumen Rekapitulasi Aspal (Sample Multi-Halaman)
        'hasRekapSuhuLapangan': true,
        'rekapSuhuLapanganList': [
          {
            'no': '1',
            'nomorKendaraan': 'R 1234 AB',
            'jamDatang': '08:30',
            'suhuDatang': '150°C',
            'suhu': '145°C',
            'jamMulaiTuang': '08:45',
            'jamSelesaiTuang': '09:15',
            'suhuPemadatanAkhir': '95°C',
            'jamPulang': '09:20',
          },
          {
            'no': '2',
            'nomorKendaraan': 'R 5678 CD',
            'jamDatang': '09:10',
            'suhuDatang': '148°C',
            'suhu': '142°C',
            'jamMulaiTuang': '09:20',
            'jamSelesaiTuang': '09:50',
            'suhuPemadatanAkhir': '92°C',
            'jamPulang': '09:55',
          },
        ],
        'hasRekapSuhuAmp': true,
        'rekapSuhuAmpList': [
          {
            'no': '1',
            'nomorKendaraan': 'R 1234 AB',
            'jamPergi': '07:30',
            'suhuAmp': '160°C',
            'jamPulang': '10:00',
          },
          {
            'no': '2',
            'nomorKendaraan': 'R 5678 CD',
            'jamPergi': '08:15',
            'suhuAmp': '158°C',
            'jamPulang': '10:45',
          },
        ],
        'hasRekapTonaseAspal': true,
        'rekapTonaseAspalList': [
          {
            'no': '1',
            'nomorKendaraan': 'R 1234 AB',
            'tonaseTiket': '10',
            'jumlahKumulatif': '10',
          },
          {
            'no': '2',
            'nomorKendaraan': 'R 1234 AC',
            'tonaseTiket': '10',
            'jumlahKumulatif': '20',
          },
        ],

        'cuaca': 'Gerimis',
        'temuan': 'Pekerjaan Galian Tanah untuk Saluran (35 m³), Pemasangan U-Ditch Precast 40x40 (20 Unit)',
        'instruksi': 'Lanjutkan pekerjaan galian tanah dan rapikan buangan material di bahu jalan.',
        'rekomendasi': 'CV. Tata Saka Consultant: Pemasangan U-Ditch disetujui, pastikan pemadatan dasar pasir.',
        'auditor': 'CV. Tata Saka Consultant',
        'status': 'Terverifikasi',
        'fotoCount': 2,
        'fotoList': ['Foto Galian STA 0+150', 'Foto Pemasangan U-Ditch'],
        'createdAt': DateTime(2026, 10, 4, 15, 30).toIso8601String(),
      };
      reports = [sample];
      keg['laporans'] = reports;
      widget.contract.kegiatans[_currentKegiatanIndex] = keg;

      widgetsBindingInstance();
    }
  }

  void widgetsBindingInstance() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<ContractProvider>(context, listen: false).updateContract(widget.contract);
      }
    });
  }

  void _initSampleWeeklyReportIfEmpty() {
    // Dibiarkan kosong agar tidak memaksa data dummy laporan mingguan.
    // Pengguna dapat membuat laporan mingguan baru secara mandiri.
  }

  DateTime _getMondayOfWeek(DateTime d) {
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDateKey(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  bool _matchReportDate(dynamic r, DateTime targetDate) {
    if (r == null) return false;
    final targetKey = _formatDateKey(targetDate);
    final String? rawDate = r['tanggal']?.toString();
    if (rawDate != null) {
      if (rawDate == targetKey || rawDate.startsWith(targetKey)) {
        return true;
      }
      final parsed = DateTime.tryParse(rawDate);
      if (parsed != null && _isSameDay(parsed, targetDate)) {
        return true;
      }
    }
    final String? createdAt = r['createdAt']?.toString();
    if (createdAt != null) {
      final parsed = DateTime.tryParse(createdAt);
      if (parsed != null && _isSameDay(parsed, targetDate)) {
        return true;
      }
    }
    return false;
  }

  List<Map<String, dynamic>> _getReportsForDate(DateTime d) {
    final keg = _currentKegiatan;
    if (keg == null) return [];
    final rawReports = keg['laporans'] as List<dynamic>? ?? [];
    return rawReports
        .where((r) => _matchReportDate(r, d))
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }

  bool _hasReportOnDate(DateTime d) {
    return _getReportsForDate(d).isNotEmpty;
  }

  void _goToPreviousWeek() {
    setState(() {
      _currentWeekMonday = _currentWeekMonday.subtract(const Duration(days: 7));
      _selectedDate = _selectedDate.subtract(const Duration(days: 7));
    });
  }

  void _goToNextWeek() {
    setState(() {
      _currentWeekMonday = _currentWeekMonday.add(const Duration(days: 7));
      _selectedDate = _selectedDate.add(const Duration(days: 7));
    });
  }

  ContractModel get _liveContract {
    try {
      final contractProvider = Provider.of<ContractProvider>(context, listen: false);
      return contractProvider.contracts.firstWhere(
        (c) => c.id == widget.contract.id,
        orElse: () => widget.contract,
      );
    } catch (_) {
      return widget.contract;
    }
  }

  Map<String, dynamic>? get _currentKegiatan {
    final live = _liveContract;
    if (live.kegiatans.isNotEmpty &&
        _currentKegiatanIndex < live.kegiatans.length) {
      return live.kegiatans[_currentKegiatanIndex];
    }
    return null;
  }

  Future<void> _editReport(Map<String, dynamic> report) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuatLaporanScreen(
          initialContract: _liveContract,
          initialKegiatanIndex: _currentKegiatanIndex,
          initialDate: _selectedDate,
          editReport: report,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  void _confirmDeleteReport(String reportId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Laporan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus dokumen laporan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final live = _liveContract;
              final keg = _currentKegiatan;
              if (keg != null) {
                final List<dynamic> reports = List.from(keg['laporans'] ?? []);
                reports.removeWhere((r) => r['id'] == reportId);
                keg['laporans'] = reports;
                live.kegiatans[_currentKegiatanIndex] = keg;
                Provider.of<ContractProvider>(context, listen: false).updateContract(live);
                try {
                  final timeline = Provider.of<TimelineProvider>(context, listen: false);
                  final kName = keg['namaKegiatan']?.toString() ?? '';
                  final kontraktor = keg['kontraktor']?.toString() ?? '';
                  final dinas = live.instansiDinas.isNotEmpty ? live.instansiDinas.first : 'DPU-PR Kab. Purbalingga';
                  timeline.logEvent(
                    actorName: 'CV. Tata Saka Consultant',
                    actionType: 'DELETE',
                    entityType: 'LAPORAN_HARIAN',
                    contractId: live.id,
                    contractName: live.namaKontrak,
                    kegiatanName: kName,
                    kontraktorName: kontraktor,
                    dinasName: dinas,
                    title: 'Penghapusan Laporan Harian: $kName',
                    description: 'Dokumen Buku Harian Standar telah dihapus dari sistem.',
                  );
                } catch (_) {}
              }
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Laporan berhasil dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // MODAL DETAIL LAPORAN: SEMIRIP MUNGKIN DENGAN LEMBAR DOKUMEN FISIK GAMBAR 2
  void _showDetailLaporanModal(Map<String, dynamic> report) {
    final pekerjaanList = (report['pekerjaanList'] as List<dynamic>?) ?? [];
    final materialList = (report['materialList'] as List<dynamic>?) ?? [];
    final peralatanList = (report['peralatanList'] as List<dynamic>?) ?? [];
    final personilList = (report['personilList'] as List<dynamic>?) ?? [];
    final cuacaKejadianList = (report['cuacaKejadianList'] as List<dynamic>?) ?? [];
    final customFields = (report['customFields'] as List<dynamic>?) ?? [];
    final fotoList = (report['fotoList'] as List<dynamic>?) ?? [];

    final String namaKegiatan = _currentKegiatan?['namaKegiatan'] ?? widget.contract.namaKontrak;
    final String lokasi = report['lokasi'] ?? _currentKegiatan?['lokasi'] ?? 'Kab. Purbalingga';
    final String dana = report['sumberDana'] ?? widget.contract.sumberDana;
    final String kontraktor = report['kontraktor'] ?? _currentKegiatan?['kontraktor'] ?? 'CV. LANGGENG';

    // Build Normalized Pekerjaan List with their own Materials, Peralatans, and Personils
    final List<Map<String, dynamic>> normalizedPekerjaanList = [];

    if (pekerjaanList.isNotEmpty) {
      for (int i = 0; i < pekerjaanList.length; i++) {
        final rawItem = pekerjaanList[i];
        if (rawItem is Map) {
          final pMap = Map<String, dynamic>.from(rawItem);
          final pIdx = i + 1;

          // Extract nested materials or fallback to flat list matching pIdx
          List<dynamic> mats = [];
          if (pMap['materials'] is List) {
            mats = List<dynamic>.from(pMap['materials'] as List);
          } else {
            mats = materialList.where((m) => m is Map && (m['pekerjaanIdx'] == pIdx || (i == 0 && m['pekerjaanIdx'] == null))).toList();
          }

          // Extract nested peralatans or fallback to flat list matching pIdx
          List<dynamic> alats = [];
          if (pMap['peralatans'] is List) {
            alats = List<dynamic>.from(pMap['peralatans'] as List);
          } else {
            alats = peralatanList.where((a) => a is Map && (a['pekerjaanIdx'] == pIdx || (i == 0 && a['pekerjaanIdx'] == null))).toList();
          }

          // Extract nested personils or fallback to flat list matching pIdx
          List<dynamic> pers = [];
          if (pMap['personils'] is List) {
            pers = List<dynamic>.from(pMap['personils'] as List);
          } else {
            pers = personilList.where((pr) => pr is Map && (pr['pekerjaanIdx'] == pIdx || (i == 0 && pr['pekerjaanIdx'] == null))).toList();
          }

          pMap['materials'] = mats;
          pMap['peralatans'] = alats;
          pMap['personils'] = pers;
          normalizedPekerjaanList.add(pMap);
        }
      }
    }

    if (normalizedPekerjaanList.isEmpty) {
      normalizedPekerjaanList.add({
        'jenis': report['temuan']?.toString().isNotEmpty == true ? report['temuan'].toString() : 'Pekerjaan Lapangan',
        'volume': '-',
        'lokasi': lokasi,
        'materials': materialList,
        'peralatans': peralatanList,
        'personils': personilList,
      });
    }

    // Rekapitulasi Dokumen (Halaman Terpisah)
    final hasRekapSuhuLapangan = report['hasRekapSuhuLapangan'] == true &&
        (report['rekapSuhuLapanganList'] as List?)?.isNotEmpty == true;
    final rekapSuhuLapanganList = (report['rekapSuhuLapanganList'] as List<dynamic>?) ?? [];

    final hasRekapSuhuAmp = report['hasRekapSuhuAmp'] == true &&
        (report['rekapSuhuAmpList'] as List?)?.isNotEmpty == true;
    final rekapSuhuAmpList = (report['rekapSuhuAmpList'] as List<dynamic>?) ?? [];

    final hasRekapTonaseAspal = report['hasRekapTonaseAspal'] == true &&
        (report['rekapTonaseAspalList'] as List?)?.isNotEmpty == true;
    final rekapTonaseAspalList = (report['rekapTonaseAspalList'] as List<dynamic>?) ?? [];

    final hasRekapBeton = (report['hasRekapBeton'] == true || report['hasRekapitulasiBeton'] == true) &&
        (report['rekapPengecoranBetonList'] as List?)?.isNotEmpty == true;
    final rekapPengecoranBetonList = (report['rekapPengecoranBetonList'] as List<dynamic>?) ?? [];

    final bool hasDataPerjalananDt = (report['hasRekapPerjalananDt'] == true ||
            report['hasRekapitulasiAspal'] == true) ||
        (hasRekapSuhuLapangan && hasRekapSuhuAmp);

    int totalPages = 2;
    if (hasRekapSuhuLapangan) totalPages++;
    if (hasRekapSuhuAmp) totalPages++;
    if (hasRekapTonaseAspal) totalPages++;
    if (hasDataPerjalananDt) totalPages++;
    if (hasRekapBeton) totalPages++;

    int pageCounter = 2;
    final int suhuLapPage = hasRekapSuhuLapangan ? ++pageCounter : 0;
    final int suhuAmpPage = hasRekapSuhuAmp ? ++pageCounter : 0;
    final int tonasePage = hasRekapTonaseAspal ? ++pageCounter : 0;
    final int perjalananDtPage = hasDataPerjalananDt ? ++pageCounter : 0;
    final int betonPage = hasRekapBeton ? ++pageCounter : 0;

    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context, listen: false);
    } catch (_) {
      userProf = null;
    }
    final isKonsultan = userProf?.isKonsultan ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF1F5F9), // Light neutral backdrop
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.98,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Top Toolbar Actions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lembar Buku Harian Standar',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        Text(
                          totalPages > 2
                              ? '$totalPages Lembar Dokumen (Lembar Rekapan PU, Rincian, & Lampiran)'
                              : '2 Lembar Dokumen Utama',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                  if (isKonsultan) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editReport(report);
                      },
                      icon: const Icon(Icons.edit, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                            title: 'Buku Harian Standar - ${report['tanggalFormatted'] ?? report['tanggal'] ?? ''}',
                            fileName: 'Buku_Harian_${(report['tanggalFormatted'] ?? report['tanggal'] ?? 'Laporan').toString().replaceAll(' ', '_')}.pdf',
                            pageFormat: PdfPageFormat.a4,
                            buildPdf: () => PdfReportService.generateLaporanHarianPdf(
                              report: report,
                              namaKegiatan: namaKegiatan,
                              lokasi: lokasi,
                              dana: dana,
                              kontraktor: kontraktor,
                              konsultan: 'CV. TATA SAKA CONSULTANT',
                              normalizedPekerjaanList: normalizedPekerjaanList,
                              cuacaKejadianList: cuacaKejadianList.map((e) => Map<String, dynamic>.from(e is Map ? e : {})).toList(),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                    label: const Text('PDF', style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // LEMBAR FISIK DOKUMEN (Scrollable Sheet)
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // LEMBAR 1: BUKU HARIAN STANDAR
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black45, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                        // KOP DOKUMEN
                        const Center(
                          child: Column(
                            children: [
                              Text(
                                'BUKU HARIAN STANDAR',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black, decoration: TextDecoration.underline, letterSpacing: 0.5),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Catatan Harian',
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // INFORMASI IDENTITAS PROYEK
                        _buildDocMetaRow('Hari / Tanggal', ':  ${report['tanggalFormatted'] ?? report['tanggal']}'),
                        _buildDocMetaRow('Nama Kegiatan', ':  $namaKegiatan'),
                        _buildDocMetaRow('Lokasi', ':  $lokasi'),
                        _buildDocMetaRow('Dana', ':  $dana'),
                        const SizedBox(height: 14),

                        // ═══════════════════════════════════════════════════════
                        // 1. REKAPAN FORMAT LAMA (RINGKASAN BUKU HARIAN STANDAR)
                        // Persis seperti dokumen fisik acuan: A, B, C, D, E
                        // ═══════════════════════════════════════════════════════
                        _buildRekapanFormatLamaSection(
                          normalizedPekerjaanList: normalizedPekerjaanList,
                          cuacaKejadianList: cuacaKejadianList,
                          defaultLokasi: lokasi,
                        ),
                        const SizedBox(height: 14),

                        // F. INSTRUKSI DAN SARAN-SARAN (LEMBAR 1 DENGAN TTD RESMI KONSULTAN)
                        _buildDocSectionLabel('F.   INSTRUKSI DAN SARAN-SARAN'),
                        const SizedBox(height: 4),
                        _buildDocTableSectionF(report, kontraktor),

                        // Footer Lembar 1
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Colors.black26),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('BUKU HARIAN STANDAR • CATATAN HARIAN', style: TextStyle(fontSize: 9, color: Colors.black54)),
                            Text('Halaman 1 dari $totalPages', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                            ],
                          ),
                        ),

                        // PEMISAH HALAMAN LEMBAR 1 KE LEMBAR 2
                        _buildPageSeparator('RINCIAN OPERASIONAL ITEM PEKERJAAN', 2, totalPages),

                        // ═══════════════════════════════════════════════════════
                        // LEMBAR 2: RINCIAN OPERASIONAL PER ITEM PEKERJAAN (FORMAT BARU)
                        // ═══════════════════════════════════════════════════════
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.black45, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // KOP DOKUMEN LEMBAR 2
                              const Center(
                                child: Column(
                                  children: [
                                    Text(
                                      'BUKU HARIAN STANDAR',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black, decoration: TextDecoration.underline, letterSpacing: 0.5),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      'Rincian Operasional Item Pekerjaan',
                                      style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // INFORMASI IDENTITAS PROYEK
                              _buildDocMetaRow('Hari / Tanggal', ':  ${report['tanggalFormatted'] ?? report['tanggal']}'),
                              _buildDocMetaRow('Nama Kegiatan', ':  $namaKegiatan'),
                              _buildDocMetaRow('Lokasi', ':  $lokasi'),
                              _buildDocMetaRow('Dana', ':  $dana'),
                              const SizedBox(height: 14),

                              // SUB-BANNER RINCIAN OPERASIONAL
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.black26, width: 0.8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.view_agenda_outlined, size: 14, color: Colors.black87),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'RINCIAN OPERASIONAL PER ITEM PEKERJAAN',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),

                              // 2. FORMAT STANDAR OPERASIONAL: SEKAT PER PEKERJAAN
                              // (MASING-MASING MEMILIKI A, B, C, D)
                              ...normalizedPekerjaanList.asMap().entries.map((entry) {
                          final index = entry.key;
                          final p = entry.value;
                          final pIdx = index + 1;
                          final pJenis = p['jenis']?.toString() ?? 'Pekerjaan #$pIdx';
                          final pVolume = p['volume']?.toString() ?? '-';
                          final pLokasi = p['lokasi']?.toString() ?? lokasi;

                          final mats = (p['materials'] as List<dynamic>?) ?? [];
                          final alats = (p['peralatans'] as List<dynamic>?) ?? [];
                          final pers = (p['personils'] as List<dynamic>?) ?? [];

                          final List<List<String>> jobRows = [
                            [
                              '1',
                              pJenis.isNotEmpty ? pJenis : '-',
                              pVolume.isNotEmpty ? pVolume : '-',
                              pLokasi.isNotEmpty ? pLokasi : lokasi,
                            ],
                          ];

                          final List<List<String>> matRows = mats.isNotEmpty
                              ? mats.asMap().entries.map((mEntry) {
                                  final m = mEntry.value is Map ? (mEntry.value as Map) : <String, dynamic>{};
                                  return [
                                    '${mEntry.key + 1}',
                                    m['jenis']?.toString() ?? '-',
                                    m['volume']?.toString() ?? '-',
                                    m['lokasiAwal']?.toString() ?? '-',
                                    m['lokasiTujuan']?.toString() ?? '-',
                                  ];
                                }).toList()
                              : [
                                  ['1', 'Tidak ada penggunaan material pada pekerjaan ini', '-', '-', '-']
                                ];

                          final List<List<String>> alatRows = alats.isNotEmpty
                              ? alats.asMap().entries.map((aEntry) {
                                  final a = aEntry.value is Map ? (aEntry.value as Map) : <String, dynamic>{};
                                  return [
                                    '${aEntry.key + 1}',
                                    a['jenis']?.toString() ?? '-',
                                    a['cacahAktif']?.toString() ?? a['jumlah']?.toString() ?? '-',
                                    a['jumlah']?.toString() ?? '-',
                                    a['noRusak']?.toString().isNotEmpty == true
                                        ? a['noRusak'].toString()
                                        : (a['jenisRusak']?.toString().isNotEmpty == true ? '${aEntry.key + 1}' : '-'),
                                    a['jenisRusak']?.toString().isNotEmpty == true ? a['jenisRusak'].toString() : '-',
                                    a['kode']?.toString().isNotEmpty == true ? a['kode'].toString() : '-',
                                    a['rusak']?.toString().isNotEmpty == true ? a['rusak'].toString() : '-',
                                  ];
                                }).toList()
                              : [
                                  ['1', 'Pekerjaan manual / tanpa peralatan mekanis', '-', '-', '-', '-', '-', '-']
                                ];

                          final List<List<String>> persRows = pers.isNotEmpty
                              ? pers.asMap().entries.map((prEntry) {
                                  final pr = prEntry.value is Map ? (prEntry.value as Map) : <String, dynamic>{};
                                  return [
                                    '${prEntry.key + 1}',
                                    pr['role']?.toString() ?? '-',
                                    '${pr['cacah'] ?? pr['count'] ?? '-'}',
                                    pr['lokasi']?.toString() ?? pLokasi,
                                  ];
                                }).toList()
                              : [
                                  ['1', 'Personil proyek umum / terpadu', '-', pLokasi]
                                ];

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildPekerjaanPartitionHeader(
                                  index: pIdx,
                                  title: pJenis,
                                  volume: pVolume,
                                  lokasi: pLokasi,
                                ),
                                const SizedBox(height: 6),

                                // A. PEKERJAAN
                                _buildDocSectionLabel('A.   PEKERJAAN'),
                                const SizedBox(height: 4),
                                _buildDocTable(
                                  colWidths: const {
                                    0: FixedColumnWidth(30),
                                    1: FlexColumnWidth(4),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(2.5),
                                  },
                                  headers: ['No', 'JENIS PEKERJAAN', 'VOLUME', 'LOKASI'],
                                  rows: jobRows,
                                ),
                                const SizedBox(height: 10),

                                // B. MATERIAL DIGUNAKAN
                                _buildDocSectionLabel('B.   MATERIAL DIGUNAKAN'),
                                const SizedBox(height: 4),
                                _buildDocTable(
                                  colWidths: const {
                                    0: FixedColumnWidth(30),
                                    1: FlexColumnWidth(3),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(2),
                                    4: FlexColumnWidth(2),
                                  },
                                  headers: ['No', 'Jenis', 'Cacah Volume', 'Lokasi Awal', 'Lokasi Tujuan'],
                                  rows: matRows,
                                ),
                                const SizedBox(height: 10),

                                // C. JENIS PERALATAN YANG DIGUNAKAN
                                _buildDocSectionLabel('C.   JENIS PERALATAN YANG DIGUNAKAN'),
                                const SizedBox(height: 4),
                                _buildDocTable(
                                  colWidths: const {
                                    0: FixedColumnWidth(26),
                                    1: FlexColumnWidth(2.8),
                                    2: FlexColumnWidth(1.6),
                                    3: FlexColumnWidth(1.4),
                                    4: FixedColumnWidth(26),
                                    5: FlexColumnWidth(2.0),
                                    6: FlexColumnWidth(1.4),
                                    7: FlexColumnWidth(1.6),
                                  },
                                  headers: ['No', 'Jenis Peralatan', 'Cacah aktif', 'Jumlah', 'No', 'Jenis', 'Kode', 'Rusak'],
                                  rows: alatRows,
                                ),
                                const SizedBox(height: 10),

                                // D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR
                                _buildDocSectionLabel('D.   PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR'),
                                const SizedBox(height: 4),
                                _buildDocTable(
                                  colWidths: const {
                                    0: FixedColumnWidth(30),
                                    1: FlexColumnWidth(4),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(2.5),
                                  },
                                  headers: ['No', 'Personil proyek', 'Cacah', 'Lokasi'],
                                  rows: persRows,
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        const SizedBox(height: 4),
                        const Divider(height: 18, thickness: 1.5, color: Colors.black45),
                        const SizedBox(height: 8),

                        // E. CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN
                        _buildDocSectionLabel('E.   CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN'),
                        const SizedBox(height: 4),
                        _buildDocTable(
                          colWidths: const {
                            0: FixedColumnWidth(28),
                            1: FlexColumnWidth(1.8),
                            2: FlexColumnWidth(2.2),
                            3: FlexColumnWidth(1.6),
                            4: FlexColumnWidth(1.6),
                            5: FlexColumnWidth(2.0),
                            6: FlexColumnWidth(2.2),
                          },
                          headers: ['No', 'Cuaca', 'Jenis Kejadian', 'Jam', 'Lokasi', 'Tanggung Jwb Kontraktor\n(Ya / Tidak)', 'Akibat'],
                          rows: cuacaKejadianList.isNotEmpty
                              ? cuacaKejadianList.asMap().entries.map((e) {
                                  final item = e.value is Map ? (e.value as Map) : <String, dynamic>{};
                                  final cuacaVal = item['cuaca']?.toString() ?? '-';
                                  final jk = item['jenisKejadian']?.toString() ?? item['jenis']?.toString() ?? '-';
                                  return [
                                    '${e.key + 1}',
                                    cuacaVal.isNotEmpty ? cuacaVal : '-',
                                    jk.isNotEmpty ? jk : '-',
                                    item['jam']?.toString() ?? '-',
                                    item['lokasi']?.toString() ?? '-',
                                    item['tanggungJawab']?.toString() ?? 'Tidak',
                                    item['akibat']?.toString() ?? '-',
                                  ];
                                }).toList()
                              : [
                                  ['1', '-', '-', '-', '-', '-', '-'],
                                ],
                        ),
                        const SizedBox(height: 12),

                        // F. INSTRUKSI DAN SARAN-SARAN (DENGAN TTD RESMI KONSULTAN SUPERVISI)
                        _buildDocSectionLabel('F.   INSTRUKSI DAN SARAN-SARAN'),
                        const SizedBox(height: 4),
                        _buildDocTableSectionF(report, kontraktor),
                        const SizedBox(height: 14),

                        // FIELD TAMBAHAN / CUSTOM (Jika Ada)
                        if (customFields.isNotEmpty) ...[
                          _buildDocSectionLabel('G.   FIELD TAMBAHAN / CATATAN KHUSUS'),
                          const SizedBox(height: 4),
                          _buildDocTable(
                            colWidths: const {
                              0: FixedColumnWidth(30),
                              1: FlexColumnWidth(3),
                              2: FlexColumnWidth(7),
                            },
                            headers: ['No', 'Nama Field', 'Keterangan / Uraian'],
                            rows: customFields.asMap().entries.map((e) => [
                              '${e.key + 1}',
                              e.value['nama']?.toString() ?? '',
                              e.value['isi']?.toString() ?? '',
                            ]).toList(),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // DOKUMENTASI FOTO LAPANGAN
                        if (fotoList.isNotEmpty) ...[
                          _buildDocSectionLabel(customFields.isNotEmpty ? 'H.   DOKUMENTASI FOTO LAPANGAN' : 'G.   DOKUMENTASI FOTO LAPANGAN'),
                          const SizedBox(height: 6),
                          _buildDocSectionFoto(fotoList),
                          const SizedBox(height: 14),
                        ],

                        // Footer Halaman 2
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Colors.black26),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('BUKU HARIAN STANDAR • RINCIAN OPERASIONAL', style: TextStyle(fontSize: 9, color: Colors.black54)),
                            Text('Halaman 2 dari $totalPages', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                            ],
                          ),
                        ),

                        // HALAMAN 3+: LAMPIRAN REKAPITULASI PADA LEMBAR TERPISAH
                        if (hasRekapSuhuLapangan) ...[
                          _buildPageSeparator('REKAP WAKTU & SUHU LAPANGAN', suhuLapPage, totalPages),
                          _buildSheetRekapSuhuLapangan(
                            namaKegiatan: namaKegiatan,
                            kontraktor: kontraktor,
                            rows: rekapSuhuLapanganList,
                            page: suhuLapPage,
                            totalPages: totalPages,
                          ),
                        ],

                        if (hasRekapSuhuAmp) ...[
                          _buildPageSeparator('REKAP WAKTU & SUHU AMP', suhuAmpPage, totalPages),
                          _buildSheetRekapSuhuAmp(
                            namaKegiatan: namaKegiatan,
                            kontraktor: kontraktor,
                            rows: rekapSuhuAmpList,
                            page: suhuAmpPage,
                            totalPages: totalPages,
                          ),
                        ],

                        if (hasRekapTonaseAspal) ...[
                          _buildPageSeparator('REKAP TONASE ASPAL', tonasePage, totalPages),
                          _buildSheetRekapTonaseAspal(
                            namaKegiatan: namaKegiatan,
                            kontraktor: kontraktor,
                            rows: rekapTonaseAspalList,
                            page: tonasePage,
                            totalPages: totalPages,
                          ),
                        ],

                        if (hasDataPerjalananDt) ...[
                          _buildPageSeparator('DATA PERJALANAN DT (AMP - LAPANGAN - AMP)', perjalananDtPage, totalPages),
                          _buildSheetDataPerjalananDt(
                            namaKegiatan: namaKegiatan,
                            lokasi: lokasi,
                            kontraktor: kontraktor,
                            report: report,
                            page: perjalananDtPage,
                            totalPages: totalPages,
                          ),
                        ],

                        if (hasRekapBeton) ...[
                          _buildPageSeparator('REKAP PENGECORAN BETON READY MIX', betonPage, totalPages),
                          _buildSheetRekapBeton(
                            namaKegiatan: namaKegiatan,
                            penyediaJasa: report['penyediaJasaBeton']?.toString().isNotEmpty == true
                                ? report['penyediaJasaBeton'].toString()
                                : kontraktor,
                            jenisBeton: report['jenisBeton']?.toString().isNotEmpty == true
                                ? report['jenisBeton'].toString()
                                : '-',
                            rows: rekapPengecoranBetonList,
                            page: betonPage,
                            totalPages: totalPages,
                          ),
                        ],
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPekerjaanPartitionHeader({
    required int index,
    required String title,
    String? volume,
    String? lokasi,
  }) {
    return Container(
      margin: EdgeInsets.only(top: index == 1 ? 4 : 14, bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark slate navy
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'PEKERJAAN #$index',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
                color: Color(0xFF1E293B),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.isNotEmpty ? title.toUpperCase() : 'PEKERJAAN KE-$index',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (volume != null && volume.trim().isNotEmpty && volume != '-') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                'Vol: $volume',
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (lokasi != null && lokasi.trim().isNotEmpty && lokasi != '-') ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, size: 10, color: Colors.white70),
                  const SizedBox(width: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Text(
                      lokasi,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildRekapanFormatLamaSection({
    required List<dynamic> normalizedPekerjaanList,
    required List<dynamic> cuacaKejadianList,
    required String defaultLokasi,
  }) {
    // 1. A. PEKERJAAN (Kompilasi semua pekerjaan)
    final List<List<String>> allJobRows = normalizedPekerjaanList.asMap().entries.map((entry) {
      final p = entry.value is Map ? (entry.value as Map) : <String, dynamic>{};
      final pJenis = p['jenis']?.toString() ?? '-';
      final pVol = p['volume']?.toString() ?? '-';
      final pLok = p['lokasi']?.toString() ?? defaultLokasi;
      return [
        '${entry.key + 1}',
        pJenis.isNotEmpty ? pJenis : '-',
        pVol.isNotEmpty ? pVol : '-',
        pLok.isNotEmpty ? pLok : defaultLokasi,
      ];
    }).toList();
    if (allJobRows.isEmpty) {
      allJobRows.add(['1', 'Tidak ada data pekerjaan', '-', defaultLokasi]);
    }

    // 2. B. MATERIAL (Kompilasi seluruh material dari semua pekerjaan)
    final List<List<String>> allMatRows = [];
    int mCount = 1;
    for (final p in normalizedPekerjaanList) {
      final mats = (p is Map ? p['materials'] : null) as List<dynamic>? ?? [];
      for (final m in mats) {
        if (m is Map) {
          allMatRows.add([
            '$mCount',
            m['jenis']?.toString() ?? '-',
            m['volume']?.toString() ?? '-',
            m['lokasiAwal']?.toString() ?? '-',
            m['lokasiTujuan']?.toString() ?? '-',
          ]);
          mCount++;
        }
      }
    }
    if (allMatRows.isEmpty) {
      allMatRows.add(['1', 'Nihil / Tanpa material', '-', '-', '-']);
    }

    // 3. C. JENIS PERALATAN YANG DIGUNAKAN
    final List<List<String>> allAlatRows = [];
    int aCount = 1;
    for (final p in normalizedPekerjaanList) {
      final alats = (p is Map ? p['peralatans'] : null) as List<dynamic>? ?? [];
      for (final a in alats) {
        if (a is Map) {
          allAlatRows.add([
            '$aCount',
            a['jenis']?.toString() ?? '-',
            a['cacahAktif']?.toString() ?? a['jumlah']?.toString() ?? '-',
            a['jumlah']?.toString() ?? '-',
            a['noRusak']?.toString().isNotEmpty == true
                ? a['noRusak'].toString()
                : (a['jenisRusak']?.toString().isNotEmpty == true ? '$aCount' : '-'),
            a['jenisRusak']?.toString().isNotEmpty == true ? a['jenisRusak'].toString() : '-',
            a['kode']?.toString().isNotEmpty == true ? a['kode'].toString() : '-',
            a['rusak']?.toString().isNotEmpty == true ? a['rusak'].toString() : '-',
          ]);
          aCount++;
        }
      }
    }
    if (allAlatRows.isEmpty) {
      allAlatRows.add(['1', 'Pekerjaan manual / Nihil', '-', '-', '-', '-', '-', '-']);
    }

    // 4. D. PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR
    final List<List<String>> allPersRows = [];
    final Map<String, int> roleMap = {};
    final Map<String, String> roleLokMap = {};

    for (final p in normalizedPekerjaanList) {
      final pers = (p is Map ? p['personils'] : null) as List<dynamic>? ?? [];
      final pLok = (p is Map ? p['lokasi'] : null)?.toString() ?? defaultLokasi;
      for (final pr in pers) {
        if (pr is Map) {
          final role = (pr['role'] ?? '-').toString().trim();
          final cnt = int.tryParse(pr['cacah']?.toString() ?? pr['count']?.toString() ?? '') ?? 1;
          roleMap[role] = (roleMap[role] ?? 0) + cnt;
          roleLokMap[role] = (pr['lokasi'] ?? pLok).toString();
        }
      }
    }

    if (roleMap.isNotEmpty) {
      int pCount = 1;
      roleMap.forEach((role, count) {
        allPersRows.add([
          '$pCount',
          role,
          '$count',
          roleLokMap[role] ?? defaultLokasi,
        ]);
        pCount++;
      });
    } else {
      final defaultRoles = [
        'Pengawas DPU',
        'Konsultan Pengawas',
        'Pelaksana',
        'Logistik',
        'Kepala Tukang',
        'Tukang',
        'Pekerja',
      ];
      for (int i = 0; i < defaultRoles.length; i++) {
        allPersRows.add(['${i + 1}', defaultRoles[i], '-', defaultLokasi]);
      }
    }

    // 5. E. CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN
    final List<List<String>> allCuacaRows = cuacaKejadianList.isNotEmpty
        ? cuacaKejadianList.asMap().entries.map((e) {
            final item = e.value is Map ? (e.value as Map) : <String, dynamic>{};
            final cuacaVal = item['cuaca']?.toString() ?? '-';
            final jk = item['jenisKejadian']?.toString() ?? item['jenis']?.toString() ?? '-';
            return [
              '${e.key + 1}',
              cuacaVal.isNotEmpty ? cuacaVal : '-',
              jk.isNotEmpty ? jk : '-',
              item['jam']?.toString() ?? '-',
              item['lokasi']?.toString() ?? '-',
              item['tanggungJawab']?.toString() ?? 'Tidak',
              item['akibat']?.toString() ?? '-',
            ];
          }).toList()
        : [
            ['1', 'Cerah', 'Nihil', '08:00 - 17:00', defaultLokasi, 'Tidak', '-'],
          ];

    Widget buildHorizontalScroll(Widget child) {
      return HorizontalDragScrollArea(child: child);
    }

    Widget buildScrollableBox({
      required String label,
      required Map<int, TableColumnWidth> colWidths,
      required List<String> headers,
      required List<List<String>> rows,
      double minWidth = 320,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildDocSectionLabel(label),
          const SizedBox(height: 4),
          buildHorizontalScroll(
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minWidth),
                child: _buildDocTable(
                  colWidths: colWidths,
                  headers: headers,
                  rows: rows,
                ),
              ),
            ),
          ),
        ],
      );
    }

    final tableA = buildScrollableBox(
      label: 'A.   PEKERJAAN',
      colWidths: const {
        0: FixedColumnWidth(26),
        1: FlexColumnWidth(3.8),
        2: FlexColumnWidth(2.0),
        3: FlexColumnWidth(2.2),
      },
      headers: ['No', 'JENIS PEKERJAAN', 'VOLUME', 'LOKASI'],
      rows: allJobRows,
      minWidth: 320,
    );

    final tableD = buildScrollableBox(
      label: 'D.   PERSONAL PROYEK PENGAWAS DAN KONTRAKTOR',
      colWidths: const {
        0: FixedColumnWidth(26),
        1: FlexColumnWidth(3.8),
        2: FlexColumnWidth(1.8),
        3: FlexColumnWidth(2.2),
      },
      headers: ['No', 'Personil proyek', 'Cacah', 'Lokasi'],
      rows: allPersRows,
      minWidth: 300,
    );

    final tableB = buildScrollableBox(
      label: 'B.   MATERIAL',
      colWidths: const {
        0: FixedColumnWidth(24),
        1: FlexColumnWidth(2.4),
        2: FlexColumnWidth(1.8),
        3: FlexColumnWidth(1.8),
        4: FlexColumnWidth(1.8),
      },
      headers: ['No', 'Jenis', 'Cacah Volume', 'Lokasi Awal', 'Lokasi Tujuan'],
      rows: allMatRows,
      minWidth: 340,
    );

    final tableC = buildScrollableBox(
      label: 'C.   JENIS PERALATAN YANG DIGUNAKAN',
      colWidths: const {
        0: FixedColumnWidth(22),
        1: FlexColumnWidth(2.4),
        2: FlexColumnWidth(1.3),
        3: FlexColumnWidth(1.1),
        4: FixedColumnWidth(22),
        5: FlexColumnWidth(1.6),
        6: FlexColumnWidth(1.1),
        7: FlexColumnWidth(1.1),
      },
      headers: ['No', 'Jenis Peralatan', 'Cacah aktif', 'Jumlah', 'No', 'Jenis', 'Kode', 'Rusak'],
      rows: allAlatRows,
      minWidth: 420,
    );

    final tableE = buildScrollableBox(
      label: 'E.   CUACA/BENCANA/KEJADIAN PENGHAMBAT PEKERJAAN',
      colWidths: const {
        0: FixedColumnWidth(24),
        1: FlexColumnWidth(1.8),
        2: FlexColumnWidth(2.0),
        3: FlexColumnWidth(1.4),
        4: FlexColumnWidth(1.5),
        5: FlexColumnWidth(1.8),
        6: FlexColumnWidth(1.8),
      },
      headers: ['No', 'Cuaca', 'Jenis Kejadian', 'Jam', 'Lokasi', 'Tanggung Jwb Kontraktor\n(Ya / Tidak)', 'Akibat'],
      rows: allCuacaRows,
      minWidth: 420,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double minContainerWidth = 740;
        final double effectiveWidth = constraints.maxWidth < minContainerWidth
            ? minContainerWidth
            : constraints.maxWidth;

        return buildHorizontalScroll(
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: effectiveWidth,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kolom Kiri: A & D (persis tata letak dokumen fisik dinas PU)
                  Expanded(
                    flex: 48,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tableA,
                        const SizedBox(height: 12),
                        tableD,
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Kolom Kanan: B, C, E (persis tata letak dokumen fisik dinas PU)
                  Expanded(
                    flex: 52,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        tableB,
                        const SizedBox(height: 12),
                        tableC,
                        const SizedBox(height: 12),
                        tableE,
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocSectionLabel(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black),
    );
  }

  Widget _buildDocTable({
    required Map<int, TableColumnWidth> colWidths,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return Table(
      columnWidths: colWidths,
      border: TableBorder.all(color: Colors.black, width: 0.8),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header Row
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            child: Text(
              h,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          )).toList(),
        ),
        // Data Rows
        ...rows.map((row) => TableRow(
          children: row.asMap().entries.map((entry) {
            final colIdx = entry.key;
            final text = entry.value;
            final isCenter = colIdx == 0 || colIdx == 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 10, color: Colors.black),
                textAlign: isCenter ? TextAlign.center : TextAlign.left,
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  Widget _buildDocTableSectionF(Map<String, dynamic> report, [String? _]) {
    final instruksiKonsultan = report['instruksiKonsultan']?.toString() ??
        report['instruksi']?.toString() ??
        (report['instruksiSaran'] is Map ? report['instruksiSaran']['konsultanUraian']?.toString() : '') ?? '';

    // Ambil list penandatangan pengawas jika ada
    final ttdPengawasListRaw = report['ttdPengawasList'] as List<dynamic>?;
    final List<Map<String, String?>> signers = [];

    if (ttdPengawasListRaw != null && ttdPengawasListRaw.isNotEmpty) {
      for (var t in ttdPengawasListRaw) {
        if (t is Map) {
          final n = t['nama']?.toString().trim() ?? '';
          final j = t['jabatan']?.toString().trim() ?? '';
          final s = t['signature']?.toString();
          if (n.isNotEmpty || j.isNotEmpty || (s != null && s.isNotEmpty)) {
            signers.add({'nama': n, 'jabatan': j, 'signature': s});
          }
        }
      }
    }

    if (signers.isEmpty) {
      final rawNama = report['ttdNama']?.toString().trim() ?? '';
      final rawJabatan = report['ttdJabatan']?.toString().trim() ?? '';
      final ttdNama = rawNama.isNotEmpty ? rawNama : 'MISWANTO';
      final ttdJabatan = rawJabatan.isNotEmpty ? rawJabatan : 'Inspector';
      final ttdSig = report['ttdSignature']?.toString();
      signers.add({'nama': ttdNama, 'jabatan': ttdJabatan, 'signature': ttdSig});
    }

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4.0),
        1: FlexColumnWidth(5.8),
        2: FlexColumnWidth(3.2),
      },
      border: TableBorder.all(color: Colors.black, width: 0.8),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Header: Kolom kiri kosong (Pihak/Petugas dihapus), tengah Uraian dan Saran - Saran, kanan ttd
        const TableRow(
          decoration: BoxDecoration(color: Color(0xFFE2E8F0)),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Text(
                '',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Text(
                'Uraian dan Saran - Saran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              child: Text(
                'ttd',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        // Satu-satunya Baris Konten: Konsultan Supervisi CV. TATA SAKA CONSULTANT
        TableRow(
          children: [
            // Kolom paling kiri: Konsultan Supervisi & CV. TATA SAKA CONSULTANT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Konsultan Supervisi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 9.5, color: Colors.black),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'CV. TATA SAKA CONSULTANT',
                    style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                ],
              ),
            ),
            // Kolom tengah: Uraian dan Saran - Saran dari input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                instruksiKonsultan.isNotEmpty ? instruksiKonsultan : '-',
                style: const TextStyle(fontSize: 9.5, color: Colors.black),
              ),
            ),
            // Kolom paling kanan: TTD Konsultan (Mendukung Multi-Penandatangan)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: Column(
                children: signers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final s = entry.value;
                  final ttdNama = s['nama'] ?? '';
                  final ttdJabatan = s['jabatan'] ?? '';
                  final ttdSig = s['signature'];

                  return Column(
                    children: [
                      if (idx > 0) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1, thickness: 0.5, color: Color(0xFF9CA3AF)),
                        const SizedBox(height: 6),
                      ],
                      if (ttdSig != null && ttdSig.isNotEmpty)
                        SizedBox(
                          height: 38,
                          child: _buildSignatureImagePreview(ttdSig),
                        )
                      else
                        const SizedBox(height: 28),
                      if (ttdNama.isNotEmpty)
                        Text(
                          ttdNama,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            color: Colors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      if (ttdJabatan.isNotEmpty)
                        Text(
                          ttdJabatan,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 8.5, color: Colors.black),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSignatureImagePreview(String b64) {
    if (b64.startsWith('http')) {
      return Image.network(
        b64,
        fit: BoxFit.contain,
        height: 34,
        errorBuilder: (context, error, stackTrace) => const SizedBox(height: 20),
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
        fit: BoxFit.contain,
        height: 34,
        errorBuilder: (context, error, stackTrace) => const SizedBox(height: 20),
      );
    } catch (_) {
      return const SizedBox(height: 20);
    }
  }

  Widget _buildDocSectionFoto(List<dynamic> fotoList) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: fotoList.asMap().entries.map((entry) {
        final idx = entry.key;
        final foto = entry.value.toString();
        return _buildDocPhotoItem(idx, foto);
      }).toList(),
    );
  }

  Widget _buildDocPhotoItem(int idx, String foto) {
    final isBase64 = foto.startsWith('data:image') || (!foto.startsWith('Foto ') && foto.length > 50);

    return InkWell(
      onTap: () => _showDocPhotoDialog(idx, foto),
      child: Container(
        width: 140,
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: Colors.black45),
        ),
        clipBehavior: Clip.antiAlias,
        child: isBase64
            ? Stack(
                fit: StackFit.expand,
                children: [
                  _buildPhotoWidget(foto, fit: BoxFit.cover),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Text(
                        'Foto #${idx + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.image, size: 36, color: AppColors.primaryBlue),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      foto,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPhotoWidget(String b64, {BoxFit fit = BoxFit.cover}) {
    if (b64.startsWith('http')) {
      return Image.network(
        b64,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
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
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, size: 28, color: Colors.grey),
        ),
      );
    } catch (_) {
      return const Center(child: Icon(Icons.image_not_supported, color: Colors.grey));
    }
  }

  void _showDocPhotoDialog(int idx, String foto) {
    final isBase64 = foto.startsWith('data:image') || (!foto.startsWith('Foto ') && foto.length > 50);

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
                maxHeight: MediaQuery.of(context).size.height * 0.75,
                maxWidth: 650,
              ),
              child: isBase64
                  ? _buildPhotoWidget(foto, fit: BoxFit.contain)
                  : Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.image, size: 60, color: Colors.blueGrey),
                          const SizedBox(height: 12),
                          Text(foto, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SEPARATOR ANTAR HALAMAN FISIK ---
  Widget _buildPageSeparator(String title, int page, int totalPages) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.black26, thickness: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.description, size: 14, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    'LEMBAR $page DARI $totalPages : $title',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.black26, thickness: 1)),
        ],
      ),
    );
  }

  // --- TABEL DOKUMEN DENGAN DUA BARIS HEADER (NAMA KOLOM & HURUF a,b,c...) ---
  Widget _buildDocTableWithSubheader({
    required Map<int, TableColumnWidth> colWidths,
    required List<String> headers,
    required List<String> subLetters,
    required List<List<String>> rows,
  }) {
    return Table(
      columnWidths: colWidths,
      border: TableBorder.all(color: Colors.black, width: 0.8),
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        // Main Headers (Baris 1)
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
            child: Text(
              h,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8.5, color: Colors.black),
              textAlign: TextAlign.center,
            ),
          )).toList(),
        ),
        // Sub-letter Row (Baris 2: a, b, c, d...)
        TableRow(
          decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
          children: subLetters.map((l) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Text(
              l,
              style: const TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          )).toList(),
        ),
        // Data Rows
        ...rows.map((row) => TableRow(
          children: row.asMap().entries.map((entry) {
            final colIdx = entry.key;
            final text = entry.value;
            final isCenter = colIdx == 0 || colIdx >= 2;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              child: Text(
                text,
                style: const TextStyle(fontSize: 9.5, color: Colors.black),
                textAlign: isCenter ? TextAlign.center : TextAlign.left,
              ),
            );
          }).toList(),
        )),
      ],
    );
  }

  // --- LEMBAR REKAPITULASI 1: SUHU DI LAPANGAN (9 Kolom: a s/d i) ---
  Widget _buildSheetRekapSuhuLapangan({
    required String namaKegiatan,
    required String kontraktor,
    required List<dynamic> rows,
    required int page,
    required int totalPages,
  }) {
    const colWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(24), // No [a]
      1: FlexColumnWidth(2.3), // NOMOR KENDARAAN [b]
      2: FlexColumnWidth(1.8), // JAM DATANG KE LAPANGAN [c]
      3: FlexColumnWidth(1.6), // SUHU DATANG [d]
      4: FlexColumnWidth(1.6), // SUHU HAMPAR [e]
      5: FlexColumnWidth(1.9), // JAM MULAI TUANG KE FINISHER [f]
      6: FlexColumnWidth(1.9), // JAM SELESEI TUANG KE FINISHER [g]
      7: FlexColumnWidth(1.8), // SUHU PEMADATAN AKHIR [h]
      8: FlexColumnWidth(1.8), // JAM PULANG KE LAPANGAN [i]
    };

    final headers = [
      'No',
      'NOMOR\nKENDARAAN',
      'JAM DATANG\nKE LAPANGAN',
      'SUHU\nDATANG',
      'SUHU\nHAMPAR',
      'JAM MULAI TUANG\nKE FINISHER',
      'JAM SELESEI TUANG\nKE FINISHER',
      'SUHU PEMADATAN\nAKHIR',
      'JAM PULANG\nKE LAPANGAN',
    ];
    final subLetters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'];

    String formatSuhu(dynamic val) {
      if (val == null) return '-';
      final s = val.toString().trim();
      if (s.isEmpty || s == '-') return '-';
      return s.endsWith('°C') ? s : '$s°C';
    }

    final tableRows = rows.isNotEmpty
        ? rows.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            final rawSuhuDatang = item['suhuDatang'];
            final rawSuhuHampar = item['suhuHampar'] ?? item['suhuLap'] ?? item['suhu'];
            final rawSuhuAkhir = item['suhuPemadatanAkhir'] ?? item['suhuAkhir'];

            return [
              '${entry.key + 1}',
              PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
              item['jamDatang']?.toString().isNotEmpty == true ? item['jamDatang'].toString() : '-',
              formatSuhu(rawSuhuDatang),
              formatSuhu(rawSuhuHampar),
              item['jamMulaiTuang']?.toString().isNotEmpty == true ? item['jamMulaiTuang'].toString() : '-',
              item['jamSelesaiTuang']?.toString().isNotEmpty == true ? item['jamSelesaiTuang'].toString() : '-',
              formatSuhu(rawSuhuAkhir),
              item['jamPulang']?.toString().isNotEmpty == true ? item['jamPulang'].toString() : '-',
            ];
          }).toList()
        : [
            ['1', '-', '-', '-', '-', '-', '-', '-', '-'],
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Judul
          const Center(
            child: Text(
              'REKAPITULASI WAKTU TEMPUH DT & SUHU DI LAPANGAN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
                decoration: TextDecoration.underline,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // Metadata Kegiatan, Penyedia Jasa, Konsultan Pengawas
          _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
          _buildDocMetaRow('PENYEDIA JASA', ':  $kontraktor'),
          _buildDocMetaRow('KONSULTAN PENGAWAS', ':  CV. Tata Saka Consultant'),
          const SizedBox(height: 12),

          // Tabel 9 Kolom (a s/d i)
          _buildDocTableWithSubheader(
            colWidths: colWidths,
            headers: headers,
            subLetters: subLetters,
            rows: tableRows,
          ),

          // Footer Lembar Rekapitulasi
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.black26),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REKAPITULASI WAKTU TEMPUH DT & SUHU DI LAPANGAN',
                style: TextStyle(fontSize: 8.5, color: Colors.black54),
              ),
              Text(
                'Halaman $page dari $totalPages',
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LEMBAR REKAPITULASI 2: SUHU DI AMP (5 Kolom: a s/d e) ---
  Widget _buildSheetRekapSuhuAmp({
    required String namaKegiatan,
    required String kontraktor,
    required List<dynamic> rows,
    required int page,
    required int totalPages,
  }) {
    const colWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(28), // No [a]
      1: FlexColumnWidth(2.8), // NOMOR KENDARAAN [b]
      2: FlexColumnWidth(2.2), // JAM PERGI / DARI AMP [c]
      3: FlexColumnWidth(2.0), // SUHU DI AMP [d]
      4: FlexColumnWidth(2.2), // JAM PULANG KE AMP [e]
    };

    final headers = [
      'No',
      'NOMOR KENDARAAN',
      'JAM PERGI / DARI AMP',
      'SUHU DI AMP',
      'JAM PULANG KE AMP',
    ];
    final subLetters = ['a', 'b', 'c', 'd', 'e'];

    final tableRows = rows.isNotEmpty
        ? rows.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            return [
              '${entry.key + 1}',
              PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
              item['jamPergi']?.toString() ?? '',
              item['suhuAmp']?.toString() ?? '',
              item['jamPulang']?.toString() ?? '',
            ];
          }).toList()
        : [
            ['1', '-', '-', '-', '-'],
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Judul
          const Center(
            child: Text(
              'REKAPITULASI WAKTU TEMPUH DT & SUHU DI AMP',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
                decoration: TextDecoration.underline,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // Metadata Kegiatan, Penyedia Jasa, Konsultan Pengawas
          _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
          _buildDocMetaRow('PENYEDIA JASA', ':  $kontraktor'),
          _buildDocMetaRow('KONSULTAN PENGAWAS', ':  CV. Tata Saka Consultant'),
          const SizedBox(height: 12),

          // Tabel 5 Kolom
          _buildDocTableWithSubheader(
            colWidths: colWidths,
            headers: headers,
            subLetters: subLetters,
            rows: tableRows,
          ),

          // Footer Lembar Rekapitulasi
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.black26),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REKAPITULASI WAKTU TEMPUH DT & SUHU DI AMP',
                style: TextStyle(fontSize: 8.5, color: Colors.black54),
              ),
              Text(
                'Halaman $page dari $totalPages',
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LEMBAR REKAPITULASI 3: TONASE ASPAL (4 Kolom: a s/d d) ---
  Widget _buildSheetRekapTonaseAspal({
    required String namaKegiatan,
    required String kontraktor,
    required List<dynamic> rows,
    required int page,
    required int totalPages,
  }) {
    const colWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(30), // No [a]
      1: FlexColumnWidth(3.5), // NOMOR KENDARAAN [b]
      2: FlexColumnWidth(2.5), // TONASE TIKET [c]
      3: FlexColumnWidth(2.5), // JUMLAH KUMULATIF [d]
    };

    final headers = [
      'No',
      'NOMOR KENDARAAN',
      'TONASE TIKET',
      'JUMLAH KUMULATIF',
    ];
    final subLetters = ['a', 'b', 'c', 'd'];

    final tableRows = rows.isNotEmpty
        ? rows.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            return [
              '${entry.key + 1}',
              PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
              item['tonaseTiket']?.toString() ?? '',
              item['jumlahKumulatif']?.toString() ?? '',
            ];
          }).toList()
        : [
            ['1', '-', '-', '-'],
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Judul
          const Center(
            child: Text(
              'REKAPITULASI TONASE ASPAL',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
                decoration: TextDecoration.underline,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // Metadata Kegiatan & Kontraktor
          _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
          _buildDocMetaRow('PENYEDIA JASA', ':  $kontraktor'),
          _buildDocMetaRow('KONSULTAN PENGAWAS', ':  CV. Tata Saka Consultant'),
          const SizedBox(height: 12),

          // Tabel 4 Kolom
          _buildDocTableWithSubheader(
            colWidths: colWidths,
            headers: headers,
            subLetters: subLetters,
            rows: tableRows,
          ),

          // Footer Lembar Rekapitulasi
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.black26),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REKAPITULASI TONASE ASPAL',
                style: TextStyle(fontSize: 8.5, color: Colors.black54),
              ),
              Text(
                'Halaman $page dari $totalPages',
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LEMBAR REKAPITULASI BETON READY MIX (7 Kolom: a s/d g) ---
  Widget _buildSheetRekapBeton({
    required String namaKegiatan,
    required String penyediaJasa,
    required String jenisBeton,
    required List<dynamic> rows,
    required int page,
    required int totalPages,
  }) {
    const colWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(26), // No [a]
      1: FlexColumnWidth(2.3), // NOMOR KENDARAAN [b]
      2: FlexColumnWidth(2.5), // BATCHING PLANT [c]
      3: FlexColumnWidth(1.9), // JAM BERANGKAT DARI BP [d]
      4: FlexColumnWidth(1.9), // JAM DATANG DI LAPANGAN [e]
      5: FlexColumnWidth(1.9), // JAM BERANGKAT DARI LAPANGAN [f]
      6: FlexColumnWidth(1.9), // JAM TIBA DI BATCHING PLANT [g]
      7: FlexColumnWidth(1.6), // SLUMP TEST [h]
      8: FlexColumnWidth(1.6), // VOLUME [i]
    };

    final headers = [
      'No',
      'NOMOR KENDARAAN\n(TRUCK MIXER)',
      'BATCHING PLANT\nREADY MIX',
      'JAM BERANGKAT\nDARI BP',
      'JAM DATANG\nDI LAPANGAN',
      'JAM BERANGKAT\nDARI LAPANGAN',
      'JAM TIBA DI\nBATCHING PLANT',
      'SLUMP TEST\n(CM)',
      'VOLUME\n(M³)',
    ];
    final subLetters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i'];

    final double totalVolume = rows.fold(0.0, (sum, item) {
      if (item is Map) {
        final val = double.tryParse((item['volume']?.toString() ?? '').replaceAll(',', '.')) ?? 0.0;
        return sum + val;
      }
      return sum;
    });

    final String formattedTotal = totalVolume % 1 == 0
        ? totalVolume.toInt().toString()
        : totalVolume.toStringAsFixed(2).replaceAll('.', ',');

    final tableRows = rows.isNotEmpty
        ? rows.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            final rawVol = item['volume']?.toString() ?? '-';
            final jamBerangkat = item['jamBerangkat']?.toString() ?? '';
            final jamDatang = item['jamDatang']?.toString() ?? '';
            final jamBerangkatLap = item['jamBerangkatLap']?.toString() ??
                item['jamBerangkatLapangan']?.toString() ??
                '';
            final jamTibaPlant = item['jamTibaPlant']?.toString() ??
                item['jamTibaBatchingPlant']?.toString() ??
                '';
            return [
              '${entry.key + 1}',
              PlatNomorUtil.normalize(item['nomorKendaraan']?.toString() ?? ''),
              item['batchingPlant']?.toString().isNotEmpty == true ? item['batchingPlant'].toString() : '-',
              jamBerangkat.isNotEmpty ? jamBerangkat : '-',
              jamDatang.isNotEmpty ? jamDatang : '-',
              jamBerangkatLap.isNotEmpty ? jamBerangkatLap : '-',
              jamTibaPlant.isNotEmpty ? jamTibaPlant : '-',
              item['slumpTest']?.toString().isNotEmpty == true ? item['slumpTest'].toString() : '-',
              rawVol.isNotEmpty ? (rawVol.endsWith('m³') ? rawVol : '$rawVol m³') : '-',
            ];
          }).toList()
        : [
            ['1', '-', '-', '-', '-', '-', '-', '-', '-'],
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Judul
          const Center(
            child: Text(
              'REKAPITULASI PENGIRIMAN & PENGECORAN BETON READY MIX',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
                decoration: TextDecoration.underline,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // Metadata Kegiatan, Penyedia Jasa, Konsultan Pengawas, Jenis Beton
          _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
          _buildDocMetaRow('PENYEDIA JASA', ':  $penyediaJasa'),
          _buildDocMetaRow('KONSULTAN PENGAWAS', ':  CV. Tata Saka Consultant'),
          _buildDocMetaRow('JENIS BETON', ':  $jenisBeton'),
          const SizedBox(height: 12),

          // Tabel 7 Kolom
          _buildDocTableWithSubheader(
            colWidths: colWidths,
            headers: headers,
            subLetters: subLetters,
            rows: tableRows,
          ),

          // Ringkasan Total Volume Kubikasi
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(
                left: BorderSide(color: Colors.black, width: 0.8),
                right: BorderSide(color: Colors.black, width: 0.8),
                bottom: BorderSide(color: Colors.black, width: 0.8),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL VOLUME PENGECORAN BETON',
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  '$formattedTotal m³',
                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ],
            ),
          ),

          // Footer Lembar Rekapitulasi
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.black26),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REKAPITULASI PENGECORAN BETON READY MIX',
                style: TextStyle(fontSize: 8.5, color: Colors.black54),
              ),
              Text(
                'Halaman $page dari $totalPages',
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LEMBAR REKAPITULASI 4: DATA PERJALANAN DT (AMP - LAPANGAN - AMP) (21 Kolom: a s/d u) ---
  Widget _buildSheetDataPerjalananDt({
    required String namaKegiatan,
    required String lokasi,
    required String kontraktor,
    required Map<String, dynamic> report,
    required int page,
    required int totalPages,
  }) {
    final jenisMaterial = (report['jenisMaterialAspal']?.toString().isNotEmpty == true)
        ? report['jenisMaterialAspal'].toString()
        : 'AC - WC';
    final penyediaAmp = (report['penyediaAmp']?.toString().isNotEmpty == true)
        ? report['penyediaAmp'].toString()
        : 'CV. SATYA WIGUNA';
    final jarakTempuhVal = report['jarakTempuh']?.toString() ?? '35.5';
    final double jarakKm = double.tryParse(jarakTempuhVal.replaceAll(',', '.')) ?? 35.5;
    final jarakTempuhText = '${PlatNomorUtil.formatDecimal(jarakKm, fractionDigits: 1)} km';

    final hari = report['hari']?.toString() ?? '';
    final tanggal = report['tanggal']?.toString() ?? '';
    final hariTanggal = (hari.isNotEmpty && tanggal.isNotEmpty)
        ? '$hari, $tanggal'
        : (tanggal.isNotEmpty ? tanggal : '-');

    final rawLapList = (report['rekapSuhuLapanganList'] as List<dynamic>?) ?? [];
    final rawDtList = (report['rekapPengirimanDtList'] as List<dynamic>?) ?? [];
    final lapanganList = rawLapList.isNotEmpty
        ? rawLapList.asMap().entries.map((e) {
            final m = Map<String, dynamic>.from(e.value as Map);
            if ((m['waktuAntrian'] == null || m['waktuAntrian'].toString().isEmpty) &&
                e.key < rawDtList.length &&
                rawDtList[e.key] is Map) {
              m['waktuAntrian'] = (rawDtList[e.key] as Map)['waktuAntrian'];
            }
            return m;
          }).toList()
        : (rawDtList.isNotEmpty
            ? rawDtList.map((m) => {
                'nomorKendaraan': m['nomorKendaraan'],
                'jamDatang': m['jamDatangLap'] ?? m['jamDatang'],
                'suhuDatang': m['suhuDatang'],
                'suhu': m['suhuLap'] ?? m['suhu'],
                'suhuLap': m['suhuLap'] ?? m['suhu'],
                'jamMulaiTuang': m['jamMulaiTuang'],
                'jamSelesaiTuang': m['jamSelesaiTuang'],
                'suhuPemadatanAkhir': m['suhuPemadatanAkhir'],
                'jamPulang': m['jamPulangLap'] ?? m['jamPulang'],
                'waktuAntrian': m['waktuAntrian'],
              }).toList()
            : []);

    final rows = PlatNomorUtil.computeDataPerjalananRows(
      lapanganList: lapanganList,
      ampList: (report['rekapSuhuAmpList'] as List<dynamic>?) ?? [],
      tonaseList: (report['rekapTonaseAspalList'] as List<dynamic>?) ?? [],
      jarakKm: jarakKm,
    );

    final double totalTonase = rows.fold(0.0, (sum, r) => sum + (r['beratAc'] as double));

    const colWidths = <int, TableColumnWidth>{
      0: FixedColumnWidth(28), // No [a]
      1: FixedColumnWidth(34), // HURUF DEPAN [b]
      2: FixedColumnWidth(50), // ANGKA [c]
      3: FixedColumnWidth(40), // HURUF BELAKANG [d]
      4: FixedColumnWidth(34), // RIT [e]
      5: FixedColumnWidth(56), // DARI AMP [f]
      6: FixedColumnWidth(56), // TIBA LOKASI [g]
      7: FixedColumnWidth(56), // DARI LOKASI [h]
      8: FixedColumnWidth(56), // TIBA AMP [i]
      9: FixedColumnWidth(66), // WAKTU BRKT [j]
      10: FixedColumnWidth(62), // WAKTU ANTRI [k]
      11: FixedColumnWidth(62), // WAKTU HAMPAR [l]
      12: FixedColumnWidth(66), // WAKTU PULANG [m]
      13: FixedColumnWidth(62), // TOTAL JAM [n]
      14: FixedColumnWidth(44), // SUHU AMP [o]
      15: FixedColumnWidth(46), // SUHU LOKASI [p]
      16: FixedColumnWidth(46), // SELISIH SUHU [q]
      17: FixedColumnWidth(62), // TURUN/JAM [r]
      18: FixedColumnWidth(66), // KEC. BRKT [s]
      19: FixedColumnWidth(66), // KEC. PULANG [t]
      20: FixedColumnWidth(64), // BERAT AC [u]
    };

    final headers = [
      'No',
      'HURUF\nDEPAN',
      'ANGKA',
      'HURUF\nBLKG',
      'RIT\nKE-',
      'DARI\nAMP',
      'TIBA DI\nLOKASI',
      'DARI\nLOKASI',
      'TIBA\nDI AMP',
      'WAKTU\nBRKT (J)',
      'WAKTU\nANTRI',
      'WAKTU\nHAMPAR',
      'WAKTU\nPLNG (J)',
      'TOTAL\n(JAM)',
      'SUHU\nAMP',
      'SUHU\nLOK.',
      'SELISIH\nSUHU',
      'TURUN /\nJAM',
      'KEC. BRKT\n(KM/JAM)',
      'KEC. PLNG\n(KM/JAM)',
      'BERAT AC\n(TON)',
    ];

    final subLetters = [
      'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
      'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u'
    ];

    final tableRows = rows.isNotEmpty
        ? rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final r = entry.value;
            return [
              '${idx + 1}',
              r['platePrefix']?.toString() ?? '',
              r['plateNumber']?.toString() ?? '',
              r['plateSuffix']?.toString() ?? '',
              '${r['rit'] ?? 1}',
              r['jamDariAmp']?.toString() ?? '',
              r['jamTibaLokasi']?.toString() ?? '',
              r['jamDariLokasi']?.toString() ?? '',
              r['jamTibaAmp']?.toString() ?? '',
              PlatNomorUtil.formatDecimal(r['waktuBerangkatJam'] as double, fractionDigits: 3),
              r['waktuAntrian']?.toString() ?? '0:05:00',
              r['waktuHampar']?.toString() ?? '0:08:28',
              PlatNomorUtil.formatDecimal(r['waktuPulangJam'] as double, fractionDigits: 3),
              PlatNomorUtil.formatDecimal(r['totalJam'] as double, fractionDigits: 3),
              (r['suhuAmp'] as double) > 0 ? PlatNomorUtil.formatDecimal(r['suhuAmp'] as double, fractionDigits: 0) : '-',
              (r['suhuLokasi'] as double) > 0 ? PlatNomorUtil.formatDecimal(r['suhuLokasi'] as double, fractionDigits: 0) : '-',
              (r['selisihSuhu'] as double) > 0 ? PlatNomorUtil.formatDecimal(r['selisihSuhu'] as double, fractionDigits: 0) : '-',
              (r['turunPerJam'] as double) > 0 ? PlatNomorUtil.formatDecimal(r['turunPerJam'] as double, fractionDigits: 3) : '-',
              (r['kecepatanBerangkat'] as double) > 0 ? PlatNomorUtil.formatDecimal(r['kecepatanBerangkat'] as double, fractionDigits: 3) : '-',
              (r['kecepatanPulang'] as double) > 0 ? PlatNomorUtil.formatDecimal(r['kecepatanPulang'] as double, fractionDigits: 3) : '-',
              PlatNomorUtil.formatDecimal(r['beratAc'] as double, fractionDigits: 2),
            ];
          }).toList()
        : [
            List.filled(21, '-'),
          ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black45, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Judul
          const Center(
            child: Text(
              'DATA PERJALANAN DT (AMP - LAPANGAN - AMP)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
                decoration: TextDecoration.underline,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 14),

          // Metadata Dokumen
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDocMetaRow('KEGIATAN', ':  $namaKegiatan'),
                    _buildDocMetaRow('LOKASI', ':  $lokasi'),
                    _buildDocMetaRow('PENYEDIA JASA', ':  $kontraktor'),
                    _buildDocMetaRow('PENGAWAS', ':  CV. Tata Saka Consultant'),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDocMetaRow('JENIS MATERIAL', ':  $jenisMaterial'),
                    _buildDocMetaRow('PENYEDIA (AMP)', ':  $penyediaAmp'),
                    _buildDocMetaRow('JARAK TEMPUH', ':  $jarakTempuhText'),
                    _buildDocMetaRow('HARI / TANGGAL', ':  $hariTanggal'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Tabel 21 Kolom dalam Scroll Horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1176),
              child: Table(
                columnWidths: colWidths,
                border: TableBorder.all(color: Colors.black, width: 0.8),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Baris Header 1: Nama Kolom
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                    children: headers.map((h) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                      child: Text(
                        h,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8.2, color: Colors.black),
                        textAlign: TextAlign.center,
                      ),
                    )).toList(),
                  ),
                  // Baris Header 2: Sub-letter (a s/d u)
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                    children: subLetters.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                      child: Text(
                        l,
                        style: const TextStyle(fontSize: 8, fontStyle: FontStyle.italic, color: Colors.black87),
                        textAlign: TextAlign.center,
                      ),
                    )).toList(),
                  ),
                  // Data Rows
                  ...tableRows.map((row) => TableRow(
                    children: row.asMap().entries.map((entry) {
                      final text = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        child: Text(
                          text,
                          style: const TextStyle(fontSize: 8.5, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }).toList(),
                  )),
                  // Summary Total Row
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFE2E8F0)),
                    children: [
                      ...List.generate(20, (cIdx) {
                        if (cIdx == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                            child: Text(
                              'JUMLAH',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 8.5, color: Colors.black),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                        child: Text(
                          PlatNomorUtil.formatDecimal(totalTonase, fractionDigits: 2),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8.5, color: Colors.black),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Footer Lembar Rekapitulasi
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.black26),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DATA PERJALANAN DT (AMP - LAPANGAN - AMP)',
                style: TextStyle(fontSize: 8.5, color: Colors.black54),
              ),
              Text(
                'Halaman $page dari $totalPages',
                style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ContractProvider? contractProvider;
    try {
      contractProvider = Provider.of<ContractProvider>(context);
    } catch (_) {
      contractProvider = null;
    }
    final liveContract = contractProvider?.contracts.firstWhere(
      (c) => c.id == widget.contract.id,
      orElse: () => widget.contract,
    ) ?? widget.contract;

    final kegiatan = (liveContract.kegiatans.isNotEmpty &&
            _currentKegiatanIndex < liveContract.kegiatans.length)
        ? liveContract.kegiatans[_currentKegiatanIndex]
        : _currentKegiatan;
    final String namaKegiatan = kegiatan?['namaKegiatan'] ?? liveContract.namaKontrak;
    final String lokasi = kegiatan?['lokasi'] ?? '-';
    final String kontraktor = kegiatan?['kontraktor'] ?? '-';
    final reportsOnSelectedDate = _getReportsForDate(_selectedDate);

    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final isKonsultan = userProf?.isKonsultan ?? true;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    final headerActions = [
      if (liveContract.kegiatans.length > 1)
        PopupMenuButton<int>(
          tooltip: 'Ganti Kegiatan',
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          icon: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDesktop ? AppColors.slateDark : AppColors.slateLighter,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.swap_horiz, color: isDesktop ? Colors.white : AppColors.primaryBlue, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Kegiatan',
                  style: TextStyle(
                    color: isDesktop ? Colors.white : AppColors.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          onSelected: (idx) {
            setState(() {
              _currentKegiatanIndex = idx;
            });
          },
          itemBuilder: (ctx) => liveContract.kegiatans.asMap().entries.map((e) {
            return PopupMenuItem<int>(
              value: e.key,
              child: Row(
                children: [
                  Icon(
                    e.key == _currentKegiatanIndex ? Icons.check_circle : Icons.circle_outlined,
                    color: e.key == _currentKegiatanIndex ? AppColors.primaryBlue : AppColors.textLight,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.value['namaKegiatan'] ?? 'Kegiatan ${e.key + 1}',
                      style: TextStyle(
                        fontWeight: e.key == _currentKegiatanIndex ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      const SizedBox(width: 8),
    ];

    final mainBody = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card (Kegiatan & Kontrak Info)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.slateLighter,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.work_outline, color: AppColors.primaryBlue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        namaKegiatan,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.description_outlined, size: 14, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.contract.namaKontrak,
                              style: const TextStyle(color: AppColors.textLight, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, size: 7, color: AppColors.successGreen),
                                const SizedBox(width: 4),
                                Text(
                                  widget.contract.status == 'Selesai' ? 'Selesai' : 'Progres',
                                  style: const TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (lokasi != '-')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 12, color: AppColors.textLight),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 140),
                                    child: Text(
                                      lokasi,
                                      style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (kontraktor != '-')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.inputBackground,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_outline, size: 12, color: AppColors.textLight),
                                  const SizedBox(width: 4),
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 140),
                                    child: Text(
                                      kontraktor,
                                      style: const TextStyle(color: AppColors.textLight, fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
              ],
            ),
          ),

          // Tab Switcher (Laporan Harian vs Laporan Mingguan)
          _buildLaporanTypeSwitcher(),

          if (_selectedTab == 0) ...[
            // Calendar Section with Week navigation & Green Dots for reports
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(top: 16, bottom: 16),
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null) {
                    if (details.primaryVelocity! < -200) {
                      _goToNextWeek();
                    } else if (details.primaryVelocity! > 200) {
                      _goToPreviousWeek();
                    }
                  }
                },
                child: Column(
                  children: [
                    // Month Header with Nav Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: AppColors.textDark, size: 28),
                            splashRadius: 22,
                            tooltip: 'Minggu Sebelumnya',
                            onPressed: _goToPreviousWeek,
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2035),
                              );
                              if (picked != null) {
                                setState(() {
                                  _selectedDate = DateTime(picked.year, picked.month, picked.day);
                                  _currentWeekMonday = _getMondayOfWeek(_selectedDate);
                                });
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${_namaBulan[_selectedDate.month - 1]} ${_selectedDate.year}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_drop_down, color: AppColors.primaryBlue),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: AppColors.textDark, size: 28),
                            splashRadius: 22,
                            tooltip: 'Minggu Selanjutnya',
                            onPressed: _goToNextWeek,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    // 7 Days of the Week
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: List.generate(7, (i) {
                          final dayDate = _currentWeekMonday.add(Duration(days: i));
                          final dayName = _namaHariSingkat[i];
                          return _buildDayItem(dayName, dayDate);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Date Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_namaHariPanjang[_selectedDate.weekday - 1]}, ${_selectedDate.day.toString().padLeft(2, '0')} ${_namaBulan[_selectedDate.month - 1]} ${_selectedDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (reportsOnSelectedDate.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${reportsOnSelectedDate.length} Laporan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Report Content List OR Empty State
            Expanded(
              child: reportsOnSelectedDate.isNotEmpty
                  ? ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: reportsOnSelectedDate.length,
                      itemBuilder: (context, index) {
                        final report = reportsOnSelectedDate[index];
                        return _buildReportItem(report, index, isKonsultan: isKonsultan);
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 56,
                            color: AppColors.textLight.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Tidak ada laporan pada hari ini',
                            style: TextStyle(
                              color: AppColors.textLight,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (isKonsultan) ...[
                            const SizedBox(height: 18),
                            ElevatedButton.icon(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BuatLaporanScreen(
                                      initialContract: widget.contract,
                                      initialKegiatanIndex: _currentKegiatanIndex,
                                      initialDate: _selectedDate,
                                    ),
                                  ),
                                );
                                if (result == true && mounted) {
                                  setState(() {});
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Buat Laporan untuk Hari Ini'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ] else ...[
            // Laporan Mingguan Section
            Expanded(
              child: _buildLaporanMingguanListSection(isKonsultan: isKonsultan),
            ),
          ],
        ],
      );

    if (isDesktop) {
      return WebDashboardLayout(
        title: 'Data Laporan: $namaKegiatan',
        activeMenu: 'data_laporan',
        showBackButton: true,
        actions: headerActions,
        child: mainBody,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
            }
          },
        ),
        title: const Text(
          'Data Laporan',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: headerActions,
      ),
      body: mainBody,
    );
  }

  Widget _buildLaporanTypeSwitcher() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            _buildTabOption(0, Icons.calendar_today, 'Harian'),
            const SizedBox(width: 4),
            _buildTabOption(1, Icons.analytics_outlined, 'Mingguan'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withValues(alpha: 0.25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: isSelected ? Colors.white : AppColors.textLight,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLaporanMingguanListSection({bool isKonsultan = true}) {
    final keg = _currentKegiatan;
    final List<dynamic> rawList = keg?['laporanMingguan'] ?? [];
    final List<WeeklyReportModel> weeklyReports = rawList
        .map((e) => WeeklyReportModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    weeklyReports.sort((a, b) => b.mingguKe.compareTo(a.mingguKe));

    return Column(
      children: [
        // Subheader with Count & Tambah Button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Kegiatan Mingguan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${weeklyReports.length} Laporan • Format Dinas PU',
                      style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isKonsultan) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BuatLaporanMingguanScreen(
                          initialContract: widget.contract,
                          initialKegiatanIndex: _currentKegiatanIndex,
                        ),
                      ),
                    );
                    if (result == true && mounted) {
                      setState(() {});
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Buat Baru', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ),

        // List View or Empty State
        Expanded(
          child: weeklyReports.isNotEmpty
              ? ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                  itemCount: weeklyReports.length,
                  itemBuilder: (context, index) {
                    final report = weeklyReports[index];
                    return _buildWeeklyReportCard(report, isKonsultan: isKonsultan);
                  },
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        size: 56,
                        color: AppColors.textLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Belum ada Laporan Mingguan untuk kegiatan ini',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (isKonsultan) ...[
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuatLaporanMingguanScreen(
                                  initialContract: widget.contract,
                                  initialKegiatanIndex: _currentKegiatanIndex,
                                ),
                              ),
                            );
                            if (result == true && mounted) {
                              setState(() {});
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Buat Ringkasan Mingguan Pertama'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildWeeklyReportCard(WeeklyReportModel report, {bool isKonsultan = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7).withValues(alpha: 0.35),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.analytics_outlined, color: Color(0xFFD97706), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Ringkasan Kegiatan Mingguan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Minggu ${report.mingguKe} dari ${report.totalMinggu}',
                              style: const TextStyle(
                                color: Color(0xFFB45309),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.periodeAwal} s/d ${report.periodeAkhir} • ${report.kontraktor}',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Metrics Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 3 Cards: Rencana, Realisasi, Deviasi
                Row(
                  children: [
                    // Rencana
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Rencana Fisik', style: TextStyle(fontSize: 10, color: AppColors.textLight), maxLines: 1),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                WeeklyReportModel.formatPercent(report.rencanaPersen, decimalDigits: 2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                WeeklyReportModel.formatRupiah(report.rencanaNominal),
                                style: const TextStyle(fontSize: 9.5, color: AppColors.textLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Realisasi
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Realisasi Fisik', style: TextStyle(fontSize: 10, color: AppColors.textLight), maxLines: 1),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                WeeklyReportModel.formatPercent(report.realisasiPersen, decimalDigits: 2),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                WeeklyReportModel.formatRupiah(report.realisasiNominal),
                                style: const TextStyle(fontSize: 9.5, color: AppColors.textLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Deviasi (Highlight Yellow)
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDE59),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Deviasi (+/-)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1),
                            const SizedBox(height: 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                WeeklyReportModel.formatPercent(report.deviasiPersen, decimalDigits: 2, showSign: true),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.black),
                              ),
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                WeeklyReportModel.formatRupiah(report.deviasiNominal),
                                style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Waktu chips
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildReportChip(Icons.timer_outlined, 'Terpakai: ${report.waktuTerpakai} Hari'),
                    _buildReportChip(Icons.hourglass_bottom_outlined, 'Sisa: ${report.sisaWaktu} Hari'),
                    _buildReportChip(Icons.event_available_outlined, 'Akhir: ${report.akhirMasaKontrak}'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDetailLaporanMingguanModal(report),
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                        label: const Text(
                          'Buka Dokumen',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                        ),
                      ),
                    ),
                    if (isKonsultan) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue, size: 20),
                        tooltip: 'Edit Laporan Mingguan',
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BuatLaporanMingguanScreen(
                                initialContract: widget.contract,
                                initialKegiatanIndex: _currentKegiatanIndex,
                                editReport: report,
                              ),
                            ),
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: 'Hapus Laporan Mingguan',
                        onPressed: () => _confirmDeleteWeeklyReport(report.id),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetailLaporanMingguanModal(WeeklyReportModel report) {
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context, listen: false);
    } catch (_) {
      userProf = null;
    }
    final isKonsultan = userProf?.isKonsultan ?? true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF1F5F9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.94,
        maxChildSize: 0.98,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Top Toolbar Actions
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textDark),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ringkasan Mingguan (M-${report.mingguKe})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${report.periodeAwal} - ${report.periodeAkhir}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isKonsultan) ...[
                    const SizedBox(width: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BuatLaporanMingguanScreen(
                              initialContract: widget.contract,
                              initialKegiatanIndex: _currentKegiatanIndex,
                              editReport: report,
                            ),
                          ),
                        );
                        if (result == true && mounted) {
                          setState(() {});
                        }
                      },
                      icon: const Icon(Icons.edit, size: 13),
                      label: const Text('Edit', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                  const SizedBox(width: 6),
                  ElevatedButton.icon(
                    onPressed: () => _showWeeklyPdfOptions(report),
                    icon: const Icon(Icons.picture_as_pdf, size: 13, color: Colors.white),
                    label: const Text('PDF', style: TextStyle(fontSize: 11, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // LEMBAR FISIK DOKUMEN ASLI
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sheet 1: RINGKASAN KEGIATAN MINGGUAN
                        LembarLaporanMingguanWidget(
                          report: report,
                          onDownloadPdf: () => _openRingkasanMingguanPdf(report),
                        ),
                        const SizedBox(height: 24),
                        // Sheet 2: LEMBAR KEMAJUAN FISIK PEKERJAAN (BoQ / RKK RESMI PU)
                        LembarBoqMingguanWidget(
                          report: report,
                          kegiatan: _currentKegiatan,
                          onDownloadPdf: () => _openBoqMingguanPdf(report),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRingkasanMingguanPdf(WeeklyReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          title: 'Ringkasan Mingguan - Minggu Ke-${report.mingguKe}',
          fileName: 'Ringkasan_Mingguan_Minggu_${report.mingguKe}.pdf',
          pageFormat: PdfPageFormat.a4,
          buildPdf: () => PdfReportService.generateLaporanMingguanPdf(
            report: report,
            kegiatan: _currentKegiatan ?? {},
            contract: widget.contract,
          ),
        ),
      ),
    );
  }

  void _openBoqMingguanPdf(WeeklyReportModel report) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          title: 'BoQ Mingguan - Minggu Ke-${report.mingguKe}',
          fileName: 'Lembar_BoQ_Mingguan_Minggu_${report.mingguKe}.pdf',
          pageFormat: PdfPageFormat.a4.landscape,
          buildPdf: () => PdfReportService.generateLembarBoqMingguanPdf(
            report: report,
            kegiatan: _currentKegiatan ?? {},
            contract: widget.contract,
          ),
        ),
      ),
    );
  }

  void _showWeeklyPdfOptions(WeeklyReportModel report) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Format Dokumen PDF Mingguan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Laporan Minggu Ke-${report.mingguKe} (${report.periodeAwal} s.d. ${report.periodeAkhir})',
                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.description_outlined, color: AppColors.primaryBlue),
                ),
                title: const Text('Ringkasan Kegiatan Mingguan (Standar PU)'),
                subtitle: const Text('Format Portrait A4 • Rencana vs Realisasi & Deviasi Fisik'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _openRingkasanMingguanPdf(report);
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.table_chart_outlined, color: Colors.green),
                ),
                title: const Text('Lembar Evaluasi Kemajuan Fisik (BoQ 8-Kolom)'),
                subtitle: const Text('Format Landscape A4 • Kumulatif Per Item Pekerjaan & Divisi'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(ctx);
                  _openBoqMingguanPdf(report);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteWeeklyReport(String reportId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Laporan Mingguan?'),
        content: const Text('Apakah Anda yakin ingin menghapus data ringkasan mingguan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              final keg = _currentKegiatan;
              if (keg != null) {
                final List<dynamic> list = List.from(keg['laporanMingguan'] ?? []);
                list.removeWhere((r) => r['id'] == reportId);
                keg['laporanMingguan'] = list;
                widget.contract.kegiatans[_currentKegiatanIndex] = keg;
                Provider.of<ContractProvider>(context, listen: false).updateContract(widget.contract);
                try {
                  final timeline = Provider.of<TimelineProvider>(context, listen: false);
                  final kName = keg['namaKegiatan']?.toString() ?? '';
                  final kontraktor = keg['kontraktor']?.toString() ?? '';
                  final dinas = widget.contract.instansiDinas.isNotEmpty
                      ? widget.contract.instansiDinas.first
                      : 'DPU-PR Kab. Purbalingga';
                  timeline.logEvent(
                    actorName: 'CV. Tata Saka Consultant',
                    actionType: 'DELETE',
                    entityType: 'LAPORAN_MINGGUAN',
                    contractId: widget.contract.id,
                    contractName: widget.contract.namaKontrak,
                    kegiatanName: kName,
                    kontraktorName: kontraktor,
                    dinasName: dinas,
                    title: 'Penghapusan Laporan Mingguan: $kName',
                    description: 'Dokumen ringkasan laporan mingguan telah dihapus dari sistem.',
                  );
                } catch (_) {}
              }
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Laporan mingguan berhasil dihapus.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }




  Widget _buildDayItem(String dayName, DateTime date) {
    final bool isSelected = _isSameDay(date, _selectedDate);
    final bool hasReport = _hasReportOnDate(date);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Column(
        children: [
          Text(
            dayName,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? AppColors.primaryBlue : AppColors.textLight,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                date.day.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Green Dot for Report marker (titik warna hijau indikator laporan)
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: hasReport ? const Color(0xFF10B981) : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: hasReport
                  ? [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem(Map<String, dynamic> report, int index, {bool isKonsultan = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header File Dokumen Laporan
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.blueLight.withOpacity(0.2),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                  ),
                  child: const Icon(Icons.description, color: AppColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Laporan Pengawasan Harian',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 10, color: AppColors.successGreen),
                                const SizedBox(width: 4),
                                Text(
                                  report['status'] ?? 'Terverifikasi',
                                  style: const TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report['tanggalFormatted'] ?? report['tanggal']} • ${report['auditor'] ?? 'CV. Tata Saka'}',
                        style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Preview
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    _buildReportChip(Icons.location_on_outlined, report['lokasiSta'] ?? '-'),
                    _buildReportChip(Icons.wb_sunny_outlined, report['cuaca'] ?? 'Cerah'),
                    if (report['customFields'] != null && (report['customFields'] as List).isNotEmpty)
                      _buildReportChip(Icons.extension_outlined, '${(report['customFields'] as List).length} Field Kustom'),
                    if (report['hasRekapitulasiAspal'] == true ||
                        report['hasRekapPerjalananDt'] == true ||
                        report['hasRekapSuhuLapangan'] == true)
                      _buildReportChip(Icons.local_shipping_outlined, 'Pengawasan Aspal & DT'),
                    if (report['hasRekapBeton'] == true || report['hasRekapitulasiBeton'] == true)
                      _buildReportChip(Icons.domain_outlined, 'Pengecoran Beton Ready Mix'),
                    _buildReportChip(Icons.photo_camera_outlined, '${report['fotoCount'] ?? 0} Foto'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Temuan Lapangan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(
                  report['temuan'] ?? '-',
                  style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                const Text('Instruksi kepada Kontraktor:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(
                  report['instruksi'] ?? '-',
                  style: const TextStyle(color: AppColors.textDark, fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDetailLaporanModal(report),
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                        label: const Text('Buka & Lihat Dokumen Laporan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    if (isKonsultan) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue, size: 20),
                        tooltip: 'Edit Laporan',
                        onPressed: () => _editReport(report),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: 'Hapus Laporan',
                        onPressed: () => _confirmDeleteReport(report['id']),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primaryBlue),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
