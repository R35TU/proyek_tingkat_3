import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';

class DataLaporanScreen extends StatefulWidget {
  final bool isEmbedded;
  const DataLaporanScreen({super.key, this.isEmbedded = false});

  @override
  State<DataLaporanScreen> createState() => _DataLaporanScreenState();
}

class _DataLaporanScreenState extends State<DataLaporanScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isKegiatanOwnedByContractor(
    Map<String, dynamic> k,
    UserProfileProvider userProf,
  ) {
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final kKontraktorUid = (k['kontraktorUid'] ?? '').toString();

    // FIRST: match by kontraktorUid
    if (currentUserUid.isNotEmpty && kKontraktorUid.isNotEmpty && kKontraktorUid == currentUserUid) {
      return true;
    }

    final contractorName = userProf.namaLengkap.toLowerCase();
    final kKontraktor = (k['kontraktor'] ?? '').toString().toLowerCase();
    if (kKontraktor.isEmpty) return false;
    if (kKontraktor.contains(contractorName) ||
        contractorName.contains(kKontraktor)) {
      return true;
    }
    if (contractorName.contains('divan') && kKontraktor.contains('divan')) {
      return true;
    }
    if (contractorName.contains('langgeng') &&
        kKontraktor.contains('langgeng')) {
      return true;
    }
    return false;
  }

  void _showPilihKegiatanSheet(
    BuildContext context,
    ContractModel contract,
    UserProfileProvider userProf,
  ) {
    final visibleIndices = <int>[];
    for (int i = 0; i < contract.kegiatans.length; i++) {
      if (!userProf.isKontraktor ||
          _isKegiatanOwnedByContractor(contract.kegiatans[i], userProf)) {
        visibleIndices.add(i);
      }
    }

    if (visibleIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Belum ada kegiatan pada kontrak ini. Silakan tambahkan kegiatan di menu Kontrak.',
          ),
        ),
      );
      return;
    }

    if (visibleIndices.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailDataLaporanScreen(
            contract: contract,
            kegiatanIndex: visibleIndices.first,
          ),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pilih Kegiatan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        contract.namaKontrak,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: visibleIndices.length,
                    separatorBuilder: (context, idx) =>
                        const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final originalIndex = visibleIndices[idx];
                      final k = contract.kegiatans[originalIndex];
                      final nama =
                          k['namaKegiatan'] ?? 'Kegiatan ${originalIndex + 1}';
                      final lokasi = k['lokasi'] ?? '-';
                      final kontraktor = k['kontraktor'] ?? '-';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.slateLighter,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.work_outline,
                            color: AppColors.primaryBlue,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Lokasi: $lokasi • Kontraktor: $kontraktor',
                            style: const TextStyle(
                              color: AppColors.textLight,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.textLight,
                        ),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailDataLaporanScreen(
                                contract: contract,
                                kegiatanIndex: originalIndex,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    final mainBody = Column(
        children: [
          // Search Bar Only
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: AppColors.textLight),
                  hintText: 'Cari Proyek atau Kegiatan..',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: AppColors.textLight),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: AppColors.textLight,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),

          // List Data Laporan
          Expanded(
            child: Consumer2<ContractProvider, UserProfileProvider>(
              builder: (context, provider, userProf, child) {
                var baseContracts = provider.contracts;
                if (userProf.isDinas) {
                  baseContracts = baseContracts.where((c) {
                    return c.instansiDinas.any((d) {
                      final din = d.toUpperCase();
                      return din.contains('DPU-PR') ||
                          din.contains('DINAS') ||
                          din.contains('PURBALINGGA');
                    });
                  }).toList();
                } else if (userProf.isKontraktor) {
                  baseContracts = baseContracts.where((c) {
                    return c.kegiatans.any(
                      (k) => _isKegiatanOwnedByContractor(k, userProf),
                    );
                  }).toList();
                }

                if (baseContracts.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        userProf.isDinas
                            ? 'Tidak ada kontrak yang terdaftar untuk instansi dinas Anda.'
                            : (userProf.isKontraktor
                                  ? 'Belum ada kegiatan pelaporan yang ditugaskan kepada Anda.'
                                  : 'Belum ada kontrak untuk dilapor.\nTambahkan kontrak baru pada menu Kontrak.'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          height: 1.4,
                        ),
                      ),
                    ),
                  );
                }

                // Filter contracts and activities based on search query
                final filteredContracts = baseContracts.where((c) {
                  if (_searchQuery.isEmpty) return true;
                  final matchContract =
                      c.namaKontrak.toLowerCase().contains(_searchQuery) ||
                      c.nomorSpk.toLowerCase().contains(_searchQuery);
                  final matchKegiatan = c.kegiatans.any((k) {
                    if (userProf.isKontraktor &&
                        !_isKegiatanOwnedByContractor(k, userProf)) {
                      return false;
                    }
                    final nama = (k['namaKegiatan'] ?? '')
                        .toString()
                        .toLowerCase();
                    final lokasi = (k['lokasi'] ?? '').toString().toLowerCase();
                    return nama.contains(_searchQuery) ||
                        lokasi.contains(_searchQuery);
                  });
                  return matchContract || matchKegiatan;
                }).toList();

                if (filteredContracts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Tidak ditemukan proyek atau kegiatan yang cocok.',
                        style: TextStyle(color: AppColors.textLight),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredContracts.length,
                  itemBuilder: (context, index) {
                    final contract = filteredContracts[index];
                    return _buildContractCard(contract, userProf);
                  },
                );
              },
            ),
          ),
        ],
      );

    if (widget.isEmbedded) {
      return mainBody;
    }

    if (isDesktop) {
      return WebDashboardLayout(
        title: 'Data Laporan',
        activeMenu: 'data_laporan',
        showBackButton: true,
        child: mainBody,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
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
        title: const Text(
          'Data Laporan',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: mainBody,
    );
  }

  Widget _buildContractCard(
    ContractModel contract,
    UserProfileProvider userProf,
  ) {
    int progressPercentage = (contract.progressFisik * 100).toInt();
    final visibleEntries = contract.kegiatans.asMap().entries.where((entry) {
      if (!userProf.isKontraktor) return true;
      return _isKegiatanOwnedByContractor(entry.value, userProf);
    }).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contract Header
          InkWell(
            onTap: () => _showPilihKegiatanSheet(context, contract, userProf),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contract.namaKontrak,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'SPK: ${contract.nomorSpk.isNotEmpty ? contract.nomorSpk : '-'}',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slateLighter,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${visibleEntries.length} Kegiatan',
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 8,
                              color: AppColors.successGreen,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              contract.status == 'Selesai'
                                  ? 'Selesai'
                                  : 'Progres',
                              style: const TextStyle(
                                color: AppColors.successGreen,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: contract.progressFisik,
                            backgroundColor: AppColors.inputBackground,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primaryBlue,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$progressPercentage%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Divider(height: 1),

          // Daftar Kegiatan List
          if (visibleEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Belum ada kegiatan pada kontrak ini.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ...visibleEntries.asMap().entries.map((listEntry) {
              final listIdx = listEntry.key;
              final originalIndex = listEntry.value.key;
              final k = listEntry.value.value;
              final namaKegiatan =
                  k['namaKegiatan'] ?? 'Kegiatan ${originalIndex + 1}';
              final lokasi = k['lokasi'] ?? '-';
              final kontraktor = k['kontraktor'] ?? '-';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailDataLaporanScreen(
                        contract: contract,
                        kegiatanIndex: originalIndex,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: listIdx < visibleEntries.length - 1
                          ? const BorderSide(color: Color(0xFFF1F5F9))
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.slateLighter,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.work_outline,
                          color: AppColors.primaryBlue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              namaKegiatan,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Lokasi: $lokasi ${kontraktor != '-' ? '• $kontraktor' : ''}',
                              style: const TextStyle(
                                color: AppColors.textLight,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Laporan',
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: AppColors.primaryBlue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
