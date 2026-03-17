import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _stockChecked = false;

  StreamSubscription<List<NotificationModel>>? _notifSub;
  StreamSubscription<int>? _countSub;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  NotificationProvider() {
    _startListening();
  }

  void _startListening() {
    _notifSub = _service.streamAll().listen((list) {
      _notifications = list;
      notifyListeners();

      // Check stock levels once after notifications load
      if (!_stockChecked) {
        _stockChecked = true;
        _checkStockAlerts();
      }
    });
    _countSub = _service.streamUnreadCount().listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
  }

  /// Check product stock levels and generate alerts
  Future<void> _checkStockAlerts() async {
    try {
      final db = FirebaseFirestore.instance;

      // Get all products
      final productsSnap = await db.collection('products').get();
      final products = productsSnap.docs.map((d) => {...d.data(), 'id': d.id}).toList();

      final outOfStock = products.where((p) => (p['stock'] ?? 0) == 0 && p['isDeleted'] != true).toList();
      final lowStock = products.where((p) {
        final stock = (p['stock'] ?? 0) as num;
        return stock > 0 && stock <= 5 && p['isDeleted'] != true;
      }).toList();

      // Get today's date for deduplication key
      final today = DateTime.now();
      final dateKey = '${today.year}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}';

      // Check if we already generated today's stock alerts
      final existingAlerts = await db.collection('notifications')
          .where('entityType', isEqualTo: 'stock_daily_check')
          .where('entityId', isEqualTo: dateKey)
          .limit(1)
          .get();

      if (existingAlerts.docs.isNotEmpty) return; // Already checked today

      // Generate out-of-stock alert
      if (outOfStock.isNotEmpty) {
        final names = outOfStock.take(3).map((p) => p['name'] ?? '').join(', ');
        final extra = outOfStock.length > 3 ? ' và ${outOfStock.length - 3} sản phẩm khác' : '';
        await _service.create(
          title: '⚠️ ${outOfStock.length} sản phẩm hết hàng',
          message: '$names$extra đã hết hàng. Cần nhập kho ngay!',
          type: NotificationType.stock,
          entityId: dateKey,
          entityType: 'stock_daily_check',
        );
      }

      // Generate low-stock alert
      if (lowStock.isNotEmpty) {
        final names = lowStock.take(3).map((p) => '${p['name']} (${p['stock']})').join(', ');
        final extra = lowStock.length > 3 ? ' và ${lowStock.length - 3} sản phẩm khác' : '';
        await _service.create(
          title: '📦 ${lowStock.length} sản phẩm sắp hết hàng',
          message: '$names$extra còn ít hàng. Nên nhập thêm!',
          type: NotificationType.stock,
          entityId: dateKey,
          entityType: 'stock_daily_check',
        );
      }

      // Check pending orders
      final pendingOrders = await db.collection('orders')
          .where('status', isEqualTo: 'pending')
          .get();

      if (pendingOrders.docs.isNotEmpty) {
        final existingOrderAlert = await db.collection('notifications')
            .where('entityType', isEqualTo: 'order_daily_check')
            .where('entityId', isEqualTo: dateKey)
            .limit(1)
            .get();

        if (existingOrderAlert.docs.isEmpty) {
          await _service.create(
            title: '🛒 ${pendingOrders.docs.length} đơn hàng chờ xử lý',
            message: 'Có ${pendingOrders.docs.length} đơn hàng đang chờ được xử lý. Hãy kiểm tra ngay!',
            type: NotificationType.order,
            entityId: dateKey,
            entityType: 'order_daily_check',
          );
        }
      }

      // Check processing orders
      final processingOrders = await db.collection('orders')
          .where('status', isEqualTo: 'processing')
          .get();

      if (processingOrders.docs.isNotEmpty) {
        final existingProcessAlert = await db.collection('notifications')
            .where('entityType', isEqualTo: 'order_processing_check')
            .where('entityId', isEqualTo: dateKey)
            .limit(1)
            .get();

        if (existingProcessAlert.docs.isEmpty) {
          await _service.create(
            title: '📋 ${processingOrders.docs.length} đơn hàng đang xử lý',
            message: 'Có ${processingOrders.docs.length} đơn hàng đang được xử lý.',
            type: NotificationType.order,
            entityId: dateKey,
            entityType: 'order_processing_check',
          );
        }
      }

      // System welcome notification (only once ever)
      final welcomeCheck = await db.collection('notifications')
          .where('entityType', isEqualTo: 'system_welcome')
          .limit(1)
          .get();

      if (welcomeCheck.docs.isEmpty) {
        await _service.create(
          title: '👋 Chào mừng đến StyleZone Admin',
          message: 'Hệ thống sẽ tự động thông báo khi có đơn hàng mới, sản phẩm hết hàng, và các sự kiện quan trọng khác.',
          type: NotificationType.system,
          entityId: 'welcome',
          entityType: 'system_welcome',
        );
      }
    } catch (e) {
      debugPrint('NotificationProvider: stock check error: $e');
    }
  }

  /// Manually trigger stock check (e.g., after stock changes)
  Future<void> refreshStockAlerts() async {
    _stockChecked = false;
    await _checkStockAlerts();
  }

  Future<void> markAsRead(String id) async {
    await _service.markAsRead(id);
  }

  Future<void> markAllAsRead() async {
    await _service.markAllAsRead();
  }

  Future<void> deleteNotification(String id) async {
    await _service.delete(id);
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _countSub?.cancel();
    super.dispose();
  }
}
