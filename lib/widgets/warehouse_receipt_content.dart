import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/admin_enums.dart';
import '../models/warehouse_receipt_model.dart';
import '../providers/warehouse_receipt_provider.dart';
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
  // CREATE / EDIT DIALOG
  // ═══════════════════════════════════════════════
  void _showReceiptDialog({WarehouseReceiptModel? receipt}) {
    final isEdit = receipt != null;
    ReceiptType type = receipt?.type ?? ReceiptType.stockIn;
    final warehouseCtrl = TextEditingController(text: receipt?.warehouse ?? '');
    final toWarehouseCtrl = TextEditingController(text: receipt?.toWarehouse ?? '');
    final noteCtrl = TextEditingController(text: receipt?.note ?? '');
    List<ReceiptItem> items = List.from(receipt?.items ?? []);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          return AlertDialog(
            backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(isEdit ? 'Sửa phiếu kho' : 'Tạo phiếu kho mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            content: SizedBox(
              width: 520,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Loại phiếu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
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
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400, fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    _dialogField('Kho', warehouseCtrl, 'Tên kho (VD: Kho Hà Nội)'),
                    if (type == ReceiptType.transfer) ...[
                      const SizedBox(height: 12),
                      _dialogField('Kho đến', toWarehouseCtrl, 'Kho nhận hàng'),
                    ],
                    const SizedBox(height: 12),
                    _dialogField('Ghi chú', noteCtrl, 'Ghi chú phiếu kho', maxLines: 2),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text('Sản phẩm (${items.length})',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => setS(() => items.add(const ReceiptItem())),
                          icon: Icon(Icons.add_rounded, size: 16),
                          label: Text('Thêm SP', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF7C3AED),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ...items.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value;
                      final nameCtrl = TextEditingController(text: item.productName);
                      final skuCtrl = TextEditingController(text: item.sku);
                      final qtyCtrl = TextEditingController(text: item.quantity > 0 ? item.quantity.toString() : '');
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
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: nameCtrl,
                                style: TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Tên sản phẩm',
                                  hintStyle: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (v) => items[idx] = items[idx].copyWith(productName: v),
                              ),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: skuCtrl,
                                style: TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'SKU',
                                  hintStyle: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (v) => items[idx] = items[idx].copyWith(sku: v),
                              ),
                            ),
                            SizedBox(width: 6),
                            SizedBox(
                              width: 70,
                              child: TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'SL',
                                  hintStyle: TextStyle(fontSize: 11, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                  isDense: true,
                                ),
                                onChanged: (v) => items[idx] = items[idx].copyWith(quantity: int.tryParse(v) ?? 0),
                              ),
                            ),
                            const SizedBox(width: 4),
                            InkWell(
                              onTap: () => setS(() => items.removeAt(idx)),
                              child: Icon(Icons.close_rounded, size: 18, color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hủy')),
              ElevatedButton.icon(
                onPressed: () async {
                  if (warehouseCtrl.text.trim().isEmpty) {
                    AppSnackBar.error(context, 'Vui lòng nhập tên kho');
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
