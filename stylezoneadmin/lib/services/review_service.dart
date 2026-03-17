import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/review_model.dart';
import 'base_service.dart';

class ReviewService with BaseServiceMixin {
  static const String _collection = 'reviews';

  /// Fetch all reviews (including hidden, excluding soft-deleted)
  Future<List<ReviewModel>> fetchAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs
          .map((d) {
            final data = d.data();
            data['id'] = d.id;
            return ReviewModel.fromJson(data);
          })
          .where((r) => !r.isDeleted)
          .toList();
    } catch (e) {
      dev.log('fetchAll reviews error: $e', name: 'ReviewService');
      throw 'Lỗi khi lấy danh sách đánh giá: $e';
    }
  }

  /// Hide a review (set both isHidden and status)
  Future<void> hide(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'isHidden': true,
        'status': 'hidden',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('hide review error: $e', name: 'ReviewService');
      throw 'Lỗi khi ẩn đánh giá: $e';
    }
  }

  /// Unhide a review
  Future<void> unhide(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'isHidden': false,
        'status': 'visible',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('unhide review error: $e', name: 'ReviewService');
      throw 'Lỗi khi bỏ ẩn đánh giá: $e';
    }
  }

  /// Admin reply to a review
  Future<void> reply(String id, String replyText) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'adminReply': replyText,
        'adminReplyAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('reply review error: $e', name: 'ReviewService');
      throw 'Lỗi khi phản hồi đánh giá: $e';
    }
  }

  /// Soft-delete a review
  Future<void> deleteReview(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'isDeleted': true,
        'status': 'deleted',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      dev.log('deleteReview error: $e', name: 'ReviewService');
      throw 'Lỗi khi xoá đánh giá: $e';
    }
  }
}
