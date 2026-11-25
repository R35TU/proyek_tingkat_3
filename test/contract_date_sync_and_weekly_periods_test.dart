import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_mingguan_screen.dart';
import 'package:tata_saka_app/screens/form_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/screens/laporan_mingguan_screen.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';
import 'package:tata_saka_app/utils/execution_period_helper.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ContractModel buildInitialContract({
    List<dynamic> laporans = const [],
    List<dynamic> laporanMingguan = const [],
  }) {
    return ContractModel(
      id: 'kontrak-uji-tgl',
      jenisKegiatan: 'Pengawasan Teknis',
      namaKontrak: 'Paket Pengawasan Jalan Baru',
      nomorSpk: '001/SPK/BM/2026',
      tglMulaiSpk: '20 April 2026',
      nomorSpmk: '001/SPMK/BM/2026',
      tglMulaiSpmk: '20 April 2026',
      tglSelesaiSpmk: '18 Juli 2026',
      hariKalender: 90,
      nilaiKontrak: 'Rp 500.000.000,00',
      instansiDinas: ['DPU-PR Kab. Purbalingga'],
      sumberDana: 'APBD Kab. Purbalingga',
      deskripsi: 'Kontrak pengujian sinkronisasi tanggal',
      kegiatans: [
        {
          'id': 'keg-uji-1',
          'namaKegiatan': 'Peningkatan Jalan Uji',
          'lokasi': 'Kec. Purbalingga',
          'sumberDana': 'APBD Kab. Purbalingga',
          'konsultanPengawas': 'CV. TATA SAKA CONSULTANT',
          'noSpkKonsultan': '001/SPK/BM/2026',
          'tglSpkKonsultan': '20 April 2026',
          'noSpmkKonsultan': '001/SPMK/BM/2026',
          'tglSpmkKonsultan': '20 April 2026',
          'awalPelaksanaan': '20 April 2026',
          'akhirPelaksanaan': '18 Juli 2026',
          'masaPelaksanaan': '90 (Sembilan Puluh) hari kalender',
          'kontraktor': 'CV. KARYA MANDIRI',
          'noSuratPesanan': '002/SP/BM/2026',
          'tglSuratPesanan': '20 April 2026',
          'noSpmkKontraktor': '002/SPMK/BM/2026',
          'tglSpmkKontraktor': '20 April 2026',
          'jangkaWaktu': '90 (Sembilan Puluh) hari kalender',
          'tglAkhirSpmkKontraktor': '18 Juli 2026',
          'nilaiKontrak': 'Rp 300.000.000,00',
          'rkkDivisiList': [
            {
              'nomorRomawi': 'I',
              'namaDivisi': 'DIVISI 1 UMUM',
              'items': [
                {
                  'no': '1',
                  'noMataPembayaran': '1.2',
                  'uraian': 'Pekerjaan Galian Batu',
                  'satuan': 'm3',
                  'hargaSatuan': 100000000.0,
                  'volume': 3.0,
                  'volumeCCO': 3.0,
                  'totalHarga': 300000000.0,
                  'nilaiBobot': 100.0,
                },
              ],
            },
          ],
          'laporans': List<dynamic>.from(laporans),
          'laporanMingguan': List<dynamic>.from(laporanMingguan),
        },
      ],
    );
  }

  group('Sinkronisasi Tanggal Kontrak -> Kegiatan -> Pelaporan (Skenario 1-11)', () {
    test('Skenario 1-7: Ubah kontrak 20 Apr -> 20 Nov 2026 (90 hari) menghasilkan akhir 17 Feb 2027 dan sinkron ke kegiatan, mingguan, bulanan', () {
      // 1-2. Kontrak awal 20 April 2026 (90 hari) & kegiatan di dalamnya
      final oldContract = buildInitialContract();
      expect(
        KegiatanModel.calculateTanggalAkhirSpmk('20 April 2026', '90'),
        '18 Juli 2026',
      );

      // 3-4. Ubah kontrak ke 20 November 2026 dengan durasi tetap 90 hari kalender
      final newEndStr =
          KegiatanModel.calculateTanggalAkhirSpmk('20 November 2026', '90');
      expect(newEndStr, '17 Februari 2027');

      final editedContractDraft = ContractModel(
        id: oldContract.id,
        jenisKegiatan: oldContract.jenisKegiatan,
        namaKontrak: oldContract.namaKontrak,
        nomorSpk: oldContract.nomorSpk,
        tglMulaiSpk: '20 November 2026',
        nomorSpmk: oldContract.nomorSpmk,
        tglMulaiSpmk: '20 November 2026',
        tglSelesaiSpmk: newEndStr,
        hariKalender: 90,
        nilaiKontrak: oldContract.nilaiKontrak,
        instansiDinas: oldContract.instansiDinas,
        sumberDana: oldContract.sumberDana,
        deskripsi: oldContract.deskripsi,
        kegiatans: oldContract.kegiatans,
      );

      // 5. Sinkronkan tanggal kontrak ke kegiatan
      final syncedContract =
          ExecutionPeriodHelper.syncContractDatesToKegiatans(
        oldContract: oldContract,
        newContract: editedContractDraft,
        forceSyncAll: true,
      );

      final syncedKeg = syncedContract.kegiatans.first;
      expect(syncedKeg['awalPelaksanaan'], '20 November 2026');
      expect(syncedKeg['akhirPelaksanaan'], '17 Februari 2027');
      expect(syncedKeg['tglSpmkKontraktor'], '20 November 2026');
      expect(syncedKeg['tglAkhirSpmkKontraktor'], '17 Februari 2027');

      // Single source of truth resolver juga mengembalikan rentang terbaru
      final resolved = ExecutionPeriodHelper.resolveExecutionPeriod(
        syncedKeg,
        contract: syncedContract,
      );
      expect(resolved.startDate, DateTime(2026, 11, 20));
      expect(resolved.endDate, DateTime(2027, 2, 17));
      expect(resolved.durationDays, 90);
      expect(resolved.totalWeeks, 13);

      // 6. Periode Laporan Mingguan terbentuk dari tanggal terbaru
      final weeks = ExecutionPeriodHelper.generateWeeklyPeriods(
        contract: syncedContract,
        kegMap: syncedKeg,
        referenceDate: DateTime(2026, 11, 25),
      );
      expect(weeks.length, 13);
      expect(weeks[0].periodeAwal, '20 November 2026');
      expect(weeks[0].periodeAkhir, '26 November 2026');
      expect(weeks[1].periodeAwal, '27 November 2026');
      expect(weeks[1].periodeAkhir, '3 Desember 2026');
      expect(weeks[2].periodeAwal, '4 Desember 2026');
      expect(weeks[2].periodeAkhir, '10 Desember 2026');
      expect(weeks[3].periodeAwal, '11 Desember 2026');
      expect(weeks[3].periodeAkhir, '17 Desember 2026');
      expect(weeks[12].periodeAwal, '12 Februari 2027');
      expect(weeks[12].periodeAkhir, '17 Februari 2027');
      expect(weeks[12].daysCount, 6);

      // 7. Periode Laporan Bulanan terbentuk dari tanggal terbaru
      final months = MonthlyReportModel.generateFromWeeklyReports(
        contract: syncedContract,
        kegiatan: syncedKeg,
      );
      expect(months.length, 4);
      expect(
        months[0].periodeFormatted,
        '20 November 2026 - 17 Desember 2026',
      );
      expect(
        months[1].periodeFormatted,
        '18 Desember 2026 - 14 Januari 2027',
      );
      expect(
        months[2].periodeFormatted,
        '15 Januari 2027 - 11 Februari 2027',
      );
      expect(
        months[3].periodeFormatted,
        '12 Februari 2027 - 17 Februari 2027',
      );
    });

    test('Skenario 8-9-11: Laporan harian 25 Nov 2026 (vol 1.5 / 3 = 50%) masuk ke Minggu 1 & Bulan 1 tanpa merusak laporan historis lama', () {
      // Simulasi terdapat laporan historis lama (22 April 2026) dan laporan mingguan lama (April 2026)
      final oldHistoricalWeekly = WeeklyReportModel(
        id: 'weekly-apr-1',
        pekerjaan: 'Peningkatan Jalan Uji',
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
        rencanaPersen: 5.0,
        rencanaNominal: 15000000.0,
        realisasiPersen: 10.0,
        realisasiNominal: 30000000.0,
        deviasiPersen: 5.0,
        deviasiNominal: 15000000.0,
        waktuTerpakai: 7,
        sisaWaktu: 83,
        akhirMasaKontrak: '18 Juli 2026',
        tabelMingguan: [],
      ).toJson();

      final historicalDailyApr = {
        'id': 'daily-apr-22',
        'tanggal': '2026-04-22',
        'tanggalFormatted': 'Rabu, 22 April 2026',
        'pekerjaanList': [
          {
            'noMataPembayaran': '1.2',
            'jenis': 'Pekerjaan Galian Batu',
            'volume': '0.3 m3',
          },
        ],
      };

      final newDailyNov25 = {
        'id': 'daily-nov-25',
        'tanggal': '2026-11-25',
        'tanggalFormatted': 'Rabu, 25 November 2026',
        'pekerjaanList': [
          {
            'noMataPembayaran': '1.2',
            'jenis': 'Pekerjaan Galian Batu',
            'volume': '1.5 m3',
          },
        ],
      };

      final oldContract = buildInitialContract(
        laporans: [historicalDailyApr, newDailyNov25],
        laporanMingguan: [oldHistoricalWeekly],
      );

      final newEnd =
          KegiatanModel.calculateTanggalAkhirSpmk('20 November 2026', '90');
      final draftNew = ContractModel(
        id: oldContract.id,
        jenisKegiatan: oldContract.jenisKegiatan,
        namaKontrak: oldContract.namaKontrak,
        nomorSpk: oldContract.nomorSpk,
        tglMulaiSpk: '20 November 2026',
        nomorSpmk: oldContract.nomorSpmk,
        tglMulaiSpmk: '20 November 2026',
        tglSelesaiSpmk: newEnd,
        hariKalender: 90,
        nilaiKontrak: oldContract.nilaiKontrak,
        instansiDinas: oldContract.instansiDinas,
        sumberDana: oldContract.sumberDana,
        deskripsi: oldContract.deskripsi,
        kegiatans: oldContract.kegiatans,
      );

      final analysis = ExecutionPeriodHelper.analyzeContractDateChange(
        oldContract,
        draftNew,
      );
      expect(analysis.datesChanged, isTrue);
      expect(analysis.dailyReportsOutsideCount, 1);
      expect(analysis.weeklyReportsOutsideCount, 1);

      final synced = ExecutionPeriodHelper.syncContractDatesToKegiatans(
        oldContract: oldContract,
        newContract: draftNew,
        forceSyncAll: true,
      );

      final keg = synced.kegiatans.first;
      // Skenario 11: Laporan historis tidak hilang atau berubah
      final savedLaporans = keg['laporans'] as List;
      expect(savedLaporans.length, 2);
      expect(savedLaporans.any((r) => r['id'] == 'daily-apr-22'), isTrue);
      final savedWeekly = keg['laporanMingguan'] as List;
      expect(savedWeekly.length, 1);
      expect(savedWeekly.first['periodeAwal'], '20 April 2026');

      // Skenario 8-9: Realisasi 25 Nov 2026 (1.5 / 3.0 = 50%) masuk tepat ke Minggu 1 & Bulan 1
      // serta laporan historis 22 April 2026 TIDAK bocor ke Minggu Lalu / Bulan Lalu
      final weeks = ExecutionPeriodHelper.generateWeeklyPeriods(
        contract: synced,
        kegMap: keg,
        referenceDate: DateTime(2026, 11, 25),
      );
      expect(weeks[0].mingguKe, 1);
      expect(weeks[0].hasDailyReportsInWeek, isTrue);
      expect(weeks[0].realisasiMingguIniPersen, closeTo(50.0, 0.01));
      expect(weeks[0].realisasiSdMingguIniPersen, closeTo(50.0, 0.01));
      expect(weeks[0].boqResult.totalBobotPeriodeLalu, 0.0);

      // Di Minggu 2 (27 Nov - 3 Des), realisasi 25 Nov 2026 otomatis berpindah ke Minggu Lalu
      expect(weeks[1].realisasiMingguIniPersen, 0.0);
      expect(weeks[1].boqResult.totalBobotPeriodeLalu, closeTo(50.0, 0.01));
      expect(weeks[1].realisasiSdMingguIniPersen, closeTo(50.0, 0.01));

      // Di Laporan Bulanan: periode tetap November 2026 & realisasi Bulan 1 = 50% (bukan tanggal April)
      final months = MonthlyReportModel.generateFromWeeklyReports(
        contract: synced,
        kegiatan: keg,
      );
      expect(
        months[0].periodeFormatted,
        '20 November 2026 - 17 Desember 2026',
      );
      expect(months[0].totalBobotBulanLalu, 0.0);
      expect(months[0].totalBobotBulanIni, closeTo(50.0, 0.01));
      expect(months[0].totalBobotSdBulanIni, closeTo(50.0, 0.01));
    });

    test('Skenario 10: Status Mingguan (On Progress, Completed, Upcoming) ditentukan oleh tanggal periode & kondisi laporan', () {
      final contract = buildInitialContract();
      final endNew =
          KegiatanModel.calculateTanggalAkhirSpmk('20 November 2026', '90');
      final draftNew = ContractModel(
        id: contract.id,
        jenisKegiatan: contract.jenisKegiatan,
        namaKontrak: contract.namaKontrak,
        nomorSpk: contract.nomorSpk,
        tglMulaiSpk: '20 November 2026',
        nomorSpmk: contract.nomorSpmk,
        tglMulaiSpmk: '20 November 2026',
        tglSelesaiSpmk: endNew,
        hariKalender: 90,
        nilaiKontrak: contract.nilaiKontrak,
        instansiDinas: contract.instansiDinas,
        sumberDana: contract.sumberDana,
        deskripsi: contract.deskripsi,
        kegiatans: contract.kegiatans,
      );
      final synced = ExecutionPeriodHelper.syncContractDatesToKegiatans(
        oldContract: contract,
        newContract: draftNew,
        forceSyncAll: true,
      );

      // Tambahkan laporan mingguan tersimpan HANYA untuk Minggu 1 (20 Nov - 26 Nov 2026)
      final savedWeek1 = WeeklyReportModel(
        id: 'w-nov-1',
        pekerjaan: 'Peningkatan Jalan Uji',
        lokasiProyek: 'Kec. Purbalingga',
        kontraktor: 'CV. KARYA MANDIRI',
        jangkaWaktu: 90,
        nomorKontrak: '001/SPK/BM/2026',
        tanggalKontrak: '20 November 2026',
        nilaiKontrak: 'Rp 300.000.000,00',
        nilaiKontrakNumeric: 300000000.0,
        tanggalSpmk: '20 November 2026',
        mingguKe: 1,
        totalMinggu: 13,
        periodeAwal: '20 November 2026',
        periodeAkhir: '26 November 2026',
        rencanaPersen: 10.0,
        rencanaNominal: 30000000.0,
        realisasiPersen: 50.0,
        realisasiNominal: 150000000.0,
        deviasiPersen: 40.0,
        deviasiNominal: 120000000.0,
        waktuTerpakai: 7,
        sisaWaktu: 83,
        akhirMasaKontrak: '17 Februari 2027',
        tabelMingguan: [],
      ).toJson();
      synced.kegiatans.first['laporanMingguan'] = [savedWeek1];

      // 1) Jika referenceDate = 25 November 2026 (MASIH di dalam Minggu 1):
      // Meskipun laporan Minggu 1 sudah ada/tersimpan, periode Minggu 1 BELUM berakhir -> On Progress!
      final weeksDuringW1 = ExecutionPeriodHelper.generateWeeklyPeriods(
        contract: synced,
        kegMap: synced.kegiatans.first,
        referenceDate: DateTime(2026, 11, 25),
      );
      expect(weeksDuringW1[0].status, WeeklyPeriodStatus.onProgress);
      expect(weeksDuringW1[0].statusLabel, 'On Progress');
      expect(weeksDuringW1[1].status, WeeklyPeriodStatus.upcoming);
      expect(weeksDuringW1[1].statusLabel, 'Upcoming');

      // 2) Jika referenceDate = 28 November 2026 (Minggu 1 sudah berakhir & laporan ada; Minggu 2 sedang berlangsung tanpa laporan; Minggu 3 belum dimulai):
      final weeksDuringW2 = ExecutionPeriodHelper.generateWeeklyPeriods(
        contract: synced,
        kegMap: synced.kegiatans.first,
        referenceDate: DateTime(2026, 11, 28),
      );
      expect(weeksDuringW2[0].status, WeeklyPeriodStatus.completed);
      expect(weeksDuringW2[0].statusLabel, 'Completed');
      expect(weeksDuringW2[1].status, WeeklyPeriodStatus.onProgress);
      expect(weeksDuringW2[1].statusLabel, 'On Progress');
      expect(weeksDuringW2[2].status, WeeklyPeriodStatus.upcoming);
      expect(weeksDuringW2[2].statusLabel, 'Upcoming');

      // 3) Jika referenceDate = 10 Desember 2026 & Minggu 2 sudah berakhir TETAPI belum ada laporan mingguan:
      // Tidak boleh Completed karena laporan belum diselesaikan -> tetap On Progress!
      final weeksLater = ExecutionPeriodHelper.generateWeeklyPeriods(
        contract: synced,
        kegMap: synced.kegiatans.first,
        referenceDate: DateTime(2026, 12, 10),
      );
      expect(weeksLater[1].status, WeeklyPeriodStatus.onProgress);
      expect(weeksLater[1].statusLabel, 'On Progress');
    });
  });

  group('UI Widget & Screen Integration Tests', () {
    Widget wrapWithProviders(
      Widget child,
      ContractProvider contractProvider,
    ) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
          ChangeNotifierProvider<UserProfileProvider>(
            create: (_) => UserProfileProvider(),
          ),
          ChangeNotifierProvider<TimelineProvider>(
            create: (_) => TimelineProvider(),
          ),
        ],
        child: MaterialApp(
          locale: const Locale('id', 'ID'),
          supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: child,
        ),
      );
    }

    testWidgets('LaporanMingguanScreen menampilkan seluruh 13 minggu, status, realisasi harian otomatis, dan bebas overflow pada 320px/360px', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final contract = buildInitialContract(
        laporans: [
          {
            'id': 'daily-nov-25',
            'tanggal': '2026-11-25',
            'tanggalFormatted': 'Rabu, 25 November 2026',
            'pekerjaanList': [
              {
                'noMataPembayaran': '1.2',
                'jenis': 'Pekerjaan Galian Batu',
                'volume': '1.5 m3',
              },
            ],
          },
        ],
      );
      final synced = ExecutionPeriodHelper.syncContractDatesToKegiatans(
        oldContract: contract,
        newContract: ContractModel(
          id: contract.id,
          jenisKegiatan: contract.jenisKegiatan,
          namaKontrak: contract.namaKontrak,
          nomorSpk: contract.nomorSpk,
          tglMulaiSpk: '20 November 2026',
          nomorSpmk: contract.nomorSpmk,
          tglMulaiSpmk: '20 November 2026',
          tglSelesaiSpmk: '17 Februari 2027',
          hariKalender: 90,
          nilaiKontrak: contract.nilaiKontrak,
          instansiDinas: contract.instansiDinas,
          sumberDana: contract.sumberDana,
          deskripsi: contract.deskripsi,
          kegiatans: contract.kegiatans,
        ),
        forceSyncAll: true,
      );

      final provider = ContractProvider();
      provider.addContract(synced);

      await tester.pumpWidget(
        wrapWithProviders(
          LaporanMingguanScreen(
            initialContract: synced,
            referenceDate: DateTime(2026, 11, 25),
          ),
          provider,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laporan Mingguan'), findsOneWidget);
      expect(find.text('Daftar Periode Mingguan'), findsOneWidget);
      expect(find.textContaining('20 November 2026 s/d 17 Februari 2027'), findsOneWidget);
      expect(find.text('Minggu 1'), findsOneWidget);
      expect(find.text('20 November 2026 - 26 November 2026 (7 hari)'), findsOneWidget);
      expect(find.text('On Progress'), findsWidgets);
      expect(find.text('Upcoming'), findsWidgets);
      // Realisasi otomatis 50.00% dari laporan harian 25 Nov 2026 tampil di kartu Minggu 1
      expect(find.text('50.00%'), findsWidgets);
      expect(tester.takeException(), isNull);

      // Uji kembali pada lebar ultra-sempit 320px
      tester.view.physicalSize = const Size(320, 750);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Klik Minggu 1 -> mengarah ke BuatLaporanMingguanScreen dengan periode minggu 1
      await tester.tap(find.text('Minggu 1'));
      await tester.pumpAndSettle();
      expect(find.byType(BuatLaporanMingguanScreen), findsOneWidget);
      expect(find.text('Minggu 1 / 13'), findsOneWidget);
      expect(find.text('20 November 2026'), findsWidgets);
      expect(find.text('26 November 2026'), findsWidgets);
    });

    testWidgets('TambahKontrakScreen menampilkan dialog sinkronisasi saat tanggal kontrak diubah & memperbarui kegiatan', (tester) async {
      tester.view.physicalSize = const Size(500, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final oldContract = buildInitialContract();
      final provider = ContractProvider();
      provider.addContract(oldContract);

      await tester.pumpWidget(
        wrapWithProviders(
          TambahKontrakScreen(contractToEdit: oldContract),
          provider,
        ),
      );
      await tester.pumpAndSettle();

      // Ubah Jangka Waktu dari 90 menjadi 60 hari untuk memicu perubahan tanggal selesai
      final jangkaField = find.widgetWithText(TextFormField, '90');
      await tester.enterText(jangkaField, '60');
      await tester.pumpAndSettle();

      // 20 April 2026 + 60 hari kalender = 18 Juni 2026
      expect(find.text('18 Juni 2026'), findsWidgets);

      // Scroll ke tombol Simpan Perubahan dan tekan
      final saveBtn = find.text('Simpan Perubahan');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Dialog sinkronisasi harus muncul dengan pilihan Sinkronkan Kegiatan
      expect(find.text('Sinkronkan Tanggal ke Kegiatan?'), findsOneWidget);
      await tester.tap(find.text('Sinkronkan Kegiatan'));
      await tester.pumpAndSettle();

      final updated = provider.contracts.firstWhere((c) => c.id == oldContract.id);
      expect(updated.hariKalender, 60);
      expect(updated.tglSelesaiSpmk, '18 Juni 2026');
      expect(updated.kegiatans.first['akhirPelaksanaan'], '18 Juni 2026');
      expect(updated.kegiatans.first['tglAkhirSpmkKontraktor'], '18 Juni 2026');
      expect(
        updated.kegiatans.first['jangkaWaktu'],
        '60 (Enam Puluh) hari kalender',
      );
    });

    testWidgets('FormKegiatanScreen melakukan sinkronisasi dua arah ketika Masa Pelaksanaan / Section 2 diubah', (tester) async {
      tester.view.physicalSize = const Size(450, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final contract = buildInitialContract();

      await tester.pumpWidget(
        MaterialApp(
          home: FormKegiatanScreen(
            contract: contract,
            initialKegiatan: contract.kegiatans.first,
            kegiatanIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Awal & SPMK sama-sama 20 April 2026 .. 18 Juli 2026 (90 hari)
      // Ubah Masa Pelaksanaan menjadi 45 hari -> Akhir Pelaksanaan & Tanggal Akhir SPMK otomatis ikut berubah ke 3 Juni 2026!
      final masaField = find.widgetWithText(
        TextFormField,
        '90 (Sembilan Puluh) hari kalender',
      ).first;
      await tester.enterText(masaField, '45 hari kalender');
      await tester.pumpAndSettle();

      // 20 April 2026 + 45 hari - 1 = 3 Juni 2026
      expect(find.text('3 Juni 2026'), findsWidgets);
    });

    testWidgets('LaporanBulananScreen selalu memperbarui periode bulan saat kontrak di provider diperbarui', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final oldContract = buildInitialContract();
      final provider = ContractProvider();
      provider.addContract(oldContract);

      await tester.pumpWidget(
        wrapWithProviders(
          LaporanBulananScreen(initialContract: oldContract),
          provider,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('20 April 2026 - 17 Mei 2026'), findsOneWidget);

      // Update kontrak & sinkronkan ke November 2026 di provider
      final synced = ExecutionPeriodHelper.syncContractDatesToKegiatans(
        oldContract: oldContract,
        newContract: ContractModel(
          id: oldContract.id,
          jenisKegiatan: oldContract.jenisKegiatan,
          namaKontrak: oldContract.namaKontrak,
          nomorSpk: oldContract.nomorSpk,
          tglMulaiSpk: '20 November 2026',
          nomorSpmk: oldContract.nomorSpmk,
          tglMulaiSpmk: '20 November 2026',
          tglSelesaiSpmk: '17 Februari 2027',
          hariKalender: 90,
          nilaiKontrak: oldContract.nilaiKontrak,
          instansiDinas: oldContract.instansiDinas,
          sumberDana: oldContract.sumberDana,
          deskripsi: oldContract.deskripsi,
          kegiatans: oldContract.kegiatans,
        ),
        forceSyncAll: true,
      );
      await provider.updateContract(synced);
      await tester.pumpAndSettle();

      expect(find.text('20 November 2026 - 17 Desember 2026'), findsOneWidget);
      expect(find.text('20 April 2026 - 17 Mei 2026'), findsNothing);
    });
  });
}
