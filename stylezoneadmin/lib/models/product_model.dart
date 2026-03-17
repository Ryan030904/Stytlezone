import 'package:cloud_firestore/cloud_firestore.dart';

/// Variant of a product (color + size combination)
class ProductVariant {
  final String color;
  final String? colorHex;
  final String? colorImage;
  final String size;
  final double price;
  final int stock;
  final String sku;

  ProductVariant({
    required this.color,
    this.colorHex,
    this.colorImage,
    required this.size,
    this.price = 0,
    this.stock = 0,
    this.sku = '',
  });

  Map<String, dynamic> toJson() => {
    'color': color,
    'colorHex': colorHex,
    'colorImage': colorImage,
    'size': size,
    'price': price,
    'stock': stock,
    'sku': sku,
  };

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      color: json['color'] ?? '',
      colorHex: json['colorHex'],
      colorImage: json['colorImage'],
      size: json['size'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      sku: json['sku'] ?? '',
    );
  }

  ProductVariant copyWith({
    String? color,
    String? colorHex,
    String? colorImage,
    String? size,
    double? price,
    int? stock,
    String? sku,
  }) {
    return ProductVariant(
      color: color ?? this.color,
      colorHex: colorHex ?? this.colorHex,
      colorImage: colorImage ?? this.colorImage,
      size: size ?? this.size,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      sku: sku ?? this.sku,
    );
  }
}

class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final double salePrice;
  final String categoryId;
  final String categoryName;
  final String brandId;
  final String brandName;
  final String gender; // "all" | "male" | "female"
  final List<String> images;
  final List<String> sizes;
  final List<String> colors;
  final int stock;
  final bool isActive;
  final int sortOrder;
  final List<ProductVariant> variants;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Admin-only fields (backward compatible)
  final String sku;
  final String material;
  final String note;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.salePrice = 0,
    required this.categoryId,
    this.categoryName = '',
    this.brandId = '',
    this.brandName = '',
    this.gender = 'all',
    this.images = const [],
    this.sizes = const [],
    this.colors = const [],
    this.stock = 0,
    this.isActive = true,
    this.sortOrder = 0,
    this.variants = const [],
    required this.createdAt,
    required this.updatedAt,
    this.sku = '',
    this.material = '',
    this.note = '',
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  /// Legacy single imageUrl getter (first image or empty)
  String? get imageUrl => images.isNotEmpty ? images.first : null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'salePrice': salePrice,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'brandId': brandId,
      'brandName': brandName,
      'gender': gender,
      'images': images,
      'sizes': sizes,
      'colors': colors,
      'stock': stock,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'variants': variants.map((v) => v.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'sku': sku,
      'material': material,
      'note': note,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle legacy `imageUrl` field → migrate to `images[]`
    List<String> images = List<String>.from(json['images'] ?? []);
    if (images.isEmpty && json['imageUrl'] != null && (json['imageUrl'] as String).isNotEmpty) {
      images = [json['imageUrl'] as String];
    }

    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      salePrice: (json['salePrice'] ?? 0).toDouble(),
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      brandId: json['brandId'] ?? '',
      brandName: json['brandName'] ?? '',
      gender: json['gender'] ?? 'all',
      images: images,
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      stock: json['stock'] ?? 0,
      isActive: json['isActive'] ?? true,
      sortOrder: json['sortOrder'] ?? 0,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((v) => ProductVariant.fromJson(Map<String, dynamic>.from(v)))
              .toList() ??
          [],
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      sku: json['sku'] ?? '',
      material: json['material'] ?? '',
      note: (json['note'] ?? '').toString(),
      createdBy: (json['createdBy'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    double? salePrice,
    String? categoryId,
    String? categoryName,
    String? brandId,
    String? brandName,
    String? gender,
    List<String>? images,
    List<String>? sizes,
    List<String>? colors,
    int? stock,
    bool? isActive,
    int? sortOrder,
    List<ProductVariant>? variants,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sku,
    String? material,
    String? note,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      gender: gender ?? this.gender,
      images: images ?? this.images,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      variants: variants ?? this.variants,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sku: sku ?? this.sku,
      material: material ?? this.material,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  String _fmtVND(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  String get formattedPrice => _fmtVND(price);
  String get formattedSalePrice => salePrice > 0 ? _fmtVND(salePrice) : '';
}
