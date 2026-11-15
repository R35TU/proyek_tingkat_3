import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

/// Model untuk mencatat riwayat perubahan dan kronologi audit trail proyek
class TimelineEventModel {
  final String id;
  final DateTime timestamp;
  final String actorName;
  final String actorRole; // 'Konsultan', 'Kontraktor', 'Dinas', 'Sistem'
  final String actionType; // 'CREATE', 'UPDATE', 'DELETE', 'APPROVE', 'UPLOAD'
  final String entityType; // 'KONTRAK', 'KEGIATAN', 'RKK', 'ADDENDUM', 'LAPORAN_HARIAN', 'LAPORAN_MINGGUAN', 'LAPORAN_BULANAN', 'DOKUMEN'

  final String contractId;
  final String contractName;
  final String? kegiatanId;
  final String? kegiatanName;
  final String? kontraktorName; // Untuk filter role Kontraktor
  final String? dinasName; // Untuk filter role Dinas

  final String title;
  final String description;

  /// Detail perubahan Sebelum vs Sesudah (Opsi A)
  /// Format: [{'parameter': 'Volume Mobilisasi', 'oldValue': '0.00 Ls', 'newValue': '1.00 Ls'}]
  final List<Map<String, String>> changes;

  /// Data pendukung tambahan (misal: mingguKe, progressPersen, nomorSurat)
  final Map<String, dynamic> metadata;

  TimelineEventModel({
    required this.id,
    required this.timestamp,
    required this.actorName,
    this.actorRole = 'Konsultan',
    required this.actionType,
    required this.entityType,
    required this.contractId,
    required this.contractName,
    this.kegiatanId,
    this.kegiatanName,
    this.kontraktorName,
    this.dinasName,
    required this.title,
    required this.description,
    this.changes = const [],
    this.metadata = const {},
  });

  /// Mengelompokkan tipe entity ke dalam Kategori Filter Utama
  String get category {
    switch (entityType.toUpperCase()) {
      case 'KONTRAK':
      case 'KEGIATAN':
        return 'Kontrak & Kegiatan';
      case 'RKK':
        return 'RAB / BoQ';
      case 'ADDENDUM':
        return 'Addendum (CCO)';
      case 'LAPORAN_HARIAN':
      case 'LAPORAN_MINGGUAN':
      case 'LAPORAN_BULANAN':
        return 'Laporan';
      case 'DOKUMEN':
        return 'Dokumen';
      default:
        return 'Lainnya';
    }
  }
  /// Icon representatif untuk jenis event
  IconData get icon {
    switch (entityType.toUpperCase()) {
      case 'KONTRAK':
        return Icons.business_center_outlined;
      case 'KEGIATAN':
        return Icons.alt_route_outlined;
      case 'RKK':
        return Icons.table_chart_outlined;
      case 'ADDENDUM':
        return Icons.difference_outlined;
      case 'LAPORAN_HARIAN':
        return Icons.today_outlined;
      case 'LAPORAN_MINGGUAN':
        return Icons.date_range_outlined;
      case 'LAPORAN_BULANAN':
        return Icons.calendar_month_outlined;
      case 'DOKUMEN':
        return Icons.folder_shared_outlined;
      default:
        return Icons.history_outlined;
    }
  }

  /// Warna badge aksi
  Color get actionColor {
    switch (actionType.toUpperCase()) {
      case 'CREATE':
        return const Color(0xFF10B981); // Emerald / Sukses
      case 'UPDATE':
        return const Color(0xFFF59E0B); // Amber / Perubahan
      case 'DELETE':
        return const Color(0xFFEF4444); // Red / Hapus
      case 'APPROVE':
        return const Color(0xFF3B82F6); // Blue / Persetujuan
      case 'UPLOAD':
        return const Color(0xFF8B5CF6); // Violet / Unggah
      default:
        return AppColors.navySlate;
    }
  }

  /// Label aksi berbahasa Indonesia
  String get actionLabel {
    switch (actionType.toUpperCase()) {
      case 'CREATE':
        return 'Dibuat';
      case 'UPDATE':
        return 'Diperbarui';
      case 'DELETE':
        return 'Dihapus';
      case 'APPROVE':
        return 'Disetujui';
      case 'UPLOAD':
        return 'Diunggah';
      default:
        return 'Aktivitas';
    }
  }

  /// Tanggal terformat (contoh: 20 Apr 2026)
  String get formattedDate {
    try {
      return DateFormat('d MMM yyyy', 'id_ID').format(timestamp);
    } catch (_) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  /// Waktu terformat (contoh: 14:30 WIB)
  String get formattedTime {
    try {
      return '${DateFormat('HH:mm').format(timestamp)} WIB';
    } catch (_) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')} WIB';
    }
  }

  /// Relasi waktu relatif
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0 && timestamp.day == now.day) {
      return 'Hari ini';
    } else if (difference.inDays == 1 || (difference.inDays == 0 && timestamp.day != now.day)) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else {
      return formattedDate;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'actorName': actorName,
    'actorRole': actorRole,
    'actionType': actionType,
    'entityType': entityType,
    'contractId': contractId,
    'contractName': contractName,
    'kegiatanId': kegiatanId,
    'kegiatanName': kegiatanName,
    'kontraktorName': kontraktorName,
    'dinasName': dinasName,
    'title': title,
    'description': description,
    'changes': changes,
    'metadata': metadata,
  };

  factory TimelineEventModel.fromJson(Map<String, dynamic> json) {
    List<Map<String, String>> parsedChanges = [];
    if (json['changes'] is List) {
      for (final item in json['changes']) {
        if (item is Map) {
          parsedChanges.add(
            item.map((key, value) => MapEntry(key.toString(), value.toString())),
          );
        }
      }
    }

    return TimelineEventModel(
      id: json['id']?.toString() ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now()
          : DateTime.now(),
      actorName: json['actorName']?.toString() ?? 'Pengguna',
      actorRole: json['actorRole']?.toString() ?? 'Konsultan',
      actionType: json['actionType']?.toString() ?? 'CREATE',
      entityType: json['entityType']?.toString() ?? 'KONTRAK',
      contractId: json['contractId']?.toString() ?? '',
      contractName: json['contractName']?.toString() ?? '',
      kegiatanId: json['kegiatanId']?.toString(),
      kegiatanName: json['kegiatanName']?.toString(),
      kontraktorName: json['kontraktorName']?.toString(),
      dinasName: json['dinasName']?.toString(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      changes: parsedChanges,
      metadata: json['metadata'] is Map ? Map<String, dynamic>.from(json['metadata']) : {},
    );
  }
}
