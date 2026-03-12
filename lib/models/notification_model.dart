import 'package:cloud_firestore/cloud_firestore.dart';

/// Notification types for categorization and icon display
enum NotificationType { order, stock, payment, system }

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final bool isRead;
  final String entityId;   // e.g. orderId, productId
  final String entityType; // e.g. 'order', 'product'
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.type = NotificationType.system,
    this.isRead = false,
    this.entityId = '',
    this.entityType = '',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'type': type.name,
        'isRead': isRead,
        'entityId': entityId,
        'entityType': entityType,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      message: (json['message'] ?? '').toString(),
      type: _parseType(json['type']),
      isRead: json['isRead'] == true,
      entityId: (json['entityId'] ?? '').toString(),
      entityType: (json['entityType'] ?? '').toString(),
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    bool? isRead,
    String? entityId,
    String? entityType,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Vietnamese label for type
  String get typeLabel {
    switch (type) {
      case NotificationType.order:
        return 'Đơn hàng';
      case NotificationType.stock:
        return 'Kho hàng';
      case NotificationType.payment:
        return 'Thanh toán';
      case NotificationType.system:
        return 'Hệ thống';
    }
  }

  static NotificationType _parseType(dynamic value) {
    final s = (value ?? '').toString().toLowerCase();
    if (s == 'order') return NotificationType.order;
    if (s == 'stock') return NotificationType.stock;
    if (s == 'payment') return NotificationType.payment;
    return NotificationType.system;
  }
}
