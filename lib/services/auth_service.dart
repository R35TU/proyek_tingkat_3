import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:tata_saka_app/firebase_options.dart';

/// Service autentikasi Firebase (Email/Password).
///
/// Konvensi akun:
/// - Akun demo dibuat sebagai email sintetis: `username@tatasakaconsultant.id`
///   (admin, konsultan, kontraktor1, kontraktor2, dinas) — layar login tetap
///   menerima username tanpa "@", service yang menerjemahkan.
/// - Akun yang dibuat Admin lewat menu "Tambah Akun" memakai email asli.
///
/// Profil & role disimpan di Firestore collection `users` (dokumen id = uid),
/// sehingga Admin dapat mengatur role/status aktif tanpa menyentuh Auth.
class AuthService {
  AuthService._();

  static const String _emailDomain = 'tatasakaconsultant.id';

  /// Akun demo dinonaktifkan — akun pengguna dikelola melalui menu Admin atau Firebase Auth / Firestore.
  static const List<Map<String, String>> seedAccounts = [];

  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static User? get currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      // Firebase belum diinisialisasi (lingkungan test / gagal init) →
      // perlakukan sebagai tidak ada sesi.
      return null;
    }
  }

  /// Login ke Firebase Auth — input langsung berupa EMAIL (tanpa terjemahan).
  /// Melempar FirebaseAuthException jika gagal.
  static Future<UserCredential> signIn(String email, String password) {
    return auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  static Future<void> signOut() => auth.signOut();

  /// Ambil profil user dari Firestore. Null jika belum ada / nonaktif.
  static Future<Map<String, dynamic>?> fetchUserDoc(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return Map<String, dynamic>.from(snap.data() as Map);
  }

  /// Buat akun baru ATAS PERINTAH ADMIN tanpa mengganggu sesi admin:
  /// memakai instance Firebase sekunder sementara.
  ///
  /// Setelah uid diperoleh, profil ditulis ke Firestore `users`.
  /// Melempar FirebaseAuthException jika email/password tidak valid.
  static Future<String> createAccount({
    required String email,
    required String password,
    required String role,
    required String namaLengkap,
    required String instansi,
    required bool isActive,
  }) async {
    final tempAppName = 'provision-${DateTime.now().millisecondsSinceEpoch}';
    final tempApp = await Firebase.initializeApp(
      name: tempAppName,
      options: DefaultFirebaseOptions.currentPlatform,
    );
    try {
      final cred = await FirebaseAuth.instanceFor(app: tempApp)
          .createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      final uid = cred.user!.uid;
      await _db.collection('users').doc(uid).set({
        'email': email.trim().toLowerCase(),
        'username': email.split('@').first,
        'role': role,
        'namaLengkap': namaLengkap.trim(),
        'companyOrAgency': instansi.trim(),
        'isActive': isActive,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return uid;
    } finally {
      await tempApp.delete();
    }
  }

  /// Perbarui profil user (role, nama, instansi, status aktif).
  static Future<void> updateUserDoc(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Hapus dokumen profil — login akun itu otomatis ditolak
  /// (akun Auth-nya tetap ada; hapus permanen butuh backend/Admin SDK).
  static Future<void> deleteUserDoc(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  /// Ganti password akun yang sedang login (perlu verifikasi password lama).
  static Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Tidak ada sesi login aktif.',
      );
    }
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: oldPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  /// Akun demo dinonaktifkan — akun pengguna dikelola melalui menu Admin atau Firebase Console.
  static Future<void> ensureSeededAccounts() async {
    return;
  }
}
