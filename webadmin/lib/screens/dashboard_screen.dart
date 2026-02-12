import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/auth_provider.dart';
import '../providers/category_provider.dart';
import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/audit_log_content.dart';
import '../widgets/category_content.dart';
import '../widgets/cms_content.dart';
import '../widgets/customer_content.dart';
import '../widgets/inventory_content.dart';
import '../widgets/order_content.dart';
import '../widgets/payment_content.dart';
import '../widgets/product_content.dart';
import '../widgets/promotion_content.dart';
import '../widgets/report_content.dart';
import '../widgets/rma_content.dart';
import '../widgets/settings_content.dart';

import '../widgets/warehouse_receipt_content.dart';
import '../widgets/theme_wave_overlay.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  late final List<Widget?> _tabCache;

  // Dashboard filter state
  String _selectedPeriod = '30 ngày';
  DateTimeRange? _customRange;

  static const _periodOptions = [
    'Hôm nay',
    '7 ngày',
    '30 ngày',
    'Tháng này',
    'Tùy chỉnh',
  ];

  List<dynamic> _filterOrdersByPeriod(List<dynamic> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime start;
    DateTime end = now;

    switch (_selectedPeriod) {
      case 'Hôm nay':
        start = today;
        break;
      case '7 ngày':
        start = today.subtract(const Duration(days: 6));
        break;
      case '30 ngày':
        start = today.subtract(const Duration(days: 29));
        break;
      case 'Tháng này':
        start = DateTime(now.year, now.month, 1);
        break;
      case 'Tùy chỉnh':
        if (_customRange != null) {
          start = _customRange!.start;
          end = _customRange!.end.add(
            const Duration(hours: 23, minutes: 59, seconds: 59),
          );
        } else {
          start = today.subtract(const Duration(days: 29));
        }
        break;
      default:
        start = today.subtract(const Duration(days: 29));
    }

    return orders
        .where(
          (o) =>
              o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
              o.createdAt.isBefore(end.add(const Duration(seconds: 1))),
        )
        .toList();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    // Pick start date
    final startDate = await showDatePicker(
      context: context,
      initialDate:
          _customRange?.start ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2024),
      lastDate: now,
      helpText: 'Ngày bắt đầu',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF7C3AED)),
          ),
          child: child!,
        );
      },
    );
    if (startDate == null || !mounted) return;

    // Pick end date
    final endDate = await showDatePicker(
      context: context,
      initialDate: _customRange?.end ?? now,
      firstDate: startDate,
      lastDate: now,
      helpText: 'Ngày kết thúc',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF7C3AED)),
          ),
          child: child!,
        );
      },
    );
    if (endDate == null || !mounted) return;

    setState(() {
      _customRange = DateTimeRange(start: startDate, end: endDate);
      _selectedPeriod = 'Tùy chỉnh';
    });
  }

  static const List<_MenuItem> _menuItems = [
    _MenuItem(Icons.dashboard_rounded, 'Tổng quan'),
    _MenuItem(Icons.shopping_bag_rounded, 'Sản phẩm'),
    _MenuItem(Icons.category_rounded, 'Danh mục'),
    _MenuItem(Icons.inventory_2_rounded, 'Tồn kho'),
    _MenuItem(Icons.receipt_long_rounded, 'Đơn hàng'),
    _MenuItem(Icons.account_balance_wallet_rounded, 'Thanh toán'),
    _MenuItem(Icons.people_rounded, 'Khách hàng'),
    _MenuItem(Icons.local_offer_rounded, 'Khuyến mãi'),
    _MenuItem(Icons.image_rounded, 'Banner'),
    _MenuItem(Icons.bar_chart_rounded, 'Báo cáo'),
    _MenuItem(Icons.assignment_rounded, 'Phiếu kho'),
    _MenuItem(Icons.swap_horiz_rounded, 'Đổi trả'),
    _MenuItem(Icons.history_rounded, 'Nhật ký'),
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
                      // Don't cache dashboard tab (index 0) so filters can rebuild it
                      if (index == 0) return _buildDashboardOverview();
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

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [const Color(0xFF1E293B), const Color(0xFF182235)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF9F5FF)],
        ),
        border: Border(
          bottom: BorderSide(color: _dividerColor(isDarkMode), width: 1),
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
                    color: const Color(
                      0xFF7C3AED,
                    ).withValues(alpha: isDarkMode ? 0.26 : 0.12),
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
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDarkMode
                                    ? Colors.white
                                    : AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.58)
                              : AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const ThemeToggleButton(),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.lightBg,
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.12)
                    : AppTheme.borderColor,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white70 : AppTheme.textLight,
                    ),
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
      case 0:
        return _buildDashboardOverview();
      case 1:
        return const ProductContent();
      case 2:
        return const CategoryContent();
      case 3:
        return const InventoryContent();
      case 4:
        return const OrderContent();
      case 5:
        return const PaymentContent();
      case 6:
        return const CustomerContent();
      case 7:
        return const PromotionContent();
      case 8:
        return const CmsContent();
      case 9:
        return const ReportContent();
      case 10:
        return const WarehouseReceiptContent();
      case 11:
        return const RmaContent();
      case 12:
        return const AuditLogContent();
      case 13:
        return const SettingsContent();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDashboardOverview() {
    return Consumer3<ProductProvider, OrderProvider, CategoryProvider>(
      builder: (context, productProvider, orderProvider, categoryProvider, _) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        final allProducts = productProvider.products
            .where((p) => !p.isDeleted)
            .toList();
        final totalProducts = allProducts.length;
        final activeProducts = allProducts.where((p) => p.isActive).length;
        final lowStock = allProducts
            .where((p) => p.stock <= 5 && p.stock > 0)
            .length;
        final outOfStock = allProducts.where((p) => p.stock <= 0).length;

        final allOrdersRaw = orderProvider.orders;
        final allOrders = _filterOrdersByPeriod(allOrdersRaw);
        final totalOrders = allOrders.length;
        final pendingOrders = allOrders
            .where((o) => o.status == 'Chờ xử lý')
            .length;
        final shippingOrders = allOrders
            .where((o) => o.status == 'Đang giao')
            .length;
        final deliveredOrders = allOrders
            .where((o) => o.status == 'Đã giao')
            .length;
        final totalRevenue = allOrders
            .where((o) => o.status == 'Đã giao')
            .fold<double>(0, (sum, o) => sum + o.total);

        final totalCategories = categoryProvider.categories.length;

        final recentOrders = List.of(allOrders)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final displayOrders = recentOrders.take(5).toList();

        final isLoading = productProvider.isLoading && allProducts.isEmpty;

        final now = DateTime.now();
        final greeting = now.hour < 12
            ? 'Chào buổi sáng'
            : now.hour < 18
            ? 'Chào buổi chiều'
            : 'Chào buổi tối';
        final dateStr =
            '${_weekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // ─── GREETING ───
                Text(
                  '$greeting! 👋',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng quan hoạt động cửa hàng · $dateStr',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.55)
                        : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 16),

                // ─── FILTER CHIPS ───
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _periodOptions.map((period) {
                      final isSelected = _selectedPeriod == period;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            period == 'Tùy chỉnh' &&
                                    _customRange != null &&
                                    _selectedPeriod == 'Tùy chỉnh'
                                ? '${_customRange!.start.day.toString().padLeft(2, '0')}/${_customRange!.start.month.toString().padLeft(2, '0')} – ${_customRange!.end.day.toString().padLeft(2, '0')}/${_customRange!.end.month.toString().padLeft(2, '0')}'
                                : period,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode
                                        ? Colors.white70
                                        : AppTheme.textDark),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF7C3AED),
                          backgroundColor: isDarkMode
                              ? AppTheme.darkCardBg
                              : const Color(0xFFF3F4F6),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          onSelected: (_) {
                            if (period == 'Tùy chỉnh') {
                              _pickCustomRange();
                            } else {
                              setState(() => _selectedPeriod = period);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // ─── CHARTS SECTION (TOP) ───
                Text(
                  'Biểu đồ thống kê',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 14),

                // TWO CHARTS SIDE BY SIDE
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    final charts = [
                      _buildChartCard(
                        isDarkMode,
                        title: 'Doanh thu 7 ngày qua',
                        child: SizedBox(
                          height: 220,
                          child: _buildRevenueLineChart(isDarkMode, allOrders),
                        ),
                      ),
                      _buildChartCard(
                        isDarkMode,
                        title: 'Trạng thái đơn hàng',
                        child: SizedBox(
                          height: 220,
                          child: _buildOrderStatusDonut(isDarkMode, allOrders),
                        ),
                      ),
                    ];

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: charts[0]),
                          const SizedBox(width: 14),
                          Expanded(flex: 2, child: charts[1]),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        charts[0],
                        const SizedBox(height: 14),
                        charts[1],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 14),

                _buildChartCard(
                  isDarkMode,
                  title: 'Sản phẩm theo danh mục',
                  child: SizedBox(
                    height: 220,
                    child: _buildCategoryBarChart(
                      isDarkMode,
                      categoryProvider.categories,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ─── REVENUE CARD ───
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tổng doanh thu',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _fmtVND(totalRevenue),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Từ $deliveredOrders đơn hàng đã giao',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ─── STAT CARDS ROW 1: PRODUCTS ───
                Text(
                  'Sản phẩm',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _buildStatCard(
                      isDarkMode,
                      title: 'Tổng sản phẩm',
                      value: '$totalProducts',
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF7C3AED),
                    ),
                    _buildStatCard(
                      isDarkMode,
                      title: 'Đang hoạt động',
                      value: '$activeProducts',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                    ),
                    _buildStatCard(
                      isDarkMode,
                      title: 'Sắp hết hàng',
                      value: '$lowStock',
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    _buildStatCard(
                      isDarkMode,
                      title: 'Hết hàng',
                      value: '$outOfStock',
                      icon: Icons.remove_shopping_cart_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── STAT CARDS ROW 2: ORDERS ───
                Text(
                  'Đơn hàng',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white70 : AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _buildStatCard(
                      isDarkMode,
                      title: 'Tổng đơn hàng',
                      value: '$totalOrders',
                      icon: Icons.receipt_long_rounded,
                      color: const Color(0xFF3B82F6),
                    ),
                    _buildStatCard(
                      isDarkMode,
                      title: 'Chờ xử lý',
                      value: '$pendingOrders',
                      icon: Icons.hourglass_empty_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    _buildStatCard(
                      isDarkMode,
                      title: 'Đang giao',
                      value: '$shippingOrders',
                      icon: Icons.local_shipping_rounded,
                      color: const Color(0xFF06B6D4),
                    ),
                    _buildStatCard(
                      isDarkMode,
                      title: 'Danh mục',
                      value: '$totalCategories',
                      icon: Icons.category_rounded,
                      color: const Color(0xFF8B5CF6),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ─── RECENT ORDERS TABLE ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Đơn hàng gần đây',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _onTabSelected(4),
                      child: const Text(
                        'Xem tất cả →',
                        style: TextStyle(
                          color: Color(0xFF7C3AED),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.darkCardBg : AppTheme.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : AppTheme.borderColor,
                    ),
                  ),
                  child: displayOrders.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'Chưa có đơn hàng nào',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.white54
                                    : AppTheme.textLight,
                              ),
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                              child: DataTable(
                              headingRowColor: WidgetStateProperty.all(
                                isDarkMode
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF8FAFC),
                              ),
                              columnSpacing: 20,
                              columns: const [
                                DataColumn(label: Text('Mã đơn')),
                                DataColumn(label: Text('Khách hàng')),
                                DataColumn(label: Text('Tổng tiền')),
                                DataColumn(label: Text('Trạng thái')),
                                DataColumn(label: Text('Ngày tạo')),
                              ],
                              rows: displayOrders.map((order) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        order.code,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Colors.white
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        order.customerName,
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        _fmtVND(order.total),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode
                                              ? Colors.white
                                              : AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                    DataCell(_buildStatusChip(order.status)),
                                    DataCell(
                                      Text(
                                        '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDarkMode
                                              ? Colors.white54
                                              : AppTheme.textLight,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ), // DataTable
                           ), // ConstrainedBox
                          ), // SingleChildScrollView
                         ), // LayoutBuilder
                        ), // ClipRRect
                ),
                const SizedBox(height: 28),

                // ─── QUICK ACTIONS ───
                Text(
                  'Thao tác nhanh',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    _buildQuickAction(
                      isDarkMode,
                      icon: Icons.add_shopping_cart_rounded,
                      label: 'Thêm sản phẩm',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _onTabSelected(1),
                    ),
                    _buildQuickAction(
                      isDarkMode,
                      icon: Icons.receipt_long_rounded,
                      label: 'Quản lý đơn hàng',
                      color: const Color(0xFF3B82F6),
                      onTap: () => _onTabSelected(4),
                    ),
                    _buildQuickAction(
                      isDarkMode,
                      icon: Icons.people_rounded,
                      label: 'Khách hàng',
                      color: const Color(0xFF10B981),
                      onTap: () => _onTabSelected(7),
                    ),
                    _buildQuickAction(
                      isDarkMode,
                      icon: Icons.bar_chart_rounded,
                      label: 'Báo cáo',
                      color: const Color(0xFFF59E0B),
                      onTap: () => _onTabSelected(10),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // CHART BUILDERS
  // ═══════════════════════════════════════════

  Widget _buildChartCard(
    bool isDarkMode, {
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : AppTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white70 : AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildRevenueLineChart(bool isDarkMode, List<dynamic> allOrders) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final dayLabels = <String>[];

    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayRevenue = allOrders
          .where(
            (o) =>
                o.status == 'Đã giao' &&
                o.createdAt.year == day.year &&
                o.createdAt.month == day.month &&
                o.createdAt.day == day.day,
          )
          .fold<double>(0, (sum, o) => sum + o.total);
      spots.add(FlSpot((6 - i).toDouble(), dayRevenue / 1000)); // show in K
      dayLabels.add('${day.day}/${day.month}');
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final ceilY = maxY < 10 ? 10.0 : (maxY * 1.3);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: ceilY / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFEEEEEE),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              interval: ceilY / 4,
              getTitlesWidget: (v, meta) => Text(
                '${v.toInt()}K',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white38 : AppTheme.textLight,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: 1,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= dayLabels.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dayLabels[idx],
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.white38 : AppTheme.textLight,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: ceilY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: const Color(0xFF7C3AED),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2.5,
                strokeColor: const Color(0xFF7C3AED),
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF7C3AED).withValues(alpha: 0.25),
                  const Color(0xFF7C3AED).withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) {
              return LineTooltipItem(
                _fmtVND(s.y * 1000),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      duration: Duration.zero,
    );
  }

  Widget _buildOrderStatusDonut(bool isDarkMode, List<dynamic> allOrders) {
    final statusMap = <String, int>{};
    for (final o in allOrders) {
      statusMap[o.status] = (statusMap[o.status] ?? 0) + 1;
    }

    if (statusMap.isEmpty) {
      return Center(
        child: Text(
          'Chưa có đơn hàng',
          style: TextStyle(
            color: isDarkMode ? Colors.white54 : AppTheme.textLight,
          ),
        ),
      );
    }

    final colors = <String, Color>{
      'Chờ xử lý': const Color(0xFFF59E0B),
      'Đã xác nhận': const Color(0xFF3B82F6),
      'Đang giao': const Color(0xFF06B6D4),
      'Đã giao': const Color(0xFF10B981),
      'Đã hủy': const Color(0xFFEF4444),
    };

    final sections = statusMap.entries.map((e) {
      final color = colors[e.key] ?? const Color(0xFF6B7280);
      return PieChartSectionData(
        value: e.value.toDouble(),
        color: color,
        radius: 30,
        title: '${e.value}',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 36,
              sectionsSpace: 2,
            ),
            duration: Duration.zero,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: statusMap.entries.map((e) {
            final color = colors[e.key] ?? const Color(0xFF6B7280);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${e.key} (${e.value})',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode ? Colors.white70 : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCategoryBarChart(bool isDarkMode, List<dynamic> categories) {
    if (categories.isEmpty) {
      return Center(
        child: Text(
          'Chưa có danh mục',
          style: TextStyle(
            color: isDarkMode ? Colors.white54 : AppTheme.textLight,
          ),
        ),
      );
    }

    final barColors = [
      const Color(0xFF7C3AED),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEC4899),
      const Color(0xFF06B6D4),
      const Color(0xFFEF4444),
      const Color(0xFF8B5CF6),
    ];

    double maxCount = 1;
    for (final c in categories) {
      if (c.productCount > maxCount) maxCount = c.productCount.toDouble();
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount * 1.3,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, gIdx, rod, rIdx) {
              final cat = categories[group.x.toInt()];
              return BarTooltipItem(
                '${cat.name}\n${cat.productCount} sản phẩm',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              getTitlesWidget: (v, meta) {
                final idx = v.toInt();
                if (idx < 0 || idx >= categories.length) {
                  return const SizedBox();
                }
                final name = categories[idx].name as String;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    name.length > 8 ? '${name.substring(0, 7)}…' : name,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDarkMode ? Colors.white38 : AppTheme.textLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: (maxCount / 4).ceilToDouble().clamp(1, double.infinity),
              getTitlesWidget: (v, meta) => Text(
                '${v.toInt()}',
                style: TextStyle(
                  fontSize: 10,
                  color: isDarkMode ? Colors.white38 : AppTheme.textLight,
                ),
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxCount / 4).ceilToDouble().clamp(
            1,
            double.infinity,
          ),
          getDrawingHorizontalLine: (v) => FlLine(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFEEEEEE),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(categories.length, (i) {
          final c = categories[i];
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: c.productCount.toDouble(),
                color: barColors[i % barColors.length],
                width: 22,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
      duration: Duration.zero,
    );
  }

  Widget _buildStatCard(
    bool isDarkMode, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return SizedBox(
      width: 250,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardBg : AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDarkMode ? Colors.white : AppTheme.textDark,
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.65)
                          : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Chờ xử lý':
        color = const Color(0xFFF59E0B);
        break;
      case 'Đã xác nhận':
        color = const Color(0xFF3B82F6);
        break;
      case 'Đang giao':
        color = const Color(0xFF06B6D4);
        break;
      case 'Đã giao':
        color = const Color(0xFF10B981);
        break;
      case 'Đã hủy':
        color = const Color(0xFFEF4444);
        break;
      default:
        color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    bool isDarkMode, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 165,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardBg : AppTheme.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _weekday(int w) {
    const days = [
      '',
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return days[w];
  }

  String _fmtVND(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }
}

class _MenuItem {
  const _MenuItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
