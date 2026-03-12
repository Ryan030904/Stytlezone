import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/category_model.dart';
import '../models/paginated_result.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class CategoryService with BaseServiceMixin {
  static const String _collectionName = 'categories';

  Future<List<Category>> getAllCategories() async {
    try {
      ensureAuth();
      final snapshot = await firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Category.fromJson(doc.data()))
          .where((c) => c.isDeleted != true)
          .toList();
    } catch (e) {
      throw 'Lỗi khi lấy danh mục: $e';
    }
  }

  /// Lấy danh mục phân trang
  Future<PaginatedResult<Category>> fetchCategoriesPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    ensureAuth();
    return fetchPaginated<Category>(
      collection: _collectionName,
      fromJson: Category.fromJson,
      startAfter: startAfter,
      limit: limit,
    );
  }

  Future<Category?> getCategoryById(String id) async {
    try {
      ensureAuth();
      final doc = await firestore.collection(_collectionName).doc(id).get();
      if (doc.exists) {
        return Category.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Lỗi khi lấy danh mục: $e';
    }
  }

  Future<String> createCategory(Category category) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(category.name, 'Tên danh mục');

      final docRef = firestore.collection(_collectionName).doc();
      final a = actor();
      final newCategory = category.copyWith(
        id: docRef.id,
        createdBy: a,
        updatedBy: a,
        isDeleted: false,
      );
      await docRef.set(newCategory.toJson());
      await safeAudit(
        action: AuditAction.create,
        entity: AuditEntity.category,
        entityId: docRef.id,
        summary: 'Tạo danh mục ${newCategory.name}',
      );
      return docRef.id;
    } catch (e) {
      throw 'Lỗi khi tạo danh mục: $e';
    }
  }

  Future<void> updateCategory(Category category) async {
    try {
      ensureAuth();
      Validators.requireValidId(category.id, 'Mã danh mục');
      Validators.requireNonEmpty(category.name, 'Tên danh mục');

      final a = actor();
      final updatedCategory = category.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: a,
      );
      await firestore
          .collection(_collectionName)
          .doc(category.id)
          .update(updatedCategory.toJson());
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.category,
        entityId: category.id,
        summary: 'Cập nhật danh mục ${updatedCategory.name}',
      );
    } catch (e) {
      throw 'Lỗi khi cập nhật danh mục: $e';
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collectionName).doc(id).update({
        'isDeleted': true,
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
      });
      await safeAudit(
        action: AuditAction.softDelete,
        entity: AuditEntity.category,
        entityId: id,
        summary: 'Xóa danh mục',
      );
    } catch (e) {
      throw 'Lỗi khi xóa danh mục: $e';
    }
  }

  Future<List<Category>> searchCategories(String query) async {
    try {
      ensureAuth();
      final snapshot = await firestore
          .collection(_collectionName)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();
      return snapshot.docs
          .where((d) => d.data()['isDeleted'] != true)
          .map((doc) => Category.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Lỗi khi tìm kiếm danh mục: $e';
    }
  }

  Stream<List<Category>> streamCategories() {
    return firestore
        .collection(_collectionName)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .where((d) => d.data()['isDeleted'] != true)
            .map((doc) => Category.fromJson(doc.data()))
            .toList());
  }
}
