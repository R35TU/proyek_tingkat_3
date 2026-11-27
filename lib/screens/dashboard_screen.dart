import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/services/auth_service.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/kontrak_screen.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/laporan_screen.dart';
import 'package:tata_saka_app/screens/login_screen.dart';

import 'laporan_mingguan_screen.dart';

import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/screens/timeline_screen.dart';
import 'package:tata_saka_app/screens/pengaturan_screen.dart';
import 'package:tata_saka_app/screens/setting_screen.dart';
import 'package:tata_saka_app/screens/keamanan_screen.dart';
import 'package:tata_saka_app/screens/edit_profil_screen.dart';
import 'package:tata_saka_app/screens/panduan_faq_screen.dart';
import 'package:tata_saka_app/screens/kelola_addendum_screen.dart';
import 'package:intl/intl.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/timeline_event_model.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';
import 'package:tata_saka_app/utils/contract_access.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';
import 'package:tata_saka_app/utils/web_navigation.dart';

class DashboardScreen extends StatefulWidget {
  final String? initialMenu;
  const DashboardScreen({super.key, this.initialMenu});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _currentPage = 0;
  String _activeWebMenu = 'dashboard';
  final List<String> _webMenuHistory = ['dashboard'];

  static String? _normalizeMenuFromUrl(String route) {
    final clean = route.replaceAll('#', '').trim();
    final uri = Uri.tryParse(clean);
    if (uri == null) return null;
    final path = uri.path.replaceAll('/', '').trim();
    if (path.isEmpty || path == 'main' || path == 'dashboard')
      return 'dashboard';
    const validMenus = {
      'kontrak',
      'kegiatan',
      'laporan',
      'buat_laporan',
      'buat-laporan',
      'data_laporan',
      'data-laporan',
      'laporan_harian',
      'laporan-harian',
      'laporan_mingguan',
      'laporan-mingguan',
      'laporan_bulanan',
      'laporan-bulanan',
      'timeline',
      'akun',
      'pengaturan',
      'keamanan',
      'edit_profil',
      'edit-profil',
      'panduan_faq',
      'panduan-faq',
    };
    if (validMenus.contains(path)) {
      final norm = path.replaceAll('-', '_');
      return norm == 'data_laporan' ? 'laporan_harian' : norm;
    }
    final qMenu = uri.queryParameters['menu'];
    if (qMenu != null && validMenus.contains(qMenu)) {
      final norm = qMenu.replaceAll('-', '_');
      return norm == 'data_laporan' ? 'laporan_harian' : norm;
    }
    return null;
  }

  void _onWebMenuSelected(String menuKey) {
    if (GoRouter.maybeOf(context) != null) {
      goTopLevelRoute(context, WebDashboardLayout.routeForMenu(menuKey));
      return;
    }
    if (_activeWebMenu == menuKey) return;
    setState(() {
      if (_webMenuHistory.isEmpty || _webMenuHistory.last != menuKey) {
        _webMenuHistory.add(menuKey);
      }
      _activeWebMenu = menuKey;
    });
  }

  void _onWebBack() {
    if (GoRouter.maybeOf(context) != null) {
      goBackWithShellHistory(context, fallback: '/dashboard');
      return;
    }
    setState(() {
      if (_webMenuHistory.length > 1) {
        _webMenuHistory.removeLast();
        _activeWebMenu = _webMenuHistory.last;
      } else {
        _activeWebMenu = 'dashboard';
        _webMenuHistory
          ..clear()
          ..add('dashboard');
      }
    });
  }

  Widget? _destinationForMenu(String menuKey, UserProfileProvider userProf) {
    switch (menuKey) {
      case 'kontrak':
      case 'kegiatan':
        return const KontrakScreen();
      case 'laporan':
        return const LaporanScreen();
      case 'buat_laporan':
        return const BuatLaporanScreen();
      case 'data_laporan':
      case 'laporan_harian':
        return const DataLaporanScreen();
      case 'laporan_mingguan':
        return const LaporanMingguanScreen();
      case 'laporan_bulanan':
        return const LaporanBulananScreen();
      case 'timeline':
        return const TimelineScreen();
      case 'akun':
        return const SettingScreen();
      case 'pengaturan':
        return const PengaturanScreen();
      case 'keamanan':
        return const KeamananScreen();
      case 'edit_profil':
        return const EditProfilScreen();
      case 'panduan_faq':
        // Panduan hanya sesuai peran login; Dinas belum punya
        // guidebook → null → tampilan 3 tab default (tetap).
        return PanduanFaqScreen(
          role: userProf.isKontraktor
              ? 'kontraktor'
              : (userProf.isKonsultan ? 'konsultan' : null),
        );
      case 'dashboard':
      default:
        return null;
    }
  }

  void _navigateFromSidebar(
    String menuKey,
    Widget? destination, {
    bool isDrawer = false,
  }) {
    if (isDrawer) Navigator.pop(context);
    if (GoRouter.maybeOf(context) != null) {
      goTopLevelRoute(context, WebDashboardLayout.routeForMenu(menuKey));
      return;
    }
    if (menuKey == 'dashboard' || ResponsiveBreakpoints.isDesktop(context)) {
      setState(() {
        if (_webMenuHistory.isEmpty || _webMenuHistory.last != menuKey) {
          _webMenuHistory.add(menuKey);
        }
        _activeWebMenu = menuKey;
      });
    } else if (destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      );
    }
  }

  String _getHeaderTitle(UserProfileProvider userProf) {
    switch (_activeWebMenu) {
      case 'kontrak':
        return userProf.tr('nav_kontrak');
      case 'kegiatan':
        return userProf.tr('nav_kegiatan_saya');
      case 'rab':
      case 'rab_boq':
        return 'RAB / BoQ (Rencana Kerja)';
      case 'addendum':
      case 'addendum_cco':
        return 'Addendum CCO & Tambah Kurang';
      case 'laporan':
        return 'Laporan Proyek';
      case 'buat_laporan':
        return 'Buat Laporan Harian';
      case 'data_laporan':
      case 'laporan_harian':
        return 'Laporan Harian';
      case 'laporan_mingguan':
        return 'Laporan Mingguan Proyek';
      case 'laporan_bulanan':
        return 'Laporan Bulanan Supervisi';
      case 'timeline':
        return 'Timeline & Histori Proyek';
      case 'akun':
        return userProf.tr('nav_account');
      case 'pengaturan':
        return 'Pengaturan Akun';
      case 'keamanan':
        return 'Keamanan & Sandi';
      case 'edit_profil':
        return 'Edit Profil Pengguna';
      case 'panduan_faq':
        return 'Panduan & FAQ';
      case 'dashboard':
      default:
        return userProf.isKontraktor
            ? 'Dashboard Kontraktor'
            : userProf.tr('nav_dashboard');
    }
  }

  Widget _buildActiveWebContent(
    BuildContext context,
    UserProfileProvider userProf,
    List<ContractModel> contracts,
    Widget defaultDashboardBody,
  ) {
    switch (_activeWebMenu) {
      case 'kontrak':
      case 'kegiatan':
        return const KontrakScreen(isEmbedded: true);
      case 'rab':
      case 'rab_boq':
        if (contracts.isNotEmpty) {
          return DetailKontrakScreen(
            contract: contracts.first,
            isEmbedded: true,
          );
        }
        return const KontrakScreen(isEmbedded: true);
      case 'addendum':
      case 'addendum_cco':
        if (contracts.isNotEmpty && contracts.first.kegiatans.isNotEmpty) {
          return KelolaAddendumScreen(
            contract: contracts.first,
            kegiatanIndex: 0,
            isEmbedded: true,
          );
        }
        return const KontrakScreen(isEmbedded: true);
      case 'laporan':
        return const LaporanScreen(isEmbedded: true);
      case 'buat_laporan':
        return const BuatLaporanScreen(isEmbedded: true);
      case 'data_laporan':
      case 'laporan_harian':
        return const DataLaporanScreen(isEmbedded: true);
      case 'laporan_mingguan':
        return const LaporanMingguanScreen(isEmbedded: true);
      case 'laporan_bulanan':
        return const LaporanBulananScreen(isEmbedded: true);
      case 'timeline':
        return const TimelineScreen(isEmbedded: true);
      case 'akun':
        return const SettingScreen(isEmbedded: true);
      case 'pengaturan':
        return const PengaturanScreen(isEmbedded: true);
      case 'keamanan':
        return const KeamananScreen(isEmbedded: true);
      case 'edit_profil':
        return const EditProfilScreen(isEmbedded: true);
      case 'panduan_faq':
        return PanduanFaqScreen(
          role: userProf.isKontraktor
              ? 'kontraktor'
              : (userProf.role.toLowerCase() == 'konsultan'
                    ? 'konsultan'
                    : null),
        );
      case 'dashboard':
      default:
        return defaultDashboardBody;
    }
  }

  void _handleLogout(BuildContext context, {bool isDrawer = false}) {
    if (isDrawer) Navigator.pop(context);
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text(
          'Konfirmasi Keluar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun ini?',
          style: TextStyle(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                final userProf = context.read<UserProfileProvider>();
                await userProf.logout();
              } catch (_) {}
              if (!context.mounted) return;
              final router = GoRouter.maybeOf(context);
              if (router != null) {
                Router.neglect(context, () => router.go('/login'));
              } else {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _startTimer();
    final hasRouter = GoRouter.maybeOf(context) != null;
    final startMenu =
        widget.initialMenu ??
        (kIsWeb && hasRouter ? _normalizeMenuFromUrl(getInitialWebRoute()) : null) ??
        'dashboard';
    _activeWebMenu = startMenu;
    _webMenuHistory.clear();
    _webMenuHistory.add(startMenu);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final contracts = context.read<ContractProvider>().contracts;
        context.read<TimelineProvider>().syncWithContracts(contracts);
      } catch (_) {}
    });
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialMenu != null &&
        widget.initialMenu != oldWidget.initialMenu) {
      final newMenu = _normalizeMenuFromUrl(widget.initialMenu!) ?? 'dashboard';
      if (_activeWebMenu != newMenu) {
        _activeWebMenu = newMenu;
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_pageController.hasClients) {
        final contractCount = Provider.of<ContractProvider>(
          context,
          listen: false,
        ).contracts.length;
        if (contractCount > 1) {
          int nextPage = _currentPage + 1;
          if (nextPage >= contractCount) {
            nextPage = 0;
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.fastOutSlowIn,
            );
          } else {
            _pageController.animateToPage(
              nextPage,
              duration: const Duration(milliseconds: 800),
              curve: Curves.fastOutSlowIn,
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final safeUserProf = userProf ?? UserProfileProvider();
    final provider = Provider.of<ContractProvider>(context);
    final allContracts = provider.contracts;
    TimelineProvider? timelineProv;
    try {
      timelineProv = Provider.of<TimelineProvider>(context);
    } catch (_) {
      timelineProv = null;
    }

    // ─── ROLE KONTRAKTOR: TAMPILAN KHUSUS KEGIATAN TANPA DATA KONTRAK LAIN ───
    if (safeUserProf.isKontraktor) {
      return _buildContractorDashboard(
        context,
        safeUserProf,
        allContracts,
        timelineProv,
      );
    }

    // Filter Kontrak untuk Dinas: hanya kontrak terkait dinas tersebut
    final List<ContractModel> contracts;
    if (safeUserProf.isDinas) {
      contracts = allContracts.where((c) {
        return c.isOwnedByDinas(
          dinasUserUid: safeUserProf.uid,
          companyOrAgency: safeUserProf.companyOrAgency,
          userFullName: safeUserProf.namaLengkap,
        );
      }).toList();
    } else {
      contracts = allContracts;
    }

    final int totalKontrak = contracts.length;
    final int kontrakAktif = contracts
        .where((c) => c.status != 'Selesai')
        .length;
    final int kontrakSelesai = contracts
        .where((c) => c.status == 'Selesai')
        .length;

    final bool isWeb = ResponsiveBreakpoints.isDesktop(context);

    final Widget mainBody = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section with Dynamic Branding
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      safeUserProf.tr('dash_welcome'),
                      style: TextStyle(
                        color: AppColors.getTextLight(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      safeUserProf.namaLengkap,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.getTextDark(context),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      safeUserProf.isDinas
                          ? safeUserProf.tr('dash_subtitle_dinas')
                          : safeUserProf.tr('dash_subtitle_konsultan'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.getTextLight(context),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.getCardBackground(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.getBorder(context),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/logoRev.png',
                  fit: BoxFit.contain,
                  cacheWidth: 160,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.business,
                    color: AppColors.getTextDark(context),
                    size: 26,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3 Grid Stats (Corporate Slate harmonized)
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  safeUserProf.tr('dash_total_kontrak'),
                  totalKontrak.toString(),
                  Icons.folder_outlined,
                  AppColors.slateLighter,
                  AppColors.navySlate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  safeUserProf.tr('dash_kontrak_aktif'),
                  kontrakAktif.toString(),
                  Icons.trending_up,
                  const Color(0xFFE6F4EA),
                  AppColors.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  safeUserProf.tr('dash_kontrak_selesai'),
                  kontrakSelesai.toString(),
                  Icons.check_circle_outline,
                  AppColors.slateLighter,
                  AppColors.slate,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Carousel Section
          if (contracts.isNotEmpty) ...[
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: contracts.length,
                itemBuilder: (context, index) {
                  final contract = contracts[index];
                  return _buildCarouselCard(contract);
                },
              ),
            ),
            const SizedBox(height: 16),
            // Carousel Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                contracts.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AppColors.navySlate
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: AppColors.textLight),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada kontrak',
                    style: TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),
          _buildRecentActivitiesSection(
            context,
            safeUserProf,
            timelineProv,
            contracts,
          ),
        ],
      ),
    );

    if (isWeb) {
      if (WebShellScope.isInside(context)) {
        return mainBody;
      }
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          if (_activeWebMenu != 'dashboard') {
            _onWebBack();
          }
        },
        child: WebDashboardLayout(
          title: _activeWebMenu != 'dashboard'
              ? _getHeaderTitle(safeUserProf)
              : safeUserProf.tr('nav_dashboard'),
          activeMenu: _activeWebMenu,
          showBackButton: _activeWebMenu != 'dashboard',
          onBack: _onWebBack,
          onMenuSelected: _onWebMenuSelected,
          child: _buildActiveWebContent(
            context,
            safeUserProf,
            contracts,
            mainBody,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getCardBackground(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.getBorder(context)),
        ),
        leading: Builder(
          builder: (scaffoldCtx) => IconButton(
            icon: Icon(Icons.menu, color: AppColors.getTextDark(context)),
            tooltip: 'Buka Menu',
            onPressed: () {
              Scaffold.of(scaffoldCtx).openDrawer();
            },
          ),
        ),
        title: Text(
          safeUserProf.tr('nav_dashboard'),
          style: TextStyle(
            color: AppColors.getTextDark(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      drawer: _buildWebSidebar(context, userProf: safeUserProf, isDrawer: true),
      body: mainBody,
    );
  }

  /// Label waktu relatif yang benar: Hari ini / Kemarin / tanggal lengkap.
  static String _relativeTimeLabel(String? tglStr, String? jam) {
    final tgl = DateTime.tryParse(tglStr ?? '');
    if (tgl == null) return (jam != null && jam.isNotEmpty) ? jam : '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(tgl.year, tgl.month, tgl.day);
    if (day == today) {
      return (jam != null && jam.isNotEmpty) ? 'Hari ini • $jam' : 'Hari ini';
    }
    if (day == today.subtract(const Duration(days: 1))) {
      return (jam != null && jam.isNotEmpty) ? 'Kemarin • $jam' : 'Kemarin';
    }
    return tglStr ?? '';
  }

  List<Map<String, String>> _extractRecentActivities(
    List<ContractModel> contracts, {
    UserProfileProvider? userProfile,
  }) {
    final List<Map<String, dynamic>> list = [];
    // Jalur cadangan ini dipakai saat timeline kosong; tetap harus mengikuti
    // aturan akses supaya proyek yang tidak ditugaskan tidak bocor.
    final visibleContracts = userProfile == null
        ? contracts
        : ContractAccess.visibleContracts(contracts, userProfile);
    for (final c in visibleContracts) {
      for (final keg in c.kegiatans) {
        if (userProfile != null &&
            userProfile.isKontraktor &&
            !ContractAccess.kegiatanOwnedByKontraktor(
              keg,
              contractorUid: userProfile.uid,
              fullName: userProfile.namaLengkap,
              companyOrAgency: userProfile.companyOrAgency,
              username: userProfile.username,
            )) {
          continue;
        }
        final laporans = keg['laporans'] as List? ?? [];
        for (final rep in laporans) {
          if (rep is Map) {
            final tglStr = rep['tanggal']?.toString() ?? '';
            list.add({
              'title': 'Laporan Harian Ditambahkan',
              'desc':
                  '${rep['tanggalFormatted'] ?? rep['tanggal'] ?? 'Laporan'} - ${keg['namaKegiatan'] ?? c.namaKontrak}',
              'time': _relativeTimeLabel(tglStr, rep['jam']?.toString()),
              'sortTs': DateTime.tryParse(tglStr)?.millisecondsSinceEpoch ?? 0,
            });
          }
        }
        final mingguan = keg['laporanMingguan'] as List? ?? [];
        for (final m in mingguan) {
          if (m is Map) {
            final periode = m['periodeAkhir']?.toString() ?? '';
            final periodeTs =
                DateTime.tryParse(periode)?.millisecondsSinceEpoch ??
                (DateTime.tryParse(m['docCreateTime']?.toString() ?? '')
                        ?.millisecondsSinceEpoch ??
                    0);
            list.add({
              'title': 'Laporan Mingguan Dibuat',
              'desc':
                  'Minggu ke-${m['mingguKe']} - ${keg['namaKegiatan'] ?? c.namaKontrak}',
              'time': periode.isNotEmpty ? periode : 'Minggu ini',
              'sortTs': periodeTs,
            });
          }
        }
        final folders = keg['folders'] as List? ?? [];
        for (final f in folders) {
          if (f is Map) {
            final docs = f['documents'] as List? ?? [];
            for (final d in docs) {
              if (d is Map) {
                final upTs =
                    DateTime.tryParse(d['uploadDate']?.toString() ?? '')
                        ?.millisecondsSinceEpoch ??
                    (d['sortTs'] as num?)?.toInt() ??
                    0;
                list.add({
                  'title': 'Dokumen Diunggah',
                  'desc': 'File "${d['name']}" pada ${f['name']}',
                  'time': (d['uploadDate'] ?? '-').toString(),
                  'sortTs': upTs,
                });
              }
            }
          }
        }
      }
    }
    // Urutkan: terbaru di atas (konsisten dengan Timeline & Histori).
    list.sort(
      (a, b) =>
          ((b['sortTs'] as num?) ?? 0).compareTo((a['sortTs'] as num?) ?? 0),
    );
    return list
        .map(
          (e) => {
            'title': e['title']?.toString() ?? '',
            'desc': e['desc']?.toString() ?? '',
            'time': e['time']?.toString() ?? '',
          },
        )
        .toList();
  }

  Widget _buildCarouselCard(ContractModel contract) {
    int totalKegiatan = contract.kegiatans.length;

    bool isPengawasan = contract.jenisKegiatan.toLowerCase().contains(
      'pengawasan',
    );

    // Harmonized badge color in Corporate Slate
    Color badgeBgColor = isPengawasan
        ? AppColors.slateLighter
        : const Color(0xFFFEF3C7);
    Color badgeTextColor = isPengawasan
        ? AppColors.navySlate
        : const Color(0xFFB45309);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  contract.namaKontrak,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.navySlate,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeBgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.8),
                ),
                child: Text(
                  contract.jenisKegiatan,
                  style: TextStyle(
                    color: badgeTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              // Circular Progress
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 75,
                    width: 75,
                    child: CircularProgressIndicator(
                      value: contract.progressFisik,
                      strokeWidth: 8,
                      backgroundColor: AppColors.slateLighter,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.navySlate,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${contract.progressPercent.toStringAsFixed(contract.progressPercent % 1 == 0 ? 0 : 1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.navySlate,
                        ),
                      ),
                      const Text(
                        'Progres',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: AppColors.navySlate,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Kegiatan',
                          style: TextStyle(
                            color: AppColors.slate,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: Text(
                        totalKegiatan.toString(),
                        style: const TextStyle(
                          color: AppColors.navySlate,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: AppColors.getTextLight(context),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppColors.getTextDark(context),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimelineEventTime(TimelineEventModel event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      event.timestamp.year,
      event.timestamp.month,
      event.timestamp.day,
    );
    final timeStr = DateFormat('HH:mm').format(event.timestamp);

    if (eventDay == today) {
      return 'Hari ini • $timeStr WIB';
    } else if (eventDay == today.subtract(const Duration(days: 1))) {
      return 'Kemarin • $timeStr WIB';
    } else {
      return '${event.formattedDate} • $timeStr WIB';
    }
  }

  Widget _buildActivityCardFromEvent(
    BuildContext context,
    TimelineEventModel event,
  ) {
    final timeLabel = _formatTimelineEventTime(event);
    final actorLabel = event.actorName.isNotEmpty
        ? (event.actorRole.isNotEmpty
              ? 'Oleh: ${event.actorName} (${event.actorRole})'
              : 'Oleh: ${event.actorName}')
        : 'Oleh: CV. Tata Saka (Konsultan)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: event.actionColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(event.icon, color: event.actionColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeLabel,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  actorLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection(
    BuildContext context,
    UserProfileProvider userProf,
    TimelineProvider? timelineProv,
    List<ContractModel> contracts,
  ) {
    final timelineEvents = timelineProv != null
        ? timelineProv.getFilteredEvents(userProfile: userProf)
        : <TimelineEventModel>[];

    // Samakan urutan dengan Timeline & Histori: event yang tanggalnya masih
    // di depan (mis. laporan bertanggal besok) tidak boleh menimpa aktivitas
    // hari ini di posisi teratas. Di timeline event tersebut jatuh ke grup
    // bulannya, di bawah "HARI INI".
    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
    final recentEvents = List<TimelineEventModel>.from(timelineEvents)
      ..sort((a, b) {
        final aFuture = a.timestamp.isAfter(endOfToday);
        final bFuture = b.timestamp.isAfter(endOfToday);
        if (aFuture != bFuture) return aFuture ? 1 : -1;
        return b.timestamp.compareTo(a.timestamp);
      });

    final hasTimelineEvents = recentEvents.isNotEmpty;
    final fallbackActivities = !hasTimelineEvents
        ? _extractRecentActivities(contracts, userProfile: userProf)
        : <Map<String, String>>[];

    final hasActivities = hasTimelineEvents || fallbackActivities.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Aktivitas Terkini',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.textDark,
                ),
              ),
            ),
            if (hasActivities)
              InkWell(
                onTap: () {
                  if (GoRouter.maybeOf(context) != null) {
                    goTopLevelRoute(context, '/timeline');
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TimelineScreen()),
                    );
                  }
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (hasTimelineEvents)
          Column(
            children: recentEvents
                .take(5)
                .map(
                  (ev) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActivityCardFromEvent(context, ev),
                  ),
                )
                .toList(),
          )
        else if (fallbackActivities.isNotEmpty)
          Column(
            children: fallbackActivities
                .take(5)
                .map(
                  (act) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActivityItem(
                      act['title']!,
                      act['desc']!,
                      act['time']!,
                    ),
                  ),
                )
                .toList(),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 40,
                  color: AppColors.slate,
                ),
                SizedBox(height: 10),
                Text(
                  'Belum Ada Aktivitas Terkini',
                  style: TextStyle(
                    color: AppColors.navySlate,
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Aktivitas pembuatan laporan dan dokumen akan tercatat di sini secara otomatis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.slate, fontSize: 11.5),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActivityItem(String title, String desc, String time) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.slateLighter,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.folder, color: AppColors.navySlate),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Oleh: CV. Tata Saka (Konsultan)',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // DASHBOARD EKSKLUSIF KONTRAKTOR: HANYA MENAMPILKAN KEGIATAN MEREKA SENDIRI
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildContractorDashboard(
    BuildContext context,
    UserProfileProvider userProf,
    List<ContractModel> contracts, [
    TimelineProvider? timelineProv,
  ]) {
    final currentUserUid = AuthService.currentUser?.uid ?? '';
    final List<Map<String, dynamic>> myKegiatans = [];
    final List<int> kegIndices = [];
    final List<ContractModel> parentContracts = [];

    for (final c in contracts) {
      for (int i = 0; i < c.kegiatans.length; i++) {
        final k = c.kegiatans[i];
        if (!ContractAccess.kegiatanOwnedByKontraktor(
          k,
          contractorUid: currentUserUid,
          fullName: userProf.namaLengkap,
          companyOrAgency: userProf.companyOrAgency,
          username: userProf.username,
        )) {
          continue;
        }
        myKegiatans.add(k);
        kegIndices.add(i);
        parentContracts.add(c);
      }
    }

    double sumProgress = 0.0;
    for (int i = 0; i < myKegiatans.length; i++) {
      sumProgress += _calcKegiatanProgress(
        myKegiatans[i],
        contract: parentContracts[i],
      );
    }
    final double avgProgress = myKegiatans.isNotEmpty
        ? (sumProgress / myKegiatans.length)
        : 0.0;

    final bool isWeb = ResponsiveBreakpoints.isDesktop(context);

    final Widget contractorBody = SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selamat Datang,',
                        style: TextStyle(
                          color: AppColors.slate,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        userProf.namaLengkap,
                        style: const TextStyle(
                          color: AppColors.navySlate,
                          fontSize: 18.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: const Text(
                          'Penyedia Jasa / Kontraktor Pelaksana',
                          style: TextStyle(
                            color: Color(0xFF1D4ED8),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(
                    Icons.engineering_outlined,
                    color: Color(0xFF2563EB),
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3 Stat Cards Khusus Kegiatan
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Kegiatan Saya',
                  myKegiatans.length.toString(),
                  Icons.assignment_outlined,
                  AppColors.slateLighter,
                  AppColors.navySlate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Rata-rata Progres',
                  '${avgProgress.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  const Color(0xFFE6F4EA),
                  AppColors.successGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Status',
                  'Aktif',
                  Icons.check_circle_outline,
                  AppColors.slateLighter,
                  AppColors.slate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),

          // Daftar Kegiatan Pelaksanaan Saya
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Kegiatan Pelaksanaan Saya',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${myKegiatans.length} Kegiatan',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (myKegiatans.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.assignment_late_outlined,
                    size: 48,
                    color: AppColors.slate,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum Ada Kegiatan Ditugaskan',
                    style: TextStyle(
                      color: AppColors.navySlate,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kegiatan pelaksanaan yang ditugaskan kepada ${userProf.namaLengkap} akan tampil di sini.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.slate,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: List.generate(myKegiatans.length, (idx) {
                final k = myKegiatans[idx];
                final parentContract = parentContracts[idx];
                final kIndex = kegIndices[idx];
                final prog = _calcKegiatanProgress(k, contract: parentContract);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.assignment,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  k['namaKegiatan'] ?? 'Nama Kegiatan',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: AppColors.navySlate,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${k['lokasi'] ?? '-'} • ${k['sumberDana'] ?? 'APBD'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Nilai Kontrak Kegiatan:',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.slate,
                            ),
                          ),
                          Text(
                            (k['nilaiKontrak'] ?? '-').toString(),
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navySlate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Progress Bar
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: prog / 100.0,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFF1F5F9),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.navySlate,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${prog.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppColors.navySlate,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          final router = GoRouter.maybeOf(context);
                          if (router != null) {
                            router.go(
                              '/kegiatan/${parentContract.id}/$kIndex',
                              extra: parentContract,
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailKegiatanScreen(
                                  contract: parentContract,
                                  kegiatanIndex: kIndex,
                                ),
                              ),
                            );
                          }
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: const [
                            Text(
                              'Lihat Detail Kegiatan',
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Color(0xFF2563EB),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          const SizedBox(height: 24),
          _buildRecentActivitiesSection(
            context,
            userProf,
            timelineProv,
            contracts,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );

    if (isWeb) {
      if (WebShellScope.isInside(context)) {
        return contractorBody;
      }
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            return;
          }
          if (_activeWebMenu != 'dashboard') {
            _onWebBack();
          }
        },
        child: WebDashboardLayout(
          title: _activeWebMenu != 'dashboard'
              ? _getHeaderTitle(userProf)
              : 'Dashboard Kontraktor',
          activeMenu: _activeWebMenu,
          showBackButton: _activeWebMenu != 'dashboard',
          onBack: _onWebBack,
          onMenuSelected: _onWebMenuSelected,
          child: _buildActiveWebContent(
            context,
            userProf,
            contracts,
            contractorBody,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
        leading: Builder(
          builder: (scaffoldCtx) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.navySlate),
            tooltip: 'Buka Menu',
            onPressed: () {
              Scaffold.of(scaffoldCtx).openDrawer();
            },
          ),
        ),
        title: Column(
          children: [
            const Text(
              'Dashboard Kontraktor',
              style: TextStyle(
                color: AppColors.navySlate,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              userProf.namaLengkap,
              style: const TextStyle(color: AppColors.slate, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
      ),
      drawer: _buildWebSidebar(context, userProf: userProf, isDrawer: true),
      body: contractorBody,
    );
  }

  double _calcKegiatanProgress(
    Map<String, dynamic> keg, {
    ContractModel? contract,
  }) => ProgressCalculator.calculateKegiatanProgress(keg, contract: contract);

  // ═══════════════════════════════════════════════════════════════════════════
  // ─── SIDEBAR DASHBOARD WEB ───
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildWebSidebar(
    BuildContext context, {
    required UserProfileProvider userProf,
    bool isCollapsed = false,
    bool isDrawer = false,
  }) {
    final double sidebarWidth = isDrawer ? 300 : (isCollapsed ? 76 : 260);
    final sidebarBackground = isDrawer
        ? const Color(0xFF0F172A)
        : AppColors.navySlate;
    final headerDividerColor = isDrawer
        ? const Color(0xFF1E293B)
        : AppColors.slateDark;
    final mutedIconColor = isDrawer
        ? const Color(0xFF94A3B8)
        : AppColors.slateLight;
    final activeMenuKey = WebDashboardLayout.resolveActiveMenuKey(
      context,
      fallback: _activeWebMenu,
    );
    final sidebarSections = WebDashboardLayout.sidebarSectionsFor(userProf);

    return Container(
      key: isDrawer ? const ValueKey('mobile_dark_drawer') : null,
      width: sidebarWidth,
      height: double.infinity,
      color: sidebarBackground,
      child: SafeArea(
        child: Column(
          children: [
            // ─── Header: Branding Tata Saka & Collapse Action ───
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 12 : 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: headerDividerColor, width: 1),
                ),
              ),
              child: isCollapsed
                  ? Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.asset(
                            'assets/images/logoRev.png',
                            fit: BoxFit.contain,
                            cacheWidth: 160,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business,
                              color: sidebarBackground,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        IconButton(
                          icon: Icon(
                            Icons.chevron_right,
                            color: mutedIconColor,
                            size: 20,
                          ),
                          tooltip: 'Buka Sidebar',
                          onPressed: () {
                            WebDashboardLayout.isSidebarOpen.value = true;
                          },
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logoRev.png',
                            fit: BoxFit.contain,
                            cacheWidth: 160,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.business,
                              color: sidebarBackground,
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CV. TATA SAKA CONSULTANT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'KONSULTAN TEKNIS',
                                style: TextStyle(
                                  color: isDrawer
                                      ? const Color(0xFF38BDF8)
                                      : AppColors.slateLight,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isDrawer)
                          IconButton(
                            icon: Icon(
                              Icons.chevron_left,
                              color: mutedIconColor,
                              size: 22,
                            ),
                            tooltip: 'Ciutkan Sidebar',
                            onPressed: () {
                              WebDashboardLayout.isSidebarOpen.value = false;
                            },
                          ),
                      ],
                    ),
            ),

            // ─── User Profile Banner ───
            if (!isCollapsed)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDrawer
                      ? const Color(0xFF1E293B)
                      : AppColors.slateDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDrawer ? const Color(0xFF334155) : AppColors.slate,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isDrawer
                          ? const Color(0xFF38BDF8).withOpacity(0.2)
                          : AppColors.slate,
                      child: Text(
                        userProf.namaLengkap.isNotEmpty
                            ? userProf.namaLengkap[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          color: isDrawer
                              ? const Color(0xFF38BDF8)
                              : AppColors.navySlate,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userProf.namaLengkap,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDrawer
                                  ? (userProf.isKontraktor
                                        ? const Color(0xFFFEF3C7)
                                        : (userProf.isDinas
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFDBEAFE)))
                                  : AppColors.slate,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              userProf.role.toUpperCase(),
                              style: TextStyle(
                                color: isDrawer
                                    ? (userProf.isKontraktor
                                          ? const Color(0xFFB45309)
                                          : (userProf.isDinas
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFF1D4ED8)))
                                    : Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Tooltip(
                  message: '${userProf.namaLengkap} (${userProf.role})',
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: isDrawer
                        ? const Color(0xFF1E293B)
                        : AppColors.slateDark,
                    child: Text(
                      userProf.namaLengkap.isNotEmpty
                          ? userProf.namaLengkap[0].toUpperCase()
                          : 'U',
                      style: TextStyle(
                        color: isDrawer
                            ? const Color(0xFF38BDF8)
                            : AppColors.slateLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),

            // ─── Scrollable Menu Categories ───
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 8 : 12,
                  vertical: 8,
                ),
                children: [
                  for (final section in sidebarSections) ...[
                    _buildSidebarCategory(
                      section.title,
                      isCollapsed,
                      isDrawer,
                    ),
                    for (final item in section.items)
                      _buildSidebarItem(
                        isDrawer: isDrawer,
                        key: item.key,
                        label: item.label,
                        icon: item.mobileIcon,
                        isActive: activeMenuKey == item.key,
                        isCollapsed: isCollapsed,
                        onTap: () => _navigateFromSidebar(
                          item.key,
                          _destinationForMenu(item.key, userProf),
                          isDrawer: isDrawer,
                        ),
                      ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
            // ─── Footer: Tombol Logout ───
            Container(
              padding: EdgeInsets.all(isCollapsed ? 8 : 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFF1E293B), width: 1),
                ),
              ),
              child: isCollapsed
                  ? Tooltip(
                      message: 'Keluar / Logout',
                      preferBelow: false,
                      child: InkWell(
                        onTap: () => _handleLogout(context, isDrawer: isDrawer),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          width: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFF87171),
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  : InkWell(
                      onTap: () => _handleLogout(context, isDrawer: isDrawer),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFF87171),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Keluar / Logout',
                                style: TextStyle(
                                  color: Color(0xFFF87171),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarCategory(String title, bool isCollapsed, bool isDrawer) {
    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Divider(
          color: isDrawer ? const Color(0xFF1E293B) : AppColors.slateDark,
          height: 1,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.slate,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required bool isDrawer,
    required String key,
    required String label,
    required IconData icon,
    required bool isActive,
    required bool isCollapsed,
    required VoidCallback onTap,
  }) {
    final activeBg = isDrawer ? const Color(0xFF1E293B) : AppColors.white;
    final activeBorder = isDrawer ? const Color(0xFF38BDF8) : AppColors.white;
    final activeIconColor = isDrawer
        ? const Color(0xFF38BDF8)
        : AppColors.navySlate;
    final inactiveIconColor = isDrawer ? const Color(0xFF94A3B8) : Colors.white;
    final inactiveTextColor = isDrawer
        ? const Color(0xFFCBD5E1)
        : AppColors.slateLight;

    if (isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Tooltip(
          message: label,
          preferBelow: false,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: isActive
                    ? Border.all(color: activeBorder, width: 1)
                    : null,
              ),
              child: Icon(
                icon,
                color: isActive ? activeIconColor : inactiveIconColor,
                size: 21,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isActive
                ? Border.all(color: activeBorder.withOpacity(0.6), width: 1)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isActive ? activeIconColor : inactiveIconColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isActive
                        ? (isDrawer ? Colors.white : AppColors.navySlate)
                        : inactiveTextColor,
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isActive)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDrawer
                        ? const Color(0xFF38BDF8)
                        : AppColors.navySlate,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
