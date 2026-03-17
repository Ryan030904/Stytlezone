import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../theme/app_theme.dart';

/// Notification bell icon with badge + dropdown panel.
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final unread = provider.unreadCount;

    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (_) => _buildOverlay(context),
        child: _BellButton(
          unreadCount: unread,
          onTap: () => _overlayController.toggle(),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _overlayController.hide(),
      child: Stack(
        children: [
          CompositedTransformFollower(
            link: _link,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, 8),
            child: GestureDetector(
              onTap: () {}, // prevent close when tapping inside
              child: const _NotificationPanel(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bell button with animated badge
// ─────────────────────────────────────────────
class _BellButton extends StatefulWidget {
  const _BellButton({required this.unreadCount, required this.onTap});
  final int unreadCount;
  final VoidCallback onTap;

  @override
  State<_BellButton> createState() => _BellButtonState();
}

class _BellButtonState extends State<_BellButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _hovered
                ? const Color(0xFF7C3AED).withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.notifications_none_rounded,
                size: 22,
                color: _hovered
                    ? const Color(0xFF7C3AED)
                    : AppTheme.textLight,
              ),
              if (widget.unreadCount > 0)
                Positioned(
                  top: 7,
                  right: 7,
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        widget.unreadCount > 99
                            ? '99+'
                            : '${widget.unreadCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Notification dropdown panel
// ─────────────────────────────────────────────
class _NotificationPanel extends StatelessWidget {
  const _NotificationPanel();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;

    return Material(
      elevation: 0,
      color: Colors.transparent,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.05),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, provider),
            const Divider(height: 1, color: AppTheme.borderColor),
            if (notifications.isEmpty)
              _buildEmptyState()
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 56, endIndent: 16),
                  itemBuilder: (context, index) =>
                      _NotificationItem(notification: notifications[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          const Text(
            'Thông báo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          if (provider.hasUnread) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${provider.unreadCount} mới',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ],
          const Spacer(),
          if (provider.hasUnread)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Đọc tất cả',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 28,
              color: AppTheme.textLight.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có thông báo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Thông báo mới sẽ xuất hiện ở đây',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Single notification item
// ─────────────────────────────────────────────
class _NotificationItem extends StatefulWidget {
  const _NotificationItem({required this.notification});
  final NotificationModel notification;

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final provider = context.read<NotificationProvider>();

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: () {
          if (!n.isRead) provider.markAsRead(n.id);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: _hovered
              ? const Color(0xFFF9F5FF)
              : (n.isRead ? Colors.transparent : const Color(0xFFFAF8FF)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(n.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  n.isRead ? FontWeight.w500 : FontWeight.w700,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF7C3AED),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      n.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textLight,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeAgo(n.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textLight.withValues(alpha: 0.65),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hovered)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () => provider.deleteNotification(n.id),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                    splashRadius: 14,
                    color: AppTheme.textLight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(NotificationType type) {
    IconData icon;
    Color color;
    Color bgColor;

    switch (type) {
      case NotificationType.order:
        icon = Icons.receipt_long_rounded;
        color = const Color(0xFF7C3AED);
        bgColor = const Color(0xFF7C3AED).withValues(alpha: 0.1);
        break;
      case NotificationType.stock:
        icon = Icons.inventory_2_rounded;
        color = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        break;
      case NotificationType.payment:
        icon = Icons.account_balance_wallet_rounded;
        color = const Color(0xFF10B981);
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        break;
      case NotificationType.system:
        icon = Icons.info_outline_rounded;
        color = const Color(0xFF6366F1);
        bgColor = const Color(0xFF6366F1).withValues(alpha: 0.1);
        break;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    final d = dateTime;
    return '${d.day}/${d.month}/${d.year}';
  }
}
