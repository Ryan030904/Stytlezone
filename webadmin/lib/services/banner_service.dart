import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/banner_model.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class BannerService with BaseServiceMixin {
  static const String _collection = 'banners';

  Future<List<BannerModel>> getAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_collection)
          .orderBy('sortOrder')
          .get();
      return snap.docs
          .where((d) => d.data()['isDeleted'] != true)
          .map((d) => BannerModel.fromJson(d.data()))
          .toList();
    } catch (e) {
      dev.log('getAll banners error: $e', name: 'BannerService');
      throw 'Lỗi khi lấy banner: $e';
    }
  }

  Future<String> create(BannerModel banner) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(banner.title, 'Tiêu đề banner');

      final docRef = firestore.collection(_collection).doc();
      final a = actor();
      final data = banner
          .copyWith(
            id: docRef.id,
            createdBy: a,
            updatedBy: a,
            isDeleted: false,
          )
          .toJson();
      await docRef.set(data);
      await safeAudit(
        action: AuditAction.create,
        entity: AuditEntity.cms,
        entityId: docRef.id,
        summary: 'Tạo banner "${data['title']}"',
      );
      return docRef.id;
    } catch (e) {
      dev.log('create banner error: $e', name: 'BannerService');
      throw 'Lỗi khi tạo banner: $e';
    }
  }

  Future<void> update(BannerModel banner) async {
    try {
      ensureAuth();
      Validators.requireValidId(banner.id, 'Mã banner');

      final data = banner
          .copyWith(
            updatedAt: DateTime.now(),
            updatedBy: actor(),
          )
          .toJson();
      await firestore.collection(_collection).doc(banner.id).set(data, SetOptions(merge: true));
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.cms,
        entityId: banner.id,
        summary: 'Cập nhật banner "${banner.title}"',
      );
    } catch (e) {
      dev.log('update banner error: $e', name: 'BannerService');
      throw 'Lỗi khi cập nhật banner: $e';
    }
  }

  Future<void> delete(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'isDeleted': true,
        'status': 'draft',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
      });
      await safeAudit(
        action: AuditAction.softDelete,
        entity: AuditEntity.cms,
        entityId: id,
        summary: 'Xóa banner',
      );
    } catch (e) {
      dev.log('delete banner error: $e', name: 'BannerService');
      throw 'Lỗi khi xóa banner: $e';
    }
  }

  Future<void> reorder(List<BannerModel> banners) async {
    try {
      ensureAuth();
      final batch = firestore.batch();
      for (var i = 0; i < banners.length; i++) {
        batch.update(
          firestore.collection(_collection).doc(banners[i].id),
          {'sortOrder': i, 'updatedAt': Timestamp.fromDate(DateTime.now())},
        );
      }
      await batch.commit();
    } catch (e) {
      dev.log('reorder banners error: $e', name: 'BannerService');
      throw 'Lỗi khi sắp xếp banner: $e';
    }
  }
}
