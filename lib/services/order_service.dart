import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'dart:developer' as dev;
import '../models/order_model.dart';
import '../models/paginated_result.dart';
import '../models/notification_model.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';
import 'notification_service.dart';

class OrderService with BaseServiceMixin {
  static const String _col = 'orders';
  final NotificationService _notifService = NotificationService();

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
      // Fire notification
      try {
        await _notifService.create(
          title: 'Đơn hàng mới',
          message: 'Đơn ${data['code']} - ${order.customerName} - ${order.formattedTotal}',
          type: NotificationType.order,
          entityId: docRef.id,
          entityType: 'order',
        );
      } catch (_) {}
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

  /// Statuses where stock has already been deducted
  static const _stockDeductedStatuses = ['Đang giao', 'Đã giao'];

  Future<void> updateStatus(String id, String newStatus, {String note = ''}) async {
    try {
      ensureAuth();
      Validators.requireValidId(id, 'Mã đơn hàng');
      Validators.requireNonEmpty(newStatus, 'Trạng thái mới');

      final docRef = firestore.collection(_col).doc(id);
      final snap = await docRef.get();
      if (!snap.exists) throw 'Đơn hàng không tồn tại';
      final order = Order.fromJson(snap.data()!);
      final oldStatus = order.status;

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

      // ── Stock adjustment based on status transition ──
      await _adjustStockForStatusChange(order, oldStatus, newStatus);

      await safeAudit(
        action: AuditAction.statusChange,
        entity: AuditEntity.order,
        entityId: id,
        summary: 'Cập nhật trạng thái đơn hàng → $newStatus',
        newSummary: note,
      );
      // Fire notification
      try {
        await _notifService.create(
          title: 'Cập nhật đơn hàng',
          message: 'Đơn ${order.code} → $newStatus',
          type: NotificationType.order,
          entityId: id,
          entityType: 'order',
        );
      } catch (_) {}
    } catch (e) {
      dev.log('updateStatus order error: $e', name: 'OrderService');
      throw 'Lỗi cập nhật trạng thái: $e';
    }
  }

  /// Adjust product stock when order status transitions.
  /// - Moving INTO "Đang giao" (from non-deducted state) → decrease stock
  /// - Moving INTO "Hoàn trả" (from stock-deducted state) → restore stock
  /// - "Đã hủy" never affects stock (cancel happens before shipping)
  Future<void> _adjustStockForStatusChange(
    Order order, String oldStatus, String newStatus,
  ) async {
    if (order.items.isEmpty) return;

    final wasDeducted = _stockDeductedStatuses.contains(oldStatus);
    final willDeduct = _stockDeductedStatuses.contains(newStatus);
    final isReturning = newStatus == 'Hoàn trả';

    // Case 1: Transitioning into a deducted status from a non-deducted status
    // e.g. "Đã xác nhận" → "Đang giao" = decrease stock
    if (willDeduct && !wasDeducted) {
      await _batchUpdateStock(order.items, decrease: true);
      dev.log('Stock decreased for order ${order.code}', name: 'OrderService');
    }
    // Case 2: Customer returns product after delivery
    // e.g. "Đã giao" → "Hoàn trả" = restore stock
    else if (isReturning && wasDeducted) {
      await _batchUpdateStock(order.items, decrease: false);
      dev.log('Stock restored for returned order ${order.code}', name: 'OrderService');
    }
  }

  /// Batch update product stock using atomic FieldValue.increment
  Future<void> _batchUpdateStock(List<OrderItem> items, {required bool decrease}) async {
    final batch = firestore.batch();
    for (final item in items) {
      if (item.productId.isEmpty) continue;
      final prodRef = firestore.collection('products').doc(item.productId);
      batch.update(prodRef, {
        'stock': FieldValue.increment(decrease ? -item.quantity : item.quantity),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
  }

  Future<void> bulkUpdateStatus(List<String> ids, String newStatus) async {
    ensureAuth();
    final batch = firestore.batch();
    final ordersForStock = <Order>[];

    for (final id in ids) {
      final docRef = firestore.collection(_col).doc(id);
      // Read current order to get old status & items for stock adjustment
      final snap = await docRef.get();
      if (snap.exists) {
        ordersForStock.add(Order.fromJson(snap.data()!));
      }
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

    // Adjust stock for each order based on status transition
    for (final order in ordersForStock) {
      await _adjustStockForStatusChange(order, order.status, newStatus);
    }

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
