import 'package:flutter/material.dart';
import '../models/customer_model.dart';
import '../services/customer_service.dart';

class CustomerProvider extends ChangeNotifier {
  final CustomerService _service = CustomerService();

  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _customers = await _service.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> banCustomer(String id, String reason) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.banUser(id, reason);
      await loadCustomers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> unbanCustomer(String id) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.unbanUser(id);
      await loadCustomers();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
