import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final int rating; // 1-5
  final String comment;
  final List<String> imageUrls;
  final bool isHidden;
  final String adminReply;
  final DateTime? adminReplyAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const ReviewModel({
    required this.id,
    this.productId = '',
    this.productName = '',
    this.productImageUrl = '',
    this.customerId = '',
    this.customerName = '',
    this.customerEmail = '',
    this.rating = 5,
    this.comment = '',
    this.imageUrls = const [],
    this.isHidden = false,
    this.adminReply = '',
    this.adminReplyAt,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'productImageUrl': productImageUrl,
        'customerId': customerId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls,
        'isHidden': isHidden,
        'adminReply': adminReply,
        'adminReplyAt':
            adminReplyAt != null ? Timestamp.fromDate(adminReplyAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isDeleted': isDeleted,
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) => ReviewModel(
        id: (json['id'] ?? '').toString(),
        productId: (json['productId'] ?? '').toString(),
        productName: (json['productName'] ?? '').toString(),
        productImageUrl: (json['productImageUrl'] ?? '').toString(),
        customerId: (json['customerId'] ?? '').toString(),
        customerName: (json['customerName'] ?? '').toString(),
        customerEmail: (json['customerEmail'] ?? '').toString(),
        rating: (json['rating'] ?? 5) as int,
        comment: (json['comment'] ?? '').toString(),
        imageUrls: List<String>.from(json['imageUrls'] ?? []),
        isHidden: json['isHidden'] == true,
        adminReply: (json['adminReply'] ?? '').toString(),
        adminReplyAt: json['adminReplyAt']?.toDate(),
        createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
        updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
        isDeleted: json['isDeleted'] == true,
      );

  ReviewModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? customerId,
    String? customerName,
    String? customerEmail,
    int? rating,
    String? comment,
    List<String>? imageUrls,
    bool? isHidden,
    String? adminReply,
    DateTime? adminReplyAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) =>
      ReviewModel(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        productName: productName ?? this.productName,
        productImageUrl: productImageUrl ?? this.productImageUrl,
        customerId: customerId ?? this.customerId,
        customerName: customerName ?? this.customerName,
        customerEmail: customerEmail ?? this.customerEmail,
        rating: rating ?? this.rating,
        comment: comment ?? this.comment,
        imageUrls: imageUrls ?? this.imageUrls,
        isHidden: isHidden ?? this.isHidden,
        adminReply: adminReply ?? this.adminReply,
        adminReplyAt: adminReplyAt ?? this.adminReplyAt,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        isDeleted: isDeleted ?? this.isDeleted,
      );
}
