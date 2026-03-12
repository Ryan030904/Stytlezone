import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/promotion_model.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class PromotionService with BaseServiceMixin {
  static const String _collection = 'promotions';

  Future<List<Promotion>> getAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .where((d) => d.data()['isDeleted'] != true)
          .map((d) => Promotion.fromJson(d.data()))
          .toList();
    } catch (e) {
      dev.log('getAll promotions error: $e', name: 'PromotionService');
      throw 'Lỗi khi lấy khuyến mãi: $e';
    }
  }

  Future<String> create(Promotion promo) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(promo.code, 'Mã khuyến mãi');

      final docRef = firestore.collection(_collection).doc();
      final a = actor();
      final data = promo
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
        entity: AuditEntity.promotion,
        entityId: docRef.id,
        summary: 'Tạo khuyến mãi ${data['code']}',
      );
      return docRef.id;
    } catch (e) {
      dev.log('create promotion error: $e', name: 'PromotionService');
      throw 'Lỗi khi tạo khuyến mãi: $e';
    }
  }

  Future<void> update(Promotion promo) async {
    try {
      ensureAuth();
      Validators.requireValidId(promo.id, 'Mã khuyến mãi');

      final data = promo
          .copyWith(
            updatedAt: DateTime.now(),
            updatedBy: actor(),
          )
          .toJson();
      await firestore.collection(_collection).doc(promo.id).set(data, SetOptions(merge: true));
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.promotion,
        entityId: promo.id,
        summary: 'Cập nhật khuyến mãi ${promo.code}',
      );
    } catch (e) {
      dev.log('update promotion error: $e', name: 'PromotionService');
      throw 'Lỗi khi cập nhật khuyến mãi: $e';
    }
  }

  Future<void> delete(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'isDeleted': true,
        'isActive': false,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
      });
      await safeAudit(
        action: AuditAction.softDelete,
        entity: AuditEntity.promotion,
        entityId: id,
        summary: 'Xóa khuyến mãi',
      );
    } catch (e) {
      dev.log('delete promotion error: $e', name: 'PromotionService');
      throw 'Lỗi khi xóa khuyến mãi: $e';
    }
  }
}
