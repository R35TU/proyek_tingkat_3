import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pembersihan Data Dummy MT Haryono & Pencegahan Re-seed Tests', () {
    test('1. Dokumen referensi eksternal Markdown dan PDF jika ada di direktori proyek', () {
      final mdFile = File('REFERENSI_DUMMY_PEMELIHARAAN_BERKALA_JL_MT_HARYONO.md');
      if (mdFile.existsSync()) {
        final mdContent = mdFile.readAsStringSync();

        // Memastikan Bagian A (Deskripsi Kontrak)
        expect(mdContent.contains('PEMELIHARAAN BERKALA JL. MT HARYONO'), isTrue);
        expect(mdContent.contains('kontrak-mt-haryono-demo'), isTrue);
        expect(mdContent.contains('000.3.2/1691.1/WAS-21/SPK-BM/1.03.10.2.01.0056/2026'), isTrue);
        expect(mdContent.contains('Rp 288.350.000,00'), isTrue);
        expect(mdContent.contains('SENDAYU GALIH K., ST'), isTrue);

        // Memastikan Bagian B (3 Kegiatan Lengkap)
        expect(mdContent.contains('Ruas Jalan A'), isTrue);
        expect(mdContent.contains('Ruas Jalan B'), isTrue);
        expect(mdContent.contains('Ruas Jalan C'), isTrue);
        expect(mdContent.contains('CV. DIVAN INSAN CEMERLANG'), isTrue);
        expect(mdContent.contains('CV. LANGGENG'), isTrue);

        // Memastikan Bagian C (3 RAB Lengkap)
        expect(mdContent.contains('DIVISI 1 UMUM'), isTrue);
        expect(mdContent.contains('DIVISI 2. DRAINASE'), isTrue);
        expect(mdContent.contains('DIVISI 6. PERKERASAN ASPAL'), isTrue);
        expect(mdContent.contains('DIVISI 7 STRUKTUR'), isTrue);
        expect(mdContent.contains('Rp 100.000.000,00'), isTrue);
        expect(mdContent.contains('Rp 80.000.000,00'), isTrue);
      }

      final pdfFile = File('REFERENSI_DUMMY_PEMELIHARAAN_BERKALA_JL_MT_HARYONO.pdf');
      if (pdfFile.existsSync()) {
        expect(pdfFile.lengthSync(), greaterThan(10000));
      }
    });

    test('2. ContractProvider inisialisasi awal tidak menginjeksi data dummy saat storage kosong', () async {
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

    test('3. TimelineProvider inisialisasi default tidak memasukkan event dummy MT Haryono', () async {
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

    test('4. Data dummy lama di local storage otomatis dibersihkan dan disaring keluar', () async {
      // Simulasikan storage lama yang menyimpan kontrak MT Haryono
      SharedPreferences.setMockInitialValues({
        'contracts': '[{"id":"kontrak-mt-haryono-demo","namaKontrak":"PEMELIHARAAN BERKALA JL. MT HARYONO","jenisKegiatan":"Pengawasan Teknis","nomorSpk":"SPK-01","kegiatans":[]}]',
        'app_timeline_events': '[{"id":"old_ev_01","timestamp":"2026-05-18T10:30:00.000","actorName":"Site Engineer","actorRole":"Konsultan","actionType":"APPROVE","entityType":"LAPORAN","contractId":"kontrak-mt-haryono-demo","contractName":"PEMELIHARAAN BERKALA JL. MT HARYONO","title":"Pengesahan"}]',
      });

      final contractProv = ContractProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        contractProv.contracts.any((c) => c.id == 'kontrak-mt-haryono-demo'),
        isFalse,
      );

      final timelineProv = TimelineProvider();
      await timelineProv.loadEvents();
      expect(
        timelineProv.allEvents.any((e) => e.contractId == 'kontrak-mt-haryono-demo'),
        isFalse,
      );
    });

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
