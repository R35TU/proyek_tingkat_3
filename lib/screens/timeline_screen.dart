import 'package:flutter/material.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Kronologi Proyek',
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
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildTimelineItem(
            date: '2026-09-21',
            time: '13:06',
            title: 'Dokumen Ditambah: File "project1.pdf"\ndiunggah.',
            subtitle: 'CV. Tata Saka (Konsultan)',
            isFirst: true,
            isLast: false,
          ),
          _buildTimelineItem(
            date: '2026-08-20',
            time: '07:50',
            title: 'Dokumen Ditambah: File "1234.pdf" diunggah.',
            subtitle: 'CV. Tata Saka (Konsultan)',
            isFirst: false,
            isLast: true,
          ),
        ],
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
