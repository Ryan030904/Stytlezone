import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_snackbar.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import 'admin_slide_panel.dart';

/// Tab "Quản lý kho" — compact pill-tabs + slide panel nhập/xuất.
class InventoryContent extends StatefulWidget {
  const InventoryContent({super.key});
  @override
  State<InventoryContent> createState() => _InventoryContentState();
}

class _InventoryContentState extends State<InventoryContent> {
  // ── Sub-tab ──
  int _activeTab = 0; // 0 = Sản phẩm, 1 = Lịch sử

  // ── Product filters ──
  String _productSearch = '';
  String _productCategory = 'Tất cả';
  String _stockFilter = 'Tất cả';
  final _productSearchCtrl = TextEditingController();

  // ── History filters ──
  String _historySearch = '';
  String _historyType = 'Tất cả';
  final _historySearchCtrl = TextEditingController();

  // ── Slide Panel ──
  bool _isPanelOpen = false;
  Product? _editingProduct;
  final _stockCtrl = TextEditingController();
  String _adjustType = 'Nhập kho';
  String _adjustReason = 'Nhập hàng mới';
  final _noteCtrl = TextEditingController();

  // ── History log (in-memory) ──
  final List<_StockLog> _stockLogs = [];

  static const _adjustTypes = ['Nhập kho', 'Xuất kho'];
  static const _importReasons = ['Nhập hàng mới', 'Hoàn hàng', 'Chuyển kho đến', 'Kiểm kho tăng', 'Khác'];
  static const _exportReasons = ['Bán hàng', 'Hàng lỗi/hỏng', 'Chuyển kho đi', 'Kiểm kho giảm', 'Khác'];
  static const _stockFilters = ['Tất cả', 'Còn hàng', 'Sắp hết', 'Hết hàng'];

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
    _productSearchCtrl.dispose();
    _historySearchCtrl.dispose();
    _stockCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _openImportPanel(Product product) {
    _editingProduct = product;
    _stockCtrl.text = '';
    _adjustType = 'Nhập kho';
    _adjustReason = 'Nhập hàng mới';
    _noteCtrl.clear();
    setState(() => _isPanelOpen = true);
  }

  void _closePanel() => setState(() => _isPanelOpen = false);

  String _fmtVND(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  String _fmtTime(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AdminSlidePanel(
      isOpen: _isPanelOpen,
      title: _adjustType == 'Nhập kho' ? 'Nhập kho sản phẩm' : 'Xuất kho sản phẩm',
      onClose: _closePanel,
      panelBody: _isPanelOpen ? _buildPanelBody(isDark) : null,
      panelFooter: _isPanelOpen ? _buildPanelFooter(isDark) : null,
      child: Consumer<ProductProvider>(
        builder: (context, prov, _) {
          if (prov.isLoading && prov.products.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(60), child: CircularProgressIndicator(color: Color(0xFF7C3AED))));
          }
          return Column(children: [
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildHeader(isDark),
                const SizedBox(height: 20),
                _buildStats(isDark, prov.products),
                const SizedBox(height: 24),
                // Content card with tab header
                _buildContentCard(isDark, prov.products),
              ]),
            )),
          ]);
        },
      ),
    );
  }

  // ═══════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════
  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quản lý kho', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.textDark)),
          const SizedBox(height: 4),
          Text('Theo dõi tồn kho và lịch sử nhập xuất', style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.5) : AppTheme.textLight)),
        ])),
        ElevatedButton.icon(
          onPressed: () {
            final products = Provider.of<ProductProvider>(context, listen: false).products;
            if (products.isNotEmpty) {
              _openImportPanel(products.first);
            } else {
              AppSnackBar.error(context, 'Chưa có sản phẩm nào');
            }
          },
          icon: const Icon(Icons.swap_vert_rounded, size: 18),
          label: const Text('Nhập / Xuất kho'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════
  Widget _buildStats(bool isDark, List<Product> products) {
    final total = products.length;
    final totalStock = products.fold<int>(0, (s, p) => s + p.stock);
    final lowStock = products.where((p) => p.stock > 0 && p.stock <= 10).length;
    final outOfStock = products.where((p) => p.stock == 0).length;
    final totalValue = products.fold<double>(0, (s, p) => s + (p.price * p.stock));
    return Row(children: [
      _statCard(isDark, Icons.inventory_2_rounded, '$total', 'Tổng SP', const Color(0xFF7C3AED)),
      const SizedBox(width: 12),
      _statCard(isDark, Icons.straighten_rounded, '$totalStock', 'Tổng tồn kho', const Color(0xFF3B82F6)),
      const SizedBox(width: 12),
      _statCard(isDark, Icons.warning_amber_rounded, '$lowStock', 'Sắp hết hàng', const Color(0xFFF59E0B)),
      const SizedBox(width: 12),
      _statCard(isDark, Icons.error_outline_rounded, '$outOfStock', 'Hết hàng', const Color(0xFFEF4444)),
      const SizedBox(width: 12),
      _statCard(isDark, Icons.payments_rounded, _fmtVND(totalValue), 'Giá trị kho', const Color(0xFF10B981)),
    ]);
  }

  Widget _statCard(bool isDark, IconData icon, String value, String label, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
      ),
      child: Row(children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : AppTheme.textDark), overflow: TextOverflow.ellipsis),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9CA3AF))),
        ])),
      ]),
    ));
  }

  // ═══════════════════════════════════════
  // CONTENT CARD (tab header + search + filters + table)
  // ═══════════════════════════════════════
  Widget _buildContentCard(bool isDark, List<Product> products) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Card header: tabs + search ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Pill tabs row
            Row(children: [
              _pillTab(isDark, 0, Icons.inventory_2_rounded, 'Sản phẩm'),
              const SizedBox(width: 6),
              _pillTab(isDark, 1, Icons.history_rounded, 'Lịch sử'),
            ]),
            const SizedBox(height: 16),
            // Search bar
            if (_activeTab == 0)
              _buildSearchField(isDark, _productSearchCtrl, 'Tìm theo tên sản phẩm, SKU...', (v) => setState(() => _productSearch = v))
            else
              _buildSearchField(isDark, _historySearchCtrl, 'Tìm theo tên sản phẩm, SKU...', (v) => setState(() => _historySearch = v)),
            const SizedBox(height: 10),
            // Filter chips
            if (_activeTab == 0)
              _buildProductFilters(isDark)
            else
              _buildHistoryFilters(isDark),
            const SizedBox(height: 14),
          ]),
        ),
        // Divider
        Divider(height: 1, thickness: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0F0F0)),
        // Table content
        if (_activeTab == 0)
          _buildProductTable(isDark, products)
        else
          _buildHistoryTable(isDark),
      ]),
    );
  }

  Widget _pillTab(bool isDark, int index, IconData icon, String label) {
    final isActive = _activeTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
              ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
              : (isDark ? Colors.transparent : Colors.transparent),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                ? const Color(0xFF7C3AED).withValues(alpha: 0.35)
                : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 15, color: isActive ? const Color(0xFF7C3AED) : (isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9CA3AF))),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? const Color(0xFF7C3AED) : (isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDark, TextEditingController ctrl, String hint, ValueChanged<String> onChanged) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: TextStyle(fontSize: 14, color: isDark ? Colors.white : AppTheme.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.25) : const Color(0xFFBBBBBB)),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(Icons.search_rounded, size: 20, color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFFBBBBBB)),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
      ),
    );
  }

  Widget _buildProductFilters(bool isDark) {
    final categories = Provider.of<CategoryProvider>(context, listen: false)
        .categories.where((c) => c.isActive).map((c) => c.name).toList();
    return Row(children: [
      _filterChip(isDark, 'Danh mục', _productCategory, ['Tất cả', ...categories], (v) => setState(() => _productCategory = v)),
      const SizedBox(width: 8),
      _filterChip(isDark, 'Tồn kho', _stockFilter, _stockFilters, (v) => setState(() => _stockFilter = v)),
    ]);
  }

  Widget _buildHistoryFilters(bool isDark) {
    return Row(children: [
      _filterChip(isDark, 'Loại', _historyType, ['Tất cả', 'Nhập kho', 'Xuất kho'], (v) => setState(() => _historyType = v)),
    ]);
  }

  // ═══════════════════════════════════════
  // PRODUCT TABLE
  // ═══════════════════════════════════════
  Widget _buildProductTable(bool isDark, List<Product> products) {
    final filtered = products.where((p) {
      if (_productSearch.isNotEmpty) {
        final q = _productSearch.toLowerCase();
        if (!p.name.toLowerCase().contains(q) && !p.sku.toLowerCase().contains(q)) return false;
      }
      if (_productCategory != 'Tất cả' && p.categoryName != _productCategory) return false;
      if (_stockFilter == 'Còn hàng' && p.stock <= 10) return false;
      if (_stockFilter == 'Sắp hết' && (p.stock == 0 || p.stock > 10)) return false;
      if (_stockFilter == 'Hết hàng' && p.stock > 0) return false;
      return true;
    }).toList();

    if (filtered.isEmpty) return _emptyState(isDark, Icons.inventory_2_outlined, 'Không tìm thấy sản phẩm');

    return Column(children: [
      // Table header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFB),
        child: Row(children: [
          const SizedBox(width: 42),
          Expanded(flex: 3, child: _th('SẢN PHẨM', isDark)),
          Expanded(flex: 2, child: _th('DANH MỤC', isDark)),
          Expanded(flex: 1, child: _th('TỒN KHO', isDark)),
          Expanded(flex: 1, child: _th('TRẠNG THÁI', isDark)),
          Expanded(flex: 1, child: _th('GIÁ TRỊ', isDark)),
          const SizedBox(width: 80),
        ]),
      ),
      ...filtered.map((p) => _productRow(p, isDark)),
    ]);
  }

  Widget _th(String t, bool isDark) => Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF9CA3AF)));

  Widget _productRow(Product p, bool isDark) {
    final stk = p.stock;
    final Color sc = stk == 0 ? const Color(0xFFEF4444) : stk <= 10 ? const Color(0xFFF59E0B) : const Color(0xFF10B981);
    final String sl = stk == 0 ? 'Hết hàng' : stk <= 10 ? 'Sắp hết' : 'Còn hàng';
    final ln = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6);
    return InkWell(
      onTap: () => _openImportPanel(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ln))),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6)),
            clipBehavior: Clip.antiAlias,
            child: p.imageUrl != null && p.imageUrl!.isNotEmpty
              ? Image.network(p.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_rounded, size: 14, color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFD1D5DB)))
              : Icon(Icons.image_rounded, size: 14, color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFD1D5DB))),
          const SizedBox(width: 10),
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.85) : AppTheme.textDark)),
            Text(p.sku, style: TextStyle(fontSize: 10, color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF9CA3AF))),
          ])),
          Expanded(flex: 2, child: Text(p.categoryName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280)))),
          Expanded(flex: 1, child: Text('${p.stock}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: sc))),
          Expanded(flex: 1, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Text(sl, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: sc)))),
          Expanded(flex: 1, child: Text(_fmtVND(p.price * p.stock), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280)), overflow: TextOverflow.ellipsis)),
          SizedBox(width: 80, child: SizedBox(height: 28, child: OutlinedButton.icon(
            onPressed: () => _openImportPanel(p),
            icon: const Icon(Icons.swap_vert_rounded, size: 13),
            label: const Text('Nhập/Xuất', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(horizontal: 6),
              side: BorderSide(color: const Color(0xFF7C3AED).withValues(alpha: 0.25)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)))))),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════
  // HISTORY TABLE
  // ═══════════════════════════════════════
  Widget _buildHistoryTable(bool isDark) {
    var logs = List<_StockLog>.from(_stockLogs);
    if (_historySearch.isNotEmpty) {
      final q = _historySearch.toLowerCase();
      logs = logs.where((l) => l.productName.toLowerCase().contains(q) || l.sku.toLowerCase().contains(q)).toList();
    }
    if (_historyType != 'Tất cả') logs = logs.where((l) => l.type == _historyType).toList();

    if (logs.isEmpty) return _emptyState(isDark, Icons.history_rounded, 'Chưa có lịch sử nhập/xuất kho');

    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFB),
        child: Row(children: [
          Expanded(flex: 2, child: _th('THỜI GIAN', isDark)),
          Expanded(flex: 1, child: _th('LOẠI', isDark)),
          Expanded(flex: 3, child: _th('SẢN PHẨM', isDark)),
          Expanded(flex: 1, child: _th('SỐ LƯỢNG', isDark)),
          Expanded(flex: 2, child: _th('LÝ DO', isDark)),
          Expanded(flex: 2, child: _th('GHI CHÚ', isDark)),
        ]),
      ),
      ...logs.map((l) => _historyRow(l, isDark)),
    ]);
  }

  Widget _historyRow(_StockLog log, bool isDark) {
    final isImport = log.type == 'Nhập kho';
    final tc = isImport ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final ln = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ln))),
      child: Row(children: [
        Expanded(flex: 2, child: Text(_fmtTime(log.date), style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.45) : const Color(0xFF6B7280)))),
        Expanded(flex: 1, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(color: tc.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(isImport ? Icons.download_rounded : Icons.upload_rounded, size: 11, color: tc),
            const SizedBox(width: 3),
            Text(isImport ? 'Nhập' : 'Xuất', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tc)),
          ]))),
        Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log.productName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.8) : AppTheme.textDark)),
          Text(log.sku, style: TextStyle(fontSize: 10, color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF9CA3AF))),
        ])),
        Expanded(flex: 1, child: Text('${isImport ? '+' : '-'}${log.quantity}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tc))),
        Expanded(flex: 2, child: Text(log.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280)))),
        Expanded(flex: 2, child: Text(log.note.isEmpty ? '—' : log.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? Colors.white.withValues(alpha: 0.3) : const Color(0xFF9CA3AF)))),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════
  Widget _filterChip(bool isDark, String label, String value, List<String> options, ValueChanged<String> onSelected) {
    final isDefault = value == 'Tất cả';
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 38),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      itemBuilder: (_) => options.map((o) => PopupMenuItem(value: o, height: 36, child: Row(children: [
        if (o == value) const Icon(Icons.check_rounded, size: 14, color: Color(0xFF7C3AED)) else const SizedBox(width: 14),
        const SizedBox(width: 8),
        Text(o, style: TextStyle(fontSize: 12, fontWeight: o == value ? FontWeight.w600 : FontWeight.w400, color: isDark ? Colors.white : AppTheme.textDark)),
      ]))).toList(),
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDefault
            ? (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB))
            : const Color(0xFF7C3AED).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDefault
            ? (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB))
            : const Color(0xFF7C3AED).withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(isDefault ? label : value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDefault ? (isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280)) : const Color(0xFF7C3AED))),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDefault ? (isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9CA3AF)) : const Color(0xFF7C3AED)),
        ]),
      ),
    );
  }

  Widget _emptyState(bool isDark, IconData icon, String msg) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 50),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 40, color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFD1D5DB)),
        const SizedBox(height: 10),
        Text(msg, style: TextStyle(fontSize: 13, color: isDark ? Colors.white.withValues(alpha: 0.35) : const Color(0xFF9CA3AF))),
      ])),
    );
  }

  // ═══════════════════════════════════════
  // PANEL BODY / FOOTER
  // ═══════════════════════════════════════
  Widget _buildPanelBody(bool isDark) {
    final p = _editingProduct;
    if (p == null) return const SizedBox.shrink();
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    final card = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final reasons = _adjustType == 'Nhập kho' ? _importReasons : _exportReasons;
    if (!reasons.contains(_adjustReason)) _adjustReason = reasons.first;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: bdr)),
        child: Row(children: [
          Container(width: 44, height: 44,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white, border: Border.all(color: bdr)),
            clipBehavior: Clip.antiAlias,
            child: p.imageUrl != null && p.imageUrl!.isNotEmpty
              ? Image.network(p.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_rounded, size: 20, color: ts))
              : Icon(Icons.image_rounded, size: 20, color: ts)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tp)),
            const SizedBox(height: 2),
            Text('${p.sku} · Tồn: ${p.stock}', style: TextStyle(fontSize: 11, color: ts)),
          ])),
        ]),
      ),
      const SizedBox(height: 20),
      _panelLabel('Loại giao dịch', tp),
      const SizedBox(height: 8),
      Row(children: _adjustTypes.map((t) {
        final sel = _adjustType == t;
        final isImp = t == 'Nhập kho';
        final clr = isImp ? const Color(0xFF10B981) : const Color(0xFFEF4444);
        return Expanded(child: Padding(padding: EdgeInsets.only(right: t == _adjustTypes.last ? 0 : 8),
          child: InkWell(borderRadius: BorderRadius.circular(10), onTap: () => setState(() { _adjustType = t; _adjustReason = (t == 'Nhập kho' ? _importReasons : _exportReasons).first; }),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(color: sel ? clr.withValues(alpha: 0.1) : card, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? clr.withValues(alpha: 0.4) : bdr, width: sel ? 1.5 : 1)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(isImp ? Icons.download_rounded : Icons.upload_rounded, size: 16, color: sel ? clr : ts),
                const SizedBox(width: 6),
                Text(t, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w500, color: sel ? clr : ts)),
              ])))));
      }).toList()),
      const SizedBox(height: 18),
      _panelLabel('Số lượng', tp),
      const SizedBox(height: 8),
      TextField(controller: _stockCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], onChanged: (_) => setState(() {}),
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp),
        decoration: InputDecoration(hintText: '0', filled: true, fillColor: card, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)), isDense: true)),
      const SizedBox(height: 10),
      Row(children: [5, 10, 20, 50, 100].map((n) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(borderRadius: BorderRadius.circular(7), onTap: () { _stockCtrl.text = '$n'; setState(() {}); },
          child: Container(padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(7), border: Border.all(color: bdr)),
            child: Center(child: Text('$n', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7280))))))))).toList()),
      const SizedBox(height: 18),
      _panelLabel('Lý do', tp),
      const SizedBox(height: 8),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: _adjustReason, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ts), dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white, style: TextStyle(fontSize: 13, color: tp),
          items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
          onChanged: (v) { if (v != null) setState(() => _adjustReason = v); }))),
      const SizedBox(height: 14),
      _panelLabel('Ghi chú', tp),
      const SizedBox(height: 8),
      TextField(controller: _noteCtrl, maxLines: 2, style: TextStyle(fontSize: 12, color: tp),
        decoration: InputDecoration(hintText: 'Ghi chú (không bắt buộc)', hintStyle: TextStyle(fontSize: 12, color: ts.withValues(alpha: 0.6)),
          filled: true, fillColor: card, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          contentPadding: const EdgeInsets.all(12), isDense: true)),
    ]);
  }

  Widget _panelLabel(String t, Color c) => Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c));

  Widget _buildPanelFooter(bool isDark) {
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final isImport = _adjustType == 'Nhập kho';
    final btnColor = isImport ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Row(children: [
      Expanded(child: SizedBox(height: 40, child: OutlinedButton(onPressed: _closePanel,
        style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        child: const Text('Hủy', style: TextStyle(fontSize: 13))))),
      const SizedBox(width: 10),
      Expanded(flex: 2, child: SizedBox(height: 40, child: ElevatedButton.icon(
        icon: Icon(isImport ? Icons.download_rounded : Icons.upload_rounded, size: 16),
        label: Text(isImport ? 'Xác nhận nhập kho' : 'Xác nhận xuất kho', style: const TextStyle(fontSize: 13)),
        style: ElevatedButton.styleFrom(backgroundColor: btnColor, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: () async {
          final p = _editingProduct; if (p == null) return;
          final qty = int.tryParse(_stockCtrl.text) ?? 0;
          if (qty <= 0) { AppSnackBar.error(context, 'Vui lòng nhập số lượng > 0'); return; }
          final newStock = isImport ? p.stock + qty : (p.stock - qty).clamp(0, 999999);
          if (!isImport && qty > p.stock) { AppSnackBar.error(context, 'Số lượng xuất vượt quá tồn kho (${p.stock})'); return; }
          final updated = p.copyWith(stock: newStock, isActive: p.isActive, updatedAt: DateTime.now());
          _closePanel();
          final prov = Provider.of<ProductProvider>(context, listen: false);
          final ok = await prov.updateProduct(updated);
          if (!mounted) return;
          if (ok) {
            setState(() => _stockLogs.insert(0, _StockLog(
              productName: p.name, sku: p.sku, type: _adjustType, quantity: qty,
              reason: _adjustReason, note: _noteCtrl.text, date: DateTime.now(),
              oldStock: p.stock, newStock: newStock,
            )));
            AppSnackBar.success(context, '${isImport ? 'Nhập' : 'Xuất'} kho: ${p.name} — ${isImport ? '+' : '-'}$qty (${p.stock} → $newStock)');
          }
        }))),
    ]);
  }
}

class _StockLog {
  final String productName, sku, type, reason, note;
  final int quantity, oldStock, newStock;
  final DateTime date;
  _StockLog({required this.productName, required this.sku, required this.type, required this.quantity, required this.reason, required this.note, required this.date, required this.oldStock, required this.newStock});
}
