import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/models/monthly_report_model.dart';
import 'package:tata_saka_app/models/weekly_report_model.dart';
import 'package:tata_saka_app/services/pdf_report_service.dart';
import 'package:tata_saka_app/widgets/signature_pad_widget.dart';

void main() {
  group('Weekly & Monthly Signatures Model Tests', () {
    test('WeeklyReportModel supports multi-signers ttdList with json serialization', () {
      final sample = WeeklyReportModel.sampleDocument();

      final signers = [
        {
          'peran': 'Kontraktor Pelaksana',
          'instansi': 'PT. MAJU BERSAMA',
          'nama': 'Ahmad Fauzi',
          'tanggal': '24 Mei 2026',
          'signature': 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
        },
        {
          'peran': 'Konsultan Supervisi',
          'instansi': 'CV. TATA SAKA CONSULTANT',
          'nama': 'Ir. Bambang S.',
          'tanggal': '24 Mei 2026',
          'signature': null,
        },
        {
          'peran': 'Pejabat Pembuat Komitmen (PPK)',
          'instansi': 'DPU-PR Kab. Purbalingga',
          'nama': 'Drs. Hendro Wibowo',
          'tanggal': '24 Mei 2026',
          'signature': null,
        },
      ];

      sample.ttdList = signers;
      sample.ttdKontraktorNama = 'Ahmad Fauzi';
      sample.ttdKontraktorJabatan = 'Kontraktor Pelaksana';

      final json = sample.toJson();
      expect(json['ttdList'], isNotNull);
      expect((json['ttdList'] as List).length, 3);

      final restored = WeeklyReportModel.fromJson(json);
      expect(restored.ttdList, isNotNull);
      expect(restored.ttdList!.length, 3);
      expect(restored.ttdKontraktor['nama'], 'Ahmad Fauzi');
      expect(restored.ttdKonsultan['nama'], 'Ir. Bambang S.');
      expect(restored.ttdPpk['nama'], 'Drs. Hendro Wibowo');
    });

    test('MonthlyReportModel copyWithSignatures and getter logic', () {
      final monthly = MonthlyReportModel(
        bulanKe: 1,
        bulanRomawi: 'I',
        namaBulan: 'Bulan Ke-1',
        periodeFormatted: '20 April 2026 - 17 Mei 2026',
        mingguMulai: 1,
        mingguSelesai: 4,
        mingguTersedia: [1, 2, 3, 4],
        status: 'Selesai',
        statusDetail: 'Selesai (M-1 s.d. M-4)',
        divisions: [],
        totalBobotCCO: 100.0,
        totalBobotBulanLalu: 0.0,
        totalBobotBulanIni: 38.5,
        totalBobotSdBulanIni: 38.5,
        totalBobotSisa: 61.5,
        rencanaFisikPersen: 35.0,
        realisasiKumulatifPersen: 38.5,
        deviasiPersen: 3.5,
        namaKegiatan: 'Ruas Jalan A',
        lokasi: 'Purbalingga',
        sumberDana: 'APBD',
        pelaksanaKontraktor: 'CV. DIVAN',
        noKontrak: '001/SPK/2026',
        konsultanPengawas: 'CV. TATA SAKA',
        noKontrakPengawas: '002/SPK/2026',
      );

      final updated = monthly.copyWithSignatures(
        ttdList: [
          {
            'peran': 'Kontraktor Pelaksana',
            'instansi': 'CV. DIVAN',
            'nama': 'Doni Pratama',
            'tanggal': '17 Mei 2026',
          },
          {
            'peran': 'Konsultan Supervisi',
            'instansi': 'CV. TATA SAKA',
            'nama': 'Siti Rahma',
            'tanggal': '17 Mei 2026',
          },
        ],
      );

      expect(updated.ttdList!.length, 2);
      expect(updated.ttdKontraktor['nama'], 'Doni Pratama');
      expect(updated.ttdKonsultan['nama'], 'Siti Rahma');
    });
  });

  group('PDF Generation with Dynamic Signatures Tests', () {
    testWidgets('PdfReportService generates valid PDFs without hardcoded template crash', (tester) async {
      final sample = WeeklyReportModel.sampleDocument();
      sample.ttdList = [
        {
          'peran': 'Kontraktor Pelaksana',
          'instansi': 'PT. UJI COBA',
          'nama': 'Test Kontraktor',
          'tanggal': '30 Mei 2026',
          'signature': null,
        },
        {
          'peran': 'Konsultan Supervisi',
          'instansi': 'CV. TATA SAKA',
          'nama': 'Test Konsultan',
          'tanggal': '30 Mei 2026',
          'signature': null,
        },
      ];

      final contract = ContractModel(
        id: 'test-c1',
        namaKontrak: 'Kontrak Uji Coba',
        jenisKegiatan: 'Pengawasan Teknis',
        nomorSpk: '001/SPK',
        nomorSpmk: '001/SPMK',
        tglMulaiSpk: '20 April 2026',
        tglMulaiSpmk: '20 April 2026',
        tglSelesaiSpmk: '18 Juli 2026',
        nilaiKontrak: '1.000.000.000',
        hariKalender: 90,
        sumberDana: 'APBD',
        instansiDinas: ['DPU-PR'],
        deskripsi: 'Deskripsi',
        kegiatans: [],
      );

      final ringkasanBytes = await PdfReportService.generateLaporanMingguanPdf(
        report: sample,
        kegiatan: {},
        contract: contract,
      );
      expect(ringkasanBytes, isNotEmpty);

      final boqBytes = await PdfReportService.generateLembarBoqMingguanPdf(
        report: sample,
        kegiatan: {},
        contract: contract,
      );
      expect(boqBytes, isNotEmpty);

      final monthly = MonthlyReportModel(
        bulanKe: 1,
        bulanRomawi: 'I',
        namaBulan: 'Bulan Ke-1',
        periodeFormatted: '20 April 2026 - 17 Mei 2026',
        mingguMulai: 1,
        mingguSelesai: 4,
        mingguTersedia: [1, 2, 3, 4],
        status: 'Selesai',
        statusDetail: 'Selesai',
        divisions: [],
        totalBobotCCO: 100.0,
        totalBobotBulanLalu: 0.0,
        totalBobotBulanIni: 38.5,
        totalBobotSdBulanIni: 38.5,
        totalBobotSisa: 61.5,
        rencanaFisikPersen: 35.0,
        realisasiKumulatifPersen: 38.5,
        deviasiPersen: 3.5,
        namaKegiatan: 'Ruas Jalan A',
        lokasi: 'Purbalingga',
        sumberDana: 'APBD',
        pelaksanaKontraktor: 'CV. DIVAN',
        noKontrak: '001/SPK/2026',
        konsultanPengawas: 'CV. TATA SAKA',
        noKontrakPengawas: '002/SPK/2026',
        ttdList: sample.ttdList,
      );

      final bulananBytes = await PdfReportService.generateLaporanBulananPdf(
        report: monthly,
        contract: contract,
      );
      expect(bulananBytes, isNotEmpty);
    });
  });

  group('SignaturePadWidget UI Test', () {
    testWidgets('SignaturePadWidget renders name and date controllers properly', (tester) async {
      final nameCtrl = TextEditingController(text: 'Eko Prasetyo');
      final roleCtrl = TextEditingController(text: 'Inspector');
      final dateCtrl = TextEditingController(text: '20 Mei 2026');
      String? savedSig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SignaturePadWidget(
                nameController: nameCtrl,
                roleController: roleCtrl,
                dateController: dateCtrl,
                nameLabel: 'Nama Lengkap',
                roleLabel: 'Jabatan',
                dateLabel: 'Tanggal Tanda Tangan',
                onSignatureChanged: (val) {
                  savedSig = val;
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Eko Prasetyo'), findsOneWidget);
      expect(find.text('Inspector'), findsOneWidget);
      expect(find.text('20 Mei 2026'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Tanggal Tanda Tangan'), findsOneWidget);
    });
  });
}
