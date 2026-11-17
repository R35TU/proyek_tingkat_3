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
///                                      folders, struktur organisasi) TANPA array laporan.
/// - `contracts/{cid}/laporans`       : laporan harian per dokumen (+ kegiatanId,
///                                      kegiatanNama, contractId).
/// - `contracts/{cid}/laporanMingguan`: laporan mingguan per dokumen (+ penanda sama).
/// - Laporan Bulanan                   : turunan otomatis dari data mingguan di UI,
///                                      tidak perlu penyimpanan terpisah.
///
/// Semua layar tetap memutasi data nested (`keg['laporan']`, `keg['laporanMingguan']`)
/// lalu memanggil [updateContract] — provider yang memisahkan & menyinkronkan
/// laporan ke subcollection saat itu juga (dengan diff agar tulisannya minimal).
class ContractProvider with ChangeNotifier {
  /// Firestore diakses lazy: hanya saat operasi nyata berjalan (di dalam try),
  /// sehingga konstruktor tetap aman di lingkungan test / belum init Firebase.
  final FirebaseFirestore? _injectedDb;
  List<ContractModel> _contracts = [];
  bool _isLoading = false;

  /// Cache untuk diff tulisan: cid -> {docId: json terakhir yang tersimpan}
  final Map<String, Map<String, String>> _reportDocCache = {};
  final Map<String, Map<String, String>> _weeklyDocCache = {};

  bool get isLoading => _isLoading;

  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;

  ContractProvider({FirebaseFirestore? db}) : _injectedDb = db {
    _loadContracts();
    // Muat ulang dari Firestore begitu sesi login Firebase Auth tersedia
    // (sebelum login, rules menolak baca → fallback lokal dipakai sementara).
    try {
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _loadContracts();
        }
      });
    } catch (_) {
      // Firebase belum init (test) → abaikan.
    }
  }

  // ═════════════════════════════════════════════════════════════════════
  // LOAD
  // ═════════════════════════════════════════════════════════════════════

  Future<void> _loadContracts() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snap = await _db.collection('contracts').get();
      if (snap.docs.isEmpty) {
        await _seedDemoData();
      } else {
        final list = <ContractModel>[];
        for (final doc in snap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          final contract = ContractModel.fromJson(data);
          await _hydrateReports(contract);
          list.add(contract);
        }
        _contracts = list;

        // Aplikasi = patokan: pastikan kontrak demo selalu versi terbaru.
        final demoIdx = _contracts.indexWhere((c) => c.id == 'kontrak-mt-haryono-demo');
        if (demoIdx < 0) {
          await _seedDemoData(addToList: true);
        } else if (_isOldDemoData(_contracts[demoIdx])) {
          await _refreshDemoData();
        }
      }
    } catch (e) {
      debugPrint('[ContractProvider] Firestore gagal, pakai data lokal: $e');
      await _loadFromLocalFallback();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fallback offline: baca mirror JSON di SharedPreferences.
  Future<void> _loadFromLocalFallback() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contractsJson = prefs.getString('contracts');
      if (contractsJson != null) {
        final List<dynamic> decoded = jsonDecode(contractsJson);
        _contracts = decoded
            .map((item) => ContractModel.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } else {
        _contracts = [SampleContractData.getDemoContract()];
      }
    } catch (_) {
      _contracts = [SampleContractData.getDemoContract()];
    }
  }

  /// Mirror cadangan ke SharedPreferences (dipakai saat offline).
  Future<void> _saveLocalBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_contracts.map((c) => c.toJson()).toList());
      await prefs.setString('contracts', encoded);
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

  /// Tulis kontrak demo + seluruh laporannya ke Firestore.
  Future<void> _seedDemoData({bool addToList = false}) async {
    final demo = SampleContractData.getDemoContract();
    if (demo.id.isEmpty) demo.id = generateId();
    _ensureKegiatanIds(demo);

    final daily = _extractReports(demo, 'laporans');
    final weekly = _extractReports(demo, 'laporanMingguan');

    try {
      final batch = _db.batch();
      final cRef = _db.collection('contracts').doc(demo.id);
      batch.set(cRef, _sanitizeForWrite(demo));

      daily.forEach((_, reps) {
        for (final r in reps) {
          batch.set(cRef.collection('laporans').doc(r['id'].toString()), r);
        }
      });
      weekly.forEach((_, reps) {
        for (final r in reps) {
          batch.set(cRef.collection('laporanMingguan').doc(r['id'].toString()), r);
        }
      });
      await batch.commit();

      // Isi cache diff agar tulisan berikutnya minimal.
      _fillCache(demo.id, daily, _reportDocCache);
      _fillCache(demo.id, weekly, _weeklyDocCache);

      if (addToList && !_contracts.any((c) => c.id == demo.id)) {
        _contracts.add(demo);
      }
    } catch (e) {
      debugPrint('[ContractProvider] Seed gagal: $e');
    }
    await _saveLocalBackup();
  }

  /// Ganti kontrak demo lama dengan dataset terbaru dari aplikasi.
  Future<void> _refreshDemoData() async {
    final demo = SampleContractData.getDemoContract();
    if (demo.id.isEmpty) demo.id = generateId();
    _ensureKegiatanIds(demo);
    _contracts.removeWhere((c) => c.id == demo.id);

    final daily = _extractReports(demo, 'laporans');
    final weekly = _extractReports(demo, 'laporanMingguan');

    try {
      final cRef = _db.collection('contracts').doc(demo.id);
      // Bersihkan laporan lama milik demo sebelum menulis yang baru.
      for (final sub in const ['laporans', 'laporanMingguan']) {
        final snap = await cRef.collection(sub).get();
        if (snap.docs.isNotEmpty) {
          final del = _db.batch();
          for (final d in snap.docs) {
            del.delete(d.reference);
          }
          await del.commit();
        }
      }

      final batch = _db.batch();
      batch.set(cRef, _sanitizeForWrite(demo));
      daily.forEach((_, reps) {
        for (final r in reps) {
          batch.set(cRef.collection('laporans').doc(r['id'].toString()), r);
        }
      });
      weekly.forEach((_, reps) {
        for (final r in reps) {
          batch.set(cRef.collection('laporanMingguan').doc(r['id'].toString()), r);
        }
      });
      await batch.commit();

      _fillCache(demo.id, daily, _reportDocCache);
      _fillCache(demo.id, weekly, _weeklyDocCache);
      _contracts.add(demo);
      notifyListeners(); // UI harus bangun ulang dengan objek demo yang baru
    } catch (e) {
      debugPrint('[ContractProvider] Refresh demo gagal: $e');
    }
    await _saveLocalBackup();
  }

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
    final out = <String, List<Map<String, dynamic>>>{};
    for (final keg in c.kegiatans) {
      final kegId = (keg['id'] ?? '').toString();
      final kegName = keg['namaKegiatan']?.toString() ?? '';
      final list = (keg[key] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      for (final r in list) {
        if ((r['id'] ?? '').toString().isEmpty) r['id'] = generateId();
        r['kegiatanId'] = kegId;
        r['kegiatanNama'] = kegName;
        r['contractId'] = c.id;
      }
      keg[key] = list;
      out[kegId] = list;
    }
    return out;
  }

  /// Salinan kontrak untuk ditulis ke Firestore — TANPA array laporan
  /// (mencegah dokumen membengkak mendekati limit 1 MiB).
  Map<String, dynamic> _sanitizeForWrite(ContractModel c) {
    final json = c.toJson();
    json['kegiatans'] = (json['kegiatans'] as List).map((keg) {
      final m = Map<String, dynamic>.from(keg as Map);
      m.remove('laporans'); // laporan harian (key aplikasi baru)
      m.remove('laporan'); // kompatibilitas key lama
      m.remove('laporanMingguan');
      m.remove('laporanBulanan');
      return m;
    }).toList();
    return json;
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
    // (mis. sisa data versi lama).
    try {
      final existing = await cRef.collection(subName).get();
      for (final d in existing.docs) {
        if (!seenIds.contains(d.id)) {
          batch.delete(d.reference);
          ops++;
        }
      }
    } catch (_) {}

    cache
      ..clear()
      ..addAll(newCache);

    if (ops > 0) {
      await batch.commit();
    }
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
        final key = (r['kegiatanId'] ?? r['kegiatanNama'] ?? '').toString();
        dailyByKeg.putIfAbsent(key, () => []).add(r);
        reportCache[d.id] = jsonEncode(r);
      }
      for (final d in weeklySnap.docs) {
        final r = Map<String, dynamic>.from(d.data());
        r['id'] = d.id;
        final key = (r['kegiatanId'] ?? r['kegiatanNama'] ?? '').toString();
        weeklyByKeg.putIfAbsent(key, () => []).add(r);
        weeklyCache[d.id] = jsonEncode(r);
      }

      // Urutkan: harian terbaru dulu, mingguan urut mingguKe.
      dailyByKeg.forEach((_, list) {
        list.sort((a, b) => (b['tanggal'] ?? '').toString().compareTo((a['tanggal'] ?? '').toString()));
      });
      weeklyByKeg.forEach((_, list) {
        list.sort((a, b) => ((a['mingguKe'] is int) ? a['mingguKe'] as int : int.tryParse(a['mingguKe']?.toString() ?? '1') ?? 1)
            .compareTo((b['mingguKe'] is int) ? b['mingguKe'] as int : int.tryParse(b['mingguKe']?.toString() ?? '1') ?? 1));
      });

      for (final keg in c.kegiatans) {
        final kegId = (keg['id'] ?? '').toString();
        final kegName = keg['namaKegiatan']?.toString() ?? '';
        keg['laporans'] = dailyByKeg[kegId] ?? dailyByKeg[kegName] ?? [];
        keg['laporanMingguan'] = weeklyByKeg[kegId] ?? weeklyByKeg[kegName] ?? [];
      }
    } catch (e) {
      debugPrint('[ContractProvider] Hydrate gagal untuk ${c.id}: $e');
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
      await cRef.set(_sanitizeForWrite(newContract));
      await _syncReports(newContract.id, daily, _reportDocCache, 'laporans');
      await _syncReports(newContract.id, weekly, _weeklyDocCache, 'laporanMingguan');
    } catch (e) {
      debugPrint('[ContractProvider] addContract gagal: $e');
    }
    await _saveLocalBackup();
  }

  /// Simpan perubahan kontrak. Laporan harian/mingguan otomatis disinkronkan
  /// ke subcollection (tambah/ubah/hapus) dengan diff minimal.
  Future<void> updateContract(ContractModel updatedContract) async {
    final index = _contracts.indexWhere((c) => c.id == updatedContract.id);
    if (index < 0) {
      await addContract(updatedContract);
      return;
    }
    _contracts[index] = updatedContract;
    notifyListeners(); // UI responsif tanpa menunggu jaringan

    _ensureKegiatanIds(updatedContract);
    final daily = _extractReports(updatedContract, 'laporans');
    final weekly = _extractReports(updatedContract, 'laporanMingguan');

    try {
      await _db
          .collection('contracts')
          .doc(updatedContract.id)
          .set(_sanitizeForWrite(updatedContract));
      await _syncReports(updatedContract.id, daily, _reportDocCache, 'laporans');
      await _syncReports(updatedContract.id, weekly, _weeklyDocCache, 'laporanMingguan');
    } catch (e) {
      debugPrint('[ContractProvider] updateContract gagal: $e');
    }
    await _saveLocalBackup();
  }

  Future<void> deleteContract(String id) async {
    _contracts.removeWhere((c) => c.id == id);
    _reportDocCache.remove(id);
    _weeklyDocCache.remove(id);
    notifyListeners();

    try {
      final cRef = _db.collection('contracts').doc(id);
      for (final sub in const ['laporans', 'laporanMingguan']) {
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
}
