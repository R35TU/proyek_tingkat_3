import 'package:flutter/material.dart';
import 'package:tata_saka_app/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:tata_saka_app/providers/contract_provider.dart';
import 'package:tata_saka_app/providers/timeline_provider.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';
import '../utils/rupiah_input_formatter.dart';

class TambahKontrakScreen extends StatefulWidget {
  final ContractModel? contractToEdit;

  const TambahKontrakScreen({super.key, this.contractToEdit});

  @override
  State<TambahKontrakScreen> createState() => _TambahKontrakScreenState();
}

class _TambahKontrakScreenState extends State<TambahKontrakScreen> {
  String? _jenisKegiatan = 'Pengawasan Teknis';
  final TextEditingController _namaController = TextEditingController();
  
  final TextEditingController _noSpkController = TextEditingController();
  final TextEditingController _tglMulaiSpkController = TextEditingController();
  
  final TextEditingController _noSpmkController = TextEditingController();
  final TextEditingController _tglMulaiSpmkController = TextEditingController();
  final TextEditingController _jangkaWaktuController = TextEditingController();
  final TextEditingController _tglSelesaiSpmkController = TextEditingController();
  
  final TextEditingController _nilaiKontrakController = TextEditingController();
  
  // Dynamic list for dinas
  final List<TextEditingController> _dinasControllers = [TextEditingController()];
  
  final TextEditingController _sumberDanaController = TextEditingController();
  final TextEditingController _deskripsiController = TextEditingController();

  // Struktur Organisasi Personel Konsultan (Site Engineer, Inspektor 1-4, Administrasi)
  final TextEditingController _siteEngineerController = TextEditingController();
  final List<TextEditingController> _inspektorControllers = [];
  final TextEditingController _administrasiController = TextEditingController();

  DateTime? _tglMulaiSpmk;
  DateTime? _tglSelesaiSpmk;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);

    if (widget.contractToEdit != null) {
      final c = widget.contractToEdit!;
      _jenisKegiatan = c.jenisKegiatan;
      _namaController.text = c.namaKontrak;
      _noSpkController.text = c.nomorSpk;
      _tglMulaiSpkController.text = c.tglMulaiSpk;
      _noSpmkController.text = c.nomorSpmk;
      _tglMulaiSpmkController.text = c.tglMulaiSpmk;
      if (c.hariKalender > 0) {
        _jangkaWaktuController.text = c.hariKalender.toString();
      }
      _tglSelesaiSpmkController.text = c.tglSelesaiSpmk;
      _nilaiKontrakController.text = RupiahUtil.formatString(c.nilaiKontrak);
      _sumberDanaController.text = c.sumberDana;
      _deskripsiController.text = c.deskripsi;

      if (c.instansiDinas.isNotEmpty) {
        _dinasControllers.clear();
        for (var dinas in c.instansiDinas) {
          _dinasControllers.add(TextEditingController(text: dinas));
        }
      }

      // Pre-fill Struktur Organisasi jika sudah ada
      if (c.strukturOrganisasi != null) {
        _siteEngineerController.text = c.siteEngineer;
        _administrasiController.text = c.administrasi;
        if (c.inspektors.isNotEmpty) {
          _inspektorControllers.clear();
          for (var ins in c.inspektors) {
            _inspektorControllers.add(TextEditingController(text: ins));
          }
        }
      }
    }

    if (_inspektorControllers.isEmpty) {
      _inspektorControllers.add(TextEditingController());
    }
  }

  void _addInspektorField() {
    if (_inspektorControllers.length < 4) {
      setState(() {
        _inspektorControllers.add(TextEditingController());
      });
    }
  }

  void _removeInspektorField(int index) {
    if (_inspektorControllers.length > 1) {
      setState(() {
        final c = _inspektorControllers.removeAt(index);
        c.dispose();
      });
    } else {
      _inspektorControllers[0].clear();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noSpkController.dispose();
    _tglMulaiSpkController.dispose();
    _noSpmkController.dispose();
    _tglMulaiSpmkController.dispose();
    _jangkaWaktuController.dispose();
    _tglSelesaiSpmkController.dispose();
    _nilaiKontrakController.dispose();
    for (var c in _dinasControllers) {
      c.dispose();
    }
    _sumberDanaController.dispose();
    _deskripsiController.dispose();
    _siteEngineerController.dispose();
    for (var c in _inspektorControllers) {
      c.dispose();
    }
    _administrasiController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool isMulaiSpmk = false}) async {
    final firstDate = DateTime(2000);
    final lastDate = DateTime(2101);
    DateTime initial = (isMulaiSpmk && _tglMulaiSpmk != null) ? _tglMulaiSpmk! : DateTime.now();
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navySlate,
              onPrimary: Colors.white,
              onSurface: AppColors.textDark,
            ),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        // Format as dd MMMM yyyy in Indonesian
        controller.text = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
        
        if (isMulaiSpmk) {
          _tglMulaiSpmk = picked;
          _updateEndDate();
        }
      });
    }
  }

  void _updateEndDate() {
    final days = int.tryParse(_jangkaWaktuController.text.trim());
    if (_tglMulaiSpmk != null && days != null && days > 0) {
      // Jangka waktu N hari kalender dihitung mulai dari tanggal mulai SPMK (inklusif)
      // Misal mulai 1 September 2026 dan jangka waktu 90 hari kalender, maka selesai 29 November 2026
      final endDate = DateTime(
        _tglMulaiSpmk!.year,
        _tglMulaiSpmk!.month,
        _tglMulaiSpmk!.day + days - 1,
      );
      _tglSelesaiSpmk = endDate;
      _tglSelesaiSpmkController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(endDate);
    } else {
      _tglSelesaiSpmk = null;
      _tglSelesaiSpmkController.text = '';
    }
  }

  int get _hariKalender {
    final days = int.tryParse(_jangkaWaktuController.text.trim());
    if (days != null && days > 0) {
      return days;
    }
    return 0;
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
        title: Text(
          widget.contractToEdit != null ? 'Edit Kontrak' : 'Tambah Kontrak Baru',
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jenis Kegiatan
            DropdownButtonFormField<String>(
              value: _jenisKegiatan,
              decoration: InputDecoration(
                labelText: 'Jenis Kegiatan',
                labelStyle: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                ),
                prefixIcon: const Icon(Icons.engineering, color: AppColors.textLight),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: ['Pengawasan Teknis', 'Perencanaan Teknis'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _jenisKegiatan = newValue;
                });
              },
            ),
            const SizedBox(height: 20),

            // Nama Kegiatan
            _buildTextField(
              controller: _namaController,
              label: 'Nama Kegiatan / Kontrak',
              icon: Icons.business,
              floatingLabel: true
            ),
            const SizedBox(height: 20),

            // SPK
            const Text(
              'Detail Surat Perintah Kerja (SPK)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _noSpkController,
              label: 'Nomor SPK',
              icon: Icons.description_outlined,
              floatingLabel: true,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context, _tglMulaiSpkController),
              child: IgnorePointer(
                child: _buildTextField(
                  controller: _tglMulaiSpkController,
                  label: 'Tanggal Mulai SPK',
                  icon: Icons.calendar_today,
                  floatingLabel: true,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SPMK
            const Text(
              'Surat Perintah Mulai Kerja (SPMK)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _noSpmkController,
              label: 'Nomor SPMK',
              icon: Icons.assignment_outlined,
              floatingLabel: true,
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () => _selectDate(context, _tglMulaiSpmkController, isMulaiSpmk: true),
              child: IgnorePointer(
                child: _buildTextField(
                  controller: _tglMulaiSpmkController,
                  label: 'Tanggal Mulai SPMK',
                  icon: Icons.calendar_today,
                  floatingLabel: true,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _jangkaWaktuController,
                    label: 'Jangka Waktu',
                    suffixText: 'Hari',
                    icon: Icons.timelapse_outlined,
                    floatingLabel: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (val) {
                      setState(() {
                        _updateEndDate();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _tglSelesaiSpmkController,
                    label: 'Tgl Akhir SPMK',
                    icon: Icons.event_available,
                    floatingLabel: true,
                    readOnly: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
            if (_tglMulaiSpmk != null && _hariKalender > 0 && _tglSelesaiSpmk != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline, size: 18, color: AppColors.successGreen),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Masa Pelaksanaan: $_hariKalender Hari Kalender\nBerakhir pada: ${_tglSelesaiSpmkController.text}',
                        style: const TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Nilai Kontrak
            _buildTextField(
              controller: _nilaiKontrakController,
              label: 'Nilai Kontrak',
              hint: '0',
              icon: Icons.monetization_on_outlined,
              floatingLabel: true,
              prefixText: 'Rp ',
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
            ),
            const SizedBox(height: 24),

            // Instansi / Dinas Terkait
            const Text(
              'Instansi / Dinas Terkait',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ..._dinasControllers.asMap().entries.map((entry) {
              int index = entry.key;
              TextEditingController controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: controller,
                        label: 'Nama Dinas ${index + 1}',
                        icon: Icons.account_balance,
                        floatingLabel: true,
                      ),
                    ),
                    if (_dinasControllers.length > 1)
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _dinasControllers.removeAt(index);
                          });
                        },
                      ),
                  ],
                ),
              );
            }),
            InkWell(
              onTap: () {
                setState(() {
                  _dinasControllers.add(TextEditingController());
                });
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Dinas Lain',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Sumber Dana
            _buildTextField(
              controller: _sumberDanaController,
              label: 'Sumber Dana',
              icon: Icons.monetization_on,
              floatingLabel: true,
            ),
            const SizedBox(height: 20),

            // Deskripsi
            TextFormField(
              controller: _deskripsiController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Deskripsi Kegiatan',
                hintStyle: const TextStyle(color: AppColors.textLight, fontWeight: FontWeight.normal),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primaryBlue),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            // Struktur Organisasi Personel Konsultan
            const Text(
              'Struktur Personel Konsultan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),

            // 1. Site Engineer (1 Orang)
            _buildTextField(
              controller: _siteEngineerController,
              label: 'Site Engineer',
              icon: Icons.engineering_outlined,
              floatingLabel: true,
            ),
            const SizedBox(height: 16),

            // 2. Inspektor (1 - 4 Orang Fleksibel)
            ..._inspektorControllers.asMap().entries.map((entry) {
              final idx = entry.key;
              final ctrl = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: ctrl,
                        label: _inspektorControllers.length > 1
                            ? 'Inspektor ${idx + 1}'
                            : 'Inspektor',
                        icon: Icons.verified_user_outlined,
                        floatingLabel: true,
                      ),
                    ),
                    if (_inspektorControllers.length > 1) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        tooltip: 'Hapus Inspektor ${idx + 1}',
                        onPressed: () => _removeInspektorField(idx),
                      ),
                    ],
                  ],
                ),
              );
            }),

            // Tombol Tambah Inspektor (maksimal 4)
            if (_inspektorControllers.length < 4) ...[
              InkWell(
                onTap: _addInspektorField,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle_outline, color: AppColors.primaryBlue, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tambah Inspektor',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 3. Administrasi (1 Orang)
            _buildTextField(
              controller: _administrasiController,
              label: 'Administrasi',
              icon: Icons.assignment_ind_outlined,
              floatingLabel: true,
            ),
            const SizedBox(height: 40),

            // Simpan Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final provider = Provider.of<ContractProvider>(context, listen: false);
                  
                  List<String> dinasList = _dinasControllers
                      .map((c) => c.text.trim())
                      .where((text) => text.isNotEmpty)
                      .toList();

                  final siteEng = _siteEngineerController.text.trim();
                  final adminis = _administrasiController.text.trim();
                  final inspekList = _inspektorControllers
                      .map((c) => c.text.trim())
                      .where((t) => t.isNotEmpty)
                      .toList();

                  Map<String, dynamic>? strukturMap;
                  if (siteEng.isNotEmpty || inspekList.isNotEmpty || adminis.isNotEmpty) {
                    strukturMap = {
                      'siteEngineer': siteEng,
                      'inspektors': inspekList,
                      'administrasi': adminis,
                    };
                  }

                  if (widget.contractToEdit != null) {
                    final updatedContract = ContractModel(
                      id: widget.contractToEdit!.id,
                      jenisKegiatan: _jenisKegiatan ?? 'Pengawasan Teknis',
                      namaKontrak: _namaController.text.isEmpty ? 'Proyek' : _namaController.text,
                      nomorSpk: _noSpkController.text,
                      tglMulaiSpk: _tglMulaiSpkController.text,
                      nomorSpmk: _noSpmkController.text,
                      tglMulaiSpmk: _tglMulaiSpmkController.text,
                      tglSelesaiSpmk: _tglSelesaiSpmkController.text,
                      hariKalender: _hariKalender,
                      nilaiKontrak: _nilaiKontrakController.text.trim().isNotEmpty
                          ? 'Rp ${_nilaiKontrakController.text.trim()}'
                          : '',
                      instansiDinas: dinasList,
                      sumberDana: _sumberDanaController.text,
                      deskripsi: _deskripsiController.text,
                      progressFisik: widget.contractToEdit!.progressFisik,
                      folders: widget.contractToEdit!.folders,
                      kegiatans: widget.contractToEdit!.kegiatans,
                      strukturOrganisasi: strukturMap,
                    );
                    provider.updateContract(updatedContract);
                    try {
                      final timeline = Provider.of<TimelineProvider>(context, listen: false);
                      timeline.logEvent(
                        actorName: 'CV. Tata Saka Consultant',
                        actionType: 'UPDATE',
                        entityType: 'KONTRAK',
                        contractId: updatedContract.id,
                        contractName: updatedContract.namaKontrak,
                        dinasName: updatedContract.instansiDinas.isNotEmpty
                            ? updatedContract.instansiDinas.first
                            : 'DPU-PR Kab. Purbalingga',
                        title: 'Pembaruan Kontrak: ${updatedContract.namaKontrak}',
                        description: 'Data administrasi kontrak diperbarui (SPK: ${updatedContract.nomorSpk}).',
                      );
                    } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kontrak berhasil diperbarui')),
                    );
                  } else {
                    final newContract = ContractModel(
                      id: provider.generateId(),
                      jenisKegiatan: _jenisKegiatan ?? 'Pengawasan Teknis',
                      namaKontrak: _namaController.text.isEmpty ? 'Proyek Baru' : _namaController.text,
                      nomorSpk: _noSpkController.text,
                      tglMulaiSpk: _tglMulaiSpkController.text,
                      nomorSpmk: _noSpmkController.text,
                      tglMulaiSpmk: _tglMulaiSpmkController.text,
                      tglSelesaiSpmk: _tglSelesaiSpmkController.text,
                      hariKalender: _hariKalender,
                      nilaiKontrak: _nilaiKontrakController.text.trim().isNotEmpty
                          ? 'Rp ${_nilaiKontrakController.text.trim()}'
                          : '',
                      instansiDinas: dinasList,
                      sumberDana: _sumberDanaController.text,
                      deskripsi: _deskripsiController.text,
                      progressFisik: 0.0,
                      strukturOrganisasi: strukturMap,
                    );
                    provider.addContract(newContract);
                    try {
                      final timeline = Provider.of<TimelineProvider>(context, listen: false);
                      timeline.logEvent(
                        actorName: 'CV. Tata Saka Consultant',
                        actionType: 'CREATE',
                        entityType: 'KONTRAK',
                        contractId: newContract.id,
                        contractName: newContract.namaKontrak,
                        dinasName: newContract.instansiDinas.isNotEmpty
                            ? newContract.instansiDinas.first
                            : 'DPU-PR Kab. Purbalingga',
                        title: 'Pembuatan Kontrak Baru: ${newContract.namaKontrak}',
                        description: 'Kontrak pengawasan teknis baru ditambahkan ke sistem.',
                      );
                    } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kontrak berhasil ditambahkan')),
                    );
                  }
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.contractToEdit != null ? 'Simpan Perubahan' : 'Simpan Kontrak',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    TextEditingController? controller,
    required String label,
    String? hint,
    required IconData icon,
    bool floatingLabel = false,
    TextStyle? hintStyle,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    String? prefixText,
    String? suffixText,
    ValueChanged<String>? onChanged,
    Color? fillColor,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: floatingLabel ? label : null,
        hintText: hint,
        hintStyle: hintStyle ?? const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
        ),
        labelStyle: const TextStyle(
          color: AppColors.textLight,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.textLight),
        prefixText: prefixText,
        prefixStyle: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        suffixText: suffixText,
        suffixStyle: const TextStyle(
          color: AppColors.textDark,
          fontWeight: FontWeight.w600,
        ),
        filled: fillColor != null,
        fillColor: fillColor,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
