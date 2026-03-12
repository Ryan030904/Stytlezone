import 'package:cloud_firestore/cloud_firestore.dart';

/// Loại banner
enum BannerType { hero, promotion, category }

/// Trạng thái banner
enum BannerStatus { active, draft, archived }

class BannerModel {
  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String linkUrl;
  final BannerType type;
  final BannerStatus status;
  final String position; // hero, sidebar, footer, popup
  final int sortOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.linkUrl = '',
    this.type = BannerType.hero,
    this.status = BannerStatus.draft,
    this.position = 'hero',
    this.sortOrder = 0,
    this.startDate,
    this.endDate,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  /// Lấy label loại banner
  String get typeLabel {
    switch (type) {
      case BannerType.hero:
        return 'Hero';
      case BannerType.promotion:
        return 'Khuyến mãi';
      case BannerType.category:
        return 'Danh mục';
    }
  }

  /// Lấy label trạng thái
  String get statusLabel {
    switch (status) {
      case BannerStatus.active:
        return 'Đang hiển thị';
      case BannerStatus.draft:
        return 'Nháp';
      case BannerStatus.archived:
        return 'Lưu trữ';
    }
  }

  /// Kiểm tra banner có đang trong thời hạn
  bool get isInDateRange {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }

  /// Kiểm tra banner đang hoạt động thực sự
  bool get isLive => status == BannerStatus.active && isInDateRange && !isDeleted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'imageUrl': imageUrl,
      'linkUrl': linkUrl,
      'type': type.name,
      'status': status.name,
      'position': position,
      'sortOrder': sortOrder,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
    };
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      linkUrl: json['linkUrl'] ?? '',
      type: _parseType(json['type']),
      status: _parseStatus(json['status']),
      position: json['position'] ?? 'hero',
      sortOrder: json['sortOrder'] ?? 0,
      startDate: _toDate(json['startDate']),
      endDate: _toDate(json['endDate']),
      createdAt: _toDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(json['updatedAt']) ?? DateTime.now(),
      createdBy: (json['createdBy'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  BannerModel copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    String? linkUrl,
    BannerType? type,
    BannerStatus? status,
    String? position,
    int? sortOrder,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return BannerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      linkUrl: linkUrl ?? this.linkUrl,
      type: type ?? this.type,
      status: status ?? this.status,
      position: position ?? this.position,
      sortOrder: sortOrder ?? this.sortOrder,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  static BannerType _parseType(dynamic value) {
    final s = (value ?? '').toString().toLowerCase();
    if (s == 'promotion') return BannerType.promotion;
    if (s == 'category') return BannerType.category;
    return BannerType.hero;
  }

  static BannerStatus _parseStatus(dynamic value) {
    final s = (value ?? '').toString().toLowerCase();
    if (s == 'active') return BannerStatus.active;
    if (s == 'archived') return BannerStatus.archived;
    return BannerStatus.draft;
  }

  static DateTime? _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
