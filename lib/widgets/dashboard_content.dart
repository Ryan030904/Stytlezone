import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';

/// Dashboard overview — tổng hợp dữ liệu từ Product, Order, Category.
class DashboardContent extends StatefulWidget {
  /// Callback khi bấm quick action để chuyển tab.
  final void Function(int tabIndex)? onNavigateTab;

  const DashboardContent({super.key, this.onNavigateTab});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  String _selectedPeriod = '30 ngày';
  DateTimeRange? _customRange;

  static const _periodOptions = ['Hôm nay', '7 ngày', '30 ngày', 'Tháng này', 'Tùy chỉnh'];

  // ═══════════════════════════════════════
  // FILTER HELPERS
  // ═══════════════════════════════════════
  List<dynamic> _filterOrders(List<dynamic> orders) {
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
          end = _customRange!.end.add(const Duration(hours: 23, minutes: 59, seconds: 59));
        } else {
          start = today.subtract(const Duration(days: 29));
        }
        break;
      default:
        start = today.subtract(const Duration(days: 29));
    }

    return orders
        .where((o) =>
            o.createdAt.isAfter(start.subtract(const Duration(seconds: 1))) &&
            o.createdAt.isBefore(end.add(const Duration(seconds: 1))))
        .toList();
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final startDate = await showDatePicker(
      context: context,
      initialDate: _customRange?.start ?? now.subtract(const Duration(days: 30)),
      firstDate: DateTime(2024),
      lastDate: now,
      helpText: 'Ngày bắt đầu',
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: Theme.of(c).colorScheme.copyWith(primary: const Color(0xFF7C3AED)),
        ),
        child: child!,
      ),
    );
    if (startDate == null || !mounted) return;
    final endDate = await showDatePicker(
      context: context,
      initialDate: _customRange?.end ?? now,
      firstDate: startDate,
      lastDate: now,
      helpText: 'Ngày kết thúc',
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: Theme.of(c).colorScheme.copyWith(primary: const Color(0xFF7C3AED)),
        ),
        child: child!,
      ),
    );
    if (endDate == null || !mounted) return;
    setState(() {
      _customRange = DateTimeRange(start: startDate, end: endDate);
      _selectedPeriod = 'Tùy chỉnh';
    });
  }

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Consumer3<ProductProvider, OrderProvider, CategoryProvider>(
      builder: (context, productProv, orderProv, categoryProv, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        // ─── Data ───
        final allProducts = productProv.products.where((p) => !p.isDeleted).toList();
        final totalProducts = allProducts.length;
        final activeProducts = allProducts.where((p) => p.isActive).length;
        final lowStock = allProducts.where((p) => p.stock <= 5 && p.stock > 0).length;
        final outOfStock = allProducts.where((p) => p.stock <= 0).length;

        final allOrdersRaw = orderProv.orders;
        final allOrders = _filterOrders(allOrdersRaw);
        final totalOrders = allOrders.length;
        final pendingOrders = allOrders.where((o) => o.status == 'Chờ xử lý').length;
        final shippingOrders = allOrders.where((o) => o.status == 'Đang giao').length;
        final deliveredOrders = allOrders.where((o) => o.status == 'Đã giao').length;
        final totalRevenue = allOrders
            .where((o) => o.status == 'Đã giao')
            .fold<double>(0, (sum, o) => sum + o.total);
        final totalCategories = categoryProv.categories.length;

        // Tính số lượng đã bán cho mỗi productId từ đơn đã giao
        final soldMap = <String, int>{};
        for (final o in allOrdersRaw.where((o) => o.status == 'Đã giao')) {
          for (final item in o.items) {
            soldMap[item.productId] = (soldMap[item.productId] ?? 0) + item.quantity;
          }
        }

        final recentOrders = List.of(allOrders)
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        final displayOrders = recentOrders.take(5).toList();
        final isLoading = productProv.isLoading && allProducts.isEmpty;

        // ─── Greeting ───
        final now = DateTime.now();
        final greeting = now.hour < 12
            ? 'Chào buổi sáng'
            : now.hour < 18
                ? 'Chào buổi chiều'
                : 'Chào buổi tối';
        final dateStr =
            '${_weekday(now.weekday)}, ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

        if (isLoading) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ════════════════════════════════════
              // ROW 0: Greeting + Filter Chips
              // ════════════════════════════════════
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$greeting!',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.textDark)),
                        const SizedBox(height: 4),
                        Text('Tổng quan hoạt động cửa hàng · $dateStr',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.55) : AppTheme.textLight)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Filter Chips ──
              _buildFilterChips(isDark),
              const SizedBox(height: 20),

              // ════════════════════════════════════
              // ROW 1: 4 KPI Cards
              // ════════════════════════════════════
              Row(
                children: [
                  Expanded(child: _kpiCard(isDark, Icons.account_balance_wallet_rounded, 'Doanh thu', _fmtVND(totalRevenue), const Color(0xFF7C3AED), 'Từ $deliveredOrders đơn đã giao')),
                  const SizedBox(width: 14),
                  Expanded(child: _kpiCard(isDark, Icons.shopping_bag_rounded, 'Đơn hàng', '$totalOrders', const Color(0xFF3B82F6), '$pendingOrders chờ · $shippingOrders giao')),
                  const SizedBox(width: 14),
                  Expanded(child: _kpiCard(isDark, Icons.inventory_2_rounded, 'Sản phẩm', '$totalProducts', const Color(0xFF10B981), '$activeProducts active · $lowStock sắp hết')),
                  const SizedBox(width: 14),
                  Expanded(child: _kpiCard(isDark, Icons.category_rounded, 'Danh mục', '$totalCategories', const Color(0xFFF59E0B), '$outOfStock SP hết hàng')),
                ],
              ),
              const SizedBox(height: 20),

              // ════════════════════════════════════
              // ROW 2: Charts (Revenue Line + Order Donut)
              // ════════════════════════════════════
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final charts = [
                    _chartCard(isDark, 'Doanh thu 7 ngày qua', Icons.show_chart_rounded,
                        SizedBox(height: 240, child: _buildRevenueLineChart(isDark, allOrders))),
                    _chartCard(isDark, 'Trạng thái đơn hàng', Icons.pie_chart_rounded,
                        SizedBox(height: 240, child: _buildOrderStatusDonut(isDark, allOrders))),
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
                  return Column(children: [charts[0], const SizedBox(height: 14), charts[1]]);
                },
              ),
              const SizedBox(height: 14),

              // ════════════════════════════════════
              // ROW 3: Category Bar Chart (full width)
              // ════════════════════════════════════
              _chartCard(isDark, 'Sản phẩm theo danh mục', Icons.bar_chart_rounded,
                  SizedBox(height: 240, child: _buildCategoryBarChart(isDark, categoryProv.categories))),
              const SizedBox(height: 20),

              // ════════════════════════════════════
              // ROW 4: Top Products + Low Stock
              // ════════════════════════════════════
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  final topProd = _buildTopProducts(isDark, allProducts, soldMap);
                  final lowStk = _buildLowStock(isDark, allProducts);
                  if (isWide) {
                    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Expanded(child: topProd), const SizedBox(width: 14), Expanded(child: lowStk),
                    ]);
                  }
                  return Column(children: [topProd, const SizedBox(height: 14), lowStk]);
                },
              ),
              const SizedBox(height: 14),

              // ════════════════════════════════════
              // ROW 5: Recent Orders + Quick Actions
              // ════════════════════════════════════
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  final ordersWidget = _buildRecentOrders(isDark, displayOrders);
                  final actionsWidget = _buildQuickActions(isDark);

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: ordersWidget),
                        const SizedBox(width: 14),
                        Expanded(flex: 2, child: actionsWidget),
                      ],
                    );
                  }
                  return Column(children: [ordersWidget, const SizedBox(height: 14), actionsWidget]);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════
  Widget _buildFilterChips(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _periodOptions.map((period) {
          final isSelected = _selectedPeriod == period;
          String label = period;
          if (period == 'Tùy chỉnh' && _customRange != null && _selectedPeriod == 'Tùy chỉnh') {
            label = '${_customRange!.start.day.toString().padLeft(2, '0')}/${_customRange!.start.month.toString().padLeft(2, '0')} – ${_customRange!.end.day.toString().padLeft(2, '0')}/${_customRange!.end.month.toString().padLeft(2, '0')}';
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppTheme.textDark))),
              selected: isSelected,
              selectedColor: const Color(0xFF7C3AED),
              backgroundColor: isDark ? AppTheme.darkCardBg : const Color(0xFFF3F4F6),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    );
  }

  // ═══════════════════════════════════════
  // KPI CARD
  // ═══════════════════════════════════════
  Widget _kpiCard(bool isDark, IconData icon, String title, String value, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7280))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF111827)),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subtitle,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF9CA3AF)),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // CHART CARD WRAPPER
  // ═══════════════════════════════════════
  Widget _chartCard(bool isDark, String title, IconData icon, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // REVENUE LINE CHART
  // ═══════════════════════════════════════
  Widget _buildRevenueLineChart(bool isDark, List<dynamic> allOrders) {
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final dayLabels = <String>[];

    for (var i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final dayRevenue = allOrders
          .where((o) => o.status == 'Đã giao' && o.createdAt.year == day.year && o.createdAt.month == day.month && o.createdAt.day == day.day)
          .fold<double>(0, (sum, o) => sum + o.total);
      spots.add(FlSpot((6 - i).toDouble(), dayRevenue / 1000));
      dayLabels.add('${day.day}/${day.month}');
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final ceilY = maxY < 10 ? 10.0 : (maxY * 1.3);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true, drawVerticalLine: false, horizontalInterval: ceilY / 4,
          getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEEEEEE), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 46, interval: ceilY / 4,
            getTitlesWidget: (v, m) => Text('${v.toInt()}K', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : AppTheme.textLight)),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 28, interval: 1,
            getTitlesWidget: (v, m) {
              final idx = v.toInt();
              if (idx < 0 || idx >= dayLabels.length) return const SizedBox();
              return Padding(padding: const EdgeInsets.only(top: 6), child: Text(dayLabels[idx], style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : AppTheme.textLight)));
            },
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 6, minY: 0, maxY: ceilY,
        lineBarsData: [
          LineChartBarData(
            spots: spots, isCurved: true, preventCurveOverShooting: true,
            color: const Color(0xFF7C3AED), barWidth: 3,
            dotData: FlDotData(show: true, getDotPainter: (s, p, b, i) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2.5, strokeColor: const Color(0xFF7C3AED))),
            belowBarData: BarAreaData(show: true, gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [const Color(0xFF7C3AED).withValues(alpha: 0.25), const Color(0xFF7C3AED).withValues(alpha: 0.0)],
            )),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(_fmtVND(s.y * 1000), const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12))).toList(),
          ),
        ),
      ),
      duration: Duration.zero,
    );
  }

  // ═══════════════════════════════════════
  // ORDER STATUS DONUT
  // ═══════════════════════════════════════
  Widget _buildOrderStatusDonut(bool isDark, List<dynamic> allOrders) {
    final statusMap = <String, int>{};
    for (final o in allOrders) {
      statusMap[o.status] = (statusMap[o.status] ?? 0) + 1;
    }

    if (statusMap.isEmpty) {
      return Center(child: Text('Chưa có đơn hàng', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.textLight)));
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
      return PieChartSectionData(value: e.value.toDouble(), color: color, radius: 32,
          title: '${e.value}', titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white));
    }).toList();

    return Row(
      children: [
        Expanded(child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2), duration: Duration.zero)),
        const SizedBox(width: 16),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: statusMap.entries.map((e) {
            final color = colors[e.key] ?? const Color(0xFF6B7280);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
                  const SizedBox(width: 8),
                  Text('${e.key} (${e.value})', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppTheme.textDark)),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // CATEGORY BAR CHART
  // ═══════════════════════════════════════
  Widget _buildCategoryBarChart(bool isDark, List<dynamic> categories) {
    if (categories.isEmpty) {
      return Center(child: Text('Chưa có danh mục', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.textLight)));
    }

    final barColors = [
      const Color(0xFF7C3AED), const Color(0xFF3B82F6), const Color(0xFF10B981),
      const Color(0xFFF59E0B), const Color(0xFFEC4899), const Color(0xFF06B6D4),
      const Color(0xFFEF4444), const Color(0xFF8B5CF6),
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
              return BarTooltipItem('${cat.name}\n${cat.productCount} sản phẩm',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12));
            },
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 38,
            getTitlesWidget: (v, m) {
              final idx = v.toInt();
              if (idx < 0 || idx >= categories.length) return const SizedBox();
              final name = categories[idx].name as String;
              return Padding(padding: const EdgeInsets.only(top: 6),
                  child: Text(name.length > 8 ? '${name.substring(0, 7)}…' : name,
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : AppTheme.textLight), textAlign: TextAlign.center));
            },
          )),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true, reservedSize: 30, interval: (maxCount / 4).ceilToDouble().clamp(1, double.infinity),
            getTitlesWidget: (v, m) => Text('${v.toInt()}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : AppTheme.textLight)),
          )),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          horizontalInterval: (maxCount / 4).ceilToDouble().clamp(1, double.infinity),
          getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFEEEEEE), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(categories.length, (i) {
          final c = categories[i];
          return BarChartGroupData(x: i, barRods: [
            BarChartRodData(toY: c.productCount.toDouble(), color: barColors[i % barColors.length], width: 22,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6))),
          ]);
        }),
      ),
      duration: Duration.zero,
    );
  }

  // ═══════════════════════════════════════
  // RECENT ORDERS TABLE
  // ═══════════════════════════════════════
  Widget _buildRecentOrders(bool isDark, List<dynamic> displayOrders) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 8),
                    Text('Đơn hàng gần đây', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF374151))),
                  ],
                ),
                TextButton(
                  onPressed: () => widget.onNavigateTab?.call(6),
                  child: const Text('Xem tất cả →', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600, fontSize: 12)),
                ),
              ],
            ),
          ),
          // Table
          if (displayOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text('Chưa có đơn hàng nào', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.textLight))),
            )
          else
            ClipRRect(
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
                      columnSpacing: 20,
                      columns: const [
                        DataColumn(label: Text('Mã đơn')),
                        DataColumn(label: Text('Khách hàng')),
                        DataColumn(label: Text('Tổng tiền')),
                        DataColumn(label: Text('Trạng thái')),
                        DataColumn(label: Text('Ngày tạo')),
                      ],
                      rows: displayOrders.map((order) {
                        return DataRow(cells: [
                          DataCell(Text(order.code, style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textDark))),
                          DataCell(Text(order.customerName, style: TextStyle(color: isDark ? Colors.white70 : AppTheme.textDark))),
                          DataCell(Text(_fmtVND(order.total), style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textDark))),
                          DataCell(_buildStatusChip(order.status)),
                          DataCell(Text(
                            '${order.createdAt.day.toString().padLeft(2, '0')}/${order.createdAt.month.toString().padLeft(2, '0')}/${order.createdAt.year}',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : AppTheme.textLight),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // TOP PRODUCTS (bán chạy)
  // ═══════════════════════════════════════
  Widget _buildTopProducts(bool isDark, List<dynamic> products, Map<String, int> soldMap) {
    final sorted = List.of(products)..sort((a, b) => (soldMap[b.id] ?? 0).compareTo(soldMap[a.id] ?? 0));
    final top = sorted.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Row(children: [
          const Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFEC4899)),
          const SizedBox(width: 8),
          Text('Sản phẩm bán chạy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF374151))),
        ])),
        if (top.isEmpty)
          Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.textLight))))
        else
          ...top.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            final sold = soldMap[p.id] ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6)))),
              child: Row(children: [
                Container(width: 24, height: 24,
                  decoration: BoxDecoration(color: i < 3 ? const Color(0xFFF59E0B).withValues(alpha: 0.12) : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6)), borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text('#${i + 1}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: i < 3 ? const Color(0xFFF59E0B) : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)))))),
                const SizedBox(width: 10),
                Expanded(child: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.8) : AppTheme.textDark))),
                const SizedBox(width: 8),
                Text(_fmtVND(p.price), style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                const SizedBox(width: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text('Đã bán: $sold', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF10B981)))),
              ]),
            );
          }),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // LOW STOCK (tồn kho thấp)
  // ═══════════════════════════════════════
  Widget _buildLowStock(bool isDark, List<dynamic> products) {
    final low = products.where((p) => p.isActive && p.stock <= 10).toList()
      ..sort((a, b) => a.stock.compareTo(b.stock));
    final display = low.take(5).toList();
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12), child: Row(children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          Text('Tồn kho thấp (≤ 10)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF374151))),
        ])),
        if (display.isEmpty)
          Padding(padding: const EdgeInsets.all(32), child: Center(child: Text('Không có SP tồn kho thấp', style: TextStyle(color: isDark ? Colors.white54 : AppTheme.textLight))))
        else
          ...display.map((p) {
            final sc = p.stock == 0 ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
            final sl = p.stock == 0 ? 'Hết hàng' : 'Sắp hết';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6)))),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.8) : AppTheme.textDark)),
                  Text(p.sku, style: TextStyle(fontSize: 10, color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF9CA3AF))),
                ])),
                const SizedBox(width: 8),
                Text('${p.stock}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sc)),
                const SizedBox(width: 8),
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(sl, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sc))),
              ]),
            );
          }),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      _QuickAction(Icons.add_shopping_cart_rounded, 'Thêm sản phẩm', const Color(0xFF7C3AED), 3),
      _QuickAction(Icons.receipt_long_rounded, 'Quản lý đơn hàng', const Color(0xFF3B82F6), 6),
      _QuickAction(Icons.people_rounded, 'Khách hàng', const Color(0xFF10B981), 10),
      _QuickAction(Icons.warehouse_rounded, 'Quản lý kho', const Color(0xFF06B6D4), 4),
      _QuickAction(Icons.local_offer_rounded, 'Khuyến mãi', const Color(0xFFEC4899), 11),
      _QuickAction(Icons.settings_rounded, 'Cài đặt', const Color(0xFFF59E0B), 15),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, size: 18, color: Color(0xFF7C3AED)),
              const SizedBox(width: 8),
              Text('Thao tác nhanh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF374151))),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: actions.map((a) => _buildQuickActionItem(isDark, a)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem(bool isDark, _QuickAction action) {
    return InkWell(
      onTap: () => widget.onNavigateTab?.call(action.tabIndex),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(color: action.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(action.label, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textDark)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STATUS CHIP
  // ═══════════════════════════════════════
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Chờ xử lý': color = const Color(0xFFF59E0B); break;
      case 'Đã xác nhận': color = const Color(0xFF3B82F6); break;
      case 'Đang giao': color = const Color(0xFF06B6D4); break;
      case 'Đã giao': color = const Color(0xFF10B981); break;
      case 'Đã hủy': color = const Color(0xFFEF4444); break;
      default: color = const Color(0xFF6B7280);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
    );
  }

  // ═══════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════
  String _weekday(int w) {
    const days = ['', 'Thứ Hai', 'Thứ Ba', 'Thứ Tư', 'Thứ Năm', 'Thứ Sáu', 'Thứ Bảy', 'Chủ Nhật'];
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

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final int tabIndex;
  const _QuickAction(this.icon, this.label, this.color, this.tabIndex);
}
