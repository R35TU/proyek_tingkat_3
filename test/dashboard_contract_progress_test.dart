import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProgressCalculator Unit Tests', () {
    test('1. Menghitung progres kegiatan dari laporan harian terhadap RKK aktif', () {
      final keg = {
        'namaKegiatan': 'Pekerjaan Saluran',
        'rkkDivisiList': [
          {
            'nomorRomawi': 'DIVISI 1',
            'judul': 'DRAINASE',
            'items': [
              {
                'uraian': 'Galian Saluran',
                'volume': 100.0,
                'satuan': 'm3',
                'nilaiBobot': 40.0, // 40% dari total kegiatan
              },
              {
                'uraian': 'Pemasangan U-Ditch',
                'volume': 50.0,
                'satuan': 'unit',
                'nilaiBobot': 60.0, // 60% dari total kegiatan
              },
            ],
          }
        ],
        'laporans': [
          {
            'tanggal': '2026-11-01',
            'pekerjaanList': [
              {
                'rkkItemId': 'DIVISI 1_Galian Saluran',
                'uraian': 'Galian Saluran',
                'volume': '50.0 m3', // 50% dari item 1 -> 50% * 40% = 20%
              },
            ],
          },
          {
            'tanggal': '2026-11-02',
            'pekerjaanList': [
              {
                'rkkItemId': 'DIVISI 1_Pemasangan U-Ditch',
                'uraian': 'Pemasangan U-Ditch',
                'volume': '25 unit', // 50% dari item 2 -> 50% * 60% = 30%
              },
            ],
          },
        ],
      };

      final prog = ProgressCalculator.calculateKegiatanProgress(keg);
      // Total progres = 20% + 30% = 50.0%
      expect(prog, closeTo(50.0, 0.01));
    });

    test('2. Addendum CCO: Menghitung progres terhadap target volume CCO terbaru', () {
      final keg = {
        'namaKegiatan': 'Pekerjaan Saluran CCO',
        'rkkKontrakAwal': [
          {
            'nomorRomawi': 'DIVISI 1',
            'items': [
              {
                'uraian': 'Galian Saluran',
                'volume': 100.0,
                'nilaiBobot': 100.0,
              }
            ],
          }
        ],
        'addendums': [
          {
            'nomorAddendum': '01',
            'rkkDivisiList': [
              {
                'nomorRomawi': 'DIVISI 1',
                'items': [
                  {
                    'uraian': 'Galian Saluran',
                    'volume': 100.0,
                    'volumeCCO': 200.0, // Volume bertambah menjadi 200 m3
                    'nilaiBobot': 100.0,
                  }
                ],
              }
            ],
          }
        ],
        'laporans': [
          {
            'pekerjaanList': [
              {
                'rkkItemId': 'DIVISI 1_Galian Saluran',
                'uraian': 'Galian Saluran',
                'volume': '100.0', // 100 m3 terealisasi
              }
            ],
          }
        ],
      };

      final prog = ProgressCalculator.calculateKegiatanProgress(keg);
      // Karena target CCO = 200, maka 100 / 200 = 50% (bukan 100%)
      expect(prog, closeTo(50.0, 0.01));
    });

    test('3. Kontrak Multi-Kegiatan: Rata-rata dari seluruh kegiatan', () {
      final keg1 = {
        'namaKegiatan': 'Kegiatan A',
        'progressFisik': 60.0,
      };
      final keg2 = {
        'namaKegiatan': 'Kegiatan B',
        'progressFisik': 30.0,
      };
      final keg3 = {
        'namaKegiatan': 'Kegiatan C',
        // Belum ada progres / laporan
      };

      final kegiatans = [keg1, keg2, keg3];
      final avgPercent = ProgressCalculator.calculateContractProgressPercent(kegiatans);
      final ratio = ProgressCalculator.calculateContractProgressRatio(kegiatans);

      // (60 + 30 + 0) / 3 = 30.0%
      expect(avgPercent, closeTo(30.0, 0.01));
      expect(ratio, closeTo(0.30, 0.001));
    });

    test('4. Kontrak Model: Dinamis menghitung progressFisik dan status', () {
      final contract = ContractModel(
        id: 'c1',
        namaKontrak: 'Kontrak Uji',
        jenisKegiatan: 'Konstruksi',
        nomorSpk: 'SPK-01',
        tglMulaiSpk: '01 Jan 2026',
        nomorSpmk: 'SPMK-01',
        tglMulaiSpmk: '01 Jan 2026',
        tglSelesaiSpmk: '31 Des 2026',
        hariKalender: 365,
        nilaiKontrak: '1M',
        instansiDinas: ['DPU'],
        sumberDana: 'APBD',
        deskripsi: 'Uji',
        kegiatans: [
          {
            'namaKegiatan': 'Keg 1',
            'progressFisik': 80.0,
          },
          {
            'namaKegiatan': 'Keg 2',
            'progressFisik': 100.0,
          },
        ],
      );

      // Rata-rata: (80 + 100) / 2 = 90%
      expect(contract.progressPercent, closeTo(90.0, 0.01));
      expect(contract.progressFisik, closeTo(0.90, 0.001));
      expect(contract.status, 'Aktif');

      // Jika kegiatan kedua menjadi 100% dan kegiatan pertama juga 100%
      contract.kegiatans[0]['progressFisik'] = 100.0;
      expect(contract.progressPercent, closeTo(100.0, 0.01));
      expect(contract.progressFisik, closeTo(1.0, 0.001));
      expect(contract.status, 'Selesai');
    });
  });

  group('Dashboard Widget Progress Integration Tests', () {
    Widget createDashboardTestApp({
      required Key key,
      required UserProfileProvider userProfile,
      required ContractProvider contractProvider,
    }) {
      return MultiProvider(
        key: key,
        providers: [
          ChangeNotifierProvider<UserProfileProvider>.value(value: userProfile),
          ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
          ChangeNotifierProvider<TimelineProvider>(create: (_) => TimelineProvider()),
        ],
        child: const MaterialApp(
          home: DashboardScreen(),
        ),
      );
    }

    testWidgets(
      '5. Indikator lingkaran di Dashboard menampilkan rata-rata akurat seluruh kegiatan dan ikut terupdate saat data berubah',
      (tester) async {
        final contract = ContractModel(
          id: 'ktr-01',
          namaKontrak: 'Pembangunan Drainase Kota',
          jenisKegiatan: 'Pengawasan Lapangan',
          nomorSpk: 'SPK/01',
          tglMulaiSpk: '01 Jan 2026',
          nomorSpmk: 'SPMK/01',
          tglMulaiSpmk: '01 Jan 2026',
          tglSelesaiSpmk: '31 Des 2026',
          hariKalender: 365,
          nilaiKontrak: 'Rp 500.000.000',
          instansiDinas: ['DPU'],
          sumberDana: 'APBD',
          deskripsi: 'Deskripsi',
          kegiatans: [
            {
              'namaKegiatan': 'Paket 1 Drainase Barat',
              'progressFisik': 40.0,
            },
            {
              'namaKegiatan': 'Paket 2 Drainase Timur',
              'progressFisik': 60.0,
            },
          ],
        );

        SharedPreferences.setMockInitialValues({});

        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));

        final contractProvider = ContractProvider();
        await contractProvider.addContract(contract);

        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createDashboardTestApp(
            key: const Key('app_test_5'),
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Rata-rata awal = (40 + 60) / 2 = 50%
        expect(find.text('50%'), findsOneWidget);

        // CircularProgressIndicator value = 0.50
        final progressIndicatorFinder = find.byType(CircularProgressIndicator);
        expect(progressIndicatorFinder, findsOneWidget);
        final progressWidget = tester.widget<CircularProgressIndicator>(progressIndicatorFinder);
        expect(progressWidget.value, closeTo(0.50, 0.001));

        // Simulasi perubahan progres: Paket 1 bertambah dari 40% ke 80%
        contract.kegiatans[0]['progressFisik'] = 80.0;
        contractProvider.updateContract(contract);
        await tester.pumpAndSettle();

        // Rata-rata baru = (80 + 60) / 2 = 70%
        expect(find.text('70%'), findsOneWidget);
        expect(find.text('50%'), findsNothing);

        final updatedWidget = tester.widget<CircularProgressIndicator>(progressIndicatorFinder);
        expect(updatedWidget.value, closeTo(0.70, 0.001));
      },
    );

    testWidgets(
      '6. Konsistensi nilai progress antara DetailKegiatanScreen dan Dashboard',
      (tester) async {
        final keg = {
          'namaKegiatan': 'Pekerjaan Jembatan Utama',
          'rkkDivisiList': [
            {
              'nomorRomawi': 'DIVISI 1',
              'items': [
                {
                  'uraian': 'Pondasi Bore Pile',
                  'volume': 10.0,
                  'satuan': 'titik',
                  'nilaiBobot': 100.0,
                }
              ],
            }
          ],
          'laporans': [
            {
              'pekerjaanList': [
                {
                  'rkkItemId': 'DIVISI 1_Pondasi Bore Pile',
                  'uraian': 'Pondasi Bore Pile',
                  'volume': '7.5 titik', // 75%
                }
              ],
            }
          ],
        };

        final contract = ContractModel(
          id: 'ktr-bridge',
          namaKontrak: 'Pembangunan Jembatan',
          jenisKegiatan: 'Pengawasan Lapangan',
          nomorSpk: 'SPK/02',
          tglMulaiSpk: '01 Jan 2026',
          nomorSpmk: 'SPMK/02',
          tglMulaiSpmk: '01 Jan 2026',
          tglSelesaiSpmk: '31 Des 2026',
          hariKalender: 365,
          nilaiKontrak: 'Rp 2.000.000.000',
          instansiDinas: ['DPU'],
          sumberDana: 'APBD',
          deskripsi: 'Jembatan',
          kegiatans: [keg],
        );

        SharedPreferences.setMockInitialValues({});

        final konsultanProfile = UserProfileProvider();
        konsultanProfile.loginAs(const RegisteredUser(
          username: 'konsultan',
          password: 'password123',
          role: 'Konsultan',
          namaLengkap: 'CV. Tata Saka Consultant',
          companyOrAgency: 'CV. Tata Saka Consultant',
        ));

        final contractProvider = ContractProvider();
        await contractProvider.addContract(contract);

        // 1. Periksa kalkulasi di DetailKegiatanScreen
        tester.view.physicalSize = const Size(1280, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MultiProvider(
            key: const Key('detail_kegiatan_provider'),
            providers: [
              ChangeNotifierProvider<UserProfileProvider>.value(value: konsultanProfile),
              ChangeNotifierProvider<ContractProvider>.value(value: contractProvider),
              ChangeNotifierProvider<TimelineProvider>(create: (_) => TimelineProvider()),
            ],
            child: MaterialApp(
              home: DetailKegiatanScreen(
                contract: contract,
                kegiatanIndex: 0,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 75.00% pada Detail Kegiatan
        expect(find.text('75.00%'), findsOneWidget);

        // 2. Periksa kalkulasi di Dashboard
        await tester.pumpWidget(
          createDashboardTestApp(
            key: const Key('app_test_6'),
            userProfile: konsultanProfile,
            contractProvider: contractProvider,
          ),
        );
        await tester.pumpAndSettle();

        // Di Dashboard tampil 75%
        expect(find.text('75%'), findsOneWidget);
        final cpi = tester.widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));
        expect(cpi.value, closeTo(0.75, 0.001));
      },
    );
  });
}
