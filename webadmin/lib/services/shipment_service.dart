import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/shipment_model.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class ShipmentService with BaseServiceMixin {
  static const String _col = 'shipments';

  Future<List<Shipment>> getAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_col)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .where((d) => d.data()['isDeleted'] != true)
          .map((d) => Shipment.fromJson(d.data()))
          .toList();
    } catch (e) {
      dev.log('getAll shipments error: $e', name: 'ShipmentService');
      throw 'Lỗi khi lấy vận đơn: $e';
    }
  }

  Future<String> create(Shipment s) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(s.trackingCode, 'Mã vận đơn');

      final docRef = firestore.collection(_col).doc();
      final a = actor();
      final data = s
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
        entity: AuditEntity.shipment,
        entityId: docRef.id,
        summary: 'Tạo vận đơn ${data['trackingCode']}',
      );
      return docRef.id;
    } catch (e) {
      throw 'Lỗi tạo vận đơn: $e';
    }
  }

  Future<void> update(Shipment s) async {
    try {
      ensureAuth();
      Validators.requireValidId(s.id, 'Mã vận đơn');

      await firestore.collection(_col).doc(s.id).set(
            s
                .copyWith(
                  updatedAt: DateTime.now(),
                  updatedBy: actor(),
                )
                .toJson(),
            SetOptions(merge: true),
          );
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.shipment,
        entityId: s.id,
        summary: 'Cập nhật vận đơn ${s.trackingCode}',
      );
    } catch (e) {
      throw 'Lỗi cập nhật vận đơn: $e';
    }
  }

  /// Cập nhật trạng thái + thêm tracking entry + sync đơn hàng nếu đã giao
  Future<void> updateStatus(String id, String newStatus, {String location = '', String note = ''}) async {
    try {
      ensureAuth();
      Validators.requireValidId(id, 'Mã vận đơn');
      Validators.requireNonEmpty(newStatus, 'Trạng thái mới');

      final docRef = firestore.collection(_col).doc(id);
      final snap = await docRef.get();
      if (!snap.exists) throw 'Vận đơn không tồn tại';
      final ship = Shipment.fromJson(snap.data()!);
      final entry = TrackingEntry(status: newStatus, location: location, note: note, timestamp: DateTime.now());
      final updated = ship.copyWith(
        status: newStatus,
        updatedBy: actor(),
        trackingHistory: [...ship.trackingHistory, entry],
        deliveredAt: newStatus == ShipmentStatus.delivered ? DateTime.now() : ship.deliveredAt,
        updatedAt: DateTime.now(),
      );
      await docRef.set(updated.toJson(), SetOptions(merge: true));

      // Auto sync order status
      if (newStatus == ShipmentStatus.delivered && ship.orderId.isNotEmpty) {
        await firestore.collection('orders').doc(ship.orderId).update({
          'status': 'Đã giao',
          'updatedBy': actor(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'activityLog': FieldValue.arrayUnion([{
            'action': 'Vận chuyển: Đã giao thành công',
            'note': 'Tự động từ vận đơn ${ship.trackingCode}',
            'timestamp': Timestamp.fromDate(DateTime.now()),
          }]),
        });
      }
      await safeAudit(
        action: AuditAction.statusChange,
        entity: AuditEntity.shipment,
        entityId: id,
        summary: 'Cập nhật trạng thái vận đơn → $newStatus',
        newSummary: note,
      );
    } catch (e) {
      throw 'Lỗi cập nhật trạng thái: $e';
    }
  }

  Future<void> bulkUpdateStatus(List<String> ids, String newStatus) async {
    ensureAuth();
    final batch = firestore.batch();
    for (final id in ids) {
      batch.update(firestore.collection(_col).doc(id), {
        'status': newStatus,
        'updatedBy': actor(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    await batch.commit();
    await safeAudit(
      action: AuditAction.statusChange,
      entity: AuditEntity.shipment,
      entityId: 'bulk',
      summary: 'Cập nhật hàng loạt ${ids.length} vận đơn → $newStatus',
    );
  }

  Future<void> delete(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_col).doc(id).update({
        'isDeleted': true,
        'updatedBy': actor(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
      await safeAudit(
        action: AuditAction.softDelete,
        entity: AuditEntity.shipment,
        entityId: id,
        summary: 'Xóa vận đơn',
      );
    } catch (e) {
      throw 'Lỗi xóa vận đơn: $e';
    }
  }
}
