import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/clean_text_form_field.dart';

class KelolaRkkScreen extends StatefulWidget {
  final ContractModel contract;
  final int kegiatanIndex;

  const KelolaRkkScreen({
    super.key,
    required this.contract,
    required this.kegiatanIndex,
  });

  @override
  State<KelolaRkkScreen> createState() => _KelolaRkkScreenState();
}

class _KelolaRkkScreenState extends State<KelolaRkkScreen> {
  late List<Map<String, dynamic>> _rkkDivisiList;
  late String _namaKegiatan;
  bool _isModified = false;

  static const List<String> _romanNumerals = [
    'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
    'XI', 'XII', 'XIII', 'XIV', 'XV', 'XVI', 'XVII', 'XVIII', 'XIX', 'XX'
  ];

  static String toRoman(int number) {
    if (number >= 1 && number <= _romanNumerals.length) {
      return _romanNumerals[number - 1];
    }
    return '$number';
  }

  @override
  void initState() {
    super.initState();
    _loadRkkData();
  }

  void _loadRkkData() {
    final keg = widget.contract.kegiatans[widget.kegiatanIndex];
    _namaKegiatan = keg['namaKegiatan'] ?? widget.contract.namaKontrak;

    final rawRkk = keg['rkkDivisiList'];
    if (rawRkk != null && (rawRkk as List).isNotEmpty) {
      _rkkDivisiList = (rawRkk as List).asMap().entries.map((entry) {
        final dMap = Map<String, dynamic>.from(entry.value);
        // Automatic Roman numeral based on position
        dMap['nomorRomawi'] = toRoman(entry.key + 1);
        final items = (dMap['items'] as List? ?? []).map((it) => Map<String, dynamic>.from(it)).toList();
        dMap['items'] = items;
        return dMap;
      }).toList();
    } else {
      _rkkDivisiList = [];
    }
  }

  void _recalcRomanNumerals() {
    for (int i = 0; i < _rkkDivisiList.length; i++) {
      _rkkDivisiList[i]['nomorRomawi'] = toRoman(i + 1);
    }
  }

  double get _totalBobot {
    double total = 0.0;
    for (final div in _rkkDivisiList) {
      final items = div['items'] as List? ?? [];
      for (final item in items) {
        final b = (item['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
        total += b;
      }
    }
    return total;
  }

  int get _totalItems {
    int count = 0;
    for (final div in _rkkDivisiList) {
      count += (div['items'] as List? ?? []).length;
    }
    return count;
  }

  double _getDivisiSubtotalBobot(Map<String, dynamic> div) {
    double total = 0.0;
    final items = div['items'] as List? ?? [];
    for (final item in items) {
      final b = (item['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
      total += b;
    }
    return total;
  }

  void _saveRkk() {
    _recalcRomanNumerals();
    final keg = widget.contract.kegiatans[widget.kegiatanIndex];
    keg['rkkDivisiList'] = _rkkDivisiList;

    context.read<ContractProvider>().updateContract(widget.contract);
    setState(() {
      _isModified = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text('Rincian Kuantitas Pekerjaan berhasil disimpan.'),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context, true);
  }

  void _showAddEditDivisiSheet({int? index}) {
    final isEdit = index != null;
    final roman = isEdit ? toRoman(index + 1) : toRoman(_rkkDivisiList.length + 1);
    final existingName = isEdit ? (_rkkDivisiList[index]['namaDivisi']?.toString() ?? '') : '';

    // Strip out repeated prefix if user typed "DIVISI X" before
    String initialClean = existingName;
    if (initialClean.toUpperCase().startsWith('DIVISI')) {
      final regex = RegExp(r'^DIVISI\s+[0-9IVXLCDM.]+\s*', caseSensitive: false);
      initialClean = initialClean.replaceFirst(regex, '').trim();
      if (initialClean.isEmpty) initialClean = existingName;
    }

    final namaDivisiCtrl = TextEditingController(text: initialClean);

    const commonDivisions = [
      'UMUM',
      'DRAINASE',
      'PEKERJAAN TANAH & GEOSINTETIK',
      'PEKERJAAN PREVENTIF',
      'PERKERASAN BERBUTIR',
      'PERKERASAN ASPAL',
      'STRUKTUR',
      'REHABILITASI JEMBATAN',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Title and Auto-Roman Badge
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DIVISI $roman',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Ubah Nama Divisi' : 'Tambah Divisi Pekerjaan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Nomor romawi dihitung otomatis ($roman). Cukup masukkan nama bagian divisi pekerjaan.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
              ),
              const SizedBox(height: 18),

              // Input Nama Divisi
              CleanTextFormField(
                controller: namaDivisiCtrl,
                label: 'Nama Divisi Pekerjaan',
                hintText: 'Misal: UMUM / DRAINASE / PERKERASAN ASPAL',
              ),
              const SizedBox(height: 14),

              // Quick Suggestion Chips
              const Text(
                'Saran Kategori Standar PU:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: commonDivisions.map((suggestion) {
                  return InkWell(
                    onTap: () {
                      setSheetState(() {
                        namaDivisiCtrl.text = suggestion;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        suggestion,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final raw = namaDivisiCtrl.text.trim();
                        if (raw.isEmpty) return;

                        // Ensure clean formatted title e.g. "DIVISI 1 UMUM" or "DIVISI 2. DRAINASE" or "DIVISI I: UMUM"
                        String formattedTitle = raw;
                        if (!formattedTitle.toUpperCase().startsWith('DIVISI')) {
                          formattedTitle = 'DIVISI $roman. $raw';
                        }

                        setState(() {
                          if (isEdit) {
                            _rkkDivisiList[index]['nomorRomawi'] = roman;
                            _rkkDivisiList[index]['namaDivisi'] = formattedTitle;
                          } else {
                            _rkkDivisiList.add({
                              'nomorRomawi': roman,
                              'namaDivisi': formattedTitle,
                              'items': <Map<String, dynamic>>[],
                            });
                          }
                          _recalcRomanNumerals();
                          _isModified = true;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        isEdit ? 'Simpan Perubahan' : 'Tambahkan Divisi $roman',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditItemSheet(int divIndex, {int? itemIndex}) {
    final isEdit = itemIndex != null;
    final items = _rkkDivisiList[divIndex]['items'] as List<Map<String, dynamic>>;
    final existing = isEdit ? items[itemIndex] : null;

    final uraianCtrl = TextEditingController(text: existing?['uraian']?.toString() ?? '');
    final satuanCtrl = TextEditingController(text: existing?['satuan']?.toString() ?? 'm3');
    final volumeCtrl = TextEditingController(
      text: existing != null ? (existing['volumeCCO']?.toString() ?? '') : '',
    );
    final bobotCtrl = TextEditingController(
      text: existing != null ? (existing['nilaiBobot']?.toString() ?? '') : '',
    );

    const commonSatuan = ['m3', 'm2', 'm1', 'Ls', 'liter', 'kg', 'Ton', 'Buah'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grabber
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Ubah Item Pekerjaan' : 'Tambah Item Pekerjaan',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            _rkkDivisiList[divIndex]['namaDivisi'] ?? '',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Uraian Pekerjaan
                CleanTextFormField(
                  controller: uraianCtrl,
                  label: 'Uraian Pekerjaan *',
                  hintText: 'Contoh: Pekerjaan Galian Tanah / Pasangan Batu',
                ),
                const SizedBox(height: 14),

                // Satuan + Quick Chips
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CleanTextFormField(
                      controller: satuanCtrl,
                      label: 'Satuan Pekerjaan *',
                      hintText: 'm3, m2, m1, Ls, liter, kg',
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: commonSatuan.map((s) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ActionChip(
                              label: Text(s, style: const TextStyle(fontSize: 11)),
                              backgroundColor: satuanCtrl.text == s ? AppColors.blueLight : const Color(0xFFF1F5F9),
                              labelStyle: TextStyle(
                                color: satuanCtrl.text == s ? AppColors.primaryBlue : const Color(0xFF334155),
                                fontWeight: satuanCtrl.text == s ? FontWeight.bold : FontWeight.normal,
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onPressed: () {
                                setSheetState(() {
                                  satuanCtrl.text = s;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Volume CCO & Nilai Bobot in 2-Columns
                Row(
                  children: [
                    Expanded(
                      child: CleanTextFormField(
                        controller: volumeCtrl,
                        label: 'Volume CCO *',
                        hintText: 'Misal: 115.00',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CleanTextFormField(
                        controller: bobotCtrl,
                        label: 'Nilai Bobot (%) *',
                        hintText: 'Misal: 26.362',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      final uraian = uraianCtrl.text.trim();
                      if (uraian.isEmpty) return;

                      final vol = double.tryParse(volumeCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;
                      final bbt = double.tryParse(bobotCtrl.text.trim().replaceAll(',', '.')) ?? 0.0;

                      setState(() {
                        final itemData = {
                          'no': '${isEdit ? (existing?['no'] ?? (itemIndex! + 1)) : (items.length + 1)}',
                          'uraian': uraian,
                          'satuan': satuanCtrl.text.trim().isNotEmpty ? satuanCtrl.text.trim() : 'Ls',
                          'volumeCCO': vol,
                          'nilaiBobot': bbt,
                        };

                        if (isEdit) {
                          items[itemIndex] = itemData;
                        } else {
                          items.add(itemData);
                        }
                        _isModified = true;
                      });

                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(
                      isEdit ? 'Simpan Perubahan Item' : 'Tambahkan Item ke Divisi',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteDivisi(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Divisi?'),
        content: Text(
          'Seluruh item pekerjaan di dalam "${_rkkDivisiList[index]['namaDivisi']}" akan ikut terhapus.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _rkkDivisiList.removeAt(index);
                _recalcRomanNumerals();
                _isModified = true;
              });
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteItem(int divIndex, int itemIndex) {
    setState(() {
      final items = _rkkDivisiList[divIndex]['items'] as List<Map<String, dynamic>>;
      items.removeAt(itemIndex);
      for (int i = 0; i < items.length; i++) {
        items[i]['no'] = '${i + 1}';
      }
      _isModified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalBobotVal = _totalBobot;
    final is100Percent = (totalBobotVal - 100.0).abs() < 0.05;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 18),
          onPressed: () {
            if (_isModified) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Perubahan Belum Disimpan'),
                  content: const Text('Anda memiliki perubahan yang belum disimpan. Simpan sebelum kembali?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Tinggalkan', style: TextStyle(color: Colors.red)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveRkk();
                      },
                      child: const Text('Simpan', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rincian Kuantitas Kontrak',
              style: TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _namaKegiatan,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _saveRkk,
              icon: const Icon(Icons.save_outlined, size: 16),
              label: const Text(
                'Simpan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── 1. EXECUTIVE PROGRESS CARD (ELEGAN & MODERN) ───
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOTAL BOBOT PEKERJAAN (BoQ)',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              totalBobotVal.toStringAsFixed(3),
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: is100Percent ? const Color(0xFF10B981) : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: is100Percent ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: is100Percent ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    is100Percent ? Icons.check_circle : Icons.info_outline,
                                    size: 12,
                                    color: is100Percent ? const Color(0xFF059669) : const Color(0xFFB45309),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    is100Percent ? 'Sesuai 100%' : 'Belum 100%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: is100Percent ? const Color(0xFF059669) : const Color(0xFFB45309),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_rkkDivisiList.length} Divisi',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            '$_totalItems Item',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (totalBobotVal / 100.0).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      is100Percent ? const Color(0xFF10B981) : AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ─── 2. EMPTY STATE (ELEGAN TANPA TEMPLATE) ───
          if (_rkkDivisiList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.account_tree_outlined, size: 30, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mulai Susun Rincian Kuantitas (RKK)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tambahkan divisi pekerjaan sesuai BoQ kontrak. Nomor romawi divisi akan terisi otomatis secara berurutan.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => _showAddEditDivisiSheet(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Tambah Divisi Pertama',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

          // ─── 3. DAFTAR DIVISI & ITEM PEKERJAAN (KARTU ELEGAN) ───
          ..._rkkDivisiList.asMap().entries.map((divEntry) {
            final divIndex = divEntry.key;
            final div = divEntry.value;
            final items = div['items'] as List<Map<String, dynamic>>? ?? [];
            final romawi = toRoman(divIndex + 1);
            final namaDiv = div['namaDivisi'] ?? 'DIVISI $romawi';
            final subtotalBobot = _getDivisiSubtotalBobot(div);

            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Divisi Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: const Color(0xFFF8FAFC),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            romawi,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                namaDiv,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${items.length} Item • Subtotal Bobot: ${subtotalBobot.toStringAsFixed(3)}%',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF64748B)),
                          tooltip: 'Ubah Nama Divisi',
                          splashRadius: 18,
                          onPressed: () => _showAddEditDivisiSheet(index: divIndex),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          tooltip: 'Hapus Divisi',
                          splashRadius: 18,
                          onPressed: () => _confirmDeleteDivisi(divIndex),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),

                  // Items List
                  if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                      child: Center(
                        child: Text(
                          'Belum ada item pekerjaan di divisi ini.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, itemIndex) {
                        final item = items[itemIndex];
                        final uraian = item['uraian'] ?? '-';
                        final satuan = item['satuan'] ?? '-';
                        final vol = (item['volumeCCO'] as num?)?.toDouble() ?? 0.0;
                        final bbt = (item['nilaiBobot'] as num?)?.toDouble() ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Number
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${itemIndex + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10.5,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      uraian,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Color(0xFF0F172A),
                                        height: 1.3,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 4,
                                      children: [
                                        _buildMetricTag('Satuan', satuan),
                                        _buildMetricTag('Vol CCO', vol > 0 ? vol.toStringAsFixed(2) : '-'),
                                        _buildMetricTag(
                                          'Bobot',
                                          bbt > 0 ? '${bbt.toStringAsFixed(3)}%' : '-',
                                          highlight: true,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Row Actions
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                                tooltip: 'Ubah Item',
                                splashRadius: 16,
                                onPressed: () => _showAddEditItemSheet(divIndex, itemIndex: itemIndex),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 16, color: Color(0xFF94A3B8)),
                                tooltip: 'Hapus Item',
                                splashRadius: 16,
                                onPressed: () => _confirmDeleteItem(divIndex, itemIndex),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  // Button Tambah Item ke Divisi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () => _showAddEditItemSheet(divIndex),
                      icon: const Icon(Icons.add_circle_outline, size: 16),
                      label: const Text(
                        'Tambah Item Pekerjaan',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // ─── 4. TOMBOL TAMBAH DIVISI BARU ───
          if (_rkkDivisiList.isNotEmpty)
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showAddEditDivisiSheet(),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Tambah Divisi ${toRoman(_rkkDivisiList.length + 1)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildMetricTag(String label, String value, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlight ? AppColors.slateLighter : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: highlight ? AppColors.navySlate.withOpacity(0.25) : const Color(0xFFE2E8F0),
          width: 0.6,
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
          color: highlight ? AppColors.navySlate : const Color(0xFF475569),
        ),
      ),
    );
  }
}
