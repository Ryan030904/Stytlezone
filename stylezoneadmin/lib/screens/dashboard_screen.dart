import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

import '../widgets/category_content.dart';
import '../widgets/cms_content.dart';
import '../widgets/brand_content.dart';
import '../widgets/banner_content.dart';
import '../widgets/customer_content.dart';
import '../widgets/dashboard_content.dart';
import '../widgets/inventory_content.dart';
import '../widgets/order_content.dart';
import '../widgets/payment_content.dart';
import '../widgets/product_content.dart';
import '../widgets/promotion_content.dart';
import '../widgets/review_content.dart';
import '../widgets/feedback_content.dart';
import '../widgets/rma_content.dart';
import '../widgets/settings_content.dart';
import '../widgets/notification_bell.dart';
import 'auth_shell.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  /// Notifier that increments whenever the active tab changes.
  /// Content widgets listen to this to auto-close their slide panels.
  static final ValueNotifier<int> panelCloseNotifier = ValueNotifier<int>(0);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  /// Lazy cache: only builds a tab widget when it's first selected.
  /// This avoids building all 17 tabs on startup.
  final Map<int, Widget> _tabCache = {};

  static const List<_MenuItem> _menuItems = [
    // ── Tổng quan ──
    _MenuItem(Icons.dashboard_rounded, 'Tổng quan'),
    // ── Sản phẩm ──
    _MenuItem(null, 'SẢN PHẨM', isSection: true),
    _MenuItem(Icons.category_rounded, 'Danh mục'),
    _MenuItem(Icons.shopping_bag_rounded, 'Sản phẩm'),
    _MenuItem(Icons.verified_rounded, 'Thương hiệu'),
    _MenuItem(Icons.warehouse_rounded, 'Quản lý kho'),
    // ── Bán hàng ──
    _MenuItem(null, 'BÁN HÀNG', isSection: true),
    _MenuItem(Icons.receipt_long_rounded, 'Đơn hàng'),
    _MenuItem(Icons.account_balance_wallet_rounded, 'Thanh toán'),
    _MenuItem(Icons.swap_horiz_rounded, 'Đổi trả'),
    // ── Khách hàng & Marketing ──
    _MenuItem(null, 'MARKETING', isSection: true),
    _MenuItem(Icons.people_rounded, 'Khách hàng'),
    _MenuItem(Icons.local_offer_rounded, 'Khuyến mãi'),
    _MenuItem(Icons.star_rounded, 'Đánh giá'),
    _MenuItem(Icons.feedback_rounded, 'Phản hồi'),
    _MenuItem(Icons.image_rounded, 'Banner'),
    // ── Hệ thống ──
    _MenuItem(null, 'HỆ THỐNG', isSection: true),
    _MenuItem(Icons.settings_rounded, 'Cài đặt'),
  ];

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
    // Notify all content widgets to close their slide panels
    DashboardScreen.panelCloseNotifier.value++;
  }

  /// Lazily build & cache the widget for a given tab index.
  Widget _getOrBuildTab(int index) {
    return _tabCache.putIfAbsent(index, () => _buildContentForTab(index));
  }

  Future<void> _handleSignOut(AuthProvider auth) async {
    await auth.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const AuthShell()));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final dividerColor = _dividerColor(isDarkMode);

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBg : AppTheme.lightBg,
      body: Row(
        children: [
          _buildSidebar(isDarkMode, auth),
          Container(width: 1, color: dividerColor),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isDarkMode, auth),
                Expanded(
                  // Only build tabs that have been visited (lazy)
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: List<Widget>.generate(_menuItems.length, (index) {
                      // Only build the tab if it has been selected before
                      if (_tabCache.containsKey(index) || index == _selectedIndex) {
                        return _getOrBuildTab(index);
                      }
                      // Placeholder for unvisited tabs — zero cost
                      return const SizedBox.shrink();
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── SIDEBAR ───
  Widget _buildSidebar(bool isDarkMode, AuthProvider auth) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : AppTheme.white,
      ),
      child: Column(
        children: [
          // ── Brand header ──
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [const Color(0xFF1E293B), const Color(0xFF172033)]
                    : [const Color(0xFFFFFFFF), const Color(0xFFF7F3FF)],
              ),
              border: Border(
                bottom: BorderSide(color: _dividerColor(isDarkMode), width: 1),
              ),
            ),
            alignment: Alignment.center,
            child: _buildBrandMark(isDarkMode),
          ),
          // ── Menu items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                if (item.isSection) {
                  return _buildSectionHeader(item.label, isDarkMode);
                }
                return _buildSidebarItem(item, index, isDarkMode);
              },
            ),
          ),
          // ── Sign out ──
          Container(height: 1, color: _dividerColor(isDarkMode)),
          Padding(
            padding: const EdgeInsets.all(8),
            child: SizedBox(
              height: 34,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _handleSignOut(auth),
                icon: const Icon(Icons.logout_rounded, size: 14),
                label: const Text('Đăng xuất', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  side: BorderSide(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 8, top: 10, bottom: 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.3)
              : AppTheme.textLight.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildSidebarItem(_MenuItem item, int index, bool isDarkMode) {
    final selected = _selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onTabSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: selected
                ? const Color(
                    0xFF7C3AED,
                  ).withValues(alpha: isDarkMode ? 0.28 : 0.14)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                size: 16,
                color: selected
                    ? const Color(0xFF7C3AED)
                    : (isDarkMode ? Colors.white70 : AppTheme.textLight),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF7C3AED)
                        : (isDarkMode ? Colors.white : AppTheme.textDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrandMark(bool isDarkMode) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        'assets/logo.png',
        width: 46,
        height: 46,
        fit: BoxFit.contain,
      ),
    );
  }

  // ─── TOP BAR ───
  Widget _buildTopBar(bool isDarkMode, AuthProvider auth) {
    final title = _menuItems[_selectedIndex].label;
    final email = auth.user?.email ?? 'admin';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          // ── Title ──
          if (_menuItems[_selectedIndex].icon != null)
            Icon(
              _menuItems[_selectedIndex].icon,
              size: 18,
              color: const Color(0xFF7C3AED),
            ),
          const SizedBox(width: 8),
          Expanded(child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          )),

          // ── Notification bell ──
          const NotificationBell(),
          const SizedBox(width: 6),

          // ── User pill ──
          Container(
            padding: const EdgeInsets.only(left: 4, right: 10, top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFFF5F3FF),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    email,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _dividerColor(bool isDarkMode) {
    return isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : AppTheme.borderColor;
  }

  Widget _buildContentForTab(int index) {
    switch (index) {
      case 0:  return DashboardContent(onNavigateTab: _onTabSelected);
      // case 1: section SẢN PHẨM
      case 2:  return const CategoryContent();
      case 3:  return const ProductContent();
      case 4:  return const BrandContent();
      case 5:  return const InventoryContent();
      // case 6: section BÁN HÀNG
      case 7:  return const OrderContent();
      case 8:  return const PaymentContent();
      case 9:  return const RmaContent();
      // case 10: section MARKETING
      case 11: return const CustomerContent();
      case 12: return const PromotionContent();
      case 13: return const ReviewContent();
      case 14: return const FeedbackContent();
      case 15: return const BannerContent();
      // case 16: section HỆ THỐNG
      case 17: return const SettingsContent();
      default: return const SizedBox.shrink();
    }
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label, {this.isSection = false});

  final IconData? icon;
  final String label;
  final bool isSection;
}
