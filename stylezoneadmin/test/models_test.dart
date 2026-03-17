import 'package:flutter_test/flutter_test.dart';
import 'package:webadmin/models/product_model.dart';
import 'package:webadmin/models/category_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('Product Model', () {
    test('fromJson tạo Product đúng', () {
      final json = {
        'id': 'p1',
        'name': 'Áo thun',
        'description': 'Áo thun cotton',
        'sku': 'SKU001',
        'brand': 'StyleZone',
        'price': 199000,
        'salePrice': 159000,
        'categoryId': 'c1',
        'categoryName': 'Áo',
        'imageUrl': 'https://example.com/image.jpg',
        'sizes': ['S', 'M', 'L'],
        'colors': ['Đen', 'Trắng'],
        'material': 'Cotton',
        'stock': 50,
        'isActive': true,
        'note': '',
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'createdBy': 'admin@test.com',
        'updatedBy': 'admin@test.com',
        'isDeleted': false,
      };

      final product = Product.fromJson(json);

      expect(product.id, 'p1');
      expect(product.name, 'Áo thun');
      expect(product.price, 199000);
      expect(product.salePrice, 159000);
      expect(product.stock, 50);
      expect(product.isDeleted, false);
      expect(product.sizes, ['S', 'M', 'L']);
    });

    test('toJson → fromJson roundtrip', () {
      final product = Product(
        id: 'p2',
        name: 'Quần jean',
        description: 'Quần jean nam',
        sku: 'SKU002',
        brand: 'StyleZone',
        price: 350000,
        categoryId: 'c2',
        categoryName: 'Quần',
        stock: 30,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final json = product.toJson();
      final restored = Product.fromJson(json);

      expect(restored.id, product.id);
      expect(restored.name, product.name);
      expect(restored.price, product.price);
      expect(restored.stock, product.stock);
    });

    test('fromJson xử lý giá trị null an toàn', () {
      final json = <String, dynamic>{
        'id': null,
        'name': null,
        'price': null,
        'stock': null,
        'createdAt': null,
        'updatedAt': null,
      };

      final product = Product.fromJson(json);

      expect(product.id, '');
      expect(product.name, '');
      expect(product.price, 0);
      expect(product.stock, 0);
    });

    test('copyWith tạo bản sao đúng', () {
      final product = Product(
        id: 'p3',
        name: 'Váy',
        description: 'Váy nữ',
        price: 250000,
        categoryId: 'c3',
        categoryName: 'Váy',
        stock: 10,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final updated = product.copyWith(
        name: 'Váy dạ hội',
        price: 500000,
        stock: 5,
      );

      expect(updated.name, 'Váy dạ hội');
      expect(updated.price, 500000);
      expect(updated.stock, 5);
      // unchanged fields
      expect(updated.id, 'p3');
      expect(updated.categoryId, 'c3');
    });
  });

  group('Category Model', () {
    test('fromJson tạo Category đúng', () {
      final json = {
        'id': 'c1',
        'name': 'Áo',
        'description': 'Danh mục áo',
        'imageUrl': 'https://example.com/ao.jpg',
        'isActive': true,
        'productCount': 15,
        'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
        'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 2)),
        'createdBy': 'admin',
        'updatedBy': 'admin',
        'isDeleted': false,
      };

      final category = Category.fromJson(json);

      expect(category.id, 'c1');
      expect(category.name, 'Áo');
      expect(category.productCount, 15);
      expect(category.isActive, true);
      expect(category.isDeleted, false);
    });

    test('toJson → fromJson roundtrip', () {
      final category = Category(
        id: 'c2',
        name: 'Quần',
        description: 'Danh mục quần',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final json = category.toJson();
      final restored = Category.fromJson(json);

      expect(restored.id, category.id);
      expect(restored.name, category.name);
      expect(restored.description, category.description);
    });
  });
}
