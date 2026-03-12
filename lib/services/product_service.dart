import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/product_model.dart';
import '../models/paginated_result.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class ProductService with BaseServiceMixin {
  static const String _collectionName = 'products';

  Future<List<Product>> getAllProducts() async {
    try {
      ensureAuth();
      final snapshot = await firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .where((p) => p.isDeleted != true)
          .toList();
    } catch (e) {
      dev.log('getAllProducts error: $e', name: 'ProductService');
      throw 'Lỗi khi lấy sản phẩm: $e';
    }
  }

  /// Lấy sản phẩm phân trang
  Future<PaginatedResult<Product>> fetchProductsPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    ensureAuth();
    return fetchPaginated<Product>(
      collection: _collectionName,
      fromJson: Product.fromJson,
      startAfter: startAfter,
      limit: limit,
    );
  }

  Future<List<Product>> getProductsByCategory(String categoryId) async {
    try {
      ensureAuth();
      final snapshot = await firestore
          .collection(_collectionName)
          .where('categoryId', isEqualTo: categoryId)
          .get();
      return snapshot.docs
          .map((doc) => Product.fromJson(doc.data()))
          .where((p) => p.isDeleted != true)
          .toList();
    } catch (e) {
      dev.log('getProductsByCategory error: $e', name: 'ProductService');
      throw 'Lỗi khi lấy sản phẩm theo danh mục: $e';
    }
  }

  Future<String> createProduct(Product product) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(product.name, 'Tên sản phẩm');
      Validators.requireNonNegative(product.price, 'Giá sản phẩm');
      Validators.requireNonNegative(product.stock, 'Số lượng tồn kho');

      final docRef = firestore.collection(_collectionName).doc();
      final a = actor();
      final newProduct = product.copyWith(
        id: docRef.id,
        createdBy: a,
        updatedBy: a,
        isDeleted: false,
      );
      await docRef.set(newProduct.toJson());
      await _updateCategoryProductCount(product.categoryId, 1);
      await safeAudit(
        action: AuditAction.create,
        entity: AuditEntity.product,
        entityId: docRef.id,
        summary: 'Tạo sản phẩm ${newProduct.name}',
      );
      return docRef.id;
    } catch (e) {
      dev.log('createProduct error: $e', name: 'ProductService');
      throw 'Lỗi khi tạo sản phẩm: $e';
    }
  }

  Future<void> updateProduct(Product product, {String? oldCategoryId}) async {
    try {
      ensureAuth();
      Validators.requireValidId(product.id, 'Mã sản phẩm');
      Validators.requireNonEmpty(product.name, 'Tên sản phẩm');
      Validators.requireNonNegative(product.price, 'Giá sản phẩm');

      final updatedProduct = product.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: actor(),
      );
      await firestore
          .collection(_collectionName)
          .doc(product.id)
          .set(updatedProduct.toJson(), SetOptions(merge: true));

      if (oldCategoryId != null && oldCategoryId != product.categoryId) {
        await _updateCategoryProductCount(oldCategoryId, -1);
        await _updateCategoryProductCount(product.categoryId, 1);
      }
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.product,
        entityId: product.id,
        summary: 'Cập nhật sản phẩm ${updatedProduct.name}',
      );
    } catch (e) {
      dev.log('updateProduct error: $e', name: 'ProductService');
      throw 'Lỗi khi cập nhật sản phẩm: $e';
    }
  }

  Future<void> deleteProduct(String id, String categoryId) async {
    try {
      ensureAuth();
      await firestore.collection(_collectionName).doc(id).update({
        'isDeleted': true,
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
      });
      await _updateCategoryProductCount(categoryId, -1);
      await safeAudit(
        action: AuditAction.softDelete,
        entity: AuditEntity.product,
        entityId: id,
        summary: 'Xóa sản phẩm',
      );
    } catch (e) {
      dev.log('deleteProduct error: $e', name: 'ProductService');
      throw 'Lỗi khi xóa sản phẩm: $e';
    }
  }

  Future<void> _updateCategoryProductCount(String categoryId, int delta) async {
    try {
      if (categoryId.isEmpty) return;
      await firestore.collection('categories').doc(categoryId).update({
        'productCount': FieldValue.increment(delta),
      });
    } catch (e) {
      dev.log('updateCategoryProductCount error: $e', name: 'ProductService');
    }
  }
}
