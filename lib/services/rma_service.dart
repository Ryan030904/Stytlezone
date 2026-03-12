import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/rma_model.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class RmaService with BaseServiceMixin {
  static const String _collection = 'rmas';

  /// Lấy tất cả phiếu RMA (không bao gồm đã xóa mềm)
  Future<List<RmaModel>> getAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_collection)
          .orderBy('updatedAt', descending: true)
          .get();
      return snap.docs
          .where((d) => d.data()['isDeleted'] != true)
          .map((d) => RmaModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      dev.log('getAll RMAs error: $e', name: 'RmaService');
      throw 'Lỗi khi lấy danh sách đổi trả: $e';
    }
  }

  /// Tạo phiếu RMA mới
  Future<String> create(RmaModel rma) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(rma.customerName, 'Tên khách hàng');
      Validators.requireNonEmptyList(rma.items, 'Danh sách sản phẩm đổi trả');

      final docRef = firestore.collection(_collection).doc();
      final a = actor();
      final now = DateTime.now();
      final code = _generateCode(now);

      final data = rma
          .copyWith(
            id: docRef.id,
            code: code,
            createdBy: a,
            updatedBy: a,
            createdAt: now,
            updatedAt: now,
            isDeleted: false,
          )
          .toJson();

      await docRef.set(data);
      await safeAudit(
        action: AuditAction.create,
        entity: AuditEntity.rma,
        entityId: docRef.id,
        summary: 'Tạo phiếu đổi trả "$code" cho KH: ${rma.customerName}',
      );
      return docRef.id;
    } catch (e) {
      dev.log('create RMA error: $e', name: 'RmaService');
      throw 'Lỗi khi tạo phiếu đổi trả: $e';
    }
  }

  /// Cập nhật phiếu RMA
  Future<void> update(RmaModel rma) async {
    try {
      ensureAuth();
      Validators.requireValidId(rma.id, 'Mã phiếu RMA');

      final data = rma
          .copyWith(
            updatedAt: DateTime.now(),
            updatedBy: actor(),
          )
          .toJson();

      await firestore.collection(_collection).doc(rma.id).set(data, SetOptions(merge: true));
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.rma,
        entityId: rma.id,
        summary: 'Cập nhật phiếu đổi trả "${rma.code}"',
      );
    } catch (e) {
      dev.log('update RMA error: $e', name: 'RmaService');
      throw 'Lỗi khi cập nhật phiếu đổi trả: $e';
    }
  }

  /// Cập nhật trạng thái phiếu RMA
  Future<void> updateStatus(String id, RmaStatus newStatus, {String note = ''}) async {
    try {
      ensureAuth();
      Validators.requireValidId(id, 'Mã phiếu RMA');

      final now = DateTime.now();
      final a = actor();
      final updates = <String, dynamic>{
        'status': newStatus.name,
        'updatedAt': Timestamp.fromDate(now),
        'updatedBy': a,
      };
      if (note.isNotEmpty) {
        updates['adminNote'] = note;
      }
      if (newStatus == RmaStatus.completed) {
        updates['resolution'] = 'Đã hoàn tất xử lý';
      }

      await firestore.collection(_collection).doc(id).update(updates);
      await safeAudit(
        action: AuditAction.statusChange,
        entity: AuditEntity.rma,
        entityId: id,
        summary: 'Đổi trạng thái phiếu RMA → ${_statusLabel(newStatus)}',
      );
    } catch (e) {
      dev.log('updateStatus RMA error: $e', name: 'RmaService');
      throw 'Lỗi khi cập nhật trạng thái: $e';
    }
  }

  /// Xóa mềm phiếu RMA
  Future<void> delete(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'isDeleted': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
      });
      await safeAudit(
        action: AuditAction.softDelete,
        entity: AuditEntity.rma,
        entityId: id,
        summary: 'Xóa phiếu đổi trả',
      );
    } catch (e) {
      dev.log('delete RMA error: $e', name: 'RmaService');
      throw 'Lỗi khi xóa phiếu đổi trả: $e';
    }
  }

  String _generateCode(DateTime now) {
    final date = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final rand = now.millisecondsSinceEpoch.toString().substring(8);
    return 'RMA-$date-$rand';
  }

  String _statusLabel(RmaStatus s) {
    switch (s) {
      case RmaStatus.pendingReview:
        return 'Chờ duyệt';
      case RmaStatus.approved:
        return 'Đã duyệt';
      case RmaStatus.rejected:
        return 'Từ chối';
      case RmaStatus.processing:
        return 'Đang xử lý';
      case RmaStatus.completed:
        return 'Hoàn tất';
    }
  }
}
