import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/admin_enums.dart';
import '../models/paginated_result.dart';
import 'audit_log_service.dart';

/// Mixin cung cấp các tiện ích chung cho tất cả service:
/// - [actor]: lấy email/uid người đang đăng nhập
/// - [ensureAuth]: throw nếu chưa đăng nhập
/// - [safeAudit]: ghi audit log mà không ảnh hưởng business logic
/// - [fetchPaginated]: lấy dữ liệu phân trang
///
/// Hỗ trợ Dependency Injection: có thể truyền [FirebaseFirestore] và
/// [FirebaseAuth] tùy chỉnh (dùng cho testing).
mixin BaseServiceMixin {
  // Mặc định dùng instance thật, có thể override trong subclass
  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;
  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;
  AuditLogService get auditLogService => _auditLogService ?? AuditLogService();

  // Cho phép inject dependency (dùng trong testing)
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  AuditLogService? _auditLogService;

  void injectDependencies({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    AuditLogService? auditLogService,
  }) {
    _firestore = firestore;
    _auth = auth;
    _auditLogService = auditLogService;
  }

  /// Lấy actor (email ưu tiên, rồi uid, cuối cùng 'system').
  String actor() {
    final user = auth.currentUser;
    return user?.email ?? user?.uid ?? 'system';
  }

  /// Đảm bảo user đã đăng nhập, throw nếu chưa.
  void ensureAuth() {
    if (auth.currentUser == null) {
      throw 'Bạn chưa đăng nhập. Vui lòng đăng nhập lại.';
    }
  }

  /// Lấy dữ liệu phân trang từ 1 collection.
  Future<PaginatedResult<T>> fetchPaginated<T>({
    required String collection,
    required T Function(Map<String, dynamic>) fromJson,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
    String orderBy = 'createdAt',
    bool descending = true,
  }) async {
    Query<Map<String, dynamic>> query = firestore
        .collection(collection)
        .orderBy(orderBy, descending: descending)
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
      return fromJson(data);
    }).toList();

    return PaginatedResult<T>(
      items: items,
      lastDocument: docs.isEmpty ? null : docs.last,
      hasMore: docs.length == limit,
    );
  }

  /// Ghi audit log an toàn — lỗi audit không ảnh hưởng business logic.
  Future<void> safeAudit({
    required AuditAction action,
    required AuditEntity entity,
    required String entityId,
    required String summary,
    String oldSummary = '',
    String newSummary = '',
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await auditLogService.log(
        action: action,
        entity: entity,
        entityId: entityId,
        summary: summary,
        oldSummary: oldSummary,
        newSummary: newSummary,
        metadata: metadata,
      );
    } catch (_) {
      // Ignore audit failure — không block business logic
    }
  }
}
