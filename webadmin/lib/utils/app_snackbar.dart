import 'package:flutter/material.dart';

/// Global snackbar helper for Admin.
/// - Success: 3 seconds
/// - Error: 5 seconds
/// - Undo: available for soft delete flows
class AppSnackBar {
  AppSnackBar._();

  static const Duration _successDuration = Duration(seconds: 3);
  static const Duration _errorDuration = Duration(seconds: 5);
  static const Duration _defaultDuration = Duration(seconds: 3);

  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: const Color(0xFF10B981),
      duration: _successDuration,
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.error_rounded,
      backgroundColor: const Color(0xFFEF4444),
      duration: _errorDuration,
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.warning_rounded,
      backgroundColor: const Color(0xFFF59E0B),
      duration: _defaultDuration,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      icon: Icons.info_rounded,
      backgroundColor: const Color(0xFF7C3AED),
      duration: _defaultDuration,
    );
  }

  /// Use for soft delete flows.
  /// Call [onUndo] to restore data.
  static void deletedWithUndo(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = _errorDuration,
    String undoLabel = 'UNDO',
  }) {
    _show(
      context,
      message: message,
      icon: Icons.delete_rounded,
      backgroundColor: const Color(0xFFEF4444),
      duration: duration,
      action: SnackBarAction(
        label: undoLabel,
        textColor: Colors.white,
        onPressed: onUndo,
      ),
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          action: action,
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          duration: duration,
          elevation: 6,
        ),
      );
  }
}
