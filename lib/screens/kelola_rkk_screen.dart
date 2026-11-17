import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';
import 'package:tata_saka_app/widgets/clean_text_form_field.dart';

class KelolaRkkScreen extends StatefulWidget {
  final ContractModel contract;
  final int kegiatanIndex;
  final bool? readOnly;
  final bool isEmbedded;

  const KelolaRkkScreen({
    super.key,
    required this.contract,
    required this.kegiatanIndex,
    this.readOnly,
    this.isEmbedded = false,
  });

  /// Format angka ke Rupiah dengan penanganan desimal sen (contoh: Rp 288.350.703,03)
  static String formatRupiah(num value) {
    if (value == 0) return 'Rp 0';
    final isNegative = value < 0;
    final absVal = value.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final intPart = num.tryParse(parts[0]) ?? 0;
    final formattedInt = RupiahUtil.formatNumber(intPart);
    final decPart = parts.length > 1 ? parts[1] : '';

    String result;
    if (decPart.isNotEmpty && decPart != '00') {
      result = 'Rp $formattedInt,$decPart';
    } else {
      result = 'Rp $formattedInt';
    }
    return isNegative ? '-$result' : result;
  }

  @override
  State<KelolaRkkScreen> createState() => _KelolaRkkScreenState();
}

class _KelolaRkkScreenState extends State<KelolaRkkScreen> {
  late List<Map<String, dynamic>> _rkkDivisiList;
  late String _namaKegiatan;
  late double _nilaiKontrakKegiatan;
  bool _isModified = false;

  static const List<String> _romanNumerals = [
    'I',
    'II',
    'III',
    'IV',
    'V',
    'VI',
    'VII',
    'VIII',
    'IX',
    'X',
    'XI',
    'XII',
    'XIII',
    'XIV',
    'XV',
    'XVI',
    'XVII',
    'XVIII',
    'XIX',
    'XX',
  ];

  static String toRoman(int number) {
    if (number >= 1 && number <= _romanNumerals.length) {
      return _romanNumerals[number - 1];
    }
    return '$number';
  }

  /// Preset divisi standar PU / Bina Marga
  static const List<Map<String, String>> _standardDivisions = [
    {'nomor': '1', 'romawi': 'I', 'nama': 'DIVISI I. UMUM', 'short': 'UMUM'},
    {
      'nomor': '2',
      'romawi': 'II',
      'nama': 'DIVISI 2. DRAINASE',
      'short': 'DRAINASE',
    },
    {
      'nomor': '3',
      'romawi': 'III',
      'nama': 'DIVISI 3. PEKERJAAN TANAH & GEOSINTETIK',
      'short': 'PEKERJAAN TANAH',
    },
    {
      'nomor': '4',
      'romawi': 'IV',
      'nama': 'DIVISI 4. PEKERJAAN PREVENTIF',
      'short': 'PREVENTIF',
    },
    {
      'nomor': '5',
      'romawi': 'V',
      'nama': 'DIVISI 5. PERKERASAN BERBUTIR',
      'short': 'PERKERASAN BERBUTIR',
    },
    {
      'nomor': '6',
      'romawi': 'VI',
      'nama': 'DIVISI 6. PERKERASAN ASPAL',
      'short': 'PERKERASAN ASPAL',
    },
    {
      'nomor': '7',
      'romawi': 'VII',
      'nama': 'DIVISI 7 STRUKTUR',
      'short': 'STRUKTUR',
    },
    {
      'nomor': '8',
      'romawi': 'VIII',
      'nama': 'DIVISI 8. REHABILITASI JEMBATAN',
      'short': 'REHAB. JEMBATAN',
    },
    {
      'nomor': '9',
      'romawi': 'IX',
      'nama': 'DIVISI 9. PEKERJAAN HARIAN & LAIN-LAIN',
      'short': 'PEKERJAAN HARIAN',
    },
    {
      'nomor': '10',
      'romawi': 'X',
      'nama': 'DIVISI 10. PEMELIHARAAN KINERJA',
      'short': 'PEMELIHARAAN KINERJA',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRkkData();
  }

  void _loadRkkData() {
    final keg = widget.contract.kegiatans[widget.kegiatanIndex];
    _namaKegiatan = keg['namaKegiatan'] ?? widget.contract.namaKontrak;

    final kegNilaiStr =
        keg['nilaiKontrak']?.toString() ?? widget.contract.nilaiKontrak;
    _nilaiKontrakKegiatan = RupiahUtil.parseToDouble(kegNilaiStr);

    final rawRkk =
        (keg['rkkKontrakAwal'] != null &&
            (keg['rkkKontrakAwal'] as List).isNotEmpty)
        ? keg['rkkKontrakAwal']
        : keg['rkkDivisiList'];
    if (rawRkk != null && (rawRkk as List).isNotEmpty) {
      _rkkDivisiList = (rawRkk as List).map((entry) {
        final dMap = Map<String, dynamic>.from(entry);
        if (dMap['nomorRomawi'] == null ||
            dMap['nomorRomawi'].toString().trim().isEmpty) {
          dMap['nomorRomawi'] = 'I';
        }
        final items = (dMap['items'] as List? ?? []).map((it) {
          final itMap = Map<String, dynamic>.from(it);
          if (!itMap.containsKey('volume') && itMap.containsKey('volumeCCO')) {
            itMap['volume'] = itMap['volumeCCO'];
          }
          if (!itMap.containsKey('volumeCCO') && itMap.containsKey('volume')) {
            itMap['volumeCCO'] = itMap['volume'];
          }
          return itMap;
        }).toList();
        dMap['items'] = items;
        return dMap;
      }).toList();
    } else {
      _rkkDivisiList = [];
    }

    if (_nilaiKontrakKegiatan == 0 && _totalHargaRkk > 0) {
      _nilaiKontrakKegiatan = _totalHargaRkk;
    }
  }

  /// Format angka ke Rupiah dengan penanganan desimal sen (contoh: Rp 288.350.703,03)
  static String formatRupiah(num value) => KelolaRkkScreen.formatRupiah(value);

  /// Parse input angka desimal atau nominal rupiah secara fleksibel
  static double parseNumberInput(String text) {
    if (text.trim().isEmpty) return 0.0;
    final clean = text.trim().replaceAll('Rp', '').replaceAll(' ', '');
    if (RegExp(r'^\d+(\.\d+)?$').hasMatch(clean)) {
      return double.tryParse(clean) ?? 0.0;
    }
    return RupiahUtil.parseToDouble(clean);
  }

  double get _totalHargaRkk {
    double total = 0.0;
    for (final div in _rkkDivisiList) {
      final items = div['items'] as List? ?? [];
      for (final item in items) {
        final th = (item['totalHarga'] as num?)?.toDouble() ?? 0.0;
        if (th > 0) {
          total += th;
        } else {
          final hs = (item['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
          final vol =
              (item['volume'] ?? item['volumeCCO'] as num?)?.toDouble() ?? 0.0;
          total += (hs * vol);
        }
      }
    }
    return total;
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

  double _getDivisiSubtotalHarga(Map<String, dynamic> div) {
    double total = 0.0;
    final items = div['items'] as List? ?? [];
    for (final item in items) {
      final th = (item['totalHarga'] as num?)?.toDouble() ?? 0.0;
      if (th > 0) {
        total += th;
      } else {
        final hs = (item['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final vol =
            (item['volume'] ?? item['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        total += (hs * vol);
      }
    }
    return total;
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

  void _recalculateAllBobot({bool notify = true}) {
    final totalRkk = _totalHargaRkk;
    final divisor = totalRkk > 0
        ? totalRkk
        : (_nilaiKontrakKegiatan > 0 ? _nilaiKontrakKegiatan : 0.0);

    if (divisor > 0) {
      for (final div in _rkkDivisiList) {
        final items = div['items'] as List<Map<String, dynamic>>? ?? [];
        for (final item in items) {
          final itemTotal = (item['totalHarga'] as num?)?.toDouble() ?? 0.0;
          if (itemTotal > 0) {
            final calculatedBobot = (itemTotal / divisor) * 100.0;
            item['nilaiBobot'] = double.parse(
              calculatedBobot.toStringAsFixed(3),
            );
          } else {
            item['nilaiBobot'] = 0.0;
          }
        }
      }
    }

    if (notify) {
      setState(() {
        _isModified = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Seluruh nilai bobot berhasil dihitung ulang otomatis (Total: 100.000%).',
          ),
          backgroundColor: const Color(0xFF0F172A),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  void _syncNilaiKegiatan() {
    final totalRkk = _totalHargaRkk;
    if (totalRkk <= 0) return;

    setState(() {
      _nilaiKontrakKegiatan = totalRkk;
      _isModified = true;
    });
    _recalculateAllBobot(notify: false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nilai Kegiatan diselaraskan: ${formatRupiah(totalRkk)}'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _saveRkk() {
    final keg = widget.contract.kegiatans[widget.kegiatanIndex];

    // 1. Simpan selalu ke rkkKontrakAwal sebagai Master Baseline
    keg['rkkKontrakAwal'] = _rkkDivisiList;

    final adds = (keg['addendums'] as List?) ?? [];
    if (adds.isEmpty) {
      // Jika belum ada Addendum CCO, RKK operasional adalah Kontrak Awal
      keg['rkkDivisiList'] = _rkkDivisiList;
      final totalRkk = _totalHargaRkk;
      if (totalRkk > 0) {
        keg['nilaiKontrak'] = formatRupiah(totalRkk);
      }
    } else {
      // Jika sudah ada Addendum CCO, sinkronkan baseline baru ke seluruh Addendum tanpa menghapus Addendum
      _syncAddendumsWithNewBaseline(keg, _rkkDivisiList);
    }

    context.read<ContractProvider>().updateContract(widget.contract);
    try {
      final timeline = context.read<TimelineProvider>();
      final kName = keg['namaKegiatan']?.toString() ?? '';
      final kontraktor = keg['kontraktor']?.toString() ?? '';
      final dinas = widget.contract.instansiDinas.isNotEmpty
          ? widget.contract.instansiDinas.first
          : 'DPU-PR Kab. Purbalingga';
      timeline.logEvent(
        actorName: 'CV. Tata Saka Consultant',
        actionType: 'UPDATE',
        entityType: 'RKK',
        contractId: widget.contract.id,
        contractName: widget.contract.namaKontrak,
        kegiatanName: kName,
        kontraktorName: kontraktor,
        dinasName: dinas,
        title: 'Pembaruan Master RKK: $kName',
        description:
            'Data Master Rencana Kerja Kontrak (RKK) diperbarui ke sistem (Total ${keg['nilaiKontrak'] ?? 'disesuaikan'}).',
      );
    } catch (_) {}
    setState(() {
      _isModified = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                adds.isEmpty
                    ? 'Rincian Kuantitas Pekerjaan & Nilai Kontrak berhasil disimpan.'
                    : 'Master Kontrak Awal berhasil diperbarui & disinkronkan ke Addendum (${adds.length} CCO tetap aktif).',
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    Navigator.pop(context, true);
  }

  /// Menyelaraskan seluruh Addendum (CCO) yang telah dibuat dengan baseline Kontrak Awal yang baru diedit,
  /// tanpa menghapus Addendum atau volume perubahan lapangan yang sudah tercatat pada Addendum.
  void _syncAddendumsWithNewBaseline(
    Map<String, dynamic> keg,
    List<Map<String, dynamic>> newBaseline,
  ) {
    final rawAdds = keg['addendums'] as List?;
    if (rawAdds == null || rawAdds.isEmpty) return;

    final adds = rawAdds
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    List<Map<String, dynamic>> currentBase = newBaseline;

    for (int addIdx = 0; addIdx < adds.length; addIdx++) {
      final addMap = Map<String, dynamic>.from(adds[addIdx]);
      final oldAddRkk = (addMap['rkkDivisiList'] as List? ?? [])
          .map((d) => Map<String, dynamic>.from(d as Map))
          .toList();

      // Buat lookup item dari oldAddRkk
      final Map<String, Map<String, dynamic>> oldAddItems = {};
      for (final div in oldAddRkk) {
        final items = (div['items'] as List? ?? []);
        for (final it in items) {
          final itMap = Map<String, dynamic>.from(it as Map);
          final id = (itMap['id'] ?? '').toString().trim();
          final noMata = (itMap['noMataPembayaran'] ?? '').toString().trim();
          final uraian = (itMap['uraian'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          if (id.isNotEmpty) oldAddItems['id:$id'] = itMap;
          if (noMata.isNotEmpty) oldAddItems['no:$noMata'] = itMap;
          if (uraian.isNotEmpty) oldAddItems['u:$uraian'] = itMap;
        }
      }

      // Bangun ulang rkkDivisiList addendum berdasarkan struktur baseline baru
      final List<Map<String, dynamic>> syncedDivList = [];
      double addendumGrandTotal = 0.0;

      // Pass 1: Masukkan item-item baseline dengan mempertahankan volume penyesuaian CCO jika ada
      for (final baseDiv in currentBase) {
        final divNomor = baseDiv['nomorRomawi'] ?? 'I';
        final divNama = baseDiv['namaDivisi'] ?? '';
        final baseItems = (baseDiv['items'] as List? ?? []);

        final List<Map<String, dynamic>> syncedItems = [];
        for (final bIt in baseItems) {
          final bMap = Map<String, dynamic>.from(bIt as Map);
          final bId = (bMap['id'] ?? '').toString().trim();
          final bNo = (bMap['noMataPembayaran'] ?? '').toString().trim();
          final bUr = (bMap['uraian'] ?? '').toString().trim().toLowerCase();
          final bHarga = (bMap['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
          final bVol =
              (bMap['volume'] ?? bMap['volumeCCO'] as num?)?.toDouble() ?? 0.0;

          // Temukan apakah item ini memiliki catatan penyesuaian di addendum sebelumnya
          Map<String, dynamic>? match;
          if (bId.isNotEmpty && oldAddItems.containsKey('id:$bId')) {
            match = oldAddItems['id:$bId'];
          } else if (bNo.isNotEmpty && oldAddItems.containsKey('no:$bNo')) {
            match = oldAddItems['no:$bNo'];
          } else if (bUr.isNotEmpty && oldAddItems.containsKey('u:$bUr')) {
            match = oldAddItems['u:$bUr'];
          }

          double finalVol = bVol;
          if (match != null) {
            final oldVol =
                (match['volume'] ?? match['volumeCCO'] as num?)?.toDouble() ??
                0.0;
            // Pertahankan volume CCO yang sudah ditetapkan di addendum
            finalVol = oldVol;
          }

          final th = bHarga * finalVol;
          addendumGrandTotal += th;

          syncedItems.add(<String, dynamic>{
            ...bMap,
            'volume': finalVol,
            'volumeCCO': finalVol,
            'totalHarga': th,
            'nilaiBobot': 0.0,
          });
        }

        syncedDivList.add({
          'nomorRomawi': divNomor,
          'namaDivisi': divNama,
          'items': syncedItems,
        });
      }

      // Cek apakah ada item khusus yang hanya dibuat di addendum (pekerjaan baru CCO)
      for (final oldDiv in oldAddRkk) {
        final oldDivNomor = oldDiv['nomorRomawi'] ?? 'I';
        final oldDivNama = oldDiv['namaDivisi'] ?? '';
        final oldItems = (oldDiv['items'] as List? ?? []);

        for (final oldIt in oldItems) {
          final itMap = Map<String, dynamic>.from(oldIt as Map);
          final oId = (itMap['id'] ?? '').toString().trim();
          final oNo = (itMap['noMataPembayaran'] ?? '').toString().trim();
          final oUr = (itMap['uraian'] ?? '').toString().trim().toLowerCase();

          bool existsInBase = false;
          for (final bDiv in currentBase) {
            for (final bIt in (bDiv['items'] as List? ?? [])) {
              final bId = (bIt['id'] ?? '').toString().trim();
              final bNo = (bIt['noMataPembayaran'] ?? '').toString().trim();
              final bUr = (bIt['uraian'] ?? '').toString().trim().toLowerCase();
              if ((oId.isNotEmpty && oId == bId) ||
                  (oNo.isNotEmpty && oNo == bNo) ||
                  (oUr.isNotEmpty && oUr == bUr)) {
                existsInBase = true;
                break;
              }
            }
            if (existsInBase) break;
          }

          if (!existsInBase) {
            final targetDivIdx = syncedDivList.indexWhere(
              (d) =>
                  d['nomorRomawi'].toString().trim().toUpperCase() ==
                  oldDivNomor.toString().trim().toUpperCase(),
            );
            if (targetDivIdx == -1) {
              syncedDivList.add({
                'nomorRomawi': oldDivNomor,
                'namaDivisi': oldDivNama,
                'items': [itMap],
              });
            } else {
              (syncedDivList[targetDivIdx]['items'] as List).add(itMap);
            }
            addendumGrandTotal +=
                (itMap['totalHarga'] as num?)?.toDouble() ?? 0.0;
          }
        }
      }

      // Pass 2: Hitung ulang nilaiBobot per item berdasarkan addendumGrandTotal
      final divisor = addendumGrandTotal > 0 ? addendumGrandTotal : 1.0;
      for (final div in syncedDivList) {
        for (final it in (div['items'] as List)) {
          final th = (it['totalHarga'] as num?)?.toDouble() ?? 0.0;
          final bobot = (th / divisor) * 100.0;
          it['nilaiBobot'] = double.parse(bobot.toStringAsFixed(3));
        }
      }

      addMap['rkkDivisiList'] = syncedDivList;
      adds[addIdx] = addMap;
      currentBase = syncedDivList;
    }

    keg['addendums'] = adds;
    final latestAdd = adds.last;
    keg['rkkDivisiList'] = latestAdd['rkkDivisiList'];

    double latestTot = 0.0;
    for (final div in (latestAdd['rkkDivisiList'] as List? ?? [])) {
      for (final it in (div['items'] as List? ?? [])) {
        latestTot += (it['totalHarga'] as num?)?.toDouble() ?? 0.0;
      }
    }
    if (latestTot > 0) {
      keg['nilaiKontrak'] = formatRupiah(latestTot);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEET: TAMBAH / UBAH DIVISI (OPSI A: PRESET PU + EDIT MANUAL BEBAS)
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddEditDivisiSheet({int? index}) {
    final isEdit = index != null;
    String currentRoman = isEdit
        ? (_rkkDivisiList[index]['nomorRomawi']?.toString().toUpperCase() ??
              'I')
        : toRoman(_rkkDivisiList.length + 1);

    final existingFullName = isEdit
        ? (_rkkDivisiList[index]['namaDivisi']?.toString() ?? '')
        : '';

    final romawiCtrl = TextEditingController(text: currentRoman);
    final namaDivisiCtrl = TextEditingController(text: existingFullName);

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

                // Header & Roman Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'DIVISI ${romawiCtrl.text.trim().isEmpty ? currentRoman : romawiCtrl.text.trim().toUpperCase()}',
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
                        isEdit
                            ? 'Ubah Divisi Pekerjaan'
                            : 'Tambah Divisi Pekerjaan',
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
                const Text(
                  'Urutan divisi dapat melompat sesuai dengan jenis pekerjaan proyek Anda. Pilih preset standar PU atau edit langsung di bawah.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),

                // Pilihan Cepat Standar PU / Bina Marga (Scrollable & Responsive)
                const Text(
                  'Pilihan Cepat Standar Bina Marga (PU):',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _standardDivisions.map((preset) {
                      final pRom = preset['romawi']!;
                      final pNom = preset['nomor']!;
                      final pNam = preset['nama']!;
                      final pShort = preset['short']!;
                      final isSelected =
                          romawiCtrl.text.trim().toUpperCase() == pRom;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () {
                            setSheetState(() {
                              romawiCtrl.text = pRom;
                              namaDivisiCtrl.text = pNam;
                              currentRoman = pRom;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0F172A)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Divisi $pNom ($pRom)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  pShort,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),

                // Kolom Input Langsung (Dapat diedit bebas kapan saja)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: CleanTextFormField(
                        controller: romawiCtrl,
                        label: 'No. Romawi *',
                        hintText: 'I, II, VI, VII',
                        onChanged: (val) {
                          setSheetState(() {
                            currentRoman = val.trim().toUpperCase();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CleanTextFormField(
                        controller: namaDivisiCtrl,
                        label: 'Nama / Judul Divisi *',
                        hintText: 'Misal: DIVISI 6. PERKERASAN ASPAL',
                      ),
                    ),
                  ],
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final rawName = namaDivisiCtrl.text.trim();
                          if (rawName.isEmpty) return;

                          final rom =
                              romawiCtrl.text.trim().toUpperCase().isNotEmpty
                              ? romawiCtrl.text.trim().toUpperCase()
                              : currentRoman;

                          String formattedTitle = rawName;
                          if (!formattedTitle.toUpperCase().startsWith(
                            'DIVISI',
                          )) {
                            formattedTitle = 'DIVISI $rom. $rawName';
                          }

                          setState(() {
                            if (isEdit) {
                              _rkkDivisiList[index]['nomorRomawi'] = rom;
                              _rkkDivisiList[index]['namaDivisi'] =
                                  formattedTitle;
                            } else {
                              _rkkDivisiList.add({
                                'nomorRomawi': rom,
                                'namaDivisi': formattedTitle,
                                'items': <Map<String, dynamic>>[],
                              });
                            }
                            _isModified = true;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          isEdit
                              ? 'Simpan Perubahan'
                              : 'Tambahkan Divisi $currentRoman',
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
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BOTTOM SHEET: TAMBAH / UBAH ITEM PEKERJAAN (LAYOUT ALAMI & FORMAT ELEGAN)
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddEditItemSheet(int divIndex, {int? itemIndex}) {
    final isEdit = itemIndex != null;
    final items =
        _rkkDivisiList[divIndex]['items'] as List<Map<String, dynamic>>;
    final existing = isEdit ? items[itemIndex] : null;

    final noMataPembayaranCtrl = TextEditingController(
      text: existing?['noMataPembayaran']?.toString() ?? '',
    );
    final uraianCtrl = TextEditingController(
      text: existing?['uraian']?.toString() ?? '',
    );
    final satuanCtrl = TextEditingController(
      text: existing?['satuan']?.toString() ?? 'm3',
    );

    // Initial Volume
    final initialVol =
        (existing?['volume'] ?? existing?['volumeCCO'] as num?)?.toDouble() ??
        0.0;
    final volumeCtrl = TextEditingController(
      text: initialVol > 0
          ? (initialVol == initialVol.toInt()
                ? initialVol.toInt().toString()
                : initialVol.toString())
          : '',
    );

    // Initial Harga Satuan (format titik ribuan)
    final initialHs = (existing?['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
    final hargaSatuanCtrl = TextEditingController(
      text: initialHs > 0
          ? (initialHs == initialHs.toInt()
                ? RupiahUtil.formatNumber(initialHs)
                : formatRupiah(initialHs).replaceFirst('Rp ', ''))
          : '',
    );

    // Initial Total Harga
    final initialTotal =
        (existing?['totalHarga'] as num?)?.toDouble() ??
        (initialHs * initialVol);
    final totalHargaCtrl = TextEditingController(
      text: initialTotal > 0
          ? (initialTotal == initialTotal.toInt()
                ? initialTotal.toInt().toString()
                : initialTotal.toStringAsFixed(2))
          : '',
    );

    // Initial Bobot
    final initialBobot = (existing?['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
    final bobotCtrl = TextEditingController(
      text: initialBobot > 0 ? initialBobot.toStringAsFixed(3) : '',
    );

    bool isCustomOverride = false;
    const commonSatuan = ['m3', 'm2', 'm1', 'Ls', 'liter', 'kg', 'Ton', 'Buah'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          void recomputeFields() {
            final hs = parseNumberInput(hargaSatuanCtrl.text);
            final vol = parseNumberInput(volumeCtrl.text);
            final tot = hs * vol;

            if (!isCustomOverride) {
              if (tot > 0) {
                totalHargaCtrl.text = tot == tot.toInt()
                    ? tot.toInt().toString()
                    : tot.toStringAsFixed(2);
              } else if (vol == 0.0) {
                totalHargaCtrl.text = '0';
              }

              final refTotal = _totalHargaRkk > 0
                  ? _totalHargaRkk
                  : _nilaiKontrakKegiatan;
              if (refTotal > 0 && tot > 0) {
                final bbt = (tot / refTotal) * 100.0;
                bobotCtrl.text = bbt.toStringAsFixed(3);
              } else if (tot == 0.0) {
                bobotCtrl.text = '0.000';
              }
            }
          }

          final liveHs = parseNumberInput(hargaSatuanCtrl.text);
          final liveVol = parseNumberInput(volumeCtrl.text);
          final liveTotal = parseNumberInput(totalHargaCtrl.text);
          final effectiveTotal = liveTotal > 0 ? liveTotal : (liveHs * liveVol);
          final liveBobot =
              double.tryParse(bobotCtrl.text.replaceAll(',', '.')) ?? 0.0;

          return Padding(
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
                        child: const Icon(
                          Icons.assignment_outlined,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit
                                  ? 'Ubah Item Pekerjaan (RAB)'
                                  : 'Tambah Item Pekerjaan (RAB)',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              _rkkDivisiList[divIndex]['namaDivisi'] ?? '',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ─── BAGIAN 1: IDENTITAS MATA PEMBAYARAN ───
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '1. IDENTITAS MATA PEMBAYARAN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Nomor Mata Pembayaran
                  CleanTextFormField(
                    controller: noMataPembayaranCtrl,
                    label: 'No. Mata Pembayaran *',
                    hintText: '1.2 / 2.3.(12) / Taksir',
                  ),
                  const SizedBox(height: 12),

                  // Uraian Pekerjaan
                  CleanTextFormField(
                    controller: uraianCtrl,
                    label: 'Uraian Pekerjaan *',
                    hintText: 'Contoh: Gorong-Gorong Kotak Beton Bertulang / Lapis Resap Pengikat',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),

                  // ─── BAGIAN 2: KUANTITAS & HARGA SATUAN ───
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      '2. KUANTITAS & HARGA SATUAN',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF475569),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Volume & Satuan (Bersanding Alami)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: CleanTextFormField(
                          controller: volumeCtrl,
                          label: 'Volume Pekerjaan *',
                          hintText: 'Misal: 118.79 (0 jika taksiran)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) {
                            setSheetState(() {
                              recomputeFields();
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: CleanTextFormField(
                          controller: satuanCtrl,
                          label: 'Satuan *',
                          hintText: 'm3, m2, Ls, liter',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Satuan Quick Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: commonSatuan.map((s) {
                        final isSel = satuanCtrl.text == s;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ActionChip(
                            label: Text(
                              s,
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: isSel
                                ? AppColors.blueLight
                                : const Color(0xFFF8FAFC),
                            labelStyle: TextStyle(
                              color: isSel
                                  ? AppColors.primaryBlue
                                  : const Color(0xFF475569),
                              fontWeight: isSel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(
                              color: isSel
                                  ? AppColors.primaryBlue
                                  : const Color(0xFFE2E8F0),
                            ),
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
                  const SizedBox(height: 12),

                  // Harga Satuan (Rp)
                  CleanTextFormField(
                    controller: hargaSatuanCtrl,
                    label: 'Harga Satuan (Rp) *',
                    hintText: 'Misal: 25958 atau 2139059.32',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) {
                      setSheetState(() {
                        recomputeFields();
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // ─── BAGIAN 3: LIVE SUMMARY CARD (HASIL KALKULASI ELEGAN) ───
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.calculate_outlined,
                                  size: 16,
                                  color: Color(0xFF0F172A),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'HASIL KALKULASI OTOMATIS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: const Text(
                                'Otomatis',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TOTAL HARGA (RP)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    effectiveTotal > 0
                                        ? formatRupiah(effectiveTotal)
                                        : '-',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 38,
                              color: const Color(0xFFCBD5E1),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'NILAI BOBOT (%)',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    liveBobot > 0
                                        ? '${liveBobot.toStringAsFixed(3)}%'
                                        : (bobotCtrl.text.isNotEmpty
                                              ? '${bobotCtrl.text}%'
                                              : '-'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF059669),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 13,
                                color: Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Rumus: Volume (${liveVol > 0 ? liveVol.toString() : '0'} ${satuanCtrl.text}) × Harga Satuan = ${formatRupiah(effectiveTotal)}',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Opsi Koreksi Manual (Bila Ada Pembulatan Spesifik Dokumen)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        setSheetState(() {
                          isCustomOverride = !isCustomOverride;
                        });
                      },
                      icon: Icon(
                        isCustomOverride ? Icons.lock_open : Icons.tune,
                        size: 14,
                      ),
                      label: Text(
                        isCustomOverride
                            ? 'Tutup Penyesuaian Manual'
                            : 'Penyesuaian Manual / Pembulatan',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  if (isCustomOverride) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: CleanTextFormField(
                            controller: totalHargaCtrl,
                            label: 'Override Total (Rp)',
                            hintText: 'Misal: 10267484.74',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CleanTextFormField(
                            controller: bobotCtrl,
                            label: 'Override Bobot (%)',
                            hintText: 'Misal: 3.561',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final uraian = uraianCtrl.text.trim();
                        if (uraian.isEmpty) return;

                        final noMata = noMataPembayaranCtrl.text.trim();
                        final hs = parseNumberInput(hargaSatuanCtrl.text);
                        final vol = parseNumberInput(volumeCtrl.text);
                        var tot = parseNumberInput(totalHargaCtrl.text);
                        if (tot == 0.0 && hs > 0 && vol > 0) {
                          tot = hs * vol;
                        }

                        var bbt =
                            double.tryParse(
                              bobotCtrl.text.trim().replaceAll(',', '.'),
                            ) ??
                            0.0;
                        if (bbt == 0.0 && tot > 0) {
                          final ref = _totalHargaRkk > 0
                              ? _totalHargaRkk
                              : _nilaiKontrakKegiatan;
                          if (ref > 0) {
                            bbt = double.parse(
                              ((tot / ref) * 100.0).toStringAsFixed(3),
                            );
                          }
                        }

                        setState(() {
                          final itemData = {
                            'no':
                                '${isEdit ? (existing?['no'] ?? ((itemIndex ?? 0) + 1)) : (items.length + 1)}',
                            'noMataPembayaran': noMata,
                            'uraian': uraian,
                            'satuan': satuanCtrl.text.trim().isNotEmpty
                                ? satuanCtrl.text.trim()
                                : 'Ls',
                            'hargaSatuan': hs,
                            'volume': vol,
                            'totalHarga': tot,
                            'nilaiBobot': bbt,
                            'volumeCCO': vol,
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
                        isEdit
                            ? 'Simpan Perubahan Item'
                            : 'Tambahkan Item ke Divisi',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showDivisiActionSheet(int divIndex) {
    final div = _rkkDivisiList[divIndex];
    final romawi =
        div['nomorRomawi']?.toString().toUpperCase() ?? toRoman(divIndex + 1);
    final namaDiv = div['namaDivisi'] ?? 'DIVISI $romawi';
    final itemsCount = (div['items'] as List? ?? []).length;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
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
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$itemsCount Item Pekerjaan',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Ubah Nama / Nomor Divisi',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Sesuaikan nomor romawi atau nama divisi',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddEditDivisiSheet(index: divIndex);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Hapus Divisi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Color(0xFFEF4444),
                  ),
                ),
                subtitle: const Text(
                  'Hapus divisi beserta seluruh item pekerjaan di dalamnya',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteDivisi(divIndex);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemActionSheet(int divIndex, int itemIndex) {
    final item = _rkkDivisiList[divIndex]['items'][itemIndex];
    final noMata = item['noMataPembayaran']?.toString() ?? '';
    final uraian = item['uraian'] ?? 'Item Pekerjaan';
    final vol =
        (item['volume'] ?? item['volumeCCO'] as num?)?.toDouble() ?? 0.0;
    final satuan = item['satuan'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    if (noMata.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          noMata,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        uraian,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (vol > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                    'Volume: $vol $satuan',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Ubah Item Pekerjaan',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                subtitle: const Text(
                  'Edit volume, harga satuan, atau uraian pekerjaan',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddEditItemSheet(divIndex, itemIndex: itemIndex);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Hapus Item Pekerjaan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: Color(0xFFEF4444),
                  ),
                ),
                subtitle: const Text(
                  'Hapus item ini dari rincian kuantitas',
                  style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteItem(divIndex, itemIndex);
                },
              ),
            ],
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _rkkDivisiList.removeAt(index);
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
      final items =
          _rkkDivisiList[divIndex]['items'] as List<Map<String, dynamic>>;
      items.removeAt(itemIndex);
      for (int i = 0; i < items.length; i++) {
        items[i]['no'] = '${i + 1}';
      }
      _isModified = true;
    });
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
    final totalBobotVal = _totalBobot;
    final is100Percent = (totalBobotVal - 100.0).abs() < 0.05;
    final totalRkkHarga = _totalHargaRkk;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () {
            if (_isModified && !isReadOnly) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Text('Perubahan Belum Disimpan'),
                  content: const Text(
                    'Anda memiliki perubahan yang belum disimpan. Simpan sebelum kembali?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Tinggalkan',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveRkk();
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(color: Colors.white),
                      ),
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
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
          if (!isReadOnly)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
      body: Builder(
        builder: (context) {
          final keg = widget.contract.kegiatans[widget.kegiatanIndex];
          final adds = (keg['addendums'] as List?) ?? [];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── BANNER INFORMASI JIKA SUDAH ADA ADDENDUM CCO ───
              if (adds.isNotEmpty) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF93C5FD)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF1D4ED8),
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mode Master Kontrak Awal (RAB Baseline)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Kegiatan ini memiliki ${adds.length} Addendum (CCO) yang telah diterbitkan. Anda tetap dapat mengedit Kontrak Awal di sini kapan saja (misal perbaikan typo atau kuantitas awal). Seluruh Addendum CCO akan tetap aman dan otomatis diselaraskan dengan baseline baru ini tanpa menghapus Addendum.',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF1E40AF),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ─── 1. EXECUTIVE PROGRESS CARD (TOTAL HARGA & BOBOT SESUAI KEGIATAN) ───
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
                    // Top: Total Nilai Kontrak vs Total RAB
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TOTAL HARGA PEKERJAAN (RAB)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalRkkHarga > 0
                                    ? formatRupiah(totalRkkHarga)
                                    : 'Rp 0',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (_nilaiKontrakKegiatan > 0 &&
                                  (_nilaiKontrakKegiatan - totalRkkHarga)
                                          .abs() >
                                      1.0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Target Kegiatan: ${formatRupiah(_nilaiKontrakKegiatan)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFFB45309),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '$_totalItems Item',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 12),

                    // Middle: Total Bobot & Status Sesuai 100%
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              'Total Bobot: ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Text(
                              totalBobotVal.toStringAsFixed(3),
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: is100Percent
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Text(
                              '%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: is100Percent
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: is100Percent
                                  ? const Color(0xFFA7F3D0)
                                  : const Color(0xFFFDE68A),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                is100Percent
                                    ? Icons.check_circle
                                    : Icons.info_outline,
                                size: 12,
                                color: is100Percent
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFB45309),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                is100Percent ? 'Sesuai 100%' : 'Belum 100%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: is100Percent
                                      ? const Color(0xFF059669)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (totalBobotVal / 100.0).clamp(0.0, 1.0),
                        minHeight: 7,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          is100Percent
                              ? const Color(0xFF10B981)
                              : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Helper Quick Buttons
                    if (!isReadOnly)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => _recalculateAllBobot(notify: true),
                            icon: const Icon(
                              Icons.calculate_outlined,
                              size: 14,
                            ),
                            label: const Text(
                              'Hitung Ulang Bobot Otomatis',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (totalRkkHarga > 0 &&
                              (_nilaiKontrakKegiatan - totalRkkHarga).abs() >
                                  1.0)
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF059669),
                                side: const BorderSide(
                                  color: Color(0xFFA7F3D0),
                                ),
                                backgroundColor: const Color(0xFFECFDF5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _syncNilaiKegiatan,
                              icon: const Icon(Icons.sync, size: 14),
                              label: const Text(
                                'Samakan Nilai Kegiatan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── 2. EMPTY STATE ───
              if (_rkkDivisiList.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36,
                    horizontal: 24,
                  ),
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
                        child: const Icon(
                          Icons.account_tree_outlined,
                          size: 30,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isReadOnly
                            ? 'Belum Ada Rincian Kuantitas (RKK)'
                            : 'Mulai Susun Rincian Kuantitas (RKK)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isReadOnly
                            ? 'Rincian kuantitas pekerjaan (BoQ) belum diinput oleh konsultan pengawas.'
                            : 'Tambahkan divisi pekerjaan sesuai BoQ kontrak. Urutan divisi dapat melompat sesuai dengan jenis pekerjaan proyek Anda.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      if (!isReadOnly) ...[
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F172A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 13,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _showAddEditDivisiSheet(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Tambah Divisi Pertama',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

              // ─── 3. DAFTAR DIVISI & ITEM PEKERJAAN (KARTU ELEGAN) ───
              if (_rkkDivisiList.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 4, right: 4),
                  child: Row(
                    children: [
                      Icon(
                        isReadOnly
                            ? Icons.visibility_outlined
                            : Icons.touch_app_outlined,
                        size: 14,
                        color: const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isReadOnly
                              ? 'Mode Lihat Saja (Read-Only) • Rincian kuantitas & bobot pekerjaan resmi.'
                              : 'Ketuk untuk edit, tekan & tahan (hold) divisi atau item untuk opsi hapus.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              ..._rkkDivisiList.asMap().entries.map((divEntry) {
                final divIndex = divEntry.key;
                final div = divEntry.value;
                final items = div['items'] as List<Map<String, dynamic>>? ?? [];
                final romawi =
                    div['nomorRomawi']?.toString().toUpperCase() ??
                    toRoman(divIndex + 1);
                final namaDiv = div['namaDivisi'] ?? 'DIVISI $romawi';
                final subtotalHarga = _getDivisiSubtotalHarga(div);
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
                      // Divisi Header (Tap / Hold untuk opsi divisi)
                      InkWell(
                        onTap: isReadOnly
                            ? null
                            : () => _showDivisiActionSheet(divIndex),
                        onLongPress: isReadOnly
                            ? null
                            : () => _showDivisiActionSheet(divIndex),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          color: const Color(0xFFF8FAFC),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
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
                                      '${items.length} Item • Subtotal: ${formatRupiah(subtotalHarga)} • Bobot: ${subtotalBobot.toStringAsFixed(3)}%',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isReadOnly) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.more_vert,
                                  size: 18,
                                  color: Color(0xFF94A3B8),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),

                      // Items List
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          child: Center(
                            child: Text(
                              'Belum ada item pekerjaan di divisi ini.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (ctx, i) => const Divider(
                            height: 1,
                            color: Color(0xFFF1F5F9),
                          ),
                          itemBuilder: (ctx, itemIndex) {
                            final item = items[itemIndex];
                            final noMata =
                                item['noMataPembayaran']?.toString() ?? '';
                            final uraian = item['uraian'] ?? '-';
                            final satuan = item['satuan'] ?? '-';
                            final vol =
                                (item['volume'] ?? item['volumeCCO'] as num?)
                                    ?.toDouble() ??
                                0.0;
                            final hs =
                                (item['hargaSatuan'] as num?)?.toDouble() ??
                                0.0;
                            final tot =
                                (item['totalHarga'] as num?)?.toDouble() ??
                                (hs * vol);
                            final bbt =
                                (item['nilaiBobot'] as num?)?.toDouble() ?? 0.0;

                            return InkWell(
                              onTap: isReadOnly
                                  ? null
                                  : () => _showAddEditItemSheet(
                                      divIndex,
                                      itemIndex: itemIndex,
                                    ),
                              onLongPress: isReadOnly
                                  ? null
                                  : () => _showItemActionSheet(
                                      divIndex,
                                      itemIndex,
                                    ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
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

                                    // Content (7 Kolom Data)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (noMata.isNotEmpty) ...[
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFEFF6FF,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFBFDBFE,
                                                      ),
                                                      width: 0.8,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    noMata,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF1D4ED8),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Text(
                                                  uraian,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: Color(0xFF0F172A),
                                                    height: 1.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              _buildMetricTag('Satuan', satuan),
                                              _buildMetricTag(
                                                'Volume',
                                                vol > 0
                                                    ? (vol == vol.toInt()
                                                          ? vol
                                                                .toInt()
                                                                .toString()
                                                          : vol.toString())
                                                    : '-',
                                              ),
                                              if (hs > 0)
                                                _buildMetricTag(
                                                  'Harga Satuan',
                                                  formatRupiah(hs),
                                                ),
                                              if (tot > 0)
                                                _buildMetricTag(
                                                  'Total',
                                                  formatRupiah(tot),
                                                ),
                                              _buildMetricTag(
                                                'Bobot',
                                                bbt > 0
                                                    ? '${bbt.toStringAsFixed(3)}%'
                                                    : '-',
                                                highlight: true,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Button Tambah Item ke Divisi
                      if (!isReadOnly)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF8FAFC),
                            border: Border(
                              top: BorderSide(color: Color(0xFFF1F5F9)),
                            ),
                          ),
                          child: TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primaryBlue,
                              alignment: Alignment.centerLeft,
                            ),
                            onPressed: () => _showAddEditItemSheet(divIndex),
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 16,
                            ),
                            label: const Text(
                              'Tambah Item Pekerjaan',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),

              // ─── 4. TOMBOL TAMBAH DIVISI BARU ───
              if (_rkkDivisiList.isNotEmpty && !isReadOnly)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(
                      color: Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showAddEditDivisiSheet(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Tambah Divisi Pekerjaan',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 36),
            ],
          );
        },
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
          color: highlight
              ? AppColors.navySlate.withOpacity(0.25)
              : const Color(0xFFE2E8F0),
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
