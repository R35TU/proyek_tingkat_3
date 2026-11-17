import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';

/// Reusable Web Dashboard Layout Shell for Tata Saka Consultant.
///
/// Features:
/// - Clean white Corporate Sidebar with light-blue hover and distinct dark-navy active pill.
/// - Persistent clean white Header with dedicated Back button and Sidebar minimize toggle.
/// - Smooth animated expand/collapse for the sidebar.
/// - Notification button omitted until notification features are ready.
/// - Fully responsive: keeps mobile Drawer untouched on screens < 900px.
class WebDashboardLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final String activeMenu;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBackButton;
  final VoidCallback? onBack;
  final void Function(String menuKey)? onMenuSelected;

  /// Global notifier so collapse/expand state is remembered across all screens.
  static final ValueNotifier<bool> isSidebarOpen = ValueNotifier<bool>(true);

  /// Global notifier for active menu across all web screens.
  static final ValueNotifier<String> activeWebMenu =
      ValueNotifier<String>('dashboard');

  const WebDashboardLayout({
    super.key,
    required this.child,
    required this.title,
    this.activeMenu = 'dashboard',
    this.actions,
    this.floatingActionButton,
    this.showBackButton = false,
    this.onBack,
    this.onMenuSelected,
  });

  @override
  State<WebDashboardLayout> createState() => _WebDashboardLayoutState();
}

class _WebDashboardLayoutState extends State<WebDashboardLayout> {
  void _handleMenuClick(String menuKey) {
    WebDashboardLayout.activeWebMenu.value = menuKey;
    if (widget.onMenuSelected != null) {
      widget.onMenuSelected!(menuKey);
    } else {
      if (Navigator.canPop(context)) {
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      }
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
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // On mobile screens (< 900px), return the child directly with mobile scaffold if needed
    if (!isDesktop) {
      return widget.child;
    }

    UserProfileProvider userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = UserProfileProvider();
    }

    return ValueListenableBuilder<bool>(
      valueListenable: WebDashboardLayout.isSidebarOpen,
      builder: (context, isOpen, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildWebHeading(context, userProf, isOpen),
          floatingActionButton: widget.floatingActionButton,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                width: isOpen ? 260.0 : 76.0,
                height: double.infinity,
                child: ClipRect(
                  child: OverflowBox(
                    minWidth: 76.0,
                    maxWidth: 260.0,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      width: isOpen ? 260.0 : 76.0,
                      child: _buildWebSidebar(
                        context,
                        userProf,
                        isCollapsed: !isOpen,
                      ),
                    ),
                  ),
                ),
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: Color(0xFFE2E8F0),
              ),
              Expanded(
                child: Container(
                  color: AppColors.background,
                  child: Column(
                    children: [
                      Expanded(child: widget.child),
                      _buildWebFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '© 2026 CV. Tata Saka. Konsultan Pengawas & Perencana.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            'Sistem Informasi Pengawasan Jalan',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildWebHeading(
    BuildContext context,
    UserProfileProvider userProf,
    bool isSidebarOpen,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFE2E8F0),
        ),
      ),
      titleSpacing: 16,
      title: Row(
        children: [
          // 1. Tombol Minimize / Expand Sidebar di Header (sebelah kiri)
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: IconButton(
              icon: Icon(
                isSidebarOpen ? Icons.menu_open : Icons.menu,
                color: const Color(0xFF475569),
                size: 20,
              ),
              tooltip: isSidebarOpen ? 'Ciutkan Sidebar' : 'Buka Sidebar',
              splashRadius: 20,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              padding: EdgeInsets.zero,
              onPressed: () {
                WebDashboardLayout.isSidebarOpen.value =
                    !WebDashboardLayout.isSidebarOpen.value;
              },
            ),
          ),

          // 2. Tombol Back: tepat di sebelah kanan tombol toggle sidebar
          if (widget.showBackButton) ...[
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
                tooltip: 'Kembali',
                splashRadius: 20,
                constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
                padding: EdgeInsets.zero,
                onPressed: widget.onBack ??
                    () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/main',
                          (route) => false,
                        );
                      }
                    },
              ),
            ),
          ],
          const SizedBox(width: 14),

          // 3. Judul Halaman
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (widget.actions != null) ...widget.actions!,
        // NOTE: Tombol notifikasi dihapus dari header per ketentuan user!
        const SizedBox(width: 12),
        _buildUserProfileHeaderPill(userProf),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildUserProfileHeaderPill(UserProfileProvider userProf) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 13,
            backgroundColor: const Color(0xFFE0F2FE),
            child: Text(
              userProf.namaLengkap.isNotEmpty
                  ? userProf.namaLengkap[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Color(0xFF0284C7),
                fontWeight: FontWeight.w800,
                fontSize: 11.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(
                  userProf.namaLengkap.isNotEmpty
                      ? userProf.namaLengkap
                      : userProf.username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                userProf.role.isNotEmpty
                    ? (userProf.role[0].toUpperCase() +
                        userProf.role.substring(1).toLowerCase())
                    : 'User',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildWebSidebar(
    BuildContext context,
    UserProfileProvider userProf, {
    bool isCollapsed = false,
    bool isDrawer = false,
  }) {
    final double sidebarWidth = isDrawer ? 300 : (isCollapsed ? 76 : 260);
    const sidebarBackground = Colors.white;
    const headerDividerColor = Color(0xFFE2E8F0);

    return Container(
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
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: headerDividerColor, width: 1),
                ),
              ),
              child: isCollapsed
                  ? Center(
                      child: Container(
                        width: 42,
                        height: 42,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logoRev.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.business,
                            color: Color(0xFF1E293B),
                            size: 24,
                          ),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logoRev.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business,
                              color: Color(0xFF1E293B),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CV. TATA SAKA',
                                style: TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'KONSULTAN PENGAWAS',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                'Consultant Engineer',
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // ─── Scrollable Menu Categories ───
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isCollapsed ? 8 : 12,
                  vertical: 10,
                ),
                children: [
                  // 1. KATEGORI UTAMA
                  _buildSidebarCategory('UTAMA', isCollapsed, isDrawer),
                  _SidebarItemWidget(
                    isDrawer: isDrawer,
                    menuKey: 'dashboard',
                    label: userProf.tr('nav_dashboard'),
                    icon: Icons.dashboard,
                    isActive: widget.activeMenu == 'dashboard',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      _handleMenuClick('dashboard');
                    },
                  ),
                  if (!userProf.isKontraktor)
                    _SidebarItemWidget(
                      isDrawer: isDrawer,
                      menuKey: 'kontrak',
                      label: userProf.tr('nav_kontrak'),
                      icon: Icons.folder_outlined,
                      isActive: widget.activeMenu == 'kontrak',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        _handleMenuClick('kontrak');
                      },
                    )
                  else
                    _SidebarItemWidget(
                      isDrawer: isDrawer,
                      menuKey: 'kegiatan',
                      label: userProf.tr('nav_kegiatan_saya'),
                      icon: Icons.assignment_outlined,
                      isActive: widget.activeMenu == 'kegiatan',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        _handleMenuClick('kegiatan');
                      },
                    ),

                  const SizedBox(height: 12),

                  // 2. KATEGORI PELAPORAN (Hanya Konsultan & Dinas)
                  if (!userProf.isKontraktor) ...[
                    _buildSidebarCategory('PELAPORAN', isCollapsed, isDrawer),
                    _SidebarItemWidget(
                      isDrawer: isDrawer,
                      menuKey: 'laporan',
                      label: 'Laporan',
                      icon: Icons.description_outlined,
                      isActive: widget.activeMenu == 'laporan',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        _handleMenuClick('laporan');
                      },
                    ),
                    _SidebarItemWidget(
                      isDrawer: isDrawer,
                      menuKey: 'data_laporan',
                      label: 'Data Laporan',
                      icon: Icons.folder_open,
                      isActive: widget.activeMenu == 'data_laporan',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        _handleMenuClick('data_laporan');
                      },
                    ),
                    _SidebarItemWidget(
                      isDrawer: isDrawer,
                      menuKey: 'laporan_harian',
                      label: 'Laporan Harian',
                      icon: Icons.today_outlined,
                      isActive: widget.activeMenu == 'laporan_harian',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        _handleMenuClick('laporan_harian');
                      },
                    ),
                    _SidebarItemWidget(
                      isDrawer: isDrawer,
                      menuKey: 'laporan_mingguan',
                      label: 'Laporan Mingguan',
                      icon: Icons.date_range_outlined,
                      isActive: widget.activeMenu == 'laporan_mingguan',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        _handleMenuClick('laporan_mingguan');
                      },
                    ),
                    _SidebarItemWidget(
                      isDrawer: isDrawer,
                      menuKey: 'laporan_bulanan',
                      label: 'Laporan Bulanan',
                      icon: Icons.calendar_month_outlined,
                      isActive: widget.activeMenu == 'laporan_bulanan',
                      isCollapsed: isCollapsed,
                      onTap: () {
                        if (isDrawer) Navigator.pop(context);
                        _handleMenuClick('laporan_bulanan');
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3. KATEGORI DOKUMEN & HISTORI
                  _buildSidebarCategory(
                    'DOKUMEN & HISTORI',
                    isCollapsed,
                    isDrawer,
                  ),
                  _SidebarItemWidget(
                    isDrawer: isDrawer,
                    menuKey: 'timeline',
                    label: 'Timeline & Histori',
                    icon: Icons.timeline,
                    isActive: widget.activeMenu == 'timeline',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      _handleMenuClick('timeline');
                    },
                  ),

                  const SizedBox(height: 12),

                  // 4. KATEGORI AKUN & PENGATURAN
                  _buildSidebarCategory(
                    'AKUN & PENGATURAN',
                    isCollapsed,
                    isDrawer,
                  ),
                  _SidebarItemWidget(
                    isDrawer: isDrawer,
                    menuKey: 'pengaturan',
                    label: 'Pengaturan Akun',
                    icon: Icons.settings_outlined,
                    isActive: widget.activeMenu == 'pengaturan',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      _handleMenuClick('pengaturan');
                    },
                  ),
                  _SidebarItemWidget(
                    isDrawer: isDrawer,
                    menuKey: 'keamanan',
                    label: 'Keamanan & Sandi',
                    icon: Icons.security_outlined,
                    isActive: widget.activeMenu == 'keamanan',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      _handleMenuClick('keamanan');
                    },
                  ),
                  _SidebarItemWidget(
                    isDrawer: isDrawer,
                    menuKey: 'edit_profil',
                    label: 'Edit Profil',
                    icon: Icons.person_outline_rounded,
                    isActive: widget.activeMenu == 'edit_profil',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      _handleMenuClick('edit_profil');
                    },
                  ),

                  const SizedBox(height: 12),

                  // 5. KATEGORI BANTUAN
                  _buildSidebarCategory('BANTUAN', isCollapsed, isDrawer),
                  _SidebarItemWidget(
                    isDrawer: isDrawer,
                    menuKey: 'panduan_faq',
                    label: 'Panduan & FAQ',
                    icon: Icons.help_outline,
                    isActive: widget.activeMenu == 'panduan_faq',
                    isCollapsed: isCollapsed,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      _handleMenuClick('panduan_faq');
                    },
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),

            // ─── Footer: Keluar Akun & Tombol Minimize Sidebar ───
            Container(
              padding: EdgeInsets.all(isCollapsed ? 8 : 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol Logout / Keluar Akun
                  if (isCollapsed)
                    Tooltip(
                      message: 'Keluar Akun',
                      preferBelow: false,
                      child: InkWell(
                        onTap: () => _handleLogout(context, isDrawer: isDrawer),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 42,
                          width: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFEF4444),
                            size: 20,
                          ),
                        ),
                      ),
                    )
                  else
                    InkWell(
                      onTap: () => _handleLogout(context, isDrawer: isDrawer),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFEF4444),
                              size: 19,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Keluar Akun',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Tombol Minimize Sidebar di bawah
                  if (!isDrawer) ...[
                    const SizedBox(height: 6),
                    if (isCollapsed)
                      Tooltip(
                        message: 'Buka Sidebar',
                        preferBelow: false,
                        child: InkWell(
                          onTap: () {
                            WebDashboardLayout.isSidebarOpen.value = true;
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            height: 40,
                            width: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.chevron_right,
                              color: Color(0xFF64748B),
                              size: 22,
                            ),
                          ),
                        ),
                      )
                    else
                      InkWell(
                        onTap: () {
                          WebDashboardLayout.isSidebarOpen.value = false;
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.chevron_left,
                                color: Color(0xFF64748B),
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ciutkan Menu',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarCategory(
    String title,
    bool isCollapsed,
    bool isDrawer,
  ) {
    if (isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(
          color: Color(0xFFE2E8F0),
          height: 1,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF94A3B8),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

/// Stateful hover item widget for the Web Sidebar.
/// - Active: Dark Navy Slate (#1E293B) pill with white icon & text.
/// - Hover: Soft Light Blue (#F0F9FF) with light border & Sky Blue (#0284C7) icon & text.
/// - Inactive: Transparent with Slate icon & text.
class _SidebarItemWidget extends StatefulWidget {
  final bool isDrawer;
  final String menuKey;
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItemWidget({
    required this.isDrawer,
    required this.menuKey,
    required this.label,
    required this.icon,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItemWidget> createState() => _SidebarItemWidgetState();
}

class _SidebarItemWidgetState extends State<_SidebarItemWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color iconColor;
    final Color textColor;
    final Border? border;

    if (widget.isActive) {
      bgColor = const Color(0xFF1E293B);
      iconColor = Colors.white;
      textColor = Colors.white;
      border = null;
    } else if (_isHovered) {
      bgColor = const Color(0xFFF0F9FF);
      iconColor = const Color(0xFF0284C7);
      textColor = const Color(0xFF0369A1);
      border = Border.all(color: const Color(0xFFBAE6FD), width: 0.8);
    } else {
      bgColor = Colors.transparent;
      iconColor = const Color(0xFF64748B);
      textColor = const Color(0xFF334155);
      border = Border.all(color: Colors.transparent, width: 0.8);
    }

    if (widget.isCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Tooltip(
          message: widget.label,
          preferBelow: false,
          child: MouseRegion(
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 44,
                width: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: border,
                  boxShadow: widget.isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF1E293B).withOpacity(0.18),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.icon,
                  size: 21,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: border,
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF1E293B).withOpacity(0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: ClipRect(
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 20,
                    color: iconColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        fontWeight: widget.isActive
                            ? FontWeight.w700
                            : (_isHovered ? FontWeight.w600 : FontWeight.w500),
                      ),
                    ),
                  ),
                  if (widget.isActive)
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
