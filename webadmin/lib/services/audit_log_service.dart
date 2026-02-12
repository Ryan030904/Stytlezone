import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/admin_enums.dart';
import '../models/audit_log_model.dart';
import '../models/paginated_result.dart';

class AuditLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collection = 'audit_logs';

  Future<PaginatedResult<AuditLogModel>> fetchPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
    AuditEntity? entity,
    AuditAction? action,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();
    final docs = snapshot.docs;
    final items = docs.map((doc) {
      final data = doc.data();
      if ((data['id'] ?? '').toString().isEmpty) {
        data['id'] = doc.id;
      }
      return AuditLogModel.fromJson(data);
    }).where((log) {
      if (entity != null && log.entity != entity) return false;
      if (action != null && log.action != action) return false;
      return true;
    }).toList();
    return PaginatedResult<AuditLogModel>(
      items: items,
      lastDocument: docs.isEmpty ? null : docs.last,
      hasMore: docs.length == limit,
    );
  }

  Future<List<AuditLogModel>> fetchAllForExport({
    AuditEntity? entity,
    AuditAction? action,
  }) async {
    final items = <AuditLogModel>[];
    DocumentSnapshot<Map<String, dynamic>>? lastDoc;
    bool hasMore = true;

    while (hasMore) {
      final page = await fetchPage(
        startAfter: lastDoc,
        limit: 300,
        entity: entity,
        action: action,
      );
      items.addAll(page.items);
      lastDoc = page.lastDocument;
      hasMore = page.hasMore && lastDoc != null;
    }

    return items;
  }

  Future<void> log({
    required AuditAction action,
    required AuditEntity entity,
    required String entityId,
    required String summary,
    String oldSummary = '',
    String newSummary = '',
    Map<String, dynamic> metadata = const {},
    String? actorUid,
    String? actorEmail,
    String ipAddress = '',
  }) async {
    final docRef = _firestore.collection(_collection).doc();
    final user = _auth.currentUser;
    final model = AuditLogModel(
      id: docRef.id,
      action: action,
      entity: entity,
      entityId: entityId,
      summary: summary,
      oldSummary: oldSummary,
      newSummary: newSummary,
      metadata: metadata,
      actorUid: actorUid ?? user?.uid ?? '',
      actorEmail: actorEmail ?? user?.email ?? '',
      ipAddress: ipAddress,
      createdAt: DateTime.now(),
    );
    await docRef.set(model.toJson());
  }
}
