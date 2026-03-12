import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _col = 'notifications';

  /// Real-time stream of all notifications (newest first), limited to 50
  Stream<List<NotificationModel>> streamAll() {
    return _firestore
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
    return _firestore
        .collection(_col)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String id) async {
    await _firestore.collection(_col).doc(id).update({'isRead': true});
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    final batch = _firestore.batch();
    final snap = await _firestore
        .collection(_col)
        .where('isRead', isEqualTo: false)
        .get();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  /// Delete a single notification
  Future<void> delete(String id) async {
    await _firestore.collection(_col).doc(id).delete();
  }

  /// Create a notification
  Future<void> create({
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String entityId = '',
    String entityType = '',
  }) async {
    final docRef = _firestore.collection(_col).doc();
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

  /// Helper: get current actor email
  String get actorEmail => _auth.currentUser?.email ?? 'system';
}
