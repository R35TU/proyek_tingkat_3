# 📋 CHECKLIST TASK — Setelah Bucket `tatasaka-media` Aktif

> Dibuat: 17 Nov 2026 (pagi). Status bucket saat ini: **provisioning > 1 jam** (tiket support sudah dikirim).
> File ini adalah daftar kerja bersama: **[USER] = yang Anda kerjakan**, **[ZCODE] = yang saya kerjakan**.

---

## A. LANGKAH PERTAMA SAAT BUCKET AKTIF — [USER]

- [ ] **A1.** Refresh dashboard Sumopod → pastikan badge `provisioning` berubah jadi **active/ready** (hijau)
- [ ] **A2.** Buka tab **Credentials** di bucket `tatasaka-media`
- [ ] **A3.** Salin & kirim ke ZCode (via chat ini):
  - 🌐 **Endpoint URL** (alamat akses bucket)
  - 🔑 **Access Key ID**
  - 🔐 **Secret Access Key**
- [ ] **A4.** Simpan sendiri salinan kredensial di tempat aman (catatan pribadi / password manager)
  - ⚠️ Jangan pernah ditulis di kode yang di-commit ke GitHub, dan jangan dibagikan ke siapa pun selain proses integrasi ini

---

## B. INTEGRASI FOTO/PDF KE BUCKET — [ZCODE] (dikerjakan setelah A selesai)

- [x] **B1.** Buat `lib/services/storage_service.dart` — terintegrasi dengan Cloudflare R2 bucket `lapakdir-media` via S3 API
- [x] **B2.** Struktur folder di bucket:
  - `laporan-harian/{contractId}/{kegiatanId}/` → foto & tanda tangan
  - `laporan-pdf/` → PDF harian/mingguan/bulanan
  - `dokumen/` → berkas administrasi (SPK/SPMK/addendum)
- [x] **B3.** Ganti jalur foto laporan: base64 → **unggah ke bucket, simpan URL** di dokumen Firestore (dokumen tetap kecil & cepat)
- [x] **B4.** Ganti jalur tanda tangan (signature pad) → URL bucket
- [x] **B5.** Ganti jalur penyimpanan PDF → URL bucket
- [x] **B6.** Penampil gambar/PDF di layar detail laporan → baca dari URL (bukan base64)
- [x] **B7.** Uji end-to-end: buat 1 laporan harian + 1 foto → cek **File Browser** bucket → foto muncul di folder yang benar
- [ ] **B8.** `flutter analyze` + `flutter test` + build release + **deploy hosting** + verifikasi di Chrome & HP
- [ ] **B9.** Catatan keamanan (dibahas saat implementasi): unggah langsung dari klien pakai kredensial terbatas dulu; jalur paling aman (presigned URL via VPS) menyusul bersama rencana VPS

---

## C. TASK TERTUNDA LAIN (tidak butuh bucket — bisa dikerjakan kapan saja)

- [x] **C1.** 🟢 [ZCODE] **Tombol "Download Aplikasi" di landing diarahkan ke Cloudflare R2:** File `app-release.apk` (65.3 MB) berhasil di-build dan diunggah ke bucket `lapakdir-media` (URL publik: `https://pub-8e92a1d103164d3182dd4796ffe1ce9a.r2.dev/app-release.apk`). Tombol di landing page sudah dihubungkan.
- [x] **C2.** 🟡 [ZCODE] **Kompresi logo SELESAI 17 Nov 2026:** `logoRev.png` 1.376→84 KB (-94%, 512px), `web/icons/logoRev.png` (salinan landing) 1.376→84 KB, `logo_white_bg.png` 221→90 KB, `landingpage.png` 494→267 KB (1600px + kuantisasi). Build + deploy + verifikasi visual: tajam. First-load hemat ±2,3 MB/pengunjung baru
- [ ] **C3.** 🟡 [USER] **Ganti password default** semua 5 akun (`password123`) lewat menu Akun → Keamanan
- [ ] **C4.** 🟡 [USER] **Uji "Tambah Akun"** di Dashboard Admin sekali (buat akun kontraktor percobaan → login dengan akun itu → hapus/nonaktifkan)
- [ ] **C5.** ⏸️ [USER] **Domain `lapakdir.com`** — menunggu koordinasi dengan client. Setelah dibeli:
  - [ ] Kirim nama domainnya ke ZCode
  - [ ] [ZCODE] Pandu penghubungan ke Firebase Hosting (TXT verifikasi + A record di DNS idwebhost)
  - [ ] [ZCODE] SSL gratis otomatis dari Firebase + ganti judul tab jadi `LapakDIR — SakaRep`
- [ ] **C6.** 🟢 [ZCODE/TIM] Selesaikan sidebar "Corporate Slate Sidebar" (3 test gagal milik tim: kelompok TEKNIS & ANGGARAN + sembunyikan PELAPORAN untuk Kontraktor di web)
- [ ] **C7.** 🟢 [KEDUANYA] **VPS Sumopod + 9Router AI** (fase berikutnya: nginx + SSL, deploy, 9Router, fitur AI di aplikasi)

---

## STATUS SAAT INI (ringkas)

| Item | Status |
|---|---|
| Database Firestore Jakarta + data demo | ✅ Live |
| Firebase Auth (5 akun) + rules ketat | ✅ Live |
| Halaman Admin CRUD akun | ✅ Live (uji Tambah Akun: C4) |
| Hosting produksi `tatasakaconsultant-id.web.app` | ✅ Live |
| Splash cek akun nonaktif saat sesi lanjut | ✅ Live |
| Object storage `tatasaka-media` | ⏳ Provisioning macet > 1 jam (tiket support terkirim) |
| Integrasi foto/PDF ke bucket | 🔜 Menunggu kredensial (Bagian B) |
| Tombol Download Aplikasi | 🔴 404 (C1) |
| Kompresi logo | 🟡 Belum (C2) |
| Domain lapakdir.com | ⏸️ Menunggu client (C5) |
| VPS + AI 9Router | 🟢 Rencana (C7) |
