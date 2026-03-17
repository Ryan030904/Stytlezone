import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String productId;
  final String productName;
  final String productImageUrl;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerAvatar;
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
    this.customerAvatar = '',
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
        'customerAvatar': customerAvatar,
        'rating': rating,
        'comment': comment,
        'imageUrls': imageUrls,
        'images': imageUrls,
        'isHidden': isHidden,
        'status': isHidden ? 'hidden' : 'visible',
        'adminReply': adminReply,
        'adminReplyAt':
            adminReplyAt != null ? Timestamp.fromDate(adminReplyAt!) : null,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isDeleted': isDeleted,
      };

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    // Support both admin fields (isHidden) and webshop fields (status)
    final status = (json['status'] ?? '').toString();
    final hidden = json['isHidden'] == true || status == 'hidden';

    // Support both imageUrls (admin) and images (webshop)
    final imgs = json['imageUrls'] ?? json['images'] ?? [];

    return ReviewModel(
      id: (json['id'] ?? '').toString(),
      productId: (json['productId'] ?? '').toString(),
      productName: (json['productName'] ?? '').toString(),
      productImageUrl: (json['productImageUrl'] ?? json['productImage'] ?? '').toString(),
      customerId: (json['customerId'] ?? '').toString(),
      customerName: (json['customerName'] ?? '').toString(),
      customerEmail: (json['customerEmail'] ?? '').toString(),
      customerAvatar: (json['customerAvatar'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 5,
      comment: (json['comment'] ?? '').toString(),
      imageUrls: List<String>.from(imgs),
      isHidden: hidden,
      adminReply: (json['adminReply'] ?? '').toString(),
      adminReplyAt: _toDate(json['adminReplyAt']),
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(json['updatedAt']) ?? DateTime.now(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  ReviewModel copyWith({
    String? id,
    String? productId,
    String? productName,
    String? productImageUrl,
    String? customerId,
    String? customerName,
    String? customerEmail,
    String? customerAvatar,
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
        customerAvatar: customerAvatar ?? this.customerAvatar,
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
