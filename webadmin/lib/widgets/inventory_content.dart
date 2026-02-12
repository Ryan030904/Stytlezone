import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_snackbar.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';

/// Trang Tồn kho – hiển thị dữ liệu thực từ Firestore,
/// tính toán thống kê real-time, hỗ trợ lọc/tìm kiếm và cập nhật tồn kho.
class InventoryContent extends StatefulWidget {
  const InventoryContent({super.key});

  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent> {
  String _searchQuery = '';
  String _filterStatus = 'Tất cả';
  String _filterCategory = 'Tất cả';
  final _searchController = TextEditingController();

  // Ngưỡng cảnh báo
  static const int _lowStockThreshold = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── Status helpers ───
  String _stockStatus(int stock) {
    if (stock == 0) return 'Hết hàng';
    if (stock <= _lowStockThreshold) return 'Sắp hết';
    return 'Còn hàng';
  }

  Color _stockColor(int stock) {
    if (stock == 0) return const Color(0xFFEF4444);
    if (stock <= _lowStockThreshold) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  IconData _stockIcon(int stock) {
    if (stock == 0) return Icons.error_rounded;
    if (stock <= _lowStockThreshold) return Icons.warning_rounded;
    return Icons.check_circle_rounded;
  }

  List<Product> _filteredProducts(List<Product> products) {
    return products.where((p) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        if (!p.name.toLowerCase().contains(q) &&
            !p.sku.toLowerCase().contains(q) &&
            !p.brand.toLowerCase().contains(q)) {
          return false;
        }
      }
      if (_filterStatus != 'Tất cả' && _stockStatus(p.stock) != _filterStatus) {
        return false;
      }
      if (_filterCategory != 'Tất cả' && p.categoryName != _filterCategory) {
        return false;
      }
      return true;
    }).toList();
  }

  String _formatValue(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  String _formatVND(double v) => _formatValue(v);

  // ─── BUILD ───
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(60),
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            ),
          );
        }

        final allProducts = productProvider.products;
        final filtered = _filteredProducts(allProducts);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDarkMode),
              const SizedBox(height: 24),
              _buildStatsRow(allProducts, isDarkMode),
              const SizedBox(height: 24),
              _buildToolbar(allProducts, isDarkMode),
              const SizedBox(height: 16),
              _buildInventoryTable(filtered, isDarkMode),
            ],
          ),
        );
      },
    );
  }

  // ─── HEADER ───
  Widget _buildHeader(bool isDarkMode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý tồn kho',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Theo dõi số lượng tồn kho và cập nhật sản phẩm',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── STAT CARDS ───
  Widget _buildStatsRow(List<Product> products, bool isDarkMode) {
    final totalSku = products.length;
    final lowStock = products
        .where((p) => p.stock > 0 && p.stock <= _lowStockThreshold)
        .length;
    final outOfStock = products.where((p) => p.stock == 0).length;
    final totalValue = products.fold<double>(
      0,
      (sum, p) => sum + (p.price * p.stock),
    );

    final stats = [
      _StatItem(
        'Tổng sản phẩm',
        '$totalSku',
        Icons.inventory_2_rounded,
        const Color(0xFF7C3AED),
      ),
      _StatItem(
        'Sắp hết hàng',
        '$lowStock',
        Icons.warning_rounded,
        const Color(0xFFF59E0B),
      ),
      _StatItem(
        'Hết hàng',
        '$outOfStock',
        Icons.error_rounded,
        const Color(0xFFEF4444),
      ),
      _StatItem(
        'Giá trị tồn kho',
        _formatValue(totalValue),
        Icons.account_balance_wallet_rounded,
        const Color(0xFF10B981),
      ),
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: stat == stats.last ? 0 : 16),
            child: _buildStatCard(stat, isDarkMode),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatCard(_StatItem stat, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
                Text(
                  stat.label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TOOLBAR ───
  Widget _buildToolbar(List<Product> products, bool isDarkMode) {
    final categories = Provider.of<CategoryProvider>(
      context,
      listen: false,
    ).categories.where((c) => c.isActive).map((c) => c.name).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.lightBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.1)
                    : AppTheme.borderColor,
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên, SKU hoặc thương hiệu...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.3)
                      : AppTheme.textLight.withValues(alpha: 0.6),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.4)
                      : AppTheme.textLight,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildDropdown(
          value: _filterStatus,
          items: ['Tất cả', 'Còn hàng', 'Sắp hết', 'Hết hàng'],
          onChanged: (v) => setState(() => _filterStatus = v!),
          icon: Icons.filter_list_rounded,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(width: 12),
        _buildDropdown(
          value: _filterCategory,
          items: ['Tất cả', ...categories],
          onChanged: (v) => setState(() => _filterCategory = v!),
          icon: Icons.category_rounded,
          isDarkMode: isDarkMode,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : AppTheme.lightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.5)
                : AppTheme.textLight,
          ),
          dropdownColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(
            fontSize: 13,
            color: isDarkMode ? Colors.white : AppTheme.textDark,
          ),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // TABLE — 6 cột: SP | Danh mục | Tồn kho | Trạng thái | Giá trị | Thao tác
  // ════════════════════════════════════════════════════════════
  Widget _buildInventoryTable(List<Product> products, bool isDarkMode) {
    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.borderColor,
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppTheme.textLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Không tìm thấy sản phẩm nào',
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.5)
                      : AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.06)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        children: [
          _buildTableHeader(isDarkMode),
          ...products.map((p) => _buildRow(p, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildTableHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : AppTheme.lightBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _colHeader('Sản phẩm', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _colHeader('Danh mục', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _colHeader('Tồn kho', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _colHeader('Trạng thái', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _colHeader('Giá trị kho', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _colHeader('Thao tác', isDarkMode)),
        ],
      ),
    );
  }

  Widget _colHeader(String text, bool isDarkMode) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.65),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildRow(Product product, bool isDarkMode) {
    final status = _stockStatus(product.stock);
    final statusColor = _stockColor(product.stock);
    final stockValue = product.price * product.stock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.04)
                : AppTheme.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // ── Col 1: Ảnh + Tên + SKU ──
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_rounded,
                            size: 18,
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.15),
                          ),
                        )
                      : Icon(
                          Icons.image_rounded,
                          size: 18,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.15),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        product.sku,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.4)
                              : AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // ── Col 2: Danh mục ──
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ── Col 3: Tồn kho ──
          Expanded(
            flex: 1,
            child: Text(
              '${product.stock}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _stockColor(product.stock),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ── Col 4: Trạng thái (auto) ──
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _stockIcon(product.stock),
                      size: 12,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ── Col 5: Giá trị kho ──
          Expanded(
            flex: 1,
            child: Text(
              _formatValue(stockValue),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ── Col 6: Thao tác ──
          Expanded(
            flex: 1,
            child: Center(
              child: SizedBox(
                height: 30,
                child: OutlinedButton.icon(
                  onPressed: () => _showAdjustStockDialog(product),
                  icon: const Icon(Icons.edit_rounded, size: 13),
                  label: const Text('Sửa', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7C3AED),
                    side: BorderSide(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════
  // POPUP CẬP NHẬT TỒN KHO
  // ════════════════════════════════════════════════════════════
  void _showAdjustStockDialog(Product product) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final stockCtrl = TextEditingController(text: '${product.stock}');
    String selectedReason = 'Kiểm kho';
    String note = '';

    final reasons = [
      'Kiểm kho',
      'Nhập hàng',
      'Hàng lỗi/hỏng',
      'Hoàn hàng',
      'Khác',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final currentStock = int.tryParse(stockCtrl.text) ?? 0;
          final stockDiff = currentStock - product.stock;
          final stockValue = product.price * currentStock;

          // Status logic
          Color statusColor;
          String statusLabel;
          IconData statusIcon;
          if (currentStock == 0) {
            statusColor = const Color(0xFFEF4444);
            statusLabel = 'Hết hàng';
            statusIcon = Icons.error_rounded;
          } else if (currentStock <= _lowStockThreshold) {
            statusColor = const Color(0xFFF59E0B);
            statusLabel = 'Sắp hết hàng';
            statusIcon = Icons.warning_rounded;
          } else {
            statusColor = const Color(0xFF10B981);
            statusLabel = 'Còn hàng';
            statusIcon = Icons.check_circle_rounded;
          }

          final bgColor = isDarkMode ? const Color(0xFF1E293B) : Colors.white;
          final cardColor = isDarkMode
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF9FAFB);
          final borderClr = isDarkMode
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB);
          final textPrimary = isDarkMode
              ? Colors.white
              : const Color(0xFF111827);
          final textSecondary = isDarkMode
              ? Colors.white.withValues(alpha: 0.5)
              : const Color(0xFF6B7280);

          return Dialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ═══ HEADER: Product info ═══
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.02)
                          : const Color(0xFFF8F7FF),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.white,
                            border: Border.all(color: borderClr),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child:
                              product.imageUrl != null &&
                                  product.imageUrl!.isNotEmpty
                              ? Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(
                                    Icons.image_rounded,
                                    size: 22,
                                    color: textSecondary,
                                  ),
                                )
                              : Icon(
                                  Icons.image_rounded,
                                  size: 22,
                                  color: textSecondary,
                                ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${product.sku} · ${product.brand} · ${product.categoryName}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: textSecondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                          style: IconButton.styleFrom(
                            backgroundColor: isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.04),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ═══ BODY ═══
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── HERO: Stock numbers ──
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderClr),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Current
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            'Hiện tại',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: textSecondary,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${product.stock}',
                                            style: TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w700,
                                              color: textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Arrow + diff
                                    Column(
                                      children: [
                                        const SizedBox(height: 16),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 20,
                                          color: textSecondary,
                                        ),
                                        const SizedBox(height: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: stockDiff == 0
                                                ? Colors.transparent
                                                : stockDiff > 0
                                                ? const Color(
                                                    0xFF10B981,
                                                  ).withValues(alpha: 0.1)
                                                : const Color(
                                                    0xFFEF4444,
                                                  ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            stockDiff == 0
                                                ? '—'
                                                : '${stockDiff > 0 ? '+' : ''}$stockDiff',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: stockDiff == 0
                                                  ? textSecondary
                                                  : stockDiff > 0
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFEF4444),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    // New stock
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Text(
                                            'Mới',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: const Color(0xFF7C3AED),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          SizedBox(
                                            width: 120,
                                            child: TextField(
                                              controller: stockCtrl,
                                              keyboardType:
                                                  TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly,
                                              ],
                                              onChanged: (_) =>
                                                  setDialogState(() {}),
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w700,
                                                color: textPrimary,
                                              ),
                                              decoration: InputDecoration(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 8,
                                                    ),
                                                filled: true,
                                                fillColor: isDarkMode
                                                    ? Colors.white.withValues(
                                                        alpha: 0.06,
                                                      )
                                                    : Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  borderSide: BorderSide(
                                                    color: const Color(
                                                      0xFF7C3AED,
                                                    ).withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide: BorderSide(
                                                        color:
                                                            const Color(
                                                              0xFF7C3AED,
                                                            ).withValues(
                                                              alpha: 0.3,
                                                            ),
                                                      ),
                                                    ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      borderSide:
                                                          const BorderSide(
                                                            color: Color(
                                                              0xFF7C3AED,
                                                            ),
                                                            width: 2,
                                                          ),
                                                    ),
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Quick adjust
                                Row(
                                  children: [
                                    _chip(
                                      '-50',
                                      stockCtrl,
                                      -50,
                                      isDarkMode,
                                      setDialogState,
                                    ),
                                    const SizedBox(width: 6),
                                    _chip(
                                      '-10',
                                      stockCtrl,
                                      -10,
                                      isDarkMode,
                                      setDialogState,
                                    ),
                                    const SizedBox(width: 6),
                                    _chip(
                                      '-1',
                                      stockCtrl,
                                      -1,
                                      isDarkMode,
                                      setDialogState,
                                    ),
                                    const SizedBox(width: 10),
                                    _zeroChip(
                                      stockCtrl,
                                      isDarkMode,
                                      setDialogState,
                                    ),
                                    const SizedBox(width: 10),
                                    _chip(
                                      '+1',
                                      stockCtrl,
                                      1,
                                      isDarkMode,
                                      setDialogState,
                                    ),
                                    const SizedBox(width: 6),
                                    _chip(
                                      '+10',
                                      stockCtrl,
                                      10,
                                      isDarkMode,
                                      setDialogState,
                                    ),
                                    const SizedBox(width: 6),
                                    _chip(
                                      '+50',
                                      stockCtrl,
                                      50,
                                      isDarkMode,
                                      setDialogState,
                                    ),
                                    const SizedBox(width: 6),
                                    _chip(
                                      '+100',
                                      stockCtrl,
                                      100,
                                      isDarkMode,
                                      setDialogState,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Status + Value row ──
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.06),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        statusIcon,
                                        size: 18,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        statusLabel,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: borderClr),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.payments_rounded,
                                        size: 18,
                                        color: textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _formatVND(stockValue),
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Lý do điều chỉnh (dropdown) ──
                          Text(
                            'Lý do điều chỉnh',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderClr),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedReason,
                                isExpanded: true,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                  color: textSecondary,
                                ),
                                dropdownColor: isDarkMode
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textPrimary,
                                ),
                                items: reasons.map((r) {
                                  IconData icon;
                                  switch (r) {
                                    case 'Kiểm kho':
                                      icon = Icons.fact_check_rounded;
                                      break;
                                    case 'Nhập hàng':
                                      icon = Icons.add_shopping_cart_rounded;
                                      break;
                                    case 'Hàng lỗi/hỏng':
                                      icon = Icons.broken_image_rounded;
                                      break;
                                    case 'Hoàn hàng':
                                      icon = Icons.assignment_return_rounded;
                                      break;
                                    default:
                                      icon = Icons.more_horiz_rounded;
                                  }
                                  return DropdownMenuItem(
                                    value: r,
                                    child: Row(
                                      children: [
                                        Icon(
                                          icon,
                                          size: 18,
                                          color: const Color(0xFF7C3AED),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(r),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() => selectedReason = v);
                                  }
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Ghi chú (optional) ──
                          Text(
                            'Ghi chú',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            maxLines: 2,
                            onChanged: (v) => note = v,
                            style: TextStyle(fontSize: 13, color: textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Ghi chú thêm (không bắt buộc)',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: textSecondary.withValues(
                                  alpha: isDarkMode ? 0.5 : 0.6,
                                ),
                              ),
                              filled: true,
                              fillColor: cardColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderClr),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderClr),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF7C3AED),
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.all(14),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ── Info nhỏ ──
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.02)
                                  : const Color(0xFFFAFAFA),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.04)
                                    : const Color(0xFFF0F0F0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.update_rounded,
                                  size: 14,
                                  color: textSecondary,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Cập nhật lần cuối: ${product.updatedAt.day}/${product.updatedAt.month}/${product.updatedAt.year}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ═══ FOOTER ═══
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textSecondary,
                                side: BorderSide(color: borderClr),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Hủy'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Cập nhật tồn kho'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () async {
                                final newStock =
                                    int.tryParse(stockCtrl.text) ??
                                    product.stock;
                                final updated = product.copyWith(
                                  stock: newStock,
                                  isActive: product.isActive,
                                  updatedAt: DateTime.now(),
                                );
                                if (Navigator.of(dialogContext).canPop()) {
                                  Navigator.of(dialogContext).pop();
                                }
                                final provider = Provider.of<ProductProvider>(
                                  context,
                                  listen: false,
                                );
                                final success = await provider.updateProduct(
                                  updated,
                                );
                                if (!mounted) return;
                                if (success) {
                                  final diff = newStock - product.stock;
                                  AppSnackBar.success(
                                    context,
                                    '${product.name}: ${product.stock} → $newStock (${diff >= 0 ? '+$diff' : '$diff'}) — $selectedReason',
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Chip button ───
  Widget _chip(
    String label,
    TextEditingController controller,
    int delta,
    bool isDarkMode,
    StateSetter setDialogState,
  ) {
    final isNeg = delta < 0;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          final current = int.tryParse(controller.text) ?? 0;
          final next = (current + delta).clamp(0, 99999); // clamp ≥ 0
          controller.text = '$next';
          setDialogState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isNeg
                ? const Color(0xFFEF4444).withValues(alpha: 0.06)
                : const Color(0xFF10B981).withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isNeg
                  ? const Color(0xFFEF4444).withValues(alpha: 0.15)
                  : const Color(0xFF10B981).withValues(alpha: 0.15),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isNeg
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _zeroChip(
    TextEditingController controller,
    bool isDarkMode,
    StateSetter setDialogState,
  ) {
    return SizedBox(
      width: 32,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          controller.text = '0';
          setDialogState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.1),
            ),
          ),
          child: Center(
            child: Text(
              '0',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final String label, value;
  final IconData icon;
  final Color color;
  _StatItem(this.label, this.value, this.icon, this.color);
}
