import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String subject; // order, product, return, business, other
  final String message;
  final String status; // pending, replied, closed
  final String adminReply;
  final DateTime? adminReplyAt;
  final DateTime createdAt;

  const FeedbackModel({
    required this.id,
    this.name = '',
    this.email = '',
    this.phone = '',
    this.subject = 'other',
    this.message = '',
    this.status = 'pending',
    this.adminReply = '',
    this.adminReplyAt,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) => FeedbackModel(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    phone: (json['phone'] ?? '').toString(),
    subject: (json['subject'] ?? 'other').toString(),
    message: (json['message'] ?? '').toString(),
    status: (json['status'] ?? 'pending').toString(),
    adminReply: (json['adminReply'] ?? '').toString(),
    adminReplyAt: _toDate(json['adminReplyAt']),
    createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'phone': phone,
    'subject': subject,
    'message': message,
    'status': status,
    'adminReply': adminReply,
    'adminReplyAt': adminReplyAt != null ? Timestamp.fromDate(adminReplyAt!) : null,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  String get subjectLabel {
    switch (subject) {
      case 'order': return 'Đơn hàng';
      case 'product': return 'Sản phẩm';
      case 'return': return 'Đổi trả';
      case 'business': return 'Hợp tác';
      default: return 'Khác';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'replied': return 'Đã phản hồi';
      case 'closed': return 'Đã đóng';
      default: return 'Chờ xử lý';
    }
  }
}
