import 'package:flutter/material.dart';
import '../models/rma_model.dart';
import '../services/rma_service.dart';
import '../constants/admin_enums.dart';

class RmaProvider extends ChangeNotifier {
  final RmaService _service = RmaService();

  List<RmaModel> _rmas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RmaModel> get rmas => _rmas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadRmas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _rmas = await _service.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createRma(RmaModel rma) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.create(rma);
      await loadRmas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRma(RmaModel rma) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.update(rma);
      await loadRmas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, RmaStatus newStatus, {String note = ''}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.updateStatus(id, newStatus, note: note);
      await loadRmas();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRma(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.delete(id);
      await loadRmas();
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
