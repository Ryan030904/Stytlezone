import 'dart:async';
import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationService _service = NotificationService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

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
    });
    _countSub = _service.streamUnreadCount().listen((count) {
      _unreadCount = count;
      notifyListeners();
    });
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
