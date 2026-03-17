import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brand_model.dart';
import '../services/brand_service.dart';

class BrandProvider extends ChangeNotifier {
  final BrandService _brandService = BrandService();

  List<Brand> _brands = [];
  bool _isLoading = false;
  String? _errorMessage;
  Brand? _selectedBrand;

  List<Brand> get brands => _brands;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Brand? get selectedBrand => _selectedBrand;

  // Load all brands with real product counts
  Future<void> loadBrands() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _brands = await _brandService.getAllBrands();

      // Query all products to count per brand
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();

      final Map<String, int> countMap = {};
      for (final doc in productsSnapshot.docs) {
        if (doc.data()['isDeleted'] == true) continue;
        final brandName = doc.data()['brandName'] as String? ?? '';
        if (brandName.isNotEmpty) {
          countMap[brandName] = (countMap[brandName] ?? 0) + 1;
        }
      }

      // Update each brand with real product count
      _brands = _brands.map((brand) {
        final realCount = countMap[brand.name] ?? 0;
        return brand.copyWith(productCount: realCount);
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create brand
  Future<bool> createBrand(Brand brand) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _brandService.createBrand(brand);
      await loadBrands();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update brand
  Future<bool> updateBrand(Brand brand) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _brandService.updateBrand(brand);
      await loadBrands();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete brand (optimistic)
  Future<bool> deleteBrand(String id) async {
    final index = _brands.indexWhere((b) => b.id == id);
    final removed = index >= 0 ? _brands.removeAt(index) : null;
    notifyListeners();

    try {
      await _brandService.deleteBrand(id);
      return true;
    } catch (e) {
      if (removed != null && index >= 0) {
        _brands.insert(index, removed);
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Search brands
  Future<void> searchBrands(String query) async {
    if (query.isEmpty) {
      await loadBrands();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _brands = await _brandService.searchBrands(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select brand
  void selectBrand(Brand brand) {
    _selectedBrand = brand;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedBrand = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
