import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';
import 'dart:math';

/// Provider Kontrak — persisten ke Cloud Firestore (proyek tatasakaconsultant-id,
/// lokasi asia-southeast2 / Jakarta).
///
/// Arsitektur (mengikuti aplikasi sebagai patokan):
/// - `contracts/{cid}`                : metadata kontrak + kegiatans (RKK, addendum,
///                                      struktur organisasi, SKELETON folder) TANPA
///                                      array laporan & tanpa isi dokumen.
/// - `contracts/{cid}/laporans`       : laporan harian per dokumen.
/// - `contracts/{cid}/laporanMingguan`: laporan mingguan per dokumen.
/// - `contracts/{cid}/dokumen`        : dokumen administrasi per berkas
///                                      (folderName, kegiatanId?, remoteUrl, ...).
/// - `timeline_events`                : kronologi lintas perangkat.
/// - Laporan Bulanan                   : turunan otomatis dari data mingguan di UI.
///
/// Realtime: listener `contracts.snapshots()` menampilkan perubahan perangkat lain
/// seketika (dengan no-op bila perubahan hanyalah pantulan tulisan sendiri).
class ContractProvider with ChangeNotifier {
  /// Firestore diakses lazy: hanya saat operasi nyata berjalan (di dalam try),
  /// sehingga konstruktor tetap aman di lingkungan test / belum init Firebase.
  final FirebaseFirestore? _injectedDb;
  List<ContractModel> _contracts = [];
  bool _isLoading = false;

  /// Cache untuk diff tulisan: cid -> {docId: json terakhir yang tersimpan}
  final Map<String, Map<String, String>> _reportDocCache = {};
  final Map<String, Map<String, String>> _weeklyDocCache = {};
  final Map<String, Map<String, String>> _dokumenDocCache = {};

  /// cid -> {docId} yang di-soft-delete oleh perangkat ini
  final Map<String, Set<String>> _deletedDocIds = {};

  /// cid -> JSON terakhir yang DITULIS perangkat ini. Dipakai untuk mengenali
  /// pantulan tulisan sendiri pada listener `contracts`, supaya tidak memicu
  /// pembacaan ulang laporan & dokumen kontrak yang tidak berubah.
  final Map<String, String> _lastWrittenJson = {};

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _contractsSub;
  final Map<String, StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _dokumenSubs = {};
  bool _snapshotRebuilding = false;

  /// UID yang datanya sudah dimuat penuh pada sesi ini — mencegah pembacaan
  /// ulang seluruh koleksi (kontrak + laporan + dokumen) di sesi yang sama.
  String? _loadedUid;
  bool _loadInFlight = false;
  Future<void>? _loadFuture;
  bool _disposed = false;
  StreamSubscription<User?>? _authSub;

  bool get isLoading => _isLoading;

  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;

  /// UID sesi Firebase Auth saat ini ('' bila belum login / belum init).
  String get _currentUid {
    try {
      return FirebaseAuth.instance.currentUser?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Kunci mirror lokal khusus akun ini. Tidak memakai kunci global `contracts`
  /// agar data satu akun tidak terbaca akun lain di perangkat/browser yang sama
  /// (di web, SharedPreferences = localStorage yang tidak terpisah per akun).
  String get _localContractsKey {
    final uid = _currentUid;
    return uid.isEmpty ? '' : 'contracts_$uid';
  }

  ContractProvider({FirebaseFirestore? db}) : _injectedDb = db {
    _loadFromLocalFallback().then((_) {
      _loadFuture = _loadContracts();
    });
    // Muat ulang dari Firestore begitu sesi login Firebase Auth tersedia
    // (sebelum login, rules menolak baca → fallback lokal dipakai sementara).
    try {
      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          // Tunggu pembacaan awal selesai agar tidak berjalan bersamaan.
          if (_loadInFlight && _loadFuture != null) await _loadFuture;
          _loadFuture = _loadContracts();
        } else {
          // Logout → jangan tinggalkan data akun sebelumnya di memori/layar.
          _loadedUid = null;
          _contracts = [];
          for (final sub in _dokumenSubs.values) {
            sub.cancel();
          }
          _dokumenSubs.clear();
          if (!_disposed) notifyListeners();
        }
      });
    } catch (_) {
      // Firebase belum init (test) → abaikan.
    }
    // Realtime: perubahan dari perangkat lain langsung tampil (A).
    try {
      _contractsSub = _db.collection('contracts').snapshots().listen((snap) {
        _onContractsSnapshot(snap);
      }, onError: (e) {
        debugPrint('[ContractProvider] Snapshot error: $e');
      });
    } catch (_) {
      // Firebase belum init (test) → abaikan.
    }
  }

  /// Rebuild cerdas saat ada perubahan dari perangkat lain: tampil seketika,
  /// tapi no-op bila perubahan hanyalah pantulan tulisan perangkat ini sendiri
  /// (mencegah loop & menjaga referensi objek yang sedang dipegang layar).
  /// Optimasi: hanya kontrak yang BENAR-BENAR berubah yang di-hydrate ulang
  /// (bukan semua kontrak pada setiap event).
  Future<void> _onContractsSnapshot(
      QuerySnapshot<Map<String, dynamic>> snap) async {
    if (_isLoading || _snapshotRebuilding) return;
    try {
      // Kumpulkan kontrak yang benar-benar berubah isinya.
      final changed = <String, Map<String, dynamic>>{};
      final changedJson = <String, String>{};
      final removedIds = <String>{};
      bool anyRealChange = false;

      for (final ch in snap.docChanges) {
        final id = ch.doc.id;
        if (ch.type == DocumentChangeType.removed) {
          removedIds.add(id);
          anyRealChange = anyRealChange ||
              _contracts.any((x) => x.id == id);
          continue;
        }
        final raw = ch.doc.data();
        if (raw == null) continue;
        final data = Map<String, dynamic>.from(raw);
        data['id'] = id;
        final candidate = ContractModel.fromJson(data);
        final json = _comparisonJson(candidate);
        changed[id] = data;
        changedJson[id] = json;

        final idx = _contracts.indexWhere((x) => x.id == id);
        if (idx < 0) {
          anyRealChange = true; // kontrak baru
        } else if (_comparisonJson(_contracts[idx]) != json) {
          anyRealChange = true; // isi benar-benar beda
        }
        // Identik = pantulan ack tulisan sendiri → diabaikan.
      }
      // Kontrak yang hilang dari snapshot (dihapus perangkat lain).
      for (final x in _contracts) {
        if (!snap.docs.any((d) => d.id == x.id)) {
          removedIds.add(x.id);
          anyRealChange = true;
        }
      }
      if (!anyRealChange) return;

      _snapshotRebuilding = true;
      // Terapkan: hydrate HANYA kontrak yang berubah.
      for (final id in changed.keys) {
        final data = changed[id]!;
        // Pantulan tulisan perangkat ini sendiri → memori sudah paling baru,
        // jadi tidak perlu membaca ulang laporan & dokumen kontrak tersebut.
        if (_lastWrittenJson[id] != null &&
            _lastWrittenJson[id] == changedJson[id]) {
          continue;
        }
        final c = ContractModel.fromJson(data);
        _ensureKegiatanIds(c);
        await _hydrateReports(c);
        await _hydrateDokumen(c);
        final idx = _contracts.indexWhere((x) => x.id == id);
        if (idx >= 0) {
          // Lindungi laporan di memori jika hydrated snapshot sementara kosong
          final old = _contracts[idx];
          for (int ki = 0; ki < c.kegiatans.length; ki++) {
            if (ki < old.kegiatans.length) {
              final oldKeg = old.kegiatans[ki];
              final newKeg = c.kegiatans[ki];
              final oldLaps = (oldKeg['laporans'] as List?) ?? [];
              final newLaps = (newKeg['laporans'] as List?) ?? [];
              if (newLaps.isEmpty && oldLaps.isNotEmpty) {
                newKeg['laporans'] = oldLaps;
              }
              final oldWeek = (oldKeg['laporanMingguan'] as List?) ?? [];
              final newWeek = (newKeg['laporanMingguan'] as List?) ?? [];
              if (newWeek.isEmpty && oldWeek.isNotEmpty) {
                newKeg['laporanMingguan'] = oldWeek;
              }
            }
          }
          _contracts[idx] = c;
        } else {
          _contracts.add(c);
        }
      }
      for (final id in removedIds) {
        _contracts.removeWhere((x) => x.id == id);
        _dokumenSubs.remove(id)?.cancel();
        _dokumenDocCache.remove(id);
        _deletedDocIds.remove(id);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[ContractProvider] Snapshot rebuild gagal: $e');
    } finally {
      _snapshotRebuilding = false;
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // LOAD
  // ═════════════════════════════════════════════════════════════════════

  Future<void> _loadContracts() async {
    final uid = _currentUid;
    if (_loadInFlight) return;
    // Sesi ini sudah dimuat penuh → jangan baca ulang seluruh data.
    if (uid.isNotEmpty && _loadedUid == uid) {
      _attachDokumenListeners();
      return;
    }
    _loadInFlight = true;
    _isLoading = true;
    notifyListeners();

    bool loaded = false;
    try {
      final snap = await _db.collection('contracts').get();
      if (snap.docs.isEmpty) {
        // Jangan auto-seed: biarkan database bersih tanpa injeksi data dummy otomatis.
        _contracts = [];
      } else {
        final list = <ContractModel>[];
        for (final doc in snap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          final contract = ContractModel.fromJson(data);
          _ensureKegiatanIds(contract);
          await _hydrateReports(contract);
          await _hydrateDokumen(contract);
          list.add(contract);
        }
        _contracts = list;
      }
      loaded = true;
    } catch (e) {
      debugPrint('[ContractProvider] Firestore gagal, pakai data lokal: $e');
      await _loadFromLocalFallback();
    }

    if (loaded && uid.isNotEmpty) _loadedUid = uid;
    _isLoading = false;
    _loadInFlight = false;
    if (!_disposed) notifyListeners();
    _attachDokumenListeners();
  }

  /// Listener realtime per-subcollection `dokumen` — perubahan dokumen dari
  /// perangkat lain tampil seketika tanpa restart.
  void _attachDokumenListeners() {
    try {
      final ids = _contracts.map((c) => c.id).toSet();
      for (final c in _contracts) {
        if (_dokumenSubs.containsKey(c.id)) continue;
        _dokumenSubs[c.id] = _db
            .collection('contracts')
            .doc(c.id)
            .collection('dokumen')
            .snapshots()
            .listen((snap) {
          if (_isLoading || _snapshotRebuilding) return;
          for (final x in _contracts) {
            if (x.id != c.id) continue;
            // Pakai isi snapshot yang sudah diterima — tanpa `.get()` tambahan.
            _hydrateDokumen(x, snapshot: snap).then((_) {
              if (!_disposed) notifyListeners();
            });
          }
        }, onError: (e) {
          debugPrint('[ContractProvider] Dokumen snapshot error: $e');
        });
      }
      // Copot listener kontrak yang sudah dihapus.
      for (final cid in List<String>.from(_dokumenSubs.keys)) {
        if (!ids.contains(cid)) {
          _dokumenSubs.remove(cid)?.cancel();
        }
      }
    } catch (e) {
      debugPrint('[ContractProvider] Attach dokumen listener gagal: $e');
    }
  }

  /// Fallback offline: baca mirror JSON di SharedPreferences.
  Future<void> _loadFromLocalFallback() async {
    try {
      final key = _localContractsKey;
      if (key.isEmpty) {
        // Sesi belum diketahui → jangan tampilkan mirror milik akun lain.
        _contracts = [];
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final String? contractsJson = prefs.getString(key);
      if (contractsJson != null) {
        final List<dynamic> decoded = jsonDecode(contractsJson);
        _contracts = decoded
            .map((item) => ContractModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        _contracts = [];
      }
    } catch (_) {
      _contracts = [];
    }
  }

  /// Mirror cadangan ke SharedPreferences (dipakai saat offline).
  Future<void> _saveLocalBackup() async {
    try {
      final key = _localContractsKey;
      if (key.isEmpty) return;
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_contracts.map((c) => c.toJson()).toList());
      await prefs.setString(key, encoded);
    } catch (_) {}
  }

  // ═════════════════════════════════════════════════════════════════════
  // SEEDING DATA DEMO (aplikasi = patokan untuk data demo)
  // ═════════════════════════════════════════════════════════════════════

  /// Deteksi data demo lama (belum punya Addendum CCO / harga satuan RKK /
  /// laporan harian belum hidrate) → perlu disegarkan dari dataset aplikasi.
  bool _isOldDemoData(ContractModel c) {
    if (c.kegiatans.isEmpty) return true;
    final keg = c.kegiatans.first;
    final rkk = keg['rkkDivisiList'] as List? ?? [];
    if (rkk.isEmpty) return true;
    final items = (rkk.first as Map)['items'] as List? ?? [];
    if (items.isEmpty || ((items.first as Map)['hargaSatuan'] as num?)?.toDouble() == 0) {
      return true;
    }
    // Fitur baru: addendum CCO harus ada.
    if ((keg['addendums'] as List? ?? []).isEmpty) return true;
    // Laporan harian harus sudah hidrate dari subcollection.
    if ((keg['laporans'] as List? ?? []).isEmpty) return true;
    return false;
  }

  /// Demo data MT Haryono dinonaktifkan permanen.
  Future<void> _seedDemoData({bool addToList = false}) async {}

  /// Demo data MT Haryono dinonaktifkan permanen.
  Future<void> _refreshDemoData() async {}

  // ═════════════════════════════════════════════════════════════════════
  // HELPER STRUKTUR DATA
  // ═════════════════════════════════════════════════════════════════════

  /// Pastikan setiap kegiatan punya `id` stabil (untuk pengait subcollection).
  void _ensureKegiatanIds(ContractModel c) {
    for (final keg in c.kegiatans) {
      if ((keg['id'] ?? '').toString().isEmpty) {
        keg['id'] = 'keg-${_stableHash(keg['namaKegiatan']?.toString() ?? '')}';
      }
    }
  }

  /// Hash deterministik lintas platform (djb2) — hashCode Dart tidak konsisten
  /// antara web dan mobile.
  String _stableHash(String s) {
    var h = 5381;
    for (final cu in s.codeUnits) {
      h = ((h << 5) + h + cu) & 0x7fffffff;
    }
    return h.toRadixString(36);
  }

  /// Ambil array laporan dari setiap kegiatan, beri penanda (id, kegiatanId,
  /// kegiatanNama, contractId), dan pasang kembali list beranotasi ke keg map.
  Map<String, List<Map<String, dynamic>>> _extractReports(
    ContractModel c,
    String key,
  ) {
    _ensureKegiatanIds(c);
    final out = <String, List<Map<String, dynamic>>>{};
    for (final keg in c.kegiatans) {
      final kegId = (keg['id'] ?? '').toString();
      final kegName = keg['namaKegiatan']?.toString() ?? '';
      final list = (keg[key] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      for (final r in list) {
        if ((r['id'] ?? '').toString().isEmpty) r['id'] = generateId();
        r['kegiatanId'] = kegId.isNotEmpty ? kegId : kegName;
        r['kegiatanNama'] = kegName;
        r['namaKegiatan'] = kegName;
        r['contractId'] = c.id;
      }
      keg[key] = list;
      final outKey = kegId.isNotEmpty ? kegId : kegName;
      out[outKey] = list;
    }
    return out;
  }

  /// Salinan kontrak untuk ditulis ke Firestore — TANPA array laporan & TANPA
  /// isi dokumen (isi dokumen hidup di subcollection `dokumen`; yang tersimpan
  /// hanya skeleton nama folder).
  Map<String, dynamic> _sanitizeForWrite(ContractModel c) {
    final json = c.toJson();
    json['folders'] = (json['folders'] as List? ?? []).map((f) {
      final m = Map<String, dynamic>.from(f as Map);
      m.remove('documents'); // isi dokumen → subcollection `dokumen`
      return m;
    }).toList();
    json['kegiatans'] = (json['kegiatans'] as List).map((keg) {
      final m = Map<String, dynamic>.from(keg as Map);
      m.remove('laporans'); // laporan harian (key aplikasi baru)
      m.remove('laporan'); // kompatibilitas key lama
      m.remove('laporanMingguan');
      m.remove('laporanBulanan');
      m['folders'] = (m['folders'] as List? ?? []).map((f) {
        final fm = Map<String, dynamic>.from(f as Map);
        fm.remove('documents');
        return fm;
      }).toList();
      return m;
    }).toList();
    return json;
  }

  /// JSON ringan khusus pembanding snapshot realtime — menyisihkan isi dokumen
  /// & laporan agar pantulan tulisan sendiri terdeteksi sebagai no-op.
  String _comparisonJson(ContractModel c) {
    final json = _sanitizeForWrite(c);
    for (final f in (json['folders'] as List? ?? [])) {
      (f as Map).remove('documents');
    }
    for (final keg in (json['kegiatans'] as List)) {
      final m = keg as Map;
      m.remove('laporans');
      m.remove('laporanMingguan');
      for (final f in (m['folders'] as List? ?? [])) {
        (f as Map).remove('documents');
      }
    }
    return jsonEncode(json);
  }

  void _fillCache(
    String cid,
    Map<String, List<Map<String, dynamic>>> reports,
    Map<String, Map<String, String>> cacheHolder,
  ) {
    final cache = cacheHolder.putIfAbsent(cid, () => {});
    cache.clear();
    reports.forEach((_, reps) {
      for (final r in reps) {
        cache[r['id'].toString()] = jsonEncode(r);
      }
    });
  }

  /// Bandingkan laporan sekarang vs cache → tulis/hapus hanya yang berubah.
  /// Sekalian membersihkan dokumen yatim (ada di Firestore tapi tak ada di memori).
  Future<void> _syncReports(
    String cid,
    Map<String, List<Map<String, dynamic>>> current,
    Map<String, Map<String, String>> cacheHolder,
    String subName,
  ) async {
    final cache = cacheHolder.putIfAbsent(cid, () => {});
    final newCache = <String, String>{};
    final seenIds = <String>{};
    final batch = _db.batch();
    int ops = 0;
    final cRef = _db.collection('contracts').doc(cid);

    current.forEach((_, reps) {
      for (final r in reps) {
        final docId = r['id'].toString();
        seenIds.add(docId);
        final json = jsonEncode(r);
        newCache[docId] = json;
        if (cache[docId] != json) {
          batch.set(cRef.collection(subName).doc(docId), r);
          ops++;
        }
      }
    });

    // Hapus dokumen yang hilang dari memori ATAU tak dikenal cache
    // (mis. sisa data versi lama). Bila isi cloud sudah diketahui dari cache
    // (hasil hidrasi/sinkron sebelumnya), koleksi tidak perlu dibaca ulang.
    try {
      if (cache.isEmpty) {
        final existing = await cRef.collection(subName).get();
        for (final d in existing.docs) {
          if (!seenIds.contains(d.id)) {
            batch.delete(d.reference);
            ops++;
          }
        }
      } else {
        for (final id in List<String>.from(cache.keys)) {
          if (!seenIds.contains(id)) {
            batch.delete(cRef.collection(subName).doc(id));
            ops++;
          }
        }
      }
    } catch (_) {}

    if (ops > 0) {
      await batch.commit();
    }

    cache
      ..clear()
      ..addAll(newCache);
  }

  /// Ambil laporan dari subcollection & suntikkan kembali ke keg map agar
  /// seluruh layar (yang membaca `keg['laporan']` dsb.) tetap berjalan.
  Future<void> _hydrateReports(ContractModel c) async {
    try {
      final cRef = _db.collection('contracts').doc(c.id);
      final dailySnap = await cRef.collection('laporans').get();
      final weeklySnap = await cRef.collection('laporanMingguan').get();

      final dailyByKeg = <String, List<Map<String, dynamic>>>{};
      final weeklyByKeg = <String, List<Map<String, dynamic>>>{};

      final reportCache = _reportDocCache.putIfAbsent(c.id, () => {});
      final weeklyCache = _weeklyDocCache.putIfAbsent(c.id, () => {});
      reportCache.clear();
      weeklyCache.clear();

      for (final d in dailySnap.docs) {
        final r = Map<String, dynamic>.from(d.data());
        r['id'] = d.id;
        final kId = (r['kegiatanId'] ?? '').toString().trim();
        final kNama = (r['kegiatanNama'] ?? r['namaKegiatan'] ?? '').toString().trim();
        if (kId.isNotEmpty) {
          dailyByKeg.putIfAbsent(kId, () => []).add(r);
        }
        if (kNama.isNotEmpty && kNama != kId) {
          dailyByKeg.putIfAbsent(kNama, () => []).add(r);
        }
        if (kId.isEmpty && kNama.isEmpty) {
          dailyByKeg.putIfAbsent('', () => []).add(r);
        }
        reportCache[d.id] = jsonEncode(r);
      }
      for (final d in weeklySnap.docs) {
        final r = Map<String, dynamic>.from(d.data());
        r['id'] = d.id;
        final kId = (r['kegiatanId'] ?? '').toString().trim();
        final kNama = (r['kegiatanNama'] ?? r['namaKegiatan'] ?? '').toString().trim();
        if (kId.isNotEmpty) {
          weeklyByKeg.putIfAbsent(kId, () => []).add(r);
        }
        if (kNama.isNotEmpty && kNama != kId) {
          weeklyByKeg.putIfAbsent(kNama, () => []).add(r);
        }
        if (kId.isEmpty && kNama.isEmpty) {
          weeklyByKeg.putIfAbsent('', () => []).add(r);
        }
        weeklyCache[d.id] = jsonEncode(r);
      }

      // Urutkan & dedup: harian terbaru dulu, mingguan urut mingguKe.
      dailyByKeg.forEach((_, list) {
        final seen = <String>{};
        list.retainWhere((x) => seen.add((x['id'] ?? '').toString()));
        list.sort((a, b) => (b['tanggal'] ?? '').toString().compareTo((a['tanggal'] ?? '').toString()));
      });
      weeklyByKeg.forEach((_, list) {
        final seen = <String>{};
        list.retainWhere((x) => seen.add((x['id'] ?? '').toString()));
        list.sort((a, b) => ((a['mingguKe'] is int) ? a['mingguKe'] as int : int.tryParse(a['mingguKe']?.toString() ?? '1') ?? 1)
            .compareTo((b['mingguKe'] is int) ? b['mingguKe'] as int : int.tryParse(b['mingguKe']?.toString() ?? '1') ?? 1));
      });

      for (final keg in c.kegiatans) {
        final kegId = (keg['id'] ?? '').toString();
        final kegName = keg['namaKegiatan']?.toString() ?? '';
        final laps = dailyByKeg[kegId] ?? dailyByKeg[kegName] ?? (c.kegiatans.length == 1 ? dailyByKeg[''] : null) ?? [];
        final weeks = weeklyByKeg[kegId] ?? weeklyByKeg[kegName] ?? (c.kegiatans.length == 1 ? weeklyByKeg[''] : null) ?? [];
        keg['laporans'] = laps;
        keg['laporanMingguan'] = weeks;
      }
    } catch (e) {
      debugPrint('[ContractProvider] Hydrate gagal untuk ${c.id}: $e');
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // DOKUMEN ADMINISTRASI (subcollection `dokumen` — anti saling-timpa)
  // ═════════════════════════════════════════════════════════════════════

  /// Kumpulkan seluruh dokumen administrasi dari memori (level kontrak +
  /// level kegiatan), beri anotasi, pastikan setiap dokumen punya id.
  List<Map<String, dynamic>> _extractDokumen(ContractModel c) {
    final out = <Map<String, dynamic>>[];
    void collect(List folders, {String? kegiatanId}) {
      for (final f in folders) {
        if (f is! Map) continue;
        final folderName = f['name']?.toString() ?? '';
        for (final d in (f['documents'] as List? ?? [])) {
          if (d is! Map) continue;
          final m = Map<String, dynamic>.from(d);
          if ((m['id'] ?? '').toString().isEmpty) m['id'] = generateId();
          m['contractId'] = c.id;
          m['folderName'] = folderName;
          if (kegiatanId != null) m['kegiatanId'] = kegiatanId;
          m['sortTs'] ??= DateTime.now().millisecondsSinceEpoch;
          out.add(m);
        }
      }
    }

    collect(c.folders);
    for (final keg in c.kegiatans) {
      collect((keg['folders'] as List? ?? []).toList(),
          kegiatanId: (keg['id'] ?? '').toString());
    }
    return out;
  }

  /// Tulis dokumen ke subcollection `dokumen` (diff vs cache) + soft-delete
  /// untuk dokumen yang dihapus dari memori di perangkat ini.
  Future<void> _syncDokumen(ContractModel c) async {
    try {
      final docs = _extractDokumen(c);
      final cache = _dokumenDocCache.putIfAbsent(c.id, () => {});
      final tomb = _deletedDocIds.putIfAbsent(c.id, () => <String>{});
      final cRef = _db.collection('contracts').doc(c.id);
      final batch = _db.batch();
      int ops = 0;

      for (final d in docs) {
        final id = d['id'].toString();
        final json = jsonEncode(d);
        if (cache[id] != json) {
          batch.set(cRef.collection('dokumen').doc(id), d);
          ops++;
        }
        tomb.remove(id); // hidup kembali bila pernah dihapus lalu dikembalikan
      }

      // Soft-delete: dokumen yang dikenal cache tapi hilang dari memori
      // = dihapus user di perangkat ini (bukan overwrite perangkat lain).
      for (final id in List<String>.from(cache.keys)) {
        final masihAda = docs.any((d) => d['id'].toString() == id);
        if (!masihAda && !tomb.contains(id)) {
          batch.set(cRef.collection('dokumen').doc(id),
              {'deleted': true}, SetOptions(merge: true));
          tomb.add(id);
          ops++;
        }
      }

      final newCache = <String, String>{};
      for (final d in docs) {
        newCache[d['id'].toString()] = jsonEncode(d);
      }
      cache
        ..clear()
        ..addAll(newCache);

      if (ops > 0) await batch.commit();
    } catch (e) {
      debugPrint('[ContractProvider] Sync dokumen gagal: $e');
    }
  }

  /// Ambil dokumen dari subcollection & suntikkan ke folder yang sesuai
  /// (level kontrak dan level kegiatan), menyatu dengan dokumen lokal yang
  /// belum sempat ke cloud (mencegah hilang saat snapshot rebuild).
  Future<void> _hydrateDokumen(
    ContractModel c, {
    QuerySnapshot<Map<String, dynamic>>? snapshot,
  }) async {
    try {
      final snap = snapshot ??
          await _db
              .collection('contracts')
              .doc(c.id)
              .collection('dokumen')
              .get();
      final cache = _dokumenDocCache.putIfAbsent(c.id, () => {});
      cache.clear();

      final cloud = <Map<String, dynamic>>[];
      final cloudIds = <String>{};
      for (final d in snap.docs) {
        final r = Map<String, dynamic>.from(d.data());
        r['id'] = d.id;
        if (r['deleted'] == true) continue;
        cloud.add(r);
        cloudIds.add(d.id);
        cache[d.id] = jsonEncode(r);
      }

      // Pertahankan dokumen lokal yang belum ke cloud (upload di flight).
      final localOnly = <Map<String, dynamic>>[];
      void scanLocal(List folders, {String? kegiatanId}) {
        for (final f in folders) {
          if (f is! Map) continue;
          final folderName = f['name']?.toString() ?? '';
          for (final d in (f['documents'] as List? ?? [])) {
            if (d is! Map) continue;
            final id = (d['id'] ?? '').toString();
            if (id.isNotEmpty && cloudIds.contains(id)) continue;
            final m = Map<String, dynamic>.from(d);
            if (id.isEmpty) m['id'] = generateId();
            m['contractId'] = c.id;
            m['folderName'] = folderName;
            if (kegiatanId != null) m['kegiatanId'] = kegiatanId;
            m['sortTs'] ??= DateTime.now().millisecondsSinceEpoch;
            localOnly.add(m);
            cloudIds.add(m['id'].toString());
          }
        }
      }

      scanLocal(c.folders);
      for (final keg in c.kegiatans) {
        scanLocal((keg['folders'] as List? ?? []).toList(),
            kegiatanId: (keg['id'] ?? '').toString());
      }

      final semua = [...cloud, ...localOnly];

      // Injeksi ke folder — level kontrak
      void inject(List folders, String? kegiatanId) {
        for (final f in folders) {
          if (f is! Map) continue;
          final folderName = f['name']?.toString() ?? '';
          final list = semua
              .where((r) =>
                  (r['folderName']?.toString() ?? '') == folderName &&
                  (r['kegiatanId']?.toString() ?? '') == (kegiatanId ?? ''))
              .toList();
          list.sort((a, b) =>
              ((a['sortTs'] as num?) ?? 0).compareTo((b['sortTs'] as num?) ?? 0));
          f['documents'] = list;
        }
        // Folder yang hilang dari skeleton tapi masih punya dokumen di cloud.
        for (final r in semua) {
          if ((r['kegiatanId']?.toString() ?? '') != (kegiatanId ?? '')) continue;
          final fn = r['folderName']?.toString() ?? '';
          final ada = folders.any((f) => f is Map && f['name']?.toString() == fn);
          if (!ada) {
            folders.add({'name': fn, 'isExpanded': false, 'documents': <Map>[]});
          }
        }
        // Isi ulang list folder yang baru dibuat.
        for (final f in folders) {
          if (f is! Map) continue;
          final folderName = f['name']?.toString() ?? '';
          final list = semua
              .where((r) =>
                  (r['folderName']?.toString() ?? '') == folderName &&
                  (r['kegiatanId']?.toString() ?? '') == (kegiatanId ?? ''))
              .toList();
          list.sort((a, b) =>
              ((a['sortTs'] as num?) ?? 0).compareTo((b['sortTs'] as num?) ?? 0));
          f['documents'] = list;
        }
      }

      inject(c.folders, null);
      for (final keg in c.kegiatans) {
        inject((keg['folders'] as List? ?? []).toList(),
            (keg['id'] ?? '').toString());
      }
    } catch (e) {
      debugPrint('[ContractProvider] Hydrate dokumen gagal untuk ${c.id}: $e');
    }
  }

  /// Union dokumen dari state provider terbaru (hasil rebuild snapshot) ke
  /// objek yang akan ditulis layar — agar layar dengan objek basi TIDAK
  /// menghapus dokumen yang diunggah perangkat lain.
  void _mergePreserveDokumen(ContractModel fresh, ContractModel target) {
    void merge(List freshFolders, List targetFolders) {
      final byName = <String, Map>{};
      for (final f in targetFolders) {
        if (f is Map) byName[f['name']?.toString() ?? ''] = f;
      }
      for (final ff in freshFolders) {
        if (ff is! Map) continue;
        final name = ff['name']?.toString() ?? '';
        final t = byName[name];
        if (t == null) {
          targetFolders.add(Map<String, dynamic>.from(ff));
          continue;
        }
        final freshDocs = (ff['documents'] as List? ?? []).whereType<Map>();
        final tDocs = (t['documents'] as List? ?? []).whereType<Map>().toList();
        final ids = tDocs.map((d) => (d['id'] ?? '').toString()).toSet();
        for (final d in freshDocs) {
          final id = (d['id'] ?? '').toString();
          if (id.isNotEmpty && !ids.contains(id)) {
            tDocs.add(Map<String, dynamic>.from(d));
            ids.add(id);
          }
        }
        t['documents'] = tDocs;
      }
    }

    merge(fresh.folders, target.folders);
    for (final fk in fresh.kegiatans) {
      final kegId = (fk['id'] ?? '').toString();
      Map<String, dynamic>? tk;
      for (final t in target.kegiatans) {
        if ((t['id'] ?? '').toString() == kegId) {
          tk = t;
          break;
        }
      }
      if (tk == null) continue;
      merge((fk['folders'] as List? ?? []).toList(),
          (tk['folders'] as List? ?? []).toList());
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // CRUD KONTRAK
  // ═════════════════════════════════════════════════════════════════════

  List<ContractModel> get contracts => [..._contracts];

  int get totalContracts => _contracts.length;
  int get activeContracts => _contracts.where((c) => c.status == 'Aktif').length;
  int get completedContracts => _contracts.where((c) => c.status == 'Selesai').length;

  Future<void> addContract(ContractModel newContract) async {
    if (newContract.id.isEmpty) newContract.id = generateId();
    _ensureKegiatanIds(newContract);
    _contracts.add(newContract);
    notifyListeners(); // UI langsung tampil

    final daily = _extractReports(newContract, 'laporans');
    final weekly = _extractReports(newContract, 'laporanMingguan');

    try {
      final cRef = _db.collection('contracts').doc(newContract.id);
      _lastWrittenJson[newContract.id] = _comparisonJson(newContract);
      await cRef.set(_sanitizeForWrite(newContract));
      await _syncReports(newContract.id, daily, _reportDocCache, 'laporans');
      await _syncReports(newContract.id, weekly, _weeklyDocCache, 'laporanMingguan');
      await _syncDokumen(newContract);
    } catch (e) {
      debugPrint('[ContractProvider] addContract gagal: $e');
    }
    await _saveLocalBackup();
  }

  /// Simpan perubahan kontrak. Laporan harian/mingguan otomatis disinkronkan
  /// ke subcollection (tambah/ubah/hapus) dengan diff minimal. Dokumen
  /// administrasi ikut tersinkron ke subcollection `dokumen`, dan dokumen yang
  /// diunggah perangkat lain dijaga (union) agar tidak ikut terhapus.
  Future<void> updateContract(ContractModel updatedContract) async {
    final index = _contracts.indexWhere((c) => c.id == updatedContract.id);
    if (index < 0) {
      await addContract(updatedContract);
      return;
    }
    // Lindungi dokumen yang diunggah perangkat lain dari objek layar yang basi.
    _mergePreserveDokumen(_contracts[index], updatedContract);
    _contracts[index] = updatedContract;
    notifyListeners(); // UI responsif tanpa menunggu jaringan

    _ensureKegiatanIds(updatedContract);
    final daily = _extractReports(updatedContract, 'laporans');
    final weekly = _extractReports(updatedContract, 'laporanMingguan');

    try {
      // Sinkronkan subcollection terlebih dahulu sebelum menulis parent document
      // agar snapshot listener tidak membaca subcollection yang belum diperbarui.
      await _syncReports(updatedContract.id, daily, _reportDocCache, 'laporans');
      await _syncReports(updatedContract.id, weekly, _weeklyDocCache, 'laporanMingguan');
      await _syncDokumen(updatedContract);
      // Tulis dokumen induk hanya bila isinya benar-benar berubah.
      final writeJson = _comparisonJson(updatedContract);
      if (_lastWrittenJson[updatedContract.id] != writeJson) {
        _lastWrittenJson[updatedContract.id] = writeJson;
        await _db
            .collection('contracts')
            .doc(updatedContract.id)
            .set(_sanitizeForWrite(updatedContract));
      }
    } catch (e) {
      debugPrint('[ContractProvider] updateContract gagal: $e');
    }
    await _saveLocalBackup();
  }

  Future<void> deleteContract(String id) async {
    _contracts.removeWhere((c) => c.id == id);
    _reportDocCache.remove(id);
    _weeklyDocCache.remove(id);
    _dokumenDocCache.remove(id);
    _deletedDocIds.remove(id);
    _lastWrittenJson.remove(id);
    notifyListeners();

    try {
      final cRef = _db.collection('contracts').doc(id);
      for (final sub in const ['laporans', 'laporanMingguan', 'dokumen']) {
        final snap = await cRef.collection(sub).get();
        final batch = _db.batch();
        for (final d in snap.docs) {
          batch.delete(d.reference);
        }
        if (snap.docs.isNotEmpty) await batch.commit();
      }
      await cRef.delete();
    } catch (e) {
      debugPrint('[ContractProvider] deleteContract gagal: $e');
    }
    await _saveLocalBackup();
  }

  Future<void> clearAllContracts() async {
    for (final c in List<ContractModel>.from(_contracts)) {
      await deleteContract(c.id);
    }
    notifyListeners();
  }

  Future<void> resetToDemoContract() async {
    await clearAllContracts();
    await _seedDemoData();
    await _loadContracts();
  }

  // ═════════════════════════════════════════════════════════════════════
  // UTIL
  // ═════════════════════════════════════════════════════════════════════

  /// ID acak untuk dokumen/entri baru (dipakai layar tambah kontrak dll).
  String generateId() {
    var random = Random();
    var values = List<int>.generate(10, (i) => random.nextInt(256));
    return values.join();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    _contractsSub?.cancel();
    for (final sub in _dokumenSubs.values) {
      sub.cancel();
    }
    super.dispose();
  }
}
