import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/timeline_event_model.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/utils/contract_access.dart';

class TimelineProvider with ChangeNotifier {
  static const String _storageKey = 'tata_saka_timeline_events_v1';

  /// Koleksi cloud: `timeline_events` (doc id = event id).
  /// Semua perangkat berbagi riwayat yang sama; SharedPreferences hanya
  /// fallback offline & mirror cadangan.
  static const String _cloudCollection = 'timeline_events';

  /// Firestore diakses lazy & aman (null saat Firebase belum init / test).
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  List<TimelineEventModel> _events = [];

  /// Kontrak terakhir yang dimuat, dipakai menentukan hak akses timeline
  /// lewat `dinasUid` (kontrak) dan `kontraktorUid` (kegiatan).
  final Map<String, ContractModel> _contractsById = {};
  bool _isLoading = true;

  /// Future pemuatan yang sedang berjalan (dipakai `ensureLoaded`).
  Future<void>? _loadFuture;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _eventsSub;

  /// UID yang timeline-nya sudah dimuat penuh pada sesi ini — mencegah
  /// pembacaan ulang seluruh koleksi `timeline_events`.
  String? _loadedUid;
  bool _loadInFlight = false;
  bool _disposed = false;

  /// Jumlah event per halaman. Timeline hanya membaca halaman terbaru; sisa
  /// riwayat dimuat saat pengguna menekan "Muat lebih banyak".
  static const int _pageSize = 100;
  DocumentSnapshot<Map<String, dynamic>>? _pageCursor;
  bool _hasMore = true;
  bool _loadingMore = false;

  bool get hasMoreEvents => _hasMore;
  bool get isLoadingMoreEvents => _loadingMore;

  /// UID sesi Firebase Auth saat ini ('' bila belum login / belum init).
  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  bool get isLoading => _isLoading;
  List<TimelineEventModel> get allEvents => List.unmodifiable(_events);

  TimelineProvider({bool seedDefaultIfEmpty = false}) {
    _loadFuture = loadEvents(seedDefaultIfEmpty: seedDefaultIfEmpty);
    // Muat ulang & berlangganan realtime begitu sesi login Firebase Auth
    // tersedia (sebelum login, rules menolak baca → timeline hanya terisi lokal).
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          // Tunggu pembacaan awal selesai agar tidak berjalan bersamaan.
          if (_loadInFlight) await ensureLoaded();
          _loadFuture = loadEvents();
          _listenCloud();
        } else {
          // Logout → sesi berikutnya boleh memuat ulang timeline-nya sendiri.
          _loadedUid = null;
          _pageCursor = null;
          _hasMore = true;
        }
      });
    } catch (_) {
      // Firebase belum init (test) → abaikan.
    }
  }

  /// Langganan realtime ke koleksi `timeline_events` supaya seluruh event yang
  /// tersimpan di Firestore (termasuk hasil `logEvent`) langsung tampil, tanpa
  /// bergantung pada timing baca saat aplikasi/login pertama kali dibuka.
  void _listenCloud() {
    if (_eventsSub != null) return;
    final db = _db;
    if (db == null) return;
    try {
      _eventsSub = db
          .collection(_cloudCollection)
          .orderBy('timestamp', descending: true)
          .limit(_pageSize)
          .snapshots()
          .listen(_onCloudSnapshot, onError: (e) {
        debugPrint('[TimelineProvider] Snapshot error: $e');
        _eventsSub = null;
      });
    } catch (e) {
      debugPrint('[TimelineProvider] Gagal berlangganan timeline: $e');
    }
  }

  /// Gabungkan event dari cloud dengan yang sudah ada di memori (event lokal
  /// yang belum sempat terkirim tidak ikut terhapus).
  void _onCloudSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    if (snap.docs.isEmpty) return;
    final merged = <String, TimelineEventModel>{
      for (final e in _events) e.id: e,
    };
    for (final d in snap.docs) {
      final data = Map<String, dynamic>.from(d.data());
      data['id'] = d.id;
      merged[d.id] = TimelineEventModel.fromJson(data);
    }
    _events = merged.values.toList();
    _sortEvents();
    _isLoading = false;
    _saveEvents();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    _eventsSub?.cancel();
    super.dispose();
  }

  /// Menunggu pemuatan awal selesai agar hasil `syncWithContracts` tidak
  /// tertimpa oleh respons Firestore yang datang terlambat.
  Future<void> ensureLoaded() async {
    final pending = _loadFuture;
    if (pending == null) return;
    try {
      await pending;
    } catch (_) {}
  }

  /// Memuat riwayat timeline: utama dari Firestore, fallback ke SharedPreferences
  /// (mode offline / lingkungan test). Data lokal lama otomatis dimigrasikan ke cloud.
  Future<void> loadEvents({bool seedDefaultIfEmpty = false}) async {
    final uid = _currentUid;
    if (_loadInFlight) {
      // Pemuatan sedang berjalan → tunggu, agar pemanggil tetap mendapat data.
      await ensureLoaded();
      return;
    }
    // Sesi ini sudah dimuat penuh → cukup pastikan listener realtime hidup.
    if (uid.isNotEmpty && _loadedUid == uid) {
      if (_eventsSub == null) _listenCloud();
      return;
    }
    _loadInFlight = true;
    _isLoading = true;
    _pageCursor = null;
    _hasMore = true;
    try {
      final db = _db;
      if (db != null) {
        final snap = await db
            .collection(_cloudCollection)
            .orderBy('timestamp', descending: true)
            .limit(_pageSize)
            .get();
        if (snap.docs.isNotEmpty) {
          var cloudEvents = snap.docs.map((d) {
            final data = Map<String, dynamic>.from(d.data());
            data['id'] = d.id;
            return TimelineEventModel.fromJson(data);
          }).toList();
          // Cloud sudah bersih dari seed lama (seeder dinonaktifkan).
          // Tidak ada filter di sini — tampilkan semua event dari Firestore apa adanya.
          if (cloudEvents.isNotEmpty || !seedDefaultIfEmpty) {
            _events = cloudEvents;
            _sortEvents();
            _saveEvents(); // mirror lokal tanpa menunggu
            if (uid.isNotEmpty) _loadedUid = uid;
            _pageCursor = snap.docs.isNotEmpty ? snap.docs.last : null;
            _hasMore = snap.docs.length >= _pageSize;
            return;
          }
        }
      }
      // Cloud kosong / tidak tersedia → muat lokal (tanpa auto-seed dummy secara default)
      await _loadFromLocal(seedDefaultIfEmpty: seedDefaultIfEmpty);
      // Migrasikan isi lokal ke cloud agar lintas perangkat
      final db2 = _db;
      if (db2 != null && !seedDefaultIfEmpty) {
        if (uid.isNotEmpty) _loadedUid = uid;
        if (_events.isNotEmpty) await _pushEventsToCloud(_events);
      }
    } catch (e) {
      // Jangan kosongkan timeline hanya karena baca cloud gagal (offline /
      // rules menolak sebelum login) — pakai mirror lokal sebagai fallback.
      debugPrint('Error loading timeline events: $e');
      try {
        await _loadFromLocal(seedDefaultIfEmpty: seedDefaultIfEmpty);
      } catch (e2) {
        debugPrint('Error loading timeline local mirror: $e2');
        _events = seedDefaultIfEmpty ? _generateInitialSeedEvents() : [];
      }
    } finally {
      _loadInFlight = false;
      _isLoading = false;
      if (!_disposed) notifyListeners();
      // Setelah baca awal selesai, jaga data tetap sinkron secara realtime.
      if (_eventsSub == null) _listenCloud();
    }
  }

  /// Muat halaman berikutnya (event yang lebih lama). Hanya membaca 100
  /// dokumen saat tombol "Muat lebih banyak" benar-benar ditekan.
  Future<void> loadMoreEvents() async {
    final db = _db;
    if (db == null || _loadingMore || !_hasMore) return;
    _loadingMore = true;
    if (!_disposed) notifyListeners();
    try {
      var query = db
          .collection(_cloudCollection)
          .orderBy('timestamp', descending: true);
      if (_pageCursor != null) {
        query = query.startAfterDocument(_pageCursor!);
      }
      final snap = await query.limit(_pageSize).get();
      final merged = <String, TimelineEventModel>{
        for (final e in _events) e.id: e,
      };
      for (final d in snap.docs) {
        final data = Map<String, dynamic>.from(d.data());
        data['id'] = d.id;
        merged[d.id] = TimelineEventModel.fromJson(data);
      }
      _events = merged.values.toList();
      _sortEvents();
      await _saveEvents();
      if (snap.docs.isNotEmpty) _pageCursor = snap.docs.last;
      _hasMore = snap.docs.length >= _pageSize;
    } catch (e) {
      debugPrint('Gagal memuat halaman timeline berikutnya: $e');
    }
    _loadingMore = false;
    if (!_disposed) notifyListeners();
  }

  /// Muat dari SharedPreferences (perilaku lama).
  Future<void> _loadFromLocal({bool seedDefaultIfEmpty = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getString(_storageKey);
    if (rawData != null && rawData.isNotEmpty) {
      final List<dynamic> decoded = jsonDecode(rawData);
      var loaded = decoded
          .map((item) => TimelineEventModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      if (loaded.isEmpty && seedDefaultIfEmpty) {
        _events = _generateInitialSeedEvents();
        await _saveEvents();
      } else {
        _events = loaded;
      }
    } else {
      _events = seedDefaultIfEmpty ? _generateInitialSeedEvents() : [];
      await _saveEvents();
    }
    _sortEvents();
  }

  /// Mirror cadangan ke SharedPreferences (dipakai saat offline).
  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_events.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Error saving timeline events: $e');
    }
  }

  /// Tulis daftar event ke Firestore (batch, dedupe by doc id).
  Future<void> _pushEventsToCloud(List<TimelineEventModel> events) async {
    final db = _db;
    if (db == null || events.isEmpty) return;
    try {
      final batch = db.batch();
      for (final e in events) {
        batch.set(db.collection(_cloudCollection).doc(e.id), e.toJson());
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Cloud push timeline gagal (offline?): $e');
    }
  }

  Future<void> _deleteEventFromCloud(String id) async {
    final db = _db;
    if (db == null) return;
    try {
      await db.collection(_cloudCollection).doc(id).delete();
    } catch (_) {}
  }

  /// Hapus seluruh koleksi cloud (untuk reset/clear).
  Future<void> _wipeCloud() async {
    final db = _db;
    if (db == null) return;
    try {
      final snap = await db.collection(_cloudCollection).get();
      if (snap.docs.isEmpty) return;
      final batch = db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    } catch (_) {}
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
    // Waktu event tidak boleh melewati waktu sekarang: aktivitas yang belum
    // terjadi akan selalu nangkring di atas timeline dan menutupi aksi terbaru.
    final now = DateTime.now();
    final eventTime =
        (customTimestamp == null || customTimestamp.isAfter(now))
            ? now
            : customTimestamp;
    final event = TimelineEventModel(
      id: 'timeline_${now.millisecondsSinceEpoch}_${_events.length + 1}',
      timestamp: eventTime,
      actorName: actorName,
      actorRole: actorRole,
      actionType: actionType,
      entityType: entityType,
      contractId: contractId,
      contractName: contractName,
      kegiatanId: kegiatanId,
      kegiatanName: kegiatanName,
      kontraktorName: kontraktorName,
      dinasName: dinasName,
      title: title,
      description: description,
      changes: changes,
      metadata: metadata,
    );

    _events.insert(0, event);
    _sortEvents();
    await _saveEvents();
    await _pushEventsToCloud([event]);
    notifyListeners();
  }

  /// Hapus event tertentu (dari memori, mirror lokal, dan cloud)
  Future<void> deleteEvent(String id) async {
    _events.removeWhere((e) => e.id == id);
    await _saveEvents();
    await _deleteEventFromCloud(id);
    notifyListeners();
  }

  /// Reset timeline ke seed default bawaan
  Future<void> resetToDefaultEvents() async {
    _events = _generateInitialSeedEvents();
    _sortEvents();
    await _saveEvents();
    await _wipeCloud();
    await _pushEventsToCloud(_events);
    notifyListeners();
  }

  /// Hapus semua event
  Future<void> clearEvents() async {
    _events.clear();
    await _saveEvents();
    await _wipeCloud();
    notifyListeners();
  }

  /// Rekonsiliasi & Sinkronisasi dinamis seluruh aktivitas dari ContractProvider
  /// Memastikan seluruh laporan harian (misal tanggal 21, 22, 23), mingguan, addendum, dan dokumen
  /// terdaftar lengkap di Timeline dengan tanggal & waktu yang akurat.
  Future<void> syncWithContracts(List<ContractModel> contracts) async {
    _contractsById
      ..clear()
      ..addEntries(contracts.map((c) => MapEntry(c.id, c)));
    var totalLaporan = 0;
    for (final c in contracts) {
      for (final keg in c.kegiatans) {
        totalLaporan += ((keg['laporans'] as List?)?.length ?? 0) +
            ((keg['laporanMingguan'] as List?)?.length ?? 0);
      }
    }
    // Rekonsiliasi (hapus event laporan basi) hanya boleh berjalan bila data
    // kontrak DAN laporan benar-benar sudah termuat. Bila belum, daftar
    // "diharapkan" kosong dan SEMUA event laporan akan terhapus massal.
    final canReconcile = contracts.isNotEmpty && totalLaporan > 0;
    await ensureLoaded();
    bool hasNewEvents = false;
    final Set<String> existingIds = _events.map((e) => e.id).toSet();
    final Set<String> beforeIds = Set<String>.from(existingIds);

    // Semua id event laporan yang diharapkan ada setelah sync ini —
    // dipakai untuk membersihkan event basi/duplikat/terhapus.
    final expectedReportEventIds = <String>{};

    // Event sintetis "Penetapan Kegiatan" yang sudah diwakili event asli
    // (hasil logEvent saat kegiatan ditambahkan) dan harus dibuang.
    final staleKegEventIds = <String>{};

    for (final c in contracts) {
      final cId = c.id;
      final cName = c.namaKontrak;
      final dinas = c.instansiDinas.isNotEmpty ? c.instansiDinas.first : '';

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
        // Event "Penetapan Kegiatan" sudah dicatat saat pengguna menambahkan
        // kegiatan (DetailKontrakScreen._addKegiatan). Bila event asli itu
        // ada, event sintetis tidak dibuat dan sisa event sintetis lama
        // (yang dulu bertanggal tetap 18 April 2026) dibersihkan agar
        // timeline tidak menampilkan dua penetapan untuk kegiatan yang sama.
        final kegEventId = 'timeline_keg_create_${cId}_$kIdx';
        final hasLoggedKegEvent = _events.any((e) =>
            e.id != kegEventId &&
            e.contractId == cId &&
            (e.kegiatanName ?? '').trim() == kName.trim() &&
            e.title.startsWith('Penetapan Kegiatan:'));
        if (hasLoggedKegEvent) {
          if (existingIds.contains(kegEventId)) {
            staleKegEventIds.add(kegEventId);
          }
        } else if (!existingIds.contains(kegEventId)) {
          final kegTime = _kegiatanCreatedAt(keg, c) ?? DateTime.now();
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
              // ID stabil: TANPA kIdx — urutan kegiatan bergeser tidak lagi
              // meregenerasi event duplikat.
              final evId = 'timeline_daily_${cId}_$repId';
              expectedReportEventIds.add(evId);

              if (!existingIds.contains(evId)) {
                // Waktu kejadian sebenarnya: waktu pembuatan dokumen di
                // Firestore → createdAt → tanggal+jam laporan.
                DateTime? repDate = DateTime.tryParse(rep['docCreateTime']?.toString() ?? '')?.toLocal() ??
                    DateTime.tryParse(rep['createdAt']?.toString() ?? '')?.toLocal();
                if (repDate == null) {
                  repDate = DateTime.tryParse(tglStr) ?? DateTime.now();
                  final jamStr = rep['jam']?.toString() ?? '';
                  final jm = jamStr.split(':');
                  if (jm.length == 2) {
                    final h = int.tryParse(jm[0].trim()) ?? 0;
                    final m = int.tryParse(jm[1].trim()) ?? 0;
                    repDate = DateTime(repDate.year, repDate.month, repDate.day, h, m);
                  }
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
              // ID stabil: TANPA kIdx.
              final evId = 'timeline_weekly_${cId}_$wId';
              expectedReportEventIds.add(evId);

              if (!existingIds.contains(evId)) {
                // Waktu kejadian sebenarnya (waktu buat dokumen di Firestore).
                DateTime wTime = DateTime.tryParse(wRep['docCreateTime']?.toString() ?? '')?.toLocal() ??
                    DateTime.tryParse(wRep['createdAt']?.toString() ?? '')?.toLocal() ??
                    DateTime(2026, 4, 26).add(Duration(days: 7 * wIdx));
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

    // Hapus event sintetis penetapan kegiatan yang kini sudah diwakili oleh
    // event asli, supaya tidak muncul sebagai riwayat ganda.
    if (staleKegEventIds.isNotEmpty) {
      _events.removeWhere((e) => staleKegEventIds.contains(e.id));
      existingIds.removeAll(staleKegEventIds);
      await _saveEvents();
      final db = _db;
      if (db != null) {
        try {
          final batch = db.batch();
          for (final id in staleKegEventIds) {
            batch.delete(db.collection(_cloudCollection).doc(id));
          }
          await batch.commit();
        } catch (e) {
          debugPrint(
              '[TimelineProvider] Gagal hapus event penetapan sintetis: $e');
        }
      }
      notifyListeners();
    }

    if (hasNewEvents) {
      _sortEvents();
      await _saveEvents();
      // Dorong hanya event yang benar-benar baru ke cloud (id deterministik
      // membuat dedupe antar perangkat otomatis).
      final added = _events.where((e) => !beforeIds.contains(e.id)).toList();
      await _pushEventsToCloud(added);
      notifyListeners();
    }

    // ── Reconcile: bersihkan event laporan basi/duplikat/terhapus ──
    // Menghapus event tersimpan (format lama berkIdx, event laporan yang
    // sudah dihapus user, dsb.) yang tidak lagi cocok dengan daftar
    // laporan sekarang. Hanya menyentuh event berpola laporan — event
    // aksi user (logEvent) dan event lain tidak tersentuh.
    final staleReportEvents = !canReconcile
        ? <TimelineEventModel>[]
        : _events
            .where((e) =>
                (e.id.startsWith('timeline_daily_') ||
                    e.id.startsWith('timeline_weekly_')) &&
                !expectedReportEventIds.contains(e.id))
            .toList();
    if (staleReportEvents.isNotEmpty) {
      final db = _db;
      if (db == null) return;
      try {
        final batch = db.batch();
        for (final e in staleReportEvents) {
          batch.delete(db.collection('timeline_events').doc(e.id));
          _events.remove(e);
        }
        await batch.commit();
        _sortEvents();
        notifyListeners();
        debugPrint(
            '[TimelineProvider] ${staleReportEvents.length} event laporan basi dibersihkan');
      } catch (e) {
        debugPrint('[TimelineProvider] Reconcile gagal: $e');
      }
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
      // Penentu utama: `dinasUid` pada kontrak dan `kontraktorUid` pada
      // kegiatan. Nama hanya dipakai sebagai cadangan untuk event lama yang
      // kontraknya sudah tidak ada di memori.
      if (userProfile.isKontraktor &&
          !_visibleToKontraktor(event, userProfile)) {
        return false;
      }
      if (userProfile.isDinas && !_visibleToDinas(event, userProfile)) {
        return false;
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

  /// Waktu pembuatan kegiatan bila tercatat pada datanya; cadangan tanggal
  /// mulai kontrak, dan tidak pernah melewati waktu sekarang.
  DateTime? _kegiatanCreatedAt(
    Map<String, dynamic> keg,
    ContractModel contract,
  ) {
    DateTime? time;
    for (final key in const [
      'createdAt',
      'docCreateTime',
      'tanggalDibuat',
      'timestamp',
    ]) {
      time = DateTime.tryParse(keg[key]?.toString() ?? '')?.toLocal();
      if (time != null) break;
    }
    time ??= DateTime.tryParse(contract.tglMulaiSpk);
    time ??= DateTime.tryParse(contract.tglMulaiSpmk);
    final now = DateTime.now();
    if (time == null) return now;
    return time.isAfter(now) ? now : time;
  }

  /// Kontrak sumber event, bila masih termuat di memori.
  ContractModel? _contractOf(TimelineEventModel event) =>
      _contractsById[event.contractId];

  /// Kegiatan yang dirujuk event: cocokkan nama dulu, lalu id `keg_<kontrak>_<idx>`.
  Map<String, dynamic>? _kegiatanOf(
    ContractModel contract,
    TimelineEventModel event,
  ) {
    final nama = (event.kegiatanName ?? '').trim();
    if (nama.isNotEmpty) {
      for (final keg in contract.kegiatans) {
        if ((keg['namaKegiatan'] ?? '').toString().trim() == nama) return keg;
      }
    }
    final id = (event.kegiatanId ?? '').trim();
    if (id.startsWith('keg_')) {
      final idx = int.tryParse(id.split('_').last);
      if (idx != null && idx >= 0 && idx < contract.kegiatans.length) {
        return contract.kegiatans[idx];
      }
    }
    return null;
  }

  /// Event hanya terlihat oleh kontraktor yang ditugaskan pada kegiatannya.
  bool _visibleToKontraktor(
    TimelineEventModel event,
    UserProfileProvider user,
  ) {
    final contract = _contractOf(event);
    if (contract != null) {
      final keg = _kegiatanOf(contract, event);
      // Event tingkat kontrak (tanpa kegiatan) tidak dimiliki kontraktor.
      if (keg == null) return false;
      return ContractAccess.kegiatanOwnedByKontraktor(
        keg,
        contractorUid: user.uid,
        fullName: user.namaLengkap,
        companyOrAgency: user.companyOrAgency,
        username: user.username,
      );
    }
    // Event lama/asing: cocokkan nama dengan aturan token yang sama, sehingga
    // nama kosong tidak lagi dianggap cocok dengan semua event.
    final kontraktor = (event.kontraktorName ?? '').trim();
    if (kontraktor.isEmpty) return false;
    return ContractAccess.kegiatanOwnedByKontraktor(
      {'kontraktor': kontraktor},
      contractorUid: user.uid,
      fullName: user.namaLengkap,
      companyOrAgency: user.companyOrAgency,
      username: user.username,
    );
  }

  /// Event hanya terlihat oleh dinas pemilik kontrak (`dinasUid`).
  bool _visibleToDinas(TimelineEventModel event, UserProfileProvider user) {
    final contract = _contractOf(event);
    if (contract != null) {
      return contract.isOwnedByDinas(
        dinasUserUid: user.uid,
        companyOrAgency: user.companyOrAgency,
        userFullName: user.namaLengkap,
      );
    }
    // Fallback data lama: nama instansi, tanpa pengecualian 'dpu-pr' lagi.
    final eventDinas = (event.dinasName ?? '').trim().toLowerCase();
    final agency = user.companyOrAgency.trim().toLowerCase();
    final fullName = user.namaLengkap.trim().toLowerCase();
    if (eventDinas.isEmpty || (agency.isEmpty && fullName.isEmpty)) {
      return false;
    }
    final matchAgency = agency.isNotEmpty &&
        (eventDinas.contains(agency) || agency.contains(eventDinas));
    final matchFullName = fullName.isNotEmpty &&
        (eventDinas.contains(fullName) || fullName.contains(eventDinas));
    return matchAgency || matchFullName;
  }

  /// Data bawaan kronologi proyek (MT Haryono dinonaktifkan permanen)
  List<TimelineEventModel> _generateInitialSeedEvents() => [];

  List<TimelineEventModel> _unusedSeedEventsRemoved() {
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
