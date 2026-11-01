import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';

class DataLaporanScreen extends StatefulWidget {
  const DataLaporanScreen({super.key});

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

  void _showPilihKegiatanSheet(BuildContext context, ContractModel contract) {
    if (contract.kegiatans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada kegiatan pada kontrak ini. Silakan tambahkan kegiatan di menu Kontrak.'),
        ),
      );
      return;
    }

    if (contract.kegiatans.length == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetailDataLaporanScreen(
            contract: contract,
            kegiatanIndex: 0,
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
                        style: const TextStyle(color: AppColors.textLight, fontSize: 13),
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
                    itemCount: contract.kegiatans.length,
                    separatorBuilder: (context, i) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final k = contract.kegiatans[i];
                      final nama = k['namaKegiatan'] ?? 'Kegiatan ${i + 1}';
                      final lokasi = k['lokasi'] ?? '-';
                      final kontraktor = k['kontraktor'] ?? '-';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.work_outline, color: AppColors.primaryBlue, size: 20),
                        ),
                        title: Text(
                          nama,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Lokasi: $lokasi • Kontraktor: $kontraktor',
                            style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailDataLaporanScreen(
                                contract: contract,
                                kegiatanIndex: i,
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
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
      body: Column(
        children: [
          // Search Bar Only (Filter Tabs Removed per user request)
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
                          icon: const Icon(Icons.clear, color: AppColors.textLight, size: 20),
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

          // List Data Laporan (Grouped by Contract with direct Kegiatan selection)
          Expanded(
            child: Consumer<ContractProvider>(
              builder: (context, provider, child) {
                if (provider.contracts.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Belum ada kontrak untuk dilapor.\nTambahkan kontrak baru pada menu Kontrak.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textLight, height: 1.4),
                      ),
                    ),
                  );
                }

                // Filter contracts and activities based on search query
                final filteredContracts = provider.contracts.where((c) {
                  if (_searchQuery.isEmpty) return true;
                  final matchContract = c.namaKontrak.toLowerCase().contains(_searchQuery) ||
                      c.nomorSpk.toLowerCase().contains(_searchQuery);
                  final matchKegiatan = c.kegiatans.any((k) {
                    final nama = (k['namaKegiatan'] ?? '').toString().toLowerCase();
                    final lokasi = (k['lokasi'] ?? '').toString().toLowerCase();
                    return nama.contains(_searchQuery) || lokasi.contains(_searchQuery);
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
                    return _buildContractCard(contract);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractCard(ContractModel contract) {
    int progressPercentage = (contract.progressFisik * 100).toInt();
    final kegiatans = contract.kegiatans;

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
            onTap: () => _showPilihKegiatanSheet(context, contract),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${kegiatans.length} Kegiatan',
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.circle, size: 8, color: AppColors.successGreen),
                            const SizedBox(width: 4),
                            Text(
                              contract.status == 'Selesai' ? 'Selesai' : 'Progres',
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
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
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
          if (kegiatans.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: AppColors.textLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Belum ada kegiatan pada kontrak ini.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            )
          else
            ...kegiatans.asMap().entries.map((entry) {
              final kIndex = entry.key;
              final k = entry.value;
              final namaKegiatan = k['namaKegiatan'] ?? 'Kegiatan ${kIndex + 1}';
              final lokasi = k['lokasi'] ?? '-';
              final kontraktor = k['kontraktor'] ?? '-';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailDataLaporanScreen(
                        contract: contract,
                        kegiatanIndex: kIndex,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: kIndex < kegiatans.length - 1
                          ? const BorderSide(color: Color(0xFFF1F5F9))
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.work_outline, color: AppColors.primaryBlue, size: 18),
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                            Icon(Icons.chevron_right, size: 14, color: AppColors.primaryBlue),
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
