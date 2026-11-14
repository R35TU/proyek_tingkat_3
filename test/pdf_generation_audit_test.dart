import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/screens/pdf_viewer_screen.dart';
import 'package:tata_saka_app/services/pdf_report_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'user_profile_data': jsonEncode({
        'name': 'Konsultan Pengawas',
        'role': 'Konsultan',
        'email': 'konsultan@tatasaka.com',
      }),
    });
  });

  group('PDF Report Generation & Audit Tests', () {
    final sampleContract = ContractModel(
      id: 'kontrak-audit-01',
      jenisKegiatan: 'Pekerjaan Konstruksi',
      namaKontrak: 'Peningkatan Jalan Bobotsari - Karanganyar',
      nomorSpk: '602.1/1914/DPUPR/2026',
      tglMulaiSpk: '01 Juli 2026',
      nomorSpmk: '602.1/1914.1/DPUPR/2026',
      tglMulaiSpmk: '01 Juli 2026',
      tglSelesaiSpmk: '31 Oktober 2026',
      hariKalender: 120,
      nilaiKontrak: 'Rp 1.450.000.000,00',
      instansiDinas: ['Dinas Pekerjaan Umum dan Penataan Ruang'],
      sumberDana: 'DAU Tahun Anggaran 2026',
      deskripsi: 'Pengawasan Lapangan',
      strukturOrganisasi: {'siteEngineer': 'SENDAYU GALIH K., ST'},
      kegiatans: [
        {
          'namaKegiatan': 'Peningkatan Jalan Bobotsari - Karanganyar (Paket 1)',
          'lokasi': 'Kec. Karanganyar',
          'sumberDana': 'DAU',
          'kontraktor': 'PT. SINAR KARYA UTAMA',
          'nilaiKontrak': 'Rp 1.450.000.000,00',
          'rkkDivisiList': [
            {
              'kode': 'DIVISI 1',
              'nama': 'UMUM',
              'items': [
                {
                  'noMataPembayaran': '1.2',
                  'uraian': 'Mobilisasi dan Demobilisasi',
                  'satuan': 'Ls',
                  'volume': 1.0,
                  'hargaSatuan': 25000000.0,
                  'totalHarga': 25000000.0,
                  'nilaiBobot': 1.724,
                  'mingguIniBobot': 0.5,
                  'sdMingguIniBobot': 1.5,
                  'mingguLaluBobot': 1.0,
                  'sisaBobot': 0.224,
                },
              ],
            },
            {
              'kode': 'DIVISI 3',
              'nama': 'PEKERJAAN TANAH',
              'items': [
                {
                  'noMataPembayaran': '3.1.(1)',
                  'uraian': 'Galian Biasa',
                  'satuan': 'M3',
                  'volume': 450.0,
                  'hargaSatuan': 65000.0,
                  'totalHarga': 29250000.0,
                  'nilaiBobot': 2.017,
                  'mingguIniBobot': 0.8,
                  'sdMingguIniBobot': 1.8,
                  'mingguLaluBobot': 1.0,
                  'sisaBobot': 0.217,
                },
              ],
            },
          ],
        },
      ],
    );

    final sampleKegiatan = KegiatanModel.fromJson(
      sampleContract.kegiatans.first,
      fallbackContract: sampleContract,
    );

    test('1. Generate PDF: Buku Harian Standar (Laporan Harian)', () async {
      final dailyReportMap = {
        'id': 'laporan-daily-01',
        'tanggal': '2026-08-15',
        'tanggalFormatted': 'Sabtu, 15 Agustus 2026',
        'instruksiSaran': 'Lanjutkan pemadatan lapis pondasi agregat kelas A sesuai elevasi rencana.',
        'pekerjaanList': [
          {
            'jenis': 'Lapis Pondasi Agregat Kelas A (LPA)',
            'volume': '85.5 m3',
            'lokasi': 'STA 02+150 s.d. 02+450',
            'materials': [
              {'jenis': 'Batu Pecah 2-3', 'volume': '40 m3'},
              {'jenis': 'Pasir Pasang', 'volume': '25 m3'},
            ],
            'peralatans': [
              {'jenis': 'Vibratory Roller', 'jumlah': 1, 'kondisi': 'Baik'},
              {'jenis': 'Dump Truck 8 Ton', 'jumlah': 4, 'kondisi': 'Baik'},
            ],
            'personils': [
              {'role': 'Pelaksana Lapangan', 'cacah': 1},
              {'role': 'Mandor', 'cacah': 1},
              {'role': 'Pekerja Terampil', 'cacah': 8},
            ],
          },
        ],
        'cuacaKejadianList': [
          {'pukul': '07.00 - 12.00', 'cuaca': 'Cerah', 'keterangan': 'Pekerjaan berjalan normal'},
          {'pukul': '12.00 - 14.00', 'cuaca': 'Berawan', 'keterangan': 'Pekerjaan lancar'},
          {'pukul': '14.00 - 17.00', 'cuaca': 'Hujan Ringan', 'keterangan': 'Pekerjaan pemadatan dihentikan sementara'},
        ],
      };

      final pdfBytes = await PdfReportService.generateLaporanHarianPdf(
        report: dailyReportMap,
        namaKegiatan: sampleKegiatan.namaKegiatan,
        lokasi: sampleKegiatan.lokasi,
        dana: sampleKegiatan.sumberDana,
        kontraktor: sampleKegiatan.kontraktor,
        konsultan: 'CV. TATA SAKA CONSULTANT',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      // Standard PDF header signature "%PDF-"
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('2. Generate PDF: Ringkasan Kegiatan Mingguan (Laporan Mingguan)', () async {
      final weeklyReport = WeeklyReportModel.fromJson({
        'id': 'rep-weekly-01',
        'mingguKe': 5,
        'periodeAwal': '01 Agustus 2026',
        'periodeAkhir': '07 Agustus 2026',
        'pekerjaan': sampleKegiatan.namaKegiatan,
        'lokasiProyek': sampleKegiatan.lokasi,
        'kontraktor': sampleKegiatan.kontraktor,
        'nomorKontrak': sampleContract.nomorSpk,
        'tanggalKontrak': sampleContract.tglMulaiSpk,
        'nilaiKontrak': sampleContract.nilaiKontrak,
        'jangkaWaktu': 120,
        'waktuTerpakai': 35,
        'sisaWaktu': 85,
        'rencanaPersen': 28.50,
        'realisasiPersen': 31.25,
        'tabelMingguan': [
          {'mingguKe': 1, 'rencanaPersen': 5.0, 'realisasiPersen': 4.8},
          {'mingguKe': 2, 'rencanaPersen': 10.5, 'realisasiPersen': 11.0},
          {'mingguKe': 3, 'rencanaPersen': 16.0, 'realisasiPersen': 17.5},
          {'mingguKe': 4, 'rencanaPersen': 22.0, 'realisasiPersen': 24.0},
          {'mingguKe': 5, 'rencanaPersen': 28.5, 'realisasiPersen': 31.25},
        ],
      });

      final pdfBytes = await PdfReportService.generateLaporanMingguanPdf(
        report: weeklyReport,
        kegiatan: sampleContract.kegiatans.first,
        contract: sampleContract,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('3. Generate PDF: Lembar Evaluasi Kemajuan Fisik BoQ (8-Kolom)', () async {
      final weeklyReport = WeeklyReportModel.fromJson({
        'id': 'rep-weekly-02',
        'mingguKe': 6,
        'periodeAwal': '08 Agustus 2026',
        'periodeAkhir': '14 Agustus 2026',
        'pekerjaan': sampleKegiatan.namaKegiatan,
        'lokasiProyek': sampleKegiatan.lokasi,
        'kontraktor': sampleKegiatan.kontraktor,
        'nilaiKontrak': sampleContract.nilaiKontrak,
        'rencanaPersen': 35.0,
        'realisasiPersen': 37.8,
      });

      final pdfBytes = await PdfReportService.generateLembarBoqMingguanPdf(
        report: weeklyReport,
        kegiatan: sampleContract.kegiatans.first,
        contract: sampleContract,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('4. Generate PDF: Laporan Bulanan Pengawasan Lapangan', () async {
      final monthlyReports = MonthlyReportModel.generateFromWeeklyReports(
        contract: sampleContract,
        kegiatan: sampleKegiatan,
      );

      expect(monthlyReports, isNotEmpty);
      final monthlyReport = monthlyReports.first;

      final pdfBytes = await PdfReportService.generateLaporanBulananPdf(
        report: monthlyReport,
        contract: sampleContract,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    test('5. Generate PDF: Lembar Tambah Kurang (CCO Addendum 18-Kolom)', () async {
      final baselineDivisi = (sampleContract.kegiatans.first['rkkDivisiList'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final addendumData = {
        'nomorAddendum': '01',
        'judul': 'Daftar Perhitungan Tambah Kurang Ke - 01',
        'nomorSpkAddendum': '602.1/1914.1/ADD-01/2026',
        'tanggalAddendum': '15 Agustus 2026',
        'keterangan': 'Penyesuaian volume galian dan timbunan hasil rekayasa lapangan',
        'rkkDivisiList': [
          {
            'kode': 'DIVISI 1',
            'nama': 'UMUM',
            'items': [
              {
                'noMataPembayaran': '1.2',
                'uraian': 'Mobilisasi dan Demobilisasi',
                'satuan': 'Ls',
                'volume': 1.0,
                'hargaSatuan': 25000000.0,
                'totalHarga': 25000000.0,
                'nilaiBobot': 1.724,
              },
            ],
          },
          {
            'kode': 'DIVISI 3',
            'nama': 'PEKERJAAN TANAH',
            'items': [
              {
                'noMataPembayaran': '3.1.(1)',
                'uraian': 'Galian Biasa',
                'satuan': 'M3',
                'volume': 500.0, // bertambah 50 M3
                'hargaSatuan': 65000.0,
                'totalHarga': 32500000.0,
                'nilaiBobot': 2.241,
              },
            ],
          },
        ],
      };

      final pdfBytes = await PdfReportService.generateLembarTambahKurangPdf(
        kegiatan: sampleKegiatan,
        addendumData: addendumData,
        baselineDivisiList: baselineDivisi,
        contract: sampleContract,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, equals('%PDF-'));
    });

    testWidgets('6. Widget Test: PdfViewerScreen renders and displays actions', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PdfViewerScreen(
            title: 'Pratinjau PDF Laporan',
            fileName: 'Test_Laporan.pdf',
            pageFormat: PdfPageFormat.a4,
            buildPdf: () async {
              return Uint8List.fromList([
                0x25, 0x50, 0x44, 0x46, 0x2D, // %PDF-
                0x31, 0x2E, 0x34, 0x0A,
              ]);
            },
          ),
        ),
      );

      expect(find.text('Pratinjau PDF Laporan'), findsOneWidget);
      expect(find.byIcon(Icons.file_download_outlined), findsOneWidget);
    });
  });
}
