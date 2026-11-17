# Panduan & FAQ — Versi Web Saja (Sidebar AKUN & PENGATURAN)

## Context
Menu "Panduan & FAQ" ditambahkan di sidebar kategori **AKUN & PENGATURAN**, tapi **hanya muncul di versi web/desktop** — drawer versi app (mobile) **tidak diubah sama sekali**. Isi panduan diambil dari 3 guidebook PDF (Konsultan, Kontraktor, Admin). Format disetujui: **tab per peran**. Bottom sheet "Pusat Bantuan & FAQ" di SettingScreen tetap seperti sekarang.

Di kode: sidebar web = `_buildWebSidebar(..., isDrawer: false)` (dashboard_screen.dart:498-503), drawer versi app = `isDrawer: true` (line 491-493). Jadi cukup bungkus item baru dengan `if (!isDrawer)`.

## Perubahan

### 1. File baru: `lib/screens/panduan_faq_screen.dart`
Halaman StatefulWidget meniru pola `keamanan_screen.dart`:
- `Scaffold` bg `Color(0xFFF8FAFC)`, AppBar putih + tombol back (fallback ke `'/main'` seperti keamanan_screen.dart:267-292), title **"Panduan & FAQ"**.
- Body: `DefaultTabController` + `TabBar` 3 tab: **Konsultan**, **Kontraktor**, **Admin**, `TabBarView` berisi `ListView` per tab.
- Kartu section putih (radius 16, border `Color(0xFFE2E8F0)`, teks `0xFF0F172A` / `0xFF475569`) berisi langkah bernumber dari guidebook:

  **Konsultan**: 1) Akses Awal & Unduh Aplikasi; 2) Login (tab peran Konsultan, Ingat saya); 3) Mengenal Dashboard; 4) Manajemen Kontrak & Kegiatan — tambah/edit/hapus kontrak via titik tiga (⋮), Detail Kontrak tab Umum & Administrasi (Buat Folder), Tambah Kegiatan + Kelola RKK (+ Item/Divisi) + Addendum & Tambah Kurang; 5) Laporan Proyek — Harian (Pekerjaan & Sumber Daya A–D, foto JPG/PNG/WEBP, dokumen aspal/beton, field kustom), Mingguan (Rencana Fisik, Realisasi & Deviasi otomatis), Bulanan (rekap 4 minggu), Data Laporan (buka/edit/hapus, unduh PDF); 6) Timeline & Histori (audit trail, filter kategori chip); 7) Pengaturan Akun & Keluar.

  **Kontraktor**: 1) Login (tab Kontraktor, akun demo Kontraktor 1/2); 2) Dashboard Kontraktor (Kegiatan Saya, Rata-rata Progres, Status Aktif); 3) Detail Kegiatan & Data Laporan (RKK, Addendum & Tambah Kurang, tab Harian/Mingguan); 4) Membuat Laporan Harian (Buku Harian Standar); 5) Timeline & Histori; 6) Pengaturan Akun & Keluar.

  **Admin**: 1) Login (username admin); 2) Dashboard Admin (statistik akun, pencarian & filter peran); 3) Kelola Akun — + Tambah Akun (role, nama, instansi, email, password, status aktif), edit ikon Pensil, hapus ikon Tempat Sampah; 4) Logout pojok kanan atas.

- **FAQ**: widget `_buildFaqSection()` di bawah panduan tiap tab, pakai `ExpansionTile`. Isi = 4 FAQ lama dari `setting_screen.dart:_showFaqDialog` (laporan harian, mingguan dihitung, addendum CCO, kontak support) + tambahan: lupa password, akun gagal login (cek peran/status aktif), format foto, deviasi mingguan otomatis.

### 2. Edit: `lib/screens/dashboard_screen.dart` (hanya sidebar web)
- Tambah import `panduan_faq_screen.dart` di blok import (line ~7-25).
- Tambah item **setelah item Edit Profil** (setelah line 1859), dibungkus `if (!isDrawer)` supaya drawer versi app tetap tidak berubah:
  ```dart
  if (!isDrawer)
    _buildSidebarItem(
      isDrawer: isDrawer,
      key: 'panduan_faq',
      label: 'Panduan & FAQ',
      icon: Icons.help_outline_rounded,
      isActive: _activeWebMenu == 'panduan_faq',
      isCollapsed: isCollapsed,
      onTap: () => _navigateFromSidebar(
        'panduan_faq',
        const PanduanFaqScreen(),
        isDrawer: isDrawer,
      ),
    ),
  ```
  Bareng item lain di AKUN & PENGATURAN, ikut pola collection-if yang sudah dipakai sidebar (misal `if (!userProf.isKontraktor)` di line 1680).

## Verifikasi
1. `flutter analyze` — tidak ada error baru.
2. `flutter run -d windows` (layout web): login → menu **Panduan & FAQ** muncul di AKUN & PENGATURAN → halaman terbuka, 3 tab berganti, FAQ expand/collapse, back kembali ke dashboard.
3. Verifikasi versi app tidak berubah: lewati breakpoint mobile (drawer) → drawer TIDAK menampilkan menu Panduan & FAQ.