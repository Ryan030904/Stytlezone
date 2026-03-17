import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/feedback_model.dart';
import 'base_service.dart';

class FeedbackService with BaseServiceMixin {
  static const String _collection = 'feedbacks';

  Future<List<FeedbackModel>> fetchAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return FeedbackModel.fromJson(data);
      }).toList();
    } catch (e) {
      dev.log('fetchAll feedbacks error: $e', name: 'FeedbackService');
      throw 'Lỗi khi lấy danh sách phản hồi: $e';
    }
  }

  Future<void> reply(String id, String replyText) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'adminReply': replyText,
        'adminReplyAt': FieldValue.serverTimestamp(),
        'status': 'replied',
      });
    } catch (e) {
      dev.log('reply feedback error: $e', name: 'FeedbackService');
      throw 'Lỗi khi phản hồi: $e';
    }
  }

  Future<void> close(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'status': 'closed',
      });
    } catch (e) {
      dev.log('close feedback error: $e', name: 'FeedbackService');
      throw 'Lỗi khi đóng phản hồi: $e';
    }
  }

  Future<void> reopen(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'status': 'pending',
      });
    } catch (e) {
      dev.log('reopen feedback error: $e', name: 'FeedbackService');
      throw 'Lỗi khi mở lại phản hồi: $e';
    }
  }

  Future<void> deleteFeedback(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      dev.log('delete feedback error: $e', name: 'FeedbackService');
      throw 'Lỗi khi xoá phản hồi: $e';
    }
  }
}
