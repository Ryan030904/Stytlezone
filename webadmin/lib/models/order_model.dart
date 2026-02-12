import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

// ═══════════════════════════════════════════
// Trạng thái đơn
// ═══════════════════════════════════════════
class OrderStatus {
  static const String pending = 'Chờ xử lý';
  static const String confirmed = 'Đã xác nhận';
  static const String shipping = 'Đang giao';
  static const String delivered = 'Đã giao';
  static const String cancelled = 'Đã hủy';

  static const List<String> all = [pending, confirmed, shipping, delivered, cancelled];

  static int index(String s) => all.indexOf(s);
}

// ═══════════════════════════════════════════
// San pham trong don
// ═══════════════════════════════════════════
class OrderItem {
  final String productId;
  final String productName;
  final String variant;
  final double price;
  final int quantity;

  OrderItem({
    required this.productId,
    required this.productName,
    this.variant = '',
    required this.price,
    required this.quantity,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'variant': variant,
        'price': price,
        'quantity': quantity,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] ?? '',
        productName: json['productName'] ?? '',
        variant: json['variant'] ?? '',
        price: (json['price'] ?? 0).toDouble(),
        quantity: json['quantity'] ?? 0,
      );
}

// ═══════════════════════════════════════════
// Activity log
// ═══════════════════════════════════════════
class ActivityEntry {
  final String action;
  final String note;
  final DateTime timestamp;

  ActivityEntry({required this.action, this.note = '', required this.timestamp});

  Map<String, dynamic> toJson() => {
        'action': action,
        'note': note,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory ActivityEntry.fromJson(Map<String, dynamic> json) => ActivityEntry(
        action: json['action'] ?? '',
        note: json['note'] ?? '',
        timestamp: json['timestamp']?.toDate() ?? DateTime.now(),
      );
}

// ═══════════════════════════════════════════
// Don hang
// ═══════════════════════════════════════════
class Order {
  final String id;
  final String code;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String customerAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double shippingFee;
  final double total;
  final String paymentMethod; // COD, VietQR, Banking
  final String paymentStatus; // Chưa thanh toán, Đã thanh toán
  final String status;
  final String note;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;
  final List<ActivityEntry> activityLog;
  final DateTime createdAt;
  final DateTime updatedAt;

  Order({
    required this.id,
    required this.code,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail = '',
    this.customerAddress = '',
    this.items = const [],
    this.subtotal = 0,
    this.discount = 0,
    this.shippingFee = 0,
    required this.total,
    this.paymentMethod = 'COD',
    this.paymentStatus = 'Chưa thanh toán',
    this.status = 'Chờ xử lý',
    this.note = '',
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
    this.activityLog = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  String get formattedTotal {
    final s = total.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerEmail': customerEmail,
        'customerAddress': customerAddress,
        'items': items.map((e) => e.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'shippingFee': shippingFee,
        'total': total,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'status': status,
        'note': note,
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'isDeleted': isDeleted,
        'activityLog': activityLog.map((e) => e.toJson()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] ?? '',
        code: json['code'] ?? '',
        customerName: json['customerName'] ?? '',
        customerPhone: json['customerPhone'] ?? '',
        customerEmail: json['customerEmail'] ?? '',
        customerAddress: json['customerAddress'] ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        subtotal: (json['subtotal'] ?? 0).toDouble(),
        discount: (json['discount'] ?? 0).toDouble(),
        shippingFee: (json['shippingFee'] ?? 0).toDouble(),
        total: (json['total'] ?? 0).toDouble(),
        paymentMethod: json['paymentMethod'] ?? 'COD',
        paymentStatus: json['paymentStatus'] ?? 'Chưa thanh toán',
        status: json['status'] ?? 'Chờ xử lý',
        note: json['note'] ?? '',
        createdBy: (json['createdBy'] ?? '').toString(),
        updatedBy: (json['updatedBy'] ?? '').toString(),
        isDeleted: json['isDeleted'] == true,
        activityLog: (json['activityLog'] as List<dynamic>?)
                ?.map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
        updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      );

  Order copyWith({
    String? id,
    String? code,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? customerAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    double? shippingFee,
    double? total,
    String? paymentMethod,
    String? paymentStatus,
    String? status,
    String? note,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
    List<ActivityEntry>? activityLog,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Order(
        id: id ?? this.id,
        code: code ?? this.code,
        customerName: customerName ?? this.customerName,
        customerPhone: customerPhone ?? this.customerPhone,
        customerEmail: customerEmail ?? this.customerEmail,
        customerAddress: customerAddress ?? this.customerAddress,
        items: items ?? this.items,
        subtotal: subtotal ?? this.subtotal,
        discount: discount ?? this.discount,
        shippingFee: shippingFee ?? this.shippingFee,
        total: total ?? this.total,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        status: status ?? this.status,
        note: note ?? this.note,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
        isDeleted: isDeleted ?? this.isDeleted,
        activityLog: activityLog ?? this.activityLog,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
