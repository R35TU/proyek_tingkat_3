import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';

/// Satu tempat untuk aturan "kontrak/kegiatan mana yang boleh dilihat akun".
///
/// Relasi di data:
/// - Dinas    → `contracts/{id}.dinasUid` (fallback nama instansi untuk data lama).
/// - Kontraktor → `kegiatans[].kontraktorUid` (fallback nama perusahaan untuk
///   data lama yang belum punya UID).
/// - Konsultan/Admin → semua kontrak.
///
/// Sebelumnya aturan ini diduplikasi di beberapa layar, dan halaman Akun sama
/// sekali tidak memfilternya.
class ContractAccess {
  ContractAccess._();

  /// Kata yang terlalu umum untuk dijadikan penanda kecocokan nama, supaya
  /// dua perusahaan berbeda tidak dianggap sama hanya karena sama-sama
  /// mengandung "cv", "jalan", "paket", dan sejenisnya.
  static const Set<String> _ignoredNameTokens = {
    'cv', 'pt', 'ud', 'pd', 'fa', 'tbk', 'persero', 'perseroan', 'terbatas',
    'konsultan', 'kontraktor', 'pelaksana', 'penyedia', 'jasa', 'mandiri',
    'jalan', 'kegiatan', 'proyek', 'paket', 'pekerjaan', 'pemeliharaan',
    'berkala', 'pembangunan', 'rehabilitasi', 'peningkatan', 'pengawasan',
    'indonesia', 'kabupaten', 'kab', 'kota', 'provinsi', 'prov', 'kecamatan',
    'dan', 'the', 'and', 'inc', 'ltd', 'group',
  };

  /// Pecah nama menjadi token huruf/angka yang layak dibandingkan.
  static List<String> _nameTokens(String raw) {
    return raw
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty && !_ignoredNameTokens.contains(t))
        // Angka pembeda (mis. "CV. TESTING 1" vs "CV. TESTING 2") tetap ikut
        // dibandingkan walau hanya satu karakter, supaya dua perusahaan berbeda
        // tidak dianggap sama hanya karena kata dasarnya sama.
        .where((t) => t.length >= 4 || RegExp(r'^\d+$').hasMatch(t))
        .toList();
  }

  /// Apakah satu kegiatan ditugaskan kepada kontraktor ini?
  ///
  /// Prioritas `kontraktorUid`. Bila kosong (data lama), dicocokkan lewat nama
  /// perusahaan/nama akun dengan token yang sama — bukan `contains` mentah,
  /// sehingga nama kosong tidak lagi dianggap cocok dengan semua kegiatan.
  static bool kegiatanOwnedByKontraktor(
    Map<String, dynamic> kegiatan, {
    required String contractorUid,
    String fullName = '',
    String companyOrAgency = '',
    String username = '',
  }) {
    final uid = contractorUid.trim();
    final kegUid = (kegiatan['kontraktorUid'] ?? '').toString().trim();
    // Bila kegiatan sudah punya `kontraktorUid`, UID itu yang menentukan.
    // Nama tidak boleh "menyelamatkan" akun lain yang namanya mirip.
    if (kegUid.isNotEmpty) return uid.isNotEmpty && uid == kegUid;

    final kegTokens =
        _nameTokens((kegiatan['kontraktor'] ?? '').toString()).toSet();
    if (kegTokens.isEmpty) return false;

    for (final candidate in [fullName, companyOrAgency, username]) {
      final tokens = _nameTokens(candidate).toSet();
      if (tokens.isEmpty) continue;
      final shared = tokens.intersection(kegTokens);
      if (shared.length >= 2) return true;
      // Satu kata sama hanya cukup bila salah satu nama memang hanya punya
      // satu kata pembeda — mis. akun "CV. DIVAN" vs "CV. DIVAN INSAN
      // CEMERLANG". Dua perusahaan berbeda seperti "CV. KARYA JAYA" dan
      // "CV. KARYA ABADI" tidak dianggap sama.
      if (shared.length == 1 &&
          (tokens.length == 1 || kegTokens.length == 1)) {
        return true;
      }
    }
    return false;
  }

  /// Apakah kontrak ini terkait dengan kontraktor tersebut (minimal satu
  /// kegiatan yang ditugaskan kepadanya)?
  static bool contractOwnedByKontraktor(
    ContractModel contract, {
    required String contractorUid,
    String fullName = '',
    String companyOrAgency = '',
    String username = '',
  }) {
    return contract.kegiatans.any(
      (k) => kegiatanOwnedByKontraktor(
        k,
        contractorUid: contractorUid,
        fullName: fullName,
        companyOrAgency: companyOrAgency,
        username: username,
      ),
    );
  }

  /// Kegiatan pada satu kontrak yang boleh tampil untuk profil ini.
  ///
  /// Kontraktor hanya melihat kegiatan yang ditugaskan kepadanya, walau
  /// kontraknya juga berisi kegiatan milik kontraktor lain. Peran lain
  /// (konsultan, dinas, admin) melihat seluruh kegiatan kontrak.
  /// Indeks asli dipertahankan agar navigasi ke detail kegiatan tetap benar.
  static List<MapEntry<int, Map<String, dynamic>>> visibleKegiatanEntries(
    ContractModel contract,
    UserProfileProvider user,
  ) {
    final entries = contract.kegiatans.asMap().entries.toList();
    if (!user.isKontraktor) return entries;
    return entries
        .where(
          (entry) => kegiatanOwnedByKontraktor(
            entry.value,
            contractorUid: user.uid,
            fullName: user.namaLengkap,
            companyOrAgency: user.companyOrAgency,
            username: user.username,
          ),
        )
        .toList();
  }

  /// Kontrak yang boleh tampil untuk profil yang sedang login.
  static List<ContractModel> visibleContracts(
    List<ContractModel> allContracts,
    UserProfileProvider user,
  ) {
    if (user.isKontraktor) {
      return allContracts
          .where(
            (c) => contractOwnedByKontraktor(
              c,
              contractorUid: user.uid,
              fullName: user.namaLengkap,
              companyOrAgency: user.companyOrAgency,
              username: user.username,
            ),
          )
          .toList();
    }
    if (user.isDinas) {
      return allContracts
          .where(
            (c) => c.isOwnedByDinas(
              dinasUserUid: user.uid,
              companyOrAgency: user.companyOrAgency,
              userFullName: user.namaLengkap,
            ),
          )
          .toList();
    }
    // Konsultan & Admin mengelola seluruh kontrak.
    return allContracts;
  }
}
