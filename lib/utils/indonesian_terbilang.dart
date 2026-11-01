class IndonesianTerbilang {
  static const List<String> _satuan = [
    '',
    'Satu',
    'Dua',
    'Tiga',
    'Empat',
    'Lima',
    'Enam',
    'Tujuh',
    'Delapan',
    'Sembilan',
    'Sepuluh',
    'Sebelas'
  ];

  /// Mengonversi bilangan bulat menjadi teks terbilang bahasa Indonesia.
  /// Contoh:
  /// 4 -> "Empat"
  /// 60 -> "Enam Puluh"
  /// 90 -> "Sembilan Puluh"
  static String convert(int n) {
    if (n == 0) return 'Nol';
    if (n < 0) return 'Minus ${convert(-n)}';
    if (n < 12) return _satuan[n];
    if (n < 20) return '${_satuan[n - 10]} Belas';
    if (n < 100) {
      final puluhan = n ~/ 10;
      final sisa = n % 10;
      return '${_satuan[puluhan]} Puluh${sisa > 0 ? " ${_satuan[sisa]}" : ""}';
    }
    if (n < 200) {
      return 'Seratus${n > 100 ? " ${convert(n - 100)}" : ""}';
    }
    if (n < 1000) {
      final ratusan = n ~/ 100;
      final sisa = n % 100;
      return '${_satuan[ratusan]} Ratus${sisa > 0 ? " ${convert(sisa)}" : ""}';
    }
    if (n < 2000) {
      return 'Seribu${n > 1000 ? " ${convert(n - 1000)}" : ""}';
    }
    if (n < 1000000) {
      final ribuan = n ~/ 1000;
      final sisa = n % 1000;
      return '${convert(ribuan)} Ribu${sisa > 0 ? " ${convert(sisa)}" : ""}';
    }
    if (n < 1000000000) {
      final jutaan = n ~/ 1000000;
      final sisa = n % 1000000;
      return '${convert(jutaan)} Juta${sisa > 0 ? " ${convert(sisa)}" : ""}';
    }
    final milyaran = n ~/ 1000000000;
    final sisa = n % 1000000000;
    return '${convert(milyaran)} Milyar${sisa > 0 ? " ${convert(sisa)}" : ""}';
  }

  /// Format durasi hari kalender resmi PU: "60 (Enam Puluh) hari kalender"
  static String formatHariKalender(int days) {
    if (days <= 0) return '';
    return '$days (${convert(days)}) hari kalender';
  }

  /// Format durasi minggu resmi PU: "4 (Empat) Minggu"
  static String formatMinggu(int weeks) {
    if (weeks <= 0) return '0 (Nol) Minggu';
    return '$weeks (${convert(weeks)}) Minggu';
  }
}
