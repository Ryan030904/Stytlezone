import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import 'base_service.dart';

class NotificationService with BaseServiceMixin {
  static const String _col = 'notifications';

  /// Real-time stream of all notifications (newest first), limited to 50
  Stream<List<NotificationModel>> streamAll() {
    return firestore
        .collection(_col)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              if ((data['id'] ?? '').toString().isEmpty) {
                data['id'] = doc.id;
              }
              return NotificationModel.fromJson(data);
            }).toList());
  }

  /// Real-time stream of unread count
  Stream<int> streamUnreadCount() {
    return firestore
        .collection(_col)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String id) async {
    await firestore.collection(_col).doc(id).update({'isRead': true});
  }

  /// Mark all notifications as read (handles > 500 docs via batch chunking)
  Future<void> markAllAsRead() async {
    final snap = await firestore
        .collection(_col)
        .where('isRead', isEqualTo: false)
        .get();
    final docs = snap.docs;
    if (docs.isEmpty) return;

    // Firestore batch limit = 500
    const batchLimit = 500;
    for (var i = 0; i < docs.length; i += batchLimit) {
      final chunk = docs.skip(i).take(batchLimit);
      final batch = firestore.batch();
      for (final doc in chunk) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    }
  }

  /// Delete a single notification
  Future<void> delete(String id) async {
    await firestore.collection(_col).doc(id).delete();
  }

  /// Create a notification
  Future<void> create({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String entityId = '',
    String entityType = '',
  }) async {
    final docRef = firestore.collection(_col).doc();
    final notification = NotificationModel(
      id: docRef.id,
      title: title,
      message: message,
      type: type,
      entityId: entityId,
      entityType: entityType,
      createdAt: DateTime.now(),
    );
    await docRef.set(notification.toJson());
  }

  /// Helper: get current actor email (dùng BaseServiceMixin.actor())
  String get actorEmail => actor();
}
