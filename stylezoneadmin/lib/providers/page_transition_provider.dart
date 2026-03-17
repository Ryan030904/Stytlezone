import 'package:flutter/material.dart';

class PageTransitionProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _loadingMessage;

  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;

  void startLoading({String? message}) {
    _isLoading = true;
    _loadingMessage = message ?? 'Loading...';
    notifyListeners();
  }

  void stopLoading() {
    _isLoading = false;
    _loadingMessage = null;
    notifyListeners();
  }

  // Runs only the real async operation, no fake delay.
  Future<void> withLoading(
    Future<void> Function() operation, {
    String? message,
  }) async {
    startLoading(message: message);
    try {
      await operation();
    } finally {
      stopLoading();
    }
  }
}
