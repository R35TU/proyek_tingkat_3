import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/timeline_event_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/theme/app_colors.dart';

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  String? _selectedContractId;
  String? _selectedKegiatanName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final contracts = context.read<ContractProvider>().contracts;
        context.read<TimelineProvider>().syncWithContracts(contracts);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _categoryTabs = [
    {'key': 'Semua', 'labelKey': 'timeline_cat_all', 'icon': Icons.all_inclusive},
    {'key': 'Kontrak & Kegiatan', 'labelKey': 'timeline_cat_contract', 'icon': Icons.business_center_outlined},
    {'key': 'RAB / BoQ', 'labelKey': 'timeline_cat_rab', 'icon': Icons.table_chart_outlined},
    {'key': 'Addendum (CCO)', 'labelKey': 'timeline_cat_cco', 'icon': Icons.difference_outlined},
    {'key': 'Laporan', 'labelKey': 'timeline_cat_report', 'icon': Icons.assignment_outlined},
    {'key': 'Dokumen', 'labelKey': 'timeline_cat_doc', 'icon': Icons.folder_shared_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    final userProf = Provider.of<UserProfileProvider>(context);
    final timelineProv = Provider.of<TimelineProvider>(context);
    final contractProv = Provider.of<ContractProvider>(context);

    final isDark = AppColors.isDark(context);
    final bgColor = AppColors.getBackground(context);
    final cardColor = AppColors.getCardBackground(context);
    final textDark = AppColors.getTextDark(context);
    final textLight = AppColors.getTextLight(context);
    final borderColor = AppColors.getBorder(context);

    // Dapatkan event terfilter
    final filteredEvents = timelineProv.getFilteredEvents(
      userProfile: userProf,
      contractId: _selectedContractId,
      kegiatanName: _selectedKegiatanName,
      category: _selectedCategory,
      searchQuery: _searchQuery,
    );

    // Kumpulkan opsi kegiatan yang relevan untuk role pengguna
    final availableKegiatans = <String>{};
    for (final c in contractProv.contracts) {
      for (final k in c.kegiatans) {
        final kName = k['namaKegiatan']?.toString() ?? '';
        final kontraktor = k['kontraktor']?.toString().toLowerCase() ?? '';
        if (kName.isEmpty) continue;

        if (userProf.isKontraktor) {
          final userComp = userProf.companyOrAgency.toLowerCase();
          final userFull = userProf.namaLengkap.toLowerCase();
          if (kontraktor.contains(userComp) ||
              userComp.contains(kontraktor) ||
              kontraktor.contains(userFull) ||
              userFull.contains(kontraktor)) {
            availableKegiatans.add(kName);
          }
        } else {
          availableKegiatans.add(kName);
        }
      }
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
        title: Column(
          children: [
            Text(
              userProf.tr('timeline_title'),
              style: TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              userProf.tr('timeline_subtitle'),
              style: TextStyle(
                color: textLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 14, color: textDark),
                const SizedBox(width: 4),
                Text(
                  '${filteredEvents.length}',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── 1. SEARCH & FAST FILTERS ───
          Container(
            color: cardColor,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                // Search Input Field
                TextField(
                  controller: _searchController,
                  style: TextStyle(color: textDark, fontSize: 13),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: userProf.tr('timeline_search_hint'),
                    hintStyle: TextStyle(color: textLight, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: textLight, size: 18),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: textLight, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : AppColors.softGray,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.getPrimary(context), width: 1.5),
                    ),
                  ),
                ),

                // Selector Dropdown Kegiatan (jika tersedia > 1)
                if (availableKegiatans.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : AppColors.softGray,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedKegiatanName ?? 'Semua Kegiatan',
                        isExpanded: true,
                        dropdownColor: cardColor,
                        icon: Icon(Icons.arrow_drop_down, color: textLight, size: 20),
                        style: TextStyle(color: textDark, fontSize: 12, fontWeight: FontWeight.w600),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'Semua Kegiatan',
                            child: Text(
                              userProf.tr('timeline_filter_activity'),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ...availableKegiatans.map(
                            (keg) => DropdownMenuItem<String>(
                              value: keg,
                              child: Text(keg, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          setState(() {
                            if (val == 'Semua Kegiatan' || val == null) {
                              _selectedKegiatanName = null;
                            } else {
                              _selectedKegiatanName = val;
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ─── 2. HORIZONTAL CATEGORY FILTER CHIPS ───
          Container(
            color: cardColor,
            height: 48,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categoryTabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final tab = _categoryTabs[idx];
                final isSelected = _selectedCategory == tab['key'];
                final label = userProf.tr(tab['labelKey']);
                final icon = tab['icon'] as IconData;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = tab['key'];
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.navySlate
                          : (isDark ? const Color(0xFF243046) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.navySlate
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFF94A3B8) : AppColors.slate),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFCBD5E1) : AppColors.slateDark),
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1, color: borderColor),

          // ─── 3. TIMELINE EVENT LIST ───
          Expanded(
            child: timelineProv.isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredEvents.isEmpty
                    ? _buildEmptyState(context, userProf, isDark)
                    : _buildGroupedTimelineList(context, filteredEvents, userProf, isDark),
          ),
        ],
      ),
    );
  }

  /// Tampilan jika tidak ada aktivitas yang sesuai
  Widget _buildEmptyState(
    BuildContext context,
    UserProfileProvider userProf,
    bool isDark,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_toggle_off,
                size: 52,
                color: AppColors.getTextLight(context).withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userProf.tr('timeline_empty_title'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextDark(context),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userProf.tr('timeline_empty_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.getTextLight(context),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            if (_searchQuery.isNotEmpty ||
                _selectedCategory != 'Semua' ||
                _selectedKegiatanName != null) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchQuery = '';
                    _searchController.clear();
                    _selectedCategory = 'Semua';
                    _selectedKegiatanName = null;
                  });
                },
                icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
                label: const Text('Reset Filter', style: TextStyle(color: Colors.white, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navySlate,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Tampilan Timeline terkelompok berdasarkan Periode / Bulan
  Widget _buildGroupedTimelineList(
    BuildContext context,
    List<TimelineEventModel> events,
    UserProfileProvider userProf,
    bool isDark,
  ) {
    // Kelompokkan berdasarkan Bulan & Tahun atau Hari Ini / Kemarin
    final Map<String, List<TimelineEventModel>> grouped = {};
    for (final event in events) {
      final key = _getGroupHeader(event.timestamp);
      grouped.putIfAbsent(key, () => []).add(event);
    }

    final groupKeys = grouped.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: groupKeys.length,
      itemBuilder: (context, gIdx) {
        final groupTitle = groupKeys[gIdx];
        final groupEvents = grouped[groupTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sticky-style Period Header Badge
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      groupTitle,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFF1F5F9) : AppColors.slateDark,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Divider(
                      color: AppColors.getBorder(context).withOpacity(0.6),
                      thickness: 1,
                    ),
                  ),
                ],
              ),
            ),

            // Timeline Items
            ...groupEvents.asMap().entries.map((entry) {
              final idx = entry.key;
              final ev = entry.value;
              final isLastInGroup = idx == groupEvents.length - 1;
              final isLastOverall = gIdx == groupKeys.length - 1 && isLastInGroup;

              return _buildTimelineNode(
                context: context,
                event: ev,
                isLast: isLastOverall,
                userProf: userProf,
                isDark: isDark,
              );
            }),
          ],
        );
      },
    );
  }

  String _getGroupHeader(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'HARI INI';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day) {
      return 'KEMARIN';
    }
    try {
      return DateFormat('MMMM yyyy', 'id_ID').format(dt).toUpperCase();
    } catch (_) {
      return '${dt.month}/${dt.year}';
    }
  }

  /// Komponen Node Timeline Tunggal
  Widget _buildTimelineNode({
    required BuildContext context,
    required TimelineEventModel event,
    required bool isLast,
    required UserProfileProvider userProf,
    required bool isDark,
  }) {
    final cardBg = AppColors.getCardBackground(context);
    final borderColor = AppColors.getBorder(context);
    final textDark = AppColors.getTextDark(context);
    final textLight = AppColors.getTextLight(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Left Track (Line & Icon Circle) ───
          SizedBox(
            width: 40,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                // Connecting Vertical Line
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),

                // Icon Indicator Badge
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: event.actionColor.withOpacity(isDark ? 0.25 : 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: event.actionColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      event.icon,
                      size: 16,
                      color: isDark ? Colors.white : event.actionColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // ─── Right Content Card ───
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Header: Action Badge & Time (Responsive Wrap to prevent overflow)
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Action Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: event.actionColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.actionLabel.toUpperCase(),
                            style: TextStyle(
                              color: event.actionColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                        // Entity Tag
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 140),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              event.category,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textLight,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        // Timestamp (Formatted Date & Time)
                        Text(
                          '${event.formattedDate} • ${event.formattedTime}',
                          style: TextStyle(
                            color: textLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    Text(
                      event.title,
                      style: TextStyle(
                        color: textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Description
                    Text(
                      event.description,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFCBD5E1) : AppColors.slateDark,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),

                    // OPSI A: Detail Perubahan Button (jika ada changes)
                    if (event.changes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: () => _showChangesDetailModal(context, event, userProf, isDark),
                        icon: const Icon(Icons.difference_outlined, size: 15),
                        label: Text(
                          userProf.tr('timeline_view_changes'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? const Color(0xFF38BDF8) : AppColors.navySlate,
                          side: BorderSide(
                            color: isDark ? const Color(0xFF0284C7) : AppColors.navySlate.withOpacity(0.5),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          visualDensity: VisualDensity.compact,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    Divider(height: 1, color: borderColor.withOpacity(0.5)),
                    const SizedBox(height: 8),

                    // Context Footer (Actor & Activity)
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 13, color: textLight),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            event.actorName,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              color: textLight,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (event.kegiatanName != null && event.kegiatanName!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.alt_route, size: 13, color: textLight),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              event.kegiatanName!,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: textLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dialog Rincian Perubahan Sebelum vs Sesudah (Opsi A)
  void _showChangesDetailModal(
    BuildContext context,
    TimelineEventModel event,
    UserProfileProvider userProf,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final modalBg = AppColors.getCardBackground(ctx);
        final modalTextDark = AppColors.getTextDark(ctx);
        final modalTextLight = AppColors.getTextLight(ctx);
        final modalBorder = AppColors.getBorder(ctx);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: modalBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: modalBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.difference_outlined, color: Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProf.tr('timeline_dialog_changes_title'),
                          style: TextStyle(
                            color: modalTextDark,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: modalTextLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: modalTextLight),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: modalBorder),
              const SizedBox(height: 12),

              // List of Changes (Sebelum vs Sesudah)
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: event.changes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, cIdx) {
                    final item = event.changes[cIdx];
                    final param = item['parameter'] ?? '-';
                    final oldVal = item['oldValue'] ?? '-';
                    final newVal = item['newValue'] ?? '-';

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: modalBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Parameter Name
                          Text(
                            param,
                            style: TextStyle(
                              color: modalTextDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Before & After Side-by-Side
                          Row(
                            children: [
                              // Nilai Lama (Sebelum)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFEF4444).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userProf.tr('timeline_old_val'),
                                        style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        oldVal,
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Icon(Icons.arrow_forward, size: 16, color: AppColors.slate),
                              ),

                              // Nilai Baru (Sesudah)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userProf.tr('timeline_new_val'),
                                        style: const TextStyle(
                                          color: Color(0xFF059669),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        newVal,
                                        style: TextStyle(
                                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navySlate,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(userProf.tr('btn_close'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
