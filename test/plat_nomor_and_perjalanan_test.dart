import 'package:flutter_test/flutter_test.dart';
import 'package:tata_saka_app/utils/plat_nomor_util.dart';

void main() {
  group('PlatNomorUtil Tests', () {
    test('normalize should format plate strings standardly', () {
      expect(PlatNomorUtil.normalize('r1234dt'), equals('R 1234 DT'));
      expect(PlatNomorUtil.normalize('R-8076-OE'), equals('R 8076 OE'));
      expect(PlatNomorUtil.normalize('r   8076   oe'), equals('R 8076 OE'));
      expect(PlatNomorUtil.normalize('b 999'), equals('B 999'));
    });

    test('split should extract prefix, number, and suffix accurately', () {
      final res = PlatNomorUtil.split('R 8076 OE');
      expect(res['prefix'], equals('R'));
      expect(res['number'], equals('8076'));
      expect(res['suffix'], equals('OE'));

      final res2 = PlatNomorUtil.split('b1234xyz');
      expect(res2['prefix'], equals('B'));
      expect(res2['number'], equals('1234'));
      expect(res2['suffix'], equals('XYZ'));
    });

    test('calcHourDiff calculates decimal hour difference correctly and handles varied formats', () {
      // 07:14 to 08:44 = 90 minutes = 1.5 hours
      expect(PlatNomorUtil.calcHourDiff('07:14', '08:44'), closeTo(1.500, 0.001));
      // 09:30 to 10:48 = 78 minutes = 1.3 hours
      expect(PlatNomorUtil.calcHourDiff('09:30', '10:48'), closeTo(1.300, 0.001));
      // 15.30 to 17 = 90 minutes = 1.5 hours
      expect(PlatNomorUtil.calcHourDiff('15.30', '17'), closeTo(1.500, 0.001));
    });

    test('normalizeTime standardizes various formats to clean HH:mm:ss', () {
      expect(PlatNomorUtil.normalizeTime('15.30'), equals('15:30:00'));
      expect(PlatNomorUtil.normalizeTime('15'), equals('15:00:00'));
      expect(PlatNomorUtil.normalizeTime('8:5'), equals('08:05:00'));
      expect(PlatNomorUtil.normalizeTime('15:30 WIB'), equals('15:30:00'));
      expect(PlatNomorUtil.normalizeTime('08.45'), equals('08:45:00'));
      expect(PlatNomorUtil.normalizeTime('15.30.25'), equals('15:30:25'));
      expect(PlatNomorUtil.normalizeTime('15:30:45 WIB'), equals('15:30:45'));
      expect(PlatNomorUtil.normalizeTime(''), equals(''));
    });

    test('formatMinutesToDuration formats minutes into HH:mm:ss', () {
      expect(PlatNomorUtil.formatMinutesToDuration(5.0), equals('0:05:00'));
      expect(PlatNomorUtil.formatMinutesToDuration(8.4667), equals('0:08:28'));
    });

    test('parseMinutes parses various manual input strings correctly', () {
      expect(PlatNomorUtil.parseMinutes(''), equals(5.0));
      expect(PlatNomorUtil.parseMinutes('5'), equals(5.0));
      expect(PlatNomorUtil.parseMinutes('10'), equals(10.0));
      expect(PlatNomorUtil.parseMinutes('15 menit'), equals(15.0));
      expect(PlatNomorUtil.parseMinutes('0:20:00'), equals(20.0));
      expect(PlatNomorUtil.parseMinutes('0'), equals(0.0));
    });

    test('formatDecimal formats with Indonesian comma', () {
      expect(PlatNomorUtil.formatDecimal(1.5, fractionDigits: 3), equals('1,500'));
      expect(PlatNomorUtil.formatDecimal(23.667, fractionDigits: 3), equals('23,667'));
      expect(PlatNomorUtil.formatDecimal(8.5, fractionDigits: 2), equals('8,50'));
    });

    test('computeDataPerjalananRows reproduces exact official document calculations', () {
      final lapanganList = [
        {
          'nomorKendaraan': 'R 8076 OE',
          'jamDatang': '08:44',
          'suhu': '145',
          'jamMulaiTuang': '08:45',
          'jamSelesaiTuang': '08:53', // 8 minutes hampar
          'jamPulang': '09:30',
        }
      ];

      final ampList = [
        {
          'nomorKendaraan': 'r8076oe',
          'jamPergi': '07:14',
          'suhuAmp': '155',
          'jamPulang': '10:48',
        }
      ];

      final tonaseList = [
        {
          'nomorKendaraan': 'R-8076-OE',
          'tonaseTiket': '8.5',
        }
      ];

      final rows = PlatNomorUtil.computeDataPerjalananRows(
        lapanganList: lapanganList,
        ampList: ampList,
        tonaseList: tonaseList,
        jarakKm: 35.5,
      );

      expect(rows.length, equals(1));
      final r = rows[0];

      expect(r['plate'], equals('R 8076 OE'));
      expect(r['platePrefix'], equals('R'));
      expect(r['plateNumber'], equals('8076'));
      expect(r['plateSuffix'], equals('OE'));
      expect(r['rit'], equals(1));
      expect(r['jamDariAmp'], equals('07:14'));
      expect(r['jamTibaLokasi'], equals('08:44'));
      expect(r['jamDariLokasi'], equals('09:30'));
      expect(r['jamTibaAmp'], equals('10:48'));
      expect(r['waktuBerangkatJam'], closeTo(1.500, 0.001));
      expect(r['waktuPulangJam'], closeTo(1.300, 0.001));
      expect(r['suhuAmp'], equals(155.0));
      expect(r['suhuLokasi'], equals(145.0));
      expect(r['selisihSuhu'], equals(10.0));
      expect(r['turunPerJam'], closeTo(6.667, 0.01));
      expect(r['kecepatanBerangkat'], closeTo(23.667, 0.01));
      expect(r['kecepatanPulang'], closeTo(27.308, 0.01));
      expect(r['beratAc'], equals(8.5));
    });

    test('computeDataPerjalananRows calculates with manual waktuAntrian when provided', () {
      final lapanganList = [
        {
          'nomorKendaraan': 'R 8076 OE',
          'jamDatang': '08:44',
          'suhu': '145',
          'waktuAntrian': '15', // 15 menit manual
          'jamMulaiTuang': '08:45',
          'jamSelesaiTuang': '08:53',
          'jamPulang': '09:30',
        }
      ];

      final ampList = [
        {
          'nomorKendaraan': 'R 8076 OE',
          'jamPergi': '07:14',
          'suhuAmp': '155',
          'jamPulang': '10:48',
        }
      ];

      final tonaseList = [
        {
          'nomorKendaraan': 'R 8076 OE',
          'tonaseTiket': '8.5',
        }
      ];

      final rows = PlatNomorUtil.computeDataPerjalananRows(
        lapanganList: lapanganList,
        ampList: ampList,
        tonaseList: tonaseList,
        jarakKm: 35.5,
      );

      expect(rows.length, equals(1));
      final r = rows[0];
      expect(r['waktuAntrian'], equals('0:15:00'));
      // Waktu Berangkat (1.5h) + Antrian (15/60 = 0.25h) + Hampar (8/60 = 0.1333h) + Pulang (1.3h) = 3.1833h
      expect(r['totalJam'], closeTo(3.183, 0.01));
    });
  });
}
