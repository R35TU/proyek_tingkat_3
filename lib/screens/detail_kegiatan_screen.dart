import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
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
import 'package:tata_saka_app/models/kegiatan_model.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:tata_saka_app/services/storage_service.dart';
import 'package:tata_saka_app/services/file_downloader.dart';
import 'package:tata_saka_app/screens/detail_data_laporan_screen.dart';
import 'package:tata_saka_app/screens/form_kegiatan_screen.dart';
import 'package:tata_saka_app/screens/kelola_rkk_screen.dart';
import 'package:tata_saka_app/screens/kelola_addendum_screen.dart';
import 'package:tata_saka_app/widgets/lembar_tambah_kurang_widget.dart';
import 'package:tata_saka_app/widgets/responsive_layout.dart';
import 'package:tata_saka_app/widgets/web_dashboard_layout.dart';
import 'package:tata_saka_app/utils/progress_calculator.dart';
import 'package:tata_saka_app/utils/rupiah_input_formatter.dart';

class _DocData {
  String id;
  String name;
  String type;
  int sizeBytes;
  String sizeFormatted;
  DateTime uploadDate;
  String? localPath;
  String? remoteUrl;

  _DocData({
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

  factory _DocData.fromJson(Map<String, dynamic> json) => _DocData(
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

  @override
  void didUpdateWidget(covariant DetailKegiatanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.contract != widget.contract || oldWidget.kegiatanIndex != widget.kegiatanIndex) {
      _loadData();
    }
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
            return _DocData.fromJson(Map<String, dynamic>.from(d));
          }).toList() ?? [],
        );
      }).toList();
    } else {
      _folders = [];
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _saveToProvider() {
    _kegiatanMap['folders'] = _folders.map((f) => {
      'name': f.name,
      'isExpanded': f.isExpanded,
      'documents': f.documents.map((d) => d.toJson()).toList(),
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

  void _deleteFolder(int index) {
    if (index < 0 || index >= _folders.length) return;
    final folder = _folders[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Folder?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus folder "${folder.name}" beserta ${folder.documents.length} dokumen di dalamnya? Tindakan ini tidak dapat dibatalkan.',
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
                  contractId: widget.contract.id,
                  contractName: widget.contract.namaKontrak,
                  kegiatanName: _namaKegiatan,
                  kontraktorName: _kegiatan.kontraktor,
                  dinasName: widget.contract.instansiDinas.isNotEmpty
                      ? widget.contract.instansiDinas.first
                      : 'DPU-PR Kab. Purbalingga',
                  title: 'Penghapusan Folder: $deletedName',
                  description: 'Folder administrasi "$deletedName" telah dihapus dari kegiatan $_namaKegiatan.',
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
                          'Upload Dokumen Nyata',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Pilih dokumen dari memori perangkat untuk disimpan secara offline.',
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

                    // File Picker Button / Action
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
                        hintText: 'Contoh: Surat Perintah Kerja (SPK) Final',
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
                                                'dokumen/${widget.contract.namaKontrak}/${_folders[selectedFolderIdx].name}/${DateTime.now().millisecondsSinceEpoch}_$pickedFileName'),
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
                                  final newDoc = _DocData(
                                    id: 'doc_${DateTime.now().millisecondsSinceEpoch}',
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
                                      contractId: widget.contract.id,
                                      contractName: widget.contract.namaKontrak,
                                      kegiatanName: _namaKegiatan,
                                      kontraktorName: _kegiatan.kontraktor,
                                      dinasName: widget.contract.instansiDinas.isNotEmpty
                                          ? widget.contract.instansiDinas.first
                                          : 'DPU-PR Kab. Purbalingga',
                                      title: 'Unggah Dokumen: $docTitle',
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

  void _deleteDocument(_FolderData folder, _DocData doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Dokumen?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Apakah Anda yakin ingin menghapus dokumen "${doc.name}"? File akan dihapus permanen dari penyimpanan perangkat.',
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
                  contractId: widget.contract.id,
                  contractName: widget.contract.namaKontrak,
                  kegiatanName: _namaKegiatan,
                  kontraktorName: _kegiatan.kontraktor,
                  dinasName: widget.contract.instansiDinas.isNotEmpty
                      ? widget.contract.instansiDinas.first
                      : 'DPU-PR Kab. Purbalingga',
                  title: 'Penghapusan Dokumen: ${doc.name}',
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

  void _previewOrOpenDocument(_DocData doc, _FolderData folder, {bool isKonsultan = true}) {
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
      try {
        final timeline = Provider.of<TimelineProvider>(context, listen: false);
        timeline.logEvent(
          actorName: 'CV. Tata Saka Consultant',
          actionType: 'UPDATE',
          entityType: 'KEGIATAN',
          contractId: widget.contract.id,
          contractName: widget.contract.namaKontrak,
          kegiatanName: _namaKegiatan,
          kontraktorName: _kegiatan.kontraktor,
          dinasName: widget.contract.instansiDinas.isNotEmpty
              ? widget.contract.instansiDinas.first
              : 'DPU-PR Kab. Purbalingga',
          title: 'Pembaruan Data Kegiatan: $_namaKegiatan',
          description: 'Informasi umum kegiatan $_namaKegiatan telah diperbarui.',
        );
      } catch (_) {}
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
              final deletedName = _namaKegiatan;
              final deletedKontraktor = _kegiatan.kontraktor;
              widget.contract.kegiatans.removeAt(widget.kegiatanIndex);
              Provider.of<ContractProvider>(context, listen: false).updateContract(widget.contract);
              try {
                final timeline = Provider.of<TimelineProvider>(context, listen: false);
                timeline.logEvent(
                  actorName: 'CV. Tata Saka Consultant',
                  actionType: 'DELETE',
                  entityType: 'KEGIATAN',
                  contractId: widget.contract.id,
                  contractName: widget.contract.namaKontrak,
                  kegiatanName: deletedName,
                  kontraktorName: deletedKontraktor,
                  dinasName: widget.contract.instansiDinas.isNotEmpty
                      ? widget.contract.instansiDinas.first
                      : 'DPU-PR Kab. Purbalingga',
                  title: 'Penghapusan Kegiatan: $deletedName',
                  description: 'Kegiatan $deletedName telah dihapus dari kontrak.',
                );
              } catch (_) {}
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
    UserProfileProvider? userProf;
    try {
      userProf = Provider.of<UserProfileProvider>(context);
    } catch (_) {
      userProf = null;
    }
    final isKonsultan = userProf?.isKonsultan ?? true;
    final isKontraktor = userProf?.isKontraktor ?? false;

    // Filter folder untuk kontraktor: laporan harian & mingguan ditutup total
    final displayFolders = isKontraktor
        ? _folders.where((f) {
            final lower = f.name.toLowerCase();
            return !lower.contains('laporan') && !lower.contains('harian') && !lower.contains('mingguan');
          }).toList()
        : _folders;

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    final headerActions = [
      if (isKonsultan)
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: isDesktop ? Colors.white : AppColors.textDark),
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
    ];

    final mainBody = ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // Info Kegiatan Top Section (Executive Card)
          _buildExecutiveGeneralInfo(isKonsultan: isKonsultan),

          const SizedBox(height: 18),

          // Action Card: Rincian Kuantitas & Bobot Pekerjaan (RKK)
          _buildRkkActionCard(isKonsultan: isKonsultan),

          const SizedBox(height: 28),

          // Administrasi Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Folder Administrasi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${displayFolders.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              if (isKonsultan)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.08),
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
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          
          if (displayFolders.isEmpty)
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
                    'Belum Ada Folder Dokumen',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Folder administrasi bersih tanpa default. Buat folder baru untuk mengelola berkas.',
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
            
          ...displayFolders.asMap().entries.map((entry) {
            int index = entry.key;
            _FolderData folder = entry.value;
            return _buildFolderItem(folder, index, isKonsultan: isKonsultan);
          }),
        ],
      );

    if (isDesktop) {
      return WebDashboardLayout(
        title: 'Detail Kegiatan: $_namaKegiatan',
        activeMenu: 'kontrak',
        showBackButton: true,
        actions: headerActions,
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
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
            }
          },
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
        actions: headerActions,
      ),
      body: mainBody,
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
                            'Belum ada file dokumen yang diunggah ke folder ini',
                            style: TextStyle(color: AppColors.textLight, fontStyle: FontStyle.italic, fontSize: 12),
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

  Widget _buildDocItem(_DocData doc, _FolderData folder, {bool isKonsultan = true}) {
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

  Widget _buildPersonTile({
    required String role,
    required String name,
    required IconData icon,
    Color iconColor = const Color(0xFF64748B),
    Color iconBg = const Color(0xFFF1F5F9),
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  name.isNotEmpty ? name : '-',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveGeneralInfo({bool isKonsultan = true}) {
    const Color borderColor = Color(0xFFE2E8F0);
    const Color labelColor = Color(0xFF64748B);
    const Color valueColor = Color(0xFF0F172A);
    const Color headerBg = Color(0xFF0F172A);
    const Color sectionBg = Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — clean, modern, dark slate
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
                if (isKonsultan) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: _editKegiatanSelf,
                    child: const Tooltip(
                      message: 'Edit Kegiatan',
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_outlined,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'KONSULTAN PENGAWAS',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.business_center_outlined, size: 16, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'PENYEDIA JASA / KONTRAKTOR PELAKSANA',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
                  _buildDocRow('No. Surat Pesanan/tanggal', _kegiatan.suratPesananFull),
                  _buildDocRow('No. SPMK/tanggal', _kegiatan.spmkKontraktorFull),
                  _buildDocRow('Jangka Waktu Pelaksanaan', _kegiatan.jangkaWaktu),
                  if (_kegiatan.tglAkhirSpmk.isNotEmpty)
                    _buildDocRow('Tanggal Akhir SPMK', _kegiatan.tglAkhirSpmk),
                ],
              ),
            ),

            // SECTION: NILAI KONTRAK — modern metric card row
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.payments_outlined, size: 18, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nilai Kontrak Kegiatan',
                          style: TextStyle(
                            fontSize: 11,
                            color: labelColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _kegiatan.nilaiKontrak.isNotEmpty ? _kegiatan.nilaiKontrak : '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: valueColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildRabTableExecutiveSection(),

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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.account_balance_outlined, size: 16, color: Color(0xFF2563EB)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'STRUKTUR ORGANISASI KEGIATAN',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPersonTile(
                    role: 'Pengguna Anggaran / PPK',
                    name: _kegiatan.penggunaAnggaran,
                    icon: Icons.badge_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                  ),
                  _buildPersonTile(
                    role: _kegiatan.stafTeknisLabel,
                    name: _kegiatan.stafTeknisDisplay,
                    icon: Icons.groups_outlined,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF475569),
                  ),
                  _buildPersonTile(
                    role: 'Direktur Penyedia Jasa',
                    name: _kegiatan.direkturPenyedia.isNotEmpty
                        ? _kegiatan.direkturPenyedia
                        : _kegiatan.direkturKonsultan,
                    icon: Icons.business_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.engineering_outlined, size: 16, color: Color(0xFFD97706)),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'STRUKTUR ORGANISASI PENYEDIA JASA',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildPersonTile(
                    role: 'Direktur',
                    name: _kegiatan.direkturPenyedia.isNotEmpty
                        ? _kegiatan.direkturPenyedia
                        : _kegiatan.direkturKonsultan,
                    icon: Icons.person_outline,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                  ),
                  _buildPersonTile(
                    role: 'Pelaksana Lapangan',
                    name: _kegiatan.pelaksanaLapangan,
                    icon: Icons.construction_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF2563EB),
                  ),
                  _buildPersonTile(
                    role: 'Ahli / Petugas K3',
                    name: _kegiatan.petugasK3,
                    icon: Icons.health_and_safety_outlined,
                    iconBg: const Color(0xFFE6F4EA),
                    iconColor: const Color(0xFF059669),
                  ),
                ],
              ),
            ),
          ],

          // Progress Bar — always visible, bottom of card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: _currentProgresFisik > 0
                                ? const Color(0xFFE6F4EA)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.trending_up,
                            size: 15,
                            color: _currentProgresFisik > 0
                                ? AppColors.successGreen
                                : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Progres Fisik',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _currentProgresFisik > 0
                            ? const Color(0xFFE6F4EA)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _currentProgresFisik > 0
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        '${_currentProgresFisik.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: _currentProgresFisik > 0
                              ? AppColors.successGreen
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_currentProgresFisik / 100.0).clamp(0.0, 1.0),
                    minHeight: 7,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _currentProgresFisik > 0
                          ? AppColors.successGreen
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _currentProgresFisik =>
      ProgressCalculator.calculateKegiatanProgress(_kegiatanMap);

  void _bukaLembarTambahKurangLatest() {
    if (!_kegiatan.hasAddendum) return;
    final latestAddendum = _kegiatan.addendums.last;
    final int addendumIdx = _kegiatan.addendums.length - 1;
    List<Map<String, dynamic>> baselineList;
    if (addendumIdx == 0) {
      baselineList = _kegiatan.rkkKontrakAwal.isNotEmpty
          ? _kegiatan.rkkKontrakAwal
          : _kegiatan.rkkDivisiList;
    } else {
      baselineList = (_kegiatan.addendums[addendumIdx - 1]['rkkDivisiList'] as List)
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Lembar Perhitungan Tambah Kurang (${latestAddendum['nomorAddendum'] ?? '01'})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: LembarTambahKurangWidget(
                  kegiatan: _kegiatan,
                  addendumData: latestAddendum,
                  baselineDivisiList: baselineList,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRkkActionCard({bool isKonsultan = true}) {
    final rawRkk = _kegiatan.activeRkkDivisiList;
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Flexible(
                          child: Text(
                            'Rincian Kuantitas & Bobot Pekerjaan',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_kegiatan.hasAddendum) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Text(
                              'Addendum ${_kegiatan.latestAddendum?['nomorAddendum'] ?? '01'}',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasRkk
                          ? '${rawRkk.length} Divisi • $totalItems Item Pekerjaan'
                          : 'Belum diisi • Acuan dropdown laporan harian & BoQ mingguan',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (hasRkk) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: is100Percent ? const Color(0xFFE6F4EA) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: is100Percent ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                    ),
                  ),
                  child: Text(
                    '${totalBobot.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: is100Percent ? const Color(0xFF059669) : const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Two elegant side-by-side action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1D4ED8),
                    backgroundColor: const Color(0xFFF8FAFC),
                    side: const BorderSide(color: Color(0xFFBFDBFE)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                  ),
                  onPressed: () async {
                    final changed = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => KelolaRkkScreen(
                          contract: widget.contract,
                          kegiatanIndex: widget.kegiatanIndex,
                          readOnly: !isKonsultan,
                        ),
                      ),
                    );
                    if (changed == true || mounted) {
                      setState(() {
                        _loadData();
                      });
                    }
                  },
                  icon: Icon(isKonsultan ? Icons.edit_note : Icons.visibility_outlined, size: 18),
                  label: Text(
                    isKonsultan
                        ? (hasRkk ? 'Kelola Rincian Pekerjaan (RKK)' : 'Setup Rincian Kuantitas (RKK)')
                        : 'Lihat Rincian Pekerjaan (RKK)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (hasRkk) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      final changed = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => KelolaAddendumScreen(
                            contract: widget.contract,
                            kegiatanIndex: widget.kegiatanIndex,
                            readOnly: !isKonsultan,
                          ),
                        ),
                      );
                      if (changed == true || mounted) {
                        setState(() {
                          _loadData();
                        });
                      }
                    },
                    icon: Icon(isKonsultan ? Icons.history_edu : Icons.visibility_outlined, size: 16),
                    label: Text(
                      isKonsultan
                          ? (_kegiatan.hasAddendum
                              ? 'Kelola Addendum (${_kegiatan.addendums.length}) & Tambah Kurang'
                              : 'Kelola Addendum (CCO)')
                          : 'Lihat Addendum & Tambah Kurang',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// A clean, document-style label : value row.
  Widget _buildDocRow(String label, String value) {
    const Color labelColor = Color(0xFF64748B);
    const Color valueColor = Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 145,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 4),
          const Text(':', style: TextStyle(fontSize: 11.5, color: Color(0xFFCBD5E1))),
          const SizedBox(width: 8),
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

  // ─── TABEL RINCIAN KUANTITAS KONTRAK (RAB) DIBAWAH NILAI KONTRAK KEGIATAN ───
  Widget _buildRabTableExecutiveSection() {
    const Color borderColor = Color(0xFFD1D5DB);
    const Color sectionBg = Color(0xFFFAFAFA);

    final rawRkk = _kegiatan.activeRkkDivisiList;
    int totalItems = 0;
    double totalHarga = 0.0;
    double totalBobot = 0.0;

    for (final div in rawRkk) {
      final items = (div['items'] as List? ?? []);
      totalItems += items.length;
      for (final it in items) {
        final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
        final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
        final th = (it['totalHarga'] as num?)?.toDouble() ?? (hs * vol);
        totalHarga += th;
        totalBobot += (it['nilaiBobot'] as num?)?.toDouble() ?? 0.0;
      }
    }

    final hasRkk = rawRkk.isNotEmpty && totalItems > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: sectionBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFD1D5DB), width: 1)),
                  ),
                  child: Text(
                    _kegiatan.hasAddendum
                        ? 'RINCIAN KUANTITAS KONTRAK (ADDENDUM ${_kegiatan.latestAddendum?['nomorAddendum'] ?? '01'})'
                        : 'RINCIAN KUANTITAS KONTRAK (RAB)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_kegiatan.hasAddendum) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: _bukaLembarTambahKurangLatest,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined, size: 13, color: AppColors.primaryBlue),
                        SizedBox(width: 4),
                        Text(
                          'Lembar Tambah Kurang',
                          style: TextStyle(fontSize: 10.5, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          if (!hasRkk)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Belum ada rincian kuantitas kontrak (RAB).',
                style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Color(0xFF94A3B8)),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 840),
                  child: Table(
                    border: TableBorder.all(color: const Color(0xFFCBD5E1), width: 0.8),
                    columnWidths: const {
                      0: FixedColumnWidth(34),   // NO
                      1: FixedColumnWidth(85),   // NO. MATA PEMBAYARAN
                      2: FixedColumnWidth(260),  // URAIAN
                      3: FixedColumnWidth(48),   // SATUAN
                      4: FixedColumnWidth(115),  // HARGA SATUAN
                      5: FixedColumnWidth(65),   // VOLUME
                      6: FixedColumnWidth(130),  // TOTAL HARGA
                      7: FixedColumnWidth(75),   // BOBOT
                    },
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      // Header Baris
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                        children: [
                          _rabTh('NO.'),
                          _rabTh('NO. MATA\nPEMBAYARAN'),
                          _rabTh('URAIAN PEKERJAAN'),
                          _rabTh('SATUAN'),
                          _rabTh('HARGA SATUAN\n(Rp)'),
                          _rabTh('VOLUME'),
                          _rabTh('TOTAL HARGA\n(Rp)'),
                          _rabTh('BOBOT\n(%)'),
                        ],
                      ),

                      // Baris Divisi & Item
                      ...rawRkk.expand((div) {
                        final items = (div['items'] as List? ?? []);
                        final romawi = div['nomorRomawi']?.toString().toUpperCase() ?? '';
                        final namaDiv = (div['namaDivisi']?.toString() ?? (romawi.isNotEmpty ? 'DIVISI $romawi' : 'DIVISI')).toUpperCase();

                        double divSubtotal = 0.0;
                        double divBobot = 0.0;
                        for (final it in items) {
                          final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
                          final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
                          final th = (it['totalHarga'] as num?)?.toDouble() ?? (hs * vol);
                          divSubtotal += th;
                          divBobot += totalHarga > 0
                              ? (th / totalHarga) * 100.0
                              : ((it['nilaiBobot'] as num?)?.toDouble() ?? 0.0);
                        }

                        return [
                          // Baris Header Divisi
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: [
                              _rabTd(romawi, align: TextAlign.center, isBold: true),
                              _rabTd('', isBold: true),
                              _rabTd(namaDiv, isBold: true),
                              _rabTd(''),
                              _rabTd(''),
                              _rabTd(''),
                              _rabTd(divSubtotal > 0 ? KelolaRkkScreen.formatRupiah(divSubtotal).replaceFirst('Rp ', '') : '-', align: TextAlign.right, isBold: true),
                              _rabTd(divBobot > 0 ? '${divBobot.toStringAsFixed(3)}%' : '-', align: TextAlign.right, isBold: true),
                            ],
                          ),

                          // Baris Item Pekerjaan
                          ...items.asMap().entries.map((itemEntry) {
                            final idx = itemEntry.key + 1;
                            final it = itemEntry.value;
                            final noMata = it['noMataPembayaran']?.toString() ?? '-';
                            final uraian = it['uraian']?.toString() ?? '-';
                            final satuan = it['satuan']?.toString() ?? '-';
                            final hs = (it['hargaSatuan'] as num?)?.toDouble() ?? 0.0;
                            final vol = (it['volume'] ?? it['volumeCCO'] as num?)?.toDouble() ?? 0.0;
                            final th = (it['totalHarga'] as num?)?.toDouble() ?? (hs * vol);
                            // Rumus konsisten: Bobot Pekerjaan (%) = (Total Harga Item / Total Nilai RAB) * 100%
                            final bbt = totalHarga > 0
                                ? (th / totalHarga) * 100.0
                                : ((it['nilaiBobot'] as num?)?.toDouble() ?? 0.0);

                            return TableRow(
                              children: [
                                _rabTd('$idx', align: TextAlign.center),
                                _rabTd(noMata, align: TextAlign.center, isBold: true),
                                _rabTd(uraian, align: TextAlign.left),
                                _rabTd(satuan, align: TextAlign.center),
                                _rabTd(hs > 0 ? KelolaRkkScreen.formatRupiah(hs).replaceFirst('Rp ', '') : '-', align: TextAlign.right),
                                _rabTd(vol > 0 ? (vol == vol.toInt() ? vol.toInt().toString() : vol.toString()) : '-', align: TextAlign.right),
                                _rabTd(th > 0 ? KelolaRkkScreen.formatRupiah(th).replaceFirst('Rp ', '') : '-', align: TextAlign.right),
                                _rabTd(bbt > 0 ? '${bbt.toStringAsFixed(3)}%' : '-', align: TextAlign.right, isBold: true),
                              ],
                            );
                          }),
                        ];
                      }),

                      // Summary Total Row
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                        children: [
                          _rabTd('', align: TextAlign.center),
                          _rabTd('', align: TextAlign.center),
                          _rabTd('JUMLAH TOTAL HARGA PEKERJAAN', align: TextAlign.left, isBold: true),
                          _rabTd('', align: TextAlign.center),
                          _rabTd('', align: TextAlign.right),
                          _rabTd('', align: TextAlign.right),
                          _rabTd(KelolaRkkScreen.formatRupiah(totalHarga).replaceFirst('Rp ', ''), align: TextAlign.right, isBold: true),
                          _rabTd(totalHarga > 0 ? '100.000%' : '0.000%', align: TextAlign.right, isBold: true),
                        ],
                      ),
                      // Baris Pembulatan Sesuai Format Dokumen Fisik Dinas PU (Floor kelipatan Rp 1.000)
                      if (totalHarga > 0 || _kegiatan.nilaiKontrak.isNotEmpty)
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                          children: [
                            _rabTd('', align: TextAlign.center),
                            _rabTd('', align: TextAlign.center),
                            _rabTd('JUMLAH TOTAL HARGA PEKERJAAN (DIBULATKAN)', align: TextAlign.left, isBold: true),
                            _rabTd('', align: TextAlign.center),
                            _rabTd('', align: TextAlign.right),
                            _rabTd('', align: TextAlign.right),
                            _rabTd(
                              KelolaRkkScreen.formatRupiah(
                                RupiahUtil.floorToNearestThousand(
                                  totalHarga > 0
                                      ? totalHarga
                                      : RupiahUtil.parseToDouble(_kegiatan.nilaiKontrak),
                                ),
                                forceDecimals: true,
                              ).replaceFirst('Rp ', ''),
                              align: TextAlign.right,
                              isBold: true,
                            ),
                            _rabTd('100.000%', align: TextAlign.right, isBold: true),
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

  Widget _rabTh(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9.0,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
          height: 1.15,
        ),
      ),
    );
  }

  Widget _rabTd(String text, {TextAlign align = TextAlign.left, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Text(
        text,
        textAlign: align,
        style: TextStyle(
          fontSize: 9.0,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: isBold ? const Color(0xFF0F172A) : const Color(0xFF334155),
          height: 1.25,
        ),
      ),
    );
  }
}
