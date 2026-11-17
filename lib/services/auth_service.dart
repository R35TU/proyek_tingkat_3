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

  /// Email demo bawaan (seed) — password sama: `password123`.
  static const List<Map<String, String>> seedAccounts = [
    {'email': 'admin@$_emailDomain', 'username': 'admin', 'password': 'password123', 'role': 'Admin', 'nama': 'Admin Sistem', 'instansi': 'CV. Tata Saka Consultant'},
    {'email': 'konsultan@$_emailDomain', 'username': 'konsultan', 'password': 'password123', 'role': 'Konsultan', 'nama': 'CV. Tata Saka Consultant', 'instansi': 'CV. Tata Saka Consultant'},
    {'email': 'kontraktor1@$_emailDomain', 'username': 'kontraktor1', 'password': 'password123', 'role': 'Kontraktor', 'nama': 'CV. Divan Insan Cemerlang', 'instansi': 'CV. Divan Insan Cemerlang'},
    {'email': 'kontraktor2@$_emailDomain', 'username': 'kontraktor2', 'password': 'password123', 'role': 'Kontraktor', 'nama': 'CV. Langgeng', 'instansi': 'CV. Langgeng'},
    {'email': 'dinas@$_emailDomain', 'username': 'dinas', 'password': 'password123', 'role': 'Dinas', 'nama': 'DPU-PR Kabupaten Purbalingga', 'instansi': 'DPU-PR'},
  ];

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

  /// Pastikan akun demo (5 email sintetis) ada di Firebase Auth + Firestore.
  /// Dijalankan sekali saat aplikasi start; aman dipanggil berkali-kali:
  /// hanya melakukan sesuatu bila collection `users` masih kosong.
  static Future<void> ensureSeededAccounts() async {
    try {
      final users = await _db.collection('users').limit(1).get();
      if (users.docs.isNotEmpty) return; // sudah ada profil — selesai

      for (final acc in seedAccounts) {
        final email = acc['email']!;
        String uid;
        try {
          // Buat akun Auth via instance sekunder agar sesi aktif tidak berubah.
          final tempApp = await Firebase.initializeApp(
            name: 'seed-${DateTime.now().millisecondsSinceEpoch}',
            options: DefaultFirebaseOptions.currentPlatform,
          );
          try {
            final cred = await FirebaseAuth.instanceFor(app: tempApp)
                .createUserWithEmailAndPassword(
              email: email,
              password: acc['password']!,
            );
            uid = cred.user!.uid;
          } finally {
            await tempApp.delete();
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == 'email-already-in-use') {
            // Akun Auth sudah ada (mis. dari import) → login utk ambil uid.
            final tempApp = await Firebase.initializeApp(
              name: 'seed-in-${DateTime.now().millisecondsSinceEpoch}',
              options: DefaultFirebaseOptions.currentPlatform,
            );
            try {
              final cred = await FirebaseAuth.instanceFor(app: tempApp)
                  .signInWithEmailAndPassword(email: email, password: acc['password']!);
              uid = cred.user!.uid;
            } finally {
              await tempApp.delete();
            }
          } else {
            rethrow;
          }
        }
        await _db.collection('users').doc(uid).set({
          'email': email,
          'username': acc['username'],
          'role': acc['role'],
          'namaLengkap': acc['nama'],
          'companyOrAgency': acc['instansi'],
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
        });
      }
      debugPrint('[AuthService] Akun demo ter-seed (Auth + users).');
    } catch (e) {
      // Email/Password belum diaktifkan / offline → biarkan login lokal.
      debugPrint('[AuthService] Seed dilewati: $e');
    }
  }
}
