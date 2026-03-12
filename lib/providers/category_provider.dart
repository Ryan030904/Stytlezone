import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategoryProvider extends ChangeNotifier {
  final CategoryService _categoryService = CategoryService();
  
  List<Category> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  Category? _selectedCategory;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Category? get selectedCategory => _selectedCategory;

  // Load all categories with real product counts
  Future<void> loadCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryService.getAllCategories();
      
      // Query all products to count per category
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();
      
      // Build a map: categoryName -> count
      final Map<String, int> countMap = {};
      for (final doc in productsSnapshot.docs) {
        if (doc.data()['isDeleted'] == true) {
          continue;
        }
        final catName = doc.data()['categoryName'] as String? ?? '';
        if (catName.isNotEmpty) {
          countMap[catName] = (countMap[catName] ?? 0) + 1;
        }
      }
      
      // Update each category with the real product count
      _categories = _categories.map((cat) {
        final realCount = countMap[cat.name] ?? 0;
        return cat.copyWith(productCount: realCount);
      }).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create category
  Future<bool> createCategory(Category category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryService.createCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update category
  Future<bool> updateCategory(Category category) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryService.updateCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete category
  Future<bool> deleteCategory(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _categoryService.deleteCategory(id);
      await loadCategories();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Search categories
  Future<void> searchCategories(String query) async {
    if (query.isEmpty) {
      await loadCategories();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _categoryService.searchCategories(query);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Select category
  void selectCategory(Category category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Clear selection
  void clearSelection() {
    _selectedCategory = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
