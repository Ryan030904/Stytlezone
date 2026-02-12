import 'package:flutter/material.dart';
import '../models/promotion_model.dart';
import '../services/promotion_service.dart';

class PromotionProvider extends ChangeNotifier {
  final PromotionService _service = PromotionService();

  List<Promotion> _promotions = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Promotion> get promotions => _promotions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadPromotions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _promotions = await _service.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createPromotion(Promotion promo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.create(promo);
      await loadPromotions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePromotion(Promotion promo) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.update(promo);
      await loadPromotions();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePromotion(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.delete(id);
      await loadPromotions();
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
