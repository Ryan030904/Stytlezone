import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/warehouse_receipt_model.dart';
import '../constants/admin_enums.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class WarehouseReceiptService with BaseServiceMixin {
  static const String _collection = 'warehouse_receipts';

  /// Lấy tất cả phiếu kho (bỏ đã xóa mềm)
  Future<List<WarehouseReceiptModel>> getAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_collection)
          .orderBy('updatedAt', descending: true)
          .get();
      return snap.docs
          .where((d) => d.data()['isDeleted'] != true)
          .map((d) => WarehouseReceiptModel.fromJson({...d.data(), 'id': d.id}))
          .toList();
    } catch (e) {
      dev.log('getAll warehouse receipts error: $e', name: 'WarehouseReceiptService');
      throw 'Lỗi khi lấy danh sách phiếu kho: $e';
    }
  }

  /// Tạo phiếu kho mới
  Future<String> create(WarehouseReceiptModel receipt) async {
    try {
      ensureAuth();
      Validators.requireNonEmpty(receipt.warehouse, 'Kho hàng');
      Validators.requireNonEmptyList(receipt.items, 'Danh sách hàng hóa');

      final docRef = firestore.collection(_collection).doc();
      final a = actor();
      final now = DateTime.now();
      final code = _generateCode(receipt.type, now);

      final data = receipt
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
        entity: AuditEntity.warehouseReceipt,
        entityId: docRef.id,
        summary: 'Tạo phiếu kho "$code" - ${receipt.typeLabel} tại ${receipt.warehouse}',
      );
      return docRef.id;
    } catch (e) {
      dev.log('create warehouse receipt error: $e', name: 'WarehouseReceiptService');
      throw 'Lỗi khi tạo phiếu kho: $e';
    }
  }

  /// Cập nhật phiếu kho
  Future<void> update(WarehouseReceiptModel receipt) async {
    try {
      ensureAuth();
      Validators.requireValidId(receipt.id, 'Mã phiếu kho');

      final data = receipt
          .copyWith(
            updatedAt: DateTime.now(),
            updatedBy: actor(),
          )
          .toJson();

      await firestore.collection(_collection).doc(receipt.id).set(data, SetOptions(merge: true));
      await safeAudit(
        action: AuditAction.update,
        entity: AuditEntity.warehouseReceipt,
        entityId: receipt.id,
        summary: 'Cập nhật phiếu kho "${receipt.code}"',
      );
    } catch (e) {
      dev.log('update warehouse receipt error: $e', name: 'WarehouseReceiptService');
      throw 'Lỗi khi cập nhật phiếu kho: $e';
    }
  }

  /// Cập nhật trạng thái phiếu kho
  Future<void> updateStatus(String id, ReceiptStatus newStatus, {String note = ''}) async {
    try {
      ensureAuth();
      Validators.requireValidId(id, 'Mã phiếu kho');

      final now = DateTime.now();
      final a = actor();
      final updates = <String, dynamic>{
        'status': EnumMapper.receiptStatus(newStatus),
        'updatedAt': Timestamp.fromDate(now),
        'updatedBy': a,
      };
      if (note.isNotEmpty) {
        updates['note'] = note;
      }
      // Đánh dấu đã áp kho khi hoàn tất
      if (newStatus == ReceiptStatus.completed) {
        updates['stockEffected'] = true;
      }

      await firestore.collection(_collection).doc(id).update(updates);
      await safeAudit(
        action: AuditAction.statusChange,
        entity: AuditEntity.warehouseReceipt,
        entityId: id,
        summary: 'Đổi trạng thái phiếu kho → ${_statusLabel(newStatus)}',
      );
    } catch (e) {
      dev.log('updateStatus warehouse receipt error: $e', name: 'WarehouseReceiptService');
      throw 'Lỗi khi cập nhật trạng thái: $e';
    }
  }

  /// Xóa mềm phiếu kho
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
        entity: AuditEntity.warehouseReceipt,
        entityId: id,
        summary: 'Xóa phiếu kho',
      );
    } catch (e) {
      dev.log('delete warehouse receipt error: $e', name: 'WarehouseReceiptService');
      throw 'Lỗi khi xóa phiếu kho: $e';
    }
  }

  String _generateCode(ReceiptType type, DateTime now) {
    final prefix = switch (type) {
      ReceiptType.stockIn => 'NK',
      ReceiptType.stockOut => 'XK',
      ReceiptType.transfer => 'CK',
      ReceiptType.stockCheck => 'KK',
    };
    final date = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final rand = now.millisecondsSinceEpoch.toString().substring(8);
    return '$prefix-$date-$rand';
  }

  String _statusLabel(ReceiptStatus s) {
    switch (s) {
      case ReceiptStatus.draft:
        return 'Nháp';
      case ReceiptStatus.processing:
        return 'Đang xử lý';
      case ReceiptStatus.completed:
        return 'Hoàn tất';
      case ReceiptStatus.cancelled:
        return 'Đã hủy';
    }
  }
}
