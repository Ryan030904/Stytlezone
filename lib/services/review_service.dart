import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/review_model.dart';

class ReviewService {
  final _col = FirebaseFirestore.instance.collection('reviews');

  Future<List<ReviewModel>> fetchAll() async {
    final snap = await _col
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return ReviewModel.fromJson(data);
    }).toList();
  }



  Future<void> hide(String id) async {
    await _col.doc(id).update({
      'isHidden': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unhide(String id) async {
    await _col.doc(id).update({
      'isHidden': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reply(String id, String replyText) async {
    await _col.doc(id).update({
      'adminReply': replyText,
      'adminReplyAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String id) async {
    await _col.doc(id).update({
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
