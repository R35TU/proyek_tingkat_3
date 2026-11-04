import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tata_saka_app/models/contract_model.dart';
import 'package:tata_saka_app/utils/sample_contract_data.dart';
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
      try {
        final List<dynamic> decoded = jsonDecode(contractsJson);
        _contracts = decoded
            .map((item) => ContractModel.fromJson(item))
            .where((c) => c.id != 'contract-mt-haryono') // Remove old dummy contract
            .toList();
      } catch (_) {
        _contracts = [];
      }
    } else {
      _contracts = [];
    }
    
    // Jika data kontrak kosong, inisialisasi dengan 1 kontrak demo sesuai permintaan:
    // "PEMELIHARAAN BERKALA JL. MT HARYONO" dengan 3 Kegiatan: Ruas Jalan A, B, C
    if (_contracts.isEmpty) {
      _contracts = [SampleContractData.getDemoContract()];
      await _saveContracts();
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

  Future<void> clearAllContracts() async {
    _contracts.clear();
    await _saveContracts();
    notifyListeners();
  }

  Future<void> resetToDemoContract() async {
    _contracts = [SampleContractData.getDemoContract()];
    await _saveContracts();
    notifyListeners();
  }

  // Generate random string for ID
  String generateId() {
    var random = Random();
    var values = List<int>.generate(10, (i) => random.nextInt(256));
    return values.join();
  }
}
