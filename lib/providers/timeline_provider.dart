import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/timeline_event_model.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';

class TimelineProvider with ChangeNotifier {
  static const String _storageKey = 'tata_saka_timeline_events_v1';

  List<TimelineEventModel> _events = [];
  bool _isLoading = true;

  bool get isLoading => _isLoading;
  List<TimelineEventModel> get allEvents => List.unmodifiable(_events);

  TimelineProvider() {
    loadEvents();
  }
  /// Memuat riwayat timeline dari local persistence (SharedPreferences)
  Future<void> loadEvents() async {
    _isLoading = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawData = prefs.getString(_storageKey);

      if (rawData != null && rawData.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(rawData);
        _events = decoded
            .map((item) => TimelineEventModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        // Inisialisasi seed bawaan bila belum ada data tersimpan
        _events = _generateInitialSeedEvents();
        await _saveEvents();
      }
      _sortEvents();
    } catch (e) {
      debugPrint('Error loading timeline events: $e');
      _events = _generateInitialSeedEvents();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Menyimpan events ke local storage
  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_events.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving timeline events: $e');
    }
  }

  /// Urutkan timeline dari yang paling baru ke paling lama
  void _sortEvents() {
    _events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Mencatat event baru ke dalam audit trail
  Future<void> logEvent({
    required String actorName,
    String actorRole = 'Konsultan',
    required String actionType,
    required String entityType,
    required String contractId,
    required String contractName,
    String? kegiatanId,
    String? kegiatanName,
    String? kontraktorName,
    String? dinasName,
    required String title,
    required String description,
    List<Map<String, String>> changes = const [],
    Map<String, dynamic> metadata = const {},
    DateTime? customTimestamp,
  }) async {
    final event = TimelineEventModel(
      id: 'timeline_${DateTime.now().millisecondsSinceEpoch}_${_events.length + 1}',
      timestamp: customTimestamp ?? DateTime.now(),
      actorName: actorName,
      actorRole: actorRole,
      actionType: actionType,
      entityType: entityType,
      contractId: contractId,
      contractName: contractName,
      kegiatanId: kegiatanId,
      kegiatanName: kegiatanName,
      kontraktorName: kontraktorName,
      dinasName: dinasName ?? 'DPU-PR Kab. Purbalingga',
      title: title,
      description: description,
      changes: changes,
      metadata: metadata,
    );

    _events.insert(0, event);
    _sortEvents();
    await _saveEvents();
    notifyListeners();
  }

  /// Hapus event tertentu
  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    await _saveEvents();
    notifyListeners();
  }

  /// Reset timeline ke seed default bawaan
  Future<void> resetToDefaultEvents() async {
    _events = _generateInitialSeedEvents();
    _sortEvents();
    await _saveEvents();
    notifyListeners();
  }

  /// Hapus semua event
  Future<void> clearEvents() async {
    _events.clear();
    await _saveEvents();
    notifyListeners();
  }

  /// Rekonsiliasi & Sinkronisasi dinamis seluruh aktivitas dari ContractProvider
  /// Memastikan seluruh laporan harian (misal tanggal 21, 22, 23), mingguan, addendum, dan dokumen
  /// terdaftar lengkap di Timeline dengan tanggal & waktu yang akurat.
  Future<void> syncWithContracts(List<ContractModel> contracts) async {
    bool hasNewEvents = false;
    final Set<String> existingIds = _events.map((e) => e.id).toSet();

    for (final c in contracts) {
      final cId = c.id;
      final cName = c.namaKontrak;
      final dinas = c.instansiDinas.isNotEmpty
          ? c.instansiDinas.first
          : 'DPU-PR Kab. Purbalingga';

      // 1. Aktivitas Pembuatan Kontrak
      final contractEventId = 'timeline_contract_create_$cId';
      if (!existingIds.contains(contractEventId)) {
        DateTime contractTime = DateTime.tryParse(c.tglMulaiSpk) ?? DateTime(2026, 4, 15, 9, 0);
        _events.add(TimelineEventModel(
          id: contractEventId,
          timestamp: contractTime,
          actorName: 'PPK Dinas & Tim Konsultan',
          actorRole: 'Konsultan',
          actionType: 'CREATE',
          entityType: 'KONTRAK',
          contractId: cId,
          contractName: cName,
          dinasName: dinas,
          title: 'Pembuatan Kontrak Pengawasan: $cName',
          description:
              'Kontrak pengawasan resmi diterbitkan dengan nomor ${c.nomorSpk.isNotEmpty ? c.nomorSpk : "-"} dan nilai Rp ${c.nilaiKontrak.isNotEmpty ? c.nilaiKontrak : "-"}.',
          metadata: {'nomorSpk': c.nomorSpk, 'nilai': c.nilaiKontrak},
        ));
        existingIds.add(contractEventId);
        hasNewEvents = true;
      }

      // 2. Aktivitas Dokumen Tingkat Kontrak
      for (final f in c.folders) {
        final docs = f['documents'];
        if (docs is List) {
          for (final doc in docs) {
            if (doc is Map) {
              final docId = doc['id']?.toString() ?? doc['name']?.toString() ?? '';
              final evId = 'timeline_doc_contract_${cId}_$docId';
              if (docId.isNotEmpty && !existingIds.contains(evId)) {
                DateTime docTime = doc['uploadDate'] != null
                    ? (DateTime.tryParse(doc['uploadDate']) ?? DateTime.now())
                    : DateTime.now();
                _events.add(TimelineEventModel(
                  id: evId,
                  timestamp: docTime,
                  actorName: 'CV. Tata Saka Consultant',
                  actorRole: 'Konsultan',
                  actionType: 'UPLOAD',
                  entityType: 'DOKUMEN',
                  contractId: cId,
                  contractName: cName,
                  dinasName: dinas,
                  title: 'Unggah Dokumen Kontrak: ${doc['name']}',
                  description:
                      'Dokumen ${doc['name']} (${doc['type'] ?? 'PDF'}) diunggah ke folder administrasi kontrak "${f['name']}".',
                  metadata: {'folder': f['name'], 'docType': doc['type']},
                ));
                existingIds.add(evId);
                hasNewEvents = true;
              }
            }
          }
        }
      }

      // 3. Iterasi Seluruh Kegiatan di Bawah Kontrak
      for (int kIdx = 0; kIdx < c.kegiatans.length; kIdx++) {
        final keg = c.kegiatans[kIdx];
        final kName = keg['namaKegiatan']?.toString() ?? 'Kegiatan #${kIdx + 1}';
        final kontraktor = keg['kontraktor']?.toString() ?? 'Kontraktor';
        final kegId = 'keg_${cId}_$kIdx';

        // 3a. Event Pembuatan Kegiatan
        final kegEventId = 'timeline_keg_create_${cId}_$kIdx';
        if (!existingIds.contains(kegEventId)) {
          final kegTime = DateTime(2026, 4, 18, 10, 0);
          _events.add(TimelineEventModel(
            id: kegEventId,
            timestamp: kegTime,
            actorName: 'CV. Tata Saka Consultant',
            actorRole: 'Konsultan',
            actionType: 'CREATE',
            entityType: 'KEGIATAN',
            contractId: cId,
            contractName: cName,
            kegiatanId: kegId,
            kegiatanName: kName,
            kontraktorName: kontraktor,
            dinasName: dinas,
            title: 'Penetapan Kegiatan: $kName',
            description:
                'Kegiatan pengawasan lapangan disiapkan untuk kontraktor pelaksana $kontraktor.',
            metadata: {'kegiatan': kName, 'kontraktor': kontraktor},
          ));
          existingIds.add(kegEventId);
          hasNewEvents = true;
        }

        // 3b. Seluruh Laporan Harian (Buku Harian Standar)
        final rawLaporans = keg['laporans'];
        if (rawLaporans is List) {
          for (int rIdx = 0; rIdx < rawLaporans.length; rIdx++) {
            final rep = rawLaporans[rIdx];
            if (rep is Map) {
              final repId = rep['id']?.toString() ?? 'rep_$rIdx';
              final tglStr = rep['tanggal']?.toString() ?? '';
              final tglFormatted = rep['tanggalFormatted']?.toString() ?? tglStr;
              final evId = 'timeline_daily_${cId}_${kIdx}_$repId';

              if (!existingIds.contains(evId)) {
                DateTime repDate = DateTime.tryParse(tglStr) ??
                    DateTime(2026, 4, 20 + (rIdx % 10), 16, 30);
                if (repDate.hour == 0 && repDate.minute == 0) {
                  repDate = DateTime(repDate.year, repDate.month, repDate.day, 16, 30);
                }

                final cuaca = rep['cuaca']?.toString() ?? 'Cerah';
                final nTenaga = rep['tenagaKerja'] != null
                    ? '${rep['tenagaKerja']} orang'
                    : '-';

                String pekSummary = '';
                final pekerjaanList = rep['pekerjaan'];
                if (pekerjaanList is List && pekerjaanList.isNotEmpty) {
                  pekSummary = pekerjaanList
                      .map((p) => p['uraian'] ?? p['nama'] ?? '')
                      .where((s) => s.toString().isNotEmpty)
                      .take(3)
                      .join(', ');
                }

                _events.add(TimelineEventModel(
                  id: evId,
                  timestamp: repDate,
                  actorName: 'BILAL, A.Md (Inspektor Lapangan)',
                  actorRole: 'Konsultan',
                  actionType: 'CREATE',
                  entityType: 'LAPORAN_HARIAN',
                  contractId: cId,
                  contractName: cName,
                  kegiatanId: kegId,
                  kegiatanName: kName,
                  kontraktorName: kontraktor,
                  dinasName: dinas,
                  title: 'Buku Harian Standar: $kName ($tglFormatted)',
                  description:
                      'Laporan harian tercatat pada tanggal $tglFormatted. Cuaca: $cuaca, Tenaga Kerja: $nTenaga.${pekSummary.isNotEmpty ? " Rincian item: $pekSummary." : ""}',
                  metadata: {
                    'tanggal': tglStr,
                    'tanggalFormatted': tglFormatted,
                    'cuaca': cuaca,
                    'tenagaKerja': nTenaga,
                  },
                ));
                existingIds.add(evId);
                hasNewEvents = true;
              }
            }
          }
        }

        // 3c. Seluruh Laporan Mingguan
        final rawWeekly = keg['laporanMingguan'];
        if (rawWeekly is List) {
          for (int wIdx = 0; wIdx < rawWeekly.length; wIdx++) {
            final wRep = rawWeekly[wIdx];
            if (wRep is Map) {
              final wId = wRep['id']?.toString() ?? 'w_$wIdx';
              final mKe = wRep['mingguKe'] ?? wRep['nomorMinggu'] ?? (wIdx + 1);
              final evId = 'timeline_weekly_${cId}_${kIdx}_$wId';

              if (!existingIds.contains(evId)) {
                DateTime wTime = DateTime(2026, 4, 26).add(Duration(days: 7 * wIdx));
                _events.add(TimelineEventModel(
                  id: evId,
                  timestamp: wTime,
                  actorName: 'MUBALLIGH, ST., M.Sc. (Inspektor)',
                  actorRole: 'Konsultan',
                  actionType: 'CREATE',
                  entityType: 'LAPORAN_MINGGUAN',
                  contractId: cId,
                  contractName: cName,
                  kegiatanId: kegId,
                  kegiatanName: kName,
                  kontraktorName: kontraktor,
                  dinasName: dinas,
                  title: 'Penerbitan Laporan Mingguan ke-$mKe: $kName',
                  description:
                      'Laporan Mingguan Periode ${wRep['periodeAwal'] ?? '-'} s.d. ${wRep['periodeAkhir'] ?? '-'}. Progres realisasi: ${wRep['realisasi'] ?? wRep['kemajuanMingguIni'] ?? '-'}%.',
                  metadata: {
                    'mingguKe': mKe,
                    'realisasi': wRep['realisasi'] ?? wRep['kemajuanMingguIni'],
                  },
                ));
                existingIds.add(evId);
                hasNewEvents = true;
              }
            }
          }
        }

        // 3d. Seluruh Addendum CCO Kegiatan
        final rawAddendums = keg['addendums'];
        if (rawAddendums is List) {
          for (int aIdx = 0; aIdx < rawAddendums.length; aIdx++) {
            final add = rawAddendums[aIdx];
            if (add is Map) {
              final noAdd = add['nomorAddendum']?.toString() ?? '${aIdx + 1}';
              final evId = 'timeline_add_${cId}_${kIdx}_$noAdd';
              // Hindari duplikasi jika Addendum 01 Ruas Jalan A sudah terdaftar dalam default seed (seed_ev_03)
              if (existingIds.contains('seed_ev_03') && (cId == 'kontrak-mt-haryono-demo' || cId == '1') && kIdx == 0 && (noAdd == '01' || noAdd == '1')) {
                continue;
              }
              if (!existingIds.contains(evId)) {
                _events.add(TimelineEventModel(
                  id: evId,
                  timestamp: DateTime(2026, 5, 12, 14, 0),
                  actorName: 'CV. Tata Saka Consultant & PPK',
                  actorRole: 'Konsultan',
                  actionType: 'UPDATE',
                  entityType: 'ADDENDUM',
                  contractId: cId,
                  contractName: cName,
                  kegiatanId: kegId,
                  kegiatanName: kName,
                  kontraktorName: kontraktor,
                  dinasName: dinas,
                  title: 'Penerbitan Addendum $noAdd ($kName)',
                  description: add['judulAddendum']?.toString() ??
                      'Penerbitan Addendum CCO Tambah Kurang volume pekerjaan.',
                  metadata: {'nomorAddendum': noAdd},
                ));
                existingIds.add(evId);
                hasNewEvents = true;
              }
            }
          }
        }

        // 3e. Seluruh Dokumen dalam Folder Kegiatan
        final rawFolders = keg['folders'];
        if (rawFolders is List) {
          for (final f in rawFolders) {
            if (f is Map && f['documents'] is List) {
              for (final doc in f['documents']) {
                if (doc is Map) {
                  final docId = doc['id']?.toString() ?? doc['name']?.toString() ?? '';
                  final evId = 'timeline_doc_${cId}_${kIdx}_$docId';
                  if (docId.isNotEmpty && !existingIds.contains(evId)) {
                    DateTime docTime = doc['uploadDate'] != null
                        ? (DateTime.tryParse(doc['uploadDate']) ?? DateTime.now())
                        : DateTime.now();
                    _events.add(TimelineEventModel(
                      id: evId,
                      timestamp: docTime,
                      actorName: 'CV. Tata Saka Consultant',
                      actorRole: 'Konsultan',
                      actionType: 'UPLOAD',
                      entityType: 'DOKUMEN',
                      contractId: cId,
                      contractName: cName,
                      kegiatanId: kegId,
                      kegiatanName: kName,
                      kontraktorName: kontraktor,
                      dinasName: dinas,
                      title: 'Unggah Dokumen: ${doc['name']}',
                      description:
                          'Dokumen ${doc['name']} (${doc['type'] ?? 'PDF'}) diunggah ke folder "${f['name']}".',
                      metadata: {'folder': f['name'], 'docType': doc['type']},
                    ));
                    existingIds.add(evId);
                    hasNewEvents = true;
                  }
                }
              }
            }
          }
        }
      }
    }

    if (hasNewEvents) {
      _sortEvents();
      await _saveEvents();
      notifyListeners();
    }
  }

  /// Mengambil event yang sudah difilter sesuai Role Pengguna, Kontrak, Kegiatan, Kategori, & Kata Kunci
  List<TimelineEventModel> getFilteredEvents({
    required UserProfileProvider userProfile,
    String? contractId,
    String? kegiatanName,
    String? category,
    String? searchQuery,
  }) {
    return _events.where((event) {
      // 1. FILTER BERDASARKAN ROLE & HAK AKSES PENGGUNA
      if (userProfile.isKontraktor) {
        final userCompany = userProfile.companyOrAgency.trim().toLowerCase();
        final userFullName = userProfile.namaLengkap.trim().toLowerCase();
        final eventKontraktor = (event.kontraktorName ?? '').trim().toLowerCase();

        // Kontraktor HANYA melihat histori dari kegiatan miliknya sendiri
        final isMatchingContractor = eventKontraktor.isNotEmpty &&
            (eventKontraktor.contains(userCompany) ||
                userCompany.contains(eventKontraktor) ||
                eventKontraktor.contains(userFullName) ||
                userFullName.contains(eventKontraktor));

        if (!isMatchingContractor) {
          return false;
        }
      } else if (userProfile.isDinas) {
        final agency = userProfile.companyOrAgency.trim().toLowerCase();
        final agencyFullName = userProfile.namaLengkap.trim().toLowerCase();
        final eventDinas = (event.dinasName ?? '').trim().toLowerCase();

        // Dinas melihat kontrak & kegiatan di bawah naungan instansi dinas terkait
        final isMatchingAgency = eventDinas.isNotEmpty &&
            (eventDinas.contains(agency) ||
                agency.contains(eventDinas) ||
                eventDinas.contains('dpu-pr') ||
                agencyFullName.contains(eventDinas));

        if (!isMatchingAgency) {
          return false;
        }
      }
      // Role Konsultan memiliki akses penuh untuk melihat semua kronologi

      // 2. FILTER KONTRAK
      if (contractId != null &&
          contractId.isNotEmpty &&
          contractId != 'semua' &&
          contractId != 'all') {
        if (event.contractId != contractId) {
          return false;
        }
      }

      // 3. FILTER KEGIATAN
      if (kegiatanName != null &&
          kegiatanName.isNotEmpty &&
          kegiatanName != 'Semua Kegiatan' &&
          kegiatanName != 'All Activities') {
        if (event.kegiatanName != kegiatanName) {
          return false;
        }
      }

      // 4. FILTER KATEGORI UTAMA
      if (category != null &&
          category.isNotEmpty &&
          category != 'Semua' &&
          category != 'All') {
        if (event.category != category) {
          return false;
        }
      }

      // 5. FILTER PENCARIAN TEKS (SEARCH QUERY)
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.trim().toLowerCase();
        final matchTitle = event.title.toLowerCase().contains(q);
        final matchDesc = event.description.toLowerCase().contains(q);
        final matchActor = event.actorName.toLowerCase().contains(q);
        final matchKegiatan = (event.kegiatanName ?? '').toLowerCase().contains(q);
        final matchContract = event.contractName.toLowerCase().contains(q);
        final matchParam = event.changes.any((c) =>
            (c['parameter'] ?? '').toLowerCase().contains(q) ||
            (c['oldValue'] ?? '').toLowerCase().contains(q) ||
            (c['newValue'] ?? '').toLowerCase().contains(q));

        if (!matchTitle &&
            !matchDesc &&
            !matchActor &&
            !matchKegiatan &&
            !matchContract &&
            !matchParam) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Data bawaan kronologi proyek (Seed Default MT Haryono)
  List<TimelineEventModel> _generateInitialSeedEvents() {
    const cId = 'kontrak-mt-haryono-demo';
    const cName = 'PEMELIHARAAN BERKALA JL. MT HARYONO';
    const dinas = 'DPU-PR Kab. Purbalingga';

    return [
      // 1. Dokumen Laporan Bulanan I
      TimelineEventModel(
        id: 'seed_ev_01',
        timestamp: DateTime(2026, 5, 18, 10, 30),
        actorName: 'SENDAYU GALIH K., ST (Site Engineer)',
        actorRole: 'Konsultan',
        actionType: 'APPROVE',
        entityType: 'LAPORAN_BULANAN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Pengesahan Laporan Bulanan Bulan I (Mei 2026)',
        description:
            'Laporan Bulanan Periode I telah disahkan bersama PPK dan Tim Konsultan Supervisi dengan kumulatif progres 40.78%.',
        metadata: {'bulanKe': 1, 'progress': 40.78},
      ),

      // 2. Laporan Mingguan ke-4
      TimelineEventModel(
        id: 'seed_ev_02',
        timestamp: DateTime(2026, 5, 17, 16, 45),
        actorName: 'MUBALLIGH, ST., M.Sc. (Inspektor)',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'LAPORAN_MINGGUAN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Penerbitan Laporan Mingguan ke-4',
        description:
            'Laporan Mingguan Periode 11 Mei - 17 Mei 2026 selesai disusun. Progres realisasi kumulatif mencapai 40.78% (Deviasi +3.28%).',
        metadata: {'mingguKe': 4, 'realisasi': 40.78, 'rencana': 37.50},
      ),

      // 3. Addendum 01 CCO (Dengan Opsi A Sebelum vs Sesudah)
      TimelineEventModel(
        id: 'seed_ev_03',
        timestamp: DateTime(2026, 5, 12, 14, 00),
        actorName: 'CV. Tata Saka Consultant & PPK DPU-PR',
        actorRole: 'Konsultan',
        actionType: 'UPDATE',
        entityType: 'ADDENDUM',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Penerbitan Addendum 01 (CCO Rekayasa Lapangan)',
        description:
            'Penyesuaian volume tambah kurang pekerjaan akibat rekayasa elevasi dan pelebaran bahu jalan. Nilai pagu kontrak tetap seimbang Rp 288.350.000,00.',
        changes: [
          {
            'parameter': 'Divisi 3.1 Galian Biasa',
            'oldValue': '210.00 m3',
            'newValue': '245.00 m3 (+35.00 m3)',
          },
          {
            'parameter': 'Divisi 5.1 Lapis Pondasi Agregat Kelas A',
            'oldValue': '180.00 m3',
            'newValue': '165.00 m3 (-15.00 m3)',
          },
          {
            'parameter': 'Divisi 6.3 Campuran Aspal Panas (AC-WC)',
            'oldValue': '95.50 Ton',
            'newValue': '102.30 Ton (+6.80 Ton)',
          },
        ],
        metadata: {'nomorAddendum': '01', 'jenis': 'CCO Tambah Kurang'},
      ),

      // 4. Laporan Mingguan ke-3
      TimelineEventModel(
        id: 'seed_ev_04',
        timestamp: DateTime(2026, 5, 10, 17, 00),
        actorName: 'MUBALLIGH, ST., M.Sc. (Inspektor)',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'LAPORAN_MINGGUAN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Penerbitan Laporan Mingguan ke-3',
        description:
            'Laporan Mingguan Periode 04 Mei - 10 Mei 2026. Progres realisasi kumulatif mencapai 29.80%.',
        metadata: {'mingguKe': 3, 'realisasi': 29.80},
      ),

      // 5. Dokumen Uji Teknis Lab
      TimelineEventModel(
        id: 'seed_ev_05',
        timestamp: DateTime(2026, 5, 05, 11, 20),
        actorName: 'Laboratorium DPU-PR Kab. Purbalingga',
        actorRole: 'Dinas',
        actionType: 'UPLOAD',
        entityType: 'DOKUMEN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Unggah Hasil Uji Kuat Tekan Beton Silinder fc 20 MPa',
        description:
            'Hasil pengujian slump test dan kuat tekan sampel beton umur 7 hari memenuhi spesifikasi teknis Bina Marga.',
        metadata: {'folder': 'Laporan Teknis & Hasil Uji Laboratorium'},
      ),

      // 6. Laporan Mingguan ke-2
      TimelineEventModel(
        id: 'seed_ev_06',
        timestamp: DateTime(2026, 5, 03, 17, 15),
        actorName: 'MUBALLIGH, ST., M.Sc. (Inspektor)',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'LAPORAN_MINGGUAN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Penerbitan Laporan Mingguan ke-2',
        description:
            'Laporan Mingguan Periode 27 April - 03 Mei 2026. Realisasi kumulatif mencapai 19.40%.',
        metadata: {'mingguKe': 2, 'realisasi': 19.40},
      ),

      // 7. Laporan Harian Ruas A
      TimelineEventModel(
        id: 'seed_ev_07',
        timestamp: DateTime(2026, 4, 28, 16, 30),
        actorName: 'BILAL, A.Md (Inspektor Lapangan)',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'LAPORAN_HARIAN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Buku Harian Standar #08: Ruas Jalan A',
        description:
            'Pekerjaan galian drainase STA 0+250 - 0+400 dan pemadatan subgrade. Cuaca cerah, tenaga kerja 12 orang.',
        metadata: {'cuaca': 'Cerah', 'tenagaKerja': 12},
      ),

      // 8. Laporan Mingguan ke-1
      TimelineEventModel(
        id: 'seed_ev_08',
        timestamp: DateTime(2026, 4, 26, 17, 00),
        actorName: 'SENDAYU GALIH K., ST (Site Engineer)',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'LAPORAN_MINGGUAN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Penerbitan Laporan Mingguan ke-1',
        description:
            'Laporan Mingguan Periode 20 April - 26 April 2026. Pekerjaan awal mobilisasi dan pengukuran rekayasa lapangan (Uitzet). Realisasi 8.50%.',
        metadata: {'mingguKe': 1, 'realisasi': 8.50},
      ),

      // 9. Input Master RKK Ruas Jalan B (CV. Langgeng)
      TimelineEventModel(
        id: 'seed_ev_09',
        timestamp: DateTime(2026, 4, 21, 11, 00),
        actorName: 'HANGGORO AJI (Administrasi Teknik)',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'RKK',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_b',
        kegiatanName: 'Ruas Jalan B',
        kontraktorName: 'CV. Langgeng',
        dinasName: dinas,
        title: 'Pengisian Master RKK / BoQ Ruas Jalan B',
        description:
            'Master Rencana Kerja Kontrak (RKK) Ruas Jalan B untuk kontraktor pelaksana CV. Langgeng telah selesai divalidasi ke sistem.',
        metadata: {'itemCount': 12},
      ),

      // 10. Input Master RKK Ruas Jalan A (CV. Divan Insan Cemerlang)
      TimelineEventModel(
        id: 'seed_ev_10',
        timestamp: DateTime(2026, 4, 21, 10, 00),
        actorName: 'HANGGORO AJI (Administrasi Teknik)',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'RKK',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Pengisian Master RKK / BoQ Ruas Jalan A',
        description:
            'Input rincian mata pembayaran BoQ 7-kolom kontrak awal Ruas MT Haryono dengan nilai fisik Rp 288.350.000,00.',
        metadata: {'itemCount': 18},
      ),

      // 11. Penetapan Kegiatan Ruas B
      TimelineEventModel(
        id: 'seed_ev_11',
        timestamp: DateTime(2026, 4, 20, 10, 30),
        actorName: 'CV. Tata Saka Consultant',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'KEGIATAN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_b',
        kegiatanName: 'Ruas Jalan B',
        kontraktorName: 'CV. Langgeng',
        dinasName: dinas,
        title: 'Penetapan Kegiatan Ruas Jalan B',
        description:
            'Penetapan paket kegiatan Ruas Letnan Sudani dengan kontraktor pelaksana CV. Langgeng.',
      ),

      // 12. Penetapan Kegiatan Ruas A
      TimelineEventModel(
        id: 'seed_ev_12',
        timestamp: DateTime(2026, 4, 20, 10, 00),
        actorName: 'CV. Tata Saka Consultant',
        actorRole: 'Konsultan',
        actionType: 'CREATE',
        entityType: 'KEGIATAN',
        contractId: cId,
        contractName: cName,
        kegiatanId: 'kegiatan_ruas_a',
        kegiatanName: 'Ruas Jalan A',
        kontraktorName: 'CV. Divan Insan Cemerlang',
        dinasName: dinas,
        title: 'Penetapan Kegiatan Ruas Jalan A',
        description:
            'Penetapan paket kegiatan Ruas Letjen MT Haryono dengan kontraktor pelaksana CV. Divan Insan Cemerlang.',
      ),

      // 13. Pembuatan Kontrak Induk (SPK & SPMK)
      TimelineEventModel(
        id: 'seed_ev_13',
        timestamp: DateTime(2026, 4, 20, 08, 30),
        actorName: 'PPK Bina Marga DPU-PR Kab. Purbalingga',
        actorRole: 'Dinas',
        actionType: 'CREATE',
        entityType: 'KONTRAK',
        contractId: cId,
        contractName: cName,
        dinasName: dinas,
        title: 'Penerbitan SPK & SPMK Kontrak Pengawasan',
        description:
            'Penerbitan Surat Perintah Kerja (SPK) Nomor 000.3.2/1691.1/WAS-21/SPK-BM/1.03.10.2.01.0056/2026 untuk pekerjaan pengawasan teknis 90 hari kalender.',
        metadata: {
          'nomorSpk': '000.3.2/1691.1/WAS-21/SPK-BM/1.03.10.2.01.0056/2026',
          'nomorSpmk': '000.3.2/1691.1/WAS-21/SPMK-BM/1.03.10.2.01.0056/2026',
          'pagu': 'Rp 288.350.000,00',
        },
      ),
    ];
  }
}
