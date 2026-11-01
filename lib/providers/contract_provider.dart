import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'dart:math';

class ContractProvider with ChangeNotifier {
  // List starts empty
  List<ContractModel> _contracts = [];

  ContractProvider() {
    _loadContracts();
  }

  Future<void> _loadContracts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contractsJson = prefs.getString('contracts');
    if (contractsJson != null) {
      final List<dynamic> decoded = jsonDecode(contractsJson);
      _contracts = decoded.map((item) => ContractModel.fromJson(item)).toList();
      for (final contract in _contracts) {
        if (contract.id == 'contract-mt-haryono') {
          for (final keg in contract.kegiatans) {
            if (keg['penggunaAnggaran'] == null || keg['penggunaAnggaran'].toString().isEmpty) {
              if (keg['kontraktor'] == null ||
                  keg['kontraktor'] == 'PT. ANDHIKA BANGUNAN PERKASA' ||
                  keg['kontraktor'] == 'CV. SATYA WIGUNA') {
                keg['kontraktor'] = 'CV. SATYA WIGUNA';
              }
              keg['penggunaAnggaran'] = 'DRAJAT UJI WAKHYONO, S.T., M.T.';
              keg['stafTeknis1'] = 'MUBALLIGH, ST., M.Sc.';
              keg['stafTeknis2'] = 'BILAL A.Md';
              keg['siteEngineerKegiatan'] = 'SENDAYU GALIH K., ST';
              keg['direkturPenyedia'] = 'IKSAN';
              keg['direkturKontraktor'] = 'IKSAN';
              keg['pelaksanaLapangan'] = 'GALIH WAHYU UTAMA';
              keg['petugasK3'] = 'IQBAL ZAINUL ARIFIN';
            }
          }
        }
      }
    }
    
    // Seed initial contract matching the official PU document if completely empty
    if (_contracts.isEmpty) {
      final defaultContract = ContractModel(
        id: 'contract-mt-haryono',
        jenisKegiatan: 'Pengawasan Teknis',
        namaKontrak: 'PEMELIHARAAN BERKALA JALAN LETJEND MT. HARYONO',
        nomorSpk: '000.3.3/ 1128 /KONST/BM/IV/2026',
        tglMulaiSpk: '20 April 2026',
        nomorSpmk: '000.3.3/ 1128 /KONST/BM/IV/2026',
        tglMulaiSpmk: '20 April 2026',
        tglSelesaiSpmk: '18 Juli 2026',
        hariKalender: 90,
        nilaiKontrak: 'Rp 3.000.000.000,00',
        instansiDinas: ['DPUPR Purbalingga'],
        sumberDana: 'APBD Kab. Purbalingga',
        deskripsi: 'Pekerjaan Pemeliharaan Berkala Jalan Letjend MT. Haryono',
        progressFisik: 0.0693,
        strukturOrganisasi: {
          'siteEngineer': 'SENDAYU GALIH KUSUMA, ST',
          'inspektors': ['RIZAL PRASTOMO'],
          'administrasi': 'HANGGORO AJI',
        },
        kegiatans: [
          {
            'namaKegiatan': 'Pemeliharaan Berkala Jalan Letjend MT. Haryono',
            'lokasi': 'KEC. PURBALINGGA',
            'kontraktor': 'CV. SATYA WIGUNA',
            'penggunaAnggaran': 'DRAJAT UJI WAKHYONO, S.T., M.T.',
            'stafTeknis1': 'MUBALLIGH, ST., M.Sc.',
            'stafTeknis2': 'BILAL A.Md',
            'siteEngineerKegiatan': 'SENDAYU GALIH K., ST',
            'direkturPenyedia': 'IKSAN',
            'direkturKontraktor': 'IKSAN',
            'pelaksanaLapangan': 'GALIH WAHYU UTAMA',
            'petugasK3': 'IQBAL ZAINUL ARIFIN',
            'laporans': [],
            'laporanMingguan': [],
            'folders': [
              {'name': 'Laporan Harian', 'isExpanded': false, 'documents': []},
              {'name': 'Laporan Mingguan', 'isExpanded': true, 'documents': []},
              {'name': 'Foto Progres', 'isExpanded': false, 'documents': []},
            ],
          }
        ],
      );
      _contracts.add(defaultContract);
      _saveContracts();
    }
    notifyListeners();
  }

  Future<void> _saveContracts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(_contracts.map((c) => c.toJson()).toList());
    await prefs.setString('contracts', encoded);
  }

  List<ContractModel> get contracts => [..._contracts];

  int get totalContracts => _contracts.length;
  int get activeContracts => _contracts.where((c) => c.status == 'Aktif').length;
  int get completedContracts => _contracts.where((c) => c.status == 'Selesai').length;

  void addContract(ContractModel newContract) {
    _contracts.add(newContract);
    _saveContracts();
    notifyListeners();
  }

  void updateContract(ContractModel updatedContract) {
    final index = _contracts.indexWhere((c) => c.id == updatedContract.id);
    if (index >= 0) {
      _contracts[index] = updatedContract;
      _saveContracts();
      notifyListeners();
    }
  }

  void deleteContract(String id) {
    _contracts.removeWhere((c) => c.id == id);
    _saveContracts();
    notifyListeners();
  }

  // Generate random string for ID
  String generateId() {
    var random = Random();
    var values = List<int>.generate(10, (i) => random.nextInt(256));
    return values.join();
  }
}
