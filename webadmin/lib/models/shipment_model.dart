import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════
// Tracking entry
// ═══════════════════════════════════════════
class TrackingEntry {
  final String status;
  final String location;
  final String note;
  final DateTime timestamp;

  TrackingEntry({
    required this.status,
    this.location = '',
    this.note = '',
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        'location': location,
        'note': note,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory TrackingEntry.fromJson(Map<String, dynamic> json) => TrackingEntry(
        status: json['status'] ?? '',
        location: json['location'] ?? '',
        note: json['note'] ?? '',
        timestamp: json['timestamp']?.toDate() ?? DateTime.now(),
      );
}

// ═══════════════════════════════════════════
// Status constants
// ═══════════════════════════════════════════
class ShipmentStatus {
  static const String processing = 'Đang xử lý';
  static const String pickedUp = 'Đã lấy hàng';
  static const String inTransit = 'Đang vận chuyển';
  static const String delivering = 'Đang giao';
  static const String delivered = 'Đã giao';
  static const String returned = 'Hoàn hàng';
  static const String failed = 'Giao thất bại';

  static const List<String> all = [
    processing, pickedUp, inTransit, delivering, delivered, returned, failed
  ];
}

// ═══════════════════════════════════════════
// Shipment model
// ═══════════════════════════════════════════
class Shipment {
  final String id;
  final String trackingCode;
  final String orderId;
  final String orderCode;
  final String carrier;
  final String receiverName;
  final String receiverPhone;
  final String receiverAddress;
  final String status;
  final String note;
  final List<TrackingEntry> trackingHistory;
  final DateTime? shippedAt;
  final DateTime? estimatedDelivery;
  final DateTime? deliveredAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  Shipment({
    required this.id,
    required this.trackingCode,
    required this.orderId,
    this.orderCode = '',
    required this.carrier,
    required this.receiverName,
    required this.receiverPhone,
    this.receiverAddress = '',
    this.status = 'Đang xử lý',
    this.note = '',
    this.trackingHistory = const [],
    this.shippedAt,
    this.estimatedDelivery,
    this.deliveredAt,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  bool get isLate {
    if (estimatedDelivery == null) return false;
    if (status == ShipmentStatus.delivered) return false;
    return DateTime.now().isAfter(estimatedDelivery!);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trackingCode': trackingCode,
        'orderId': orderId,
        'orderCode': orderCode,
        'carrier': carrier,
        'receiverName': receiverName,
        'receiverPhone': receiverPhone,
        'receiverAddress': receiverAddress,
        'status': status,
        'note': note,
        'trackingHistory': trackingHistory.map((e) => e.toJson()).toList(),
        'shippedAt': shippedAt != null ? Timestamp.fromDate(shippedAt!) : null,
        'estimatedDelivery': estimatedDelivery != null ? Timestamp.fromDate(estimatedDelivery!) : null,
        'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'isDeleted': isDeleted,
      };

  factory Shipment.fromJson(Map<String, dynamic> json) => Shipment(
        id: json['id'] ?? '',
        trackingCode: json['trackingCode'] ?? '',
        orderId: json['orderId'] ?? '',
        orderCode: json['orderCode'] ?? '',
        carrier: json['carrier'] ?? '',
        receiverName: json['receiverName'] ?? '',
        receiverPhone: json['receiverPhone'] ?? '',
        receiverAddress: json['receiverAddress'] ?? '',
        status: json['status'] ?? 'Đang xử lý',
        note: (json['note'] ?? '').toString(),
        trackingHistory: (json['trackingHistory'] as List<dynamic>?)
                ?.map((e) => TrackingEntry.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        shippedAt: json['shippedAt']?.toDate(),
        estimatedDelivery: json['estimatedDelivery']?.toDate(),
        deliveredAt: json['deliveredAt']?.toDate(),
        createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
        updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
        createdBy: (json['createdBy'] ?? '').toString(),
        updatedBy: (json['updatedBy'] ?? '').toString(),
        isDeleted: json['isDeleted'] == true,
      );

  Shipment copyWith({
    String? id,
    String? trackingCode,
    String? orderId,
    String? orderCode,
    String? carrier,
    String? receiverName,
    String? receiverPhone,
    String? receiverAddress,
    String? status,
    String? note,
    List<TrackingEntry>? trackingHistory,
    DateTime? shippedAt,
    DateTime? estimatedDelivery,
    DateTime? deliveredAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) =>
      Shipment(
        id: id ?? this.id,
        trackingCode: trackingCode ?? this.trackingCode,
        orderId: orderId ?? this.orderId,
        orderCode: orderCode ?? this.orderCode,
        carrier: carrier ?? this.carrier,
        receiverName: receiverName ?? this.receiverName,
        receiverPhone: receiverPhone ?? this.receiverPhone,
        receiverAddress: receiverAddress ?? this.receiverAddress,
        status: status ?? this.status,
        note: note ?? this.note,
        trackingHistory: trackingHistory ?? this.trackingHistory,
        shippedAt: shippedAt ?? this.shippedAt,
        estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
        deliveredAt: deliveredAt ?? this.deliveredAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        createdBy: createdBy ?? this.createdBy,
        updatedBy: updatedBy ?? this.updatedBy,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}
