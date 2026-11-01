import 'package:flutter/material.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';
import 'package:tata_saka_app/screens/detail_kontrak_screen.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';

class KontrakScreen extends StatelessWidget {
  const KontrakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: AppColors.textDark),
          onPressed: () {},
        ),
        title: const Text(
          'Daftar Kontrak',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Search and Filter
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Cari Kontrak..',
                        hintStyle: TextStyle(color: AppColors.textLight),
                        prefixIcon: Icon(Icons.search, color: AppColors.textLight),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.filter_alt_outlined, color: AppColors.primaryBlue),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tambah Kontrak Button
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
            const SizedBox(height: 24),

            // Contract List
            Expanded(
              child: Consumer<ContractProvider>(
                builder: (context, provider, child) {
                  if (provider.contracts.isEmpty) {
                    return const Center(child: Text('Belum ada kontrak.'));
                  }
                  return ListView.builder(
                    itemCount: provider.contracts.length,
                    itemBuilder: (context, index) {
                      final contract = provider.contracts[index];
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
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DetailKontrakScreen(contract: contract),
                                ),
                              );
                            },
                            onLongPress: () {
                              _showContractOptions(context, contract);
                            },
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
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
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
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE6F4EA), // Light green
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
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${contract.kegiatans.length} Kegiatan',
                                        style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
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
                },
              ),
            ),
          ],
        ),
      ),
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
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  contract.namaKontrak,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(),
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
