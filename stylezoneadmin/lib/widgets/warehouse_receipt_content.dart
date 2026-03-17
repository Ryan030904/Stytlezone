import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/admin_enums.dart';
import '../models/product_model.dart';
import '../models/warehouse_receipt_model.dart';
import '../providers/warehouse_receipt_provider.dart';
import '../services/product_service.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'app_state_widgets.dart';

class WarehouseReceiptContent extends StatefulWidget {
  const WarehouseReceiptContent({super.key});

  @override
  State<WarehouseReceiptContent> createState() => _WarehouseReceiptContentState();
}

class _WarehouseReceiptContentState extends State<WarehouseReceiptContent> {
  bool get isDarkMode => mounted ? Theme.of(context).brightness == Brightness.dark : false;
  int _selectedTypeTab = 0;
  int _selectedStatusTab = 0;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  static const _typeTabs = ['Tất cả', 'Nhập kho', 'Xuất kho', 'Chuyển kho', 'Kiểm kho'];
  static const _statusTabs = ['Tất cả', 'Nháp', 'Đang xử lý', 'Hoàn tất', 'Đã hủy'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WarehouseReceiptProvider>().loadReceipts();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WarehouseReceiptModel> _applyFilters(List<WarehouseReceiptModel> list) {
    var filtered = list;
    if (_selectedTypeTab > 0) {
      final t = [ReceiptType.stockIn, ReceiptType.stockOut, ReceiptType.transfer, ReceiptType.stockCheck][_selectedTypeTab - 1];
      filtered = filtered.where((r) => r.type == t).toList();
    }
    if (_selectedStatusTab > 0) {
      final s = [ReceiptStatus.draft, ReceiptStatus.processing, ReceiptStatus.completed, ReceiptStatus.cancelled][_selectedStatusTab - 1];
      filtered = filtered.where((r) => r.status == s).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((r) =>
          r.code.toLowerCase().contains(q) ||
          r.warehouse.toLowerCase().contains(q) ||
          r.toWarehouse.toLowerCase().contains(q) ||
          r.note.toLowerCase().contains(q)).toList();
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WarehouseReceiptProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.receipts.isEmpty) {
          return const AppLoadingState(message: 'Đang tải phiếu kho...');
        }
        final all = provider.receipts;
        final filtered = _applyFilters(all);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(provider),
              const SizedBox(height: 20),
              _buildStatCards(all),
              const SizedBox(height: 20),
              _buildFilterBar(),
              const SizedBox(height: 16),
              if (provider.errorMessage != null)
                AppErrorState(message: provider.errorMessage!, onRetry: () => provider.loadReceipts()),
              if (filtered.isEmpty && provider.errorMessage == null)
                const AppEmptyState(
                  title: 'Không có phiếu kho',
                  message: 'Chưa có phiếu kho nào phù hợp bộ lọc.',
                  icon: Icons.inventory_2_outlined,
                ),
              if (filtered.isNotEmpty) _buildTable(filtered, provider),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader(WarehouseReceiptProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quản lý phiếu kho',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : AppTheme.textDark)),
              SizedBox(height: 4),
              Text('Tạo và quản lý phiếu nhập kho, xuất kho, chuyển kho, kiểm kho',
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : AppTheme.textLight)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () => _showReceiptDialog(),
          icon: Icon(Icons.add_rounded, size: 18),
          label: Text('Tạo phiếu kho'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          onPressed: () => provider.loadReceipts(),
          icon: Icon(Icons.refresh_rounded, size: 18),
          label: Text('Tải lại'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // STAT CARDS
  // ═══════════════════════════════════════════════
  Widget _buildStatCards(List<WarehouseReceiptModel> all) {
    final total = all.length;
    final stockIn = all.where((r) => r.type == ReceiptType.stockIn).length;
    final stockOut = all.where((r) => r.type == ReceiptType.stockOut).length;
    final completed = all.where((r) => r.status == ReceiptStatus.completed).length;
    final totalQty = all.fold<int>(0, (s, r) => s + r.totalQty);

    return Row(
      children: [
        _statCard('Tổng phiếu', total.toString(), Icons.receipt_long_rounded, const Color(0xFF7C3AED)),
        const SizedBox(width: 12),
        _statCard('Nhập kho', stockIn.toString(), Icons.arrow_downward_rounded, const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _statCard('Xuất kho', stockOut.toString(), Icons.arrow_upward_rounded, const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _statCard('Hoàn tất', completed.toString(), Icons.check_circle_rounded, const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        _statCard('Tổng SL hàng', _fmtNumber(totalQty), Icons.inventory_rounded, const Color(0xFFEC4899)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : const Color(0xFF111827))),
                  Text(label, style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // FILTER BAR — search + type + status in 1 card
  // ═══════════════════════════════════════════════
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          // Search row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 18, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo mã phiếu, tên kho...',
                      hintStyle: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close_rounded, size: 16, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Type + Status filters — symmetric row
          Row(
            children: [
              // Left: Loại
              Expanded(
                child: _filterSection(
                  icon: Icons.category_rounded,
                  label: 'Loại phiếu',
                  tabs: _typeTabs,
                  selectedIndex: _selectedTypeTab,
                  colors: [
                    const Color(0xFF7C3AED), // Tất cả
                    const Color(0xFF10B981), // Nhập
                    const Color(0xFFF59E0B), // Xuất
                    const Color(0xFF3B82F6), // Chuyển
                    const Color(0xFF8B5CF6), // Kiểm
                  ],
                  onTap: (i) => setState(() => _selectedTypeTab = i),
                ),
              ),
              const SizedBox(width: 16),
              // Right: Trạng thái
              Expanded(
                child: _filterSection(
                  icon: Icons.flag_rounded,
                  label: 'Trạng thái',
                  tabs: _statusTabs,
                  selectedIndex: _selectedStatusTab,
                  colors: [
                    const Color(0xFF7C3AED), // Tất cả
                    const Color(0xFF6B7280), // Nháp
                    const Color(0xFFF59E0B), // Xử lý
                    const Color(0xFF10B981), // Hoàn tất
                    const Color(0xFFEF4444), // Hủy
                  ],
                  onTap: (i) => setState(() => _selectedStatusTab = i),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterSection({
    required IconData icon,
    required String label,
    required List<String> tabs,
    required int selectedIndex,
    required List<Color> colors,
    required ValueChanged<int> onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280)),
              SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
            ],
          ),
          SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tabs.asMap().entries.map((e) {
              final isActive = e.key == selectedIndex;
              final color = colors[e.key];
              return InkWell(
                onTap: () => onTap(e.key),
                borderRadius: BorderRadius.circular(8),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? color : (isDarkMode ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? color : (isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
                      width: isActive ? 1.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? Colors.white : (isDarkMode ? Colors.white70 : const Color(0xFF374151)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DATA TABLE
  // ═══════════════════════════════════════════════
  Widget _buildTable(List<WarehouseReceiptModel> list, WarehouseReceiptProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                _hdr('Mã phiếu', 2),
                _hdr('Loại', 2),
                _hdr('Kho', 2),
                _hdr('SL hàng', 1),
                _hdr('Trạng thái', 2),
                _hdr('Áp kho', 1),
                _hdr('Ngày tạo', 2),
                _hdr('Thao tác', 2),
              ],
            ),
          ),
          ...list.map((r) => _buildRow(r, provider)),
        ],
      ),
    );
  }

  Widget _hdr(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
    );
  }

  Widget _buildRow(WarehouseReceiptModel r, WarehouseReceiptProvider provider) {
    final typeColor = _typeColor(r.type);
    final statusColor = _statusColor(r.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          // Mã phiếu
          Expanded(
            flex: 2,
            child: Text(r.code.isNotEmpty ? r.code : r.id.substring(0, 8),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
          ),
          // Loại
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(r.typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: typeColor)),
              ),
            ),
          ),
          // Kho
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(r.warehouse.isNotEmpty ? r.warehouse : '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : const Color(0xFF111827)),
                    overflow: TextOverflow.ellipsis),
                if (r.type == ReceiptType.transfer && r.toWarehouse.isNotEmpty)
                  Text('→ ${r.toWarehouse}', textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
              ],
            ),
          ),
          // SL hàng
          Expanded(
            flex: 1,
            child: Text(r.totalQty.toString(), textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : const Color(0xFF111827))),
          ),
          // Trạng thái
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(r.statusLabel, style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          // Áp kho
          Expanded(
            flex: 1,
            child: Center(
              child: Icon(
                r.stockEffected ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 18,
                color: r.stockEffected ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ),
          // Ngày tạo
          Expanded(
            flex: 2,
            child: Text(_fmtDate(r.createdAt), textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
          ),
          // Thao tác
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionBtn(Icons.visibility_rounded, 'Xem', const Color(0xFF3B82F6), () => _showDetailDialog(r)),
                const SizedBox(width: 4),
                if (r.status != ReceiptStatus.completed && r.status != ReceiptStatus.cancelled)
                  _actionBtn(Icons.published_with_changes_rounded, 'Trạng thái', const Color(0xFF10B981),
                      () => _showStatusDialog(r, provider)),
                if (r.status != ReceiptStatus.completed && r.status != ReceiptStatus.cancelled)
                  const SizedBox(width: 4),
                _actionBtn(Icons.edit_rounded, 'Sửa', const Color(0xFFF59E0B), () => _showReceiptDialog(receipt: r)),
                const SizedBox(width: 4),
                _actionBtn(Icons.delete_outline_rounded, 'Xóa', const Color(0xFFEF4444), () => _confirmDelete(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DETAIL DIALOG
  // ═══════════════════════════════════════════════
  void _showDetailDialog(WarehouseReceiptModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: Color(0xFF7C3AED), size: 22),
            SizedBox(width: 8),
            Text('Chi tiết phiếu kho', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : const Color(0xFF111827))),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('Mã phiếu', r.code),
                _detailRow('Loại', r.typeLabel),
                _detailRow('Trạng thái', r.statusLabel),
                _detailRow('Kho', r.warehouse),
                if (r.type == ReceiptType.transfer) _detailRow('Kho đến', r.toWarehouse),
                _detailRow('Tổng SL', r.totalQty.toString()),
                _detailRow('Áp kho', r.stockEffected ? 'Có' : 'Không'),
                _detailRow('Ghi chú', r.note.isNotEmpty ? r.note : '—'),
                _detailRow('Ngày tạo', _fmtDate(r.createdAt)),
                _detailRow('Cập nhật', _fmtDate(r.updatedAt)),
                _detailRow('Người tạo', r.createdBy.isNotEmpty ? r.createdBy : '—'),
                _detailRow('Người sửa', r.updatedBy.isNotEmpty ? r.updatedBy : '—'),
                SizedBox(height: 12),
                Text('Danh sách sản phẩm (${r.items.length})',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : const Color(0xFF111827))),
                const SizedBox(height: 8),
                if (r.items.isEmpty)
                  Text('Chưa có sản phẩm', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
                ...r.items.asMap().entries.map((e) {
                  final item = e.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Text('${e.key + 1}.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.productName.isNotEmpty ? item.productName : 'Sản phẩm',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : const Color(0xFF111827))),
                              if (item.sku.isNotEmpty)
                                Text('SKU: ${item.sku}', style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
                            ],
                          ),
                        ),
                        Text('x${item.quantity}',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Đóng'))],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110,
              child: Text(label, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280), fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white : const Color(0xFF111827), fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // STATUS UPDATE DIALOG
  // ═══════════════════════════════════════════════
  void _showStatusDialog(WarehouseReceiptModel r, WarehouseReceiptProvider provider) {
    ReceiptStatus newStatus = r.status;
    final noteCtrl = TextEditingController();

    List<ReceiptStatus> nextStatuses;
    switch (r.status) {
      case ReceiptStatus.draft:
        nextStatuses = [ReceiptStatus.processing, ReceiptStatus.cancelled];
        break;
      case ReceiptStatus.processing:
        nextStatuses = [ReceiptStatus.completed, ReceiptStatus.cancelled];
        break;
      default:
        nextStatuses = [];
    }
    if (nextStatuses.isEmpty) return;
    newStatus = nextStatuses.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cập nhật trạng thái', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phiếu: ${r.code}', style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
                SizedBox(height: 4),
                Text('Hiện tại: ${r.statusLabel}', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF))),
                const SizedBox(height: 14),
                Text('Chọn trạng thái mới:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: nextStatuses.map((s) {
                    final label = _receiptStatusLabel(s);
                    final isSelected = s == newStatus;
                    final c = _statusColor(s);
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => setS(() => newStatus = s),
                      selectedColor: c.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? c : (isDarkMode ? Colors.white70 : const Color(0xFF374151)),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 13,
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 14),
                TextField(
                  controller: noteCtrl, maxLines: 2,
                  style: TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    labelStyle: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hủy')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await provider.updateStatus(r.id, newStatus, note: noteCtrl.text.trim());
                if (!mounted) return;
                ok ? AppSnackBar.success(context, 'Đã cập nhật trạng thái') : AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _statusColor(newStatus), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // CREATE / EDIT DIALOG — Multi-product + Variants
  // ═══════════════════════════════════════════════
  void _showReceiptDialog({WarehouseReceiptModel? receipt}) {
    final isEdit = receipt != null;
    ReceiptType type = receipt?.type ?? ReceiptType.stockIn;
    final warehouseCtrl = TextEditingController(text: receipt?.warehouse ?? '');
    final toWarehouseCtrl = TextEditingController(text: receipt?.toWarehouse ?? '');
    final noteCtrl = TextEditingController(text: receipt?.note ?? '');
    final searchCtrl = TextEditingController();

    // All products fetched from Firestore
    List<Product> allProducts = [];
    bool isLoadingProducts = true;

    // Selected products: productId → { product, expanded, variantQuantities: {variantIndex → qty} }
    // Also support a "whole product" quantity for products without variants
    final Map<String, _SelectedProduct> selectedProducts = {};

    // Pre-populate from existing receipt items (edit mode)
    // We'll match them after products are loaded
    final List<ReceiptItem> existingItems = List.from(receipt?.items ?? []);

    String searchQuery = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          // Load products once
          if (isLoadingProducts && allProducts.isEmpty) {
            ProductService().getAllProducts().then((products) {
              setS(() {
                allProducts = products;
                isLoadingProducts = false;
                // Pre-populate selected products from existing items
                if (existingItems.isNotEmpty) {
                  _populateFromExistingItems(existingItems, allProducts, selectedProducts);
                }
              });
            }).catchError((_) {
              setS(() => isLoadingProducts = false);
            });
          }

          // Filter for search dropdown
          final filteredProducts = searchQuery.isEmpty
              ? <Product>[]
              : allProducts.where((p) {
                  final q = searchQuery.toLowerCase();
                  return (p.name.toLowerCase().contains(q) ||
                          p.sku.toLowerCase().contains(q)) &&
                      !selectedProducts.containsKey(p.id);
                }).take(8).toList();

          // Count total items
          int totalVariantCount = 0;
          for (final sp in selectedProducts.values) {
            totalVariantCount += sp.variantQuantities.values.where((q) => q > 0).length;
            if (sp.wholeQty > 0) totalVariantCount++;
          }

          return AlertDialog(
            backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  isEdit ? Icons.edit_rounded : Icons.add_box_rounded,
                  color: const Color(0xFF7C3AED), size: 22,
                ),
                const SizedBox(width: 8),
                Text(isEdit ? 'Sửa phiếu kho' : 'Tạo phiếu kho mới',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            content: SizedBox(
              width: 680,
              height: 600,
              child: Column(
                children: [
                  // ─── TOP FORM FIELDS (non-scrollable) ───
                  Row(
                    children: [
                      // Receipt type chips
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Loại phiếu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: ReceiptType.values.map((t) {
                                final isSelected = t == type;
                                final c = _typeColor(t);
                                return ChoiceChip(
                                  label: Text(_receiptTypeLabel(t)),
                                  selected: isSelected,
                                  onSelected: isEdit ? null : (_) => setS(() => type = t),
                                  selectedColor: c.withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    color: isSelected ? c : (isDarkMode ? Colors.white70 : const Color(0xFF374151)),
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 11,
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Warehouse + note row
                  Row(
                    children: [
                      Expanded(child: _dialogField('Kho', warehouseCtrl, 'Tên kho (VD: Kho HN)')),
                      if (type == ReceiptType.transfer) ...[
                        const SizedBox(width: 12),
                        Expanded(child: _dialogField('Kho đến', toWarehouseCtrl, 'Kho nhận hàng')),
                      ],
                      const SizedBox(width: 12),
                      Expanded(child: _dialogField('Ghi chú', noteCtrl, 'Ghi chú', maxLines: 1)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ─── PRODUCT SEARCH ───
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.search_rounded, size: 16, color: const Color(0xFF7C3AED)),
                          const SizedBox(width: 6),
                          Text('Tìm & thêm sản phẩm',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : const Color(0xFF111827))),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${selectedProducts.length} SP · $totalVariantCount dòng',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: searchCtrl,
                              style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : const Color(0xFF111827)),
                              decoration: InputDecoration(
                                hintText: isLoadingProducts ? 'Đang tải sản phẩm...' : 'Gõ tên sản phẩm để tìm...',
                                hintStyle: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                prefixIcon: Icon(Icons.inventory_2_outlined, size: 18,
                                    color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                isDense: true,
                              ),
                              onChanged: (v) => setS(() => searchQuery = v.trim()),
                            ),
                            // Search results
                            if (filteredProducts.isNotEmpty)
                              Container(
                                constraints: const BoxConstraints(maxHeight: 160),
                                decoration: BoxDecoration(
                                  border: Border(top: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB))),
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  itemCount: filteredProducts.length,
                                  itemBuilder: (_, i) {
                                    final p = filteredProducts[i];
                                    return InkWell(
                                      onTap: () {
                                        setS(() {
                                          selectedProducts[p.id] = _SelectedProduct(
                                            product: p,
                                            expanded: true,
                                          );
                                          searchCtrl.clear();
                                          searchQuery = '';
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          border: Border(bottom: BorderSide(
                                            color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6),
                                          )),
                                        ),
                                        child: Row(
                                          children: [
                                            // Product thumbnail
                                            Container(
                                              width: 36, height: 36,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(6),
                                                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                                  ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Icon(Icons.image, size: 16, color: Colors.grey))
                                                  : Icon(Icons.image, size: 16, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                                      color: isDarkMode ? Colors.white : const Color(0xFF111827)),
                                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  Text(
                                                    '${p.variants.length} biến thể · Tồn: ${p.stock}',
                                                    style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(Icons.add_circle_outline_rounded, size: 18, color: const Color(0xFF10B981)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // ─── SELECTED PRODUCTS (scrollable) ───
                  Expanded(
                    child: selectedProducts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inventory_2_outlined, size: 40,
                                    color: isDarkMode ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFD1D5DB)),
                                const SizedBox(height: 8),
                                Text('Chưa chọn sản phẩm nào',
                                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF))),
                                Text('Tìm kiếm ở trên để thêm sản phẩm',
                                    style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white24 : const Color(0xFFD1D5DB))),
                              ],
                            ),
                          )
                        : ListView(
                            children: selectedProducts.entries.map((entry) {
                              final sp = entry.value;
                              final p = sp.product;
                              final hasVariants = p.variants.isNotEmpty;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF9FAFB),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: sp.expanded
                                        ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                                        : (isDarkMode ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    // ── Product header ──
                                    InkWell(
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                                      onTap: () => setS(() => sp.expanded = !sp.expanded),
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Row(
                                          children: [
                                            // Thumbnail
                                            Container(
                                              width: 38, height: 38,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFE5E7EB),
                                              ),
                                              clipBehavior: Clip.antiAlias,
                                              child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                                  ? Image.network(p.imageUrl!, fit: BoxFit.cover,
                                                      errorBuilder: (_, __, ___) => Icon(Icons.image, size: 16, color: Colors.grey))
                                                  : Icon(Icons.image, size: 16, color: Colors.grey),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(p.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                                      color: isDarkMode ? Colors.white : const Color(0xFF111827)),
                                                      maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  Row(
                                                    children: [
                                                      if (p.sku.isNotEmpty)
                                                        Text('SKU: ${p.sku}  ·  ', style: TextStyle(fontSize: 10,
                                                            color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF))),
                                                      Text(
                                                        hasVariants
                                                            ? '${p.variants.length} biến thể'
                                                            : 'Không có biến thể',
                                                        style: TextStyle(fontSize: 10,
                                                            color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Qty badge
                                            _buildQtyBadge(sp),
                                            const SizedBox(width: 6),
                                            // Expand/collapse
                                            Icon(
                                              sp.expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                              size: 20, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280),
                                            ),
                                            const SizedBox(width: 4),
                                            // Remove product
                                            InkWell(
                                              onTap: () => setS(() => selectedProducts.remove(entry.key)),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Icon(Icons.close_rounded, size: 14, color: Color(0xFFEF4444)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // ── Variant list (expandable) ──
                                    if (sp.expanded) ...[
                                      Container(
                                        width: double.infinity,
                                        height: 1,
                                        color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB),
                                      ),
                                      if (hasVariants)
                                        // Variant rows
                                        ...p.variants.asMap().entries.map((ve) {
                                          final vIdx = ve.key;
                                          final v = ve.value;
                                          final qty = sp.variantQuantities[vIdx] ?? 0;
                                          final qtyCtrl = TextEditingController(text: qty > 0 ? qty.toString() : '');
                                          // Keep cursor at end
                                          qtyCtrl.selection = TextSelection.fromPosition(
                                              TextPosition(offset: qtyCtrl.text.length));

                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: qty > 0
                                                  ? const Color(0xFF7C3AED).withValues(alpha: isDarkMode ? 0.08 : 0.04)
                                                  : Colors.transparent,
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: isDarkMode ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6),
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                // Color indicator
                                                if (v.colorHex != null && v.colorHex!.isNotEmpty)
                                                  Container(
                                                    width: 14, height: 14,
                                                    margin: const EdgeInsets.only(right: 8),
                                                    decoration: BoxDecoration(
                                                      color: _parseColor(v.colorHex!),
                                                      borderRadius: BorderRadius.circular(4),
                                                      border: Border.all(color: Colors.black12),
                                                    ),
                                                  )
                                                else
                                                  const SizedBox(width: 22),
                                                // Variant label
                                                Expanded(
                                                  flex: 3,
                                                  child: Text(
                                                    '${v.color} · ${v.size}',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                                                        color: isDarkMode ? Colors.white : const Color(0xFF111827)),
                                                  ),
                                                ),
                                                // SKU
                                                Expanded(
                                                  flex: 2,
                                                  child: Text(
                                                    v.sku.isNotEmpty ? v.sku : '—',
                                                    style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                                  ),
                                                ),
                                                // Current stock
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF3F4F6),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Tồn: ${v.stock}',
                                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                                                        color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280)),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                // Quantity input
                                                SizedBox(
                                                  width: 70,
                                                  height: 30,
                                                  child: TextField(
                                                    controller: qtyCtrl,
                                                    keyboardType: TextInputType.number,
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                                        color: isDarkMode ? Colors.white : const Color(0xFF111827)),
                                                    decoration: InputDecoration(
                                                      hintText: '0',
                                                      hintStyle: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white24 : const Color(0xFFD1D5DB)),
                                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                      enabledBorder: OutlineInputBorder(
                                                        borderRadius: BorderRadius.circular(6),
                                                        borderSide: BorderSide(
                                                          color: qty > 0
                                                              ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
                                                              : (isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
                                                        ),
                                                      ),
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                      isDense: true,
                                                    ),
                                                    onChanged: (val) {
                                                      setS(() {
                                                        sp.variantQuantities[vIdx] = int.tryParse(val) ?? 0;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      if (!hasVariants)
                                        // No variants — show single quantity input
                                        Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              Icon(Icons.inventory_rounded, size: 16,
                                                  color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                              const SizedBox(width: 8),
                                              Text('Số lượng nhập/xuất:',
                                                  style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : const Color(0xFF374151))),
                                              const SizedBox(width: 12),
                                              SizedBox(
                                                width: 80,
                                                height: 32,
                                                child: TextField(
                                                  controller: TextEditingController(text: sp.wholeQty > 0 ? sp.wholeQty.toString() : ''),
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                                  decoration: InputDecoration(
                                                    hintText: '0',
                                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                    isDense: true,
                                                  ),
                                                  onChanged: (val) => setS(() => sp.wholeQty = int.tryParse(val) ?? 0),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text('Tồn kho: ${p.stock}',
                                                  style: TextStyle(fontSize: 11,
                                                      color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF))),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
              ElevatedButton.icon(
                onPressed: () async {
                  if (warehouseCtrl.text.trim().isEmpty) {
                    AppSnackBar.error(context, 'Vui lòng nhập tên kho');
                    return;
                  }
                  // Flatten selected products → ReceiptItem list
                  final items = _flattenToReceiptItems(selectedProducts);
                  if (items.isEmpty) {
                    AppSnackBar.error(context, 'Vui lòng nhập số lượng cho ít nhất 1 biến thể');
                    return;
                  }

                  final now = DateTime.now();
                  final model = WarehouseReceiptModel(
                    id: receipt?.id ?? '',
                    code: receipt?.code ?? '',
                    type: type,
                    status: receipt?.status ?? ReceiptStatus.draft,
                    warehouse: warehouseCtrl.text.trim(),
                    toWarehouse: toWarehouseCtrl.text.trim(),
                    note: noteCtrl.text.trim(),
                    items: items,
                    stockEffected: receipt?.stockEffected ?? false,
                    createdAt: receipt?.createdAt ?? now,
                    updatedAt: now,
                    createdBy: receipt?.createdBy ?? '',
                    updatedBy: '',
                  );
                  Navigator.pop(ctx);
                  final provider = Provider.of<WarehouseReceiptProvider>(context, listen: false);
                  final ok = isEdit ? await provider.updateReceipt(model) : await provider.createReceipt(model);
                  if (!mounted) return;
                  ok ? AppSnackBar.success(context, isEdit ? 'Đã cập nhật' : 'Đã tạo phiếu kho')
                      : AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
                },
                icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                label: Text(isEdit ? 'Lưu' : 'Tạo phiếu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Flatten selected products with variant quantities into ReceiptItem list
  List<ReceiptItem> _flattenToReceiptItems(Map<String, _SelectedProduct> selected) {
    final items = <ReceiptItem>[];
    for (final sp in selected.values) {
      final p = sp.product;
      if (p.variants.isNotEmpty) {
        for (final entry in sp.variantQuantities.entries) {
          final qty = entry.value;
          if (qty <= 0) continue;
          final v = p.variants[entry.key];
          items.add(ReceiptItem(
            productId: p.id,
            productName: '${p.name} - ${v.color}/${v.size}',
            sku: v.sku,
            quantity: qty,
          ));
        }
      } else if (sp.wholeQty > 0) {
        items.add(ReceiptItem(
          productId: p.id,
          productName: p.name,
          sku: p.sku,
          quantity: sp.wholeQty,
        ));
      }
    }
    return items;
  }

  /// Pre-populate selectedProducts from existing receipt items (edit mode)
  void _populateFromExistingItems(
    List<ReceiptItem> items,
    List<Product> allProducts,
    Map<String, _SelectedProduct> selected,
  ) {
    for (final item in items) {
      if (item.productId.isEmpty) continue;
      // Find product
      final pIdx = allProducts.indexWhere((p) => p.id == item.productId);
      if (pIdx < 0) continue;
      final p = allProducts[pIdx];

      // Ensure _SelectedProduct exists
      final sp = selected.putIfAbsent(p.id, () => _SelectedProduct(product: p, expanded: false));

      if (p.variants.isNotEmpty) {
        // Try to match variant by SKU
        for (var vi = 0; vi < p.variants.length; vi++) {
          if (p.variants[vi].sku == item.sku) {
            sp.variantQuantities[vi] = item.quantity;
            break;
          }
        }
      } else {
        sp.wholeQty = item.quantity;
      }
    }
  }

  Widget _buildQtyBadge(_SelectedProduct sp) {
    int total = 0;
    for (final q in sp.variantQuantities.values) {
      if (q > 0) total += q;
    }
    total += sp.wholeQty;
    if (total <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'x$total',
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.grey;
    }
  }

  Widget _dialogField(String label, TextEditingController ctrl, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        TextField(
          controller: ctrl, maxLines: maxLines,
          style: TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // DELETE CONFIRM
  // ═══════════════════════════════════════════════
  Future<void> _confirmDelete(WarehouseReceiptModel r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xóa phiếu kho?'),
        content: Text('Bạn chắc chắn muốn xóa phiếu "${r.code}"?\nPhiếu sẽ được xóa mềm.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = Provider.of<WarehouseReceiptProvider>(context, listen: false);
    final ok = await provider.deleteReceipt(r.id);
    if (!mounted) return;
    ok ? AppSnackBar.success(context, 'Đã xóa') : AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
  }

  // ═══════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════
  Color _typeColor(ReceiptType t) {
    switch (t) {
      case ReceiptType.stockIn: return const Color(0xFF10B981);
      case ReceiptType.stockOut: return const Color(0xFFF59E0B);
      case ReceiptType.transfer: return const Color(0xFF3B82F6);
      case ReceiptType.stockCheck: return const Color(0xFF8B5CF6);
    }
  }

  Color _statusColor(ReceiptStatus s) {
    switch (s) {
      case ReceiptStatus.draft: return const Color(0xFF6B7280);
      case ReceiptStatus.processing: return const Color(0xFFF59E0B);
      case ReceiptStatus.completed: return const Color(0xFF10B981);
      case ReceiptStatus.cancelled: return const Color(0xFFEF4444);
    }
  }

  String _receiptTypeLabel(ReceiptType t) {
    switch (t) {
      case ReceiptType.stockIn: return 'Nhập kho';
      case ReceiptType.stockOut: return 'Xuất kho';
      case ReceiptType.transfer: return 'Chuyển kho';
      case ReceiptType.stockCheck: return 'Kiểm kho';
    }
  }

  String _receiptStatusLabel(ReceiptStatus s) {
    switch (s) {
      case ReceiptStatus.draft: return 'Nháp';
      case ReceiptStatus.processing: return 'Đang xử lý';
      case ReceiptStatus.completed: return 'Hoàn tất';
      case ReceiptStatus.cancelled: return 'Đã hủy';
    }
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }

  String _fmtNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

/// Internal helper to track a selected product and its variant quantities
class _SelectedProduct {
  final Product product;
  bool expanded;
  /// variantIndex → quantity
  final Map<int, int> variantQuantities;
  /// For products without variants
  int wholeQty;

  _SelectedProduct({
    required this.product,
    this.expanded = false,
    Map<int, int>? variantQuantities,
    this.wholeQty = 0,
  }) : variantQuantities = variantQuantities ?? {};
}
