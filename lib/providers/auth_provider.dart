import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../constants/admin_enums.dart';
import '../services/audit_log_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final AuditLogService _auditLogService = AuditLogService();
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _authService.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (password != confirmPassword) {
        throw Exception('Mat khau khong khop');
      }

      if (password.length < 6) {
        throw Exception('Mat khau phai co it nhat 6 ky tu');
      }

      await _authService.signUp(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      await _safeAuditLog(
        action: AuditAction.login,
        entity: AuditEntity.auth,
        entityId: email,
        summary: 'Admin login',
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendPasswordResetEmail({required String email}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    final actor = _user?.email ?? _user?.uid ?? 'unknown';
    await _authService.signOut();
    await _safeAuditLog(
      action: AuditAction.logout,
      entity: AuditEntity.auth,
      entityId: actor,
      summary: 'Admin logout',
    );
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _safeAuditLog({
    required AuditAction action,
    required AuditEntity entity,
    required String entityId,
    required String summary,
  }) async {
    try {
      await _auditLogService.log(
        action: action,
        entity: entity,
        entityId: entityId,
        summary: summary,
      );
    } catch (_) {
      // ignore logging errors to avoid breaking auth flow
    }
  }
}
