import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../utils/money_formatter.dart';

/// Dashboard — modern production-ready design.
class DashboardContent extends StatefulWidget {
  final void Function(int tabIndex)? onNavigateTab;
  const DashboardContent({super.key, this.onNavigateTab});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProductProvider>().loadProducts();
      context.read<OrderProvider>().loadOrders();
      context.read<CategoryProvider>().loadCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, OrderProvider, CategoryProvider>(
      builder: (context, productProv, orderProv, categoryProv, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        final products = productProv.products.where((p) => !p.isDeleted).toList();
        final orders = orderProv.orders;
        final categories = categoryProv.categories;

        if (productProv.isLoading && products.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
        }

        // ─── Computed data ───
        final activeProducts = products.where((p) => p.isActive).length;
        final outOfStock = products.where((p) => p.stock <= 0).length;
        final lowStock = products.where((p) => p.stock > 0 && p.stock <= 10).length;

        final delivered = orders.where((o) => o.status == 'Đã giao').toList();
        final pending = orders.where((o) => o.status == 'Chờ xử lý').length;
        final shipping = orders.where((o) => o.status == 'Đang giao').length;
        final revenue = delivered.fold<double>(0, (s, o) => s + o.total);

        // Sold map
        final soldMap = <String, int>{};
        for (final o in delivered) {
          for (final item in o.items) {
            soldMap[item.productId] = (soldMap[item.productId] ?? 0) + item.quantity;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════
              // SECTION 1 — Welcome Banner
              // ═══════════════════════════
              _WelcomeBanner(
                revenue: revenue,
                totalOrders: orders.length,
                pending: pending,
                shipping: shipping,
              ),
              const SizedBox(height: 24),

              // ═══════════════════════════
              // SECTION 2 — Stat Cards
              // ═══════════════════════════
              _buildStatCards(isDark, revenue, orders.length, activeProducts, categories.length, outOfStock, lowStock, pending),
              const SizedBox(height: 24),

              // ═══════════════════════════
              // SECTION 3 — Charts Row
              // ═══════════════════════════
              LayoutBuilder(builder: (ctx, box) {
                final wide = box.maxWidth > 760;
                final revenueChart = _RevenueChart(isDark: isDark, orders: orders);
                final donut = _OrderDonut(isDark: isDark, orders: orders);
                if (wide) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 5, child: revenueChart),
                    const SizedBox(width: 20),
                    Expanded(flex: 3, child: donut),
                  ]);
                }
                return Column(children: [revenueChart, const SizedBox(height: 20), donut]);
              }),
              const SizedBox(height: 24),

              // ═══════════════════════════
              // SECTION 4 — Activity + Top Products + Alerts
              // ═══════════════════════════
              LayoutBuilder(builder: (ctx, box) {
                final wide = box.maxWidth > 760;
                final activity = _ActivityFeed(isDark: isDark, orders: orders, onViewAll: () => widget.onNavigateTab?.call(7));
                final topProd = _TopProducts(isDark: isDark, products: products, soldMap: soldMap);
                final alerts = _StockAlerts(isDark: isDark, products: products, onNavigate: () => widget.onNavigateTab?.call(5));
                if (wide) {
                  return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(flex: 2, child: activity),
                    const SizedBox(width: 20),
                    Expanded(flex: 1, child: topProd),
                    const SizedBox(width: 20),
                    Expanded(flex: 1, child: alerts),
                  ]);
                }
                return Column(children: [activity, const SizedBox(height: 20), topProd, const SizedBox(height: 20), alerts]);
              }),
            ],
          ),
        );
      },
    );
  }

  // ─── Stat Cards ───
  Widget _buildStatCards(bool isDark, double revenue, int totalOrders, int activeProducts, int totalCategories, int outOfStock, int lowStock, int pending) {
    return Row(children: [
      Expanded(child: _StatCard(
        isDark: isDark,
        label: 'Doanh thu',
        value: formatVND(revenue),
        icon: Icons.trending_up_rounded,
        gradient: const [Color(0xFF6D28D9), Color(0xFF7C3AED)],
        detail: 'tổng cộng',
      )),
      const SizedBox(width: 16),
      Expanded(child: _StatCard(
        isDark: isDark,
        label: 'Đơn hàng',
        value: '$totalOrders',
        icon: Icons.shopping_cart_rounded,
        gradient: const [Color(0xFF2563EB), Color(0xFF3B82F6)],
        detail: '$pending chờ xử lý',
      )),
      const SizedBox(width: 16),
      Expanded(child: _StatCard(
        isDark: isDark,
        label: 'Sản phẩm',
        value: '$activeProducts',
        icon: Icons.inventory_2_rounded,
        gradient: const [Color(0xFF059669), Color(0xFF10B981)],
        detail: '$lowStock sắp hết · $outOfStock hết',
      )),
      const SizedBox(width: 16),
      Expanded(child: _StatCard(
        isDark: isDark,
        label: 'Danh mục',
        value: '$totalCategories',
        icon: Icons.grid_view_rounded,
        gradient: const [Color(0xFFD97706), Color(0xFFF59E0B)],
        detail: 'đang hoạt động',
      )),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════════
// WELCOME BANNER — Gradient card with summary
// ═══════════════════════════════════════════════════════════════
class _WelcomeBanner extends StatelessWidget {
  final double revenue;
  final int totalOrders;
  final int pending;
  final int shipping;
  const _WelcomeBanner({required this.revenue, required this.totalOrders, required this.pending, required this.shipping});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12 ? 'Chào buổi sáng' : now.hour < 18 ? 'Chào buổi chiều' : 'Chào buổi tối';
    final dateStr = '${_wd(now.weekday)}, ${now.day.toString().padLeft(2, '0')} tháng ${now.month.toString().padLeft(2, '0')}, ${now.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6D28D9), Color(0xFF7C3AED), Color(0xFF9333EA)],
        ),
        boxShadow: [
          BoxShadow(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          // Left — Greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 4),
                Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 16),
                Row(children: [
                  _bannerChip(Icons.receipt_long_rounded, '$pending chờ xử lý'),
                  const SizedBox(width: 10),
                  _bannerChip(Icons.local_shipping_rounded, '$shipping đang giao'),
                ]),
              ],
            ),
          ),
          // Right — Revenue highlight
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Tổng doanh thu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Text(formatVND(revenue), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text('$totalOrders đơn hàng', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bannerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.9))),
      ]),
    );
  }

  static String _wd(int d) => const ['', 'Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'CN'][d];
}

// ═══════════════════════════════════════════════════════════════
// STAT CARD — Gradient icon + value + detail
// ═══════════════════════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final bool isDark;
  final String label;
  final String value;
  final IconData icon;
  final List<Color> gradient;
  final String detail;
  const _StatCard({required this.isDark, required this.label, required this.value, required this.icon, required this.gradient, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              gradient: LinearGradient(colors: gradient),
            ),
            child: Icon(icon, size: 17, color: Colors.white),
          ),
          const Spacer(),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
        ]),
        const SizedBox(height: 14),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827), letterSpacing: -0.3), overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(detail, style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REVENUE CHART — Smooth area chart
// ═══════════════════════════════════════════════════════════════
class _RevenueChart extends StatelessWidget {
  final bool isDark;
  final List<dynamic> orders;
  const _RevenueChart({required this.isDark, required this.orders});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final labels = <String>[];

    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final rev = orders
          .where((o) => o.status == 'Đã giao' && o.createdAt.year == day.year && o.createdAt.month == day.month && o.createdAt.day == day.day)
          .fold<double>(0, (s, o) => s + o.total);
      spots.add(FlSpot((6 - i).toDouble(), rev / 1000));
      labels.add('${day.day}/${day.month}');
    }

    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);
    final ceil = maxY < 10 ? 10.0 : maxY * 1.25;

    return _CardShell(
      isDark: isDark,
      icon: Icons.show_chart_rounded,
      title: 'Doanh thu 7 ngày',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true, drawVerticalLine: false, horizontalInterval: ceil / 4,
              getDrawingHorizontalLine: (_) => FlLine(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF0F0F0), strokeWidth: 1),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 40, interval: ceil / 4,
                getTitlesWidget: (v, _) => Text('${v.toInt()}K', style: TextStyle(fontSize: 9, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA))),
              )),
              bottomTitles: AxisTitles(sideTitles: SideTitles(
                showTitles: true, reservedSize: 24, interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  return (i >= 0 && i < labels.length)
                      ? Padding(padding: const EdgeInsets.only(top: 4), child: Text(labels[i], style: TextStyle(fontSize: 9, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA))))
                      : const SizedBox();
                },
              )),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            minX: 0, maxX: 6, minY: 0, maxY: ceil,
            lineBarsData: [
              LineChartBarData(
                spots: spots, isCurved: true, preventCurveOverShooting: true,
                gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)]),
                barWidth: 3, isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 3.5, color: Colors.white, strokeWidth: 2.5, strokeColor: const Color(0xFF7C3AED)),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [const Color(0xFF7C3AED).withValues(alpha: 0.18), const Color(0xFF7C3AED).withValues(alpha: 0.0)],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(formatVND(s.y * 1000), const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11))).toList(),
              ),
            ),
          ),
          duration: Duration.zero,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ORDER DONUT
// ═══════════════════════════════════════════════════════════════
class _OrderDonut extends StatelessWidget {
  final bool isDark;
  final List<dynamic> orders;
  const _OrderDonut({required this.isDark, required this.orders});

  static const _statusColors = {
    'Chờ xử lý': Color(0xFFF59E0B),
    'Đã xác nhận': Color(0xFF3B82F6),
    'Đang giao': Color(0xFF06B6D4),
    'Đã giao': Color(0xFF10B981),
    'Đã hủy': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    final map = <String, int>{};
    for (final o in orders) {
      map[o.status] = (map[o.status] ?? 0) + 1;
    }

    return _CardShell(
      isDark: isDark,
      icon: Icons.donut_large_rounded,
      title: 'Trạng thái đơn',
      child: SizedBox(
        height: 200,
        child: map.isEmpty
            ? Center(child: Text('Chưa có đơn', style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))))
            : Row(children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sections: map.entries.map((e) {
                        final c = _statusColors[e.key] ?? const Color(0xFF6B7280);
                        return PieChartSectionData(value: e.value.toDouble(), color: c, radius: 24, title: '', showTitle: false);
                      }).toList(),
                      centerSpaceRadius: 34,
                      sectionsSpace: 3,
                    ),
                    duration: Duration.zero,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: map.entries.map((e) {
                    final c = _statusColors[e.key] ?? const Color(0xFF6B7280);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(e.key, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white70 : const Color(0xFF374151))),
                        const SizedBox(width: 4),
                        Text('${e.value}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
                      ]),
                    );
                  }).toList(),
                ),
              ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACTIVITY FEED — Timeline of recent orders
// ═══════════════════════════════════════════════════════════════
class _ActivityFeed extends StatelessWidget {
  final bool isDark;
  final List<dynamic> orders;
  final VoidCallback? onViewAll;
  const _ActivityFeed({required this.isDark, required this.orders, this.onViewAll});

  static const _statusIcons = {
    'Chờ xử lý': Icons.hourglass_top_rounded,
    'Đã xác nhận': Icons.check_circle_outline_rounded,
    'Đang giao': Icons.local_shipping_rounded,
    'Đã giao': Icons.verified_rounded,
    'Đã hủy': Icons.cancel_outlined,
  };
  static const _statusColors = {
    'Chờ xử lý': Color(0xFFF59E0B),
    'Đã xác nhận': Color(0xFF3B82F6),
    'Đang giao': Color(0xFF06B6D4),
    'Đã giao': Color(0xFF10B981),
    'Đã hủy': Color(0xFFEF4444),
  };

  @override
  Widget build(BuildContext context) {
    final recent = List.of(orders)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final display = recent.take(6).toList();

    return _CardShell(
      isDark: isDark,
      icon: Icons.history_rounded,
      title: 'Hoạt động gần đây',
      trailing: TextButton(
        onPressed: onViewAll,
        child: const Text('Xem tất cả', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
      ),
      child: display.isEmpty
          ? const SizedBox(height: 120, child: Center(child: Text('Chưa có hoạt động', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))))
          : Column(
              children: display.asMap().entries.map((e) {
                final o = e.value;
                final isLast = e.key == display.length - 1;
                final icon = _statusIcons[o.status] ?? Icons.circle;
                final color = _statusColors[o.status] ?? const Color(0xFF6B7280);
                final ago = _timeAgo(o.createdAt);

                return IntrinsicHeight(
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Timeline dot + line
                    SizedBox(
                      width: 28,
                      child: Column(children: [
                        Container(
                          width: 22, height: 22,
                          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                          child: Icon(icon, size: 12, color: color),
                        ),
                        if (!isLast) Expanded(child: Container(width: 1.5, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB))),
                      ]),
                    ),
                    const SizedBox(width: 10),
                    // Content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${o.code} · ${o.customerName}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text('${o.status} · ${formatVND(o.total)}', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
                          ])),
                          Text(ago, style: TextStyle(fontSize: 9, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA))),
                        ]),
                      ),
                    ),
                  ]),
                );
              }).toList(),
            ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }
}

// ═══════════════════════════════════════════════════════════════
// TOP PRODUCTS
// ═══════════════════════════════════════════════════════════════
class _TopProducts extends StatelessWidget {
  final bool isDark;
  final List<dynamic> products;
  final Map<String, int> soldMap;
  const _TopProducts({required this.isDark, required this.products, required this.soldMap});

  @override
  Widget build(BuildContext context) {
    final sorted = List.of(products)..sort((a, b) => (soldMap[b.id] ?? 0).compareTo(soldMap[a.id] ?? 0));
    final top = sorted.take(5).toList();
    final maxSold = top.isEmpty ? 1 : (soldMap[top.first.id] ?? 1).clamp(1, 999999);

    return _CardShell(
      isDark: isDark,
      icon: Icons.local_fire_department_rounded,
      iconColor: const Color(0xFFEC4899),
      title: 'Bán chạy nhất',
      child: top.isEmpty
          ? const SizedBox(height: 120, child: Center(child: Text('Chưa có dữ liệu', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)))))
          : Column(
              children: top.asMap().entries.map((e) {
                final i = e.key;
                final p = e.value;
                final sold = soldMap[p.id] ?? 0;
                final ratio = sold / maxSold;
                final medal = i < 3;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: medal ? const Color(0xFFF59E0B).withValues(alpha: 0.15) : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: medal ? const Color(0xFFF59E0B) : (isDark ? Colors.white38 : const Color(0xFF9CA3AF))))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF374151))),
                        const SizedBox(height: 3),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: ratio.clamp(0.0, 1.0),
                            minHeight: 3,
                            backgroundColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6),
                            valueColor: AlwaysStoppedAnimation(Color.lerp(const Color(0xFF7C3AED), const Color(0xFFEC4899), ratio) ?? const Color(0xFF7C3AED)),
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(width: 8),
                    Text('$sold', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
                  ]),
                );
              }).toList(),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// STOCK ALERTS
// ═══════════════════════════════════════════════════════════════
class _StockAlerts extends StatelessWidget {
  final bool isDark;
  final List<dynamic> products;
  final VoidCallback? onNavigate;
  const _StockAlerts({required this.isDark, required this.products, this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final alerts = products.where((p) => p.isActive && p.stock <= 10).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    final display = alerts.take(6).toList();

    return _CardShell(
      isDark: isDark,
      icon: Icons.warning_amber_rounded,
      iconColor: const Color(0xFFEF4444),
      title: 'Cảnh báo tồn kho',
      trailing: TextButton(
        onPressed: onNavigate,
        child: const Text('Quản lý kho', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
      ),
      child: display.isEmpty
          ? SizedBox(height: 120, child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.check_circle_rounded, size: 16, color: const Color(0xFF10B981).withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text('Tồn kho ổn định', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
            ])))
          : Column(
              children: display.map((p) {
                final danger = p.stock == 0;
                final color = danger ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: isDark ? 0.08 : 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Row(children: [
                      Icon(danger ? Icons.error_rounded : Icons.warning_rounded, size: 14, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF374151)))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                        child: Text(danger ? 'Hết hàng' : '${p.stock} sp', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                      ),
                    ]),
                  ),
                );
              }).toList(),
            ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SHARED — Card Shell wrapper
// ═══════════════════════════════════════════════════════════════
class _CardShell extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget child;
  final Widget? trailing;
  const _CardShell({required this.isDark, required this.icon, this.iconColor, required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 15, color: iconColor ?? const Color(0xFF7C3AED)),
          const SizedBox(width: 7),
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151))),
          const Spacer(),
          if (trailing != null) trailing!,
        ]),
        const SizedBox(height: 14),
        child,
      ]),
    );
  }
}
