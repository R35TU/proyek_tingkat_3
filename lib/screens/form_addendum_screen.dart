import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class FormAddendumScreen extends StatefulWidget {
  final ContractModel contract;
  final int kegiatanIndex;
  final Map<String, dynamic>? initialAddendum;
  final int addendumSequence; // 1 untuk Addendum 01, 2 untuk Addendum 02, dst.

  const FormAddendumScreen({
    super.key,
    required this.contract,
    required this.kegiatanIndex,
    this.initialAddendum,
    this.addendumSequence = 1,
  });

  @override
  State<FormAddendumScreen> createState() => _FormAddendumScreenState();
}

class _FormAddendumScreenState extends State<FormAddendumScreen> {
  late TextEditingController _nomorAddendumCtrl;
  late TextEditingController _judulCtrl;
  late TextEditingController _nomorSpkCtrl;
  late TextEditingController _tanggalCtrl;
  late TextEditingController _keteranganCtrl;

  late List<Map<String, dynamic>> _baselineDivisiList;
  late List<Map<String, dynamic>> _workingDivisiList;

  // Controllers per item: key = '$divIndex-$itemIndex'
  final Map<String, TextEditingController> _volumeControllers = {};

  @override
  void initState() {
    super.initState();
    final keg = widget.contract.kegiatans[widget.kegiatanIndex];
    final kegiatanModel = KegiatanModel.fromJson(keg, fallbackContract: widget.contract);

    final seqStr = widget.addendumSequence.toString().padLeft(2, '0');
    final isEdit = widget.initialAddendum != null;

    _nomorAddendumCtrl = TextEditingController(
      text: widget.initialAddendum?['nomorAddendum']?.toString() ?? seqStr,
    );
    _judulCtrl = TextEditingController(
      text: widget.initialAddendum?['judul'] ?? 'Daftar Perhitungan Tambah Kurang Ke - $seqStr',
    );
    _nomorSpkCtrl = TextEditingController(
      text: widget.initialAddendum?['nomorSpkAddendum'] ?? '',
    );
    _tanggalCtrl = TextEditingController(
      text: widget.initialAddendum?['tanggalAddendum'] ?? _formatToday(),
    );
    _keteranganCtrl = TextEditingController(
      text: widget.initialAddendum?['keterangan'] ?? 'Penyesuaian volume hasil rekayasa lapangan (CCO $seqStr)',
    );

    // 1. Tentukan Baseline: Jika Addendum 1, baseline = rkkKontrakAwal (atau rkkDivisiList).
    // Jika Addendum > 1, baseline = addendum sebelumnya.
    if (widget.addendumSequence > 1 && kegiatanModel.addendums.length >= (widget.addendumSequence - 1)) {
      final prevAdd = kegiatanModel.addendums[widget.addendumSequence - 2];
      _baselineDivisiList = _cloneDivisiList(prevAdd['rkkDivisiList'] as List? ?? []);
    } else {
      _baselineDivisiList = _cloneDivisiList(
        kegiatanModel.rkkKontrakAwal.isNotEmpty
            ? kegiatanModel.rkkKontrakAwal
            : kegiatanModel.rkkDivisiList,
      );
    }

    // 2. Tentukan Working List (data yang diedit)
    if (isEdit) {
      _workingDivisiList = _cloneDivisiList(widget.initialAddendum!['rkkDivisiList'] as List? ?? []);
    } else {
      _workingDivisiList = _cloneDivisiList(_baselineDivisiList);
    }

    // 3. Inisialisasi controller volume
    for (int d = 0; d < _workingDivisiList.length; d++) {
      final items = _workingDivisiList[d]['items'] as List? ?? [];
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        final key = '$d-$i';
        _volumeControllers[key] = TextEditingController(
          text: vol > 0 ? (vol == vol.toInt() ? vol.toInt().toString() : vol.toString()) : '0',
        );
      }
    }
  }

  List<Map<String, dynamic>> _cloneDivisiList(List raw) {
    return raw.map((d) {
      final dMap = Map<String, dynamic>.from(d);
      final items = (dMap['items'] as List? ?? []).map((it) {
        return Map<String, dynamic>.from(it);
      }).toList();
      dMap['items'] = items;
      return dMap;
    }).toList();
  }

  String _formatToday() {
    final now = DateTime.now();
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }

  @override
  void dispose() {
    _nomorAddendumCtrl.dispose();
    _judulCtrl.dispose();
    _nomorSpkCtrl.dispose();
    _tanggalCtrl.dispose();
    _keteranganCtrl.dispose();
    for (final c in _volumeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // --- Real-time Calculations ---

  double get _totalBaselineHarga {
    double tot = 0.0;
    for (final div in _baselineDivisiList) {
      final items = div['items'] as List? ?? [];
      for (final it in items) {
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        tot += (it['totalHarga'] as num?)?.toDouble() ?? (hs * vol);
      }
    }
    return tot;
  }

  double get _totalWorkingHarga {
    double tot = 0.0;
    for (int d = 0; d < _workingDivisiList.length; d++) {
      final items = _workingDivisiList[d]['items'] as List? ?? [];
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final vol = double.tryParse(_volumeControllers['$d-$i']?.text ?? '0') ?? 0.0;
        tot += (hs * vol);
      }
    }
    return tot;
  }

  double get _totalPekerjaanTambahHarga {
    double tot = 0.0;
    for (int d = 0; d < _workingDivisiList.length; d++) {
      final items = _workingDivisiList[d]['items'] as List? ?? [];
      final baseItems = d < _baselineDivisiList.length ? (_baselineDivisiList[d]['items'] as List? ?? []) : [];
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final v1 = double.tryParse(_volumeControllers['$d-$i']?.text ?? '0') ?? 0.0;
        final v0 = i < baseItems.length ? ((baseItems[i]['volume'] ?? baseItems[i]['volumeCCO'] as num?)?.toDouble() ?? 0.0) : 0.0;
        if (v1 > v0) {
          tot += (v1 - v0) * hs;
        }
      }
    }
    return tot;
  }

  double get _totalPekerjaanKurangHarga {
    double tot = 0.0;
    for (int d = 0; d < _workingDivisiList.length; d++) {
      final items = _workingDivisiList[d]['items'] as List? ?? [];
      final baseItems = d < _baselineDivisiList.length ? (_baselineDivisiList[d]['items'] as List? ?? []) : [];
      for (int i = 0; i < items.length; i++) {
        final it = items[i];
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final v1 = double.tryParse(_volumeControllers['$d-$i']?.text ?? '0') ?? 0.0;
        final v0 = i < baseItems.length ? ((baseItems[i]['volume'] ?? baseItems[i]['volumeCCO'] as num?)?.toDouble() ?? 0.0) : 0.0;
        if (v1 < v0) {
          tot += (v0 - v1) * hs;
        }
      }
    }
    return tot;
  }

  void _saveAddendum() {
    final t1 = _totalWorkingHarga;
    if (t1 <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total harga addendum tidak boleh 0.')),
      );
      return;
    }

    // Update workingDivisiList dengan volume baru dan hitung ulang totalHarga & nilaiBobot
    for (int d = 0; d < _workingDivisiList.length; d++) {
      final items = _workingDivisiList[d]['items'] as List;
      for (int i = 0; i < items.length; i++) {
        final it = items[i] as Map<String, dynamic>;
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final v1 = double.tryParse(_volumeControllers['$d-$i']?.text ?? '0') ?? 0.0;
        final th1 = hs * v1;
        final b1 = t1 > 0 ? (th1 / t1) * 100.0 : 0.0;

        it['volume'] = v1;
        it['volumeCCO'] = v1;
        it['totalHarga'] = th1;
        it['nilaiBobot'] = double.parse(b1.toStringAsFixed(3));
      }
    }

    final addendumMap = <String, dynamic>{
      'id': widget.initialAddendum?['id'] ?? 'addendum-${widget.addendumSequence}-${DateTime.now().millisecondsSinceEpoch}',
      'nomorAddendum': _nomorAddendumCtrl.text.trim(),
      'judul': _judulCtrl.text.trim(),
      'nomorSpkAddendum': _nomorSpkCtrl.text.trim(),
      'tanggalAddendum': _tanggalCtrl.text.trim(),
      'keterangan': _keteranganCtrl.text.trim(),
      'parentVersion': widget.addendumSequence == 1 ? 'kontrak_awal' : 'addendum-${widget.addendumSequence - 1}',
      'rkkDivisiList': _workingDivisiList,
      'createdAt': DateTime.now().toIso8601String(),
    };

    Navigator.pop(context, addendumMap);
  }

  @override
  Widget build(BuildContext context) {
    final baseTotal = _totalBaselineHarga;
    final newTotal = _totalWorkingHarga;
    final tambahTotal = _totalPekerjaanTambahHarga;
    final kurangTotal = _totalPekerjaanKurangHarga;
    final netSelisih = tambahTotal - kurangTotal;

    final tambahBobot = baseTotal > 0 ? (tambahTotal / baseTotal) * 100.0 : 0.0;
    final kurangBobot = baseTotal > 0 ? (kurangTotal / baseTotal) * 100.0 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.initialAddendum != null
              ? 'Edit Addendum ${_nomorAddendumCtrl.text}'
              : 'Buat Addendum Baru (CCO)',
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saveAddendum,
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Simpan Addendum', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 1. KARTU INFORMASI ADDENDUM ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.description_outlined, size: 18, color: AppColors.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      'Identitas Addendum & Rekayasa Lapangan',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _nomorAddendumCtrl,
                        decoration: _inputDec('No. Addendum', hint: '01 / 02'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _tanggalCtrl,
                        decoration: _inputDec('Tanggal Addendum', hint: 'Misal: 15 Agustus 2026'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nomorSpkCtrl,
                  decoration: _inputDec('No. SPK Addendum', hint: '000.3.2/1914.1/ADD-01/.../2026'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _keteranganCtrl,
                  decoration: _inputDec('Keterangan / Alasan CCO', hint: 'Misal: Perubahan volume hasil rekayasa lapangan'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 2. LIVE SUMMARY CARD TAMBAH KURANG ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL PAGU KONTRAK ADDENDUM',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          KelolaRkkScreen.formatRupiah(newTotal),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: netSelisih.abs() < 1000
                            ? const Color(0xFF10B981).withOpacity(0.2)
                            : const Color(0xFFF59E0B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: netSelisih.abs() < 1000 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        netSelisih.abs() < 1000 ? '✓ Pagu Seimbang' : 'Selisih Pagu',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: netSelisih.abs() < 1000 ? const Color(0xFF34D399) : const Color(0xFFFBBF24),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFF334155)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Tambah
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pekerjaan Tambah', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            KelolaRkkScreen.formatRupiah(tambahTotal),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                          ),
                          Text('+${tambahBobot.toStringAsFixed(3)}%', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    // Kurang
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pekerjaan Kurang', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(
                            KelolaRkkScreen.formatRupiah(kurangTotal),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF87171)),
                          ),
                          Text('-${kurangBobot.toStringAsFixed(3)}%', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── 3. DAFTAR ITEM PEKERJAAN & INPUT TARGET VOLUME BARU ───
          ..._workingDivisiList.asMap().entries.map((divEntry) {
            final divIndex = divEntry.key;
            final div = divEntry.value;
            final items = div['items'] as List;
            final romawi = div['nomorRomawi']?.toString().toUpperCase() ?? 'I';
            final namaDiv = div['namaDivisi'] ?? 'DIVISI $romawi';

            final baseItems = divIndex < _baselineDivisiList.length
                ? (_baselineDivisiList[divIndex]['items'] as List? ?? [])
                : [];

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Divisi
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    color: const Color(0xFFF8FAFC),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            romawi,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            namaDiv,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Items
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    itemBuilder: (ctx, itemIndex) {
                      final it = items[itemIndex];
                      final noMata = it['noMataPembayaran']?.toString() ?? '';
                      final uraian = it['uraian'] ?? '-';
                      final satuan = it['satuan'] ?? '-';
                      final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;

                      final baseIt = itemIndex < baseItems.length ? baseItems[itemIndex] : null;
                      final v0 = baseIt != null ? ((baseIt['volume'] ?? baseIt['volumeCCO'] as num?)?.toDouble() ?? 0.0) : 0.0;

                      final ctrl = _volumeControllers['$divIndex-$itemIndex'];
                      final v1 = double.tryParse(ctrl?.text ?? '0') ?? 0.0;
                      final delta = v1 - v0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (noMata.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFBFDBFE), width: 0.8),
                                    ),
                                    child: Text(
                                      noMata,
                                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: Text(
                                    uraian,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Row Input Volume Baru vs Volume Semula
                            Row(
                              children: [
                                // Baseline info
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Volume Semula', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${v0 > 0 ? (v0 == v0.toInt() ? v0.toInt().toString() : v0.toString()) : '0'} $satuan',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                        ),
                                        if (hs > 0)
                                          Text(
                                            KelolaRkkScreen.formatRupiah(hs),
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),

                                // Target Volume Baru input
                                Expanded(
                                  flex: 4,
                                  child: TextFormField(
                                    controller: ctrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (val) {
                                      setState(() {});
                                    },
                                    decoration: InputDecoration(
                                      labelText: 'Volume Baru (CCO)',
                                      labelStyle: const TextStyle(fontSize: 11),
                                      suffixText: satuan,
                                      suffixStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),

                            // Real-time delta badge
                            if (delta.abs() > 0.0001)
                              Row(
                                children: [
                                  Icon(
                                    delta > 0 ? Icons.trending_up : Icons.trending_down,
                                    size: 14,
                                    color: delta > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    delta > 0
                                        ? '+ Tambah ${delta.toStringAsFixed(2)} $satuan (+${KelolaRkkScreen.formatRupiah(delta * hs)})'
                                        : '- Kurang ${delta.abs().toStringAsFixed(2)} $satuan (-${KelolaRkkScreen.formatRupiah(delta.abs() * hs)})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: delta > 0 ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                '• Volume Tetap (Tidak ada perubahan)',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  InputDecoration _inputDec(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    );
  }
}
