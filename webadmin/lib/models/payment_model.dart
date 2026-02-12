import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/admin_enums.dart';

class PaymentModel {
  final String id;
  final String orderId;
  final String orderCode;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String source;
  final String transactionId;
  final String bankCode;
  final String bankName;
  final String note;
  final String confirmedBy;
  final DateTime? confirmedAt;
  final String reconciledBy;
  final DateTime? reconciledAt;
  final double refundedAmount;
  final String refundTransactionId;
  final String refundBy;
  final DateTime? refundedAt;
  final DateTime? paidAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  const PaymentModel({
    required this.id,
    this.orderId = '',
    this.orderCode = '',
    this.customerId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.amount = 0,
    this.method = PaymentMethod.cod,
    this.status = PaymentStatus.pending,
    this.source = 'manual',
    this.transactionId = '',
    this.bankCode = '',
    this.bankName = '',
    this.note = '',
    this.confirmedBy = '',
    this.confirmedAt,
    this.reconciledBy = '',
    this.reconciledAt,
    this.refundedAmount = 0,
    this.refundTransactionId = '',
    this.refundBy = '',
    this.refundedAt,
    this.paidAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'orderCode': orderCode,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'amount': amount,
      'method': EnumMapper.paymentMethod(method),
      'status': EnumMapper.paymentStatus(status),
      'source': source,
      'transactionId': transactionId,
      'bankCode': bankCode,
      'bankName': bankName,
      'note': note,
      'confirmedBy': confirmedBy,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'reconciledBy': reconciledBy,
      'reconciledAt':
          reconciledAt != null ? Timestamp.fromDate(reconciledAt!) : null,
      'refundedAmount': refundedAmount,
      'refundTransactionId': refundTransactionId,
      'refundBy': refundBy,
      'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
    };
  }

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    final rawMethod = (json['method'] ?? 'cod').toString().trim();
    final rawStatus = (json['status'] ?? 'pending').toString().trim();

    return PaymentModel(
      id: (json['id'] ?? '').toString(),
      orderId: (json['orderId'] ?? '').toString(),
      orderCode: (json['orderCode'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      amount: (json['amount'] ?? 0).toDouble(),
      method: EnumMapper.parsePaymentMethod(_normalizeMethod(rawMethod)),
      status: EnumMapper.parsePaymentStatus(_normalizeStatus(rawStatus)),
      source: (json['source'] ?? 'manual').toString(),
      transactionId: (json['transactionId'] ?? '').toString(),
      bankCode: (json['bankCode'] ?? '').toString(),
      bankName: (json['bankName'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      confirmedBy: (json['confirmedBy'] ?? '').toString(),
      confirmedAt: json['confirmedAt']?.toDate(),
      reconciledBy: (json['reconciledBy'] ?? '').toString(),
      reconciledAt: json['reconciledAt']?.toDate(),
      refundedAmount: (json['refundedAmount'] ?? 0).toDouble(),
      refundTransactionId: (json['refundTransactionId'] ?? '').toString(),
      refundBy: (json['refundBy'] ?? '').toString(),
      refundedAt: json['refundedAt']?.toDate(),
      paidAt: json['paidAt']?.toDate(),
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: (json['createdBy'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  PaymentModel copyWith({
    String? id,
    String? orderId,
    String? orderCode,
    String? customerId,
    String? customerName,
    String? customerPhone,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? source,
    String? transactionId,
    String? bankCode,
    String? bankName,
    String? note,
    String? confirmedBy,
    DateTime? confirmedAt,
    String? reconciledBy,
    DateTime? reconciledAt,
    double? refundedAmount,
    String? refundTransactionId,
    String? refundBy,
    DateTime? refundedAt,
    DateTime? paidAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      source: source ?? this.source,
      transactionId: transactionId ?? this.transactionId,
      bankCode: bankCode ?? this.bankCode,
      bankName: bankName ?? this.bankName,
      note: note ?? this.note,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      reconciledBy: reconciledBy ?? this.reconciledBy,
      reconciledAt: reconciledAt ?? this.reconciledAt,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      refundTransactionId: refundTransactionId ?? this.refundTransactionId,
      refundBy: refundBy ?? this.refundBy,
      refundedAt: refundedAt ?? this.refundedAt,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  static String _normalizeMethod(String raw) {
    final value = raw.toLowerCase();
    if (value == 'banking' || value == 'bank_transfer') return 'bankTransfer';
    if (value == 'vietqr' || value == 'viet_qr') return 'vietQr';
    return raw;
  }

  static String _normalizeStatus(String raw) {
    final value = raw.toLowerCase();
    if (value == 'da_thanh_toan' || value == 'paid') return 'paid';
    if (value == 'chua_thanh_toan' || value == 'pending') return 'pending';
    if (value == 'that_bai' || value == 'failed') return 'failed';
    if (value == 'da_hoan_tien' || value == 'refunded') return 'refunded';
    if (value == 'hoan_tien_mot_phan' || value == 'partial_refunded') {
      return 'partialRefunded';
    }
    if (value == 'da_doi_soat' || value == 'reconciled') return 'reconciled';
    return raw;
  }
}
