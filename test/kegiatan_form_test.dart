import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/screens/form_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/utils/indonesian_terbilang.dart';

void main() {
  group('IndonesianTerbilang Unit Tests', () {
    test('Converts numbers correctly', () {
      expect(IndonesianTerbilang.convert(0), 'Nol');
      expect(IndonesianTerbilang.convert(4), 'Empat');
      expect(IndonesianTerbilang.convert(12), 'Dua Belas');
      expect(IndonesianTerbilang.convert(60), 'Enam Puluh');
      expect(IndonesianTerbilang.convert(150), 'Seratus Lima Puluh');
    });

    test('Formats official document strings correctly', () {
      expect(IndonesianTerbilang.formatHariKalender(60), '60 (Enam Puluh) hari kalender');
      expect(IndonesianTerbilang.formatMinggu(4), '4 (Empat) Minggu');
    });
  });

  group('KegiatanModel Unit Tests', () {
    final mockContract = ContractModel(
      id: 'c-1',
      namaKontrak: 'Kontrak Pengawasan Jalan',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas PU'],
      nilaiKontrak: 'Rp 200.000.000,00',
      hariKalender: 60,
      tglMulaiSpk: '26 Mei 2026',
      nomorSpk: '000.3.2/1280.1/WAS-17/SPK-BM/1.03.10.2.01.0056/2026',
      nomorSpmk: '000.3.2/1463/WAS-17/SPMK-BM/1.03.10.2.01.0056/2026',
      tglMulaiSpmk: '18 Juni 2026',
      tglSelesaiSpmk: '16 Agustus 2026',
      sumberDana: 'APBD Kabupaten Purbalingga Tahun Anggaran 2026',
      deskripsi: 'Deskripsi proyek',
      kegiatans: [],
    );

    test('Full document string getters format correctly', () {
      final keg = KegiatanModel(
        namaKegiatan: 'Pemeliharaan Berkala Jalan Karangmoncol - Rajawana',
        noSpkKonsultan: '000.3.2/1280.1/WAS-17/SPK-BM/1.03.10.2.01.0056/2026',
        tglSpkKonsultan: '26 Mei 2026',
        noSpmkKonsultan: '000.3.2/1463/WAS-17/SPMK-BM/1.03.10.2.01.0056/2026',
        tglSpmkKonsultan: '18 Juni 2026',
        kontraktor: 'CV. SATYA WIGUNA',
        noSuratPesanan: 'EP-01KSHQ79D62E1FJ0RYT6WEBADX',
        tglSuratPesanan: '18 Juni 2026',
        noSpmkKontraktor: '000.3.3 / 1457 / SPMK / BM / VI / 2026',
        tglSpmkKontraktor: '18 Juni 2026',
        nilaiKontrak: 'Rp 1.723.985.515,00 (Termasuk PPN+PPH)',
      );

      expect(
        keg.spkKonsultanFull,
        '000.3.2/1280.1/WAS-17/SPK-BM/1.03.10.2.01.0056/2026 Tanggal 26 Mei 2026',
      );
      expect(
        keg.spmkKonsultanFull,
        '000.3.2/1463/WAS-17/SPMK-BM/1.03.10.2.01.0056/2026 Tanggal 18 Juni 2026',
      );
      expect(
        keg.suratPesananFull,
        'EP-01KSHQ79D62E1FJ0RYT6WEBADX Tanggal 18 Juni 2026',
      );
      expect(
        keg.spmkKontraktorFull,
        '000.3.3 / 1457 / SPMK / BM / VI / 2026 Tanggal 18 Juni 2026',
      );
    });

    test('calculateTanggalAkhirSpmk calculates inclusive end date correctly', () {
      // Skenario dari User: 20 April 2026 + 90 hari kalender -> 18 Juli 2026
      expect(
        KegiatanModel.calculateTanggalAkhirSpmk('20 April 2026', '90 (Sembilan Puluh) hari kalender'),
        '18 Juli 2026',
      );
      expect(
        KegiatanModel.calculateTanggalAkhirSpmk('20 April 2026', '90'),
        '18 Juli 2026',
      );
      expect(
        KegiatanModel.calculateTanggalAkhirSpmk('20 April 2026', '90 Hari'),
        '18 Juli 2026',
      );
      expect(
        KegiatanModel.calculateTanggalAkhirSpmk('Tanggal 20 April 2026', '90 hari kalender'),
        '18 Juli 2026',
      );
      // Skenario 1 September 2026 + 90 hari kalender -> 29 November 2026
      expect(
        KegiatanModel.calculateTanggalAkhirSpmk('1 September 2026', '90 hari kalender'),
        '29 November 2026',
      );
      // Skenario kosong / invalid
      expect(KegiatanModel.calculateTanggalAkhirSpmk('', '90'), '');
      expect(KegiatanModel.calculateTanggalAkhirSpmk('20 April 2026', ''), '');
      expect(KegiatanModel.calculateTanggalAkhirSpmk('invalid date', '90'), '');
    });

    test('Struktur organisasi getters and json serialization work properly', () {
      final keg = KegiatanModel(
        namaKegiatan: 'Pekerjaan Jembatan',
        penggunaAnggaran: 'DRAJAT UJI WAKHYONO, S.T., M.T.',
        stafTeknis1: 'MUBALLIGH, ST., M.Sc.',
        stafTeknis2: 'BILAL A.Md',
        siteEngineerKegiatan: 'SENDAYU GALIH K., ST',
        direkturPenyedia: 'IKSAN',
        direkturKontraktor: 'IKSAN',
        pelaksanaLapangan: 'GALIH WAHYU UTAMA',
        petugasK3: 'IQBAL ZAINUL ARIFIN',
      );

      expect(keg.stafTeknisDisplay, 'MUBALLIGH, ST., M.Sc. & BILAL A.Md');
      expect(keg.stafTeknisLabel, 'Staf Teknis 1 & 2');

      // Test label jika hanya satu staf teknis yang terisi
      final kegSingle1 = KegiatanModel(namaKegiatan: 'Jembatan A', stafTeknis1: 'MUBALLIGH');
      expect(kegSingle1.stafTeknisLabel, 'Staf Teknis 1');
      final kegSingle2 = KegiatanModel(namaKegiatan: 'Jembatan B', stafTeknis2: 'BILAL');
      expect(kegSingle2.stafTeknisLabel, 'Staf Teknis 2');

      final json = keg.toJson();
      final fromJsonKeg = KegiatanModel.fromJson(json);

      expect(fromJsonKeg.penggunaAnggaran, 'DRAJAT UJI WAKHYONO, S.T., M.T.');
      expect(fromJsonKeg.stafTeknis1, 'MUBALLIGH, ST., M.Sc.');
      expect(fromJsonKeg.stafTeknis2, 'BILAL A.Md');
      expect(fromJsonKeg.stafTeknisDisplay, 'MUBALLIGH, ST., M.Sc. & BILAL A.Md');
      expect(fromJsonKeg.siteEngineerKegiatan, 'SENDAYU GALIH K., ST');
      expect(fromJsonKeg.direkturPenyedia, 'IKSAN');
      expect(fromJsonKeg.direkturKontraktor, 'IKSAN');
      expect(fromJsonKeg.pelaksanaLapangan, 'GALIH WAHYU UTAMA');
      expect(fromJsonKeg.petugasK3, 'IQBAL ZAINUL ARIFIN');
    });

    test('Falls back to parent ContractModel when fields are empty', () {
      final keg = KegiatanModel.fromJson(
        {'namaKegiatan': 'Pekerjaan Jembatan'},
        fallbackContract: mockContract,
      );

      expect(keg.sumberDana, 'APBD Kabupaten Purbalingga Tahun Anggaran 2026');
      expect(keg.konsultanPengawas, 'CV. TATA SAKA CONSULTANT');
      expect(keg.noSpkKonsultan, '000.3.2/1280.1/WAS-17/SPK-BM/1.03.10.2.01.0056/2026');
      expect(keg.tglSpkKonsultan, '26 Mei 2026');
      expect(keg.awalPelaksanaan, '18 Juni 2026');
      expect(keg.akhirPelaksanaan, '16 Agustus 2026');
      expect(keg.masaPelaksanaan, '60 (Enam Puluh) hari kalender');
      expect(keg.jangkaWaktu, '60 (Enam Puluh) hari kalender');
      expect(keg.tglSuratPesanan, '26 Mei 2026');
      expect(keg.tglSpmkKontraktor, '18 Juni 2026');
    });

    test('parseIndonesianDate parses varied date formats and prefixes', () {
      final d1 = WeeklyReportModel.parseIndonesianDate('20 April 2026');
      expect(d1, DateTime(2026, 4, 20));

      final d2 = WeeklyReportModel.parseIndonesianDate('Tanggal 20 April 2026');
      expect(d2, DateTime(2026, 4, 20));

      final d3 = WeeklyReportModel.parseIndonesianDate('Tgl 20 April 2026');
      expect(d3, DateTime(2026, 4, 20));

      final d4 = WeeklyReportModel.parseIndonesianDate('20-04-2026');
      expect(d4, DateTime(2026, 4, 20));

      final d5 = WeeklyReportModel.parseIndonesianDate('20/04/2026');
      expect(d5, DateTime(2026, 4, 20));
    });
  });

  group('FormKegiatanScreen Widget Tests', () {
    final mockContract = ContractModel(
      id: 'c-1',
      namaKontrak: 'Kontrak Pengawasan Jalan',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas PU'],
      nilaiKontrak: 'Rp 200.000.000,00',
      hariKalender: 60,
      tglMulaiSpk: '26 Mei 2026',
      nomorSpk: '000.3.2/1280.1/WAS-17/SPK-BM/1.03.10.2.01.0056/2026',
      nomorSpmk: '000.3.2/1463/WAS-17/SPMK-BM/1.03.10.2.01.0056/2026',
      tglMulaiSpmk: '18 Juni 2026',
      tglSelesaiSpmk: '16 Agustus 2026',
      sumberDana: 'APBD Kabupaten Purbalingga Tahun Anggaran 2026',
      deskripsi: 'Deskripsi proyek',
      kegiatans: [],
    );

    testWidgets('Renders all 5 sections and fields properly', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));

      await tester.pumpWidget(
        MaterialApp(
          home: FormKegiatanScreen(contract: mockContract),
        ),
      );
      await tester.pumpAndSettle();

      // Check Section Headers
      expect(find.text('DATA POKOK KEGIATAN'), findsOneWidget);
      expect(find.text('KONSULTAN PENGAWAS'), findsOneWidget);
      expect(find.text('PENYEDIA JASA / KONTRAKTOR PELAKSANA'), findsOneWidget);
      expect(find.text('STRUKTUR ORGANISASI KEGIATAN'), findsOneWidget);
      expect(find.text('STRUKTUR ORGANISASI PENYEDIA JASA'), findsOneWidget);

      // Check Auto-filled unlocked fields
      expect(find.text('APBD Kabupaten Purbalingga Tahun Anggaran 2026'), findsOneWidget);
      expect(find.text('CV. TATA SAKA CONSULTANT'), findsWidgets);
      expect(find.text('000.3.2/1280.1/WAS-17/SPK-BM/1.03.10.2.01.0056/2026'), findsOneWidget);

      // Verifikasi Label Netral Staf Teknis (tanpa DPU-PR)
      expect(find.text('Staf Teknis 1'), findsOneWidget);
      expect(find.text('Staf Teknis 2'), findsOneWidget);
      expect(find.text('Staf Teknis 1 DPU-PR'), findsNothing);
      expect(find.text('Staf Teknis 2 DPU-PR'), findsNothing);

      // Verifikasi Field Tanggal Akhir SPMK (Dihitung Otomatis)
      expect(find.text('Tanggal Akhir SPMK'), findsOneWidget);

      // Verify Save Button is present
      expect(find.byType(ElevatedButton), findsWidgets);
    });

    testWidgets('FormKegiatanScreen updates Tanggal Akhir SPMK automatically when Jangka Waktu or Tgl SPMK changes', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));

      await tester.pumpWidget(
        MaterialApp(
          home: FormKegiatanScreen(
            contract: mockContract,
            initialKegiatan: {
              'tglSpmkKontraktor': '20 April 2026',
              'jangkaWaktu': '90 (Sembilan Puluh) hari kalender',
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tanggal akhir terhitung otomatis 18 Juli 2026
      expect(find.text('18 Juli 2026'), findsWidgets);

      // Ubah jangka waktu jadi 60 hari
      final jangkaWaktuFinder = find.widgetWithText(TextFormField, '90 (Sembilan Puluh) hari kalender');
      await tester.enterText(jangkaWaktuFinder, '60 hari kalender');
      await tester.pumpAndSettle();

      // 20 April 2026 + 60 hari kalender = 18 Juni 2026
      expect(find.text('18 Juni 2026'), findsWidgets);
    });
  });

  group('DetailKegiatanScreen Widget Tests', () {
    final mockContractWithKegiatan = ContractModel(
      id: 'c-1',
      namaKontrak: 'Kontrak Pengawasan Jalan',
      jenisKegiatan: 'Pengawasan',
      instansiDinas: ['Dinas PU'],
      nilaiKontrak: 'Rp 200.000.000,00',
      hariKalender: 60,
      tglMulaiSpk: '26 Mei 2026',
      nomorSpk: '000.3.2/1280.1/WAS-17/SPK-BM/1.03.10.2.01.0056/2026',
      nomorSpmk: '000.3.2/1463/WAS-17/SPMK-BM/1.03.10.2.01.0056/2026',
      tglMulaiSpmk: '18 Juni 2026',
      tglSelesaiSpmk: '16 Agustus 2026',
      sumberDana: 'APBD Kabupaten Purbalingga Tahun Anggaran 2026',
      deskripsi: 'Deskripsi proyek',
      kegiatans: [
        {
          'namaKegiatan': 'Pemeliharaan Berkala Jalan Karangmoncol - Rajawana',
          'lokasi': 'Ruas Jalan Kabupaten Purbalingga',
          'kontraktor': 'CV. SATYA WIGUNA',
          'nilaiKontrak': 'Rp 1.723.985.515,00 (Termasuk PPN+PPH)',
          'noSuratPesanan': 'EP-01KSHQ79D62E1FJ0RYT6WEBADX',
          'tglSuratPesanan': '18 Juni 2026',
          'noSpmkKontraktor': '000.3.3 / 1457 / SPMK / BM / VI / 2026',
          'tglSpmkKontraktor': '18 Juni 2026',
          'jangkaWaktu': '60 (Enam Puluh) hari kalender',
          'waktuBerjalan': '4 (Empat) Minggu',
          'penggunaAnggaran': 'DRAJAT UJI WAKHYONO, S.T., M.T.',
          'stafTeknis1': 'MUBALLIGH, ST., M.Sc.',
          'stafTeknis2': 'BILAL A.Md',
          'siteEngineerKegiatan': 'SENDAYU GALIH K., ST',
          'direkturPenyedia': 'IKSAN',
          'direkturKontraktor': 'IKSAN',
          'pelaksanaLapangan': 'GALIH WAHYU UTAMA',
          'petugasK3': 'IQBAL ZAINUL ARIFIN',
        }
      ],
    );

    testWidgets('Renders Executive Info Card and Organization Structure according to BAB II document format', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1400));

      final provider = ContractProvider();
      provider.addContract(mockContractWithKegiatan);

      await tester.pumpWidget(
        ChangeNotifierProvider<ContractProvider>.value(
          value: provider,
          child: MaterialApp(
            home: DetailKegiatanScreen(
              contract: mockContractWithKegiatan,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header Banner
      expect(find.text('Pemeliharaan Berkala Jalan Karangmoncol - Rajawana'), findsOneWidget);

      // Section KONSULTAN PENGAWAS
      expect(find.text('KONSULTAN PENGAWAS'), findsOneWidget);
      expect(find.text('CV. TATA SAKA CONSULTANT'), findsWidgets);

      // Section PENYEDIA JASA / KONTRAKTOR PELAKSANA
      expect(find.text('PENYEDIA JASA / KONTRAKTOR PELAKSANA'), findsOneWidget);
      expect(find.text('CV. SATYA WIGUNA'), findsOneWidget);
      expect(find.text('No. Surat Pesanan/tanggal'), findsOneWidget);
      expect(find.text('No. SPMK/tanggal'), findsWidgets);
      expect(find.text('Jangka Waktu Pelaksanaan'), findsOneWidget);
      expect(find.text('Tanggal Akhir SPMK'), findsOneWidget);
      expect(find.text('16 Agustus 2026'), findsWidgets);
      expect(find.text('Rp 1.723.985.515,00 (Termasuk PPN+PPH)'), findsOneWidget);

      // Section STRUKTUR ORGANISASI KEGIATAN
      expect(find.text('STRUKTUR ORGANISASI KEGIATAN'), findsOneWidget);
      expect(find.text('DRAJAT UJI WAKHYONO, S.T., M.T.'), findsOneWidget);
      expect(find.text('MUBALLIGH, ST., M.Sc. & BILAL A.Md'), findsOneWidget);
      expect(find.text('Staf Teknis 1 & 2'), findsOneWidget);
      expect(find.text('Staf Teknis 1 & 2 DPU-PR'), findsNothing);
      expect(find.text('Staf Teknis DPU-PR'), findsNothing);
      expect(find.text('Direktur Penyedia Jasa'), findsOneWidget);

      // Section STRUKTUR ORGANISASI PENYEDIA JASA
      expect(find.text('STRUKTUR ORGANISASI PENYEDIA JASA'), findsOneWidget);
      expect(find.text('Direktur'), findsOneWidget);
      expect(find.text('GALIH WAHYU UTAMA'), findsOneWidget);
      expect(find.text('IQBAL ZAINUL ARIFIN'), findsOneWidget);

      // Quick Action Button: Pen icon edit in header
      expect(find.byIcon(Icons.edit_outlined), findsWidgets);
    });
  });
}
