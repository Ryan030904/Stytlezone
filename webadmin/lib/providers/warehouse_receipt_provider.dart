import 'package:flutter/material.dart';
import '../models/warehouse_receipt_model.dart';
import '../services/warehouse_receipt_service.dart';
import '../constants/admin_enums.dart';

class WarehouseReceiptProvider extends ChangeNotifier {
  final WarehouseReceiptService _service = WarehouseReceiptService();

  List<WarehouseReceiptModel> _receipts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<WarehouseReceiptModel> get receipts => _receipts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReceipts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _receipts = await _service.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createReceipt(WarehouseReceiptModel receipt) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.create(receipt);
      await loadReceipts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReceipt(WarehouseReceiptModel receipt) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.update(receipt);
      await loadReceipts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, ReceiptStatus newStatus, {String note = ''}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updateStatus(id, newStatus, note: note);
      await loadReceipts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReceipt(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.delete(id);
      await loadReceipts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
