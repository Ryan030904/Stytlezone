import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';

/// Provider for store settings — fetch, update, save to Firestore.
class SettingsProvider extends ChangeNotifier {
  final SettingsService _service = SettingsService();

  StoreSettings _settings = const StoreSettings();
  StoreSettings get settings => _settings;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  bool _hasUnsavedChanges = false;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  /// Fetch settings from Firestore.
  Future<void> fetchSettings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _settings = await _service.getSettings();
    } catch (e) {
      _error = 'Không thể tải cài đặt: $e';
    } finally {
      _isLoading = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// Update local settings (does NOT save to Firestore yet).
  void updateSettings(StoreSettings newSettings) {
    _settings = newSettings;
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  /// Persist current settings to Firestore.
  Future<bool> saveSettings() async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _service.saveSettings(_settings);
      _hasUnsavedChanges = false;
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Lưu cài đặt thất bại: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }
}
