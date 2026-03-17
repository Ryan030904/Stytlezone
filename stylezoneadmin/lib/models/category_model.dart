import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String gender; // "all" | "male" | "female"
  final String? parentId;
  final bool isActive;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Admin-only fields (backward compatible)
  final int productCount;
  final String note;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  Category({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.gender = 'all',
    this.parentId,
    this.isActive = true,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    this.productCount = 0,
    this.note = '',
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'gender': gender,
      'parentId': parentId,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'productCount': productCount,
      'note': note,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'],
      gender: json['gender'] ?? 'all',
      parentId: json['parentId'],
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      productCount: json['productCount'] ?? 0,
      note: (json['note'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? gender,
    String? parentId,
    bool? isActive,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? productCount,
    String? note,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      gender: gender ?? this.gender,
      parentId: parentId ?? this.parentId,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productCount: productCount ?? this.productCount,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
