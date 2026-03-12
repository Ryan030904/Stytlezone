import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/admin_enums.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  final List<PaymentModel> _payments = [];
  final Map<String, DocumentSnapshot<Map<String, dynamic>>?> _lastDocsByFilter =
      {};
  final Map<String, bool> _hasMoreByFilter = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSyncing = false;
  String? _errorMessage;
  PaymentStatus? _statusFilter;
  PaymentMethod? _methodFilter;
  String _searchQuery = '';

  List<PaymentModel> get payments {
    if (_searchQuery.trim().isEmpty) return _payments;
    final query = _searchQuery.trim().toLowerCase();
    return _payments.where((p) {
      return p.orderCode.toLowerCase().contains(query) ||
          p.customerName.toLowerCase().contains(query) ||
          p.customerPhone.toLowerCase().contains(query) ||
          p.transactionId.toLowerCase().contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  PaymentStatus? get statusFilter => _statusFilter;
  PaymentMethod? get methodFilter => _methodFilter;
  String get searchQuery => _searchQuery;

  bool get hasMore => _hasMoreByFilter[_filterKey] ?? true;

  String get _filterKey =>
      's:${_statusFilter?.name ?? "all"}|m:${_methodFilter?.name ?? "all"}';

  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    _payments.clear();
    _lastDocsByFilter[_filterKey] = null;
    _hasMoreByFilter[_filterKey] = true;
    notifyListeners();

    try {
      final result = await _service.fetchPage(
        status: _statusFilter,
        method: _methodFilter,
        limit: 20,
      );
      _payments.addAll(result.items);
      _lastDocsByFilter[_filterKey] = result.lastDocument;
      _hasMoreByFilter[_filterKey] = result.hasMore;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore) return;
    final lastDoc = _lastDocsByFilter[_filterKey];
    if (lastDoc == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _service.fetchPage(
        startAfter: lastDoc,
        status: _statusFilter,
        method: _methodFilter,
        limit: 20,
      );
      _payments.addAll(result.items);
      _lastDocsByFilter[_filterKey] = result.lastDocument;
      _hasMoreByFilter[_filterKey] = result.hasMore;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setStatusFilter(PaymentStatus? status) async {
    _statusFilter = status;
    await loadInitial();
  }

  Future<void> setMethodFilter(PaymentMethod? method) async {
    _methodFilter = method;
    await loadInitial();
  }

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  Future<void> syncFromOrders() async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.syncFromOrders();
      // Reload data without clearing existing list
      final result = await _service.fetchPage(
        status: _statusFilter,
        method: _methodFilter,
        limit: 20,
      );
      _payments.clear();
      _payments.addAll(result.items);
      _lastDocsByFilter[_filterKey] = result.lastDocument;
      _hasMoreByFilter[_filterKey] = result.hasMore;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<bool> markAsPaid({
    required String paymentId,
    String note = '',
  }) async {
    return _runAction(() => _service.markAsPaid(paymentId: paymentId, note: note));
  }

  Future<bool> markAsFailed({
    required String paymentId,
    String note = '',
  }) async {
    return _runAction(
      () => _service.markAsFailed(paymentId: paymentId, note: note),
    );
  }

  Future<bool> refund({
    required String paymentId,
    required double amount,
    String note = '',
  }) async {
    return _runAction(
      () => _service.refund(
        paymentId: paymentId,
        amount: amount,
        note: note,
      ),
    );
  }

  Future<bool> reconcile({
    required String paymentId,
    String note = '',
  }) async {
    return _runAction(
      () => _service.reconcile(paymentId: paymentId, note: note),
    );
  }

  Future<List<PaymentModel>> exportCurrentFilter() {
    return _service.fetchAllForExport(
      status: _statusFilter,
      method: _methodFilter,
    );
  }

  Future<List<PaymentModel>> exportAll() {
    return _service.fetchAllForExport();
  }

  Future<bool> _runAction(Future<void> Function() callback) async {
    _errorMessage = null;
    notifyListeners();
    try {
      await callback();
      await loadInitial();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
