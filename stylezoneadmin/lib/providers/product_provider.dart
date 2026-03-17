import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedCategoryId = '';

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedCategoryId => _selectedCategoryId;

  // Filtered products by category
  List<Product> get filteredProducts {
    if (_selectedCategoryId.isEmpty) return _products;
    return _products
        .where((p) => p.categoryId == _selectedCategoryId)
        .toList();
  }

  // Get product count by category
  int getProductCountByCategory(String categoryId) {
    return _products.where((p) => p.categoryId == categoryId).length;
  }

  // Load all products
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productService.getAllProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create product
  Future<bool> createProduct(Product product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productService.createProduct(product);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(Product product, {String? oldCategoryId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _productService.updateProduct(product, oldCategoryId: oldCategoryId);
      await loadProducts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete product (optimistic)
  Future<bool> deleteProduct(String id, String categoryId) async {
    // Optimistic: remove from local list immediately
    final index = _products.indexWhere((p) => p.id == id);
    final removed = index >= 0 ? _products.removeAt(index) : null;
    notifyListeners();

    try {
      await _productService.deleteProduct(id, categoryId);
      return true;
    } catch (e) {
      // Rollback on failure
      if (removed != null && index >= 0) {
        _products.insert(index, removed);
      }
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Filter by category
  void filterByCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  // Clear filter
  void clearFilter() {
    _selectedCategoryId = '';
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
