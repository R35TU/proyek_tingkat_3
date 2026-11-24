import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/services/auth_service.dart';
import 'package:tata_saka_app/utils/app_translations.dart';

class RegisteredUser {
  final String username;
  final String password;
  final String role; // 'Konsultan', 'Kontraktor', 'Dinas'
  final String namaLengkap;
  final String companyOrAgency;
  final String description;

  const RegisteredUser({
    required this.username,
    required this.password,
    required this.role,
    required this.namaLengkap,
    required this.companyOrAgency,
    this.description = '',
  });
}

class LoginActivityItem {
  final String id;
  final String deviceName;
  final String location;
  final String time;
  final bool isCurrent;
  final IconData icon;

  LoginActivityItem({
    required this.id,
    required this.deviceName,
    required this.location,
    required this.time,
    this.isCurrent = false,
    this.icon = Icons.smartphone,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'deviceName': deviceName,
    'location': location,
    'time': time,
    'isCurrent': isCurrent,
  };

  factory LoginActivityItem.fromJson(Map<String, dynamic> json) => LoginActivityItem(
    id: json['id'] ?? '',
    deviceName: json['deviceName'] ?? '',
    location: json['location'] ?? '',
    time: json['time'] ?? '',
    isCurrent: json['isCurrent'] ?? false,
    icon: (json['deviceName']?.toString().toLowerCase().contains('windows') == true ||
            json['deviceName']?.toString().toLowerCase().contains('mac') == true ||
            json['deviceName']?.toString().toLowerCase().contains('laptop') == true)
        ? Icons.computer
        : Icons.smartphone,
  );
}

class UserProfileProvider with ChangeNotifier {
  static const String _prefProfileKey = 'user_profile_data';
  static const String _prefSettingsKey = 'app_settings_data';

  // ─── MASTER AKUN TERDAFTAR RESMI ───
  // Akun didaftarkan dan dikelola melalui Firebase Auth & Firestore.
  static const List<RegisteredUser> registeredUsers = [];

  static List<String> get registeredContractors => registeredContractorNames;

  static List<String> get registeredContractorNames => [];

  static List<String> get registeredAgencyNames => [];

  // ─── 1. ACTIVE USER PROFILE & ROLE ───
  String _uid = '';
  String _namaLengkap = '';
  String _username = '';
  String _role = '';
  String _companyOrAgency = '';
  String? _profileImagePath;
  String _currentPassword = '';

  // ─── 2. APP PREFERENCES ───
  String _themeMode = 'Terang'; // 'Terang', 'Gelap', 'Mengikuti Sistem'
  String _language = 'Indonesia'; // 'Indonesia', 'English'

  // ─── 3. NOTIFIKASI ───
  bool _notifikasiPush = true;
  bool _emailNotifikasi = true;
  bool _notifikasiProyek = true;
  bool _notifikasiLaporan = true;

  // ─── 4. LAINNYA ───
  bool _reminderLaporanHarian = true;
  String _reminderTime = '17:00';
  String _lastBackupDate = '';
  String _cacheSize = '0 KB';

  // ─── 5. AKTIVITAS LOGIN ───
  final List<LoginActivityItem> _loginActivities = [];

  // Getters Profile & Roles
  String get uid => _uid.isNotEmpty ? _uid : (AuthService.currentUser?.uid ?? '');
  String get namaLengkap => _namaLengkap;
  String get username => _username;
  String get role => _role;
  String get companyOrAgency {
    if (isKonsultan) {
      return 'CV. Tata Saka Consultant';
    }
    return _companyOrAgency;
  }
  String? get profileImagePath => _profileImagePath;
  String get currentPassword => _currentPassword;

  bool get isKonsultan => _role.toLowerCase() == 'konsultan';
  bool get isKontraktor => _role.toLowerCase() == 'kontraktor';
  bool get isDinas => _role.toLowerCase() == 'dinas';

  // Getters Settings
  String get themeMode => _themeMode;
  String get language => _language;
  bool get isEnglish => _language == 'English';
  String tr(String key) => AppTranslations.translate(key, _language);

  bool get isDarkMode {
    if (_themeMode == 'Gelap') return true;
    if (_themeMode == 'Terang') return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
  }

  bool get notifikasiPush => _notifikasiPush;
  bool get emailNotifikasi => _emailNotifikasi;
  bool get notifikasiProyek => _notifikasiProyek;
  bool get notifikasiLaporan => _notifikasiLaporan;
  bool get reminderLaporanHarian => _reminderLaporanHarian;
  String get reminderTime => _reminderTime;
  String get lastBackupDate => _lastBackupDate;
  String get cacheSize => _cacheSize;
  List<LoginActivityItem> get loginActivities => List.unmodifiable(_loginActivities);

  ThemeMode get flutterThemeMode {
    if (_themeMode == 'Gelap') return ThemeMode.dark;
    if (_themeMode == 'Mengikuti Sistem') return ThemeMode.system;
    return ThemeMode.light;
  }

  UserProfileProvider() {
    _loadFromPreferences();
  }

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profileJson = prefs.getString(_prefProfileKey);
      if (profileJson != null) {
        final Map<String, dynamic> p = jsonDecode(profileJson);
        _uid = p['uid'] ?? AuthService.currentUser?.uid ?? _uid;
        _namaLengkap = p['namaLengkap'] ?? _namaLengkap;
        _username = p['username'] ?? _username;
        _role = p['role'] ?? _role;
        if (_role.toLowerCase() == 'konsultan') {
          _companyOrAgency = 'CV. Tata Saka Consultant';
        } else {
          _companyOrAgency = p['companyOrAgency'] ?? _companyOrAgency;
        }
        _profileImagePath = p['profileImagePath'];
        _currentPassword = p['currentPassword'] ?? _currentPassword;
      }

      final settingsJson = prefs.getString(_prefSettingsKey);
      if (settingsJson != null) {
        final Map<String, dynamic> s = jsonDecode(settingsJson);
        _themeMode = s['themeMode'] ?? _themeMode;
        _language = s['language'] ?? _language;
        _notifikasiPush = s['notifikasiPush'] ?? _notifikasiPush;
        _emailNotifikasi = s['emailNotifikasi'] ?? _emailNotifikasi;
        _notifikasiProyek = s['notifikasiProyek'] ?? _notifikasiProyek;
        _notifikasiLaporan = s['notifikasiLaporan'] ?? _notifikasiLaporan;
        _reminderLaporanHarian = s['reminderLaporanHarian'] ?? _reminderLaporanHarian;
        _reminderTime = s['reminderTime'] ?? _reminderTime;
        _lastBackupDate = s['lastBackupDate'] ?? _lastBackupDate;
        _cacheSize = s['cacheSize'] ?? _cacheSize;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _saveToPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final profileMap = {
        'uid': _uid,
        'namaLengkap': _namaLengkap,
        'username': _username,
        'role': _role,
        'companyOrAgency': _companyOrAgency,
        'profileImagePath': _profileImagePath,
        'currentPassword': _currentPassword,
      };
      await prefs.setString(_prefProfileKey, jsonEncode(profileMap));

      final settingsMap = {
        'themeMode': _themeMode,
        'language': _language,
        'notifikasiPush': _notifikasiPush,
        'emailNotifikasi': _emailNotifikasi,
        'notifikasiProyek': _notifikasiProyek,
        'notifikasiLaporan': _notifikasiLaporan,
        'reminderLaporanHarian': _reminderLaporanHarian,
        'reminderTime': _reminderTime,
        'lastBackupDate': _lastBackupDate,
        'cacheSize': _cacheSize,
      };
      await prefs.setString(_prefSettingsKey, jsonEncode(settingsMap));
    } catch (_) {}
  }

  // ─── AUTH & LOGIN ACTIONS ───
  /// Login via Firebase Auth (menerima EMAIL atau USERNAME) + profil
  /// Firestore.
  Future<bool> login(String input, String passwordInput,
      {String? roleHint}) async {
    final cleanInput = input.trim().toLowerCase();
    final cleanPassword = passwordInput.trim();
    if (cleanPassword.isEmpty) return false;

    // ── 1. Coba Firebase Auth ──
    try {
      final cred = await AuthService.signIn(cleanInput, cleanPassword);
      final uid = cred.user!.uid;
      final doc = await AuthService.fetchUserDoc(uid);
      if (doc != null && doc['isActive'] == false) {
        // Akun dinonaktifkan admin → tolak.
        await AuthService.signOut();
        return false;
      }
      _uid = uid;
      final fallbackUsername = cleanInput.contains('@') ? cleanInput.split('@').first : cleanInput;
      _username = (doc?['username'] ?? fallbackUsername).toString();
      _role = (doc?['role'] ?? roleHint ?? 'Konsultan').toString();
      _namaLengkap = (doc?['namaLengkap'] ?? fallbackUsername).toString();
      if (_role.toLowerCase() == 'konsultan') {
        _companyOrAgency = 'CV. Tata Saka Consultant';
      } else {
        _companyOrAgency = (doc?['companyOrAgency'] ?? '').toString();
      }
      _currentPassword = cleanPassword;
      _profileImagePath = null;
      notifyListeners();
      _saveToPreferences();
      return true;
    } catch (_) {
      // Firebase tidak tersedia / kredensial salah → lanjut fallback lokal.
    }

    // ── 2. Fallback lokal (mode offline / dev) ──
    return _loginLocal(cleanInput, cleanPassword, roleHint: roleHint);
  }

  /// Jalur login lokal dinonaktifkan — autentikasi sepenuhnya melalui Firebase Auth.
  bool _loginLocal(String cleanEmail, String cleanPassword,
      {String? roleHint}) {
    return false;
  }

  void loginAs(RegisteredUser user) {
    _username = user.username;
    _role = user.role;
    _namaLengkap = user.namaLengkap;
    _companyOrAgency = user.role.toLowerCase() == 'konsultan'
        ? 'CV. Tata Saka Consultant'
        : user.companyOrAgency;
    _currentPassword = user.password;
    _profileImagePath = null;

    notifyListeners();
    _saveToPreferences();
  }

  // ─── ACTIONS: PROFIL ───
  void updateNamaLengkap(String newName) {
    if (newName.trim().isNotEmpty) {
      _namaLengkap = newName.trim();
      notifyListeners();
      _saveToPreferences();
    }
  }

  void updateProfileImage(String? newPath) {
    _profileImagePath = newPath;
    notifyListeners();
    _saveToPreferences();
  }

  // ─── ACTIONS: PENGATURAN ───
  void updateTheme(String theme) {
    _themeMode = theme;
    notifyListeners();
    _saveToPreferences();
  }

  void setThemeMode(String theme) => updateTheme(theme);

  void updateLanguage(String lang) {
    _language = lang;
    notifyListeners();
    _saveToPreferences();
  }

  void setLanguage(String lang) => updateLanguage(lang);

  void setNotifikasiPush(bool val) {
    _notifikasiPush = val;
    notifyListeners();
    _saveToPreferences();
  }

  void setEmailNotifikasi(bool val) {
    _emailNotifikasi = val;
    notifyListeners();
    _saveToPreferences();
  }

  void setNotifikasiProyek(bool val) {
    _notifikasiProyek = val;
    notifyListeners();
    _saveToPreferences();
  }

  void setNotifikasiLaporan(bool val) {
    _notifikasiLaporan = val;
    notifyListeners();
    _saveToPreferences();
  }

  void setReminderLaporanHarian(bool enabled, {String? time}) {
    _reminderLaporanHarian = enabled;
    if (time != null) _reminderTime = time;
    notifyListeners();
    _saveToPreferences();
  }

  void clearCache() {
    _cacheSize = '0 KB';
    notifyListeners();
    _saveToPreferences();
  }

  // ─── ACTIONS: KEAMANAN ───
  bool verifyCurrentPassword(String input) {
    return input.trim() == _currentPassword;
  }

  /// Ganti password: lewat Firebase Auth bila sesi aktif,
  /// fallback ke penyimpanan lokal bila offline.
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (!verifyCurrentPassword(oldPassword)) {
      return false;
    }
    try {
      await AuthService.changePassword(oldPassword, newPassword);
    } catch (_) {
      // Offline / sesi Auth tidak ada → cukup simpan lokal.
    }
    _currentPassword = newPassword;
    notifyListeners();
    _saveToPreferences();
    return true;
  }

  /// Logout: keluar dari Firebase Auth + bersihkan profil lokal.
  Future<void> logout() async {
    try {
      await AuthService.signOut();
    } catch (_) {}
    _uid = '';
    _username = '';
    _role = '';
    _namaLengkap = '';
    _companyOrAgency = '';
    _profileImagePath = null;
    _currentPassword = '';
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefProfileKey);
    } catch (_) {}
  }

  void logoutFromAllOtherDevices() {
    _loginActivities.removeWhere((item) => !item.isCurrent);
    notifyListeners();
  }

  void removeLoginActivity(String id) {
    _loginActivities.removeWhere((item) => item.id == id);
    notifyListeners();
  }
}
