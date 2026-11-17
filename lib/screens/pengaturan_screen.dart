import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class PengaturanScreen extends StatefulWidget {
  final bool isEmbedded;
  const PengaturanScreen({super.key, this.isEmbedded = false});

  @override
  State<PengaturanScreen> createState() => _PengaturanScreenState();
}

class _PengaturanScreenState extends State<PengaturanScreen> {
  void _showThemePickerSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<UserProfileProvider>(
          builder: (context, userProf, _) {
            final currentTheme = userProf.themeMode;
            final themes = ['Terang', 'Gelap', 'Mengikuti Sistem'];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        userProf.tr('settings_theme_dialog'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextDark(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...themes.map((t) {
                      final isSelected = t == currentTheme;
                      IconData tIcon;
                      String displayTheme;
                      if (t == 'Terang') {
                        tIcon = Icons.wb_sunny_outlined;
                        displayTheme = userProf.tr('settings_theme_light');
                      } else if (t == 'Gelap') {
                        tIcon = Icons.nightlight_round_outlined;
                        displayTheme = userProf.tr('settings_theme_dark');
                      } else {
                        tIcon = Icons.settings_suggest_outlined;
                        displayTheme = userProf.tr('settings_theme_system');
                      }

                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF0369A1) : const Color(0xFFEFF6FF))
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            tIcon,
                            color: isSelected
                                ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                                : AppColors.getTextLight(context),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          displayTheme,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                                : AppColors.getTextDark(context),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                size: 22)
                            : null,
                        onTap: () {
                          userProf.updateTheme(t);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showLanguagePickerSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Consumer<UserProfileProvider>(
          builder: (context, userProf, _) {
            final currentLang = userProf.language;
            final languages = ['Indonesia', 'English'];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        userProf.tr('settings_language_dialog'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextDark(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...languages.map((l) {
                      final isSelected = l == currentLang;
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (isDark ? const Color(0xFF0369A1) : const Color(0xFFEFF6FF))
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.language,
                            color: isSelected
                                ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                                : AppColors.getTextLight(context),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          l == 'Indonesia' ? 'Bahasa Indonesia' : 'English (US)',
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB))
                                : AppColors.getTextDark(context),
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle,
                                color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF2563EB),
                                size: 22)
                            : null,
                        onTap: () {
                          userProf.updateLanguage(l);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showReminderSettingsDialog(BuildContext context) async {
    final provider = context.read<UserProfileProvider>();
    final parts = provider.reminderTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 17,
      minute: parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hourStr = picked.hour.toString().padLeft(2, '0');
      final minuteStr = picked.minute.toString().padLeft(2, '0');
      provider.setReminderLaporanHarian(true, time: '$hourStr:$minuteStr');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.isEnglish
              ? 'Reminder time set to $hourStr:$minuteStr.'
              : 'Waktu reminder berhasil diatur ke pukul $hourStr:$minuteStr WIB.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showBackupInfoDialog(BuildContext context) {
    final userProf = context.read<UserProfileProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_upload_outlined, color: Color(0xFF2563EB), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userProf.tr('settings_backup_dialog_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextDark(context),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userProf.tr('settings_backup_dialog_msg'),
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.getTextDark(context),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Color(0xFF2563EB)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${userProf.tr('settings_backup_sub')} ${userProf.lastBackupDate}',
                      style: TextStyle(fontSize: 12, color: AppColors.getTextLight(context)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              userProf.isEnglish ? 'Understood' : 'Mengerti',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context) {
    final userProf = context.read<UserProfileProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                userProf.tr('settings_clear_cache_dialog_title'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextDark(context),
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '${userProf.tr('settings_clear_cache_dialog_msg')}\n(${userProf.tr('settings_clear_cache_sub')} ${userProf.cacheSize})',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.getTextDark(context),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              userProf.tr('btn_cancel'),
              style: TextStyle(color: AppColors.getTextLight(context)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () {
              context.read<UserProfileProvider>().clearCache();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(userProf.tr('settings_clear_cache_success')),
                  backgroundColor: AppColors.successGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(userProf.isEnglish ? 'Clear' : 'Bersihkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = AppColors.getCardBackground(context);
    final borderColor = AppColors.getBorder(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.getTextDark(context)),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
            }
          },
        ),
        title: Consumer<UserProfileProvider>(
          builder: (context, userProf, child) => Text(
            userProf.tr('settings_title'),
            style: TextStyle(
              color: AppColors.getTextDark(context),
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<UserProfileProvider>(
        builder: (context, userProf, child) {
          String displayTheme = userProf.themeMode;
          if (userProf.themeMode == 'Terang') {
            displayTheme = userProf.tr('settings_theme_light');
          } else if (userProf.themeMode == 'Gelap') {
            displayTheme = userProf.tr('settings_theme_dark');
          } else {
            displayTheme = userProf.tr('settings_theme_system');
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // ─── 1. PREFERENSI APLIKASI ───
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  userProf.tr('settings_preferences'),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextDark(context),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildNavRow(
                      context: context,
                      icon: Icons.wb_sunny_outlined,
                      iconBg: isDark ? const Color(0xFF0369A1) : const Color(0xFFE0F2FE),
                      iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      hasIconBox: true,
                      title: userProf.tr('settings_theme'),
                      subtitle: userProf.tr('settings_theme_sub'),
                      trailingText: displayTheme,
                      onTap: () => _showThemePickerSheet(context),
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildNavRow(
                      context: context,
                      icon: Icons.language,
                      iconBg: isDark ? const Color(0xFF0369A1) : const Color(0xFFE0F2FE),
                      iconColor: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      hasIconBox: true,
                      title: userProf.tr('settings_language'),
                      subtitle: userProf.tr('settings_language_sub'),
                      trailingText: userProf.language,
                      onTap: () => _showLanguagePickerSheet(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── 2. NOTIFIKASI ───
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  userProf.tr('settings_notifications'),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextDark(context),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildSwitchRow(
                      context: context,
                      icon: Icons.notifications_none_outlined,
                      title: userProf.tr('settings_notif_push'),
                      subtitle: userProf.tr('settings_notif_push_sub'),
                      value: userProf.notifikasiPush,
                      onChanged: (v) => userProf.setNotifikasiPush(v),
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildSwitchRow(
                      context: context,
                      icon: Icons.mail_outline,
                      title: userProf.tr('settings_notif_email'),
                      subtitle: userProf.tr('settings_notif_email_sub'),
                      value: userProf.emailNotifikasi,
                      onChanged: (v) => userProf.setEmailNotifikasi(v),
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildSwitchRow(
                      context: context,
                      icon: Icons.folder_open_outlined,
                      title: userProf.tr('settings_notif_project'),
                      subtitle: userProf.tr('settings_notif_project_sub'),
                      value: userProf.notifikasiProyek,
                      onChanged: (v) => userProf.setNotifikasiProyek(v),
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildSwitchRow(
                      context: context,
                      icon: Icons.description_outlined,
                      title: userProf.tr('settings_notif_report'),
                      subtitle: userProf.tr('settings_notif_report_sub'),
                      value: userProf.notifikasiLaporan,
                      onChanged: (v) => userProf.setNotifikasiLaporan(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ─── 3. LAINNYA ───
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  userProf.tr('settings_others'),
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextDark(context),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _buildNavRow(
                      context: context,
                      icon: Icons.calendar_today_outlined,
                      title: userProf.tr('settings_reminder'),
                      subtitle: '${userProf.tr('settings_reminder_sub')} ${userProf.reminderTime}',
                      onTap: () => _showReminderSettingsDialog(context),
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildNavRow(
                      context: context,
                      icon: Icons.cloud_upload_outlined,
                      title: userProf.tr('settings_backup'),
                      subtitle: '${userProf.tr('settings_backup_sub')} ${userProf.lastBackupDate}',
                      onTap: () => _showBackupInfoDialog(context),
                    ),
                    Divider(height: 1, color: borderColor),
                    _buildNavRow(
                      context: context,
                      icon: Icons.delete_outline,
                      title: userProf.tr('settings_clear_cache'),
                      subtitle: '${userProf.tr('settings_clear_cache_sub')} ${userProf.cacheSize}',
                      onTap: () => _showClearCacheDialog(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNavRow({
    required BuildContext context,
    required IconData icon,
    Color? iconBg,
    Color? iconColor,
    bool hasIconBox = false,
    required String title,
    required String subtitle,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            if (hasIconBox)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBg ?? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                  size: 20,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  icon,
                  color: iconColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  size: 22,
                ),
              ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.getTextDark(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextLight(context),
                    ),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextLight(context),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Icon(Icons.chevron_right, color: AppColors.getTextLight(context), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              icon,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextDark(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.getTextLight(context),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2563EB),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
