import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
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
    final provider = Provider.of<ContractProvider>(context);
    final contracts = provider.contracts;
    
    final int totalKontrak = contracts.length;
    final int kontrakAktif = contracts.where((c) => c.status != 'Selesai').length;
    final int kontrakSelesai = contracts.where((c) => c.status == 'Selesai').length;

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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.navySlate),
          onPressed: () {},
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.navySlate,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.navySlate),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section with Corporate Branding
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat Datang,',
                      style: TextStyle(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'CV. Tata Saka',
                      style: TextStyle(
                        color: AppColors.navySlate,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Konsultan Pengawas & Perencana',
                      style: TextStyle(color: AppColors.slate, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border, width: 1),
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
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.business,
                      color: AppColors.navySlate,
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
                Expanded(child: _buildStatCard('Total Kontrak', totalKontrak.toString(), Icons.folder_outlined, AppColors.slateLighter, AppColors.navySlate)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Kontrak Aktif', kontrakAktif.toString(), Icons.trending_up, const Color(0xFFE6F4EA), AppColors.successGreen)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Kontrak Selesai', kontrakSelesai.toString(), Icons.check_circle_outline, AppColors.slateLighter, AppColors.slate)),
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
      ),
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
                  style: const TextStyle(
                    color: AppColors.slate,
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
            style: const TextStyle(
              color: AppColors.navySlate,
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
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
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
}
