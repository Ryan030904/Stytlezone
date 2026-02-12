import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'products';

  // Get all active products
  Future<List<Product>> getActiveProducts() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Loi khi lay san pham: ${e.toString()}';
    }
  }

  // Get new arrivals (latest products)
  Future<List<Product>> getNewArrivals({int limit = 8}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Loi khi lay san pham moi: ${e.toString()}';
    }
  }

  // Get products on sale
  Future<List<Product>> getSaleProducts({int limit = 8}) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final products = snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .where((p) => p.isOnSale)
          .take(limit)
          .toList();

      return products;
    } catch (e) {
      throw 'Loi khi lay san pham giam gia: ${e.toString()}';
    }
  }

  // Get products by category
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('categoryId', isEqualTo: categoryId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Loi khi lay san pham theo danh muc: ${e.toString()}';
    }
  }

  // Search products
  Future<List<Product>> searchProducts(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .startAt([query])
          .endAt(['${query}\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Loi khi tim kiem san pham: ${e.toString()}';
    }
  }
}
