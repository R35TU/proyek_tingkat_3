// ignore_for_file: subtype_of_sealed_class
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';

ContractModel _makeContract(
  String id,
  String nama, {
  List<Map<String, dynamic>>? folders,
  List<Map<String, dynamic>>? kegiatans,
}) {
  return ContractModel(
    id: id,
    namaKontrak: nama,
    jenisKegiatan: 'Pengawasan Teknis',
    nomorSpk: 'SPK-$id',
    tglMulaiSpk: '20 April 2026',
    nomorSpmk: 'SPMK-$id',
    tglMulaiSpmk: '20 April 2026',
    tglSelesaiSpmk: '18 Juli 2026',
    hariKalender: 90,
    nilaiKontrak: 'Rp 250.000.000',
    instansiDinas: const ['DPU-PR Kab. Purbalingga'],
    sumberDana: 'APBD',
    deskripsi: 'Kontrak uji $nama',
    folders: folders ?? [],
    kegiatans: kegiatans ?? [],
  );
}

class _MemDoc {
  Map<String, dynamic> data;
  final Map<String, Map<String, Map<String, dynamic>>> subcollections = {};
  _MemDoc(this.data);
}

class _FakeFirestore implements FirebaseFirestore {
  final Map<String, _MemDoc> contracts = {};
  Completer<void>? getDelay;
  bool failReads = false;
  bool failWrites = false;
  bool failBatchCommit = false;
  int contractSetCount = 0;

  final StreamController<QuerySnapshot<Map<String, dynamic>>> _contractsStream =
      StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();

  void seedContract(ContractModel c) {
    final json = c.toJson();
    json['folders'] = const [];
    json['kegiatans'] = const [];
    contracts[c.id] = _MemDoc(json);
  }

  void emitContractsSnapshot({
    List<String> modifiedOrAddedIds = const [],
    List<String> removedIds = const [],
  }) {
    final docs = contracts.entries
        .map((e) => _FakeQueryDoc(e.key, Map<String, dynamic>.from(e.value.data)))
        .toList();
    final changes = <DocumentChange<Map<String, dynamic>>>[];
    for (final id in modifiedOrAddedIds) {
      final doc = contracts[id];
      if (doc != null) {
        changes.add(_FakeDocChange(
          _FakeQueryDoc(id, Map<String, dynamic>.from(doc.data)),
          DocumentChangeType.modified,
        ));
      }
    }
    for (final id in removedIds) {
      changes.add(_FakeDocChange(
        _FakeQueryDoc(id, <String, dynamic>{}),
        DocumentChangeType.removed,
      ));
    }
    _contractsStream.add(_FakeQuerySnapshot(docs, changes));
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    assert(collectionPath == 'contracts');
    return _FakeContractsCollection(this);
  }

  @override
  WriteBatch batch() => _FakeWriteBatch(this);

  Future<void> dispose() => _contractsStream.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeContractsCollection
    implements CollectionReference<Map<String, dynamic>> {
  final _FakeFirestore fs;
  _FakeContractsCollection(this.fs);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FakeContractDocRef(fs, path ?? 'auto');

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    if (fs.getDelay != null) {
      await fs.getDelay!.future;
    }
    if (fs.failReads) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    final docs = fs.contracts.entries
        .map((e) => _FakeQueryDoc(e.key, Map<String, dynamic>.from(e.value.data)))
        .toList();
    return _FakeQuerySnapshot(docs, const []);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      fs._contractsStream.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeContractDocRef implements DocumentReference<Map<String, dynamic>> {
  final _FakeFirestore fs;
  @override
  final String id;
  _FakeContractDocRef(this.fs, this.id);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    if (fs.failWrites) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    fs.contractSetCount++;
    final existing = fs.contracts[id];
    if (existing != null) {
      existing.data = Map<String, dynamic>.from(data);
    } else {
      fs.contracts[id] = _MemDoc(Map<String, dynamic>.from(data));
    }
  }

  @override
  Future<void> delete() async {
    if (fs.failWrites) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    fs.contracts.remove(id);
  }

  @override
  CollectionReference<Map<String, dynamic>> collection(String subPath) =>
      _FakeSubCollection(fs, id, subPath);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubCollection implements CollectionReference<Map<String, dynamic>> {
  final _FakeFirestore fs;
  final String contractId;
  final String subName;
  _FakeSubCollection(this.fs, this.contractId, this.subName);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FakeSubDocRef(fs, contractId, subName, path ?? 'auto-sub');

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> get([GetOptions? options]) async {
    if (fs.failReads) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    final subMap =
        fs.contracts[contractId]?.subcollections[subName] ?? const {};
    final docs = subMap.entries
        .map((e) => _FakeQueryDoc(e.key, Map<String, dynamic>.from(e.value)))
        .toList();
    return _FakeQuerySnapshot(docs, const []);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) =>
      const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubDocRef implements DocumentReference<Map<String, dynamic>> {
  final _FakeFirestore fs;
  final String contractId;
  final String subName;
  @override
  final String id;
  _FakeSubDocRef(this.fs, this.contractId, this.subName, this.id);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWriteBatch implements WriteBatch {
  final _FakeFirestore fs;
  final List<void Function()> _ops = [];
  _FakeWriteBatch(this.fs);

  @override
  void set<T>(DocumentReference<T> doc, T data, [SetOptions? options]) {
    if (doc is _FakeSubDocRef && data is Map<String, dynamic>) {
      final subDoc = doc as _FakeSubDocRef;
      _ops.add(() {
        final cDoc =
            fs.contracts.putIfAbsent(subDoc.contractId, () => _MemDoc({}));
        final sub = cDoc.subcollections.putIfAbsent(subDoc.subName, () => {});
        if (options?.merge == true && sub.containsKey(subDoc.id)) {
          sub[subDoc.id] = {...sub[subDoc.id]!, ...data};
        } else {
          sub[subDoc.id] = Map<String, dynamic>.from(data);
        }
      });
    }
  }

  @override
  void delete(DocumentReference<Object?> doc) {
    if (doc is _FakeSubDocRef) {
      _ops.add(() {
        fs.contracts[doc.contractId]?.subcollections[doc.subName]?.remove(doc.id);
      });
    }
  }

  @override
  Future<void> commit() async {
    if (fs.failWrites || fs.failBatchCommit) {
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    }
    for (final op in _ops) {
      op();
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQuerySnapshot implements QuerySnapshot<Map<String, dynamic>> {
  @override
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs;
  @override
  final List<DocumentChange<Map<String, dynamic>>> docChanges;
  _FakeQuerySnapshot(this.docs, this.docChanges);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDocChange implements DocumentChange<Map<String, dynamic>> {
  @override
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  @override
  final DocumentChangeType type;
  _FakeDocChange(this.doc, this.type);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeQueryDoc implements QueryDocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;
  final Map<String, dynamic> _data;
  _FakeQueryDoc(this.id, this._data);

  @override
  Map<String, dynamic> data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _flushMicrotasks([int cycles = 12]) async {
  for (int i = 0; i < cycles; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ContractProvider Concurrency, Sync, Isolation & Recovery Audit', () {
    test(
      '1. Mutasi tambah, ubah, dan hapus saat Firestore load lambat tidak tertimpa & tidak duplikat',
      () async {
        final fs = _FakeFirestore();
        final slowLoad = Completer<void>();
        fs.getDelay = slowLoad;

        final existingOld = _makeContract('c_exist', 'Kontrak Server Lama');
        final deletedServer = _makeContract('c_del', 'Kontrak Akan Dihapus');
        final untouched = _makeContract('c_keep', 'Kontrak Tetap');
        fs.seedContract(existingOld);
        fs.seedContract(deletedServer);
        fs.seedContract(untouched);

        // Cache lokal sudah memuat 3 kontrak tersebut agar updateContract & deleteContract bisa dijalankan saat cloud load lambat
        SharedPreferences.setMockInitialValues({
          'contracts_uidA': jsonEncode([
            existingOld.toJson(),
            deletedServer.toJson(),
            untouched.toJson(),
          ]),
        });

        final authCtrl = StreamController<String?>.broadcast();
        final provider = ContractProvider(
          db: fs,
          uidProvider: () => 'uidA',
          authUidStream: authCtrl.stream,
        );
        addTearDown(() async {
          provider.dispose();
          await authCtrl.close();
          await fs.dispose();
        });

        // Tunggu _loadFromLocalFallback selesai, sementara cloud .get() tertahan oleh slowLoad
        await _flushMicrotasks();
        expect(provider.isLoading, isTrue);
        expect(provider.contracts.length, 3);

        // Operasi tambah, ubah, & hapus terjadi SELAMA cloud load masih berlangsung
        final addedContract = _makeContract('c_new', 'Kontrak Baru Saat Loading');
        await provider.addContract(addedContract);

        final existingEdited = _makeContract('c_exist', 'Kontrak Hasil Edit Lokal');
        await provider.updateContract(existingEdited);

        await provider.deleteContract('c_del');

        // Lepaskan cloud .get() lambat (yang berisi data lama pra-mutasi)
        // Simulasikan Firestore mengembalikan state lama
        fs.seedContract(existingOld);
        fs.seedContract(deletedServer);
        slowLoad.complete();
        await _flushMicrotasks();

        expect(provider.isLoading, isFalse);
        final namesById = {for (final c in provider.contracts) c.id: c.namaKontrak};
        expect(namesById['c_exist'], 'Kontrak Hasil Edit Lokal');
        expect(namesById['c_new'], 'Kontrak Baru Saat Loading');
        expect(namesById['c_keep'], 'Kontrak Tetap');
        expect(namesById.containsKey('c_del'), isFalse);
        expect(
          provider.contracts.where((c) => c.id == 'c_exist').length,
          1,
        );
        expect(
          provider.contracts.where((c) => c.id == 'c_new').length,
          1,
        );
      },
    );

    test(
      '2. Mutasi yang sudah tersinkron tidak diterapkan dua kali sehingga pembaruan remote berikutnya tetap tampil dan tidak ditulis ulang',
      () async {
        final fs = _FakeFirestore();
        final slowInit = Completer<void>();
        fs.getDelay = slowInit;

        final provider = ContractProvider(
          db: fs,
          uidProvider: () => 'uidA',
        );
        addTearDown(() async {
          provider.dispose();
          await fs.dispose();
        });

        await _flushMicrotasks();
        // addContract berhasil tersinkron saat initial load masih berjalan
        await provider.addContract(_makeContract('c1', 'Versi Lokal Tersinkron'));
        expect(fs.contractSetCount, 1);

        // Initial load selesai (mengembalikan list lama pra-mutasi) -> c1 dipertahankan tepat 1x (tidak duplikat)
        fs.contracts.clear();
        slowInit.complete();
        await _flushMicrotasks();
        expect(provider.contracts.length, 1);
        expect(provider.contracts.first.namaKontrak, 'Versi Lokal Tersinkron');

        // Perangkat lain memperbarui c1 di Firestore -> snapshot memperbarui c1 tanpa ditimpa mutasi lama
        fs.seedContract(_makeContract('c1', 'Versi Remote Terbaru'));
        fs.emitContractsSnapshot(modifiedOrAddedIds: ['c1']);
        await _flushMicrotasks();

        expect(provider.contracts.length, 1);
        expect(provider.contracts.first.namaKontrak, 'Versi Remote Terbaru');

        // Saat mutasi offline lain pulih & retry berjalan, c1 yang sudah tersinkron tidak ditulis/diterapkan ulang
        fs.failWrites = true;
        await provider.addContract(_makeContract('c2_off', 'Kontrak Offline Kedua'));
        fs.failWrites = false;
        fs.emitContractsSnapshot();
        await _flushMicrotasks();

        expect(
          {for (final c in provider.contracts) c.id: c.namaKontrak},
          {
            'c1': 'Versi Remote Terbaru',
            'c2_off': 'Kontrak Offline Kedua',
          },
        );
        expect(fs.contractSetCount, 2);
      },
    );

    test(
      '3. Offline mutation, kegagalan sinkronisasi, & pemulihan koneksi tidak menghilangkan data dan sukses retry ke Firestore',
      () async {
        final fs = _FakeFirestore();
        final existing = _makeContract('c_srv', 'Kontrak Awal Server');
        final toDeleteOffline = _makeContract('c_del_off', 'Hapus Saat Offline');
        fs.seedContract(existing);
        fs.seedContract(toDeleteOffline);

        final provider = ContractProvider(
          db: fs,
          uidProvider: () => 'uidA',
        );
        addTearDown(() async {
          provider.dispose();
          await fs.dispose();
        });

        await _flushMicrotasks();
        expect(provider.contracts.length, 2);

        // Masuk mode offline / gagal tulis Firestore
        fs.failWrites = true;
        final setCountBeforeOffline = fs.contractSetCount;

        final addedOffline = _makeContract('c_off_new', 'Kontrak Dibuat Offline');
        await provider.addContract(addedOffline);

        final editedOffline = _makeContract('c_srv', 'Kontrak Diedit Offline');
        await provider.updateContract(editedOffline);

        await provider.deleteContract('c_del_off');

        expect(fs.contractSetCount, setCountBeforeOffline);
        expect(
          {for (final c in provider.contracts) c.id: c.namaKontrak},
          {
            'c_srv': 'Kontrak Diedit Offline',
            'c_off_new': 'Kontrak Dibuat Offline',
          },
        );

        // Koneksi pulih & snapshot server (yang masih belum tahu mutasi offline) tiba + ada kontrak dari perangkat lain
        fs.failWrites = false;
        final fromOtherDevice = _makeContract('c_other', 'Kontrak Perangkat Lain');
        fs.seedContract(fromOtherDevice);
        fs.emitContractsSnapshot(
          modifiedOrAddedIds: ['c_srv', 'c_other'],
        );
        await _flushMicrotasks();

        // Data offline TETAP terjaga (tidak tertimpa / tidak hilang oleh removedIds / tidak muncul lagi yang dihapus)
        expect(
          {for (final c in provider.contracts) c.id: c.namaKontrak},
          {
            'c_srv': 'Kontrak Diedit Offline',
            'c_off_new': 'Kontrak Dibuat Offline',
            'c_other': 'Kontrak Perangkat Lain',
          },
        );

        // Dan retry pemulihan koneksi benar-benar mensinkronkan mutasi ke Firestore (termasuk parent doc meski comparisonJson sama!)
        expect(fs.contracts['c_off_new']?.data['namaKontrak'], 'Kontrak Dibuat Offline');
        expect(fs.contracts['c_srv']?.data['namaKontrak'], 'Kontrak Diedit Offline');
        expect(fs.contracts.containsKey('c_del_off'), isFalse);

        // Backup lokal SharedPreferences juga terbarui
        final prefs = await SharedPreferences.getInstance();
        final savedRaw = prefs.getString('contracts_uidA');
        expect(savedRaw, isNotNull);
        expect(savedRaw, contains('Kontrak Dibuat Offline'));
      },
    );

    test(
      '4. Kegagalan sebagian pada subcollection dokumen tidak menandai sinkron selesai dan tetap tersinkron saat retry',
      () async {
        final fs = _FakeFirestore();
        final provider = ContractProvider(
          db: fs,
          uidProvider: () => 'uidA',
        );
        addTearDown(() async {
          provider.dispose();
          await fs.dispose();
        });

        await _flushMicrotasks();

        // Batch commit dokumen gagal meskipun set dokumen kontrak induk berhasil
        fs.failBatchCommit = true;
        final withDoc = _makeContract(
          'c_doc',
          'Kontrak Dengan Dokumen',
          folders: [
            {
              'name': 'Administrasi',
              'isExpanded': false,
              'documents': [
                {'id': 'doc_1', 'title': 'BAST.pdf'},
              ],
            }
          ],
        );
        await provider.addContract(withDoc);
        expect(fs.contracts['c_doc']?.subcollections['dokumen'], isNull);

        // Pemulihan: batch commit normal -> snapshot memicu retry yang berhasil menyinkronkan dokumen
        fs.failBatchCommit = false;
        fs.emitContractsSnapshot(modifiedOrAddedIds: ['c_doc']);
        await _flushMicrotasks();

        expect(
          fs.contracts['c_doc']?.subcollections['dokumen']?['doc_1']?['title'],
          'BAST.pdf',
        );
      },
    );

    test(
      '5. Isolasi antar akun, perpindahan akun saat offline, dan logout saat load berjalan tidak membocorkan state',
      () async {
        final fs = _FakeFirestore();
        String currentUid = 'uidA';
        final authCtrl = StreamController<String?>.broadcast();

        // Akun A mulai dalam kondisi offline -> _loadedUid masih null
        fs.failReads = true;
        fs.failWrites = true;

        final provider = ContractProvider(
          db: fs,
          uidProvider: () => currentUid,
          authUidStream: authCtrl.stream,
        );
        addTearDown(() async {
          provider.dispose();
          await authCtrl.close();
          await fs.dispose();
        });

        await _flushMicrotasks();
        await provider.addContract(_makeContract('c_a1', 'Kontrak Rahasia Akun A'));
        expect(provider.contracts.length, 1);

        // Pindah langsung ke Akun B (tanpa melalui null) saat online
        fs.failReads = false;
        fs.failWrites = false;
        fs.contracts.clear();
        fs.seedContract(_makeContract('c_b1', 'Kontrak Milik Akun B'));
        currentUid = 'uidB';
        authCtrl.add('uidB');
        await _flushMicrotasks();

        expect(
          provider.contracts.map((c) => c.id).toList(),
          ['c_b1'],
        );

        // Pastikan mirror Akun A tetap terpisah dan Akun B tidak tercemari data Akun A
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('contracts_uidA'), contains('Kontrak Rahasia Akun A'));
        expect(prefs.getString('contracts_uidB') ?? '', isNot(contains('Kontrak Rahasia Akun A')));

        // Uji logout saat cloud load untuk Akun C sedang in-flight lambat
        final slowLoadC = Completer<void>();
        fs.contracts.clear();
        fs.seedContract(_makeContract('c_c1', 'Kontrak Akun C'));
        fs.getDelay = slowLoadC;
        currentUid = 'uidC';
        authCtrl.add('uidC');
        await _flushMicrotasks();

        // Logout terjadi SEBELUM load Akun C selesai!
        currentUid = '';
        authCtrl.add(null);
        await _flushMicrotasks();
        expect(provider.contracts, isEmpty);

        // Load lama Akun C baru selesai setelah logout -> TIDAK boleh memunculkan data Akun C
        slowLoadC.complete();
        await _flushMicrotasks();
        expect(provider.contracts, isEmpty);
      },
    );
  });
}
