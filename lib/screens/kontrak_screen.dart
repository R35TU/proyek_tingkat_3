import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';
import 'package:tata_saka_app/utils/web_navigation.dart';

class KontrakScreen extends StatefulWidget {
  final bool isEmbedded;
  const KontrakScreen({super.key, this.isEmbedded = false});

  @override
  State<KontrakScreen> createState() => _KontrakScreenState();
}

class _KontrakScreenState extends State<KontrakScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double _calcKegiatanProgress(Map<String, dynamic> keg) =>
      ProgressCalculator.calculateKegiatanProgress(keg);

  @override
  Widget build(BuildContext context) {
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final safeUserProf = userProf ?? UserProfileProvider();
    final contractProv = Provider.of<ContractProvider>(context);
    final allContracts = contractProv.contracts;

    final isKontraktor = safeUserProf.isKontraktor;
    final isDinas = safeUserProf.isDinas;
    final isKonsultan = safeUserProf.isKonsultan;

    final String titleText = isKontraktor ? 'Kegiatan Saya' : 'Daftar Kontrak';
    final String hintSearch = isKontraktor ? 'Cari Kegiatan...' : 'Cari Kontrak...';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              surfaceTintColor: Colors.transparent,
              title: Text(
                titleText,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search Box
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: hintSearch,
                        hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 13.5),
                        prefixIcon: const Icon(Icons.search, color: AppColors.textLight),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Tombol Tambah Kontrak Baru: HANYA DITAMPILKAN UNTUK KONSULTAN
            if (isKonsultan) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TambahKontrakScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Kontrak Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),

            // Content List
            Expanded(
              child: isKontraktor
                  ? _buildContractorKegiatanList(context, safeUserProf, allContracts)
                  : _buildContractList(context, isKonsultan, isDinas, safeUserProf, allContracts),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAMPILAN KHUSUS KONTRAKTOR: HANYA KEGIATAN MEREKA ───
  Widget _buildContractorKegiatanList(
    BuildContext context,
    UserProfileProvider userProf,
    List<ContractModel> allContracts,
  ) {
    final contractorName = userProf.namaLengkap.toLowerCase();
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final searchQuery = _searchController.text.trim().toLowerCase();

    final List<Map<String, dynamic>> myKegiatans = [];
    final List<int> kegIndices = [];
    final List<ContractModel> parentContracts = [];

    for (final c in allContracts) {
      for (int i = 0; i < c.kegiatans.length; i++) {
        final k = c.kegiatans[i];
        final kKontraktor = (k['kontraktor'] ?? '').toString().toLowerCase();
        final kKontraktorUid = (k['kontraktorUid'] ?? '').toString();
        final kNama = (k['namaKegiatan'] ?? '').toString().toLowerCase();

        bool isMine = false;
        // FIRST: try matching by kontraktorUid (Firebase Auth UID)
        if (currentUserUid.isNotEmpty && kKontraktorUid.isNotEmpty && kKontraktorUid == currentUserUid) {
          isMine = true;
        }

        // FALLBACK: name-based matching for backward compatibility
        if (!isMine && kKontraktor.isNotEmpty) {
          if (kKontraktor.contains(contractorName) || contractorName.contains(kKontraktor)) {
            isMine = true;
          } else if (contractorName.contains('divan') && kKontraktor.contains('divan')) {
            isMine = true;
          } else if (contractorName.contains('langgeng') && kKontraktor.contains('langgeng')) {
            isMine = true;
          }
        }

        if (isMine) {
          if (searchQuery.isEmpty || kNama.contains(searchQuery)) {
            myKegiatans.add(k);
            kegIndices.add(i);
            parentContracts.add(c);
          }
        }
      }
    }

    if (myKegiatans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_late_outlined, size: 52, color: AppColors.slate),
            const SizedBox(height: 12),
            const Text(
              'Belum Ada Kegiatan Ditugaskan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navySlate),
            ),
            const SizedBox(height: 6),
            Text(
              'Kegiatan yang ditugaskan kepada ${userProf.namaLengkap} akan tampil di sini.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.slate, fontSize: 12.5),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: myKegiatans.length,
      itemBuilder: (context, idx) {
        final k = myKegiatans[idx];
        final parentContract = parentContracts[idx];
        final kIndex = kegIndices[idx];
        final prog = _calcKegiatanProgress(k);

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailKegiatanScreen(
                      contract: parentContract,
                      kegiatanIndex: kIndex,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
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
                          child: const Icon(Icons.assignment, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                k['namaKegiatan'] ?? 'Nama Kegiatan',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${k['lokasi'] ?? '-'} • ${k['sumberDana'] ?? 'APBD'}',
                                style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.textLight),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Nilai Kontrak Kegiatan:', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                        Text(
                          (k['nilaiKontrak'] ?? '-').toString(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.navySlate),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: prog / 100.0,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.navySlate),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${prog.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.navySlate),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── TAMPILAN DAFTAR KONTRAK UNTUK KONSULTAN DAN DINAS ───
  Widget _buildContractList(
    BuildContext context,
    bool isKonsultan,
    bool isDinas,
    UserProfileProvider userProf,
    List<ContractModel> allContracts,
  ) {
    final searchQuery = _searchController.text.trim().toLowerCase();

    List<ContractModel> filteredContracts = allContracts;
    if (isDinas) {
      filteredContracts = filteredContracts.where((c) {
        return c.isOwnedByDinas(
          dinasUserUid: userProf.uid,
          companyOrAgency: userProf.companyOrAgency,
          userFullName: userProf.namaLengkap,
        );
      }).toList();
    }

    if (searchQuery.isNotEmpty) {
      filteredContracts = filteredContracts.where((c) {
        return c.namaKontrak.toLowerCase().contains(searchQuery) ||
            c.nomorSpk.toLowerCase().contains(searchQuery);
      }).toList();
    }

    if (filteredContracts.isEmpty) {
      return const Center(child: Text('Belum ada kontrak yang sesuai.'));
    }

    return ListView.builder(
      itemCount: filteredContracts.length,
      itemBuilder: (context, index) {
        final contract = filteredContracts[index];
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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (kIsWeb) {
                  replaceWebUrl('/#/detail-kontrak?id=${contract.id}&tab=0');
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: RouteSettings(
                      name: '/detail-kontrak?id=${contract.id}&tab=0',
                    ),
                    builder: (context) => DetailKontrakScreen(contract: contract),
                  ),
                ).then((_) {
                  if (kIsWeb && mounted) {
                    replaceWebUrl('/#/kontrak');
                  }
                });
              },
              onLongPress: isKonsultan ? () => _showContractOptions(context, contract) : null,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                        // Opsi Menu Edit/Hapus Kontrak HANYA untuk Konsultan
                        if (isKonsultan)
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textLight),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _showContractOptions(context, contract),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contract.nomorSpk.isNotEmpty ? contract.nomorSpk : '-',
                      style: const TextStyle(
                        color: AppColors.textLight,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F4EA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.successGreen),
                              const SizedBox(width: 6),
                              Text(
                                contract.status == 'Selesai' ? 'Selesai' : 'Progres',
                                style: const TextStyle(
                                  color: AppColors.successGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(contract.progressFisik * 100).toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: contract.progressFisik,
                        backgroundColor: AppColors.inputBackground,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showContractOptions(BuildContext context, ContractModel contract) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                title: const Text('Edit Kontrak', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TambahKontrakScreen(contractToEdit: contract),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Kontrak', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteContract(context, contract);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteContract(BuildContext context, ContractModel contract) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kontrak', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus kontrak "${contract.namaKontrak}"?\nSeluruh data kegiatan di dalamnya akan ikut terhapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<ContractProvider>(context, listen: false).deleteContract(contract.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kontrak berhasil dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
