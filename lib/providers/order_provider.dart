import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider extends ChangeNotifier {
  final OrderService _service = OrderService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _orders = await _service.getAll();
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createOrder(Order order) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.create(order);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateOrder(Order order) async {
    try {
      await _service.update(order);
      await loadOrders();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(String id, String status, {String note = '', VoidCallback? onStockChanged}) async {
    try {
      await _service.updateStatus(id, status, note: note);
      await loadOrders();
      // Notify caller to reload products if stock was adjusted
      if (onStockChanged != null) onStockChanged();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> bulkUpdateStatus(List<String> ids, String status, {VoidCallback? onStockChanged}) async {
    try {
      await _service.bulkUpdateStatus(ids, status);
      await loadOrders();
      if (onStockChanged != null) onStockChanged();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteOrder(String id) async {
    try {
      await _service.delete(id);
      await loadOrders();
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
