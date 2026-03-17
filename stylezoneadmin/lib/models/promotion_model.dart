import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại giảm giá
enum DiscountType { percent, fixed }

class Promotion {
  final String id;
  final String code;
  final String name;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final double minOrderAmount;
  final int maxUses;
  final int usedCount;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  Promotion({
    required this.id,
    required this.code,
    required this.name,
    this.description = '',
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount = 0,
    this.maxUses = 0,
    this.usedCount = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  /// Trạng thái auto từ ngày
  String get status {
    final now = DateTime.now();
    if (!isActive) return 'Tắt';
    if (now.isBefore(startDate)) return 'Sắp tới';
    if (now.isAfter(endDate)) return 'Đã kết thúc';
    return 'Đang chạy';
  }

  String get discountLabel {
    if (discountType == DiscountType.percent) {
      return '${discountValue.toStringAsFixed(0)}%';
    }
    final v = discountValue;
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  String get discountTypeLabel =>
      discountType == DiscountType.percent ? 'Phần trăm' : 'Cố định';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'discountType': discountType == DiscountType.percent ? 'percent' : 'fixed',
      'discountValue': discountValue,
      'minOrderAmount': minOrderAmount,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isActive': isActive,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
    };
  }

  factory Promotion.fromJson(Map<String, dynamic> json) {
    return Promotion(
      id: json['id'] ?? '',
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      discountType:
          json['discountType'] == 'fixed' ? DiscountType.fixed : DiscountType.percent,
      discountValue: (json['discountValue'] ?? 0).toDouble(),
      minOrderAmount: (json['minOrderAmount'] ?? 0).toDouble(),
      maxUses: json['maxUses'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      startDate: json['startDate']?.toDate() ?? DateTime.now(),
      endDate: json['endDate']?.toDate() ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      note: (json['note'] ?? '').toString(),
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: (json['createdBy'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  Promotion copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    DiscountType? discountType,
    double? discountValue,
    double? minOrderAmount,
    int? maxUses,
    int? usedCount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
