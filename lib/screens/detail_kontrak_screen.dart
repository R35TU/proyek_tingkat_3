import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';
import 'package:tata_saka_app/screens/form_kegiatan_screen.dart';

class _DocumentData {
  String name;
  String type;
  _DocumentData({required this.name, required this.type});
}

class _FolderData {
  String name;
  bool isExpanded;
  List<_DocumentData> documents;
  _FolderData({required this.name, this.isExpanded = false, List<_DocumentData>? documents}) 
    : documents = documents ?? [];
}

class _KegiatanData {
  Map<String, dynamic> data;

  _KegiatanData({required this.data});

  String get name => data['namaKegiatan'] ?? '';
  set name(String val) => data['namaKegiatan'] = val;

  String get lokasi => data['lokasi'] ?? '';
  set lokasi(String val) => data['lokasi'] = val;

  String get kontraktor => data['kontraktor'] ?? '';
  set kontraktor(String val) => data['kontraktor'] = val;

  String get nilaiKontrak => data['nilaiKontrak'] ?? '';
  set nilaiKontrak(String val) => data['nilaiKontrak'] = val;

  dynamic get foldersRaw => data['folders'];
  set foldersRaw(dynamic val) {
    if (val != null) {
      data['folders'] = val;
    } else {
      data.remove('folders');
    }
  }
}

class DetailKontrakScreen extends StatefulWidget {
  final ContractModel contract;

  const DetailKontrakScreen({super.key, required this.contract});

  @override
  State<DetailKontrakScreen> createState() => _DetailKontrakScreenState();
}

class _DetailKontrakScreenState extends State<DetailKontrakScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<_FolderData> _folders;
  late List<_KegiatanData> _kegiatans;

  @override
  void initState() {
    super.initState();
    
    // Load Folders
    _folders = widget.contract.folders.map((f) {
      return _FolderData(
        name: f['name'] ?? '',
        isExpanded: f['isExpanded'] ?? false,
        documents: (f['documents'] as List<dynamic>?)?.map((d) {
          return _DocumentData(
            name: d['name'] ?? '',
            type: d['type'] ?? 'PDF',
          );
        }).toList() ?? [],
      );
    }).toList();

    // Load Kegiatans directly from contract
    _kegiatans = widget.contract.kegiatans.map((k) {
      return _KegiatanData(data: Map<String, dynamic>.from(k));
    }).toList();

    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB visibility
    });
  }

  void _saveToProvider() {
    widget.contract.folders = _folders.map((f) => {
      'name': f.name,
      'isExpanded': f.isExpanded,
      'documents': f.documents.map((d) => {
        'name': d.name,
        'type': d.type,
      }).toList(),
    }).toList();

    widget.contract.kegiatans = _kegiatans.map((k) => Map<String, dynamic>.from(k.data)).toList();

    Provider.of<ContractProvider>(context, listen: false).updateContract(widget.contract);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addFolder() {
    showDialog(
      context: context,
      builder: (context) {
        String newName = '';
        return AlertDialog(
          title: const Text('Tambah Folder Baru', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            onChanged: (val) => newName = val,
            decoration: InputDecoration(
              hintText: 'Nama Folder',
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.isNotEmpty) {
                  setState(() {
                    _folders.add(_FolderData(name: newName));
                    _saveToProvider();
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _editFolder(int index) {
    showDialog(
      context: context,
      builder: (context) {
        String newName = _folders[index].name;
        return AlertDialog(
          title: const Text('Ubah Nama Folder', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextFormField(
            initialValue: newName,
            onChanged: (val) => newName = val,
            decoration: InputDecoration(
              hintText: 'Nama Folder',
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newName.isNotEmpty) {
                  setState(() {
                    _folders[index].name = newName;
                    _saveToProvider();
                  });
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text('Simpan', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _uploadDocument(int index) {
    String docName = '';
    String docType = 'PDF';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Upload Dokumen (Simulasi)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    onChanged: (val) => docName = val,
                    decoration: InputDecoration(
                      hintText: 'Nama Dokumen',
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: docType,
                    items: ['PDF', 'IMG', 'DOCX'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setDialogState(() => docType = val!),
                    decoration: InputDecoration(
                      labelText: 'Bentuk File',
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                    ),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (docName.isNotEmpty) {
                      setState(() {
                        _folders[index].documents.add(_DocumentData(name: docName, type: docType));
                        _folders[index].isExpanded = true;
                        _saveToProvider();
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                  child: const Text('Upload', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addKegiatan() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FormKegiatanScreen(contract: widget.contract),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _kegiatans.add(_KegiatanData(data: result));
        _saveToProvider();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil ditambahkan')),
      );
    }
  }

  Future<void> _editKegiatan(int index) async {
    final current = _kegiatans[index];
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FormKegiatanScreen(
          contract: widget.contract,
          initialKegiatan: current.data,
          kegiatanIndex: index,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        if (current.data.containsKey('folders')) {
          result['folders'] = current.data['folders'];
        }
        _kegiatans[index] = _KegiatanData(data: result);
        _saveToProvider();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil diperbarui')),
      );
    }
  }

  void _confirmDeleteKegiatan(int index) {
    final kegiatanName = _kegiatans[index].name;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kegiatan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus kegiatan "$kegiatanName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              setState(() {
                _kegiatans.removeAt(index);
                _saveToProvider();
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kegiatan berhasil dihapus')),
              );
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showKegiatanOptions(int index) {
    final kegiatan = _kegiatans[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    kegiatan.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ),
              const Divider(height: 20),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: AppColors.primaryBlue),
                title: const Text('Edit Kegiatan', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(modalContext);
                  _editKegiatan(index);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Kegiatan', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                onTap: () {
                  Navigator.pop(modalContext);
                  _confirmDeleteKegiatan(index);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteContract() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kontrak', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus kontrak "${widget.contract.namaKontrak}"? Semua data kegiatan terkait akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<ContractProvider>(context, listen: false).deleteContract(widget.contract.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Kontrak',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.textDark),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'edit') {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TambahKontrakScreen(contractToEdit: widget.contract),
                  ),
                );
                if (updated == true && mounted) {
                  setState(() {});
                }
              } else if (value == 'delete') {
                _confirmDeleteContract();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryBlue),
                    SizedBox(width: 12),
                    Text('Edit Kontrak', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Hapus Kontrak', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.textLight,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'Umum'),
            Tab(text: 'Administrasi'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUmumTab(),
          _buildAdministrasiTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _addFolder,
              backgroundColor: AppColors.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildUmumTab() {
    final provider = Provider.of<ContractProvider>(context);
    final contract = provider.contracts.firstWhere(
      (c) => c.id == widget.contract.id,
      orElse: () => widget.contract,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progres Badge
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
          const SizedBox(height: 16),

          // Title
          Text(
            contract.namaKontrak,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // SPK Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.description_outlined, size: 16, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'SPK: ${contract.nomorSpk.isNotEmpty ? contract.nomorSpk : '-'}',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Mulai SPK: ${contract.tglMulaiSpk.isNotEmpty ? contract.tglMulaiSpk : '-'}',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // SPMK Info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.assignment_outlined, size: 16, color: AppColors.textLight),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  'SPMK: ${contract.nomorSpmk.isNotEmpty ? contract.nomorSpmk : '-'}',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tanggal SPMK
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Mulai SPMK', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      contract.tglMulaiSpmk.isNotEmpty ? contract.tglMulaiSpmk : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Selesai SPMK', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      contract.tglSelesaiSpmk.isNotEmpty ? contract.tglSelesaiSpmk : '-',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Spesifikasi Kontrak
          const Text(
            'Spesifikasi Kontrak',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildSpecItem('Tipe Kontrak', contract.jenisKegiatan),
                const Divider(height: 1, color: AppColors.border),
                _buildSpecItem('Instansi Jasa', contract.instansiDinas.isNotEmpty ? contract.instansiDinas.join(', ') : '-'),
                const Divider(height: 1, color: AppColors.border),
                _buildSpecItem('Nilai Kontrak', contract.nilaiKontrak.isNotEmpty ? contract.nilaiKontrak : '-'),
                const Divider(height: 1, color: AppColors.border),
                _buildSpecItem('Masa Pelaksanaan', '${contract.hariKalender} Hari Kalender'),
                const Divider(height: 1, color: AppColors.border),
                _buildSpecItem('Sumber Dana', contract.sumberDana),
                const Divider(height: 1, color: AppColors.border),
                _buildSpecItem('Konsultan Pengawas', 'CV. Tata Saka Konsultan'),
                const Divider(height: 1, color: AppColors.border),
                _buildSpecItem('Deskripsi', contract.deskripsi),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Struktur Anggota Konsultan (Tepat di bawah Spesifikasi Kontrak)
          const Text(
            'Struktur Anggota Konsultan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildSpecItem(
                  'Site Engineer',
                  contract.siteEngineer.isNotEmpty ? contract.siteEngineer : '-',
                ),
                const Divider(height: 1, color: AppColors.border),
                if (contract.inspektors.isNotEmpty) ...[
                  for (int i = 0; i < contract.inspektors.length; i++) ...[
                    _buildSpecItem(
                      contract.inspektors.length > 1 ? 'Inspektor ${i + 1}' : 'Inspektor',
                      contract.inspektors[i],
                    ),
                    const Divider(height: 1, color: AppColors.border),
                  ],
                ] else ...[
                  _buildSpecItem('Inspektor', '-'),
                  const Divider(height: 1, color: AppColors.border),
                ],
                _buildSpecItem(
                  'Administrasi',
                  contract.administrasi.isNotEmpty ? contract.administrasi : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Kegiatan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Kegiatan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_kegiatans.length}',
                      style: const TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _addKegiatan,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Icon(Icons.add, size: 16, color: AppColors.primaryBlue),
                          SizedBox(width: 4),
                          Text(
                            'Tambah',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_kegiatans.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Belum ada kegiatan yang didaftarkan pada kontrak ini.\nTekan "+ Tambah" untuk menambahkan kegiatan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textLight, height: 1.4),
              ),
            )
          else
            ..._kegiatans.asMap().entries.map((entry) => _buildKegiatanItem(entry.value, entry.key)),
            
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKegiatanItem(_KegiatanData kegiatan, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailKegiatanScreen(
                  contract: widget.contract,
                  kegiatanIndex: index,
                ),
              ),
            );
            // Refresh on return in case they edited anything inside
            setState(() {
              if (index < widget.contract.kegiatans.length) {
                _kegiatans[index] = _KegiatanData(
                  data: Map<String, dynamic>.from(widget.contract.kegiatans[index]),
                );
              }
            });
          },
          onLongPress: () => _showKegiatanOptions(index),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.work_outline, color: AppColors.primaryBlue, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kegiatan.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              kegiatan.lokasi,
                              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.person_outline, size: 14, color: AppColors.textLight),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Kontraktor: ${kegiatan.kontraktor}',
                              style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      if (kegiatan.nilaiKontrak.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.monetization_on_outlined, size: 12, color: AppColors.successGreen),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  kegiatan.nilaiKontrak,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.successGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.textLight, size: 20),
                  splashRadius: 20,
                  onPressed: () => _showKegiatanOptions(index),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAdministrasiTab() {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        const Text(
          'Folder Administrasi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 16),
        if (_folders.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('Belum ada folder', style: TextStyle(color: AppColors.textLight)),
            ),
          ),
        ..._folders.asMap().entries.map((entry) {
          int index = entry.key;
          _FolderData folder = entry.value;
          return _buildFolderItem(folder, index);
        }),
      ],
    );
  }

  Widget _buildFolderItem(_FolderData folder, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          folder.isExpanded = !folder.isExpanded;
          _saveToProvider();
        });
      },
      onLongPressStart: (details) {
        showMenu(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          items: [
            const PopupMenuItem(
              value: 'upload',
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: AppColors.primaryBlue, size: 20),
                  SizedBox(width: 12),
                  Text('Upload Dokumen', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: AppColors.textDark, size: 20),
                  SizedBox(width: 12),
                  Text('Ubah Nama', style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Hapus Folder', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),
          ],
        ).then((value) {
          if (value == 'delete') {
            setState(() {
              _folders.removeAt(index);
              _saveToProvider();
            });
          } else if (value == 'edit') {
            _editFolder(index);
          } else if (value == 'upload') {
            _uploadDocument(index);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: folder.isExpanded ? AppColors.primaryBlue : AppColors.border, width: folder.isExpanded ? 1.5 : 1),
          boxShadow: folder.isExpanded 
            ? [BoxShadow(color: AppColors.primaryBlue.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))] 
            : null,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: folder.isExpanded ? AppColors.blueLight.withOpacity(0.3) : AppColors.inputBackground,
                borderRadius: folder.isExpanded 
                  ? const BorderRadius.vertical(top: Radius.circular(15))
                  : BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.folder, color: Colors.amber, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: folder.isExpanded ? AppColors.primaryBlue : AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${folder.documents.length} File',
                          style: TextStyle(
                            color: folder.isExpanded ? AppColors.primaryBlue.withOpacity(0.7) : AppColors.textLight,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    folder.isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right, 
                    color: folder.isExpanded ? AppColors.primaryBlue : AppColors.textLight
                  ),
                ],
              ),
            ),
            
            // Expanded Content
            if (folder.isExpanded)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
                ),
                child: folder.documents.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Belum ada dokumen',
                          style: TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic),
                        ),
                      ),
                    )
                  : Column(
                      children: folder.documents.map((doc) => _buildDocItem(doc)).toList(),
                    ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(_DocumentData doc) {
    IconData iconData;
    Color iconColor;

    switch (doc.type) {
      case 'PDF':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'IMG':
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
      case 'DOCX':
        iconData = Icons.description;
        iconColor = Colors.blueAccent;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  doc.type,
                  style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: AppColors.primaryBlue),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Mengunduh ${doc.name}...')));
            },
          ),
        ],
      ),
    );
  }
}
