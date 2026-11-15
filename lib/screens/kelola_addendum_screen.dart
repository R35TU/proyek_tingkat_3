import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/screens/form_addendum_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/lembar_tambah_kurang_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:tata_saka_app/models/addendum_model.dart';
import 'package:tata_saka_app/screens/pdf_viewer_screen.dart';
import 'package:tata_saka_app/services/pdf_report_service.dart';

class KelolaAddendumScreen extends StatefulWidget {
  final ContractModel contract;
  final int kegiatanIndex;
  final bool? readOnly;

  const KelolaAddendumScreen({
    super.key,
    required this.contract,
    required this.kegiatanIndex,
    this.readOnly,
  });

  @override
  State<KelolaAddendumScreen> createState() => _KelolaAddendumScreenState();
}

class _KelolaAddendumScreenState extends State<KelolaAddendumScreen> {
  late Map<String, dynamic> _kegiatanMap;
  late KegiatanModel _kegiatan;
  bool _isModified = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _kegiatanMap = Map<String, dynamic>.from(widget.contract.kegiatans[widget.kegiatanIndex]);
    _kegiatan = KegiatanModel.fromJson(_kegiatanMap, fallbackContract: widget.contract);
  }

  void _saveToProvider() {
    _kegiatanMap['rkkKontrakAwal'] = _kegiatan.rkkKontrakAwal;
    _kegiatanMap['addendums'] = _kegiatan.addendums;
    _kegiatanMap['rkkDivisiList'] = _kegiatan.activeRkkDivisiList;

    // Sinkronkan nilai kontrak kegiatan ke nilai addendum terakhir jika ada
    if (_kegiatan.hasAddendum) {
      final latest = _kegiatan.addendums.last;
      final addDivList = latest['rkkDivisiList'] as List? ?? [];
      double tot = 0.0;
      for (final div in addDivList) {
        final items = div['items'] as List? ?? [];
        for (final it in items) {
          final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
          final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
          tot += (it['totalHarga'] as num?)?.toDouble() ?? (hs * vol);
        }
      }
      if (tot > 0) {
        _kegiatanMap['nilaiKontrak'] = KelolaRkkScreen.formatRupiah(tot);
      }
    }

    widget.contract.kegiatans[widget.kegiatanIndex] = _kegiatanMap;
    Provider.of<ContractProvider>(context, listen: false).updateContract(widget.contract);
    _isModified = true;
    setState(() {
      _loadData();
    });
  }

  void _bukaLembarTambahKurang(Map<String, dynamic> addendumData, int addendumIdx) {
    // Tentukan baseline
    List<Map<String, dynamic>> baselineList;
    if (addendumIdx == 0) {
      baselineList = _kegiatan.rkkKontrakAwal.isNotEmpty
          ? _kegiatan.rkkKontrakAwal
          : _kegiatan.rkkDivisiList;
    } else {
      baselineList = (_kegiatan.addendums[addendumIdx - 1]['rkkDivisiList'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Lembar Perhitungan Tambah Kurang (${addendumData['nomorAddendum'] ?? '01'})',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PdfViewerScreen(
                            title: 'Daftar Tambah Kurang - Addendum ${addendumData['nomorAddendum'] ?? '01'}',
                            fileName: 'Daftar_Tambah_Kurang_Addendum_${addendumData['nomorAddendum'] ?? '01'}.pdf',
                            pageFormat: PdfPageFormat.a4.landscape,
                            buildPdf: () => PdfReportService.generateLembarTambahKurangPdf(
                              addendumData: addendumData,
                              kegiatan: _kegiatan,
                              contract: widget.contract,
                              baselineDivisiList: baselineList,
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.picture_as_pdf, size: 14, color: Colors.white),
                    label: const Text('Export PDF', style: TextStyle(fontSize: 12, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: LembarTambahKurangWidget(
                  kegiatan: _kegiatan,
                  addendumData: addendumData,
                  baselineDivisiList: baselineList,
                  onDownloadPdf: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
                          title: 'Daftar Tambah Kurang - Addendum ${addendumData['nomorAddendum'] ?? '01'}',
                          fileName: 'Daftar_Tambah_Kurang_Addendum_${addendumData['nomorAddendum'] ?? '01'}.pdf',
                          pageFormat: PdfPageFormat.a4.landscape,
                          buildPdf: () => PdfReportService.generateLembarTambahKurangPdf(
                            addendumData: addendumData,
                            kegiatan: _kegiatan,
                            contract: widget.contract,
                            baselineDivisiList: baselineList,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tambahAddendumBaru() async {
    final nextSeq = _kegiatan.addendums.length + 1;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FormAddendumScreen(
          contract: widget.contract,
          kegiatanIndex: widget.kegiatanIndex,
          addendumSequence: nextSeq,
        ),
      ),
    );

    if (result != null && mounted) {
      _kegiatan.addendums.add(result);
      _saveToProvider();
      try {
        final timeline = Provider.of<TimelineProvider>(context, listen: false);
        final diffs = _extractAddendumDiff(result);
        final dinas = widget.contract.instansiDinas.isNotEmpty
            ? widget.contract.instansiDinas.first
            : 'DPU-PR Kab. Purbalingga';
        timeline.logEvent(
          actorName: 'CV. Tata Saka Consultant',
          actionType: 'UPDATE',
          entityType: 'ADDENDUM',
          contractId: widget.contract.id,
          contractName: widget.contract.namaKontrak,
          kegiatanName: _kegiatan.namaKegiatan,
          kontraktorName: _kegiatan.kontraktor,
          dinasName: dinas,
          title: 'Penerbitan Addendum ${result['nomorAddendum']} (CCO)',
          description:
              'Penyusunan Addendum ${result['nomorAddendum']} perubahan volume tambah kurang pada kegiatan ${_kegiatan.namaKegiatan}.',
          changes: diffs,
        );
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Addendum ${result['nomorAddendum']} berhasil disimpan dan disahkan.')),
      );
    }
  }

  Future<void> _editAddendum(int index) async {
    final current = _kegiatan.addendums[index];
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => FormAddendumScreen(
          contract: widget.contract,
          kegiatanIndex: widget.kegiatanIndex,
          initialAddendum: current,
          addendumSequence: index + 1,
        ),
      ),
    );

    if (result != null && mounted) {
      _kegiatan.addendums[index] = result;
      _saveToProvider();
      try {
        final timeline = Provider.of<TimelineProvider>(context, listen: false);
        final diffs = _extractAddendumDiff(result);
        final dinas = widget.contract.instansiDinas.isNotEmpty
            ? widget.contract.instansiDinas.first
            : 'DPU-PR Kab. Purbalingga';
        timeline.logEvent(
          actorName: 'CV. Tata Saka Consultant',
          actionType: 'UPDATE',
          entityType: 'ADDENDUM',
          contractId: widget.contract.id,
          contractName: widget.contract.namaKontrak,
          kegiatanName: _kegiatan.namaKegiatan,
          kontraktorName: _kegiatan.kontraktor,
          dinasName: dinas,
          title: 'Pembaruan Addendum ${result['nomorAddendum']} (CCO)',
          description:
              'Perubahan data Addendum ${result['nomorAddendum']} pada kegiatan ${_kegiatan.namaKegiatan}.',
          changes: diffs,
        );
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perubahan Addendum ${result['nomorAddendum']} disimpan.')),
      );
    }
  }

  List<Map<String, String>> _extractAddendumDiff(Map<String, dynamic> addendumMap) {
    final List<Map<String, String>> diffChanges = [];
    final newDivList = addendumMap['rkkDivisiList'] as List? ?? [];
    for (final div in newDivList) {
      final items = div['items'] as List? ?? [];
      for (final it in items) {
        final oldV = (it['volumeAwal'] as num?)?.toDouble() ??
            (it['volumeKontrak'] as num?)?.toDouble() ??
            0.0;
        final newV = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        final sat = it['satuan']?.toString() ?? '';
        final code = it['nomorMataPembayaran']?.toString() ?? '';
        final uraian = it['uraianPekerjaan']?.toString() ?? '';
        if ((newV - oldV).abs() > 0.0001) {
          final diff = newV - oldV;
          final diffStr = diff > 0
              ? '(+${diff.toStringAsFixed(2)})'
              : '(${diff.toStringAsFixed(2)})';
          diffChanges.add({
            'parameter': '$code $uraian',
            'oldValue': '${oldV.toStringAsFixed(2)} $sat',
            'newValue': '${newV.toStringAsFixed(2)} $sat $diffStr',
          });
        }
      }
    }
    return diffChanges;
  }

  void _confirmDeleteAddendum(int index) {
    final add = _kegiatan.addendums[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Hapus Addendum ${add['nomorAddendum']}?'),
        content: const Text(
          'Addendum ini akan dihapus dan versi RKK aktif akan kembali ke versi sebelumnya.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              final nomor = add['nomorAddendum'];
              _kegiatan.addendums.removeAt(index);
              _saveToProvider();
              try {
                final timeline = Provider.of<TimelineProvider>(context, listen: false);
                final dinas = widget.contract.instansiDinas.isNotEmpty
                    ? widget.contract.instansiDinas.first
                    : 'DPU-PR Kab. Purbalingga';
                timeline.logEvent(
                  actorName: 'CV. Tata Saka Consultant',
                  actionType: 'DELETE',
                  entityType: 'ADDENDUM',
                  contractId: widget.contract.id,
                  contractName: widget.contract.namaKontrak,
                  kegiatanName: _kegiatan.namaKegiatan,
                  kontraktorName: _kegiatan.kontraktor,
                  dinasName: dinas,
                  title: 'Penghapusan Addendum $nomor',
                  description:
                      'Addendum $nomor telah dihapus dan baseline dikembalikan ke versi sebelumnya.',
                );
              } catch (_) {}
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final isReadOnly = widget.readOnly ?? !(userProf?.isKonsultan ?? true);

    final activeVersionTitle = _kegiatan.hasAddendum
        ? 'Addendum ${_kegiatan.addendums.last['nomorAddendum']} (CCO Aktif)'
        : 'Kontrak Awal (RAB Original)';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context, _isModified),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Addendum & Perhitungan Tambah Kurang',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _kegiatan.namaKegiatan,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 1. STATUS VERSI AKTIF CARD ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_toggle_off, color: AppColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VERSI ACUAN FISIK SAAT INI',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        activeVersionTitle,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Digunakan sebagai acuan volume opname harian, mingguan (BoQ), & bulanan.',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── 2. RIWAYAT KONTRAK AWAL ───
          const Text(
            'KONTRAK AWAL (BASELINE)',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569), letterSpacing: 0.6),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('00', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RAB Kontrak Awal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Nilai Kontrak: ${_kegiatan.nilaiKontrak.isNotEmpty ? _kegiatan.nilaiKontrak : '-'}',
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Asli / Baseline',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 3. DAFTAR ADDENDUM / CCO ───
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DAFTAR ADDENDUM (${_kegiatan.addendums.length})',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569), letterSpacing: 0.6),
              ),
              if (!isReadOnly)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryBlue,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _tambahAddendumBaru,
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Buat Addendum Baru', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (_kegiatan.addendums.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Icon(Icons.change_circle_outlined, size: 36, color: Colors.grey.shade400),
                  const SizedBox(height: 10),
                  Text(
                    isReadOnly ? 'Belum Ada Addendum / CCO' : 'Belum Ada Addendum / CCO',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isReadOnly
                        ? 'Kegiatan ini saat ini berjalan murni sesuai acuan Kontrak Awal (RAB Original).'
                        : 'Jika terdapat perubahan volume hasil inspeksi ulang rekayasa lapangan, tambahkan Addendum 01 untuk menghitung daftar tambah kurang.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  if (!isReadOnly) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onPressed: _tambahAddendumBaru,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Buat Addendum 01 (CCO)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            )
          else
            ..._kegiatan.addendums.asMap().entries.map((entry) {
              final idx = entry.key;
              final add = entry.value;
              final noAdd = add['nomorAddendum']?.toString() ?? '01';
              final tgl = add['tanggalAddendum']?.toString() ?? '-';
              final noSpk = add['nomorSpkAddendum']?.toString() ?? '-';
              final ket = add['keterangan']?.toString() ?? '';
              final isLatest = idx == _kegiatan.addendums.length - 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isLatest ? AppColors.primaryBlue.withOpacity(0.5) : const Color(0xFFE2E8F0),
                    width: isLatest ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLatest ? AppColors.primaryBlue : const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ADD $noAdd',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                add['judul'] ?? 'Daftar Perhitungan Tambah Kurang Ke - $noAdd',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                              ),
                              Text(
                                'Disahkan: $tgl${noSpk != '-' ? ' • No. SPK: $noSpk' : ''}',
                                style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        if (isLatest)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFA7F3D0), width: 0.8),
                            ),
                            child: const Text(
                              'Versi Aktif',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                            ),
                          ),
                      ],
                    ),
                    if (ket.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Keterangan: $ket',
                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF64748B)),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 8),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              side: const BorderSide(color: AppColors.primaryBlue, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onPressed: () => _bukaLembarTambahKurang(add, idx),
                            icon: const Icon(Icons.table_chart_outlined, size: 15),
                            label: const Text('Buka Lembar Tambah Kurang', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        if (!isReadOnly) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                            tooltip: 'Edit Volume Addendum',
                            onPressed: () => _editAddendum(idx),
                          ),
                          if (isLatest)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                              tooltip: 'Hapus Addendum',
                              onPressed: () => _confirmDeleteAddendum(idx),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
