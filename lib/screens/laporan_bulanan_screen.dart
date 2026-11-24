import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/lembar_laporan_bulanan_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:tata_saka_app/screens/pdf_viewer_screen.dart';
import 'package:tata_saka_app/services/pdf_report_service.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/signature_pad_widget.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

class _TtdBulananDraftItem {
  final TextEditingController peranController;
  final TextEditingController instansiController;
  final TextEditingController namaController;
  final TextEditingController tanggalController;
  String? signatureBase64;

  _TtdBulananDraftItem({
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

class LaporanBulananScreen extends StatefulWidget {
  final ContractModel? initialContract;
  final int initialKegiatanIndex;
  final bool isEmbedded;

  const LaporanBulananScreen({
    super.key,
    this.initialContract,
    this.initialKegiatanIndex = 0,
    this.isEmbedded = false,
  });

  @override
  State<LaporanBulananScreen> createState() => _LaporanBulananScreenState();
}

class _LaporanBulananScreenState extends State<LaporanBulananScreen> {
  ContractModel? _selectedContract;
  int _selectedKegiatanIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedContract = widget.initialContract;
    _selectedKegiatanIndex = widget.initialKegiatanIndex;
  }

  void _showPilihKegiatanSheet(BuildContext context, List<ContractModel> contracts) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Pilih Kegiatan / Proyek',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Pilih kegiatan untuk melihat rekapitulasi Laporan Bulanan',
                    style: TextStyle(color: AppColors.textLight, fontSize: 13),
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    itemCount: contracts.length,
                    itemBuilder: (context, cIdx) {
                      final contract = contracts[cIdx];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: Text(
                              contract.namaKontrak,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          ...List.generate(contract.kegiatans.length, (kIdx) {
                            final kegMap = contract.kegiatans[kIdx];
                            final kegModel = KegiatanModel.fromJson(kegMap, fallbackContract: contract);
                            final isSelected = (_selectedContract?.id == contract.id &&
                                _selectedKegiatanIndex == kIdx);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.blueLight,
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: 18,
                                  color: isSelected ? Colors.white : AppColors.primaryBlue,
                                ),
                              ),
                              title: Text(
                                kegModel.namaKegiatan.isNotEmpty
                                    ? kegModel.namaKegiatan
                                    : 'Kegiatan ${kIdx + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? AppColors.primaryBlue : AppColors.textDark,
                                ),
                              ),
                              subtitle: Text(
                                'Nilai: ${kegModel.nilaiKontrak.isNotEmpty ? kegModel.nilaiKontrak : contract.nilaiKontrak} • ${kegModel.laporans.length} Laporan Harian',
                                style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle, color: AppColors.primaryBlue)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedContract = contract;
                                  _selectedKegiatanIndex = kIdx;
                                });
                                Navigator.pop(ctx);
                              },
                            );
                          }),
                          const Divider(height: 16),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openLembarLaporanBulanan(BuildContext context, MonthlyReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.94,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Modal Header with Close Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Lembar Laporan Bulanan (Bulan ${report.bulanRomawi})',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _openTandaTanganBulananModal(context, report);
                      },
                      icon: const Icon(Icons.draw_outlined, size: 14, color: AppColors.primaryBlue),
                      label: const Text('Tanda Tangan', style: TextStyle(fontSize: 12, color: AppColors.primaryBlue)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryBlue),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PdfViewerScreen(
                              title: 'Laporan Bulanan - Bulan ${report.bulanRomawi}',
                              fileName: 'Laporan_Bulanan_Bulan_${report.bulanRomawi}.pdf',
                              pageFormat: PdfPageFormat.a4.landscape,
                              buildPdf: () => PdfReportService.generateLaporanBulananPdf(
                                report: report,
                                contract: _selectedContract!,
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
                      icon: const Icon(Icons.close, color: AppColors.textDark),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Lembar Dokumen
              Expanded(
                child: LembarLaporanBulananWidget(
                  report: report,
                  onDownloadPdf: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PdfViewerScreen(
                          title: 'Laporan Bulanan - Bulan ${report.bulanRomawi}',
                          fileName: 'Laporan_Bulanan_Bulan_${report.bulanRomawi}.pdf',
                          pageFormat: PdfPageFormat.a4.landscape,
                          buildPdf: () => PdfReportService.generateLaporanBulananPdf(
                            report: report,
                            contract: _selectedContract!,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openTandaTanganBulananModal(BuildContext context, MonthlyReportModel report) {
    if (_selectedContract == null ||
        _selectedContract!.kegiatans.isEmpty ||
        _selectedKegiatanIndex < 0 ||
        _selectedKegiatanIndex >= _selectedContract!.kegiatans.length) {
      return;
    }
    final kegMap = _selectedContract!.kegiatans[_selectedKegiatanIndex];

    final existingKey = 'laporanBulanan_${report.bulanKe}';
    final existingData = kegMap[existingKey] as Map<String, dynamic>?;

    final List<_TtdBulananDraftItem> items = [];
    final rawList = existingData != null && existingData['ttdList'] is List
        ? (existingData['ttdList'] as List)
        : (report.ttdList ?? []);

    if (rawList.isNotEmpty) {
      for (final it in rawList) {
        if (it is Map) {
          items.add(
            _TtdBulananDraftItem(
              peran: it['peran']?.toString() ?? it['jabatan']?.toString() ?? '',
              instansi: it['instansi']?.toString() ?? '',
              nama: it['nama']?.toString() ?? '',
              tanggal: it['tanggal']?.toString() ?? '',
              signatureBase64: it['signature']?.toString(),
            ),
          );
        }
      }
    }

    if (items.isEmpty) {
      final dateStr = report.periodeFormatted.split('-').last.trim();
      items.add(
        _TtdBulananDraftItem(
          peran: 'Kontraktor Pelaksana',
          instansi: report.pelaksanaKontraktor,
          nama: report.ttdKontraktorNama ?? '',
          tanggal: report.ttdKontraktorTanggal ?? dateStr,
          signatureBase64: report.ttdKontraktorSignature,
        ),
      );
      items.add(
        _TtdBulananDraftItem(
          peran: 'Konsultan Supervisi',
          instansi: 'CV. TATA SAKA CONSULTANT',
          nama: report.ttdKonsultanNama ?? '',
          tanggal: report.ttdKonsultanTanggal ?? dateStr,
          signatureBase64: report.ttdKonsultanSignature,
        ),
      );
      items.add(
        _TtdBulananDraftItem(
          peran: 'Pejabat Pembuat Komitmen (PPK)',
          instansi: 'DPU-PR Kab. Purbalingga',
          nama: report.ttdPpkNama ?? '',
          tanggal: report.ttdPpkTanggal ?? dateStr,
          signatureBase64: report.ttdPpkSignature,
        ),
      );
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setModalState) {
            void addRow() {
              setModalState(() {
                items.add(
                  _TtdBulananDraftItem(
                    peran: 'Pengawas Lapangan',
                    instansi: '',
                    nama: '',
                    tanggal: report.periodeFormatted.split('-').last.trim(),
                  ),
                );
              });
            }

            void removeRow(int idx) {
              if (items.length > 1) {
                setModalState(() {
                  items[idx].dispose();
                  items.removeAt(idx);
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

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanda Tangan Digital - Bulan ${report.bulanRomawi}',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Kelola penandatangan dokumen dan bubuhkan tanda tangan canvas untuk lembar Laporan Bulanan',
                              style: TextStyle(fontSize: 12, color: AppColors.textLight),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // List of signers
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (ctx, idx) {
                        final it = items[idx];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                                  Row(
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
                                      Text(
                                        it.peranController.text.isNotEmpty
                                            ? it.peranController.text
                                            : 'Penandatangan ${idx + 1}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (items.length > 1)
                                    IconButton(
                                      tooltip: 'Hapus Penandatangan',
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => removeRow(idx),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: it.peranController,
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
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: it.instansiController,
                                      decoration: InputDecoration(
                                        labelText: 'Instansi / Perusahaan',
                                        hintText: 'Misal: CV. DIVAN INSAN CEMERLANG',
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                        ),
                                      ),
                                      onChanged: (_) => setModalState(() {}),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SignaturePadWidget(
                                nameController: it.namaController,
                                roleController: it.instansiController,
                                dateController: it.tanggalController,
                                initialSignatureBase64: it.signatureBase64,
                                nameLabel: 'Nama Lengkap Penandatangan',
                                roleLabel: 'Instansi / Perusahaan',
                                dateLabel: 'Tanggal Tanda Tangan',
                                onSignatureChanged: (base64) {
                                  it.signatureBase64 = base64;
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: addRow,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tambah'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final cleanList = items.map((e) => e.toMap()).toList();
                            final Map<String, dynamic> dataToSave = Map<String, dynamic>.from(existingData ?? {});
                            dataToSave['bulanKe'] = report.bulanKe;
                            dataToSave['ttdList'] = cleanList;

                            final ttdK = items.isNotEmpty ? items[0] : null;
                            final ttdS = items.length > 1 ? items[1] : null;
                            final ttdP = items.length > 2 ? items[2] : null;

                            dataToSave['ttdKontraktorNama'] = ttdK?.namaController.text.trim();
                            dataToSave['ttdKontraktorJabatan'] = ttdK?.peranController.text.trim();
                            dataToSave['ttdKontraktorSignature'] = ttdK?.signatureBase64;
                            dataToSave['ttdKontraktorTanggal'] = ttdK?.tanggalController.text.trim();

                            dataToSave['ttdKonsultanNama'] = ttdS?.namaController.text.trim();
                            dataToSave['ttdKonsultanJabatan'] = ttdS?.peranController.text.trim();
                            dataToSave['ttdKonsultanSignature'] = ttdS?.signatureBase64;
                            dataToSave['ttdKonsultanTanggal'] = ttdS?.tanggalController.text.trim();

                            dataToSave['ttdPpkNama'] = ttdP?.namaController.text.trim();
                            dataToSave['ttdPpkJabatan'] = ttdP?.peranController.text.trim();
                            dataToSave['ttdPpkSignature'] = ttdP?.signatureBase64;
                            dataToSave['ttdPpkTanggal'] = ttdP?.tanggalController.text.trim();

                            kegMap[existingKey] = dataToSave;

                            // Update in list as well
                            final rawBulananList = List<dynamic>.from(kegMap['laporanBulanan'] ?? []);
                            final bIdx = rawBulananList.indexWhere(
                              (b) => b is Map && (b['bulanKe'] == report.bulanKe || b['bulanKe']?.toString() == '${report.bulanKe}'),
                            );
                            if (bIdx >= 0) {
                              rawBulananList[bIdx] = dataToSave;
                            } else {
                              rawBulananList.add(dataToSave);
                            }
                            kegMap['laporanBulanan'] = rawBulananList;

                            _selectedContract!.kegiatans[_selectedKegiatanIndex] = kegMap;
                            Provider.of<ContractProvider>(context, listen: false).updateContract(_selectedContract!);

                            Navigator.pop(modalCtx);
                            setState(() {});

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Tanda tangan Laporan Bulanan ${report.bulanRomawi} berhasil disimpan!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          icon: const Icon(Icons.check, size: 18, color: Colors.white),
                          label: const Text('Simpan Tanda Tangan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractProvider = Provider.of<ContractProvider>(context);
    final userProf = Provider.of<UserProfileProvider>(context, listen: false);
    List<ContractModel> contracts = contractProvider.contracts;
    if (userProf.isDinas) {
      contracts = contracts.where((c) {
        return c.isOwnedByDinas(
          dinasUserUid: userProf.uid,
          companyOrAgency: userProf.companyOrAgency,
          userFullName: userProf.namaLengkap,
        );
      }).toList();
    }
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (contracts.isEmpty) {
      const emptyBody = Center(
        child: Text('Belum ada kontrak kegiatan yang terdaftar.'),
      );
      if (widget.isEmbedded) return emptyBody;
      if (isDesktop) {
        return const WebDashboardLayout(
          title: 'Laporan Bulanan',
          activeMenu: 'laporan',
          showBackButton: true,
          child: emptyBody,
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Laporan Bulanan'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
        ),
        body: emptyBody,
      );
    }

    // Utamakan kontrak yang memiliki kegiatan
    if (_selectedContract == null ||
        !contracts.any((c) => c.id == _selectedContract!.id) ||
        _selectedContract!.kegiatans.isEmpty) {
      _selectedContract = contracts.firstWhere(
        (c) => c.kegiatans.isNotEmpty,
        orElse: () => contracts.first,
      );
      _selectedKegiatanIndex = 0;
    }

    if (_selectedContract!.kegiatans.isEmpty) {
      final emptyKegiatanBody = Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Kegiatan pada Kontrak "${_selectedContract!.namaKontrak}"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tambahkan kegiatan terlebih dahulu pada menu Kontrak agar laporan bulanan dapat dibuat.',
                style: TextStyle(fontSize: 13, color: AppColors.textLight),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
      if (widget.isEmbedded) return emptyKegiatanBody;
      if (isDesktop) {
        return WebDashboardLayout(
          title: 'Laporan Bulanan',
          activeMenu: 'laporan_bulanan',
          showBackButton: true,
          child: emptyKegiatanBody,
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Laporan Bulanan'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
        ),
        body: emptyKegiatanBody,
      );
    }

    if (_selectedKegiatanIndex < 0 || _selectedKegiatanIndex >= _selectedContract!.kegiatans.length) {
      _selectedKegiatanIndex = 0;
    }

    final kegMap = _selectedContract!.kegiatans[_selectedKegiatanIndex];
    final kegModel = KegiatanModel.fromJson(kegMap, fallbackContract: _selectedContract!);

    // Generate daftar Laporan Bulanan otomatis (tiap blok 4 minggu)
    final monthlyReports = MonthlyReportModel.generateFromWeeklyReports(
      contract: _selectedContract!,
      kegiatan: kegModel,
    );

    final headerActions = [
      IconButton(
        tooltip: 'Ganti Kegiatan',
        icon: Icon(Icons.swap_horiz, color: (isDesktop && !widget.isEmbedded) ? Colors.white : AppColors.primaryBlue),
        onPressed: () => _showPilihKegiatanSheet(context, contracts),
      ),
    ];

    final mainBody = SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Project Selector Card
            _buildKegiatanSelectorCard(kegModel, contracts),
            const SizedBox(height: 16),

            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekapitulasi Periode 4 Mingguan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${monthlyReports.length} Periode Bulan Tersedia',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blueLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Otomatis Kumulatif',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // List of Month Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: monthlyReports.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = monthlyReports[index];
                return _buildMonthCard(report);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      );

    if (widget.isEmbedded) {
      return mainBody;
    }

    if (isDesktop) {
      return WebDashboardLayout(
        title: 'Laporan Bulanan',
        activeMenu: 'laporan',
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
        title: const Text(
          'Laporan Bulanan',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
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
        actions: headerActions,
      ),
      body: mainBody,
    );
  }

  Widget _buildKegiatanSelectorCard(KegiatanModel kegModel, List<ContractModel> contracts) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.blueLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.business_center_outlined,
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
                      _selectedContract!.namaKontrak,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kegModel.namaKegiatan.isNotEmpty
                          ? kegModel.namaKegiatan
                          : 'Pemeliharaan Berkala',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _showPilihKegiatanSheet(context, contracts),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Ganti',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pelaksana Kontraktor', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    const SizedBox(height: 2),
                    Text(
                      kegModel.kontraktor.isNotEmpty ? kegModel.kontraktor : 'CV. DIVAN INSAN CEMERLANG',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nilai Kontrak', style: TextStyle(fontSize: 11, color: AppColors.textLight)),
                    const SizedBox(height: 2),
                    Text(
                      kegModel.nilaiKontrak.isNotEmpty ? kegModel.nilaiKontrak : _selectedContract!.nilaiKontrak,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(MonthlyReportModel report) {
    Color statusBgColor;
    Color statusTextColor;
    Color statusBorderColor;
    IconData statusIcon;

    if (report.status == 'Selesai') {
      statusBgColor = const Color(0xFFE6F4EA);
      statusTextColor = const Color(0xFF137333);
      statusBorderColor = const Color(0xFF34A853);
      statusIcon = Icons.check_circle_outline;
    } else if (report.status == 'Sedang Berjalan') {
      statusBgColor = const Color(0xFFFEF3C7);
      statusTextColor = const Color(0xFFB45309);
      statusBorderColor = const Color(0xFFF59E0B);
      statusIcon = Icons.timelapse;
    } else {
      statusBgColor = Colors.grey[100]!;
      statusTextColor = Colors.grey[700]!;
      statusBorderColor = Colors.grey[300]!;
      statusIcon = Icons.hourglass_empty;
    }

    final hasData = report.status != 'Belum Ada Data';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasData ? Colors.grey[200]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            _openLembarLaporanBulanan(context, report);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Roman Badge & Title + Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: hasData ? AppColors.blueLight : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                report.bulanRomawi,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: hasData ? AppColors.primaryBlue : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BULAN ${report.bulanRomawi}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  report.namaBulan,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF475569),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusBorderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 13, color: statusTextColor),
                          const SizedBox(width: 4),
                          Text(
                            report.status,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Periode Tanggal
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 13, color: Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        report.periodeFormatted,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                const SizedBox(height: 12),

                // Metrics (Rencana, Realisasi, Deviasi)
                if (hasData) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricItem(
                          'Rencana',
                          '${report.rencanaFisikPersen.toStringAsFixed(2)}%',
                          const Color(0xFF334155),
                        ),
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Realisasi',
                          '${report.realisasiKumulatifPersen.toStringAsFixed(2)}%',
                          AppColors.primaryBlue,
                          bold: true,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricItem(
                          'Deviasi',
                          '${report.deviasiPersen >= 0 ? '+' : ''}${report.deviasiPersen.toStringAsFixed(2)}%',
                          report.deviasiPersen >= 0
                              ? const Color(0xFF137333)
                              : const Color(0xFFC5221F),
                          bold: true,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Role Dinas: tidak dapat menandatangani laporan.
                      if (Provider.of<UserProfileProvider>(context, listen: false).isDinas)
                        const SizedBox.shrink()
                      else
                      OutlinedButton.icon(
                        onPressed: () => _openTandaTanganBulananModal(context, report),
                        icon: const Icon(Icons.draw_outlined, size: 13, color: AppColors.primaryBlue),
                        label: const Text('Tanda Tangan', style: TextStyle(fontSize: 11, color: AppColors.primaryBlue)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Buka',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Expanded(
                        child: Text(
                          'Belum ada laporan mingguan (Tap untuk buka)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Menunggu Periode',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF475569),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color, {bool bold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
