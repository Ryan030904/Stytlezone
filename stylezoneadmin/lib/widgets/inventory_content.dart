import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../models/product_model.dart';
import '../models/category_model.dart';
import '../models/warehouse_receipt_model.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/brand_provider.dart';
import '../providers/warehouse_receipt_provider.dart';
import '../constants/admin_enums.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_slide_panel.dart';

/// ──────────────────────────────────────────────
/// Quản lý kho — Inventory Management
/// ──────────────────────────────────────────────
class InventoryContent extends StatefulWidget {
  const InventoryContent({super.key});

  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent>
    with SingleTickerProviderStateMixin {
  // Panel
  bool _panelOpen = false;
  bool _isStockIn = true; // true = nhập kho, false = xuất kho

  // Search & filter for main table
  String _searchQuery = '';
  String _filterParent = '';
  String _filterChild = '';
  String _filterGender = '';
  final Set<String> _expandedIds = {};

  // Panel form state
  Product? _selectedProduct;
  final _totalQtyCtrl = TextEditingController();
  final Map<String, TextEditingController> _variantQtyCtrls = {};
  String _panelFilterParent = '';
  String _panelFilterChild = '';
  String _panelFilterGender = '';
  String _panelFilterBrand = '';
  String _panelSearch = '';
  String? _validationError;

  // History tab date filter
  DateTimeRange? _historyDateRange;

  void _closePanelOnTabSwitch() {
    if (_panelOpen) setState(() => _panelOpen = false);
  }

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    DashboardScreen.panelCloseNotifier.addListener(_closePanelOnTabSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prodProv = context.read<ProductProvider>();
      final catProv = context.read<CategoryProvider>();
      final whProv = context.read<WarehouseReceiptProvider>();
      if (prodProv.products.isEmpty) prodProv.loadProducts();
      if (catProv.categories.isEmpty) catProv.loadCategories();
      whProv.loadReceipts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    DashboardScreen.panelCloseNotifier.removeListener(_closePanelOnTabSwitch);
    _totalQtyCtrl.dispose();
    _variantQtyCtrls.forEach((_, c) => c.dispose());
    super.dispose();
  }

  // ─── Filter products ───
  List<Product> _applyFilters(List<Product> all, {bool forPanel = false}) {
    var result = all;
    final query = forPanel ? _panelSearch : _searchQuery;
    final parent = forPanel ? _panelFilterParent : _filterParent;
    final child = forPanel ? _panelFilterChild : _filterChild;
    final gender = forPanel ? _panelFilterGender : _filterGender;
    final brand = forPanel ? _panelFilterBrand : '';

    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q)).toList();
    }
    if (child.isNotEmpty) {
      result = result.where((p) => p.categoryId == child).toList();
    } else if (parent.isNotEmpty) {
      final cats = context.read<CategoryProvider>().categories;
      final childIds = cats.where((c) => c.parentId == parent).map((c) => c.id).toSet();
      result = result.where((p) => childIds.contains(p.categoryId)).toList();
    }
    if (gender.isNotEmpty) {
      result = result.where((p) => p.gender == gender).toList();
    }
    if (brand.isNotEmpty) {
      result = result.where((p) => p.brandId == brand).toList();
    }
    return result;
  }

  List<Category> _parentCats(List<Category> all) =>
      all.where((c) => c.parentId == null || c.parentId!.isEmpty).toList();
  List<Category> _childCats(List<Category> all, String parentId) =>
      all.where((c) => c.parentId == parentId).toList();

  // ─── Open panel ───
  void _openPanel(bool stockIn) {
    _isStockIn = stockIn;
    _selectedProduct = null;
    _totalQtyCtrl.clear();
    _variantQtyCtrls.forEach((_, c) => c.dispose());
    _variantQtyCtrls.clear();
    _panelFilterParent = '';
    _panelFilterChild = '';
    _panelFilterGender = '';
    _panelFilterBrand = '';
    _panelSearch = '';
    _validationError = null;
    setState(() => _panelOpen = true);
  }

  void _closePanel() => setState(() => _panelOpen = false);

  // ─── Select product in panel ───
  void _selectProduct(Product p) {
    _variantQtyCtrls.forEach((_, c) => c.dispose());
    _variantQtyCtrls.clear();
    _totalQtyCtrl.clear();
    _validationError = null;

    // Create variant qty controllers
    if (p.sizes.isNotEmpty && p.colors.isNotEmpty) {
      for (final size in p.sizes) {
        for (final color in p.colors) {
          _variantQtyCtrls['$size|$color'] = TextEditingController(text: '0');
        }
      }
    }
    setState(() => _selectedProduct = p);
  }

  // ─── Validate & submit ───
  int get _totalQty => int.tryParse(_totalQtyCtrl.text) ?? 0;
  int get _variantSum {
    int sum = 0;
    _variantQtyCtrls.forEach((_, c) => sum += int.tryParse(c.text) ?? 0);
    return sum;
  }

  Future<void> _submit() async {
    if (_selectedProduct == null || _totalQty <= 0) return;

    final hasVariants = _variantQtyCtrls.isNotEmpty;
    if (hasVariants) {
      final sum = _variantSum;
      if (sum != _totalQty) {
        setState(() => _validationError =
            'Tổng phân bổ ($sum) ≠ tổng ${_isStockIn ? "nhập" : "xuất"} ($_totalQty). Cần bằng nhau!');
        return;
      }
    }

    // Check xuất kho: không được xuất quá tồn (tổng)
    if (!_isStockIn && _totalQty > _selectedProduct!.stock) {
      setState(() => _validationError =
          'Không thể xuất $_totalQty, tồn kho chỉ còn ${_selectedProduct!.stock}');
      return;
    }

    // Check xuất kho per-variant: mỗi variant không được xuất quá tồn
    if (!_isStockIn && hasVariants) {
      for (final entry in _variantQtyCtrls.entries) {
        final parts = entry.key.split('|');
        final size = parts[0];
        final color = parts[1];
        final qty = int.tryParse(entry.value.text) ?? 0;
        if (qty <= 0) continue;
        final variant = _selectedProduct!.variants
            .where((v) => v.size == size && v.color == color).firstOrNull;
        final currentStock = variant?.stock ?? 0;
        if (qty > currentStock) {
          setState(() => _validationError =
              'Size $size - Màu $color: không thể xuất $qty, tồn chỉ $currentStock');
          return;
        }
      }
    }

    final now = DateTime.now();
    final receipt = WarehouseReceiptModel(
      code: '${_isStockIn ? "NK" : "XK"}-${now.millisecondsSinceEpoch}',
      type: _isStockIn ? ReceiptType.stockIn : ReceiptType.stockOut,
      status: ReceiptStatus.completed,
      warehouse: 'Kho chính',
      items: [ReceiptItem(
        productId: _selectedProduct!.id,
        productName: _selectedProduct!.name,
        sku: _selectedProduct!.sku,
        quantity: _totalQty,
      )],
      stockEffected: true,
      createdAt: now,
      updatedAt: now,
    );

    // Create receipt
    final whProv = context.read<WarehouseReceiptProvider>();
    await whProv.createReceipt(receipt);

    // Update product: total stock + variant stocks
    final prodProv = context.read<ProductProvider>();
    final newStock = _isStockIn
        ? _selectedProduct!.stock + _totalQty
        : _selectedProduct!.stock - _totalQty;

    // Update each variant stock
    List<ProductVariant> updatedVariants = _selectedProduct!.variants;
    if (hasVariants) {
      updatedVariants = _selectedProduct!.variants.map((v) {
        final key = '${v.size}|${v.color}';
        final ctrl = _variantQtyCtrls[key];
        if (ctrl == null) return v;
        final qty = int.tryParse(ctrl.text) ?? 0;
        if (qty == 0) return v;
        final newVStock = _isStockIn ? v.stock + qty : v.stock - qty;
        return v.copyWith(stock: newVStock < 0 ? 0 : newVStock);
      }).toList();
    }

    final updated = _selectedProduct!.copyWith(
      stock: newStock < 0 ? 0 : newStock,
      variants: updatedVariants,
      updatedAt: now,
    );
    await prodProv.updateProduct(updated);

    if (mounted) _closePanel();
  }

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Consumer2<ProductProvider, CategoryProvider>(
      builder: (context, prodProv, catProv, _) {
        final allCats = catProv.categories;
        final allProducts = prodProv.products;
        final filtered = _applyFilters(allProducts);

        return AdminSlidePanel(
          isOpen: _panelOpen,
          title: _isStockIn ? 'Nhập kho' : 'Xuất kho',
          onClose: _closePanel,
          panelBody: _buildPanelContent(isDark, allProducts, allCats),
          child: Column(children: [
            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkCardBg : Colors.white,
                border: Border(bottom: BorderSide(color: border)),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF7C3AED),
                unselectedLabelColor: isDark ? Colors.white54 : const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF7C3AED),
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                tabs: const [
                  Tab(icon: Icon(Icons.inventory_2_rounded, size: 18), text: 'Thông tin kho'),
                  Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'Lịch sử kho'),
                ],
              ),
            ),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Stock info
                  Column(children: [
                    _buildHeader(isDark, allProducts, allCats),
                    Expanded(
                      child: prodProv.isLoading && allProducts.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                          : filtered.isEmpty
                              ? _buildEmpty(isDark)
                              : _buildTable(isDark, filtered),
                    ),
                  ]),
                  // Tab 2: Receipt history
                  _buildHistoryTab(isDark),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // TAB 2: HISTORY
  // ═══════════════════════════════════════════════
  Widget _buildHistoryTab(bool isDark) {
    return Consumer<WarehouseReceiptProvider>(
      builder: (context, whProv, _) {
        if (whProv.isLoading && whProv.receipts.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
        }
        final receipts = whProv.receipts;
        if (receipts.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.history_rounded, size: 36, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(height: 16),
              Text('Chưa có lịch sử kho',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151))),
              const SizedBox(height: 6),
              Text('Thực hiện nhập/xuất kho để xem lịch sử',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
            ]),
          );
        }

        final bg = isDark ? AppTheme.darkCardBg : Colors.white;
        final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
        final headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : const Color(0xFF6B7280));
        final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
        final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

        return Container(
          margin: const EdgeInsets.all(20),
          child: Column(children: [
            // Date filter bar
            _buildDateFilterBar(isDark, border),
            const SizedBox(height: 12),
            // Table
            Expanded(child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: border),
              ),
              clipBehavior: Clip.antiAlias,
          child: Column(children: [
            // Header row
            Container(
              color: headerBg,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(children: [
                SizedBox(width: 36, child: Text('#', style: headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('Mã phiếu', style: headerStyle)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('Loại', style: headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('Kho', style: headerStyle)),
                const SizedBox(width: 8),
                Expanded(flex: 1, child: Text('Số lượng', style: headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('Trạng thái', style: headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('Ngày tạo', style: headerStyle, textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: Text('Người tạo', style: headerStyle)),
              ]),
            ),
            // Rows (filtered by date)
            Expanded(child: Builder(builder: (_) {
              final filtered = _historyDateRange == null
                  ? receipts
                  : receipts.where((r) {
                      final d = r.createdAt;
                      return !d.isBefore(_historyDateRange!.start) &&
                             d.isBefore(_historyDateRange!.end.add(const Duration(days: 1)));
                    }).toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.search_off_rounded, size: 36, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF)),
                    const SizedBox(height: 8),
                    Text('Không tìm thấy phiếu kho trong khoảng ngày này',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                  ]),
                );
              }
              return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final r = filtered[i];
                final textColor = isDark ? Colors.white70 : const Color(0xFF374151);
                final textStyle = TextStyle(fontSize: 11, color: textColor);

                // Type badge
                Color typeColor;
                IconData typeIcon;
                switch (r.type) {
                  case ReceiptType.stockIn:
                    typeColor = const Color(0xFF10B981);
                    typeIcon = Icons.add_circle_rounded;
                    break;
                  case ReceiptType.stockOut:
                    typeColor = const Color(0xFFEF4444);
                    typeIcon = Icons.remove_circle_rounded;
                    break;
                  case ReceiptType.transfer:
                    typeColor = const Color(0xFF3B82F6);
                    typeIcon = Icons.swap_horiz_rounded;
                    break;
                  case ReceiptType.stockCheck:
                    typeColor = const Color(0xFFF59E0B);
                    typeIcon = Icons.fact_check_rounded;
                    break;
                }

                // Status badge
                Color statusColor;
                switch (r.status) {
                  case ReceiptStatus.draft:
                    statusColor = const Color(0xFF6B7280);
                    break;
                  case ReceiptStatus.processing:
                    statusColor = const Color(0xFF3B82F6);
                    break;
                  case ReceiptStatus.completed:
                    statusColor = const Color(0xFF10B981);
                    break;
                  case ReceiptStatus.cancelled:
                    statusColor = const Color(0xFFEF4444);
                    break;
                }

                return InkWell(
                  onTap: () => _showReceiptDetail(r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
                    child: Row(children: [
                      SizedBox(width: 36, child: Text('${i + 1}', style: textStyle, textAlign: TextAlign.center)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: Text(r.code, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: Center(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(typeIcon, size: 12, color: typeColor),
                          const SizedBox(width: 4),
                          Text(r.typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
                        ]),
                      ))),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: Text(r.warehouse, style: textStyle, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Expanded(flex: 1, child: Text('${r.totalQty}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827)), textAlign: TextAlign.center)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: Center(child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(r.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
                      ))),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: Text(dateFormat.format(r.createdAt), style: textStyle, textAlign: TextAlign.center)),
                      const SizedBox(width: 8),
                      Expanded(flex: 2, child: Text(r.createdBy, style: textStyle, overflow: TextOverflow.ellipsis)),
                    ]),
                  ),
                );
              },
            );
            })),
          ]),
        )),
        ]),
        );
      },
    );
  }

  void _showReceiptDetail(WarehouseReceiptModel receipt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    Color typeColor;
    switch (receipt.type) {
      case ReceiptType.stockIn: typeColor = const Color(0xFF10B981); break;
      case ReceiptType.stockOut: typeColor = const Color(0xFFEF4444); break;
      case ReceiptType.transfer: typeColor = const Color(0xFF3B82F6); break;
      case ReceiptType.stockCheck: typeColor = const Color(0xFFF59E0B); break;
    }
    Color statusColor;
    switch (receipt.status) {
      case ReceiptStatus.draft: statusColor = const Color(0xFF6B7280); break;
      case ReceiptStatus.processing: statusColor = const Color(0xFF3B82F6); break;
      case ReceiptStatus.completed: statusColor = const Color(0xFF10B981); break;
      case ReceiptStatus.cancelled: statusColor = const Color(0xFFEF4444); break;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 640,
          constraints: const BoxConstraints(maxHeight: 580),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: typeColor, width: 3)),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(receipt.code, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp, letterSpacing: 0.3)),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: typeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(receipt.typeLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: typeColor)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(receipt.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('${dateFormat.format(receipt.createdAt)}  \u2022  ${receipt.createdBy.isNotEmpty ? receipt.createdBy : "N/A"}',
                    style: TextStyle(fontSize: 12, color: ts)),
                ])),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: Icon(Icons.close_rounded, size: 20, color: ts),
                  style: IconButton.styleFrom(backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6)),
                ),
              ]),
            ),
            Divider(height: 1, color: bdr),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: headerBg,
              child: Row(children: [
                _receiptInfoItem('Kho', receipt.warehouse, ts, tp),
                Container(width: 1, height: 28, color: bdr),
                _receiptInfoItem('T\u1ed5ng SL', '${receipt.totalQty}', ts, tp),
                Container(width: 1, height: 28, color: bdr),
                _receiptInfoItem('S\u1ea3n ph\u1ea9m', '${receipt.items.length}', ts, tp),
              ]),
            ),
            if (receipt.note.isNotEmpty) ...[
              Divider(height: 1, color: bdr),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Text(receipt.note, style: TextStyle(fontSize: 12, color: ts, fontStyle: FontStyle.italic, height: 1.4)),
              ),
            ],
            Divider(height: 1, color: bdr),
            Container(
              color: headerBg,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Row(children: [
                SizedBox(width: 32, child: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ts, letterSpacing: 0.5), textAlign: TextAlign.center)),
                const SizedBox(width: 12),
                Expanded(flex: 5, child: Text('S\u1EA2N PH\u1EA8M', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ts, letterSpacing: 0.5))),\
                Expanded(flex: 2, child: Text('SKU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ts, letterSpacing: 0.5))),\
                SizedBox(width: 60, child: Text('SL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: ts, letterSpacing: 0.5), textAlign: TextAlign.right)),
              ]),
            ),
            Divider(height: 1, color: bdr),
            Expanded(
              child: ListView.separated(
                itemCount: receipt.items.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: bdr),
                itemBuilder: (_, i) {
                  final item = receipt.items[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    color: i % 2 == 0 ? Colors.transparent : headerBg,
                    child: Row(children: [
                      SizedBox(width: 32, child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: ts), textAlign: TextAlign.center)),
                      const SizedBox(width: 12),
                      Expanded(flex: 5, child: Text(item.productName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tp), overflow: TextOverflow.ellipsis)),
                      Expanded(flex: 2, child: Text(item.sku.isNotEmpty ? item.sku : '\u2014', style: TextStyle(fontSize: 11, color: const Color(0xFF7C3AED), fontWeight: FontWeight.w500))),\
                      SizedBox(width: 60, child: Text('${item.quantity}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: typeColor), textAlign: TextAlign.right)),
                    ]),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: headerBg,
                border: Border(top: BorderSide(color: bdr)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color.withValues(alpha: 0.7))),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ]),
    );
  }

  Widget _buildDateFilterBar(bool isDark, Color border) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final hasFilter = _historyDateRange != null;
    return Row(children: [
      InkWell(
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now().add(const Duration(days: 1)),
            initialDateRange: _historyDateRange,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: const Color(0xFF7C3AED),
                  ),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) setState(() => _historyDateRange = picked);
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: hasFilter
                ? const Color(0xFF7C3AED).withValues(alpha: 0.08)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasFilter
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                  : border,
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.calendar_month_rounded, size: 16,
              color: hasFilter ? const Color(0xFF7C3AED) : (isDark ? Colors.white54 : const Color(0xFF6B7280))),
            const SizedBox(width: 8),
            Text(
              hasFilter
                  ? '${dateFormat.format(_historyDateRange!.start)} — ${dateFormat.format(_historyDateRange!.end)}'
                  : 'Lọc theo ngày',
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasFilter ? FontWeight.w600 : FontWeight.w500,
                color: hasFilter ? const Color(0xFF7C3AED) : (isDark ? Colors.white60 : const Color(0xFF374151)),
              ),
            ),
          ]),
        ),
      ),
      if (hasFilter) ...[
        const SizedBox(width: 8),
        InkWell(
          onTap: () => setState(() => _historyDateRange = null),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFFEF4444)),
          ),
        ),
      ],
    ]);
  }

  // ═══════════════════════════════════════════════
  // HEADER BAR
  // ═══════════════════════════════════════════════
  Widget _buildHeader(bool isDark, List<Product> all, List<Category> allCats) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Left: Search + Filters (2 rows)
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: SizedBox(height: 36, child: TextField(
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Tìm sản phẩm...',
              hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA)),
              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ))),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              SizedBox(width: 180, child: _dropdown(
                isDark: isDark,
                value: _filterParent.isEmpty ? null : _filterParent,
                hint: 'Danh mục chính',
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tất cả', style: TextStyle(fontSize: 12))),
                  ..._parentCats(allCats).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 12)))),
                ],
                onChanged: (v) => setState(() { _filterParent = v ?? ''; _filterChild = ''; }),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 170, child: _dropdown(
                isDark: isDark,
                value: _filterChild.isEmpty ? null : _filterChild,
                hint: 'Danh mục con',
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tất cả', style: TextStyle(fontSize: 12))),
                  if (_filterParent.isNotEmpty)
                    ..._childCats(allCats, _filterParent).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 12)))),
                ],
                onChanged: (v) => setState(() => _filterChild = v ?? ''),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 140, child: _dropdown(
                isDark: isDark,
                value: _filterGender.isEmpty ? null : _filterGender,
                hint: 'Giới tính',
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'male', child: Text('Nam', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'female', child: Text('Nữ', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _filterGender = v ?? ''),
              )),
            ]),
          ),
        ])),
        // Right: Action buttons (vertically centered)
        const SizedBox(width: 16),
        _actionBtn('Nhập kho', Icons.add_circle_rounded, const Color(0xFF10B981), () => _openPanel(true)),
        const SizedBox(width: 8),
        _actionBtn('Xuất kho', Icons.remove_circle_rounded, const Color(0xFFEF4444), () => _openPanel(false)),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _dropdown({required bool isDark, String? value, required String hint, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        hint: Text(hint, style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
        items: items,
        onChanged: onChanged,
      )),
    );
  }

  // ═══════════════════════════════════════════════
  // PRODUCT TABLE
  // ═══════════════════════════════════════════════
  Widget _buildTable(bool isDark, List<Product> products) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : const Color(0xFF6B7280));
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Header row
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            SizedBox(width: 36, child: Text('#', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            SizedBox(width: 44, child: Text('Ảnh', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: Text('Sản phẩm', style: headerStyle)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('SKU', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Danh mục', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Size', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Màu', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: Text('Tồn kho', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: Text('Trạng thái', style: headerStyle, textAlign: TextAlign.center)),
          ]),
        ),
        // Rows
        Expanded(child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (_, i) => _buildRow(isDark, products[i], i + 1, border),
        )),
      ]),
    );
  }

  Widget _buildRow(bool isDark, Product p, int index, Color border) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF374151);
    final textStyle = TextStyle(fontSize: 11, color: textColor);

    // Stock status
    Widget stockBadge;
    if (p.stock == 0) {
      stockBadge = _statusChip('Hết hàng', const Color(0xFFEF4444));
    } else if (p.stock <= 10) {
      stockBadge = _statusChip('Sắp hết', const Color(0xFFF59E0B));
    } else {
      stockBadge = _statusChip('Còn hàng', const Color(0xFF10B981));
    }

    return Column(children: [
      InkWell(
        onTap: p.variants.isNotEmpty ? () => setState(() {
          _expandedIds.contains(p.id) ? _expandedIds.remove(p.id) : _expandedIds.add(p.id);
        }) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
          child: Row(children: [
            SizedBox(width: 36, child: Text('$index', style: textStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            SizedBox(width: 44, child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6),
              ),
              clipBehavior: Clip.antiAlias,
              child: p.images.isNotEmpty
                  ? Image.network(p.images.first, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_rounded, size: 14, color: isDark ? Colors.white24 : const Color(0xFFBBBBBB)))
                  : Icon(Icons.image_rounded, size: 14, color: isDark ? Colors.white24 : const Color(0xFFBBBBBB)),
            )),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: Row(children: [
              Flexible(child: Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
              if (p.variants.isNotEmpty) const SizedBox(width: 4),
              if (p.variants.isNotEmpty)
                AnimatedRotation(
                  turns: _expandedIds.contains(p.id) ? 0.25 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: Icon(Icons.chevron_right_rounded, size: 16,
                      color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                ),
            ])),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text(p.sku.isNotEmpty ? p.sku : '—', style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text(p.categoryName, style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text(p.sizes.join(', '), style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text(p.colors.join(', '), style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: Text('${p.stock}', style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: p.stock == 0 ? const Color(0xFFEF4444) : p.stock <= 10 ? const Color(0xFFF59E0B) : (isDark ? Colors.white : const Color(0xFF111827)),
            ), textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: Center(child: stockBadge)),
          ]),
        ),
      ),
      // Expanded variant details
      if (_expandedIds.contains(p.id) && p.variants.isNotEmpty)
        Container(
          padding: const EdgeInsets.only(left: 96, right: 20, top: 12, bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFB),
            border: Border(bottom: BorderSide(color: border)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Mini header
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                Expanded(flex: 2, child: Text('Size', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)))),
                Expanded(flex: 2, child: Text('Màu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)))),
                Expanded(flex: 1, child: Text('Tồn kho', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Giá', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)), textAlign: TextAlign.right)),
              ]),
            ),
            ...p.variants.map((v) {
              final vStockColor = v.stock == 0 ? const Color(0xFFEF4444) : v.stock <= 5 ? const Color(0xFFF59E0B) : (isDark ? Colors.white60 : const Color(0xFF374151));
              // Show variant price, fallback to product price
              final displayPrice = v.price > 0 ? v.price : p.price;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                    child: Text(v.size, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)), textAlign: TextAlign.center),
                  ))),
                  Expanded(flex: 2, child: Text(v.color, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF374151)))),
                  Expanded(flex: 1, child: Text('${v.stock}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: vStockColor), textAlign: TextAlign.center)),
                  Expanded(flex: 2, child: Text('${_formatPrice(displayPrice)}đ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF374151)), textAlign: TextAlign.right)),
                ]),
              );
            }),
          ]),
        ),
    ]);
  }

  String _formatPrice(double price) {
    final p = price.toInt().toString();
    final buf = StringBuffer();
    for (int i = 0; i < p.length; i++) {
      if (i > 0 && (p.length - i) % 3 == 0) buf.write('.');
      buf.write(p[i]);
    }
    return buf.toString();
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.inventory_2_rounded, size: 36, color: Color(0xFF7C3AED)),
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty || _filterParent.isNotEmpty || _filterGender.isNotEmpty
              ? 'Không tìm thấy sản phẩm'
              : 'Không có sản phẩm nào',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        Text('Sử dụng bộ lọc hoặc thêm sản phẩm mới', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
      ]),
    );
  }

  // ═══════════════════════════════════════════════
  // PANEL CONTENT — Complete New Design
  // ═══════════════════════════════════════════════
  Widget _buildPanelContent(bool isDark, List<Product> allProducts, List<Category> allCats) {
    final panelProducts = _applyFilters(allProducts, forPanel: true);
    final accent = _isStockIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final surfaceBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0);
    final brands = context.watch<BrandProvider>().brands;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ─── Operation type indicator ───
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accent.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(_isStockIn ? Icons.download_rounded : Icons.upload_rounded, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_isStockIn ? 'NHẬP KHO' : 'XUẤT KHO',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent, letterSpacing: 1)),
            const SizedBox(height: 2),
            Text(_isStockIn ? 'Thêm hàng vào kho' : 'Xuất hàng ra khỏi kho',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
          ]),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text('${panelProducts.length} SP',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
          ),
        ]),
      ),

      // ─── Search bar ───
      SizedBox(
        height: 38,
        child: TextField(
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: 'Tìm tên, SKU...',
            hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white30 : const Color(0xFF94A3B8)),
            filled: true,
            fillColor: surfaceBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 1.5)),
          ),
          onChanged: (v) => setState(() => _panelSearch = v),
        ),
      ),
      const SizedBox(height: 10),

      // ─── Filter pills ───
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _pill(isDark, 'Danh mục', _panelFilterParent, borderColor, [
            const DropdownMenuItem(value: '', child: Text('Tất cả')),
            ..._parentCats(allCats).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
          ], (v) => setState(() { _panelFilterParent = v ?? ''; _panelFilterChild = ''; })),
          const SizedBox(width: 6),
          if (_panelFilterParent.isNotEmpty) ...[
            _pill(isDark, 'Danh mục con', _panelFilterChild, borderColor, [
              const DropdownMenuItem(value: '', child: Text('Tất cả')),
              ..._childCats(allCats, _panelFilterParent).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
            ], (v) => setState(() => _panelFilterChild = v ?? '')),
            const SizedBox(width: 6),
          ],
          _pill(isDark, 'Thương hiệu', _panelFilterBrand, borderColor, [
            const DropdownMenuItem(value: '', child: Text('Tất cả')),
            ...brands.map((b) => DropdownMenuItem(value: b.id, child: Text(b.name))),
          ], (v) => setState(() => _panelFilterBrand = v ?? '')),
          const SizedBox(width: 6),
          _pill(isDark, 'Giới tính', _panelFilterGender, borderColor, const [
            DropdownMenuItem(value: '', child: Text('Tất cả')),
            DropdownMenuItem(value: 'male', child: Text('Nam')),
            DropdownMenuItem(value: 'female', child: Text('Nữ')),
          ], (v) => setState(() => _panelFilterGender = v ?? '')),
        ]),
      ),
      const SizedBox(height: 12),

      // ─── Product list (fixed max height) ───
      ConstrainedBox(
        constraints: BoxConstraints(maxHeight: _selectedProduct != null ? 200 : 400),
        child: panelProducts.isEmpty
          ? Container(
              height: 80,
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.inventory_2_outlined, size: 32, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                const SizedBox(height: 6),
                Text('Không tìm thấy sản phẩm', style: TextStyle(fontSize: 12, color: isDark ? Colors.white24 : const Color(0xFF94A3B8))),
              ]),
            )
          : ListView.builder(
              shrinkWrap: true,
              itemCount: panelProducts.length,
              itemBuilder: (_, i) => _buildProductTile(isDark, panelProducts[i], accent, cardBg, borderColor),
            ),
      ),

      // ─── Detail form (when product is selected) ───
      if (_selectedProduct != null) ...[
        const SizedBox(height: 16),
        _buildDetailForm(isDark, accent, cardBg, borderColor),
      ],
    ]);
  }

  // ─── Filter pill ───
  Widget _pill(bool isDark, String label, String value, Color borderColor,
      List<DropdownMenuItem<String>> items, ValueChanged<String?> onChanged) {
    final hasValue = value.isNotEmpty;
    return Container(
      height: 30,
      padding: const EdgeInsets.only(left: 10, right: 4),
      decoration: BoxDecoration(
        color: hasValue
            ? const Color(0xFF7C3AED).withValues(alpha: 0.08)
            : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasValue ? const Color(0xFF7C3AED).withValues(alpha: 0.3) : borderColor),
      ),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: hasValue ? value : null,
        hint: Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF94A3B8))),
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF334155)),
        icon: Icon(Icons.expand_more_rounded, size: 16,
          color: hasValue ? const Color(0xFF7C3AED) : (isDark ? Colors.white24 : const Color(0xFF94A3B8))),
        isDense: true,
        items: items,
        onChanged: onChanged,
      )),
    );
  }

  // ─── Product tile ───
  Widget _buildProductTile(bool isDark, Product p, Color accent, Color cardBg, Color borderColor) {
    final isSelected = _selectedProduct?.id == p.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? accent.withValues(alpha: isDark ? 0.10 : 0.04) : cardBg,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _selectProduct(p),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? accent.withValues(alpha: 0.4) : borderColor),
            ),
            child: Row(children: [
              // Radio circle
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isSelected ? accent : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)), width: 2),
                  color: isSelected ? accent : Colors.transparent,
                ),
                child: isSelected ? const Icon(Icons.check_rounded, size: 12, color: Colors.white) : null,
              ),
              const SizedBox(width: 10),
              // Image
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                ),
                clipBehavior: Clip.antiAlias,
                child: p.images.isNotEmpty
                    ? Image.network(p.images.first, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image_rounded, size: 16, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)))
                    : Icon(Icons.image_rounded, size: 16, color: isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              ),
              const SizedBox(width: 10),
              // Info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(p.name,
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis, maxLines: 1),
                const SizedBox(height: 3),
                Row(children: [
                  Text(p.brandName, style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFF94A3B8))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text('·', style: TextStyle(color: isDark ? Colors.white12 : const Color(0xFFCBD5E1))),
                  ),
                  Text(p.categoryName, style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFF94A3B8))),
                ]),
              ])),
              // Stock badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (p.stock == 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${p.stock}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: p.stock == 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ─── Detail form ───
  Widget _buildDetailForm(bool isDark, Color accent, Color cardBg, Color borderColor) {
    final p = _selectedProduct!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? accent.withValues(alpha: 0.04) : accent.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Selected product info bar
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF1F5F9)),
              clipBehavior: Clip.antiAlias,
              child: p.images.isNotEmpty
                  ? Image.network(p.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox())
                  : Icon(Icons.shopping_bag_outlined, size: 16, color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Row(children: [
                if (p.sku.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(3)),
                    child: Text(p.sku, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
                  ),
                  const SizedBox(width: 6),
                ],
                Text('Tồn kho: ${p.stock}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: p.stock == 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
              ]),
            ])),
          ]),
        ),
        const SizedBox(height: 14),

        // Qty input
        Text('Số lượng ${_isStockIn ? "nhập" : "xuất"}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: TextField(
            controller: _totalQtyCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            onChanged: (_) => setState(() => _validationError = null),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              contentPadding: EdgeInsets.zero,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: accent, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Variant allocation table
        if (_variantQtyCtrls.isNotEmpty) ...[
          Text('Phân bổ theo biến thể',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : const Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              // Table header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                child: Row(children: [
                  SizedBox(width: 50, child: Text('Size', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)))),
                  Expanded(child: Text('Màu', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)))),
                  SizedBox(width: 40, child: Text('Tồn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)), textAlign: TextAlign.center)),
                  SizedBox(width: 70, child: Text('SL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF94A3B8)), textAlign: TextAlign.center)),
                ]),
              ),
              // Table rows
              ...(() {
                int rowIdx = 0;
                return p.sizes.expand((size) => p.colors.map((color) {
                  final key = '$size|$color';
                  final ctrl = _variantQtyCtrls[key]!;
                  final variant = p.variants.where((v) => v.size == size && v.color == color).firstOrNull;
                  final currentStock = variant?.stock ?? 0;
                  final isEven = rowIdx % 2 == 0;
                  rowIdx++;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    color: isEven
                        ? Colors.transparent
                        : (isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8FAFC)),
                    child: Row(children: [
                      SizedBox(width: 50, child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                        child: Text(size, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)), textAlign: TextAlign.center),
                      )),
                      Expanded(child: Text(color, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF334155)))),
                      SizedBox(width: 40, child: Text('$currentStock',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: currentStock == 0 ? const Color(0xFFEF4444) : (isDark ? Colors.white38 : const Color(0xFF94A3B8))),
                        textAlign: TextAlign.center)),
                      SizedBox(width: 70, child: SizedBox(height: 28, child: TextField(
                        controller: ctrl,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                        onChanged: (_) => setState(() => _validationError = null),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: borderColor)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: accent, width: 1)),
                        ),
                      ))),
                    ]),
                  );
                }));
              })(),
            ]),
          ),
          const SizedBox(height: 8),
          // Progress bar for allocation
          Builder(builder: (_) {
            final sum = _variantSum;
            final total = _totalQty;
            final progress = total > 0 ? (sum / total).clamp(0.0, 1.0) : 0.0;
            final match = sum == total && total > 0;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('$sum / $total phân bổ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: match ? const Color(0xFF10B981) : const Color(0xFFF59E0B))),
                const Spacer(),
                if (match) const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
              ]),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation(match ? const Color(0xFF10B981) : const Color(0xFFF59E0B)),
                ),
              ),
            ]);
          }),
          const SizedBox(height: 14),
        ],

        // Validation error
        if (_validationError != null)
          Container(
            padding: const EdgeInsets.all(10),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Expanded(child: Text(_validationError!, style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), height: 1.3))),
            ]),
          ),

        // Submit button
        SizedBox(
          width: double.infinity,
          height: 42,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Xác nhận ${_isStockIn ? "nhập" : "xuất"} kho',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }
}
