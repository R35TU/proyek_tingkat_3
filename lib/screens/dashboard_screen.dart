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
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () {},
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            const Text(
              'Selamat Datang,',
              style: TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'CV. Tata Saka',
              style: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Konsultan',
              style: TextStyle(color: AppColors.textLight, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 3 Grid Stats
            Row(
              children: [
                Expanded(child: _buildStatCard('Total Kontrak', totalKontrak.toString(), Icons.folder, AppColors.blueLight, AppColors.primaryBlue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Kontrak Aktif', kontrakAktif.toString(), Icons.bar_chart, const Color(0xFFE6F4EA), AppColors.successGreen)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Kontrak Selesai', kontrakSelesai.toString(), Icons.check_box, const Color(0xFFF3E8FF), const Color(0xFF9333EA))),
              ],
            ),
            
            const SizedBox(height: 32),

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
                      color: _currentPage == index ? AppColors.primaryBlue : Colors.grey[300],
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
            _buildActivityItem('Dokumen Ditambah', 'File "project1.pdf" diunggah.', '13:06'),
            const SizedBox(height: 12),
            _buildActivityItem('Dokumen Ditambah', 'File "1234.pdf" diunggah.', '07:50'),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselCard(ContractModel contract) {
    int totalKegiatan = contract.kegiatans.length;

    bool isPengawasan = contract.jenisKegiatan.toLowerCase().contains('pengawasan');
    
    // Distinct colors based on type
    Color badgeBgColor = isPengawasan ? AppColors.blueLight : const Color(0xFFFFF3E0); // Light Orange
    Color badgeTextColor = isPengawasan ? AppColors.primaryBlue : const Color(0xFFE65100); // Dark Orange

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4), // Slight margin for peeking effect if we used viewportFraction
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: badgeBgColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeTextColor.withOpacity(0.1)),
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
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  contract.jenisKegiatan,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
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
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(badgeTextColor),
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
                        ),
                      ),
                      const Text(
                        'Progres',
                        style: TextStyle(
                          color: AppColors.textLight,
                          fontSize: 10,
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
                          decoration: BoxDecoration(
                            color: badgeTextColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Kegiatan',
                          style: TextStyle(
                            color: AppColors.textLight,
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
                          color: AppColors.textDark,
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
                    color: AppColors.textLight,
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
              color: AppColors.textDark,
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
            decoration: BoxDecoration(
              color: AppColors.blueLight.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.folder,
              color: AppColors.primaryBlue,
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
