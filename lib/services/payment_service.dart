import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/admin_enums.dart';
import '../models/paginated_result.dart';
import '../models/payment_model.dart';
import '../utils/validators.dart';
import 'base_service.dart';

class PaymentService with BaseServiceMixin {
  static const String _collection = 'payments';
  static const String _ordersCollection = 'orders';

  Future<PaginatedResult<PaymentModel>> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
    PaymentStatus? status,
    PaymentMethod? method,
  }) async {
    ensureAuth();

    Query<Map<String, dynamic>> query = firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final items = docs
        .map((doc) {
          final data = doc.data();
          if ((data['id'] ?? '').toString().isEmpty) {
            data['id'] = doc.id;
          }
          return PaymentModel.fromJson(data);
        })
        .where((item) {
          if (status != null && item.status != status) return false;
          if (method != null && item.method != method) return false;
          return true;
        })
        .toList();

    return PaginatedResult<PaymentModel>(
      items: items,
      lastDocument: docs.isEmpty ? null : docs.last,
      hasMore: docs.length == limit,
    );
  }

  Future<List<PaymentModel>> fetchAllForExport({
    PaymentStatus? status,
    PaymentMethod? method,
  }) async {
    ensureAuth();
    final items = <PaymentModel>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    bool hasMore = true;

    while (hasMore) {
      final page = await fetchPage(
        startAfter: lastDoc,
        limit: 200,
        status: status,
        method: method,
      );
      items.addAll(page.items);
      lastDoc = page.lastDocument;
      hasMore = page.hasMore && lastDoc != null;
    }

    return items;
  }

  Future<void> syncFromOrders() async {
    ensureAuth();

    final existingPaymentsSnapshot =
        await firestore.collection(_collection).get();

    final existingOrderIds = existingPaymentsSnapshot.docs
        .where((doc) => doc.data()['isDeleted'] != true)
        .map((doc) => (doc.data()['orderId'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    final ordersSnapshot = await firestore
        .collection(_ordersCollection)
        .orderBy('createdAt', descending: true)
        .get();

    final a = actor();
    final batch = firestore.batch();
    int createdCount = 0;

    for (final orderDoc in ordersSnapshot.docs) {
      final order = orderDoc.data();
      final orderId = orderDoc.id;
      if (existingOrderIds.contains(orderId)) {
        continue;
      }

      final paymentDoc = firestore.collection(_collection).doc();
      final createdAt = _toDate(order['createdAt']) ?? DateTime.now();
      final updatedAt = _toDate(order['updatedAt']) ?? createdAt;

      final payment = PaymentModel(
        id: paymentDoc.id,
        orderId: orderId,
        orderCode: (order['code'] ?? '').toString(),
        customerId: (order['customerId'] ?? '').toString(),
        customerName: (order['customerName'] ?? '').toString(),
        customerPhone: (order['customerPhone'] ?? '').toString(),
        amount: (order['total'] ?? 0).toDouble(),
        method: _parseMethod(order['paymentMethod']?.toString()),
        status: _parseStatus(order['paymentStatus']?.toString()),
        source: 'sync_order',
        createdAt: createdAt,
        updatedAt: updatedAt,
        createdBy: a,
        updatedBy: a,
        isDeleted: false,
      );

      batch.set(paymentDoc, payment.toJson());
      createdCount += 1;
    }

    if (createdCount > 0) {
      await batch.commit();
      await safeAudit(
        action: AuditAction.create,
        entity: AuditEntity.payment,
        entityId: 'sync_orders',
        summary: 'Đồng bộ $createdCount thanh toán từ đơn hàng',
      );
    }
  }

  Future<void> markAsPaid({
    required String paymentId,
    String note = '',
  }) async {
    ensureAuth();
    Validators.requireValidId(paymentId, 'Mã thanh toán');

    final a = actor();
    await firestore.runTransaction((transaction) async {
      final paymentRef = firestore.collection(_collection).doc(paymentId);
      final paymentSnap = await transaction.get(paymentRef);
      if (!paymentSnap.exists) {
        throw 'Thanh toán không tồn tại';
      }
      final payment = PaymentModel.fromJson(paymentSnap.data()!);

      final updateData = payment
          .copyWith(
            status: PaymentStatus.paid,
            paidAt: DateTime.now(),
            confirmedAt: DateTime.now(),
            confirmedBy: a,
            updatedAt: DateTime.now(),
            updatedBy: a,
            note: note.isNotEmpty ? note : payment.note,
          )
          .toJson();
      transaction.update(paymentRef, updateData);

      if (payment.orderId.isNotEmpty) {
        final orderRef = firestore.collection(_ordersCollection).doc(payment.orderId);
        transaction.update(orderRef, {
          'paymentStatus': 'paid',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'updatedBy': a,
        });
      }
    });

    await safeAudit(
      action: AuditAction.statusChange,
      entity: AuditEntity.payment,
      entityId: paymentId,
      summary: 'Xác nhận thanh toán',
      newSummary: note,
    );
  }

  Future<void> markAsFailed({
    required String paymentId,
    String note = '',
  }) async {
    ensureAuth();
    Validators.requireValidId(paymentId, 'Mã thanh toán');

    final a = actor();
    await firestore.runTransaction((transaction) async {
      final paymentRef = firestore.collection(_collection).doc(paymentId);
      final paymentSnap = await transaction.get(paymentRef);
      if (!paymentSnap.exists) {
        throw 'Thanh toán không tồn tại';
      }
      final payment = PaymentModel.fromJson(paymentSnap.data()!);

      transaction.update(
        paymentRef,
        payment
            .copyWith(
              status: PaymentStatus.failed,
              updatedAt: DateTime.now(),
              updatedBy: a,
              note: note.isNotEmpty ? note : payment.note,
            )
            .toJson(),
      );

      if (payment.orderId.isNotEmpty) {
        final orderRef = firestore.collection(_ordersCollection).doc(payment.orderId);
        transaction.update(orderRef, {
          'paymentStatus': 'failed',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'updatedBy': a,
        });
      }
    });

    await safeAudit(
      action: AuditAction.statusChange,
      entity: AuditEntity.payment,
      entityId: paymentId,
      summary: 'Đánh dấu thanh toán thất bại',
      newSummary: note,
    );
  }

  Future<void> refund({
    required String paymentId,
    required double amount,
    String note = '',
  }) async {
    ensureAuth();
    Validators.requireValidId(paymentId, 'Mã thanh toán');
    Validators.requirePositive(amount, 'Số tiền hoàn');

    final a = actor();
    await firestore.runTransaction((transaction) async {
      final paymentRef = firestore.collection(_collection).doc(paymentId);
      final paymentSnap = await transaction.get(paymentRef);
      if (!paymentSnap.exists) {
        throw 'Thanh toán không tồn tại';
      }

      final payment = PaymentModel.fromJson(paymentSnap.data()!);

      // Validate: không hoàn quá số tiền còn lại
      final maxRefundable = payment.amount - payment.refundedAmount;
      if (amount > maxRefundable) {
        throw 'Số tiền hoàn ($amount) vượt quá số tiền có thể hoàn ($maxRefundable).';
      }

      final totalRefunded = payment.refundedAmount + amount;
      final isFullRefund = totalRefunded >= payment.amount;
      final nextStatus =
          isFullRefund ? PaymentStatus.refunded : PaymentStatus.partialRefunded;

      transaction.update(
        paymentRef,
        payment
            .copyWith(
              refundedAmount: totalRefunded,
              refundedAt: DateTime.now(),
              refundBy: a,
              status: nextStatus,
              updatedAt: DateTime.now(),
              updatedBy: a,
              note: note.isNotEmpty ? note : payment.note,
            )
            .toJson(),
      );

      if (payment.orderId.isNotEmpty) {
        final orderRef = firestore.collection(_ordersCollection).doc(payment.orderId);
        transaction.update(orderRef, {
          'paymentStatus': isFullRefund ? 'refunded' : 'partialRefunded',
          'updatedAt': Timestamp.fromDate(DateTime.now()),
          'updatedBy': a,
        });
      }
    });

    await safeAudit(
      action: AuditAction.refund,
      entity: AuditEntity.payment,
      entityId: paymentId,
      summary: 'Hoàn tiền thanh toán',
      newSummary: 'Số tiền=$amount; Ghi chú=$note',
    );
  }

  Future<void> reconcile({
    required String paymentId,
    String note = '',
  }) async {
    ensureAuth();
    Validators.requireValidId(paymentId, 'Mã thanh toán');

    final a = actor();
    final now = DateTime.now();
    await firestore.collection(_collection).doc(paymentId).update({
      'status': EnumMapper.paymentStatus(PaymentStatus.reconciled),
      'reconciledBy': a,
      'reconciledAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
      'updatedBy': a,
      if (note.isNotEmpty) 'note': note,
    });

    await safeAudit(
      action: AuditAction.reconcile,
      entity: AuditEntity.payment,
      entityId: paymentId,
      summary: 'Đối soát thanh toán',
      newSummary: note,
    );
  }

  Future<void> softDelete(String paymentId) async {
    ensureAuth();
    final a = actor();
    final now = DateTime.now();
    await firestore.collection(_collection).doc(paymentId).update({
      'isDeleted': true,
      'updatedAt': Timestamp.fromDate(now),
      'updatedBy': a,
    });
    await safeAudit(
      action: AuditAction.softDelete,
      entity: AuditEntity.payment,
      entityId: paymentId,
      summary: 'Xóa thanh toán',
    );
  }

  DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  PaymentMethod _parseMethod(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.contains('chuyển khoản')) return PaymentMethod.bankTransfer;
    if (normalized.contains('vietqr') || normalized.contains('việt qr')) {
      return PaymentMethod.vietQr;
    }
    if (normalized == 'vietqr') return PaymentMethod.vietQr;
    if (normalized == 'banking' || normalized == 'banktransfer') {
      return PaymentMethod.bankTransfer;
    }
    if (normalized == 'momo') return PaymentMethod.momo;
    if (normalized == 'vnpay') return PaymentMethod.vnpay;
    if (normalized == 'zalopay') return PaymentMethod.zaloPay;
    return PaymentMethod.cod;
  }

  PaymentStatus _parseStatus(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.contains('đã thanh toán')) return PaymentStatus.paid;
    if (normalized.contains('chưa thanh toán')) return PaymentStatus.pending;
    if (normalized.contains('thất bại')) return PaymentStatus.failed;
    if (normalized.contains('đã hoàn tiền')) return PaymentStatus.refunded;
    if (normalized.contains('một phần')) return PaymentStatus.partialRefunded;
    if (normalized.contains('đã đối soát')) return PaymentStatus.reconciled;
    if (normalized == 'paid' || normalized == 'da thanh toan') {
      return PaymentStatus.paid;
    }
    if (normalized == 'failed' || normalized == 'that bai') {
      return PaymentStatus.failed;
    }
    if (normalized == 'refunded' || normalized == 'da hoan tien') {
      return PaymentStatus.refunded;
    }
    if (normalized == 'partialrefunded' || normalized == 'partial_refunded') {
      return PaymentStatus.partialRefunded;
    }
    if (normalized == 'reconciled' || normalized == 'da doi soat') {
      return PaymentStatus.reconciled;
    }
    return PaymentStatus.pending;
  }
}
