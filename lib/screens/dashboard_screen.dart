import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/kontrak_screen.dart';
import 'package:tata_saka_app/screens/laporan_screen.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/screens/timeline_screen.dart';
import 'package:tata_saka_app/screens/pengaturan_screen.dart';
import 'package:tata_saka_app/screens/keamanan_screen.dart';
import 'package:tata_saka_app/screens/edit_profil_screen.dart';
import 'package:tata_saka_app/screens/kelola_addendum_screen.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  bool _isWebSidebarOpen = true;
  String _activeWebMenu = 'dashboard';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_pageController.hasClients) {
        final contractCount = Provider.of<ContractProvider>(context, listen: false).contracts.length;
        if (contractCount > 1) {
          int nextPage = _currentPage + 1;
          if (nextPage >= contractCount) {
            nextPage = 0;
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.fastOutSlowIn,
            );
          } else {
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.fastOutSlowIn,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final safeUserProf = userProf ?? UserProfileProvider();
    final provider = Provider.of<ContractProvider>(context);
    final allContracts = provider.contracts;

    // ─── ROLE KONTRAKTOR: TAMPILAN KHUSUS KEGIATAN TANPA DATA KONTRAK LAIN ───
    if (safeUserProf.isKontraktor) {
      return _buildContractorDashboard(context, safeUserProf, allContracts);
    }

    // Filter Kontrak untuk Dinas: hanya kontrak terkait dinas tersebut
    final List<ContractModel> contracts;
    if (safeUserProf.isDinas) {
      final agency = safeUserProf.companyOrAgency.toLowerCase();
      contracts = allContracts.where((c) {
        return c.instansiDinas.any((d) =>
            d.toLowerCase().contains(agency) ||
            agency.contains(d.toLowerCase()) ||
            d.toLowerCase().contains('dpu') ||
            agency.contains('dpu'));
      }).toList();
    } else {
      contracts = allContracts;
    }
    
    final int totalKontrak = contracts.length;
    final int kontrakAktif = contracts.where((c) => c.status != 'Selesai').length;
    final int kontrakSelesai = contracts.where((c) => c.status == 'Selesai').length;

    final bool isWeb = MediaQuery.of(context).size.width >= 900;

    final Widget mainBody = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with Dynamic Branding
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        safeUserProf.tr('dash_welcome'),
                        style: TextStyle(color: AppColors.getTextLight(context), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        safeUserProf.namaLengkap,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.getTextDark(context),
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        safeUserProf.isDinas
                            ? safeUserProf.tr('dash_subtitle_dinas')
                            : safeUserProf.tr('dash_subtitle_konsultan'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppColors.getTextLight(context), fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: AppColors.getCardBackground(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.getBorder(context), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logoRev.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.business,
                      color: AppColors.getTextDark(context),
                      size: 26,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 3 Grid Stats (Corporate Slate harmonized)
            Row(
              children: [
                Expanded(child: _buildStatCard(safeUserProf.tr('dash_total_kontrak'), totalKontrak.toString(), Icons.folder_outlined, AppColors.slateLighter, AppColors.navySlate)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(safeUserProf.tr('dash_kontrak_aktif'), kontrakAktif.toString(), Icons.trending_up, const Color(0xFFE6F4EA), AppColors.successGreen)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(safeUserProf.tr('dash_kontrak_selesai'), kontrakSelesai.toString(), Icons.check_circle_outline, AppColors.slateLighter, AppColors.slate)),
              ],
            ),
            
            const SizedBox(height: 28),

            // Carousel Section
            if (contracts.isNotEmpty) ...[
              SizedBox(
                height: 200,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: contracts.length,
                  itemBuilder: (context, index) {
                    final contract = contracts[index];
                    return _buildCarouselCard(contract);
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Carousel Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  contracts.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.navySlate : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(24),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox, size: 48, color: AppColors.textLight),
                    SizedBox(height: 12),
                    Text('Belum ada kontrak', style: TextStyle(color: AppColors.textLight, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
            // Aktivitas Terkini
            const Text(
              'Aktivitas Terkini',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                final activities = _extractRecentActivities(contracts);
                if (activities.isNotEmpty) {
                  return Column(
                    children: activities.take(5).map((act) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildActivityItem(act['title']!, act['desc']!, act['time']!),
                    )).toList(),
                  );
                }
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.history_toggle_off, size: 40, color: AppColors.slate),
                      SizedBox(height: 10),
                      Text(
                        'Belum Ada Aktivitas Terkini',
                        style: TextStyle(color: AppColors.navySlate, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Aktivitas pembuatan laporan dan dokumen akan tercatat di sini secara otomatis.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.slate, fontSize: 11.5),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      );

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getCardBackground(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.getBorder(context)),
        ),
        leading: Builder(
          builder: (scaffoldCtx) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.getTextDark(context)),
            tooltip: isWeb
                ? (_isWebSidebarOpen ? 'Ciutkan Sidebar' : 'Buka Sidebar')
                : 'Buka Menu',
            onPressed: () {
              if (isWeb) {
                setState(() {
                  _isWebSidebarOpen = !_isWebSidebarOpen;
                });
              } else {
                Scaffold.of(scaffoldCtx).openDrawer();
              }
            },
          ),
        ),
        title: Text(
          safeUserProf.tr('nav_dashboard'),
          style: TextStyle(
            color: AppColors.getTextDark(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: AppColors.getTextDark(context)),
            onPressed: () {},
          ),
        ],
      ),
      drawer: isWeb
          ? null
          : _buildWebSidebar(
              context,
              userProf: safeUserProf,
              isDrawer: true,
            ),
      body: isWeb
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWebSidebar(
                  context,
                  userProf: safeUserProf,
                  isCollapsed: !_isWebSidebarOpen,
                  isDrawer: false,
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF1E293B)),
                Expanded(child: mainBody),
              ],
            )
          : mainBody,
    );
  }

  List<Map<String, String>> _extractRecentActivities(List<ContractModel> contracts) {
    final List<Map<String, String>> list = [];
    for (final c in contracts) {
      for (final keg in c.kegiatans) {
        final laporans = keg['laporans'] as List? ?? [];
        for (final rep in laporans) {
          if (rep is Map) {
            list.add({
              'title': 'Laporan Harian Ditambahkan',
              'desc': '${rep['tanggalFormatted'] ?? rep['tanggal'] ?? 'Laporan'} - ${keg['namaKegiatan'] ?? c.namaKontrak}',
              'time': (rep['jam'] ?? 'Hari ini').toString(),
            });
          }
        }
        final mingguan = keg['laporanMingguan'] as List? ?? [];
        for (final m in mingguan) {
          if (m is Map) {
            list.add({
              'title': 'Laporan Mingguan Dibuat',
              'desc': 'Minggu ke-${m['mingguKe']} - ${keg['namaKegiatan'] ?? c.namaKontrak}',
              'time': (m['periodeAkhir'] ?? 'Minggu ini').toString(),
            });
          }
        }
        final folders = keg['folders'] as List? ?? [];
        for (final f in folders) {
          if (f is Map) {
            final docs = f['documents'] as List? ?? [];
            for (final d in docs) {
              if (d is Map) {
                list.add({
                  'title': 'Dokumen Diunggah',
                  'desc': 'File "${d['name']}" pada ${f['name']}',
                  'time': (d['uploadDate'] ?? '-').toString(),
                });
              }
            }
          }
        }
      }
    }
    return list;
  }

  Widget _buildCarouselCard(ContractModel contract) {
    int totalKegiatan = contract.kegiatans.length;

    bool isPengawasan = contract.jenisKegiatan.toLowerCase().contains('pengawasan');
    
    // Harmonized badge color in Corporate Slate
    Color badgeBgColor = isPengawasan ? AppColors.slateLighter : const Color(0xFFFEF3C7);
    Color badgeTextColor = isPengawasan ? AppColors.navySlate : const Color(0xFFB45309);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  contract.namaKontrak,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.navySlate,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Text(
                  contract.jenisKegiatan,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Circular Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 75,
                    width: 75,
                    child: CircularProgressIndicator(
                      value: contract.progressFisik,
                      strokeWidth: 8,
                      backgroundColor: AppColors.slateLighter,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.navySlate),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(contract.progressFisik * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.navySlate,
                        ),
                      ),
                      const Text(
                        'Progres',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                ],
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.navySlate,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Kegiatan',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: Text(
                        totalKegiatan.toString(),
                        style: const TextStyle(
                          color: AppColors.navySlate,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
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

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextLight(context),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextDark(context),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String desc, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.slateLighter,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder,
              color: AppColors.navySlate,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Oleh: CV. Tata Saka (Konsultan)',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DASHBOARD EKSKLUSIF KONTRAKTOR: HANYA MENAMPILKAN KEGIATAN MEREKA SENDIRI
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContractorDashboard(
    BuildContext context,
    UserProfileProvider userProf,
    List<ContractModel> contracts,
  ) {
    final contractorName = userProf.namaLengkap.toLowerCase();
    final List<Map<String, dynamic>> myKegiatans = [];
    final List<int> kegIndices = [];
    final List<ContractModel> parentContracts = [];

    for (final c in contracts) {
      for (int i = 0; i < c.kegiatans.length; i++) {
        final k = c.kegiatans[i];
        final kKontraktor = (k['kontraktor'] ?? '').toString().toLowerCase();

        bool isMine = false;
        if (kKontraktor.isNotEmpty) {
          if (kKontraktor.contains(contractorName) || contractorName.contains(kKontraktor)) {
            isMine = true;
          } else if (contractorName.contains('divan') && kKontraktor.contains('divan')) {
            isMine = true;
          } else if (contractorName.contains('langgeng') && kKontraktor.contains('langgeng')) {
            isMine = true;
          }
        }
        if (isMine) {
          myKegiatans.add(k);
          kegIndices.add(i);
          parentContracts.add(c);
        }
      }
    }

    double sumProgress = 0.0;
    for (final k in myKegiatans) {
      sumProgress += _calcKegiatanProgress(k);
    }
    final double avgProgress = myKegiatans.isNotEmpty ? (sumProgress / myKegiatans.length) : 0.0;

    final bool isWeb = MediaQuery.of(context).size.width >= 900;

    final Widget contractorBody = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selamat Datang,',
                          style: TextStyle(color: AppColors.slate, fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          userProf.namaLengkap,
                          style: const TextStyle(
                            color: AppColors.navySlate,
                            fontSize: 18.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFDBEAFE)),
                          ),
                          child: const Text(
                            'Penyedia Jasa / Kontraktor Pelaksana',
                            style: TextStyle(
                              color: Color(0xFF1D4ED8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: const Icon(Icons.engineering_outlined, color: Color(0xFF2563EB), size: 26),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3 Stat Cards Khusus Kegiatan
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Kegiatan Saya',
                    myKegiatans.length.toString(),
                    Icons.assignment_outlined,
                    AppColors.slateLighter,
                    AppColors.navySlate,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rata-rata Progres',
                    '${avgProgress.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    const Color(0xFFE6F4EA),
                    AppColors.successGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Status',
                    'Aktif',
                    Icons.check_circle_outline,
                    AppColors.slateLighter,
                    AppColors.slate,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),

            // Daftar Kegiatan Pelaksanaan Saya
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kegiatan Pelaksanaan Saya',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '${myKegiatans.length} Kegiatan',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (myKegiatans.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.assignment_late_outlined, size: 48, color: AppColors.slate),
                    const SizedBox(height: 12),
                    const Text(
                      'Belum Ada Kegiatan Ditugaskan',
                      style: TextStyle(color: AppColors.navySlate, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kegiatan pelaksanaan yang ditugaskan kepada ${userProf.namaLengkap} akan tampil di sini.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.slate, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: List.generate(myKegiatans.length, (idx) {
                  final k = myKegiatans[idx];
                  final parentContract = parentContracts[idx];
                  final kIndex = kegIndices[idx];
                  final prog = _calcKegiatanProgress(k);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.assignment, color: Color(0xFF2563EB), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    k['namaKegiatan'] ?? 'Nama Kegiatan',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: AppColors.navySlate,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${k['lokasi'] ?? '-'} • ${k['sumberDana'] ?? 'APBD'}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.slate),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Nilai Kontrak Kegiatan:', style: TextStyle(fontSize: 11.5, color: AppColors.slate)),
                            Text(
                              (k['nilaiKontrak'] ?? '-').toString(),
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.navySlate),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Progress Bar
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: prog / 100.0,
                                  minHeight: 8,
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.navySlate),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${prog.toStringAsFixed(1)}%',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navySlate),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailKegiatanScreen(
                                  contract: parentContract,
                                  kegiatanIndex: kIndex,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: const [
                              Text(
                                'Lihat Detail Kegiatan',
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            const SizedBox(height: 20),
          ],
        ),
      );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        leading: Builder(
          builder: (scaffoldCtx) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.navySlate),
            tooltip: isWeb
                ? (_isWebSidebarOpen ? 'Ciutkan Sidebar' : 'Buka Sidebar')
                : 'Buka Menu',
            onPressed: () {
              if (isWeb) {
                setState(() {
                  _isWebSidebarOpen = !_isWebSidebarOpen;
                });
              } else {
                Scaffold.of(scaffoldCtx).openDrawer();
              }
            },
          ),
        ),
        title: Column(
          children: [
            const Text(
              'Dashboard Kontraktor',
              style: TextStyle(
                color: AppColors.navySlate,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userProf.namaLengkap,
              style: const TextStyle(
                color: AppColors.slate,
                fontSize: 11,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      drawer: isWeb
          ? null
          : _buildWebSidebar(
              context,
              userProf: userProf,
              isDrawer: true,
            ),
      body: isWeb
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWebSidebar(
                  context,
                  userProf: userProf,
                  isCollapsed: !_isWebSidebarOpen,
                  isDrawer: false,
                ),
                const VerticalDivider(width: 1, thickness: 1, color: Color(0xFF1E293B)),
                Expanded(child: contractorBody),
              ],
            )
          : contractorBody,
    );
  }

  double _calcKegiatanProgress(Map<String, dynamic> keg) {
    final activeRkk = (keg['rkkDivisiList'] as List? ?? []);
    final laporans = (keg['laporans'] as List? ?? []);

    if (activeRkk.isNotEmpty && laporans.isNotEmpty) {
      double totalRealisasiBobot = 0.0;
      for (final rep in laporans) {
        if (rep is! Map) continue;
        final pList = (rep['pekerjaanList'] as List? ?? []);
        for (final p in pList) {
          if (p is! Map) continue;
          final volStr = (p['volume'] ?? '').toString();
          final vol = double.tryParse(volStr.split(' ').first.replaceAll(',', '.')) ?? 0.0;
          final itId = (p['rkkItemId'] ?? '').toString().trim();
          final noMata = (p['noMataPembayaran'] ?? '').toString().trim();
          final jenis = (p['uraian'] ?? p['jenisPekerjaan'] ?? '').toString().trim().toLowerCase();

          for (final div in activeRkk) {
            for (final it in (div['items'] as List? ?? [])) {
              final bId = (it['id'] ?? '').toString().trim();
              final bNo = (it['noMataPembayaran'] ?? '').toString().trim();
              final bUr = (it['uraian'] ?? '').toString().trim().toLowerCase();

              final match = (itId.isNotEmpty && bId.isNotEmpty && itId == bId) ||
                  (noMata.isNotEmpty && bNo.isNotEmpty && noMata == bNo) ||
                  (jenis.isNotEmpty && (bUr == jenis || bUr.contains(jenis)));

              if (match) {
                final targetVol = (it['volumeCCO'] ?? it['volume'] as num?)?.toDouble() ?? 0.0;
                final bobotItem = (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
                if (targetVol > 0) {
                  totalRealisasiBobot += (vol / targetVol) * bobotItem;
                }
                break;
              }
            }
          }
        }
      }
      return totalRealisasiBobot.clamp(0.0, 100.0);
    }

    final weekly = (keg['laporanMingguan'] as List? ?? []);
    if (weekly.isNotEmpty && weekly.last is Map) {
      final lastW = weekly.last as Map;
      return (lastW['realisasiPersen'] as num?)?.toDouble() ?? 0.0;
    }

    return 0.0;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── DESAIN & PENGEMBANGAN SIDEBAR DASHBOARD WEB (CORPORATE SLATE PALETTE) ───
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWebSidebar(
    BuildContext context, {
    required UserProfileProvider userProf,
    bool isCollapsed = false,
    bool isDrawer = false,
  }) {
    final double sidebarWidth = isDrawer ? 300 : (isCollapsed ? 76 : 260);

    return Container(
      width: sidebarWidth,
      height: double.infinity,
      color: const Color(0xFF0F172A), // Corporate Slate 900
      child: SafeArea(
        child: Column(
          children: [
            // ─── Header: Branding Tata Saka & Collapse Action ───
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12 : 16,
                vertical: 16,
              ),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFF1E293B), width: 1),
                ),
              ),
              child: isCollapsed
                  ? Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/images/logoRev.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business,
                              color: Color(0xFF0F172A),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
                          tooltip: 'Buka Sidebar',
                          onPressed: () {
                            setState(() {
                              _isWebSidebarOpen = true;
                            });
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logoRev.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business,
                              color: Color(0xFF0F172A),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CV. TATA SAKA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Consultant Engineer',
                                style: TextStyle(
                                  color: Color(0xFF38BDF8),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isDrawer)
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: Color(0xFF94A3B8), size: 22),
                            tooltip: 'Ciutkan Sidebar',
                            onPressed: () {
                              setState(() {
                                _isWebSidebarOpen = false;
                              });
                            },
                          ),
                      ],
                    ),
            ),

            // ─── User Profile Banner ───
            if (!isCollapsed)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF334155), width: 0.8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF38BDF8).withOpacity(0.2),
                      child: Text(
                        userProf.namaLengkap.isNotEmpty ? userProf.namaLengkap[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProf.namaLengkap,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: userProf.isKontraktor
                                  ? const Color(0xFFFEF3C7)
                                  : (userProf.isDinas ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE)),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              userProf.role.toUpperCase(),
                              style: TextStyle(
                                color: userProf.isKontraktor
                                    ? const Color(0xFFB45309)
                                    : (userProf.isDinas ? const Color(0xFF15803D) : const Color(0xFF1D4ED8)),
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Tooltip(
                  message: '${userProf.namaLengkap} (${userProf.role})',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFF1E293B),
                    child: Text(
                      userProf.namaLengkap.isNotEmpty ? userProf.namaLengkap[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Color(0xFF38BDF8),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

            // ─── Scrollable Menu Categories ───
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 12, vertical: 8),
                children: [
                  // 1. KATEGORI UTAMA
                  _buildSidebarCategory('UTAMA', isCollapsed),
                  _buildSidebarItem(
                    key: 'dashboard',
                    label: userProf.tr('nav_dashboard'),
                    icon: Icons.dashboard_rounded,
                    isActive: _activeWebMenu == 'dashboard',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'dashboard');
                    },
                  ),
                  _buildSidebarItem(
                    key: 'kegiatan',
                    label: userProf.isKontraktor ? userProf.tr('nav_kegiatan_saya') : 'Data Proyek / Kegiatan',
                    icon: Icons.assignment_rounded,
                    isActive: _activeWebMenu == 'kegiatan',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'kegiatan');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KontrakScreen()));
                    },
                  ),
                  if (!userProf.isKontraktor)
                    _buildSidebarItem(
                      key: 'kontrak',
                      label: userProf.tr('nav_kontrak'),
                      icon: Icons.folder_shared_rounded,
                      isActive: _activeWebMenu == 'kontrak',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        setState(() => _activeWebMenu = 'kontrak');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const KontrakScreen()));
                      },
                    ),

                  const SizedBox(height: 14),

                  // 2. KATEGORI TEKNIS & ANGGARAN
                  _buildSidebarCategory('TEKNIS & ANGGARAN', isCollapsed),
                  _buildSidebarItem(
                    key: 'rab',
                    label: 'RAB / BoQ',
                    icon: Icons.calculate_rounded,
                    isActive: _activeWebMenu == 'rab',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'rab');
                      final prov = Provider.of<ContractProvider>(context, listen: false);
                      if (prov.contracts.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailKontrakScreen(contract: prov.contracts.first),
                          ),
                        );
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const KontrakScreen()));
                      }
                    },
                  ),
                  _buildSidebarItem(
                    key: 'addendum',
                    label: 'Addendum CCO',
                    icon: Icons.change_circle_rounded,
                    isActive: _activeWebMenu == 'addendum',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'addendum');
                      final prov = Provider.of<ContractProvider>(context, listen: false);
                      if (prov.contracts.isNotEmpty) {
                        final c = prov.contracts.first;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KelolaAddendumScreen(
                              contract: c,
                              kegiatanIndex: 0,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const KontrakScreen()));
                      }
                    },
                  ),

                  // 3. KATEGORI PELAPORAN (Hanya Konsultan & Dinas)
                  if (!userProf.isKontraktor) ...[
                    const SizedBox(height: 14),
                    _buildSidebarCategory('PELAPORAN', isCollapsed),
                    _buildSidebarItem(
                      key: 'laporan_harian',
                      label: 'Laporan Harian',
                      icon: Icons.today_rounded,
                      isActive: _activeWebMenu == 'laporan_harian',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        setState(() => _activeWebMenu = 'laporan_harian');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const DataLaporanScreen()));
                      },
                    ),
                    _buildSidebarItem(
                      key: 'laporan_mingguan',
                      label: 'Laporan Mingguan',
                      icon: Icons.date_range_rounded,
                      isActive: _activeWebMenu == 'laporan_mingguan',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        setState(() => _activeWebMenu = 'laporan_mingguan');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanScreen()));
                      },
                    ),
                    _buildSidebarItem(
                      key: 'laporan_bulanan',
                      label: 'Laporan Bulanan',
                      icon: Icons.calendar_month_rounded,
                      isActive: _activeWebMenu == 'laporan_bulanan',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        setState(() => _activeWebMenu = 'laporan_bulanan');
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporanBulananScreen()));
                      },
                    ),
                  ],

                  const SizedBox(height: 14),

                  // 4. KATEGORI DOKUMEN & HISTORI
                  _buildSidebarCategory('DOKUMEN & HISTORI', isCollapsed),
                  _buildSidebarItem(
                    key: 'dokumen',
                    label: 'Administrasi Dokumen',
                    icon: Icons.folder_copy_rounded,
                    isActive: _activeWebMenu == 'dokumen',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'dokumen');
                      final prov = Provider.of<ContractProvider>(context, listen: false);
                      if (prov.contracts.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailKontrakScreen(contract: prov.contracts.first),
                          ),
                        );
                      } else {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const KontrakScreen()));
                      }
                    },
                  ),
                  _buildSidebarItem(
                    key: 'timeline',
                    label: 'Timeline & Histori',
                    icon: Icons.timeline_rounded,
                    isActive: _activeWebMenu == 'timeline',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'timeline');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const TimelineScreen()));
                    },
                  ),

                  const SizedBox(height: 14),

                  // 5. KATEGORI AKUN
                  _buildSidebarCategory('AKUN & PENGATURAN', isCollapsed),
                  _buildSidebarItem(
                    key: 'pengaturan',
                    label: 'Pengaturan Akun',
                    icon: Icons.settings_rounded,
                    isActive: _activeWebMenu == 'pengaturan',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'pengaturan');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const PengaturanScreen()));
                    },
                  ),
                  _buildSidebarItem(
                    key: 'keamanan',
                    label: 'Keamanan & Sandi',
                    icon: Icons.security_rounded,
                    isActive: _activeWebMenu == 'keamanan',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'keamanan');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KeamananScreen()));
                    },
                  ),
                  _buildSidebarItem(
                    key: 'edit_profil',
                    label: 'Edit Profil',
                    icon: Icons.person_outline_rounded,
                    isActive: _activeWebMenu == 'edit_profil',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      setState(() => _activeWebMenu = 'edit_profil');
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilScreen()));
                    },
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarCategory(String title, bool isCollapsed) {
    if (isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: Color(0xFF1E293B), height: 1),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required String key,
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isCollapsed,
    required VoidCallback onTap,
  }) {
    const activeBg = Color(0xFF1E293B);
    const activeBorder = Color(0xFF38BDF8);
    const activeIconColor = Color(0xFF38BDF8);
    const inactiveIconColor = Color(0xFF94A3B8);
    const inactiveTextColor = Color(0xFFCBD5E1);

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Tooltip(
          message: label,
          preferBelow: false,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive ? Border.all(color: activeBorder, width: 1) : null,
              ),
              child: Icon(
                icon,
                color: isActive ? activeIconColor : inactiveIconColor,
                size: 21,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive ? Border.all(color: activeBorder.withOpacity(0.6), width: 1) : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? activeIconColor : inactiveIconColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.white : inactiveTextColor,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF38BDF8),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
