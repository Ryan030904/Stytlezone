import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/brand_model.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class BrandService with BaseServiceMixin {
  static const String _collectionName = 'brands';

  Future<List<Brand>> getAllBrands() async {
    try {
      ensureAuth();
      final snapshot = await firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Brand.fromJson(doc.data()))
          .where((b) => b.isDeleted != true)
          .toList();
    } catch (e) {
      throw 'Lỗi khi lấy thương hiệu: $e';
    }
  }

  Future<String> createBrand(Brand brand) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(brand.name, 'Tên thương hiệu');

      final docRef = firestore.collection(_collectionName).doc();
      final a = actor();
      final newBrand = brand.copyWith(
        id: docRef.id,
        createdBy: a,
        updatedBy: a,
        isDeleted: false,
      );
      await docRef.set(newBrand.toJson());
      await safeAudit(
        action: AuditAction.create,
        entity: AuditEntity.brand,
        entityId: docRef.id,
        summary: 'Tạo thương hiệu ${newBrand.name}',
      );
      return docRef.id;
    } catch (e) {
      throw 'Lỗi khi tạo thương hiệu: $e';
    }
  }

  Future<void> updateBrand(Brand brand) async {
    try {
      ensureAuth();
      Validators.requireValidId(brand.id, 'Mã thương hiệu');
      Validators.requireNonEmpty(brand.name, 'Tên thương hiệu');

      final a = actor();
      final updatedBrand = brand.copyWith(
        updatedAt: DateTime.now(),
        updatedBy: a,
      );
      await firestore
          .collection(_collectionName)
          .doc(brand.id)
          .update(updatedBrand.toJson());
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.brand,
        entityId: brand.id,
        summary: 'Cập nhật thương hiệu ${updatedBrand.name}',
      );
    } catch (e) {
      throw 'Lỗi khi cập nhật thương hiệu: $e';
    }
  }

  Future<void> deleteBrand(String id) async {
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
        entity: AuditEntity.brand,
        entityId: id,
        summary: 'Xóa thương hiệu',
      );
    } catch (e) {
      throw 'Lỗi khi xóa thương hiệu: $e';
    }
  }

  Future<List<Brand>> searchBrands(String query) async {
    try {
      ensureAuth();
      final snapshot = await firestore
          .collection(_collectionName)
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThan: '${query}z')
          .get();
      return snapshot.docs
          .where((d) => d.data()['isDeleted'] != true)
          .map((doc) => Brand.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Lỗi khi tìm kiếm thương hiệu: $e';
    }
  }
}
