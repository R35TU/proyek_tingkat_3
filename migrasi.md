# 📋 DOKUMENTASI MIGRASI FLUTTER KE WEB (TATA SAKA CONSULTANT)
> **Spesialisasi Bagian Tugas: Anggota 1**  
> **Peran & Tanggung Jawab Utama:** Core Architecture, Global Layout, Reusable UI Components, Routing Navigasi, Base HTTP Client, & Design System  
> **Referensi Visual:** Bedah 31 Tangkapan Layar Asli Aplikasi Flutter pada Folder `ss/` & Source Code `lib/`

---

## 📑 DAFTAR ISI
1. [Ringkasan Peran Anggota 1](#1-ringkasan-peran-anggota-1)
2. [Hasil Analisis Visual & Desain Sistem Berdasarkan Folder `ss/`](#2-hasil-analisis-visual--desain-sistem-berdasarkan-folder-ss)
   - 2.1 Token Warna Resmi (*Corporate Slate & Status Accents*)
   - 2.2 Tipografi & Radius Sudut (*Shape & Typography*)
   - 2.3 Transformasi Layout Mobile (Bottom Nav) ke Web Desktop (Sidebar + Navbar)
   - 2.4 Struktur 5–7 Halaman Navigasi Web
3. [Product Requirements Document (PRD) – Modul Anggota 1](#3-product-requirements-document-prd--modul-anggota-1)
   - 3.1 Setup Project & Core Architecture
   - 3.2 Design System & Token Styling (`tailwind.config.js` & `globals.css`)
   - 3.3 Global Layout System (Navbar, Sidebar, Footer, Drawer)
   - 3.4 Page Routing & Auth Guard (`ProtectedRoute`)
   - 3.5 Base HTTP Client (Axios Instance & Interceptor)
   - 3.6 Reusable UI Component Kit (`Button`, `Input`, `Card`, `Badge`)
   - 3.7 Acceptance Criteria (Kriteria Keberhasilan Tugas)
4. [RACE Prompting Framework (Siap Pakai untuk AI Generator)](#4-race-prompting-framework-siap-pakai-untuk-ai-generator)
   - 4.1 Prompt 1: Setup Project, Tailwind Design Tokens & Typography
   - 4.2 Prompt 2: Adaptive Global Layout (Sidebar, Top Navbar, Footer)
   - 4.3 Prompt 3: Page Routing & Protected Route Auth Guard (7 Rute)
   - 4.4 Prompt 4: Base HTTP Client (Axios Instance + Interceptor) & Auth State
   - 4.5 Prompt 5: Reusable UI Component Kit (`Button`, `Input`, `Card`, `Badge`)
5. [Contoh Kode Implementasi Fondasi Acuan](#5-contoh-kode-implementasi-fondasi-acuan)

---

## 1. RINGKASAN PERAN ANGGOTA 1

Berdasarkan kesepakatan pembagian tugas kelompok, **Anggota 1** memegang kendali atas fondasi arsitektur frontend web:

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       ANGGOTA 1: CORE ARCHITECTURE & ROUTING                │
├───────────────────────────────────┬─────────────────────────────────────────┤
│ • Setup Project (React/Next/Vue)  │ Fondasi arsitektur, bundler, TypeScript │
│ • Global Layout                   │ Top Navbar, Collapsible Sidebar, Footer │
│ • Reusable UI Components          │ Button, Input/FormField, Card, Badge    │
│ • Routing Navigasi 5–7 Halaman    │ Route config, nested routing & guards   │
│ • Setup Base HTTP Client          │ Axios instance, interceptors, auth token│
│ • Setup Layout Wrapper & Tokens   │ Tailwind theme & Corporate Slate tokens │
└───────────────────────────────────┴─────────────────────────────────────────┘
```

Fondasi ini disiapkan agar **Anggota 2** (Modul Kontrak & Detail), **Anggota 3** (Modul Laporan & RKK/BOQ), dan **Anggota 4** (Modul Timeline & Profil/Akun) dapat langsung membuat halaman masing-masing dengan mengimpor komponen dan routing yang sudah terstandarisasi.

---

## 2. HASIL ANALISIS VISUAL & DESAIN SISTEM BERDASARKAN FOLDER `ss/`

Setelah menelaah 31 screenshot di folder `ss/` (mulai dari Splash Screen, Login, Dashboard, Daftar Kontrak, Tambah Kontrak, Detail Kontrak, Kelola RKK/BOQ, hingga Data Laporan Harian/Mingguan), berikut ekstraksi desain sistem aslinya:

### 2.1 Token Warna Resmi (*Corporate Slate & Status Accents*)

| Token Warna | Nilai Hex | Screenshot Bukti & Penggunaan di UI |
| :--- | :---: | :--- |
| **Navy Slate** *(Primary Brand)* | `#202938` | Tombol `Masuk` di Login, tombol `+ Tambah Kontrak Baru`, Tab aktif `Umum`/`Laporan Harian`, icon header, dan button CTA utama. |
| **Slate** *(Muted/Secondary)* | `#64748B` | Subtitle teks (*"Silahkan masuk..."*, *"Konsultan Pengawas"*), icon tidak aktif di navbar, info hari dan tanggal laporan. |
| **Soft Gray** *(Canvas Background)* | `#F3F4F6` | Latar belakang seluruh halaman (`scaffoldBackgroundColor`), memberikan kontras bersih terhadap card putih. |
| **White Surface** *(Card & Inputs)* | `#FFFFFF` | Latar belakang kartu statistik, modal rincian bobot pekerjaan, header bar, dan dropdown popup. |
| **Slate Lighter / Pill BG** | `#F1F5F9` | Kontainer segmented switch (Tab Harian/Mingguan), latar belakang chip role login tidak aktif, tombol aksi ringan. |
| **Border Gray** | `#E2E8F0` | Garis batas tipis pada seluruh card, input text field, dan pemisah table. |
| **Mint / Success Light** | `#E6F4EA` | Latar belakang badge status `• Progres` dan `• Terverifikasi`. |
| **Success Green** | `#10B981` | Teks status `• Progres`, badge `Sesuai 100%`, icon trending pada statistik `Kontrak Aktif`. |
| **Danger Red** | `#DC2626` | Icon tong sampah (hapus kegiatan/item), teks error validasi form, dan aksi hapus data. |
| **Warning / Amber** | `#F59E0B` | Status pending / dokumen revisi. |

### 2.2 Tipografi & Radius Sudut (*Shape & Typography*)
- **Font Family:** `Inter`, `sans-serif` (bersih, terbaca jelas untuk aplikasi enterprise & teknik).
- **Corner Radius Standar:**
  - `rounded-xl` (12px): Seluruh input form, tombol CTA utama, dan chip navigasi tab.
  - `rounded-2xl` (16px): Kontainer card data, kartu carousel kontrak, card aktivitas terkini, dan modal bottom sheet.
  - `rounded-full`: Badge indikator titik bulat (`•`).
- **Elevation / Bayangan:**
  - `shadow-sm` tipis (`rgba(0, 0, 0, 0.03)` dengan blur `8px - 10px`), tampilan modern tanpa bayangan tebal.

### 2.3 Transformasi Layout Mobile (Bottom Nav) ke Web Desktop

| Komponen Mobile (Flutter) | Transformasi Layout Web Desktop (Tugas Anggota 1) |
| :--- | :--- |
| **BottomNavigationBar** 5 Tab (`Dashboard`, `Kontrak`, `Laporan`, `Timeline`, `Akun`) | Menjadi **Collapsible Left Sidebar** (lebar `260px` expand / `80px` collapse) di sisi kiri layar dengan icon + label teks. |
| **AppBar Mobile** (Menu icon, Title, Bell icon) | Menjadi **Top Header Navbar** web (tinggi `64px`), memuat Breadcrumbs dinamis, toggle sidebar, notifikasi dengan badge merah, dan profile avatar menu. |
| **Bottom Sheet Modal** (Form tambah item, filter) | Menjadi **Centered Dialog Modal** web dengan backdrop overlay gelap. |
| **Mobile Drawer / Hamburger** | Di layar tablet/mobile (< 1024px), sidebar otomatis menjadi **Off-canvas Slide-over Drawer**. |
| **Footer Info** | Menjadi **Global Footer** statis di bagian bawah layout web. |

### 2.4 Struktur 5–7 Halaman Navigasi Web

Sesuai dengan alur sistem di folder `ss/`, terdapat 7 halaman web yang dipetakan:

```text
               ┌───────────────────────┐
               │  /login (Auth Page)   │
               └──────────┬────────────┘
                          │ (Login Berhasil & Token Valid)
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                 GLOBAL LAYOUT (Sidebar & Header)             │
│                                                             │
│  [1] /dashboard     -> Ringkasan statistik & carousel       │
│  [2] /kontrak       -> Daftar proyek & search filter        │
│  [3] /kontrak/:id   -> Detail kontrak (Tab Umum & Admin)    │
│  [4] /laporan       -> Hub data laporan & ringkasan BoQ     │
│  [5] /timeline      -> Kurva S & chronological history      │
│  [6] /pengaturan    -> Profil konsultan & preferensi akun   │
│  [7] *              -> 404 Halaman Tidak Ditemukan          │
└─────────────────────────────────────────────────────────────┘
```

---

## 3. PRODUCT REQUIREMENTS DOCUMENT (PRD) – MODUL ANGGOTA 1

### 3.1 Setup Project & Core Architecture
- **Framework Utama:** React (dengan Vite) atau Next.js (App Router). *Rekomendasi terbaik untuk tugas kelompok kuliah: React 18 + Vite + TypeScript + Tailwind CSS karena cepat di-build dan mudah dijalankan oleh seluruh anggota.*
- **Struktur Folder Standar:**
  ```text
  src/
  ├── assets/                # Logo CV. Tata Saka Consultant, ikon
  ├── components/
  │   ├── layout/            # [ANGGOTA 1] Shell Utama, Sidebar, Navbar, Footer
  │   └── ui/                # [ANGGOTA 1] Reusable UI Kit (Button, Input, Card, Badge)
  ├── pages/                 # Tempat pengerjaan halaman oleh Anggota 1, 2, 3, 4
  │   ├── Login.tsx          # Halaman autentikasi
  │   ├── Dashboard.tsx      # Halaman utama
  │   ├── KontrakList.tsx    # Daftar kontrak (Anggota 2)
  │   ├── KontrakDetail.tsx  # Detail kontrak (Anggota 2)
  │   ├── LaporanList.tsx    # Laporan & BOQ (Anggota 3)
  │   ├── TimelineView.tsx   # Jadwal & Kurva S (Anggota 4)
  │   └── SettingsPage.tsx   # Profil & Pengaturan (Anggota 4)
  ├── router/                # [ANGGOTA 1] AppRoutes.tsx & ProtectedRoute.tsx
  ├── services/              # [ANGGOTA 1] api.client.ts (Axios + Interceptor)
  ├── store/                 # [ANGGOTA 1] authStore.ts (State session pengguna)
  └── styles/                # [ANGGOTA 1] globals.css & Tailwind Tokens
  ```

### 3.2 Design System & Token Styling
- Warna tema harus merefleksikan 100% token `app_colors.dart` ke dalam `tailwind.config.js`:
  * `corporate-navy`: `#202938`
  * `corporate-slate`: `#64748B`
  * `corporate-softGray`: `#F3F4F6`
  * `corporate-border`: `#E2E8F0`
  * `corporate-surface`: `#FFFFFF`
  * `status-success`: `#10B981` (dengan background `#E6F4EA`)
  * `status-danger`: `#DC2626`
- Mengatur font `Inter` sebagai font default di `globals.css` dengan antialiasing aktif.

### 3.3 Global Layout System (`src/components/layout/`)
1. **Collapsible Sidebar (Kiri):**
   - Logo perusahaan CV. Tata Saka Consultant di bagian header sidebar.
   - 5 menu navigasi dengan icon Lucide (`LayoutDashboard`, `FolderGit2`, `FileText`, `CalendarRange`, `Settings`).
   - Indikator aktif: Background `#202938`, teks putih, icon putih.
   - Indikator hover: Background `#F1F5F9`, teks `#202938`.
   - Tombol toggle collapse di bagian bawah untuk memperluas area kerja.
2. **Top Header Navbar (Atas):**
   - Tinggi `64px`, border-b `#E2E8F0`, latar putih.
   - Breadcrumb otomatis berdasarkan rute URL aktif.
   - Ikon lonceng notifikasi dengan counter badge merah.
   - User profile dropdown (Nama: "CV. Tata Saka", Role: "Konsultan Supervisi", tombol Logout).
3. **Responsive Mobile Drawer:**
   - Terbuka otomatis via tombol hamburger saat lebar layar < 1024px.
4. **Global Footer:**
   - Memuat copyright resmi: `© 2026 CV. Tata Saka Consultant. All rights reserved.`

### 3.4 Page Routing & Auth Guard (`src/router/`)
- Mendaftarkan 7 rute halaman menggunakan `react-router-dom`.
- Menyiapkan komponen `ProtectedRoute`:
  * Mengecek keberadaan token auth di `localStorage` / `authStore`.
  * Jika user belum login dan mencoba membuka rute selain `/login`, otomatis di-redirect ke `/login`.
  * Jika user sudah login dan mengakses `/login`, otomatis di-redirect ke `/dashboard`.
- Placeholder halaman dibuat rapi agar anggota 2, 3, dan 4 tidak mengalami blank screen saat pertama kali *pull repository*.

### 3.5 Base HTTP Client (`src/services/api.client.ts`)
- Dibuat menggunakan **Axios** instance dengan konfigurasi:
  * `baseURL` membaca `import.meta.env.VITE_API_BASE_URL` (default fallback ke mock/local API).
  * `timeout: 15000` (15 detik).
- **Request Interceptor:**
  * Menyisipkan header `Authorization: Bearer <token>` secara otomatis pada setiap request jika token ada.
- **Response Interceptor:**
  * Mem-bypass `response.data` agar pemanggilan API di level halaman lebih bersih.
  * Menangkap HTTP `401 Unauthorized` -> otomatis menghapus sesi dari local storage dan mengalihkan browser ke `/login?expired=true`.
  * Menangkap error jaringan global (`500 Server Error` / Network Offline).

### 3.6 Reusable UI Component Kit (`src/components/ui/`)

Komponen wajib yang harus disediakan Anggota 1 sesuai tangkapan layar `ss/`:

1. **`Button`:**
   - *Varian:*
     - `primary`: Background `#202938`, teks putih, rounded-xl (meniru tombol "Masuk" dan "+ Tambah Kontrak Baru").
     - `outline`: Border `1.5px solid #202938`, latar transparan, teks `#202938` (meniru tombol "Kelola Rincian Pekerjaan (RKK)").
     - `secondary`: Background `#F1F5F9`, teks `#202938`.
     - `danger`: Background `#DC2626`, teks putih.
     - `ghost`: Latar transparan dengan hover ringan.
   - *Fitur:* Loading state dengan spinner, slot `leftIcon` dan `rightIcon`.
2. **`Input` (Clean Form Field):**
   - Meniru widget `CleanTextFormField`:
   - Radius `rounded-xl`, latar `#FFFFFF` / `#F8FAFC`, border halus `#E2E8F0`.
   - Focus ring: Border aktif berubah menjadi Navy Slate `#202938`.
   - Mendukung slot `prefixIcon` (icon pencarian, kalender, rupiah) dan `suffixIcon` (icon mata password).
   - Label teks atas huruf tebal dan teks error merah di bawah.
3. **`Card`:**
   - Radius `rounded-2xl` (16px), background putih, border tipis `#E2E8F0`, shadow halus.
   - Terdiri dari `CardHeader`, `CardTitle`, `CardBody`, dan `CardFooter`.
4. **`Badge` (Pill Status):**
   - Varian `progres` / `success`: Latar `#E6F4EA`, teks `#10B981` dengan titik hijau bulat (`•`).
   - Varian `neutral`: Latar `#F1F5F9`, teks `#202938`.
   - Varian `warning`: Latar `#FEF3C7`, teks `#B45309`.

### 3.7 Acceptance Criteria (AC)
- [x] Proyek web terinisialisasi bersih dengan TypeScript dan Tailwind CSS.
- [x] Seluruh token warna di `tailwind.config.js` sama 100% dengan `app_colors.dart` dan screenshot di folder `ss/`.
- [x] Global Layout web memiliki Sidebar, Header Navbar, Breadcrumb, dan Footer yang responsif di desktop maupun mobile.
- [x] Routing 7 halaman terintegrasi dengan proteksi sesi login (`ProtectedRoute`).
- [x] Axios instance berhasil menyuntikkan token otomatis dan meredirect error 401 ke login.
- [x] Komponen `Button`, `Input`, `Card`, dan `Badge` siap diimpor oleh Anggota 2, 3, dan 4.

---

## 4. RACE PROMPTING FRAMEWORK (SIAP PAKAI UNTUK AI GENERATOR)

Gunakan kumpulan prompt berformat **RACE** (*Role, Action, Context, Expectation*) di bawah ini ke AI (seperti ChatGPT / Claude / Gemini / Cursor) untuk menghasilkan kode kerja spesifik bagian Anggota 1.

---

### 4.1 PROMPT 1: Setup Project, Tailwind Design Tokens & Typography

```markdown
### 🚀 PROMPT RACE 1: SETUP TAILWIND DESIGN TOKENS & TYPOGRAPHY

**R - Role:**  
Bertindaklah sebagai Senior Frontend Web Architect & Design System Specialist.

**A - Action:**  
Buatkan konfigurasi lengkap untuk:
1. `tailwind.config.js` yang mendefinisikan token warna korporat (*Corporate Slate*) hasil ekstraksi dari aplikasi Flutter "Tata Saka Consultant".
2. `src/styles/globals.css` yang mengimpor font `Inter`, utility font antialiased, reset border, dan styling custom scrollbar.

**C - Context:**  
Saya adalah Anggota 1 dalam kelompok penugasan migrasi sistem pengawasan proyek Flutter ke Web. Berdasarkan hasil screenshot di folder `ss/` dan `app_colors.dart`, sistem memiliki palet resmi:
- Navy Slate: `#202938` (Brand utama, tombol CTA, header)
- Slate: `#64748B` (Secondary text & icon nonaktif)
- Soft Gray Canvas: `#F3F4F6` (Background halaman)
- White Surface: `#FFFFFF` (Card & modal)
- Slate Lighter: `#F1F5F9` (Pill switch & chip nonaktif)
- Border Gray: `#E2E8F0` (Border input & divider card)
- Success Mint: `#E6F4EA` dengan teks `#10B981` (Badge status "• Progres" & "• Terverifikasi")
- Danger Red: `#DC2626`

**E - Expectation:**  
- Format file `tailwind.config.js` ES Module modern yang siap pakai.
- Token warna diberi nama yang jelas (contoh: `colors: { corporate: { navy: '#202938', slate: '#64748B', ... } }`).
- Kode bersih, tervalidasi, dan siap disalin langsung ke proyek web.
```

---

### 4.2 PROMPT 2: Adaptive Global Layout (Sidebar, Top Navbar, Footer)

```markdown
### 🚀 PROMPT RACE 2: ADAPTIVE ENTERPRISE GLOBAL LAYOUT

**R - Role:**  
Bertindaklah sebagai Lead UI/UX Frontend Engineer spesialis Dashboard Enterprise.

**A - Action:**  
Bangun satu set komponen layout web yang saling terhubung:
1. `src/components/layout/GlobalLayout.tsx`: Shell utama pembungkus rute dashboard.
2. `src/components/layout/Sidebar.tsx`: Navigasi kiri dengan logo CV. Tata Saka Consultant, 5 menu utama, dukungan mode *expand/collapse*, dan drawer di mobile (< 1024px).
3. `src/components/layout/Navbar.tsx`: Header atas setinggi 64px dengan Breadcrumbs dinamis, tombol hamburger, lonceng notifikasi, dan avatar user dropdown (Logout & Profil).
4. `src/components/layout/Footer.tsx`: Baris hak cipta di bagian paling bawah.

**C - Context:**  
Di aplikasi mobile Flutter eksisting (`lib/screens/main_layout.dart`), navigasi menggunakan `BottomNavigationBar` dengan menu:
1. Dashboard (`/dashboard`)
2. Kontrak (`/kontrak`)
3. Laporan (`/laporan`)
4. Timeline (`/timeline`)
5. Akun (`/pengaturan`)
Layout ini wajib ditransformasikan ke web desktop menjadi Sidebar kiri tetap, dengan latar belakang aplikasi `#F3F4F6`, menu aktif berlatar `#202938` teks putih, dan header putih bersih dengan border bawah `#E2E8F0`.

**E - Expectation:**  
- Menggunakan React, TypeScript, Tailwind CSS, dan icon dari `lucide-react`.
- State sidebar (collapse/expand dan mobile open) dikelola dengan rapi menggunakan state lokal atau store.
- Integrasi navigasi aktif menggunakan `<NavLink>` dari `react-router-dom`.
- Desain 100% responsif, elegan, dan profesional.
```

---

### 4.3 PROMPT 3: Page Routing & Protected Route Auth Guard (7 Rute)

```markdown
### 🚀 PROMPT RACE 3: PAGE ROUTER & AUTH NAVIGATION GUARD

**R - Role:**  
Bertindaklah sebagai Fullstack / Frontend Security Engineer yang ahli dalam `react-router-dom` v6+.

**A - Action:**  
Buatkan arsitektur perutean lengkap:
1. `src/router/AppRoutes.tsx`: Konfigurasi router yang mendaftarkan 7 rute halaman sistem.
2. `src/router/ProtectedRoute.tsx`: Guard yang memvalidasi sesi token pengguna.
3. Placeholder halaman (*stub pages*) untuk 7 rute tersebut agar rekan sekelompok (Anggota 2, 3, 4) tinggal melanjutkan isi fiturnya.

**C - Context:**  
Aplikasi "Tata Saka Consultant" membutuhkan 7 rute terintegrasi:
- `/login` : Rute publik (Guest only, diarahkan ke dashboard jika sudah login)
- `/dashboard` : Halaman ringkasan statistik & carousel proyek (Terproteksi)
- `/kontrak` : Halaman daftar kontrak proyek (Terproteksi - Tugas Anggota 2)
- `/kontrak/:id` : Halaman detail kontrak umum & administrasi (Terproteksi - Tugas Anggota 2)
- `/laporan` : Halaman pusat data laporan & BoQ (Terproteksi - Tugas Anggota 3)
- `/timeline` : Halaman kurva S & riwayat kegiatan (Terproteksi - Tugas Anggota 4)
- `/pengaturan` : Halaman profil & pengaturan akun (Terproteksi - Tugas Anggota 4)
- `*` : Halaman 404 Not Found

**E - Expectation:**  
- Token dicek dari `localStorage.getItem('token')` atau `authStore`.
- Jika belum login dan mengakses rute terproteksi, redirect otomatis ke `/login`.
- Rute terproteksi bersarang di dalam `<GlobalLayout>` dengan `<Outlet />`.
- Tipe data TypeScript kuat dan kode bebas linting error.
```

---

### 4.4 PROMPT 4: Base HTTP Client (Axios Instance + Interceptor) & Auth State

```markdown
### 🚀 PROMPT RACE 4: BASE HTTP CLIENT & GLOBAL AUTH STATE

**R - Role:**  
Bertindaklah sebagai Frontend Architect spesialis API Data Layer.

**A - Action:**  
1. Buatkan modul HTTP Client terpusat berbasis **Axios** di `src/services/api.client.ts`.
2. Konfigurasikan **Request Interceptor** untuk otomatis menyematkan header `Authorization: Bearer <token>`.
3. Konfigurasikan **Response Interceptor** untuk:
   - Mengembalikan langsung data body (`response.data`).
   - Menangani error `401 Unauthorized` dengan membersihkan storage lokal dan redirect otomatis ke `/login`.
   - Logging error jaringan secara terpusat.
4. Buatkan store status autentikasi `src/store/authStore.ts` (menggunakan Zustand atau React Context) untuk fungsi `login()`, `logout()`, data `user`, dan `token`.

**C - Context:**  
Di Flutter, aplikasi masih menggunakan penyimpanan data mock lokal (`SharedPreferences`). Di web, kita menyiapkan lapisan HTTP client standar industri sehingga Anggota 2, 3, dan 4 saat membuat fitur CRUD tinggal memanggil `apiClient.get()`, `apiClient.post()`, dll tanpa perlu memikirkan header bearer token lagi.

**E - Expectation:**  
- Menggunakan TypeScript dengan interface respons terstruktur `ApiResponse<T>`.
- Menggunakan environment variable `import.meta.env.VITE_API_BASE_URL`.
- Kode modular, memiliki penanganan error yang anggun (*graceful error handling*).
```

---

### 4.5 PROMPT 5: Reusable UI Component Kit (`Button`, `Input`, `Card`, `Badge`)

```markdown
### 🚀 PROMPT RACE 5: REUSABLE UI COMPONENT KIT

**R - Role:**  
Bertindaklah sebagai UI Component Specialist & Design System Developer.

**A - Action:**  
Buatkan 4 komponen reusable di folder `src/components/ui/`:
1. `Button.tsx`: Varian `primary` (Navy `#202938`), `outline`, `secondary`, `danger`, `ghost`, ukuran (sm, md, lg), status loading (spinner), dan icon slot kiri/kanan.
2. `Input.tsx`: Form input bergaya `CleanTextFormField` Flutter: label di atas, border halus `#E2E8F0`, ring fokus Navy `#202938`, slot leading icon (pencarian, kalender, mata sandi), serta teks error validasi merah.
3. `Card.tsx`: Wadah konten putih dengan radius `rounded-2xl` (16px), border tipis `#E2E8F0`, shadow lembut, dilengkapi sub-komponen `CardHeader`, `CardTitle`, `CardBody`, dan `CardFooter`.
4. `Badge.tsx`: Pill status dengan indikator titik (`•`), mendukung status `success` (hijau `#10B981` bg `#E6F4EA`), `neutral`, dan `warning`.

**C - Context:**  
Komponen-komponen ini wajib dibuat oleh Anggota 1 agar seluruh tampilan yang dibuat oleh Anggota 2, 3, dan 4 seragam dan presisi menyerupai tangkapan layar di folder `ss/`. Desain wajib bernuansa modern korporat *CV. Tata Saka Consultant*.

**E - Expectation:**  
- Ditulis menggunakan React + TypeScript + Tailwind CSS.
- Komponen mendukung penerusan atribut standar HTML (`React.ButtonHTMLAttributes`, `React.InputHTMLAttributes`).
- Disertai contoh pemanggilan (*usage example*) singkat pada komentar file.
```

---

## 5. CONTOH KODE IMPLEMENTASI FONDASI ACUAN

Berikut adalah kode acuan siap pakai yang dapat disalin langsung saat mengeksekusi tugas Anggota 1:

### 5.1 `tailwind.config.js`
```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        corporate: {
          navy: '#202938',         // Primary Header, active sidebar, primary buttons
          slate: '#64748B',        // Subtitle text, muted icons
          softGray: '#F3F4F6',     // Canvas background
          surface: '#FFFFFF',      // Card & modal background
          border: '#E2E8F0',       // Dividers and input borders
          slateLighter: '#F1F5F9', // Segmented tab container, inactive chips
          slateDark: '#334155',    // Dark hover state
        },
        status: {
          mintBg: '#E6F4EA',       // Badge status background
          success: '#10B981',      // Success / Terverifikasi text & dots
          danger: '#DC2626',       // Error & Delete actions
          warning: '#F59E0B',      // Pending status
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        'xl': '12px',
        '2xl': '16px',
      }
    },
  },
  plugins: [],
}
```

### 5.2 Axios Client & Interceptor (`src/services/api.client.ts`)
```typescript
import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';

const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://api.tatasaka.id/v1';

export const apiClient = axios.create({
  baseURL: BASE_URL,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
});

// Request Interceptor: Otomatis sematkan Bearer Token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = localStorage.getItem('tata_saka_token');
    if (token && config.headers) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response Interceptor: Filter respons & redirect saat 401
apiClient.interceptors.response.use(
  (response) => response.data,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('tata_saka_token');
      localStorage.removeItem('tata_saka_user');
      window.location.href = '/login?expired=true';
    }
    return Promise.reject(error);
  }
);
```

### 5.3 Komponen Reusable Button (`src/components/ui/Button.tsx`)
```tsx
import React from 'react';
import { Loader2 } from 'lucide-react';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'outline' | 'secondary' | 'danger' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  isLoading?: boolean;
  leftIcon?: React.ReactNode;
  rightIcon?: React.ReactNode;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  isLoading = false,
  leftIcon,
  rightIcon,
  className = '',
  disabled,
  ...props
}) => {
  const base = 'inline-flex items-center justify-center font-semibold rounded-xl transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-1 disabled:opacity-50 disabled:cursor-not-allowed';

  const variants = {
    primary: 'bg-corporate-navy text-white hover:bg-corporate-slateDark focus:ring-corporate-navy shadow-sm',
    outline: 'border-2 border-corporate-navy text-corporate-navy hover:bg-corporate-slateLighter focus:ring-corporate-navy',
    secondary: 'bg-corporate-slateLighter text-corporate-navy border border-corporate-border hover:bg-slate-200 focus:ring-slate-400',
    danger: 'bg-status-danger text-white hover:bg-red-700 focus:ring-red-500 shadow-sm',
    ghost: 'text-corporate-slate hover:bg-corporate-slateLighter hover:text-corporate-navy focus:ring-slate-300',
  };

  const sizes = {
    sm: 'text-xs px-3 py-1.5 gap-1.5',
    md: 'text-sm px-4 py-2.5 gap-2',
    lg: 'text-base px-6 py-3 gap-2.5',
  };

  return (
    <button
      className={`${base} ${variants[variant]} ${sizes[size]} ${className}`}
      disabled={disabled || isLoading}
      {...props}
    >
      {isLoading ? <Loader2 className="w-4 h-4 animate-spin" /> : leftIcon}
      <span>{children}</span>
      {!isLoading && rightIcon}
    </button>
  );
};
```

---

## 🎯 DAFTAR CEK SERAH TERIMA ANGGOTA 1 KEPADA ANGGOTA 2, 3, & 4
Ketika Anggota 1 selesai melakukan setup fondasi ini:
1. Rekan kelompok tinggal menjalankan `git pull` dan `npm install`.
2. **Anggota 2** langsung fokus membuat konten tabel & form di `src/pages/KontrakList.tsx` dan `src/pages/KontrakDetail.tsx`.
3. **Anggota 3** langsung fokus membuat tabel rincian item BoQ & lembar mingguan di `src/pages/LaporanList.tsx`.
4. **Anggota 4** langsung fokus membuat kurva S di `src/pages/TimelineView.tsx` dan profil di `src/pages/SettingsPage.tsx`.
5. Seluruh anggota menggunakan layout seragam yang otomatis responsive di web desktop maupun tablet.
