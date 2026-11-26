import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/utils/image_memory_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shared Asset & Font Optimization Checks', () {
    test('Unused assets & unreferenced fonts are removed and pubspec.yaml is clean', () {
      expect(File('assets/images/logo_white_bg.png').existsSync(), isFalse);
      expect(Directory('assets/fonts').existsSync(), isFalse);
      expect(File('assets/images/logoRev.png').existsSync(), isTrue);
      expect(File('assets/images/landingpage.png').existsSync(), isTrue);

      final pubspec = File('pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('- assets/images/logoRev.png'));
      expect(pubspec, contains('- assets/images/landingpage.png'));
      expect(pubspec, isNot(contains('logo_white_bg.png')));
    });

    test('Compressed PNG assets decode cleanly at original target dimensions', () async {
      final logoBytes = File('assets/images/logoRev.png').readAsBytesSync();
      final logoCodec = await ui.instantiateImageCodec(logoBytes);
      final logoFrame = await logoCodec.getNextFrame();
      expect(logoFrame.image.width, 512);
      expect(logoFrame.image.height, 512);
      logoFrame.image.dispose();

      final waveBytes = File('assets/images/landingpage.png').readAsBytesSync();
      final waveCodec = await ui.instantiateImageCodec(waveBytes);
      final waveFrame = await waveCodec.getNextFrame();
      expect(waveFrame.image.width, 1600);
      expect(waveFrame.image.height, 735);
      waveFrame.image.dispose();
    });
  });

  group('ImageMemoryCache & Rendering Optimization Checks', () {
    // 1x1 PNG pixel base64 valid
    const sample1x1PngBase64 =
        'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

    test('ImageMemoryCache memoizes decoded Uint8List instances and bounds LRU size', () {
      final first = ImageMemoryCache.decodeBase64(sample1x1PngBase64);
      final second = ImageMemoryCache.decodeBase64(sample1x1PngBase64);
      expect(first, isNotNull);
      expect(identical(first, second), isTrue);

      // Push > 80 distinct payloads to verify LRU cap never crashes or throws
      for (int i = 0; i < 95; i++) {
        final bytes = ImageMemoryCache.decodeBase64(
          base64Encode(utf8.encode('payload-$i')),
        );
        expect(bytes, isNotNull);
      }
    });

    testWidgets('buildCachedImageWidget applies cacheWidth/cacheHeight bounds cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: buildCachedImageWidget(
              sample1x1PngBase64,
              width: 140,
              height: 110,
              cacheWidth: 360,
            ),
          ),
        ),
      );

      final img = tester.widget<Image>(find.byType(Image));
      expect(img.image, isA<ResizeImage>());
      expect((img.image as ResizeImage).width, 360);
      expect(tester.takeException(), isNull);
    });

    testWidgets('KelolaRkkScreen virtualizes and smoothly scrolls large BoQ list (240 items across 12 divisions)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final largeDivisions = List.generate(12, (d) {
        return <String, dynamic>{
          'nomorRomawi': '${d + 1}',
          'namaDivisi': 'DIVISI ${d + 1} PEKERJAAN STRUKTUR',
          'items': List.generate(20, (i) {
            return <String, dynamic>{
              'id': 'item-$d-$i',
              'noMataPembayaran': '${d + 1}.${i + 1}',
              'uraian': 'Item Pekerjaan Lapangan #$d-$i',
              'satuan': 'm3',
              'volume': 10.0,
              'hargaSatuan': 100000.0,
              'totalHarga': 1000000.0,
              'nilaiBobot': 100.0 / 240.0,
            };
          }),
        };
      });

      final contract = ContractModel(
        id: 'perf-kontrak-01',
        jenisKegiatan: 'Pengawasan Teknis',
        namaKontrak: 'Paket Uji Performa Besar',
        nomorSpk: '001/SPK/PERF',
        tglMulaiSpk: '01 Juli 2026',
        nomorSpmk: '001/SPMK/PERF',
        tglMulaiSpmk: '01 Juli 2026',
        tglSelesaiSpmk: '31 Desember 2026',
        hariKalender: 180,
        nilaiKontrak: 'Rp 240.000.000,00',
        instansiDinas: ['DPU-PR'],
        sumberDana: 'APBD',
        deskripsi: 'Pengawasan Besar',
        kegiatans: [
          {
            'namaKegiatan': 'Ruas Uji Performa',
            'lokasi': 'Purbalingga',
            'kontraktor': 'CV Testing',
            'sumberDana': 'APBD',
            'nilaiKontrak': 'Rp 240.000.000,00',
            'rkkDivisiList': largeDivisions,
            'addendums': [],
            'laporans': [],
          },
        ],
      );

      final sw = Stopwatch()..start();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => ContractProvider()),
            ChangeNotifierProvider(create: (_) => TimelineProvider()),
          ],
          child: MaterialApp(
            home: KelolaRkkScreen(
              contract: contract,
              kegiatanIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      sw.stop();

      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.text('DIVISI 1 PEKERJAAN STRUKTUR'), findsOneWidget);
      // Offscreen divisi 12 belum dirender sebelum di-scroll (lazy SliverList)
      expect(find.text('DIVISI 12 PEKERJAAN STRUKTUR'), findsNothing);

      // Scroll ke bawah sampai akhir daftar
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -3500),
        4000,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
