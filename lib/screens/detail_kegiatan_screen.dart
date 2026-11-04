import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/form_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';

class _DocData {
  String name;
  String type;
  _DocData({required this.name, required this.type});
}

class _FolderData {
  String name;
  bool isExpanded;
  List<_DocData> documents;
  _FolderData({required this.name, this.isExpanded = false, List<_DocData>? documents}) 
    : documents = documents ?? [];
}

class DetailKegiatanScreen extends StatefulWidget {
  final ContractModel contract;
  final int kegiatanIndex;

  const DetailKegiatanScreen({
    super.key, 
    required this.contract, 
    required this.kegiatanIndex,
  });

  @override
  State<DetailKegiatanScreen> createState() => _DetailKegiatanScreenState();
}

class _DetailKegiatanScreenState extends State<DetailKegiatanScreen> {
  late Map<String, dynamic> _kegiatanMap;
  late KegiatanModel _kegiatan;
  late String _namaKegiatan;
  late String _lokasi;
  late List<_FolderData> _folders;
  bool _isExecutiveInfoExpanded = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _kegiatanMap = Map<String, dynamic>.from(widget.contract.kegiatans[widget.kegiatanIndex]);
    _kegiatan = KegiatanModel.fromJson(_kegiatanMap, fallbackContract: widget.contract);
    _namaKegiatan = _kegiatan.namaKegiatan;
    _lokasi = _kegiatan.lokasi;
    
    final List<dynamic>? rawFolders = _kegiatanMap['folders'];
    if (rawFolders != null) {
      _folders = rawFolders.map((f) {
        return _FolderData(
          name: f['name'] ?? '',
          isExpanded: f['isExpanded'] ?? false,
          documents: (f['documents'] as List<dynamic>?)?.map((d) {
            return _DocData(
              name: d['name'] ?? '',
              type: d['type'] ?? 'PDF',
            );
          }).toList() ?? [],
        );
      }).toList();
    } else {
      _folders = [
        _FolderData(name: 'Laporan Harian'),
        _FolderData(name: 'Laporan Mingguan'),
        _FolderData(name: 'Foto Progres'),
      ];
    }
  }

  void _saveToProvider() {
    _kegiatanMap['folders'] = _folders.map((f) => {
      'name': f.name,
      'isExpanded': f.isExpanded,
      'documents': f.documents.map((d) => {
        'name': d.name,
        'type': d.type,
      }).toList(),
    }).toList();

    widget.contract.kegiatans[widget.kegiatanIndex] = _kegiatanMap;
    Provider.of<ContractProvider>(context, listen: false).updateContract(widget.contract);
  }

  void _addFolder() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String newName = '';
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Tambah Folder Kegiatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 16),
              TextField(
                onChanged: (val) => newName = val,
                decoration: InputDecoration(
                  hintText: 'Nama Folder',
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (newName.isNotEmpty) {
                      setState(() {
                        _folders.add(_FolderData(name: newName, isExpanded: true));
                        _saveToProvider();
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Folder', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  void _editFolder(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String newName = _folders[index].name;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 24),
              const Text('Ubah Nama Folder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: newName,
                onChanged: (val) => newName = val,
                decoration: InputDecoration(
                  hintText: 'Nama Folder',
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (newName.isNotEmpty) {
                      setState(() {
                        _folders[index].name = newName;
                        _saveToProvider();
                      });
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }
    );
  }

  void _uploadDocument(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        String docName = '';
        String docType = 'PDF';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                  ),
                  const SizedBox(height: 24),
                  const Text('Upload Dokumen Kegiatan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) => docName = val,
                    decoration: InputDecoration(
                      hintText: 'Nama Dokumen',
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: docType,
                    items: ['PDF', 'IMG', 'DOCX'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setSheetState(() => docType = val!),
                    decoration: InputDecoration(
                      labelText: 'Bentuk File',
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        if (docName.isNotEmpty) {
                          setState(() {
                            _folders[index].documents.add(_DocData(name: docName, type: docType));
                            _folders[index].isExpanded = true;
                            _saveToProvider();
                          });
                        }
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _editKegiatanSelf() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FormKegiatanScreen(
          contract: widget.contract,
          initialKegiatan: _kegiatanMap,
          kegiatanIndex: widget.kegiatanIndex,
        ),
      ),
    );

    if (result != null && mounted) {
      if (_kegiatanMap.containsKey('folders')) {
        result['folders'] = _kegiatanMap['folders'];
      }
      setState(() {
        _kegiatanMap = result;
        _kegiatan = KegiatanModel.fromJson(_kegiatanMap, fallbackContract: widget.contract);
        _namaKegiatan = _kegiatan.namaKegiatan;
        _lokasi = _kegiatan.lokasi;
        widget.contract.kegiatans[widget.kegiatanIndex] = _kegiatanMap;
      });
      Provider.of<ContractProvider>(context, listen: false).updateContract(widget.contract);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data kegiatan berhasil diperbarui')),
      );
    }
  }

  void _confirmDeleteKegiatanSelf() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Kegiatan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus kegiatan "$_namaKegiatan"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              widget.contract.kegiatans.removeAt(widget.kegiatanIndex);
              Provider.of<ContractProvider>(context, listen: false).updateContract(widget.contract);
              Navigator.pop(ctx);
              Navigator.pop(context);
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
          'Detail Kegiatan',
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
            onSelected: (value) {
              if (value == 'edit') {
                _editKegiatanSelf();
              } else if (value == 'delete') {
                _confirmDeleteKegiatanSelf();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20, color: AppColors.primaryBlue),
                    SizedBox(width: 12),
                    Text('Edit Kegiatan', style: TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Hapus Kegiatan', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Info Kegiatan Top Section (Executive Card)
          _buildExecutiveGeneralInfo(),

          const SizedBox(height: 18),

          // Action Card: Rincian Kuantitas & Bobot Pekerjaan (RKK)
          _buildRkkActionCard(),

          const SizedBox(height: 28),

          // Administrasi Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Folder Administrasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.slateLighter,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _addFolder,
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
      ),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (folder.name.toLowerCase().contains('mingguan')) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailDataLaporanScreen(
                                contract: widget.contract,
                                kegiatanIndex: widget.kegiatanIndex,
                                initialTab: 1,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics_outlined, size: 18),
                        label: const Text('Buka Data Ringkasan Mingguan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD97706),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else if (folder.name.toLowerCase().contains('harian')) ...[
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailDataLaporanScreen(
                                contract: widget.contract,
                                kegiatanIndex: widget.kegiatanIndex,
                                initialTab: 0,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: const Text('Buka Data Buku Harian'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (folder.documents.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Belum ada file dokumen tambahan yang diunggah',
                            style: TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ),
                      )
                    else
                      ...folder.documents.map((doc) => _buildDocItem(doc)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(_DocData doc) {
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

  Widget _buildExecutiveGeneralInfo() {
    const Color borderColor = Color(0xFFD1D5DB);
    const Color labelColor = Color(0xFF6B7280);
    const Color valueColor = Color(0xFF111827);
    const Color headerBg = Color(0xFF1F2937);
    const Color sectionBg = Color(0xFFFAFAFA);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — clean, dark, no gradient, just the name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: headerBg,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _namaKegiatan,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isExecutiveInfoExpanded = !_isExecutiveInfoExpanded;
                    });
                  },
                  child: Icon(
                    _isExecutiveInfoExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.white70,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),

          // Sub-header: Lokasi & Sumber Dana as inline text
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 11.5, color: labelColor, height: 1.5),
                      children: [
                        const TextSpan(text: 'Lokasi: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        TextSpan(
                          text: _lokasi.isNotEmpty ? _lokasi : '-',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: valueColor),
                        ),
                        const TextSpan(text: '   •   '),
                        const TextSpan(text: 'Sumber Dana: ', style: TextStyle(fontWeight: FontWeight.w500)),
                        TextSpan(
                          text: _kegiatan.sumberDana.isNotEmpty ? _kegiatan.sumberDana : '-',
                          style: const TextStyle(fontWeight: FontWeight.w600, color: valueColor),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _editKegiatanSelf,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined, size: 13, color: Color(0xFF6B7280)),
                      SizedBox(width: 3),
                      Text(
                        'Edit',
                        style: TextStyle(fontSize: 11, color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_isExecutiveInfoExpanded) ...[
            // SECTION: KONSULTAN PENGAWAS
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: sectionBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section title — simple underlined text
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1)),
                    ),
                    child: const Text(
                      'KONSULTAN PENGAWAS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _kegiatan.konsultanPengawas.isNotEmpty
                        ? _kegiatan.konsultanPengawas
                        : 'CV. TATA SAKA CONSULTANT',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDocRow('No. Kontrak/tanggal', _kegiatan.spkKonsultanFull),
                  _buildDocRow('No. SPMK/tanggal', _kegiatan.spmkKonsultanFull),
                  _buildDocRow('Awal Pelaksanaan', _kegiatan.awalPelaksanaan),
                  _buildDocRow('Akhir Pelaksanaan', _kegiatan.akhirPelaksanaan),
                  _buildDocRow('Masa Pelaksanaan', _kegiatan.masaPelaksanaan),
                ],
              ),
            ),

            // SECTION: PENYEDIA JASA / KONTRAKTOR PELAKSANA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: sectionBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1)),
                    ),
                    child: const Text(
                      'PENYEDIA JASA / KONTRAKTOR PELAKSANA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _kegiatan.kontraktor.isNotEmpty ? _kegiatan.kontraktor : '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: valueColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDocRow('No. Surat pesanan/tanggal', _kegiatan.suratPesananFull),
                  _buildDocRow('No. SMPK/tanggal', _kegiatan.spmkKontraktorFull),
                  _buildDocRow('Jangka Waktu Pelaksanaan', _kegiatan.jangkaWaktu),
                ],
              ),
            ),

            // SECTION: NILAI KONTRAK — simple, no green box, just clean row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: 140,
                    child: Text(
                      'Nilai Kontrak Kegiatan',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: labelColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Text(' :  ', style: TextStyle(fontSize: 11.5, color: labelColor)),
                  Expanded(
                    child: Text(
                      _kegiatan.nilaiKontrak.isNotEmpty ? _kegiatan.nilaiKontrak : '-',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: valueColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SECTION: STRUKTUR ORGANISASI KEGIATAN
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: sectionBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1)),
                    ),
                    child: const Text(
                      'STRUKTUR ORGANISASI KEGIATAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDocRow('Pengguna Anggaran / PPK', _kegiatan.penggunaAnggaran),
                  _buildDocRow(_kegiatan.stafTeknisLabel, _kegiatan.stafTeknisDisplay),
                  _buildDocRow(
                    'Site Engineer',
                    _kegiatan.siteEngineerKegiatan.isNotEmpty
                        ? _kegiatan.siteEngineerKegiatan
                        : widget.contract.siteEngineer,
                  ),
                  _buildDocRow(
                    'Direktur Penyedia Jasa',
                    _kegiatan.direkturPenyedia.isNotEmpty
                        ? _kegiatan.direkturPenyedia
                        : _kegiatan.direkturKontraktor,
                  ),
                ],
              ),
            ),

            // SECTION: STRUKTUR ORGANISASI PENYEDIA JASA
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: sectionBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1)),
                    ),
                    child: const Text(
                      'STRUKTUR ORGANISASI PENYEDIA JASA',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDocRow(
                    'Direktur',
                    _kegiatan.direkturKontraktor.isNotEmpty
                        ? _kegiatan.direkturKontraktor
                        : _kegiatan.direkturPenyedia,
                  ),
                  _buildDocRow('Pelaksana Lapangan', _kegiatan.pelaksanaLapangan),
                  _buildDocRow('Ahli / Petugas K3', _kegiatan.petugasK3),
                ],
              ),
            ),
          ],

          // Progress Bar — always visible, bottom of card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Progres Fisik',
                      style: TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w600, fontSize: 11.5),
                    ),
                    Text(
                      '${_currentProgresFisik.toStringAsFixed(2)}%',
                      style: const TextStyle(color: Color(0xFF374151), fontWeight: FontWeight.w700, fontSize: 11.5),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentProgresFisik / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF374151)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _currentProgresFisik {
    final rawMingguan = _kegiatanMap['laporanMingguan'];
    if (rawMingguan != null && rawMingguan is List && rawMingguan.isNotEmpty) {
      final latest = rawMingguan.last;
      if (latest is Map && latest['realisasiPersen'] != null) {
        return (latest['realisasiPersen'] as num).toDouble();
      }
    }
    return 0.0;
  }

  Widget _buildRkkActionCard() {
    final rawRkk = _kegiatanMap['rkkDivisiList'] as List? ?? [];
    int totalItems = 0;
    double totalBobot = 0.0;
    for (final div in rawRkk) {
      final items = (div['items'] as List? ?? []);
      totalItems += items.length;
      for (final it in items) {
        totalBobot += (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final hasRkk = rawRkk.isNotEmpty && totalItems > 0;
    final is100Percent = (totalBobot - 100.0).abs() < 0.05;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD1D5DB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.assignment_outlined, color: AppColors.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rincian Kuantitas & Bobot Pekerjaan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasRkk
                          ? '${rawRkk.length} Divisi • $totalItems Item Pekerjaan'
                          : 'Belum diisi • Acuan dropdown laporan harian & BoQ mingguan',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textLight),
                    ),
                  ],
                ),
              ),
              if (hasRkk)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: is100Percent ? const Color(0xFFE6F4EA) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${totalBobot.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: is100Percent ? AppColors.successGreen : const Color(0xFFB45309),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onPressed: () async {
                final changed = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KelolaRkkScreen(
                      contract: widget.contract,
                      kegiatanIndex: widget.kegiatanIndex,
                    ),
                  ),
                );
                if (changed == true) {
                  setState(() {
                    _loadData();
                  });
                }
              },
              icon: const Icon(Icons.edit_note, size: 18),
              label: Text(
                hasRkk ? 'Kelola Rincian Pekerjaan (RKK)' : 'Setup Rincian Kuantitas (RKK)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// A clean, document-style label : value row.
  Widget _buildDocRow(String label, String value) {
    const Color labelColor = Color(0xFF6B7280);
    const Color valueColor = Color(0xFF111827);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(' :  ', style: TextStyle(fontSize: 11.5, color: labelColor)),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '-',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: valueColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
