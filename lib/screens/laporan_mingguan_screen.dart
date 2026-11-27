import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_mingguan_screen.dart';
import 'package:tata_saka_app/screens/pdf_viewer_screen.dart';
import 'package:tata_saka_app/services/pdf_report_service.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/utils/execution_period_helper.dart';
import 'package:tata_saka_app/widgets/lembar_boq_mingguan_widget.dart';
import 'package:tata_saka_app/widgets/lembar_laporan_mingguan_widget.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

class LaporanMingguanScreen extends StatefulWidget {
  final ContractModel? initialContract;
  final int initialKegiatanIndex;
  final bool isEmbedded;
  final DateTime? referenceDate;

  const LaporanMingguanScreen({
    super.key,
    this.initialContract,
    this.initialKegiatanIndex = 0,
    this.isEmbedded = false,
    this.referenceDate,
  });

  @override
  State<LaporanMingguanScreen> createState() => _LaporanMingguanScreenState();
}

class _LaporanMingguanScreenState extends State<LaporanMingguanScreen>
    with WidgetsBindingObserver {
  ContractModel? _selectedContract;
  int _selectedKegiatanIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedContract = widget.initialContract;
    _selectedKegiatanIndex = widget.initialKegiatanIndex;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  void _showPilihKegiatanSheet(
    BuildContext context,
    List<ContractModel> contracts,
  ) {
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
                    'Pilih kegiatan untuk melihat daftar periode Laporan Mingguan',
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 6,
                            ),
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
                            final kegModel = KegiatanModel.fromJson(
                              kegMap,
                              fallbackContract: contract,
                            );
                            final period =
                                ExecutionPeriodHelper.resolveExecutionPeriod(
                              kegMap,
                              contract: contract,
                            );
                            final isSelected =
                                (_selectedContract?.id == contract.id &&
                                    _selectedKegiatanIndex == kIdx);

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 2,
                              ),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor: isSelected
                                    ? AppColors.primaryBlue
                                    : AppColors.blueLight,
                                child: Icon(
                                  Icons.assignment_outlined,
                                  size: 18,
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.primaryBlue,
                                ),
                              ),
                              title: Text(
                                kegModel.namaKegiatan.isNotEmpty
                                    ? kegModel.namaKegiatan
                                    : 'Kegiatan ${kIdx + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : AppColors.textDark,
                                ),
                              ),
                              subtitle: Text(
                                '${period.startFormatted.isNotEmpty ? "${period.startFormatted} - ${period.endFormatted}" : "Jadwal belum diset"} • ${kegModel.laporans.length} Lap. Harian',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryBlue,
                                    )
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

  /// Menyusun objek WeeklyReportModel sinkron untuk kebutuhan pratinjau / PDF
  /// dari data periode mingguan terpilih.
  WeeklyReportModel _buildEffectiveReport(
    WeeklyPeriodSummary item,
    ContractModel contract,
    Map<String, dynamic> kegMap,
    List<WeeklyPeriodSummary> allWeeks,
  ) {
    final kegModel = KegiatanModel.fromJson(kegMap, fallbackContract: contract);
    final saved = item.savedReport;

    final tabelRows = allWeeks.map((w) {
      final wRange = ExecutionPeriodHelper.calcWeekRange(
        w.mingguKe,
        w.startDate != null ? allWeeks.first.startDate : null,
        allWeeks.fold<int>(0, (sum, e) => sum + e.daysCount),
      );
      String docStatus = 'Kontrak';
      if (w.savedReport != null) {
        final match = w.savedReport!.tabelMingguan.where((tr) => tr.mingguKe == w.mingguKe);
        if (match.isNotEmpty) {
          docStatus = match.first.status == 'Adendum' ? 'Adendum' : 'Kontrak';
        }
      }
      final hasSaved = w.hasSavedReport;
      final hasReal = w.realisasiSdMingguIniPersen > 0;
      return WeeklyTableRow(
        status: docStatus,
        mingguKe: w.mingguKe,
        tglMulai: wRange.tglMulaiSlash,
        tglSelesai: wRange.tglSelesaiSlash,
        rencana: hasSaved ? w.rencanaPersen : null,
        realisasi: (hasSaved || hasReal) ? w.realisasiSdMingguIniPersen : null,
      );
    }).toList();

    final kegNilai = kegModel.nilaiKontrak.trim();
    final nilaiDisplay =
        kegNilai.isNotEmpty ? kegNilai : contract.nilaiKontrak;
    final noKontrak = kegModel.noSuratPesanan.isNotEmpty
        ? kegModel.noSuratPesanan
        : (contract.nomorSpk.isNotEmpty ? contract.nomorSpk : contract.nomorSpmk);
    final tglKontrak = kegModel.tglSuratPesanan.isNotEmpty
        ? kegModel.tglSuratPesanan
        : contract.tglMulaiSpk;

    return WeeklyReportModel(
      id: saved?.id ?? 'weekly-preview-m${item.mingguKe}',
      pekerjaan: kegModel.namaKegiatan.isNotEmpty
          ? kegModel.namaKegiatan
          : contract.namaKontrak,
      lokasiProyek: kegModel.lokasi,
      kontraktor: kegModel.kontraktor,
      jangkaWaktu: allWeeks.fold<int>(0, (sum, e) => sum + e.daysCount),
      nomorKontrak: noKontrak,
      tanggalKontrak: tglKontrak,
      nilaiKontrak: nilaiDisplay,
      nilaiKontrakNumeric: item.nilaiKontrakNumeric,
      tanggalSpmk: allWeeks.first.periodeAwal,
      mingguKe: item.mingguKe,
      totalMinggu: item.totalMinggu,
      periodeAwal: item.periodeAwal,
      periodeAkhir: item.periodeAkhir,
      rencanaPersen: item.rencanaPersen,
      rencanaNominal: item.rencanaNominal,
      realisasiPersen: item.realisasiSdMingguIniPersen,
      realisasiNominal: item.realisasiNominal,
      deviasiPersen: item.deviasiPersen,
      deviasiNominal: item.deviasiNominal,
      waktuTerpakai: item.waktuTerpakai,
      sisaWaktu: item.sisaWaktu,
      akhirMasaKontrak: item.akhirMasaKontrak,
      tabelMingguan: tabelRows,
      boqProgressList: item.boqResult.divisiList,
      ttdList: saved?.ttdList,
      ttdKontraktorNama: saved?.ttdKontraktorNama,
      ttdKontraktorJabatan: saved?.ttdKontraktorJabatan,
      ttdKontraktorSignature: saved?.ttdKontraktorSignature,
      ttdKontraktorTanggal: saved?.ttdKontraktorTanggal,
      ttdKonsultanNama: saved?.ttdKonsultanNama,
      ttdKonsultanJabatan: saved?.ttdKonsultanJabatan,
      ttdKonsultanSignature: saved?.ttdKonsultanSignature,
      ttdKonsultanTanggal: saved?.ttdKonsultanTanggal,
      ttdPpkNama: saved?.ttdPpkNama,
      ttdPpkJabatan: saved?.ttdPpkJabatan,
      ttdPpkSignature: saved?.ttdPpkSignature,
      ttdPpkTanggal: saved?.ttdPpkTanggal,
    );
  }

  Future<void> _openFormForWeek(
    WeeklyPeriodSummary item,
    ContractModel contract,
    Map<String, dynamic> kegMap,
    List<WeeklyPeriodSummary> allWeeks,
  ) async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BuatLaporanMingguanScreen(
          initialContract: contract,
          initialKegiatanIndex: _selectedKegiatanIndex,
          initialMingguKe: item.mingguKe,
          editReport: item.savedReport,
        ),
      ),
    );
    if (res == true && mounted) {
      setState(() {});
    }
  }

  void _openDetailModal(
    WeeklyPeriodSummary item,
    ContractModel contract,
    Map<String, dynamic> kegMap,
    List<WeeklyPeriodSummary> allWeeks,
  ) {
    final effectiveReport =
        _buildEffectiveReport(item, contract, kegMap, allWeeks);
    final isKonsultan = () {
      try {
        return Provider.of<UserProfileProvider>(context, listen: false)
            .isKonsultan;
      } catch (_) {
        return true;
      }
    }();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.94,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              // Modal Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.date_range_outlined,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Laporan Mingguan (Minggu ${item.mingguKe})',
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
                    if (isKonsultan) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openFormForWeek(item, contract, kegMap, allWeeks);
                        },
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 14,
                          color: AppColors.primaryBlue,
                        ),
                        label: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primaryBlue),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showExportPdfOptions(effectiveReport, contract, kegMap),
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        size: 14,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'PDF',
                        style: TextStyle(fontSize: 12, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
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

              const TabBar(
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: AppColors.textLight,
                indicatorColor: AppColors.primaryBlue,
                indicatorWeight: 2.5,
                tabs: [
                  Tab(text: '1. Ringkasan Mingguan'),
                  Tab(text: '2. Progress BoQ (14 Kolom)'),
                ],
              ),

              Expanded(
                child: TabBarView(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: LembarLaporanMingguanWidget(
                          report: effectiveReport,
                          onDownloadPdf: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  title:
                                      'Ringkasan Mingguan - Minggu ${item.mingguKe}',
                                  fileName:
                                      'Ringkasan_Mingguan_Minggu_${item.mingguKe}.pdf',
                                  buildPdf: () =>
                                      PdfReportService.generateLaporanMingguanPdf(
                                    report: effectiveReport,
                                    kegiatan: kegMap,
                                    contract: contract,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: LembarBoqMingguanWidget(
                          report: effectiveReport,
                          kegiatan: kegMap,
                          onDownloadPdf: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PdfViewerScreen(
                                  title: 'BoQ Mingguan - Minggu ${item.mingguKe}',
                                  fileName:
                                      'Lembar_BoQ_Mingguan_Minggu_${item.mingguKe}.pdf',
                                  pageFormat: PdfPageFormat.a4.landscape,
                                  buildPdf: () =>
                                      PdfReportService.generateLembarBoqMingguanPdf(
                                    report: effectiveReport,
                                    kegiatan: kegMap,
                                    contract: contract,
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
            ],
          ),
        ),
      ),
    );
  }

  void _showExportPdfOptions(
    WeeklyReportModel report,
    ContractModel contract,
    Map<String, dynamic> kegMap,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Format Dokumen PDF Mingguan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.blueLight,
                  child: Icon(Icons.summarize_outlined, color: AppColors.primaryBlue),
                ),
                title: const Text(
                  'Ringkasan Kegiatan Mingguan (Standar PU)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Berisi bobot rencana, realisasi, deviasi, dan jadwal 13 minggu',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        title: 'Ringkasan Mingguan - Minggu ${report.mingguKe}',
                        fileName:
                            'Ringkasan_Mingguan_Minggu_${report.mingguKe}.pdf',
                        buildPdf: () =>
                            PdfReportService.generateLaporanMingguanPdf(
                          report: report,
                          kegiatan: kegMap,
                          contract: contract,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const Divider(height: 8),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE6F4EA),
                  child: Icon(Icons.table_chart_outlined, color: Color(0xFF137333)),
                ),
                title: const Text(
                  'Lembar Progress BoQ 14 Kolom (Landscape)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Rincian volume & bobot minggu lalu, minggu ini, s/d minggu ini, dan sisa',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        title: 'BoQ Mingguan - Minggu ${report.mingguKe}',
                        fileName:
                            'Lembar_BoQ_Mingguan_Minggu_${report.mingguKe}.pdf',
                        pageFormat: PdfPageFormat.a4.landscape,
                        buildPdf: () =>
                            PdfReportService.generateLembarBoqMingguanPdf(
                          report: report,
                          kegiatan: kegMap,
                          contract: contract,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contractProvider = Provider.of<ContractProvider>(context);
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context, listen: false);
    } catch (_) {
      userProf = null;
    }

    List<ContractModel> contracts = contractProvider.contracts;
    if (userProf != null && userProf.isDinas) {
      contracts = contracts.where((c) {
        return c.isOwnedByDinas(
          dinasUserUid: userProf!.uid,
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
          title: 'Laporan Mingguan',
          activeMenu: 'laporan_mingguan',
          showBackButton: true,
          child: emptyBody,
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => goBackOrParent(context, '/laporan'),
          ),
          title: const Text('Laporan Mingguan'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
        ),
        body: emptyBody,
      );
    }

    // Selalu sinkronkan dengan instansi kontrak terbaru dari ContractProvider
    if (_selectedContract != null) {
      _selectedContract = contracts.firstWhere(
        (c) => c.id == _selectedContract!.id,
        orElse: () => contracts.first,
      );
    } else {
      _selectedContract = contracts.first;
    }
    if (_selectedKegiatanIndex >= _selectedContract!.kegiatans.length) {
      _selectedKegiatanIndex = 0;
    }

    if (_selectedContract!.kegiatans.isEmpty) {
      const noKegBody = Center(
        child: Text('Kontrak terpilih belum memiliki kegiatan.'),
      );
      if (widget.isEmbedded) return noKegBody;
      if (isDesktop) {
        return const WebDashboardLayout(
          title: 'Laporan Mingguan',
          activeMenu: 'laporan_mingguan',
          showBackButton: true,
          child: noKegBody,
        );
      }
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () => goBackOrParent(context, '/laporan'),
          ),
          title: const Text('Laporan Mingguan'),
          backgroundColor: Colors.white,
          foregroundColor: AppColors.textDark,
          elevation: 0,
        ),
        body: noKegBody,
      );
    }

    final kegMap = _selectedContract!.kegiatans[_selectedKegiatanIndex];
    final kegModel =
        KegiatanModel.fromJson(kegMap, fallbackContract: _selectedContract!);
    final period = ExecutionPeriodHelper.resolveExecutionPeriod(
      kegMap,
      contract: _selectedContract!,
    );
    final weeklyPeriods = ExecutionPeriodHelper.generateWeeklyPeriods(
      contract: _selectedContract!,
      kegMap: kegMap,
      referenceDate: widget.referenceDate,
    );

    final headerActions = [
      IconButton(
        tooltip: 'Ganti Kegiatan',
        icon: Icon(
          Icons.swap_horiz,
          color: (isDesktop && !widget.isEmbedded)
              ? Colors.white
              : AppColors.primaryBlue,
        ),
        onPressed: () => _showPilihKegiatanSheet(context, contracts),
      ),
    ];

    final mainBody = CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Project Selector & Schedule Info Card
                _buildKegiatanSelectorCard(kegModel, period, contracts),
                const SizedBox(height: 16),

                // Section Header
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Daftar Periode Mingguan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${weeklyPeriods.length} Minggu Pelaksanaan (${period.durationDays} Hari Kalender)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blueLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Otomatis Realisasi Harian',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // List of Week Cards (lazy/virtualized)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          sliver: SliverList.separated(
            itemCount: weeklyPeriods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = weeklyPeriods[index];
              return _buildWeekCard(
                item,
                _selectedContract!,
                kegMap,
                weeklyPeriods,
              );
            },
          ),
        ),
      ],
    );

    if (widget.isEmbedded) {
      return mainBody;
    }

    if (isDesktop) {
      return WebDashboardLayout(
        title: 'Laporan Mingguan',
        activeMenu: 'laporan_mingguan',
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
          'Laporan Mingguan',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => goBackOrParent(context, '/laporan'),
        ),
        actions: headerActions,
      ),
      body: mainBody,
    );
  }

  Widget _buildKegiatanSelectorCard(
    KegiatanModel kegModel,
    ExecutionPeriod period,
    List<ContractModel> contracts,
  ) {
    final periodStr = period.startFormatted.isNotEmpty
        ? '${period.startFormatted} s/d ${period.endFormatted}'
        : 'Jadwal pelaksanaan belum ditetapkan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                          : 'Kegiatan',
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                    const Text(
                      'Pelaksana Kontraktor',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kegModel.kontraktor.isNotEmpty ? kegModel.kontraktor : '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
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
                    const Text(
                      'Nilai Kontrak',
                      style: TextStyle(fontSize: 11, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      kegModel.nilaiKontrak.isNotEmpty
                          ? kegModel.nilaiKontrak
                          : _selectedContract!.nilaiKontrak,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.date_range_outlined,
                  size: 14,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Periode Pelaksanaan: $periodStr (${period.durationDays} hari)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekCard(
    WeeklyPeriodSummary item,
    ContractModel contract,
    Map<String, dynamic> kegMap,
    List<WeeklyPeriodSummary> allWeeks,
  ) {
    final Color statusBgColor;
    final Color statusTextColor;
    final Color statusBorderColor;
    final IconData statusIcon;

    switch (item.status) {
      case WeeklyPeriodStatus.completed:
        statusBgColor = const Color(0xFFE6F4EA);
        statusTextColor = const Color(0xFF137333);
        statusBorderColor = const Color(0xFF34A853);
        statusIcon = Icons.check_circle_outline;
        break;
      case WeeklyPeriodStatus.onProgress:
        statusBgColor = const Color(0xFFFEF3C7);
        statusTextColor = const Color(0xFFB45309);
        statusBorderColor = const Color(0xFFF59E0B);
        statusIcon = Icons.timelapse;
        break;
      case WeeklyPeriodStatus.upcoming:
        statusBgColor = const Color(0xFFF1F5F9);
        statusTextColor = const Color(0xFF475569);
        statusBorderColor = const Color(0xFFCBD5E1);
        statusIcon = Icons.schedule;
        break;
    }

    final isHighlighted = item.status != WeeklyPeriodStatus.upcoming;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.status == WeeklyPeriodStatus.onProgress
              ? const Color(0xFFFDE68A)
              : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
            if (item.hasSavedReport) {
              _openDetailModal(item, contract, kegMap, allWeeks);
            } else {
              _openFormForWeek(item, contract, kegMap, allWeeks);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Week Badge & Title + Status Chip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isHighlighted
                                  ? AppColors.blueLight
                                  : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                'M${item.mingguKe}',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: isHighlighted
                                      ? AppColors.primaryBlue
                                      : const Color(0xFF475569),
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
                                  'Minggu ${item.mingguKe}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.statusDetail,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
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
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
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
                            item.statusLabel,
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
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.periodeAwal.isNotEmpty
                            ? '${item.periodeAwal} - ${item.periodeAkhir} (${item.daysCount} hari)'
                            : item.periodeFormatted,
                        style: const TextStyle(
                          fontSize: 12.5,
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

                // Metrics Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Rencana',
                        item.hasSavedReport
                            ? '${item.rencanaPersen.toStringAsFixed(2)}%'
                            : '-',
                        const Color(0xFF334155),
                      ),
                    ),
                    Expanded(
                      child: _buildMetricItem(
                        'Realisasi',
                        '${item.realisasiSdMingguIniPersen.toStringAsFixed(2)}%',
                        AppColors.primaryBlue,
                        bold: true,
                        subText: item.realisasiMingguIniPersen > 0
                            ? '+${item.realisasiMingguIniPersen.toStringAsFixed(2)}% mgg ini'
                            : null,
                      ),
                    ),
                    if (item.hasSavedReport ||
                        item.realisasiSdMingguIniPersen > 0)
                      Expanded(
                        child: _buildMetricItem(
                          'Deviasi',
                          '${item.deviasiPersen >= 0 ? '+' : ''}${item.deviasiPersen.toStringAsFixed(2)}%',
                          item.deviasiPersen >= 0
                              ? const Color(0xFF137333)
                              : const Color(0xFFC5221F),
                          bold: true,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: item.hasSavedReport
                      ? Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () => _openFormForWeek(
                                  item, contract, kegMap, allWeeks),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.primaryBlue),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                            ),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
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
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (item.hasDailyReportsInWeek ||
                                item.realisasiMingguIniPersen > 0)
                              OutlinedButton(
                                onPressed: () => _openDetailModal(
                                    item, contract, kegMap, allWeeks),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: Color(0xFF64748B)),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Lihat BOQ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                              ),
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Buat Laporan',
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem(
    String label,
    String value,
    Color color, {
    bool bold = false,
    String? subText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textLight),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ),
        if (subText != null)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              subText,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF15803D),
              ),
            ),
          ),
      ],
    );
  }
}
