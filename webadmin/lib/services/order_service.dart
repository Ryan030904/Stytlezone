import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'dart:developer' as dev;
import '../models/order_model.dart';
import '../models/paginated_result.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class OrderService with BaseServiceMixin {
  static const String _col = 'orders';

  Future<List<Order>> getAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_col)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) => Order.fromJson(d.data()))
          .where((o) => o.isDeleted != true)
          .toList();
    } catch (e) {
      dev.log('getAll orders error: $e', name: 'OrderService');
      throw 'Lỗi khi lấy đơn hàng: $e';
    }
  }

  /// Lấy đơn hàng phân trang
  Future<PaginatedResult<Order>> fetchOrdersPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    ensureAuth();
    return fetchPaginated<Order>(
      collection: _col,
      fromJson: Order.fromJson,
      startAfter: startAfter,
      limit: limit,
    );
  }

  Future<String> create(Order order) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(order.customerName, 'Tên khách hàng');
      Validators.requireNonNegative(order.total, 'Tổng tiền');

      final docRef = firestore.collection(_col).doc();
      final a = actor();
      final data = order
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
        entity: AuditEntity.order,
        entityId: docRef.id,
        summary: 'Tạo đơn hàng ${data['code']}',
      );
      return docRef.id;
    } catch (e) {
      dev.log('create order error: $e', name: 'OrderService');
      throw 'Lỗi khi tạo đơn hàng: $e';
    }
  }

  Future<void> update(Order order) async {
    try {
      ensureAuth();
      Validators.requireValidId(order.id, 'Mã đơn hàng');
      final data = order
          .copyWith(
            updatedAt: DateTime.now(),
            updatedBy: actor(),
          )
          .toJson();
      await firestore.collection(_col).doc(order.id).set(data, SetOptions(merge: true));
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.order,
        entityId: order.id,
        summary: 'Cập nhật đơn hàng ${order.code}',
      );
    } catch (e) {
      dev.log('update order error: $e', name: 'OrderService');
      throw 'Lỗi khi cập nhật đơn hàng: $e';
    }
  }

  Future<void> updateStatus(String id, String newStatus, {String note = ''}) async {
    try {
      ensureAuth();
      Validators.requireValidId(id, 'Mã đơn hàng');
      Validators.requireNonEmpty(newStatus, 'Trạng thái mới');

      final docRef = firestore.collection(_col).doc(id);
      final snap = await docRef.get();
      if (!snap.exists) throw 'Đơn hàng không tồn tại';
      final order = Order.fromJson(snap.data()!);
      final log = ActivityEntry(
        action: 'Cập nhật trạng thái → $newStatus',
        note: note,
        timestamp: DateTime.now(),
      );
      final updated = order.copyWith(
        status: newStatus,
        activityLog: [...order.activityLog, log],
        updatedAt: DateTime.now(),
        updatedBy: actor(),
      );
      await docRef.set(updated.toJson(), SetOptions(merge: true));
      await safeAudit(
        action: AuditAction.statusChange,
        entity: AuditEntity.order,
        entityId: id,
        summary: 'Cập nhật trạng thái đơn hàng → $newStatus',
        newSummary: note,
      );
    } catch (e) {
      dev.log('updateStatus order error: $e', name: 'OrderService');
      throw 'Lỗi cập nhật trạng thái: $e';
    }
  }

  Future<void> bulkUpdateStatus(List<String> ids, String newStatus) async {
    ensureAuth();
    final batch = firestore.batch();
    for (final id in ids) {
      final docRef = firestore.collection(_col).doc(id);
      batch.update(docRef, {
        'status': newStatus,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
        'activityLog': FieldValue.arrayUnion([
          ActivityEntry(
            action: 'Bulk: → $newStatus',
            timestamp: DateTime.now(),
          ).toJson(),
        ]),
      });
    }
    await batch.commit();
    await safeAudit(
      action: AuditAction.statusChange,
      entity: AuditEntity.order,
      entityId: 'bulk',
      summary: 'Cập nhật hàng loạt ${ids.length} đơn hàng → $newStatus',
    );
  }

  Future<void> delete(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_col).doc(id).update({
        'isDeleted': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
      });
      await safeAudit(
        action: AuditAction.softDelete,
        entity: AuditEntity.order,
        entityId: id,
        summary: 'Xóa đơn hàng',
      );
    } catch (e) {
      throw 'Lỗi xóa đơn hàng: $e';
    }
  }
}
