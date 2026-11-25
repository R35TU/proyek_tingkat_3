import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      // Simulasikan storage yang menyimpan kontrak manual pengguna (id unik baru, nama MT Haryono)
      SharedPreferences.setMockInitialValues({
        'contracts': '[{"id":"kontrak_user_12345","namaKontrak":"PEMELIHARAAN BERKALA JL. MT HARYONO","jenisKegiatan":"Pengawasan Teknis","nomorSpk":"SPK-01","kegiatans":[]}]',
        'tata_saka_timeline_events_v1': '[{"id":"ev_user_01","timestamp":"2026-05-18T10:30:00.000","actorName":"Site Engineer","actorRole":"Konsultan","actionType":"APPROVE","entityType":"LAPORAN","contractId":"kontrak_user_12345","contractName":"PEMELIHARAAN BERKALA JL. MT HARYONO","title":"Pengesahan"}]',
      });

      final contractProv = ContractProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Kontrak manual pengguna TIDAK boleh disaring atau dihapus
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
  });
}
