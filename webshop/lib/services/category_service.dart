import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'categories';

  // Get all active categories
  Future<List<Category>> getActiveCategories() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Category.fromJson(doc.data()))
          .toList();
    } catch (e) {
      throw 'Loi khi lay danh muc: ${e.toString()}';
    }
  }

  // Get category by ID
  Future<Category?> getCategoryById(String id) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return Category.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw 'Loi khi lay danh muc: ${e.toString()}';
    }
  }
}
