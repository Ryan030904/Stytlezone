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
  final DateTime createdAt;
  final DateTime updatedAt;

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
    required this.createdAt,
    required this.updatedAt,
  });

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
      createdAt: json['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: json['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

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
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String get formattedPrice {
    final formatted = price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatted}d';
  }

  String get formattedSalePrice {
    if (salePrice == null) return '';
    final formatted = salePrice!.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '${formatted}d';
  }

  int get discountPercent {
    if (salePrice == null || salePrice! >= price) return 0;
    return ((1 - salePrice! / price) * 100).round();
  }

  bool get isOnSale => salePrice != null && salePrice! < price;
  bool get isInStock => stock > 0;
}
