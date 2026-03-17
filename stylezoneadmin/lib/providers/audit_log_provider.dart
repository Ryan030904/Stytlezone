import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../constants/admin_enums.dart';
import '../models/audit_log_model.dart';
import '../services/audit_log_service.dart';

class AuditLogProvider extends ChangeNotifier {
  final AuditLogService _service = AuditLogService();

  final List<AuditLogModel> _logs = [];
  final Map<String, DocumentSnapshot<Map<String, dynamic>>?> _lastDocsByFilter =
      {};
  final Map<String, bool> _hasMoreByFilter = {};

  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  AuditEntity? _selectedEntity;
  AuditAction? _selectedAction;
  String _searchQuery = '';

  List<AuditLogModel> get logs {
    if (_searchQuery.trim().isEmpty) return _logs;
    final query = _searchQuery.trim().toLowerCase();
    return _logs.where((log) {
      return log.summary.toLowerCase().contains(query) ||
          log.entityId.toLowerCase().contains(query) ||
          log.actorEmail.toLowerCase().contains(query) ||
          log.actorUid.toLowerCase().contains(query);
    }).toList();
  }

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMoreByFilter[_filterKey] ?? true;
  String? get errorMessage => _errorMessage;
  AuditEntity? get selectedEntity => _selectedEntity;
  AuditAction? get selectedAction => _selectedAction;
  String get searchQuery => _searchQuery;

  String get _filterKey =>
      'e:${_selectedEntity?.name ?? "all"}|a:${_selectedAction?.name ?? "all"}';

  Future<void> loadInitial() async {
    _isLoading = true;
    _errorMessage = null;
    _logs.clear();
    _lastDocsByFilter[_filterKey] = null;
    _hasMoreByFilter[_filterKey] = true;
    notifyListeners();

    try {
      final result = await _service.fetchPage(
        limit: 20,
        entity: _selectedEntity,
        action: _selectedAction,
      );
      _logs.addAll(result.items);
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
        limit: 20,
        entity: _selectedEntity,
        action: _selectedAction,
      );
      _logs.addAll(result.items);
      _lastDocsByFilter[_filterKey] = result.lastDocument;
      _hasMoreByFilter[_filterKey] = result.hasMore;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> setEntityFilter(AuditEntity? entity) async {
    _selectedEntity = entity;
    await loadInitial();
  }

  Future<void> setActionFilter(AuditAction? action) async {
    _selectedAction = action;
    await loadInitial();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<List<AuditLogModel>> exportCurrentFilter() {
    return _service.fetchAllForExport(
      entity: _selectedEntity,
      action: _selectedAction,
    );
  }

  Future<List<AuditLogModel>> exportAll() {
    return _service.fetchAllForExport();
  }

  Future<void> log({
    required AuditAction action,
    required AuditEntity entity,
    required String entityId,
    required String summary,
    String oldSummary = '',
    String newSummary = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    await _service.log(
      action: action,
      entity: entity,
      entityId: entityId,
      summary: summary,
      oldSummary: oldSummary,
      newSummary: newSummary,
      metadata: metadata,
    );
  }
}
