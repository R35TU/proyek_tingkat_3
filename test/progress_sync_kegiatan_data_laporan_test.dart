import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ContractModel buildSyncTestContract({
    required List<dynamic> laporans,
    List<dynamic> laporanMingguan = const [],
    double staleProgressFisik = 0.0,
  }) {
    return ContractModel(
      id: 'c-sync-progress',
      jenisKegiatan: 'Pengawasan Teknis',
      namaKontrak: 'Paket Sinkronisasi Progres',
      nomorSpk: '001/SPK/BM/2026',
      tglMulaiSpk: '20 April 2026',
      nomorSpmk: '001/SPMK/BM/2026',
      tglMulaiSpmk: '20 April 2026',
      tglSelesaiSpmk: '18 Juli 2026',
      hariKalender: 90,
      nilaiKontrak: 'Rp 300.000.000,00',
      instansiDinas: ['DPU-PR Kab. Purbalingga'],
      sumberDana: 'APBD Kab. Purbalingga',
      deskripsi: 'Pengujian sinkronisasi progres',
      kegiatans: [
        {
          'id': 'keg-sync-1',
          'namaKegiatan': 'Ruas Jalan Sinkron',
          'lokasi': 'Kec. Purbalingga',
          'kontraktor': 'CV. KARYA MANDIRI',
          'tglSpmkKontraktor': '20 April 2026',
          'tglAkhirSpmkKontraktor': '18 Juli 2026',
          'jangkaWaktu': '90 (Sembilan Puluh) hari kalender',
          'nilaiKontrak': 'Rp 300.000.000,00',
          if (staleProgressFisik > 0) 'progressFisik': staleProgressFisik,
          'rkkDivisiList': [
            {
              'nomorRomawi': 'I',
              'namaDivisi': 'DIVISI I. UMUM',
              'items': [
                {
                  'id': 'item-1',
                  'no': '1',
                  'noMataPembayaran': '1.2',
                  'uraian': 'Pekerjaan Galian',
                  'satuan': 'm3',
                  'hargaSatuan': 100000000.0,
                  'volume': 4.0,
                  'volumeCCO': 4.0,
                  'totalHarga': 400000000.0,
                  'nilaiBobot': 100.0,
                },
              ],
            },
          ],
          'laporans': laporans,
          'laporanMingguan': laporanMingguan,
        },
      ],
    );
  }

  group('Sinkronisasi Progres Tab Kegiatan vs Tab Data Laporan', () {
    test(
      '1. ProgressCalculator memfilter laporan harian di luar periode pelaksanaan & tidak terjebak fallback usang saat harian kosong',
      () {
        final contract = buildSyncTestContract(
          staleProgressFisik: 0.25,
          laporans: [
            // Di luar periode kontrak (sebelum 20 April 2026) -> wajib diabaikan
            {
              'id': 'rep-outside',
              'tanggal': '2026-03-15',
              'pekerjaanList': [
                {
                  'rkkItemId': 'item-1',
                  'noMataPembayaran': '1.2',
                  'uraian': 'Pekerjaan Galian',
                  'volume': '1.0 m3',
                },
              ],
            },
            // Di dalam periode kontrak -> 2.0 / 4.0 * 100 = 50.0%
            {
              'id': 'rep-inside',
              'tanggal': '2026-04-22',
              'pekerjaanList': [
                {
                  'rkkItemId': 'item-1',
                  'noMataPembayaran': '1.2',
                  'uraian': 'Pekerjaan Galian',
                  'volume': '2.0 m3',
                },
              ],
            },
          ],
          laporanMingguan: [
            WeeklyReportModel(
              id: 'w-stale',
              pekerjaan: 'Ruas Jalan Sinkron',
              lokasiProyek: 'Kec. Purbalingga',
              kontraktor: 'CV. KARYA MANDIRI',
              jangkaWaktu: 90,
              nomorKontrak: '001/SPK/BM/2026',
              tanggalKontrak: '20 April 2026',
              nilaiKontrak: 'Rp 300.000.000,00',
              nilaiKontrakNumeric: 300000000.0,
              tanggalSpmk: '20 April 2026',
              mingguKe: 1,
              totalMinggu: 13,
              periodeAwal: '20 April 2026',
              periodeAkhir: '26 April 2026',
              rencanaPersen: 10.0,
              rencanaNominal: 30000000.0,
              realisasiPersen: 10.0,
              realisasiNominal: 30000000.0,
              deviasiPersen: 0.0,
              deviasiNominal: 0.0,
              waktuTerpakai: 7,
              sisaWaktu: 83,
              akhirMasaKontrak: '18 Juli 2026',
              tabelMingguan: [],
            ).toJson(),
          ],
        );

        final keg = contract.kegiatans.first;
        final prog = ProgressCalculator.calculateKegiatanProgress(
          keg,
          contract: contract,
        );
        final boq = ProgressCalculator.calculateBoqProgress(
          kegMap: keg,
          startDt: DateTime(2026, 4, 20),
          endDt: DateTime(2026, 7, 18),
          minStartDt: DateTime(2026, 4, 20),
        );

        expect(prog, closeTo(50.0, 0.001));
        expect(boq.totalBobotSdIni, closeTo(prog, 0.001));

        // Jika semua laporan harian dalam periode dihapus, progres harus 0% (bukan 25% / 10% usang)
        keg['laporans'] = [];
        expect(
          ProgressCalculator.calculateKegiatanProgress(keg, contract: contract),
          equals(0.0),
        );
      },
    );

    testWidgets(
      '2. DataLaporanScreen, DetailKontrakScreen, DetailKegiatanScreen, dan DetailDataLaporanScreen Mingguan sinkron & update live setelah mutasi in-place',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final staleWeekly = WeeklyReportModel(
          id: 'w-1',
          pekerjaan: 'Ruas Jalan Sinkron',
          lokasiProyek: 'Kec. Purbalingga',
          kontraktor: 'CV. KARYA MANDIRI',
          jangkaWaktu: 90,
          nomorKontrak: '001/SPK/BM/2026',
          tanggalKontrak: '20 April 2026',
          nilaiKontrak: 'Rp 300.000.000,00',
          nilaiKontrakNumeric: 300000000.0,
          tanggalSpmk: '20 April 2026',
          mingguKe: 1,
          totalMinggu: 13,
          periodeAwal: '20 April 2026',
          periodeAkhir: '26 April 2026',
          rencanaPersen: 10.0,
          rencanaNominal: 30000000.0,
          // Nilai snapshot lama sengaja berbeda (12.34%) vs harian aktual (42.95%)
          realisasiPersen: 12.34,
          realisasiNominal: 37020000.0,
          deviasiPersen: 2.34,
          deviasiNominal: 7020000.0,
          waktuTerpakai: 7,
          sisaWaktu: 83,
          akhirMasaKontrak: '18 Juli 2026',
          tabelMingguan: [],
        ).toJson();

        // 1.718 / 4.0 * 100 = 42.95% (menguji tidak ada pemotongan .toInt() menjadi 42%)
        final contract = buildSyncTestContract(
          laporans: [
            {
              'id': 'rep-1',
              'tanggal': '2026-04-22',
              'pekerjaanList': [
                {
                  'rkkItemId': 'item-1',
                  'noMataPembayaran': '1.2',
                  'uraian': 'Pekerjaan Galian',
                  'volume': '1.718 m3',
                },
              ],
            },
          ],
          laporanMingguan: [staleWeekly],
        );

        final provider = ContractProvider();
        await provider.addContract(contract);
        final userProf = UserProfileProvider();
        final timelineProf = TimelineProvider();

        Widget wrap(Widget child) {
          return MultiProvider(
            providers: [
              ChangeNotifierProvider<ContractProvider>.value(value: provider),
              ChangeNotifierProvider<UserProfileProvider>.value(value: userProf),
              ChangeNotifierProvider<TimelineProvider>.value(value: timelineProf),
            ],
            child: MaterialApp(home: child),
          );
        }

        // A. DataLaporanScreen: menampilkan 43.0% (bukan 42%) dan 42.95% per kegiatan
        await tester.pumpWidget(wrap(const DataLaporanScreen()));
        await tester.pumpAndSettle();
        expect(find.text('43.0%'), findsOneWidget);
        expect(find.text('42.95%'), findsOneWidget);

        // B. DetailKontrakScreen: kartu kegiatan juga menampilkan 42.95%
        await tester.pumpWidget(wrap(DetailKontrakScreen(contract: contract)));
        await tester.pumpAndSettle();
        expect(find.text('42.95%'), findsOneWidget);

        // C. DetailDataLaporanScreen Tab Mingguan: menghitung ulang snapshot 12.34% -> 42,95 %
        await tester.pumpWidget(
          wrap(
            DetailDataLaporanScreen(
              contract: contract,
              kegiatanIndex: 0,
              initialTab: 1,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Progres: 42.95%'), findsOneWidget);
        expect(find.text('10,00 %'), findsOneWidget);
        expect(find.text('42,95 %'), findsOneWidget);
        expect(find.text('12,34 %'), findsNothing);

        // D. DetailKegiatanScreen: menampilkan 42.95% dan ikut live-update ke 75.00% saat mutasi in-place
        await tester.pumpWidget(
          wrap(
            DetailKegiatanScreen(
              contract: contract,
              kegiatanIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('42.95%'), findsOneWidget);

        // Simulasikan penambahan laporan harian secara in-place (+1.282 m3 -> total 3.000 m3 = 75.00%)
        final list = List<dynamic>.from(contract.kegiatans[0]['laporans'] as List);
        list.add({
          'id': 'rep-2',
          'tanggal': '2026-04-23',
          'pekerjaanList': [
            {
              'rkkItemId': 'item-1',
              'noMataPembayaran': '1.2',
              'uraian': 'Pekerjaan Galian',
              'volume': '1.282 m3',
            },
          ],
        });
        contract.kegiatans[0]['laporans'] = list;
        await provider.updateContract(contract);
        await tester.pumpAndSettle();

        expect(find.text('75.00%'), findsOneWidget);

        // Verifikasi DetailDataLaporanScreen juga menunjukkan 75.00% & 75,00 %
        await tester.pumpWidget(
          wrap(
            DetailDataLaporanScreen(
              contract: contract,
              kegiatanIndex: 0,
              initialTab: 1,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Progres: 75.00%'), findsOneWidget);
        expect(find.text('75,00 %'), findsOneWidget);
      },
    );
  });
}
