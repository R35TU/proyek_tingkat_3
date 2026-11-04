import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  List<Map<String, String>> _extractTimeline(List<ContractModel> contracts) {
    final List<Map<String, String>> list = [];
    for (final c in contracts) {
      for (final keg in c.kegiatans) {
        final laporans = keg['laporans'] as List? ?? [];
        for (final rep in laporans) {
          if (rep is Map) {
            list.add({
              'date': (rep['tanggalFormatted'] ?? rep['tanggal'] ?? '-').toString(),
              'time': (rep['jam'] ?? 'Hari ini').toString(),
              'title': 'Laporan Harian: ${keg['namaKegiatan'] ?? c.namaKontrak}',
              'subtitle': 'CV. Tata Saka (Konsultan)',
            });
          }
        }
        final mingguan = keg['laporanMingguan'] as List? ?? [];
        for (final m in mingguan) {
          if (m is Map) {
            list.add({
              'date': (m['periodeAkhir'] ?? '-').toString(),
              'time': 'Mingguan',
              'title': 'Laporan Mingguan ke-${m['mingguKe']}: ${keg['namaKegiatan'] ?? c.namaKontrak}',
              'subtitle': 'CV. Tata Saka (Konsultan)',
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
                  'date': (d['uploadDate'] ?? '-').toString(),
                  'time': 'Dokumen',
                  'title': 'Dokumen: File "${d['name']}" pada ${f['name']}',
                  'subtitle': 'CV. Tata Saka (Konsultan)',
                });
              }
            }
          }
        }
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
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
          'Kronologi Proyek',
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
      body: Consumer<ContractProvider>(
        builder: (context, provider, child) {
          final contracts = provider.contracts;
          final timelineList = _extractTimeline(contracts);

          if (timelineList.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 56,
                      color: AppColors.slate.withOpacity(0.4),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Belum Ada Kronologi Aktivitas',
                      style: TextStyle(
                        color: AppColors.navySlate,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Riwayat dokumen dan laporan proyek akan tercatat di sini secara kronologis.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.slate, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: timelineList.length,
            itemBuilder: (context, index) {
              final it = timelineList[index];
              return _buildTimelineItem(
                date: it['date'] ?? '-',
                time: it['time'] ?? '-',
                title: it['title'] ?? '-',
                subtitle: it['subtitle'] ?? 'CV. Tata Saka (Konsultan)',
                isFirst: index == 0,
                isLast: index == timelineList.length - 1,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem({
    required String date,
    required String time,
    required String title,
    required String subtitle,
    required bool isFirst,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line and Dot
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Line
                if (!isLast)
                  Positioned(
                    top: 12, // start line from middle of dot
                    bottom: -24, // extend to next item
                    child: Container(
                      width: 2,
                      color: AppColors.border,
                    ),
                  ),
                // Dot
                Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.blueLight,
                      width: 4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        date,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
