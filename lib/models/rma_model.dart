import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/admin_enums.dart';

/// Sản phẩm trong phiếu đổi trả
class RmaItem {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final double unitPrice;
  final String reason; // lý do cho sản phẩm cụ thể

  RmaItem({
    required this.productId,
    required this.productName,
    this.sku = '',
    required this.quantity,
    required this.unitPrice,
    this.reason = '',
  });

  double get totalPrice => quantity * unitPrice;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'reason': reason,
      };

  factory RmaItem.fromJson(Map<String, dynamic> json) => RmaItem(
        productId: (json['productId'] ?? '').toString(),
        productName: (json['productName'] ?? '').toString(),
        sku: (json['sku'] ?? '').toString(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
        reason: (json['reason'] ?? '').toString(),
      );
}

/// Model phiếu đổi trả (RMA)
class RmaModel {
  final String id;
  final String code; // mã phiếu: RMA-20260212-001
  final String orderId;
  final String orderCode;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String customerEmail;

  final RmaType type; // đổi hàng / trả hàng hoàn tiền
  final RmaStatus status;
  final RmaReason reason;
  final String reasonNote; // ghi chú bổ sung

  final List<RmaItem> items; // sản phẩm đổi trả
  final double refundAmount;
  final String refundMethod; // cash, bank_transfer, original_method

  final String adminNote; // ghi chú admin
  final String resolution; // kết quả xử lý

  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  RmaModel({
    required this.id,
    this.code = '',
    this.orderId = '',
    this.orderCode = '',
    this.customerId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.type = RmaType.returnAndRefund,
    this.status = RmaStatus.pendingReview,
    this.reason = RmaReason.other,
    this.reasonNote = '',
    this.items = const [],
    this.refundAmount = 0,
    this.refundMethod = '',
    this.adminNote = '',
    this.resolution = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  /// Label tiếng Việt cho loại
  String get typeLabel {
    switch (type) {
      case RmaType.exchange:
        return 'Đổi hàng';
      case RmaType.returnAndRefund:
        return 'Trả hàng / Hoàn tiền';
    }
  }

  /// Label tiếng Việt cho trạng thái
  String get statusLabel {
    switch (status) {
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

  /// Label tiếng Việt cho lý do
  String get reasonLabel {
    switch (reason) {
      case RmaReason.wrongSize:
        return 'Sai kích thước';
      case RmaReason.wrongColor:
        return 'Sai màu sắc';
      case RmaReason.wrongItem:
        return 'Sai sản phẩm';
      case RmaReason.defective:
        return 'Hàng lỗi';
      case RmaReason.changedMind:
        return 'Đổi ý';
      case RmaReason.other:
        return 'Khác';
    }
  }

  /// Tổng số lượng sản phẩm
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  /// Tổng giá trị sản phẩm
  double get totalItemsValue => items.fold(0.0, (sum, i) => sum + i.totalPrice);

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'orderId': orderId,
        'orderCode': orderCode,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'type': type.name,
        'status': status.name,
        'reason': reason.name,
        'reasonNote': reasonNote,
        'items': items.map((i) => i.toJson()).toList(),
        'refundAmount': refundAmount,
        'refundMethod': refundMethod,
        'adminNote': adminNote,
        'resolution': resolution,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'isDeleted': isDeleted,
      };

  factory RmaModel.fromJson(Map<String, dynamic> json) {
    final items = <RmaItem>[];
    if (json['items'] is List) {
      for (final item in json['items']) {
        if (item is Map<String, dynamic>) {
          items.add(RmaItem.fromJson(item));
        }
      }
    }

    return RmaModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      orderId: (json['orderId'] ?? '').toString(),
      orderCode: (json['orderCode'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerPhone: (json['customerPhone'] ?? '').toString(),
      customerEmail: (json['customerEmail'] ?? '').toString(),
      type: EnumMapper.parseRmaType(json['type']?.toString()),
      status: EnumMapper.parseRmaStatus(json['status']?.toString()),
      reason: EnumMapper.parseRmaReason(json['reason']?.toString()),
      reasonNote: (json['reasonNote'] ?? '').toString(),
      items: items,
      refundAmount: (json['refundAmount'] as num?)?.toDouble() ?? 0,
      refundMethod: (json['refundMethod'] ?? '').toString(),
      adminNote: (json['adminNote'] ?? '').toString(),
      resolution: (json['resolution'] ?? '').toString(),
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(json['updatedAt']) ?? DateTime.now(),
      createdBy: (json['createdBy'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  RmaModel copyWith({
    String? id,
    String? code,
    String? orderId,
    String? orderCode,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    RmaType? type,
    RmaStatus? status,
    RmaReason? reason,
    String? reasonNote,
    List<RmaItem>? items,
    double? refundAmount,
    String? refundMethod,
    String? adminNote,
    String? resolution,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return RmaModel(
      id: id ?? this.id,
      code: code ?? this.code,
      orderId: orderId ?? this.orderId,
      orderCode: orderCode ?? this.orderCode,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      type: type ?? this.type,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      reasonNote: reasonNote ?? this.reasonNote,
      items: items ?? this.items,
      refundAmount: refundAmount ?? this.refundAmount,
      refundMethod: refundMethod ?? this.refundMethod,
      adminNote: adminNote ?? this.adminNote,
      resolution: resolution ?? this.resolution,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
