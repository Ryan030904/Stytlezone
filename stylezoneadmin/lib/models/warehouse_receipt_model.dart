import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/admin_enums.dart';

// ═══════════════════════════════════════════════
// RECEIPT ITEM (sản phẩm trong phiếu kho)
// ═══════════════════════════════════════════════
class ReceiptItem {
  final String productId;
  final String productName;
  final String sku;
  final int quantity;
  final String note;

  const ReceiptItem({
    this.productId = '',
    this.productName = '',
    this.sku = '',
    this.quantity = 0,
    this.note = '',
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      quantity: _toInt(json['quantity']),
      note: (json['note'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'quantity': quantity,
        'note': note,
      };

  ReceiptItem copyWith({
    String? productId,
    String? productName,
    String? sku,
    int? quantity,
    String? note,
  }) {
    return ReceiptItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      note: note ?? this.note,
    );
  }

  static int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }
}

// ═══════════════════════════════════════════════
// WAREHOUSE RECEIPT MODEL
// ═══════════════════════════════════════════════
class WarehouseReceiptModel {
  final String id;
  final String code;
  final ReceiptType type;
  final ReceiptStatus status;
  final String warehouse;
  final String toWarehouse; // dùng cho chuyển kho
  final String note;
  final List<ReceiptItem> items;
  final bool stockEffected;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  const WarehouseReceiptModel({
    this.id = '',
    this.code = '',
    this.type = ReceiptType.stockIn,
    this.status = ReceiptStatus.draft,
    this.warehouse = '',
    this.toWarehouse = '',
    this.note = '',
    this.items = const [],
    this.stockEffected = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  /// Tổng số lượng hàng trong phiếu
  int get totalQty => items.fold(0, (sum, i) => sum + i.quantity);

  /// Vietnamese labels
  String get typeLabel {
    switch (type) {
      case ReceiptType.stockIn:
        return 'Nhập kho';
      case ReceiptType.stockOut:
        return 'Xuất kho';
      case ReceiptType.transfer:
        return 'Chuyển kho';
      case ReceiptType.stockCheck:
        return 'Kiểm kho';
    }
  }

  String get statusLabel {
    switch (status) {
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

  // ─── JSON ────────────────────────────────
  factory WarehouseReceiptModel.fromJson(Map<String, dynamic> json) {
    return WarehouseReceiptModel(
      id: (json['id'] ?? '').toString(),
      code: (json['code'] ?? '').toString(),
      type: EnumMapper.parseReceiptType(json['type']?.toString()),
      status: EnumMapper.parseReceiptStatus(json['status']?.toString()),
      warehouse: (json['warehouse'] ?? '').toString(),
      toWarehouse: (json['toWarehouse'] ?? '').toString(),
      note: (json['note'] ?? '').toString(),
      items: _parseItems(json['items']),
      stockEffected: json['stockEffected'] == true,
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(json['updatedAt']) ?? DateTime.now(),
      createdBy: (json['createdBy'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'type': EnumMapper.receiptType(type),
        'status': EnumMapper.receiptStatus(status),
        'warehouse': warehouse,
        'toWarehouse': toWarehouse,
        'note': note,
        'items': items.map((i) => i.toJson()).toList(),
        'totalQty': totalQty,
        'stockEffected': stockEffected,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'isDeleted': isDeleted,
      };

  WarehouseReceiptModel copyWith({
    String? id,
    String? code,
    ReceiptType? type,
    ReceiptStatus? status,
    String? warehouse,
    String? toWarehouse,
    String? note,
    List<ReceiptItem>? items,
    bool? stockEffected,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return WarehouseReceiptModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      status: status ?? this.status,
      warehouse: warehouse ?? this.warehouse,
      toWarehouse: toWarehouse ?? this.toWarehouse,
      note: note ?? this.note,
      items: items ?? this.items,
      stockEffected: stockEffected ?? this.stockEffected,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // ─── helpers ─────────────────────────────
  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static List<ReceiptItem> _parseItems(dynamic v) {
    if (v is List) return v.map((e) => ReceiptItem.fromJson(Map<String, dynamic>.from(e))).toList();
    return [];
  }
}
