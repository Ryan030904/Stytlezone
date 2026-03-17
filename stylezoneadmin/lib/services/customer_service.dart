import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as dev;
import '../models/customer_model.dart';
import '../constants/admin_enums.dart';
import 'base_service.dart';

class CustomerService with BaseServiceMixin {
  static const String _collection = 'users';

  /// Fetch all customers (role == 'user')
  Future<List<CustomerModel>> getAll() async {
    try {
      ensureAuth();
      final snap = await firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      return snap.docs.map((d) {
        final data = d.data();
        data['id'] = d.id;
        return CustomerModel.fromJson(data);
      }).toList();
    } catch (e) {
      dev.log('getAll customers error: $e', name: 'CustomerService');
      throw 'Lỗi khi lấy danh sách khách hàng: $e';
    }
  }

  /// Fetch single customer by ID
  Future<CustomerModel?> getById(String id) async {
    try {
      ensureAuth();
      final doc = await firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      data['id'] = doc.id;
      return CustomerModel.fromJson(data);
    } catch (e) {
      dev.log('getById customer error: $e', name: 'CustomerService');
      throw 'Lỗi khi lấy thông tin khách hàng: $e';
    }
  }

  /// Ban customer account (soft-delete: set isBanned flag)
  /// User will see a warning when trying to log in on webshop
  Future<void> banUser(String id, String reason) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'isBanned': true,
        'bannedAt': Timestamp.fromDate(DateTime.now()),
        'banReason': reason,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
      });
      await safeAudit(
        action: AuditAction.statusChange,
        entity: AuditEntity.customer,
        entityId: id,
        summary: 'Khóa tài khoản khách hàng. Lý do: $reason',
      );
    } catch (e) {
      dev.log('banUser error: $e', name: 'CustomerService');
      throw 'Lỗi khi khóa tài khoản: $e';
    }
  }

  /// Unban customer account
  Future<void> unbanUser(String id) async {
    try {
      ensureAuth();
      await firestore.collection(_collection).doc(id).update({
        'isBanned': false,
        'bannedAt': null,
        'banReason': '',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
        'updatedBy': actor(),
      });
      await safeAudit(
        action: AuditAction.statusChange,
        entity: AuditEntity.customer,
        entityId: id,
        summary: 'Mở khóa tài khoản khách hàng',
      );
    } catch (e) {
      dev.log('unbanUser error: $e', name: 'CustomerService');
      throw 'Lỗi khi mở khóa tài khoản: $e';
    }
  }
}
