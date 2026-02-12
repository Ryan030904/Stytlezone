import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String sku;
  final String brand;
  final double price;
  final double? salePrice;
  final String categoryId;
  final String categoryName;
  final String? imageUrl;
  final List<String> sizes;
  final List<String> colors;
  final String material;
  final int stock;
  final bool isActive;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final String updatedBy;
  final bool isDeleted;

  Product({
    required this.id,
    required this.name,
    required this.description,
    this.sku = '',
    this.brand = '',
    required this.price,
    this.salePrice,
    required this.categoryId,
    this.categoryName = '',
    this.imageUrl,
    this.sizes = const [],
    this.colors = const [],
    this.material = '',
    this.stock = 0,
    this.isActive = true,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
    this.createdBy = '',
    this.updatedBy = '',
    this.isDeleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'sku': sku,
      'brand': brand,
      'price': price,
      'salePrice': salePrice,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'imageUrl': imageUrl,
      'sizes': sizes,
      'colors': colors,
      'material': material,
      'stock': stock,
      'isActive': isActive,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'createdBy': createdBy,
      'updatedBy': updatedBy,
      'isDeleted': isDeleted,
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      brand: json['brand'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      salePrice: json['salePrice']?.toDouble(),
      categoryId: json['categoryId'] ?? '',
      categoryName: json['categoryName'] ?? '',
      imageUrl: json['imageUrl'],
      sizes: List<String>.from(json['sizes'] ?? []),
      colors: List<String>.from(json['colors'] ?? []),
      material: json['material'] ?? '',
      stock: json['stock'] ?? 0,
      isActive: json['isActive'] ?? true,
      note: (json['note'] ?? '').toString(),
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
      createdBy: (json['createdBy'] ?? '').toString(),
      updatedBy: (json['updatedBy'] ?? '').toString(),
      isDeleted: json['isDeleted'] == true,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? sku,
    String? brand,
    double? price,
    double? salePrice,
    String? categoryId,
    String? categoryName,
    String? imageUrl,
    List<String>? sizes,
    List<String>? colors,
    String? material,
    int? stock,
    bool? isActive,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    bool? isDeleted,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      sku: sku ?? this.sku,
      brand: brand ?? this.brand,
      price: price ?? this.price,
      salePrice: salePrice ?? this.salePrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      imageUrl: imageUrl ?? this.imageUrl,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      material: material ?? this.material,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
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

  String get formattedSalePrice {
    if (salePrice == null) return '';
    return _fmtVND(salePrice!);
  }
}
