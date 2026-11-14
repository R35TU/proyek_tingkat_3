import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  static const List<RegisteredUser> registeredUsers = [
    RegisteredUser(
      username: 'konsultan',
      password: 'password123',
      role: 'Konsultan',
      namaLengkap: 'CV. Tata Saka Consultant',
      companyOrAgency: 'CV. Tata Saka Consultant',
      description: 'Konsultan Pengawas (Akses Penuh)',
    ),
    RegisteredUser(
      username: 'kontraktor1',
      password: 'password123',
      role: 'Kontraktor',
      namaLengkap: 'CV. Divan Insan Cemerlang',
      companyOrAgency: 'CV. Divan Insan Cemerlang',
      description: 'Kontraktor 1 (Ruas MT Haryono)',
    ),
    RegisteredUser(
      username: 'kontraktor2',
      password: 'password123',
      role: 'Kontraktor',
      namaLengkap: 'CV. Langgeng',
      companyOrAgency: 'CV. Langgeng',
      description: 'Kontraktor 2 (Ruas Kapten Piere Tendean)',
    ),
    RegisteredUser(
      username: 'dinas',
      password: 'password123',
      role: 'Dinas',
      namaLengkap: 'DPU-PR Kabupaten Purbalingga',
      companyOrAgency: 'DPU-PR',
      description: 'Dinas PU-PR (Pengawas Pemilik / Read-Only)',
    ),
  ];

  static List<String> get registeredContractors => registeredContractorNames;

  static List<String> get registeredContractorNames => [
    'CV. Divan Insan Cemerlang',
    'CV. Langgeng',
  ];

  static List<String> get registeredAgencyNames => [
    'DPU-PR Kabupaten Purbalingga',
    'DPU-PR',
  ];

  // ─── 1. ACTIVE USER PROFILE & ROLE ───
  String _namaLengkap = 'CV. Tata Saka Consultant';
  String _username = 'konsultan';
  String _role = 'Konsultan';
  String _companyOrAgency = 'CV. Tata Saka Consultant';
  String? _profileImagePath;
  String _currentPassword = 'password123';

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
  String _lastBackupDate = '31 Des 2025 10:30';
  String _cacheSize = '12.4 MB';

  // ─── 5. AKTIVITAS LOGIN ───
  final List<LoginActivityItem> _loginActivities = [
    LoginActivityItem(
      id: 'act-1',
      deviceName: 'iPhone 11',
      location: 'Jakarta, Indonesia',
      time: '01 Januari 2025 10:30 WIB',
      isCurrent: true,
      icon: Icons.smartphone,
    ),
    LoginActivityItem(
      id: 'act-2',
      deviceName: 'Windows - Brave',
      location: 'Semarang, Indonesia',
      time: '25 November 2024 17:23 WIB',
      isCurrent: false,
      icon: Icons.computer,
    ),
    LoginActivityItem(
      id: 'act-3',
      deviceName: 'Android - Chrome',
      location: 'Purbalingga, Indonesia',
      time: '15 Oktober 2024 14:10 WIB',
      isCurrent: false,
      icon: Icons.smartphone,
    ),
  ];

  // Getters Profile & Roles
  String get namaLengkap => _namaLengkap;
  String get username => _username;
  String get role => _role;
  String get companyOrAgency => _companyOrAgency;
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
        _namaLengkap = p['namaLengkap'] ?? _namaLengkap;
        _username = p['username'] ?? _username;
        _role = p['role'] ?? _role;
        _companyOrAgency = p['companyOrAgency'] ?? _companyOrAgency;
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
  bool login(String usernameInput, String passwordInput, {String? roleHint}) {
    final cleanUsername = usernameInput.trim().toLowerCase();
    final cleanPassword = passwordInput.trim();

    // Cari dari daftar akun terdaftar
    final found = registeredUsers.firstWhere(
      (u) =>
          u.username.toLowerCase() == cleanUsername ||
          (cleanUsername.isEmpty && roleHint != null && u.role.toLowerCase() == roleHint.toLowerCase()),
      orElse: () => RegisteredUser(
        username: cleanUsername.isNotEmpty ? cleanUsername : (roleHint?.toLowerCase() ?? 'konsultan'),
        password: cleanPassword.isNotEmpty ? cleanPassword : 'password123',
        role: roleHint ?? 'Konsultan',
        namaLengkap: cleanUsername.isNotEmpty ? usernameInput : 'Pengguna',
        companyOrAgency: cleanUsername.isNotEmpty ? usernameInput : 'Tata Saka',
      ),
    );

    // Cek password sederhana
    if (cleanPassword.isNotEmpty && cleanPassword != found.password && cleanPassword != 'password123') {
      return false;
    }

    _username = found.username;
    _role = found.role;
    _namaLengkap = found.namaLengkap;
    _companyOrAgency = found.companyOrAgency;
    _currentPassword = found.password;
    _profileImagePath = null;

    notifyListeners();
    _saveToPreferences();
    return true;
  }

  void loginAs(RegisteredUser user) {
    _username = user.username;
    _role = user.role;
    _namaLengkap = user.namaLengkap;
    _companyOrAgency = user.companyOrAgency;
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

  bool changePassword(String oldPassword, String newPassword) {
    if (!verifyCurrentPassword(oldPassword)) {
      return false;
    }
    _currentPassword = newPassword;
    notifyListeners();
    _saveToPreferences();
    return true;
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
