import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pencegahan Re-seed Dummy & Isolasi Data User Tests', () {
    test('1. ContractProvider inisialisasi awal tidak menginjeksi data dummy saat storage kosong', () async {
      SharedPreferences.setMockInitialValues({});

      final contractProv = ContractProvider();
      // Beri waktu microtask / future _loadContracts selesai
      await Future.delayed(const Duration(milliseconds: 50));

      expect(contractProv.contracts.isEmpty, isTrue);
      expect(
        contractProv.contracts.any((c) =>
            c.id == 'kontrak-mt-haryono-demo' ||
            c.namaKontrak.toUpperCase().contains('MT HARYONO')),
        isFalse,
      );
    });

    test('2. TimelineProvider inisialisasi default tidak memasukkan event dummy MT Haryono', () async {
      SharedPreferences.setMockInitialValues({});

      final timelineProv = TimelineProvider();
      await timelineProv.loadEvents();

      expect(
        timelineProv.allEvents.any((e) =>
            e.contractId == 'kontrak-mt-haryono-demo' ||
            e.contractName.toUpperCase().contains('MT HARYONO')),
        isFalse,
      );
    });

    // Test 4 dihapus: filter dummy ID sudah tidak ada di provider.
    // Data dummy lama yang mungkin tersisa di cache lokal akan muncul apa adanya —
    // seeder sudah dimatikan jadi data tersebut tidak akan bertambah lagi.

    test('5. Kontrak yang diinput pengguna secara manual dengan nama MT HARYONO tersimpan normal dan TIDAK terhapus', () async {
      // Simulasikan storage tanpa login (kunci global 'contracts' lama tidak
      // boleh terbaca tanpa sesi akun), serta kontrak manual via addContract().
      SharedPreferences.setMockInitialValues({
        'contracts': '[{"id":"kontrak_user_legacy_isolated","namaKontrak":"KONTRAK AKUN LAIN","jenisKegiatan":"Pengawasan Teknis","nomorSpk":"SPK-00","kegiatans":[]}]',
        'tata_saka_timeline_events_v1': '[{"id":"ev_user_01","timestamp":"2026-05-18T10:30:00.000","actorName":"Site Engineer","actorRole":"Konsultan","actionType":"APPROVE","entityType":"LAPORAN","contractId":"kontrak_user_12345","contractName":"PEMELIHARAAN BERKALA JL. MT HARYONO","title":"Pengesahan"}]',
      });

      final contractProv = ContractProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Data pada kunci global 'contracts' tidak bocor ketika belum login
      expect(
        contractProv.contracts.any((c) => c.id == 'kontrak_user_legacy_isolated'),
        isFalse,
      );

      // Kontrak manual bernama MT HARYONO via addContract() tetap aman dan tidak disaring
      await contractProv.addContract(ContractModel(
        id: 'kontrak_user_12345',
        namaKontrak: 'PEMELIHARAAN BERKALA JL. MT HARYONO',
        jenisKegiatan: 'Pengawasan Teknis',
        nomorSpk: 'SPK-01',
        tglMulaiSpk: '2026-04-20',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '2026-04-20',
        tglSelesaiSpmk: '2026-07-19',
        hariKalender: 90,
        nilaiKontrak: 'Rp 100.000.000',
        instansiDinas: ['DPU-PR'],
        sumberDana: 'APBD',
        deskripsi: 'Kontrak input manual pengguna',
        kegiatans: [],
      ));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        contractProv.contracts.any((c) => c.id == 'kontrak_user_12345'),
        isTrue,
      );
      expect(
        contractProv.contracts.firstWhere((c) => c.id == 'kontrak_user_12345').namaKontrak,
        'PEMELIHARAAN BERKALA JL. MT HARYONO',
      );

      final timelineProv = TimelineProvider();
      await timelineProv.loadEvents();
      expect(
        timelineProv.allEvents.any((e) => e.contractId == 'kontrak_user_12345'),
        isTrue,
      );
    });

    test('6. Mutasi addContract, updateContract, dan deleteContract tidak tertimpa race condition inisialisasi/fallback', () async {
      SharedPreferences.setMockInitialValues({});
      final contractProv = ContractProvider();

      // Panggil addContract dan updateContract segera saat inisialisasi/fallback async masih berjalan
      final initialContract = ContractModel(
        id: 'c_race_01',
        namaKontrak: 'Kontrak Uji Race Awal',
        jenisKegiatan: 'Pengawasan Teknis',
        nomorSpk: 'SPK-RACE-01',
        tglMulaiSpk: '2026-06-01',
        nomorSpmk: 'SPMK-RACE-01',
        tglMulaiSpmk: '2026-06-01',
        tglSelesaiSpmk: '2026-08-30',
        hariKalender: 90,
        nilaiKontrak: 'Rp 250.000.000',
        instansiDinas: ['DPU-PR'],
        sumberDana: 'APBD',
        deskripsi: 'Uji race condition inisialisasi',
        kegiatans: [],
      );
      final addFuture = contractProv.addContract(initialContract);

      final updatedContract = ContractModel(
        id: 'c_race_01',
        namaKontrak: 'Kontrak Uji Race Diperbarui',
        jenisKegiatan: 'Pengawasan Teknis',
        nomorSpk: 'SPK-RACE-01',
        tglMulaiSpk: '2026-06-01',
        nomorSpmk: 'SPMK-RACE-01',
        tglMulaiSpmk: '2026-06-01',
        tglSelesaiSpmk: '2026-08-30',
        hariKalender: 90,
        nilaiKontrak: 'Rp 300.000.000',
        instansiDinas: ['DPU-PR'],
        sumberDana: 'APBD',
        deskripsi: 'Uji race condition update',
        kegiatans: [],
      );
      await addFuture;
      await contractProv.updateContract(updatedContract);

      // Tunggu seluruh future constructor (_initLoad / _loadContracts / _loadFromLocalFallback) selesai
      await Future.delayed(const Duration(milliseconds: 100));

      expect(contractProv.contracts.length, 1);
      expect(contractProv.contracts.first.namaKontrak, 'Kontrak Uji Race Diperbarui');

      // Uji deleteContract tetap bertahan setelah async selesai
      await contractProv.deleteContract('c_race_01');
      await Future.delayed(const Duration(milliseconds: 50));
      expect(contractProv.contracts, isEmpty);
    });
  });
}
