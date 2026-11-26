import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/user_profile_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/services/storage_service.dart';
import 'package:tata_saka_app/services/file_downloader.dart';
import 'package:tata_saka_app/screens/detail_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/tambah_kontrak_screen.dart';
import 'package:tata_saka_app/screens/form_kegiatan_screen.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';
import 'package:tata_saka_app/router/app_router.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';
import 'package:tata_saka_app/utils/web_navigation.dart';

class _DocumentData {
  String id;
  String name;
  String type;
  int sizeBytes;
  String sizeFormatted;
  DateTime uploadDate;
  String? localPath;
  String? remoteUrl;

  _DocumentData({
    String? id,
    required this.name,
    required this.type,
    this.sizeBytes = 0,
    this.sizeFormatted = '',
    DateTime? uploadDate,
    this.localPath,
    this.remoteUrl,
  })  : id = id ?? 'doc_${DateTime.now().millisecondsSinceEpoch}',
        uploadDate = uploadDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'sizeBytes': sizeBytes,
        'sizeFormatted': sizeFormatted,
        'uploadDate': uploadDate.toIso8601String(),
        'localPath': localPath,
        'remoteUrl': remoteUrl,
      };

  factory _DocumentData.fromJson(Map<String, dynamic> json) => _DocumentData(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        type: json['type']?.toString() ?? 'PDF',
        sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] : 0,
        sizeFormatted: json['sizeFormatted']?.toString() ?? '',
        uploadDate: json['uploadDate'] != null
            ? (DateTime.tryParse(json['uploadDate']) ?? DateTime.now())
            : DateTime.now(),
        localPath: json['localPath']?.toString(),
        remoteUrl: json['remoteUrl']?.toString(),
      );
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
  final ContractModel? contract;
  final String? contractId;
  final int initialTabIndex;
  final bool isEmbedded;

  const DetailKontrakScreen({
    super.key,
    this.contract,
    this.contractId,
    this.initialTabIndex = 0,
    this.isEmbedded = false,
  });

  @override
  State<DetailKontrakScreen> createState() => _DetailKontrakScreenState();
}

class _DetailKontrakScreenState extends State<DetailKontrakScreen> with SingleTickerProviderStateMixin {
  ContractModel? _contract;
  ContractModel get contract => _contract ?? widget.contract!;
  bool get _isContractAvailable => _contract != null || widget.contract != null;

  late TabController _tabController;
  List<_FolderData> _folders = [];
  List<_KegiatanData> _kegiatans = [];
  ContractModel? _syncedContractRef;

  ContractModel? _resolveLiveContract({bool listen = false}) {
    final fallback = _contract ?? widget.contract;
    final targetId = fallback?.id ?? widget.contractId;
    if (targetId == null) return fallback;
    try {
      final prov = Provider.of<ContractProvider>(context, listen: listen);
      return prov.contracts.cast<ContractModel?>().firstWhere(
            (c) => c != null && c.id == targetId,
            orElse: () => fallback,
          );
    } catch (_) {
      return fallback;
    }
  }

  void _reloadFromContract(ContractModel c) {
    _contract = c;
    _syncedContractRef = c;
    _folders = c.folders.map((f) {
      return _FolderData(
        name: f['name'] ?? '',
        isExpanded: f['isExpanded'] ?? false,
        documents: (f['documents'] as List<dynamic>?)?.map((d) {
          return _DocumentData.fromJson(Map<String, dynamic>.from(d));
        }).toList() ?? [],
      );
    }).toList();

    _kegiatans = c.kegiatans.map((k) {
      return _KegiatanData(data: Map<String, dynamic>.from(k));
    }).toList();
  }

  @override
  void initState() {
    super.initState();

    if (widget.contract != null) {
      _contract = widget.contract;
      _reloadFromContract(_resolveLiveContract(listen: false) ?? widget.contract!);
    }

    final initTab = (widget.initialTabIndex >= 0 && widget.initialTabIndex < 2)
        ? widget.initialTabIndex
        : 0;
    _tabController = TabController(length: 2, vsync: this, initialIndex: initTab);
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update FAB visibility
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contract == null && widget.contractId != null) {
      final provider = Provider.of<ContractProvider>(context);
      final found = provider.contracts.cast<ContractModel?>().firstWhere(
            (c) => c != null && c.id == widget.contractId,
            orElse: () => null,
          );
      if (found != null) {
        setState(() {
          _reloadFromContract(found);
        });
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _saveToProvider() {
    final live = _resolveLiveContract(listen: false) ?? contract;
    live.folders = _folders.map((f) => {
      'name': f.name,
      'isExpanded': f.isExpanded,
      'documents': f.documents.map((d) => d.toJson()).toList(),
    }).toList();

    live.kegiatans = _kegiatans.map((k) => Map<String, dynamic>.from(k.data)).toList();
    _contract = live;
    _syncedContractRef = live;

    Provider.of<ContractProvider>(context, listen: false).updateContract(live);
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

  void _deleteFolder(int index) {
    if (index < 0 || index >= _folders.length) return;
    final folder = _folders[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Folder?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus folder "${folder.name}" beserta ${folder.documents.length} dokumen di dalamnya? File fisik akan dihapus dari penyimpanan.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final timeline = Provider.of<TimelineProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              for (final doc in folder.documents) {
                if (doc.localPath != null) {
                  try {
                    final f = File(doc.localPath!);
                    if (await f.exists()) await f.delete();
                  } catch (_) {}
                }
              }
              final deletedName = folder.name;
              setState(() {
                _folders.removeAt(index);
                _saveToProvider();
              });
              try {
                timeline.logEvent(
                  actorName: 'CV. Tata Saka Consultant',
                  actionType: 'DELETE',
                  entityType: 'DOKUMEN',
                  contractId: contract.id,
                  contractName: contract.namaKontrak,
                  dinasName: contract.instansiDinas.isNotEmpty
                      ? contract.instansiDinas.first
                      : 'DPU-PR Kab. Purbalingga',
                  title: 'Penghapusan Folder Kontrak: $deletedName',
                  description: 'Folder administrasi kontrak "$deletedName" telah dihapus.',
                );
              } catch (_) {}
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Folder "$deletedName" berhasil dihapus.'),
                  backgroundColor: AppColors.primaryRed,
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument([int? initialFolderIndex]) async {
    if (_folders.isEmpty) {
      _showNeedFolderDialog();
      return;
    }

    int selectedFolderIdx = initialFolderIndex != null && initialFolderIndex >= 0 && initialFolderIndex < _folders.length
        ? initialFolderIndex
        : 0;

    String? pickedFilePath;
    String pickedFileName = '';
    int pickedFileBytes = 0;
    Uint8List? pickedFileBytesData;
    String detectedType = 'PDF';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final nameController = TextEditingController();
        bool isUploading = false;
        String? uploadError;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: SingleChildScrollView(
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
                    const SizedBox(height: 18),
                    const Row(
                      children: [
                        Icon(Icons.cloud_upload_outlined, color: AppColors.primaryBlue, size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Upload Dokumen Kontrak',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih berkas dari perangkat untuk disimpan secara offline pada kontrak ini.',
                      style: TextStyle(fontSize: 12.5, color: AppColors.textLight),
                    ),
                    const SizedBox(height: 18),

                    // Target Folder Dropdown
                    const Text('Folder Tujuan', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.inputBackground,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: selectedFolderIdx,
                          isExpanded: true,
                          items: _folders.asMap().entries.map((e) {
                            return DropdownMenuItem<int>(
                              value: e.key,
                              child: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedFolderIdx = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // File Picker Button
                    const Text('Pilih Berkas Dokumen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 8),

                    if (pickedFilePath == null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  final res = await FilePicker.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'jpeg', 'png', 'zip', 'rar'],
                                  );
                                  if (res.isNotEmpty) {
                                    final f = res.first;
                                    final fSize = (await f.length()) ?? (f.path != null ? File(f.path!).lengthSync() : 0);
                                    if (fSize > 25 * 1024 * 1024) {
                                      setModalState(() => uploadError = 'Ukuran file melebihi batas maksimal 25 MB.');
                                      return;
                                    }
                                    final fBytesData = await f.readAsBytes();
                                    setModalState(() {
                                      uploadError = null;
                                      pickedFilePath = f.path;
                                      pickedFileBytesData = fBytesData;
                                      pickedFileName = f.name;
                                      pickedFileBytes = fSize;
                                      final ext = (f.extension ?? 'PDF').toUpperCase();
                                      detectedType = ext == 'JPG' || ext == 'JPEG' || ext == 'PNG' ? 'IMG' : ext;
                                      nameController.text = f.name.contains('.') ? f.name.substring(0, f.name.lastIndexOf('.')) : f.name;
                                    });
                                  }
                                } catch (e) {
                                  setModalState(() => uploadError = 'Gagal memilih file: $e');
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: AppColors.primaryBlue),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.attach_file, color: AppColors.primaryBlue, size: 20),
                              label: const Text('File Dokumen', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                try {
                                  if (kIsWeb) {
                                    // Web: use FilePicker with image filter (ImagePicker uses dart:io internally)
                                    final res = await FilePicker.pickFiles(
                                      type: FileType.custom,
                                      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'webp'],
                                    );
                                    if (res.isNotEmpty) {
                                      final f = res.first;
                                      final fBytesData = await f.readAsBytes();
                                      final fSize = fBytesData.length;
                                      if (fSize > 25 * 1024 * 1024) {
                                        setModalState(() => uploadError = 'Ukuran gambar melebihi 25 MB.');
                                        return;
                                      }
                                      setModalState(() {
                                        uploadError = null;
                                        pickedFilePath = f.path;
                                        pickedFileBytesData = fBytesData;
                                        pickedFileName = f.name;
                                        pickedFileBytes = fSize;
                                        detectedType = 'IMG';
                                        nameController.text = f.name.contains('.') ? f.name.substring(0, f.name.lastIndexOf('.')) : f.name;
                                      });
                                    }
                                  } else {
                                    final picker = ImagePicker();
                                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                                    if (image != null) {
                                      final fileObj = File(image.path);
                                      final size = await fileObj.length();
                                      if (size > 25 * 1024 * 1024) {
                                        setModalState(() => uploadError = 'Ukuran gambar melebihi 25 MB.');
                                        return;
                                      }
                                      setModalState(() {
                                        uploadError = null;
                                        pickedFilePath = image.path;
                                        pickedFileName = image.name;
                                        pickedFileBytes = size;
                                        detectedType = 'IMG';
                                        nameController.text = image.name.contains('.') ? image.name.substring(0, image.name.lastIndexOf('.')) : image.name;
                                      });
                                    }
                                  }
                                } catch (e) {
                                  setModalState(() => uploadError = 'Gagal memilih foto: $e');
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(color: Color(0xFF0284C7)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.image_outlined, color: Color(0xFF0284C7), size: 20),
                              label: const Text('Foto / Galeri', style: TextStyle(color: Color(0xFF0284C7), fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // File Attached Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pickedFileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textDark),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$detectedType • ${_formatFileSize(pickedFileBytes)}',
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                              onPressed: () {
                                setModalState(() {
                                  pickedFilePath = null;
                                  pickedFileName = '';
                                  pickedFileBytes = 0;
                                  pickedFileBytesData = null;
                                  nameController.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (uploadError != null) ...[
                      const SizedBox(height: 10),
                      Text(uploadError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],

                    const SizedBox(height: 16),
                    const Text('Nama / Judul Dokumen', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textDark)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: 'Contoh: SPK Kontrak Induk Final',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () async {
                                final docTitle = nameController.text.trim();
                                if (docTitle.isEmpty) {
                                  setModalState(() => uploadError = 'Nama dokumen tidak boleh kosong.');
                                  return;
                                }

                                setModalState(() {
                                  isUploading = true;
                                  uploadError = null;
                                });

                                final timeline = Provider.of<TimelineProvider>(context, listen: false);
                                final messenger = ScaffoldMessenger.of(context);
                                final nav = Navigator.of(ctx);

                                try {
                                  String? savedPath;
                                  if (pickedFilePath != null) {
                                    final appDir = await getApplicationDocumentsDirectory();
                                    final docsDir = Directory('${appDir.path}/proyek_dokumen');
                                    if (!await docsDir.exists()) {
                                      await docsDir.create(recursive: true);
                                    }
                                    final cleanName = pickedFileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
                                    final targetFile = File('${docsDir.path}/${DateTime.now().millisecondsSinceEpoch}_$cleanName');
                                    await File(pickedFilePath!).copy(targetFile.path);
                                    savedPath = targetFile.path;
                                  }

                                  // Unggah salinan ke Cloudflare R2 (URL publik).
                                  // Web: tanpa path lokal → pakai bytes dari file_picker.
                                  String? remoteUrl;
                                  Uint8List? uploadBytesData;
                                  if (savedPath != null) {
                                    uploadBytesData = await File(savedPath).readAsBytes();
                                  } else if (pickedFileBytesData != null) {
                                    uploadBytesData = pickedFileBytesData;
                                  }
                                  if (uploadBytesData != null) {
                                    try {
                                      remoteUrl = await StorageService
                                          .uploadBytes(
                                            bytes: uploadBytesData,
                                            remotePath: StorageService.safeObjectPath(
                                                'dokumen/${contract.namaKontrak}/${_folders[selectedFolderIdx].name}/${DateTime.now().millisecondsSinceEpoch}_$pickedFileName'),
                                            contentType: StorageService.detectContentType(pickedFileName),
                                          );
                                    } catch (e) {
                                      debugPrint('[Upload] Gagal unggah ke storage: $e');
                                      if (kIsWeb) {
                                        throw Exception('Gagal mengunggah berkas ke cloud storage: $e');
                                      }
                                    }
                                  }

                                  final formattedSize = _formatFileSize(pickedFileBytes > 0 ? pickedFileBytes : 1024 * 350);
                                  final newDoc = _DocumentData(
                                    id: 'doc_contract_${DateTime.now().millisecondsSinceEpoch}',
                                    name: docTitle,
                                    type: detectedType,
                                    sizeBytes: pickedFileBytes,
                                    sizeFormatted: formattedSize,
                                    uploadDate: DateTime.now(),
                                    localPath: savedPath,
                                    remoteUrl: remoteUrl,
                                  );

                                  final targetFolder = _folders[selectedFolderIdx];
                                  setState(() {
                                    targetFolder.documents.add(newDoc);
                                    targetFolder.isExpanded = true;
                                    _saveToProvider();
                                  });

                                  try {
                                    timeline.logEvent(
                                      actorName: 'CV. Tata Saka Consultant',
                                      actionType: 'UPLOAD',
                                      entityType: 'DOKUMEN',
                                      contractId: contract.id,
                                      contractName: contract.namaKontrak,
                                      dinasName: contract.instansiDinas.isNotEmpty
                                          ? contract.instansiDinas.first
                                          : 'DPU-PR Kab. Purbalingga',
                                      title: 'Unggah Dokumen Kontrak: $docTitle',
                                      description: 'Dokumen $docTitle ($detectedType, $formattedSize) berhasil diunggah ke folder "${targetFolder.name}".',
                                      metadata: {'folder': targetFolder.name, 'size': formattedSize, 'type': detectedType},
                                    );
                                  } catch (_) {}

                                  if (mounted) {
                                    nav.pop();
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Row(
                                          children: [
                                            const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('Dokumen "$docTitle" berhasil diunggah ke "${targetFolder.name}".')),
                                          ],
                                        ),
                                        backgroundColor: AppColors.successGreen,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setModalState(() {
                                    isUploading = false;
                                    uploadError = 'Gagal menyimpan dokumen: $e';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isUploading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Mulai Upload & Simpan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showNeedFolderDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Folder Belum Tersedia', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Silakan buat folder administrasi terlebih dahulu sebelum mengunggah dokumen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _addFolder();
            },
            child: const Text('Buat Folder'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(_FolderData folder, _DocumentData doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus dokumen "${doc.name}"? File fisik akan dihapus permanen dari penyimpanan perangkat.',
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final timeline = Provider.of<TimelineProvider>(context, listen: false);
              final messenger = ScaffoldMessenger.of(context);
              if (doc.localPath != null) {
                try {
                  final f = File(doc.localPath!);
                  if (await f.exists()) await f.delete();
                } catch (_) {}
              }
              setState(() {
                folder.documents.removeWhere((d) => d.id == doc.id);
                _saveToProvider();
              });
              try {
                timeline.logEvent(
                  actorName: 'CV. Tata Saka Consultant',
                  actionType: 'DELETE',
                  entityType: 'DOKUMEN',
                  contractId: contract.id,
                  contractName: contract.namaKontrak,
                  dinasName: contract.instansiDinas.isNotEmpty
                      ? contract.instansiDinas.first
                      : 'DPU-PR Kab. Purbalingga',
                  title: 'Penghapusan Dokumen Kontrak: ${doc.name}',
                  description: 'Dokumen "${doc.name}" telah dihapus dari folder "${folder.name}".',
                );
              } catch (_) {}
              if (!mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text('Dokumen "${doc.name}" berhasil dihapus.'),
                  backgroundColor: AppColors.primaryRed,
                ),
              );
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _previewOrOpenDocument(_DocumentData doc, _FolderData folder, {bool isKonsultan = true}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      doc.type == 'IMG' ? Icons.image : Icons.description,
                      color: AppColors.primaryBlue,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                        const SizedBox(height: 2),
                        Text(
                          '${doc.type} • ${doc.sizeFormatted.isNotEmpty ? doc.sizeFormatted : "1.2 MB"} • Folder ${folder.name}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textLight),
                title: const Text('Waktu Unggah', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                trailing: Text(
                  DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(doc.uploadDate),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.storage_outlined, size: 20, color: AppColors.textLight),
                title: const Text('Status File Fisik', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
                trailing: Text(
                  !kIsWeb && doc.localPath != null && File(doc.localPath!).existsSync()
                      ? 'Tersimpan Offline'
                      : ((doc.remoteUrl ?? '').isNotEmpty
                          ? 'Tersimpan di Cloud'
                          : 'Berkas Tidak Tersedia'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: !kIsWeb && doc.localPath != null && File(doc.localPath!).existsSync()
                        ? Colors.green
                        : ((doc.remoteUrl ?? '').isNotEmpty
                            ? Colors.orange
                            : Colors.red),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        final resolvedName = resolveDocFileName(doc.name, doc.type, doc.remoteUrl ?? doc.localPath);
                        // Web: buka PDF/gambar langsung di tab baru (viewer bawaan browser),
                        // sedangkan file office/arsip (DOC, DOCX, XLS, XLSX, ZIP) langsung diunduh.
                        if (kIsWeb && (doc.remoteUrl ?? '').isNotEmpty) {
                          if (isPreviewableInBrowser(doc.type, doc.remoteUrl)) {
                            openRemoteInNewTab(doc.remoteUrl!);
                          } else {
                            downloadAndOpenRemote(doc.remoteUrl!, resolvedName).catchError((e) {
                              if (!mounted) return null;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Gagal mengunduh dokumen: $e')),
                              );
                              return null;
                            });
                          }
                          return;
                        }
                        if (doc.type == 'IMG' && doc.localPath != null && File(doc.localPath!).existsSync()) {
                          showDialog(
                            context: context,
                            builder: (dCtx) => Dialog(
                              backgroundColor: Colors.transparent,
                              insetPadding: const EdgeInsets.all(12),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: InteractiveViewer(
                                      child: Image.file(File(doc.localPath!), fit: BoxFit.contain),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const CircleAvatar(backgroundColor: Colors.black54, child: Icon(Icons.close, color: Colors.white, size: 20)),
                                    onPressed: () => Navigator.pop(dCtx),
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (doc.localPath != null && File(doc.localPath!).existsSync()) {
                          OpenFilex.open(doc.localPath!);
                        } else if ((doc.remoteUrl ?? '').isNotEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mengunduh dokumen dari penyimpanan awan...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          downloadAndOpenRemote(doc.remoteUrl!, resolvedName).catchError((e) {
                            if (!mounted) return null;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal membuka dokumen: $e')),
                            );
                            return null;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('File fisik dokumen belum tersedia di penyimpanan lokal.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.open_in_new, size: 18),
                      label: const Text('Buka Dokumen', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (isKonsultan) ...[
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _deleteDocument(folder, doc);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addKegiatan() async {
    final live = _resolveLiveContract(listen: false) ?? contract;
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FormKegiatanScreen(contract: live),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _kegiatans.add(_KegiatanData(data: result));
        _saveToProvider();
      });
      try {
        final timeline = Provider.of<TimelineProvider>(context, listen: false);
        timeline.logEvent(
          actorName: 'CV. Tata Saka Consultant',
          actionType: 'CREATE',
          entityType: 'KEGIATAN',
          contractId: contract.id,
          contractName: contract.namaKontrak,
          kegiatanName: result['namaKegiatan'] ?? '',
          kontraktorName: result['kontraktor'] ?? '',
          dinasName: contract.instansiDinas.isNotEmpty
              ? contract.instansiDinas.first
              : 'DPU-PR Kab. Purbalingga',
          title: 'Penetapan Kegiatan: ${result['namaKegiatan']}',
          description: 'Kegiatan ${result['namaKegiatan']} ditambahkan pada kontrak ${contract.namaKontrak}.',
        );
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil ditambahkan')),
      );
    }
  }

  Future<void> _editKegiatan(int index) async {
    final live = _resolveLiveContract(listen: false) ?? contract;
    final current = _kegiatans[index];
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => FormKegiatanScreen(
          contract: live,
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
      try {
        final timeline = Provider.of<TimelineProvider>(context, listen: false);
        timeline.logEvent(
          actorName: 'CV. Tata Saka Consultant',
          actionType: 'UPDATE',
          entityType: 'KEGIATAN',
          contractId: contract.id,
          contractName: contract.namaKontrak,
          kegiatanName: result['namaKegiatan'] ?? '',
          kontraktorName: result['kontraktor'] ?? '',
          dinasName: contract.instansiDinas.isNotEmpty
              ? contract.instansiDinas.first
              : 'DPU-PR Kab. Purbalingga',
          title: 'Pembaruan Data Kegiatan: ${result['namaKegiatan']}',
          description: 'Informasi umum kegiatan ${result['namaKegiatan']} diperbarui.',
        );
      } catch (_) {}
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kegiatan berhasil diperbarui')),
      );
    }
  }

  void _confirmDeleteKegiatan(int index) {
    final kegiatanName = _kegiatans[index].name;
    final kontraktor = _kegiatans[index].data['kontraktor']?.toString() ?? '';
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
              try {
                final timeline = Provider.of<TimelineProvider>(context, listen: false);
                timeline.logEvent(
                  actorName: 'CV. Tata Saka Consultant',
                  actionType: 'DELETE',
                  entityType: 'KEGIATAN',
                  contractId: contract.id,
                  contractName: contract.namaKontrak,
                  kegiatanName: kegiatanName,
                  kontraktorName: kontraktor,
                  dinasName: contract.instansiDinas.isNotEmpty
                      ? contract.instansiDinas.first
                      : 'DPU-PR Kab. Purbalingga',
                  title: 'Penghapusan Kegiatan: $kegiatanName',
                  description: 'Kegiatan $kegiatanName telah dihapus dari kontrak.',
                );
              } catch (_) {}
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
        content: Text('Apakah Anda yakin ingin menghapus kontrak "${contract.namaKontrak}"? Semua data kegiatan terkait akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppColors.textLight)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final deletedContract = contract;
              final contractProv = Provider.of<ContractProvider>(context, listen: false);
              final userProf = Provider.of<UserProfileProvider>(context, listen: false);
              final timeline = Provider.of<TimelineProvider>(context, listen: false);
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              final actorName = userProf.namaLengkap.trim().isNotEmpty
                  ? userProf.namaLengkap.trim()
                  : 'CV. Tata Saka Consultant';
              final actorRole = userProf.role.trim().isNotEmpty ? userProf.role.trim() : 'Konsultan';

              try {
                await timeline.logEvent(
                  actorName: actorName,
                  actorRole: actorRole,
                  actionType: 'DELETE',
                  entityType: 'KONTRAK',
                  contractId: deletedContract.id,
                  contractName: deletedContract.namaKontrak,
                  dinasName: deletedContract.instansiDinas.isNotEmpty
                      ? deletedContract.instansiDinas.first
                      : null,
                  title: 'Penghapusan Kontrak: ${deletedContract.namaKontrak}',
                  description: 'Kontrak "${deletedContract.namaKontrak}" beserta seluruh kegiatan dan laporannya telah dihapus dari sistem.',
                );
              } catch (e) {
                debugPrint('Gagal mencatat timeline penghapusan kontrak: $e');
              }
              await contractProv.deleteContract(deletedContract.id);
              if (!mounted || !ctx.mounted) return;
              Navigator.pop(ctx);
              if (GoRouter.maybeOf(context) != null) {
                goBackOrParent(context, '/kontrak');
              } else {
                nav.pop();
              }
              messenger.showSnackBar(
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
    final contractProvider = Provider.of<ContractProvider>(context);
    if (_isContractAvailable) {
      final live = _resolveLiveContract(listen: false);
      if (live != null && !identical(live, _syncedContractRef)) {
        _reloadFromContract(live);
      }
    }

    if (!_isContractAvailable) {
      if (contractProvider.isLoading) {
        return const Scaffold(
          backgroundColor: Colors.white,
          body: Center(child: CircularProgressIndicator()),
        );
      }
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => goBackOrParent(context, '/kontrak'),
          ),
          title: const Text('Detail Kontrak'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('Data kontrak tidak ditemukan atau belum dimuat.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => goBackOrParent(context, '/kontrak'),
                child: const Text('Kembali ke Daftar Kontrak'),
              ),
            ],
          ),
        ),
      );
    }

    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final isKonsultan = userProf?.isKonsultan ?? true;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    final headerActions = [
      if (isKonsultan)
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: (isDesktop && !widget.isEmbedded) ? Colors.white : AppColors.textDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) async {
            if (value == 'edit') {
              final live = _resolveLiveContract(listen: false) ?? contract;
              final router = GoRouter.maybeOf(context);
              if (router != null) {
                router.go('/kontrak/${live.id}/edit', extra: live);
              } else {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TambahKontrakScreen(contractToEdit: live),
                  ),
                );
                if (updated == true && mounted) {
                  setState(() {
                    _reloadFromContract(_resolveLiveContract(listen: false) ?? contract);
                  });
                }
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
    ];

    final tabBarWidget = Container(
      color: Colors.white,
      child: TabBar(
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
    );

    final mainBody = Column(
      children: [
        if (isDesktop || widget.isEmbedded) ...[
          tabBarWidget,
          const Divider(height: 1, thickness: 1, color: AppColors.border),
        ],
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildUmumTab(),
              _buildAdministrasiTab(),
            ],
          ),
        ),
      ],
    );

    final fab = (_tabController.index == 1 && isKonsultan)
        ? FloatingActionButton(
            onPressed: _addFolder,
            backgroundColor: AppColors.primaryBlue,
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null;

    if (widget.isEmbedded) {
      return mainBody;
    }

    if (isDesktop) {
      return WebDashboardLayout(
        title: 'Detail Kontrak: ${contract.namaKontrak}',
        activeMenu: 'kontrak',
        showBackButton: true,
        onBack: () => goBackOrParent(context, '/kontrak'),
        onMenuSelected: (menuKey) =>
            goTopLevelRoute(context, WebDashboardLayout.routeForMenu(menuKey)),
        actions: headerActions,
        floatingActionButton: fab,
        child: mainBody,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => goBackOrParent(context, '/kontrak'),
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
        actions: headerActions,
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
      floatingActionButton: fab,
    );
  }

  Widget _buildUmumTab() {
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final isKonsultan = userProf?.isKonsultan ?? true;
    final contract = _resolveLiveContract(listen: true) ?? this.contract;
    if (!identical(contract, _syncedContractRef)) {
      _reloadFromContract(contract);
    }

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
                _buildSpecItem(
                  'Nilai Kontrak',
                  contract.nilaiKontrak.isNotEmpty
                      ? (contract.nilaiKontrak.startsWith('Rp')
                          ? contract.nilaiKontrak
                          : 'Rp ${contract.nilaiKontrak}')
                      : '-',
                ),
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

          // Struktur Personel Konsultan (Tepat di bawah Spesifikasi Kontrak)
          const Text(
            'Struktur Personel Konsultan',
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
                      color: AppColors.slateLighter,
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
              if (isKonsultan)
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
              child: Text(
                isKonsultan
                    ? 'Belum ada kegiatan yang didaftarkan pada kontrak ini.\nTekan "+ Tambah" untuk menambahkan kegiatan.'
                    : 'Belum ada kegiatan yang didaftarkan pada kontrak ini.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textLight, height: 1.4),
              ),
            )
          else
            ..._kegiatans.asMap().entries.map((entry) => _buildKegiatanItem(entry.value, entry.key, isKonsultan: isKonsultan)),
            
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildKegiatanItem(_KegiatanData kegiatan, int index, {bool isKonsultan = true}) {
    final liveContract = _resolveLiveContract(listen: false) ?? contract;
    final Map<String, dynamic> liveKegMap =
        (index >= 0 && index < liveContract.kegiatans.length)
            ? liveContract.kegiatans[index]
            : kegiatan.data;
    final double kegProgress = ProgressCalculator.calculateKegiatanProgress(
      liveKegMap,
      contract: liveContract,
    );

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
            final live = _resolveLiveContract(listen: false) ?? contract;
            final router = GoRouter.maybeOf(context);
            if (router != null) {
              router.go(
                '/kontrak/${live.id}/kegiatan/$index',
                extra: live,
              );
              return;
            }
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailKegiatanScreen(
                  contract: live,
                  kegiatanIndex: index,
                ),
              ),
            );
            // Refresh on return in case they edited anything inside
            if (mounted) {
              setState(() {
                _reloadFromContract(_resolveLiveContract(listen: false) ?? contract);
              });
            }
          },
          onLongPress: isKonsultan ? () => _showKegiatanOptions(index) : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.slateLighter,
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (kegProgress / 100.0).clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: AppColors.inputBackground,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  kegProgress > 0
                                      ? AppColors.successGreen
                                      : AppColors.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${kegProgress.toStringAsFixed(2)}%',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isKonsultan)
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
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final isKonsultan = userProf?.isKonsultan ?? true;

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
          Container(
            padding: const EdgeInsets.all(28.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.folder_open_outlined, size: 36, color: Color(0xFF94A3B8)),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Belum Ada Folder Dokumen Kontrak',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Folder administrasi bersih tanpa default. Tambah folder baru untuk mengelola berkas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                if (isKonsultan) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _addFolder,
                    icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                    label: const Text('Buat Folder Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ..._folders.asMap().entries.map((entry) {
          int index = entry.key;
          _FolderData folder = entry.value;
          return _buildFolderItem(folder, index, isKonsultan: isKonsultan);
        }),
      ],
    );
  }

  Widget _buildFolderItem(_FolderData folder, int index, {bool isKonsultan = true}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          folder.isExpanded = !folder.isExpanded;
          _saveToProvider();
        });
      },
      onLongPressStart: isKonsultan ? (details) {
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
            _deleteFolder(index);
          } else if (value == 'edit') {
            _editFolder(index);
          } else if (value == 'upload') {
            _uploadDocument(index);
          }
        });
      } : null,
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
                  if (isKonsultan)
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 22),
                      tooltip: 'Upload Dokumen',
                      onPressed: () => _uploadDocument(index),
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
                    if (isKonsultan)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OutlinedButton.icon(
                          onPressed: () => _uploadDocument(index),
                          icon: const Icon(Icons.upload_file, size: 16),
                          label: const Text('Upload Dokumen ke Folder Ini'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            side: const BorderSide(color: AppColors.primaryBlue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    if (folder.documents.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'Belum ada dokumen di folder ini',
                            style: TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic),
                          ),
                        ),
                      )
                    else
                      ...folder.documents.map((doc) => _buildDocItem(doc, folder, isKonsultan: isKonsultan)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItem(_DocumentData doc, _FolderData folder, {bool isKonsultan = true}) {
    IconData iconData;
    Color iconColor;

    switch (doc.type.toUpperCase()) {
      case 'PDF':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'IMG':
      case 'JPG':
      case 'JPEG':
      case 'PNG':
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
      case 'DOC':
      case 'DOCX':
        iconData = Icons.description;
        iconColor = const Color(0xFF2563EB);
        break;
      case 'XLS':
      case 'XLSX':
        iconData = Icons.table_chart;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = const Color(0xFF64748B);
    }

    final dateStr = DateFormat('d MMM yyyy', 'id_ID').format(doc.uploadDate);

    return InkWell(
      onTap: () => _previewOrOpenDocument(doc, folder, isKonsultan: isKonsultan),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${doc.type} • ${doc.sizeFormatted.isNotEmpty ? doc.sizeFormatted : "1.2 MB"} • $dateStr',
                    style: const TextStyle(color: AppColors.textLight, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (isKonsultan)
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                tooltip: 'Hapus Dokumen',
                onPressed: () => _deleteDocument(folder, doc),
              ),
            IconButton(
              icon: const Icon(Icons.open_in_new, color: AppColors.primaryBlue, size: 19),
              tooltip: 'Buka Dokumen',
              onPressed: () => _previewOrOpenDocument(doc, folder, isKonsultan: isKonsultan),
            ),
          ],
        ),
      ),
    );
  }
}
