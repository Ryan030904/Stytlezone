import 'package:flutter/material.dart';
import '../models/shipment_model.dart';
import '../services/shipment_service.dart';

class ShipmentProvider extends ChangeNotifier {
  final ShipmentService _service = ShipmentService();

  List<Shipment> _shipments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Shipment> get shipments => _shipments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadShipments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _shipments = await _service.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createShipment(Shipment s) async {
    try {
      await _service.create(s);
      await loadShipments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateShipment(Shipment s) async {
    try {
      await _service.update(s);
      await loadShipments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status, {String location = '', String note = ''}) async {
    try {
      await _service.updateStatus(id, status, location: location, note: note);
      await loadShipments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> bulkUpdateStatus(List<String> ids, String status) async {
    try {
      await _service.bulkUpdateStatus(ids, status);
      await loadShipments();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteShipment(String id) async {
    try {
      await _service.delete(id);
      await loadShipments();
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
