import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/admin_page.dart';
import 'package:tata_saka_app/screens/buat_laporan_screen.dart';
import 'package:tata_saka_app/screens/dashboard_screen.dart';
import 'package:tata_saka_app/screens/data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/edit_profil_screen.dart';
import 'package:tata_saka_app/screens/keamanan_screen.dart';
import 'package:tata_saka_app/screens/kelola_addendum_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/screens/kontrak_screen.dart';
import 'package:tata_saka_app/screens/landing_screen.dart';
import 'package:tata_saka_app/screens/laporan_bulanan_screen.dart';
import 'package:tata_saka_app/screens/laporan_mingguan_screen.dart';
import 'package:tata_saka_app/screens/laporan_screen.dart';
import 'package:tata_saka_app/screens/login_screen.dart';
import 'package:tata_saka_app/screens/panduan_faq_screen.dart';
import 'package:tata_saka_app/screens/pengaturan_screen.dart';
import 'package:tata_saka_app/screens/setting_screen.dart';
import 'package:tata_saka_app/screens/splash_screen.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';
import 'package:tata_saka_app/screens/timeline_screen.dart';
import 'package:tata_saka_app/widgets/app_shell_layout.dart';

/// Navigasi antar-menu dengan menjaga URL dan riwayat browser tetap sinkron.
void goTopLevelRoute(BuildContext context, String location) {
  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  try {
    final current = GoRouterState.of(context).uri.toString();
    if (current != location) {
      router.go(location);
    }
  } catch (_) {
    router.go(location);
  }
}

/// Navigasi deklaratif ke sub-route detail (menjaga hierarki agar Back kembali ke parent).
void goSubRoute(BuildContext context, String location, {Object? extra}) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    router.go(location, extra: extra);
  }
}

/// Kembali secara aman: pop jika ada tumpukan rute, atau kembali ke rute induk.
void goBackOrParent(BuildContext context, String parentLocation) {
  final router = GoRouter.maybeOf(context);
  if (router != null) {
    if (router.canPop()) {
      router.pop();
    } else {
      router.go(parentLocation);
    }
    return;
  }
  if (Navigator.canPop(context)) {
    Navigator.pop(context);
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(
  UserProfileProvider userProf, {
  String initialLocation = '/',
}) {
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialLocation,
    refreshListenable: userProf,
    redirect: (BuildContext context, GoRouterState state) {
      // Tunggu prefs / sesi selesai dimuat agar reload tidak melempar user keluar
      if (!userProf.isInitialized) {
        return null;
      }

      final loc = state.uri.path;
      // Biarkan SplashScreen pada '/' mengatur transisi awalnya secara mandiri di Flutter
      if (loc == '/') {
        return null;
      }

      final isAuth = userProf.isAuthenticated;
      final isAdmin = userProf.role.toLowerCase() == 'admin';

      const publicPaths = {'/', '/landing', '/login', '/panduan-umum'};

      if (!isAuth) {
        if (publicPaths.contains(loc)) return null;
        return '/login';
      }

      // Sudah terautentikasi
      if (loc == '/landing' || loc == '/login') {
        return isAdmin ? '/admin' : '/dashboard';
      }

      if (isAdmin) {
        if (!loc.startsWith('/admin')) return '/admin';
        return null;
      }

      if (loc.startsWith('/admin')) {
        return '/dashboard';
      }

      // Kompatibilitas alias URL lama -> rute terstruktur baru
      if (loc == '/main') return '/dashboard';
      if (loc == '/detail-kontrak') {
        final cid = state.uri.queryParameters['id'];
        final tab = state.uri.queryParameters['tab'] ?? '0';
        if (cid != null && cid.isNotEmpty) {
          return '/kontrak/$cid?tab=$tab';
        }
        return '/kontrak';
      }
      if (loc == '/data_laporan' || loc == '/data-laporan') {
        return '/laporan/data';
      }
      if (loc == '/laporan_harian' || loc == '/laporan-harian') {
        return '/laporan/harian';
      }
      if (loc == '/laporan_mingguan' || loc == '/laporan-mingguan') {
        return '/laporan/mingguan';
      }
      if (loc == '/laporan_bulanan' || loc == '/laporan-bulanan') {
        return '/laporan/bulanan';
      }
      if (loc == '/pengaturan' || loc == '/pengaturan-akun') {
        return '/akun/pengaturan';
      }
      if (loc == '/keamanan') return '/akun/keamanan';
      if (loc == '/edit_profil' || loc == '/edit-profil') {
        return '/akun/profil';
      }
      if (loc == '/panduan_faq' || loc == '/panduan-faq') {
        return '/panduan';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/landing',
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/panduan-umum',
        builder: (context, state) => const PanduanFaqScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPage(),
        routes: [
          GoRoute(
            path: 'panduan',
            builder: (context, state) => const PanduanFaqScreen(),
          ),
        ],
      ),
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => AppShellLayout(
          routerState: state,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/kontrak',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: KontrakScreen(),
            ),
            routes: [
              GoRoute(
                path: 'tambah',
                builder: (context, state) => const TambahKontrakScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  final tab =
                      int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
                  final extraContract = state.extra is ContractModel
                      ? state.extra as ContractModel
                      : null;
                  return DetailKontrakScreen(
                    contract: extraContract,
                    contractId: id,
                    initialTabIndex: tab,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      final extraContract = state.extra is ContractModel
                          ? state.extra as ContractModel
                          : null;
                      return _ContractResolver(
                        contractId: id,
                        extraContract: extraContract,
                        builder: (contract) => TambahKontrakScreen(
                          contractToEdit: contract,
                          contractId: id,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'kegiatan/:kegiatanIndex',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      final idx = int.tryParse(
                              state.pathParameters['kegiatanIndex'] ?? '0') ??
                          0;
                      final extraContract = state.extra is ContractModel
                          ? state.extra as ContractModel
                          : null;
                      return _ContractResolver(
                        contractId: id,
                        extraContract: extraContract,
                        builder: (contract) => DetailKegiatanScreen(
                          contract: contract,
                          kegiatanIndex: idx,
                        ),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'rkk',
                        builder: (context, state) {
                          final id = state.pathParameters['id'];
                          final idx = int.tryParse(
                                  state.pathParameters['kegiatanIndex'] ?? '0') ??
                              0;
                          final extraContract = state.extra is ContractModel
                              ? state.extra as ContractModel
                              : null;
                          return _ContractResolver(
                            contractId: id,
                            extraContract: extraContract,
                            builder: (contract) => KelolaRkkScreen(
                              contract: contract,
                              kegiatanIndex: idx,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'addendum',
                        builder: (context, state) {
                          final id = state.pathParameters['id'];
                          final idx = int.tryParse(
                                  state.pathParameters['kegiatanIndex'] ?? '0') ??
                              0;
                          final extraContract = state.extra is ContractModel
                              ? state.extra as ContractModel
                              : null;
                          return _ContractResolver(
                            contractId: id,
                            extraContract: extraContract,
                            builder: (contract) => KelolaAddendumScreen(
                              contract: contract,
                              kegiatanIndex: idx,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'laporan',
                        builder: (context, state) {
                          final id = state.pathParameters['id'];
                          final idx = int.tryParse(
                                  state.pathParameters['kegiatanIndex'] ?? '0') ??
                              0;
                          final tab = int.tryParse(
                                  state.uri.queryParameters['tab'] ?? '0') ??
                              0;
                          final extraContract = state.extra is ContractModel
                              ? state.extra as ContractModel
                              : null;
                          return _ContractResolver(
                            contractId: id,
                            extraContract: extraContract,
                            builder: (contract) => DetailDataLaporanScreen(
                              contract: contract,
                              kegiatanIndex: idx,
                              initialTab: tab,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/kegiatan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: KontrakScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id/:kegiatanIndex',
                builder: (context, state) {
                  final id = state.pathParameters['id'];
                  final idx = int.tryParse(
                          state.pathParameters['kegiatanIndex'] ?? '0') ??
                      0;
                  final extraContract = state.extra is ContractModel
                      ? state.extra as ContractModel
                      : null;
                  return _ContractResolver(
                    contractId: id,
                    extraContract: extraContract,
                    builder: (contract) => DetailKegiatanScreen(
                      contract: contract,
                      kegiatanIndex: idx,
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'rkk',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      final idx = int.tryParse(
                              state.pathParameters['kegiatanIndex'] ?? '0') ??
                          0;
                      final extraContract = state.extra is ContractModel
                          ? state.extra as ContractModel
                          : null;
                      return _ContractResolver(
                        contractId: id,
                        extraContract: extraContract,
                        builder: (contract) => KelolaRkkScreen(
                          contract: contract,
                          kegiatanIndex: idx,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'addendum',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      final idx = int.tryParse(
                              state.pathParameters['kegiatanIndex'] ?? '0') ??
                          0;
                      final extraContract = state.extra is ContractModel
                          ? state.extra as ContractModel
                          : null;
                      return _ContractResolver(
                        contractId: id,
                        extraContract: extraContract,
                        builder: (contract) => KelolaAddendumScreen(
                          contract: contract,
                          kegiatanIndex: idx,
                        ),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'laporan',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      final idx = int.tryParse(
                              state.pathParameters['kegiatanIndex'] ?? '0') ??
                          0;
                      final tab = int.tryParse(
                              state.uri.queryParameters['tab'] ?? '0') ??
                          0;
                      final extraContract = state.extra is ContractModel
                          ? state.extra as ContractModel
                          : null;
                      return _ContractResolver(
                        contractId: id,
                        extraContract: extraContract,
                        builder: (contract) => DetailDataLaporanScreen(
                          contract: contract,
                          kegiatanIndex: idx,
                          initialTab: tab,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/laporan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LaporanScreen(),
            ),
            routes: [
              GoRoute(
                path: 'data',
                builder: (context, state) => const DataLaporanScreen(),
                routes: [
                  GoRoute(
                    path: ':id/:kegiatanIndex',
                    builder: (context, state) {
                      final id = state.pathParameters['id'];
                      final idx = int.tryParse(
                              state.pathParameters['kegiatanIndex'] ?? '0') ??
                          0;
                      final tab = int.tryParse(
                              state.uri.queryParameters['tab'] ?? '0') ??
                          0;
                      final extraContract = state.extra is ContractModel
                          ? state.extra as ContractModel
                          : null;
                      return _ContractResolver(
                        contractId: id,
                        extraContract: extraContract,
                        builder: (contract) => DetailDataLaporanScreen(
                          contract: contract,
                          kegiatanIndex: idx,
                          initialTab: tab,
                        ),
                      );
                    },
                  ),
                ],
              ),
              GoRoute(
                path: 'harian',
                builder: (context, state) => const BuatLaporanScreen(),
              ),
              GoRoute(
                path: 'mingguan',
                builder: (context, state) => const LaporanMingguanScreen(),
              ),
              GoRoute(
                path: 'bulanan',
                builder: (context, state) => const LaporanBulananScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/timeline',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TimelineScreen(),
            ),
          ),
          GoRoute(
            path: '/akun',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingScreen(),
            ),
            routes: [
              GoRoute(
                path: 'profil',
                builder: (context, state) => const EditProfilScreen(),
              ),
              GoRoute(
                path: 'pengaturan',
                builder: (context, state) => const PengaturanScreen(),
              ),
              GoRoute(
                path: 'keamanan',
                builder: (context, state) => const KeamananScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/panduan',
            pageBuilder: (context, state) => NoTransitionPage(
              child: PanduanFaqScreen(
                role: userProf.isKontraktor
                    ? 'kontraktor'
                    : (userProf.isKonsultan ? 'konsultan' : null),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _ContractResolver extends StatelessWidget {
  final String? contractId;
  final ContractModel? extraContract;
  final Widget Function(ContractModel contract) builder;

  const _ContractResolver({
    required this.contractId,
    required this.extraContract,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (extraContract != null) {
      return builder(extraContract!);
    }
    final provider = context.watch<ContractProvider>();
    final found = contractId == null
        ? null
        : provider.contracts.cast<ContractModel?>().firstWhere(
              (c) => c != null && c.id == contractId,
              orElse: () => null,
            );
    if (found != null) {
      return builder(found);
    }
    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Kontrak Tidak Ditemukan')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Data kontrak tidak ditemukan.'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => context.go('/kontrak'),
              child: const Text('Kembali ke Kontrak'),
            ),
          ],
        ),
      ),
    );
  }
}
