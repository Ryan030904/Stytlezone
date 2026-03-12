import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';

import '../widgets/category_content.dart';
import '../widgets/cms_content.dart';
import '../widgets/customer_content.dart';
import '../widgets/dashboard_content.dart';
import '../widgets/inventory_content.dart';
import '../widgets/order_content.dart';
import '../widgets/payment_content.dart';
import '../widgets/product_content.dart';
import '../widgets/promotion_content.dart';
import '../widgets/review_content.dart';
import '../widgets/rma_content.dart';
import '../widgets/settings_content.dart';
import '../widgets/notification_bell.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late final List<Widget?> _tabCache;

  static const List<_MenuItem> _menuItems = [
    // ── Tổng quan ──
    _MenuItem(Icons.dashboard_rounded, 'Tổng quan'),
    // ── Sản phẩm ──
    _MenuItem(null, 'SẢN PHẨM', isSection: true),
    _MenuItem(Icons.category_rounded, 'Danh mục'),
    _MenuItem(Icons.shopping_bag_rounded, 'Sản phẩm'),
    _MenuItem(Icons.warehouse_rounded, 'Quản lý kho'),
    // ── Bán hàng ──
    _MenuItem(null, 'BÁN HÀNG', isSection: true),
    _MenuItem(Icons.receipt_long_rounded, 'Đơn hàng'),
    _MenuItem(Icons.account_balance_wallet_rounded, 'Thanh toán'),
    _MenuItem(Icons.swap_horiz_rounded, 'Đổi trả'),
    // ── Khách hàng & Marketing ──
    _MenuItem(null, 'KHÁCH HÀNG & MARKETING', isSection: true),
    _MenuItem(Icons.people_rounded, 'Khách hàng'),
    _MenuItem(Icons.local_offer_rounded, 'Khuyến mãi'),
    _MenuItem(Icons.star_rounded, 'Đánh giá'),
    _MenuItem(Icons.image_rounded, 'Banner'),
    // ── Hệ thống ──
    _MenuItem(null, 'HỆ THỐNG', isSection: true),
    _MenuItem(Icons.settings_rounded, 'Cài đặt'),
  ];

  @override
  void initState() {
    super.initState();
    _tabCache = List<Widget?>.generate(
      _menuItems.length,
      _buildContentForTab,
      growable: false,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().loadProducts();
      context.read<OrderProvider>().loadOrders();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  void _onTabSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleSignOut(AuthProvider auth) async {
    await auth.signOut();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
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
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: List<Widget>.generate(_menuItems.length, (index) {
                      if (index == 0) return DashboardContent(onNavigateTab: _onTabSelected);
                      return _tabCache[index] ?? const SizedBox.shrink();
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

  Widget _buildSidebar(bool isDarkMode, AuthProvider auth) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : AppTheme.white,
      ),
      child: Column(
        children: [
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                _buildBrandMark(isDarkMode),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StyleZone Admin',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1,
                          color: isDarkMode ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Trung tâm điều hành',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.55)
                              : const Color(0xFF7C3AED).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
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
          Container(height: 1, color: _dividerColor(isDarkMode)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: OutlinedButton.icon(
              onPressed: () => _handleSignOut(auth),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Đăng xuất'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: BorderSide(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                ),
                minimumSize: const Size(double.infinity, 42),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(left: 22, right: 10, top: 16, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onTabSelected(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
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
                size: 20,
                color: selected
                    ? const Color(0xFF7C3AED)
                    : (isDarkMode ? Colors.white70 : AppTheme.textLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
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
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D28D9), Color(0xFF9333EA), Color(0xFFEC4899)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFF7C3AED,
            ).withValues(alpha: isDarkMode ? 0.28 : 0.32),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(bool isDarkMode, AuthProvider auth) {
    final title = _menuItems[_selectedIndex].label;
    final email = auth.user?.email ?? 'admin';
    final subtitle = _selectedIndex == 0
        ? 'Theo dõi hoạt động cửa hàng theo thời gian thực'
        : 'Quản trị $title';
    final initials = email.isNotEmpty ? email[0].toUpperCase() : 'A';

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFF9F5FF)],
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.borderColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(11),
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    _menuItems[_selectedIndex].icon,
                    size: 20,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Notification bell ──
          const NotificationBell(),
          const SizedBox(width: 6),

          // ── User profile pill ──
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.only(left: 4, right: 14, top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: const Color(0xFFF5F3FF),
              border: Border.all(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const Text(
                        'Quản trị viên',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
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
      case 4:  return const InventoryContent();
      // case 5: section BÁN HÀNG
      case 6:  return const OrderContent();
      case 7:  return const PaymentContent();
      case 8:  return const RmaContent();
      // case 9: section KHÁCH HÀNG & MARKETING
      case 10: return const CustomerContent();
      case 11: return const PromotionContent();
      case 12: return const ReviewContent();
      case 13: return const CmsContent();
      // case 14: section HỆ THỐNG
      case 15: return const SettingsContent();
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
