import 'package:flutter/material.dart';

/// Provider quản lý trạng thái dark/light mode — đơn giản, nhẹ.
class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  void toggle() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}
