import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../services/banner_service.dart';

class BannerProvider extends ChangeNotifier {
  final BannerService _service = BannerService();

  List<BannerModel> _banners = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBanners() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _banners = await _service.getAll();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createBanner(BannerModel banner) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.create(banner);
      await loadBanners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBanner(BannerModel banner) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.update(banner);
      await loadBanners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBanner(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _service.delete(id);
      await loadBanners();
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

