import 'package:flutter/material.dart';

/// Langkah panduan: langkah bernomor, sub-bullet, atau sub-heading (A./B./C.).
class _GuideStep {
  final String text;
  final bool isHeading;
  final bool isSub;
  const _GuideStep(this.text, {this.isHeading = false, this.isSub = false});
}

/// Satu bab panduan: judul + daftar langkah.
class _GuideSection {
  final String title;
  final List<_GuideStep> steps;
  const _GuideSection(this.title, this.steps);
}

/// Item FAQ (pertanyaan + jawaban) untuk ExpansionTile.
class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}

/// Konfigurasi konten panduan untuk satu peran (intro + langkah + FAQ).
class _RoleContent {
  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<_GuideSection> sections;
  final List<_FaqItem> faqs;
  const _RoleContent(
    this.key,
    this.icon,
    this.title,
    this.subtitle,
    this.sections,
    this.faqs,
  );
}

/// Halaman Panduan & FAQ (versi web) — konten diambil dari guidebook
/// pengguna: Konsultan, Kontraktor, dan Admin.
///
/// Jika [role] diisi dengan 'konsultan', 'kontraktor', atau 'admin'
/// (dipakai dari sidebar dashboard sesuai peran yang login), halaman hanya
/// menampilkan panduan peran tersebut tanpa tab. Jika null / peran lain
/// (mis. Dinas — belum ada guidebook), tampilan default 3 tab peran tetap
/// dipertahankan.
class PanduanFaqScreen extends StatelessWidget {
  const PanduanFaqScreen({super.key, this.role});

  /// 'konsultan' | 'kontraktor' | 'admin'; null/peran lain → 3 tab.
  final String? role;

  bool get _isSingleRole {
    final r = role?.toLowerCase();
    return r == 'konsultan' || r == 'kontraktor' || r == 'admin';
  }

  _RoleContent? get _singleRoleContent {
    if (!_isSingleRole) return null;
    final r = role!.toLowerCase();
    return _roleContents.firstWhere((c) => c.key == r);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DATA PANDUAN — KONSULTAN
  // ─────────────────────────────────────────────────────────────────────────
  static const List<_GuideSection> _konsultanGuide = [
    _GuideSection('Akses Awal & Unduh Aplikasi', [
      _GuideStep('Buka halaman utama SAKA-REP (Tata Saka-Reporting System).'),
      _GuideStep(
        'Unduh Aplikasi (opsional): klik tombol Download Aplikasi untuk '
        'mengunduh berkas instalasi ke perangkat Anda.',
      ),
      _GuideStep(
        'Masuk ke Portal: klik tombol Mulai → atau Login Portal → di pojok '
        'kanan atas untuk menuju halaman login.',
      ),
    ]),
    _GuideSection('Login ke Sistem', [
      _GuideStep('Pada halaman Selamat Datang, pilih tab peran Konsultan.'),
      _GuideStep('Masukkan Username Akun dan Password Anda.'),
      _GuideStep(
        '(Opsional) Centang kotak Ingat saya agar kredensial tersimpan '
        'untuk sesi berikutnya.',
      ),
      _GuideStep('Klik tombol Masuk ke Sistem.'),
    ]),
    _GuideSection('Mengenal Halaman Dashboard', [
      _GuideStep(
        'Ringkasan Kontrak: menampilkan jumlah Total Kontrak, Kontrak Aktif, '
        'dan Kontrak Selesai.',
      ),
      _GuideStep(
        'Kartu Progres Proyek: menampilkan persentase progres dan total '
        'kegiatan pada kontrak yang sedang berjalan.',
      ),
      _GuideStep(
        'Aktivitas Terkini: riwayat pembaruan terbaru, seperti penambahan '
        'laporan harian oleh tim konsultan.',
      ),
      _GuideStep(
        'Menu Navigasi (Sidebar Kiri): Dashboard, Kontrak, Pelaporan (Data '
        'Laporan, Laporan Harian, Laporan Mingguan, Laporan Bulanan), '
        'Timeline & Histori, Pengaturan Akun, dan Keluar / Logout.',
      ),
    ]),
    _GuideSection('Manajemen Kontrak & Kegiatan', [
      _GuideStep('A. Menambah dan Menghapus Kontrak', isHeading: true),
      _GuideStep(
        'Buka menu Kontrak pada sidebar kiri untuk masuk ke Daftar Kontrak.',
      ),
      _GuideStep('Klik tombol + Tambah Kontrak Baru.'),
      _GuideStep('Lengkapi formulir data kontrak yang meliputi:'),
      _GuideStep(
        'Jenis Kegiatan (misal: Pengawasan Teknis) dan Nama Kegiatan / Kontrak.',
        isSub: true,
      ),
      _GuideStep('Detail SPK: Nomor SPK dan Tanggal Mulai SPK.', isSub: true),
      _GuideStep(
        'Detail SPMK: Nomor SPMK, Tanggal Mulai SPMK, Jangka Waktu, dan '
        'Tanggal Akhir SPMK.',
        isSub: true,
      ),
      _GuideStep(
        'Informasi Anggaran & Instansi: Nilai Kontrak, Nama Dinas terkait '
        '(gunakan + Tambah Dinas Lain jika lebih dari satu), Sumber Dana, '
        'serta Deskripsi Kegiatan.',
        isSub: true,
      ),
      _GuideStep(
        'Struktur Personel Konsultan: Nama Site Engineer, Inspektor '
        '(gunakan + Tambah Inspektor jika diperlukan), dan Administrasi.',
        isSub: true,
      ),
      _GuideStep('Klik Simpan Kontrak.'),
      _GuideStep(
        'Mengedit atau Menghapus Kontrak: pada halaman Daftar Kontrak, klik '
        'ikon titik tiga (⋮) di sisi kanan kartu kontrak, lalu pilih Edit '
        'Kontrak atau Hapus Kontrak.',
      ),
      _GuideStep('B. Mengelola Detail Kontrak & Folder Administrasi',
          isHeading: true),
      _GuideStep(
        'Pilih salah satu kontrak pada daftar untuk membuka halaman '
        'Detail Kontrak.',
      ),
      _GuideStep(
        'Tab Umum: menampilkan spesifikasi lengkap kontrak, struktur personel '
        'konsultan, dan daftar kegiatan/ruas jalan.',
      ),
      _GuideStep(
        'Tab Administrasi: digunakan untuk mengarsipkan berkas kontrak. '
        'Klik Buat Folder Baru, masukkan Nama Folder, lalu klik Simpan.',
      ),
      _GuideStep(
        'C. Menambah Kegiatan & Mengatur Rincian Kuantitas (RKK)',
        isHeading: true,
      ),
      _GuideStep(
        'Pada bagian bawah tab Umum di halaman Detail Kontrak, klik tombol '
        '+ Tambah di samping judul Kegiatan.',
      ),
      _GuideStep(
        'Isi Data Pokok Kegiatan (Nama Kegiatan, Lokasi), Data Kontraktor '
        'Pelaksana, serta Struktur Organisasi Kegiatan & Penyedia Jasa, lalu '
        'klik Simpan Data Kegiatan.',
      ),
      _GuideStep(
        'Klik salah satu item kegiatan (misal: Ruas Jalan A) untuk masuk '
        'ke Detail Kegiatan.',
      ),
      _GuideStep(
        'Klik Kelola Rincian Pekerjaan (RKK) untuk melihat item pekerjaan, '
        'menambahkan item baru (+ Tambah Item Pekerjaan), atau menambah '
        'divisi standar Bina Marga (+ Tambah Divisi Pekerjaan).',
      ),
      _GuideStep(
        'Klik Kelola Addendum & Tambah Kurang jika terdapat penyesuaian '
        'volume/addendum kontrak.',
      ),
      _GuideStep('Mengelola Folder Administrasi khusus di tingkat kegiatan.'),
    ]),
    _GuideSection('Laporan Proyek', [
      _GuideStep('A. Membuat Laporan Harian (Buku Harian Standar)',
          isHeading: true),
      _GuideStep('Pilih menu Buat Laporan Harian.'),
      _GuideStep(
        'Pastikan Tanggal Pelaksanaan sudah sesuai (klik Ubah Tanggal '
        'jika perlu).',
      ),
      _GuideStep('Pilih Kontrak dan Kegiatan yang dilaporkan.'),
      _GuideStep(
        'Isi bagian A–D. Pekerjaan & Sumber Daya: pilih item pekerjaan dari '
        'daftar RKK, masukkan Volume Realisasi Hari Ini, Lokasi/STA, '
        'material, alat, personel, serta kondisi cuaca.',
      ),
      _GuideStep(
        'Unggah foto dokumentasi lapangan melalui tombol Ambil Kamera atau '
        'Pilih File / Galeri (format JPG, PNG, WEBP).',
      ),
      _GuideStep(
        '(Opsional) Aktifkan sakelar Dokumen Pengawasan Aspal atau Dokumen '
        'Pengawasan Beton jika pekerjaan hari tersebut memerlukan '
        'rekapitulasi khusus, atau tambahkan + Tambah Field Kustom.',
      ),
      _GuideStep('Klik Simpan Buku Harian Standar.'),
      _GuideStep('B. Membuat Laporan Mingguan', isHeading: true),
      _GuideStep('Pilih menu Buat Laporan Mingguan.'),
      _GuideStep(
        'Pilih Kontrak dan Kegiatan Proyek (data pokok kontrak akan terisi '
        'otomatis).',
      ),
      _GuideStep(
        'Pada bagian Kemajuan Bobot Fisik, masukkan persentase Rencana Fisik '
        's/d Minggu Ini. Sistem akan menghitung Realisasi Fisik dan Deviasi '
        '(+/-) secara otomatis berdasarkan akumulasi laporan harian.',
      ),
      _GuideStep(
        'Klik Simpan Ringkasan Mingguan (Anda juga dapat memeriksa tampilan '
        'cetak pada tab Pratinjau Dokumen Fisik).',
      ),
      _GuideStep('C. Laporan Bulanan', isHeading: true),
      _GuideStep('Pilih menu Laporan Bulanan.'),
      _GuideStep(
        'Sistem menyajikan Rekapitulasi Periode 4 Minggu secara otomatis '
        '(meliputi Rencana, Realisasi, dan Deviasi per bulan).',
      ),
      _GuideStep(
        'Klik Buka > pada periode bulan yang berstatus Selesai untuk melihat '
        'detail rekapitulasi bulanan.',
      ),
      _GuideStep('D. Mengelola Data Laporan', isHeading: true),
      _GuideStep(
        'Pilih menu Data Laporan, lalu klik tombol Laporan > pada kegiatan '
        'yang ingin diperiksa.',
      ),
      _GuideStep(
        'Tab Harian: gunakan navigasi kalender mingguan untuk memilih '
        'tanggal tertentu. Pada kartu laporan yang tersedia, Anda dapat:',
      ),
      _GuideStep(
        'Klik Buka & Lihat Dokumen Laporan untuk meninjau lembar Buku Harian '
        'Standar, mengeditnya (Edit), atau mengunduhnya dalam format PDF.',
        isSub: true,
      ),
      _GuideStep(
        'Klik ikon Pensil untuk mengedit cepat atau ikon Tempat Sampah untuk '
        'menghapus laporan.',
        isSub: true,
      ),
      _GuideStep(
        'Jika pada tanggal tersebut belum ada laporan, klik + Buat Laporan '
        'untuk Hari Ini.',
        isSub: true,
      ),
      _GuideStep(
        'Tab Mingguan: menampilkan daftar Ringkasan Kegiatan Mingguan '
        'beserta status deviasinya. Gunakan tombol Buka Dokumen, ikon '
        'Pensil (edit), atau ikon Tempat Sampah (hapus) untuk mengelola '
        'laporan.',
      ),
    ]),
    _GuideSection('Memantau Timeline & Histori (Kronologi Proyek)', [
      _GuideStep(
        'Fitur ini berfungsi sebagai audit trail untuk melacak seluruh '
        'riwayat aktivitas dan perubahan data pada proyek secara kronologis.',
      ),
      _GuideStep(
        'Pada menu navigasi di sidebar kiri, gulir ke bagian HISTORI lalu '
        'klik Timeline & Histori.',
      ),
      _GuideStep(
        'Ketik kata kunci pada kolom Cari riwayat aktivitas... untuk '
        'menemukan catatan tertentu secara cepat.',
      ),
      _GuideStep(
        'Gunakan menu dropdown Semua Kegiatan untuk menyaring riwayat '
        'berdasarkan ruas jalan atau kegiatan spesifik.',
      ),
      _GuideStep(
        'Klik tombol chip kategori di bagian atas — yaitu Semua, Kontrak & '
        'Kegiatan, RAB / BoQ, Addendum (CCO), Laporan, atau Dokumen — untuk '
        'menampilkan jenis aktivitas tertentu saja.',
      ),
      _GuideStep(
        'Membaca Kartu Kronologi: setiap kartu aktivitas yang dikelompokkan '
        'per bulan menampilkan Status & Kategori (seperti DISETUJUI, DIBUAT, '
        'atau DIPERBARUI), Judul & Deskripsi Aktivitas, serta Pelaku & '
        'Lokasi (nama personel dan ruas jalan terkait).',
      ),
    ]),
    _GuideSection('Pengaturan Akun & Keluar (Logout)', [
      _GuideStep(
        'Keamanan & Sandi: melalui sidebar kiri, ubah kata sandi Anda '
        '(minimal 8 karakter, memuat huruf besar & kecil, angka, dan simbol).',
      ),
      _GuideStep(
        'Edit Profil: perbarui informasi akun, termasuk foto profil '
        '(format JPG/PNG, maks. 2MB).',
      ),
      _GuideStep(
        'Keluar dari Sistem: klik tombol Keluar / Logout di bagian paling '
        'bawah sidebar kiri, lalu klik Keluar pada jendela konfirmasi.',
      ),
    ]),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // DATA PANDUAN — KONTRAKTOR
  // ─────────────────────────────────────────────────────────────────────────
  static const List<_GuideSection> _kontraktorGuide = [
    _GuideSection('Login ke Sistem', [
      _GuideStep('Buka halaman login SAKA-REP (Selamat Datang).'),
      _GuideStep(
        'Pilih tab peran Kontraktor. (Pada mode demo/pengujian, tersedia '
        'pilihan cepat akun seperti Kontraktor 1 atau Kontraktor 2.)',
      ),
      _GuideStep(
        'Masukkan Username Akun (contoh: kontraktor1) dan Password Anda.',
      ),
      _GuideStep(
        '(Opsional) Centang kotak Ingat saya agar akun tetap masuk pada '
        'sesi berikutnya.',
      ),
      _GuideStep('Klik tombol Masuk ke Sistem.'),
    ]),
    _GuideSection('Mengenal Halaman Dashboard Kontraktor', [
      _GuideStep(
        'Ringkasan Kinerja: menampilkan jumlah Kegiatan Saya, Rata-rata '
        'Progres keseluruhan (dalam persen), serta Status proyek (Aktif).',
      ),
      _GuideStep(
        'Kegiatan Pelaksanaan Saya: daftar paket kegiatan atau ruas jalan '
        'yang dikerjakan oleh kontraktor beserta lokasi, sumber dana, nilai '
        'kontrak kegiatan, bar progres fisik, dan tombol pintasan '
        'Lihat Detail Kegiatan >.',
      ),
      _GuideStep(
        'Menu Navigasi (Sidebar Kiri): Dashboard, Pelaporan (Data Laporan, '
        'Laporan Harian), Histori (Timeline & Histori), Akun & Pengaturan '
        '(Pengaturan Akun, Keamanan & Sandi, Edit Profil), dan Keluar / '
        'Logout.',
      ),
    ]),
    _GuideSection('Melihat Detail Kegiatan & Data Laporan', [
      _GuideStep(
        'Pada halaman Dashboard, klik tombol Lihat Detail Kegiatan > pada '
        'salah satu kartu kegiatan (misalnya Ruas Jalan A atau Ruas Jalan B) '
        'untuk meninjau rincian spesifikasi kegiatan dan progres fisiknya.',
      ),
      _GuideStep(
        'Pada halaman Detail Kegiatan, Anda dapat melihat Struktur Organisasi '
        'Penyedia Jasa, Progres Fisik, serta Rincian Kuantitas & Bobot '
        'Pekerjaan:',
      ),
      _GuideStep(
        'Klik Lihat Rincian Pekerjaan (RKK) untuk melihat item pekerjaan, '
        'volume, harga satuan, total harga, dan bobot kontrak.',
        isSub: true,
      ),
      _GuideStep(
        'Klik Lihat Addendum & Tambah Kurang untuk membuka lembar perhitungan '
        'tambah kurang (dapat diekspor ke PDF).',
        isSub: true,
      ),
      _GuideStep(
        'Memeriksa Data Laporan: klik menu Data Laporan pada sidebar kiri.',
      ),
      _GuideStep(
        'Gunakan kolom pencarian Cari Proyek atau Kegiatan.. bila diperlukan.',
      ),
      _GuideStep(
        'Klik tombol Laporan > di sisi kanan item kegiatan untuk membuka '
        'arsip laporan harian maupun mingguan pada kegiatan tersebut.',
      ),
    ]),
    _GuideSection('Membuat Laporan Harian (Buku Harian Standar)', [
      _GuideStep(
        'Klik menu Laporan Harian pada sidebar kiri untuk membuka '
        'Form Buku Harian Standar.',
      ),
      _GuideStep(
        'Pastikan Tanggal Pelaksanaan sudah sesuai (klik Ubah Tanggal jika '
        'ingin menyesuaikan tanggal laporan).',
      ),
      _GuideStep(
        'Pada bagian Pilih Kontrak & Kegiatan, pilih nama Kontrak dan '
        'Kegiatan yang sesuai (informasi Lokasi Kegiatan dan Sumber Dana '
        'akan muncul otomatis).',
      ),
      _GuideStep(
        'Lengkapi bagian A–D. Pekerjaan & Sumber Daya: pilih item pekerjaan '
        'dari daftar RKK kontrak, masukkan Volume Realisasi Hari Ini dan '
        'titik Lokasi / STA pengerjaan, lengkapi data material, peralatan, '
        'tenaga kerja, serta kondisi cuaca di lapangan.',
      ),
      _GuideStep(
        'Unggah Dokumentasi Foto: tambahkan foto bukti pekerjaan lapangan '
        'dengan mengklik Ambil Kamera atau Pilih File / Galeri (mendukung '
        'format JPG, PNG, dan WEBP).',
      ),
      _GuideStep(
        '(Opsional) Aktifkan sakelar Dokumen Pengawasan Aspal atau Dokumen '
        'Pengawasan Beton jika pekerjaan hari itu melibatkan '
        'pengaspalan/pengecoran yang membutuhkan lampiran khusus, atau klik '
        '+ Tambah Field Kustom jika ada catatan tambahan.',
      ),
      _GuideStep(
        'Klik tombol Simpan Buku Harian Standar di bagian paling bawah '
        'untuk mengirimkan laporan.',
      ),
    ]),
    _GuideSection('Memantau Timeline & Histori', [
      _GuideStep(
        'Klik menu Timeline & Histori pada bagian HISTORI di sidebar kiri.',
      ),
      _GuideStep(
        'Anda dapat memantau riwayat aktivitas proyek secara kronologis, '
        'mencari catatan tertentu melalui kolom pencarian, serta menyaring '
        'riwayat berdasarkan kegiatan maupun kategori dokumen (Kontrak & '
        'Kegiatan, RAB/BoQ, Addendum, Laporan, Dokumen).',
      ),
    ]),
    _GuideSection('Pengaturan Akun & Keluar (Logout)', [
      _GuideStep(
        'Keamanan & Sandi: gunakan sub-menu ini untuk mengganti password.',
      ),
      _GuideStep(
        'Edit Profil: gunakan untuk memperbarui informasi profil kontraktor.',
      ),
      _GuideStep(
        'Keluar dari Sistem: klik tombol merah Keluar / Logout di pojok kiri '
        'bawah sidebar, lalu klik Keluar pada jendela Konfirmasi Keluar.',
      ),
    ]),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // DATA PANDUAN — ADMIN
  // ─────────────────────────────────────────────────────────────────────────
  static const List<_GuideSection> _adminGuide = [
    _GuideSection('Login ke Sistem', [
      _GuideStep('Buka halaman login SAKA-REP (Selamat Datang).'),
      _GuideStep(
        'Pada kolom Username Akun, masukkan admin beserta Password '
        'administrator.',
      ),
      _GuideStep('(Opsional) Centang kotak Ingat saya agar sesi tetap tersimpan.'),
      _GuideStep('Klik tombol Masuk ke Sistem.'),
    ]),
    _GuideSection('Mengenal Halaman Dashboard Admin', [
      _GuideStep(
        'Kartu Statistik Akun: menampilkan jumlah Total Akun serta rincian '
        'jumlah akun berdasarkan peran (Konsultan, Kontraktor, dan Dinas).',
      ),
      _GuideStep('Pencarian & Filter Akun:'),
      _GuideStep(
        'Gunakan kolom pencarian Cari nama, email, atau instansi... untuk '
        'menemukan pengguna secara cepat.',
        isSub: true,
      ),
      _GuideStep(
        'Klik tombol filter Semua, Konsultan, Kontraktor, atau Dinas untuk '
        'menyaring daftar akun berdasarkan peran tertentu.',
        isSub: true,
      ),
      _GuideStep(
        'Daftar Akun Terdaftar: setiap kartu akun menampilkan inisial, nama '
        'lengkap beserta gelar, label peran (Konsultan/Kontraktor/Dinas), '
        'nama instansi/perusahaan, email login, password akun, serta tombol '
        'aksi di sisi kanan.',
      ),
    ]),
    _GuideSection('Menambah, Mengedit, & Menghapus Akun Pengguna', [
      _GuideStep('A. Menambah Akun Baru', isHeading: true),
      _GuideStep(
        'Pada halaman Dashboard Admin, klik tombol + Tambah Akun di sisi '
        'kanan bilah pencarian.',
      ),
      _GuideStep('Pada jendela pop-up Tambah Akun Baru, lengkapi data berikut:'),
      _GuideStep(
        'Role / Peran Akun: pilih peran pengguna (Konsultan, Kontraktor, '
        'atau Dinas).',
        isSub: true,
      ),
      _GuideStep(
        'Nama Lengkap & Gelar: masukkan nama lengkap beserta gelar pengguna.',
        isSub: true,
      ),
      _GuideStep(
        'Nama Instansi / Perusahaan: masukkan nama CV, PT, atau Dinas terkait. '
        'Khusus untuk peran Konsultan, kolom ini tidak perlu diisi karena secara otomatis '
        'ditetapkan sebagai CV. Tata Saka Consultant.',
        isSub: true,
      ),
      _GuideStep(
        'Email Login & Password: tentukan kredensial yang akan digunakan '
        'pengguna untuk masuk ke sistem.',
        isSub: true,
      ),
      _GuideStep(
        'Status Akun Aktif: pastikan sakelar dalam posisi aktif (kanan) agar '
        'pengguna dapat langsung login ke aplikasi.',
        isSub: true,
      ),
      _GuideStep('Klik tombol Buat Akun untuk menyimpan.'),
      _GuideStep('B. Mengedit & Menghapus Akun', isHeading: true),
      _GuideStep(
        'Mengedit Akun: klik ikon Pensil (biru) di sisi kanan kartu akun '
        'untuk memperbarui informasi pengguna, mengubah kata sandi, atau '
        'menonaktifkan status akun.',
      ),
      _GuideStep(
        'Menghapus Akun: klik ikon Tempat Sampah (merah) di sisi kanan kartu '
        'akun untuk menghapus akun dari sistem.',
      ),
    ]),
    _GuideSection('Keluar dari Sistem (Logout)', [
      _GuideStep(
        'Untuk mengakhiri sesi administrator, klik tombol merah Logout di '
        'pojok kanan atas halaman Dashboard Admin.',
      ),
    ]),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // DATA FAQ
  // ─────────────────────────────────────────────────────────────────────────
  /// FAQ umum — tampil di semua tab peran.
  static const List<_FaqItem> _faqUmum = [
    _FaqItem(
      'Bagaimana cara membuat Laporan Harian?',
      'Masuk ke menu Laporan (Konsultan) atau Laporan Harian (Kontraktor) > '
      'pilih Kontrak & Kegiatan > isi item pekerjaan, material, alat, tenaga '
      'kerja, cuaca, dan instruksi pengawas > klik Simpan Buku Harian Standar.',
    ),
    _FaqItem(
      'Kapan Laporan Mingguan dihitung?',
      'Laporan mingguan otomatis menjumlahkan volume dari seluruh laporan '
      'harian pada minggu bersangkutan ke ringkasan BoQ.',
    ),
    _FaqItem(
      'Bagaimana membuat Addendum CCO?',
      'Buka menu Detail Kegiatan > Kelola Addendum & Tambah Kurang > '
      'Buat Addendum Baru.',
    ),
    _FaqItem(
      'Format foto apa yang didukung untuk dokumentasi lapangan?',
      'Format JPG, PNG, dan WEBP. Unggah melalui tombol Ambil Kamera atau '
      'Pilih File / Galeri pada form laporan harian.',
    ),
    _FaqItem(
      'Bagaimana jika lupa password?',
      'Hubungi Admin untuk mereset kata sandi: Admin membuka Dashboard Admin '
      '> klik ikon Pensil pada kartu akun Anda > masukkan password baru > '
      'simpan.',
    ),
    _FaqItem(
      'Akun saya tidak bisa login, apa yang harus dilakukan?',
      'Pastikan tab peran pada halaman login sudah sesuai (Konsultan / '
      'Kontraktor / Dinas), username dan password benar, serta status akun '
      'dalam posisi aktif. Jika masih gagal, hubungi Admin untuk memeriksa '
      'status akun.',
    ),
    _FaqItem(
      'Kontak Bantuan & Layanan Teknis',
      'Email: support@tatasaka.com\n'
      'Telepon/WA: +62 812-3456-7890 (Hari Kerja 08:00 - 17:00 WIB)',
    ),
  ];

  /// FAQ khusus peran Konsultan.
  static const List<_FaqItem> _faqKonsultan = [
    _FaqItem(
      'Mengapa Realisasi Fisik dan Deviasi pada Laporan Mingguan tidak sesuai?',
      'Nilai Realisasi Fisik dan Deviasi (+/-) dihitung otomatis berdasarkan '
      'akumulasi volume laporan harian. Periksa kembali laporan harian pada '
      'periode terkait melalui menu Data Laporan.',
    ),
  ];

  /// FAQ khusus peran Kontraktor.
  static const List<_FaqItem> _faqKontraktor = [
    _FaqItem(
      'Apakah laporan yang sudah tersimpan masih bisa diedit?',
      'Bisa. Buka menu Data Laporan > Laporan > pilih tab Harian atau '
      'Mingguan, lalu gunakan ikon Pensil (edit cepat) atau tombol Buka & '
      'Lihat Dokumen > Edit. Laporan juga dapat diunduh dalam format PDF.',
    ),
  ];

  /// FAQ khusus peran Admin.
  static const List<_FaqItem> _faqAdmin = [
    _FaqItem(
      'Bagaimana menonaktifkan akun tanpa menghapusnya?',
      'Klik ikon Pensil (biru) pada kartu akun, lalu matikan sakelar Status '
      'Akun Aktif. Akun nonaktif tidak dapat login, tetapi datanya tetap '
      'tersimpan di sistem.',
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // KONFIGURASI KONTEN PER PERAN (dipakai mode 3 tab & mode single-role)
  // ─────────────────────────────────────────────────────────────────────────
  static const List<_RoleContent> _roleContents = [
    _RoleContent(
      'konsultan',
      Icons.engineering_rounded,
      'Panduan Konsultan',
      'CV. Tata Saka Consultant — Konsultan Pengawas & Perencana. Kelola '
      'kontrak, kegiatan & RKK, laporan harian/mingguan/bulanan, serta '
      'pantau timeline proyek.',
      _konsultanGuide,
      [..._faqUmum, ..._faqKonsultan],
    ),
    _RoleContent(
      'kontraktor',
      Icons.construction_rounded,
      'Panduan Kontraktor',
      'Kontraktor Pelaksana. Lihat kegiatan & progres fisik, input laporan '
      'harian (Buku Harian Standar), dan pantau riwayat aktivitas proyek.',
      _kontraktorGuide,
      [..._faqUmum, ..._faqKontraktor],
    ),
    _RoleContent(
      'admin',
      Icons.admin_panel_settings_rounded,
      'Panduan Admin',
      'Manajemen Akun. Kelola akun pengguna Konsultan, Kontraktor, dan '
      'Dinas: tambah, edit, nonaktifkan, atau hapus akun.',
      _adminGuide,
      [..._faqUmum, ..._faqAdmin],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Mode single-role (dari sidebar sesuai peran login): tanpa tab.
    final single = _singleRoleContent;
    if (single != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(context),
        body: _buildRoleTab(
          context,
          icon: single.icon,
          title: single.title,
          subtitle: single.subtitle,
          sections: single.sections,
          faqs: single.faqs,
        ),
      );
    }

    // Mode default (mis. peran Dinas / halaman umum): 3 tab peran.
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: _buildAppBar(
          context,
          bottom: const TabBar(
            labelColor: Color(0xFF0F172A),
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: Color(0xFF0F172A),
            indicatorWeight: 2.5,
            labelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            tabs: [
              Tab(text: 'Konsultan'),
              Tab(text: 'Kontraktor'),
              Tab(text: 'Admin'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final c in _roleContents)
              _buildRoleTab(
                context,
                icon: c.icon,
                title: c.title,
                subtitle: c.subtitle,
                sections: c.sections,
                faqs: c.faqs,
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context,
      {PreferredSizeWidget? bottom}) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/main',
              (route) => false,
            );
          }
        },
      ),
      title: const Text(
        'Panduan & FAQ',
        style: TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 17,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
      bottom: bottom,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILDERS
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRoleTab(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required List<_GuideSection> sections,
    required List<_FaqItem> faqs,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // ─── Kartu intro peran ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: const Color(0xFF2563EB), size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        _buildSectionLabel('LANGKAH PENGGUNAAN'),
        for (int i = 0; i < sections.length; i++) ...[
          _buildGuideCard(i + 1, sections[i]),
          const SizedBox(height: 12),
        ],

        const SizedBox(height: 8),
        _buildSectionLabel('PERTANYAAN YANG SERING DIAJUKAN (FAQ)'),
        _buildFaqCard(context, faqs),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildGuideCard(int number, _GuideSection section) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$number',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._buildSteps(section.steps),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(List<_GuideStep> steps) {
    final widgets = <Widget>[];
    int no = 0;
    for (final step in steps) {
      if (step.isHeading) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              step.text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        );
      } else if (step.isSub) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 30, top: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Text(
                    '•',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    step.text,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        no++;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$no',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    step.text,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF334155),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildFaqCard(BuildContext context, List<_FaqItem> faqs) {
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: const Color(0xFFF1F5F9)),
        child: Column(
          children: [
            for (final faq in faqs)
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                iconColor: const Color(0xFF64748B),
                collapsedIconColor: const Color(0xFF64748B),
                title: Text(
                  faq.question,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      faq.answer,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF475569),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
