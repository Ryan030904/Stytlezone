import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rma_model.dart';
import '../providers/rma_provider.dart';
import '../constants/admin_enums.dart';
import '../utils/app_snackbar.dart';
import 'app_state_widgets.dart';

class RmaContent extends StatefulWidget {
  const RmaContent({super.key});
  @override
  State<RmaContent> createState() => _RmaContentState();
}

class _RmaContentState extends State<RmaContent> {
  int _selectedFilter = 0;
  String _searchQuery = '';
  static const _filters = ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Đang xử lý', 'Hoàn tất', 'Từ chối'];

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtMoney(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<RmaProvider>(context, listen: false).loadRmas(),
    );
  }

  List<RmaModel> _applyFilters(List<RmaModel> all) {
    var list = all.toList();
    switch (_selectedFilter) {
      case 1:
        list = list.where((r) => r.status == RmaStatus.pendingReview).toList();
        break;
      case 2:
        list = list.where((r) => r.status == RmaStatus.approved).toList();
        break;
      case 3:
        list = list.where((r) => r.status == RmaStatus.processing).toList();
        break;
      case 4:
        list = list.where((r) => r.status == RmaStatus.completed).toList();
        break;
      case 5:
        list = list.where((r) => r.status == RmaStatus.rejected).toList();
        break;
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
          r.code.toLowerCase().contains(q) ||
          r.orderCode.toLowerCase().contains(q) ||
          r.customerName.toLowerCase().contains(q) ||
          r.customerPhone.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<RmaProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.rmas.isEmpty) {
          return const AppLoadingState(message: 'Đang tải phiếu đổi trả...');
        }
        if (provider.errorMessage != null && provider.rmas.isEmpty) {
          return AppErrorState(
            message: provider.errorMessage!,
            onRetry: () => provider.loadRmas(),
          );
        }
        final all = provider.rmas;
        final filtered = _applyFilters(all);
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(isDark, all),
                    const SizedBox(height: 24),
                    _statsRow(isDark, all),
                    const SizedBox(height: 24),
                    _toolbar(isDark),
                    const SizedBox(height: 16),
                    if (filtered.isEmpty)
                      const AppEmptyState(
                        title: 'Không có phiếu đổi trả',
                        message: 'Chưa có phiếu đổi trả nào phù hợp với bộ lọc.',
                        icon: Icons.swap_horiz_outlined,
                      )
                    else
                      _table(isDark, filtered, provider),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════
  Widget _header(bool isDark, List<RmaModel> all) {
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Đổi trả / Hoàn tiền (RMA)',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: tp)),
              const SizedBox(height: 4),
              Text('Quản lý ${all.length} phiếu đổi trả từ Firestore',
                  style: TextStyle(fontSize: 14, color: ts)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => _showRmaDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Tạo phiếu đổi trả'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════
  Widget _statsRow(bool isDark, List<RmaModel> all) {
    final pending = all.where((r) => r.status == RmaStatus.pendingReview).length;
    final processing = all.where((r) => r.status == RmaStatus.processing || r.status == RmaStatus.approved).length;
    final completed = all.where((r) => r.status == RmaStatus.completed).length;
    final totalRefund = all.where((r) => r.status == RmaStatus.completed).fold(0.0, (s, r) => s + r.refundAmount);
    return Row(
      children: [
        Expanded(child: _statCard(isDark, 'Tổng phiếu', '${all.length}', Icons.swap_horiz_rounded, const Color(0xFF7C3AED))),
        const SizedBox(width: 16),
        Expanded(child: _statCard(isDark, 'Chờ duyệt', '$pending', Icons.pending_actions_rounded, const Color(0xFFF59E0B))),
        const SizedBox(width: 16),
        Expanded(child: _statCard(isDark, 'Đang xử lý', '$processing', Icons.autorenew_rounded, const Color(0xFF3B82F6))),
        const SizedBox(width: 16),
        Expanded(child: _statCard(isDark, 'Hoàn tất', '$completed', Icons.check_circle_rounded, const Color(0xFF10B981))),
        const SizedBox(width: 16),
        Expanded(child: _statCard(isDark, 'Tổng hoàn tiền', _fmtMoney(totalRefund), Icons.payments_rounded, const Color(0xFFEF4444))),
      ],
    );
  }

  Widget _statCard(bool isDark, String label, String value, IconData icon, Color color) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827)),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(label,
                    style: TextStyle(fontSize: 12,
                        color: isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280)),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TOOLBAR
  // ═══════════════════════════════════════════
  Widget _toolbar(bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr),
      ),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 280,
            height: 40,
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Tìm mã RMA, đơn hàng, khách hàng...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Filters
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_filters.length, (i) {
                  final selected = _selectedFilter == i;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filters[i], style: TextStyle(
                          fontSize: 12,
                          color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF374151)),
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                      selected: selected,
                      selectedColor: const Color(0xFF7C3AED),
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6),
                      side: BorderSide.none,
                      onSelected: (_) => setState(() => _selectedFilter = i),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TABLE
  // ═══════════════════════════════════════════
  Widget _table(bool isDark, List<RmaModel> list, RmaProvider provider) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final headerColor = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    return Container(
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                _hdr('Mã RMA', 2, headerColor),
                _hdr('Khách hàng', 2, headerColor),
                _hdr('Đơn hàng', 2, headerColor),
                _hdr('Loại', 2, headerColor),
                _hdr('Lý do', 2, headerColor),
                _hdr('Trạng thái', 2, headerColor),
                _hdr('Hoàn tiền', 2, headerColor),
                _hdr('Ngày tạo', 2, headerColor),
                _hdr('Thao tác', 2, headerColor),
              ],
            ),
          ),
          ...list.map((r) => _row(r, isDark, provider)),
        ],
      ),
    );
  }

  Widget _hdr(String t, int flex, Color c) => Expanded(
        flex: flex,
        child: Text(t,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)));

  Widget _row(RmaModel r, bool isDark, RmaProvider provider) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7280);
    final statusColor = _statusColor(r.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bdr))),
      child: Row(
        children: [
          // Mã RMA
          Expanded(
            flex: 2,
            child: Text(r.code.isNotEmpty ? r.code : r.id.substring(0, 8),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
          ),
          // Khách hàng
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Text(r.customerName.isNotEmpty ? r.customerName : '—',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: tp, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
                if (r.customerPhone.isNotEmpty)
                  Text(r.customerPhone,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: ts)),
              ],
            ),
          ),
          // Đơn hàng
          Expanded(
            flex: 2,
            child: Text(r.orderCode.isNotEmpty ? r.orderCode : (r.orderId.isNotEmpty ? r.orderId.substring(0, 8) : '—'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: ts)),
          ),
          // Loại
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: (r.type == RmaType.exchange ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B)).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(r.typeLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600,
                      color: r.type == RmaType.exchange ? const Color(0xFF3B82F6) : const Color(0xFFF59E0B))),
            ),
          ),
          // Lý do
          Expanded(
            flex: 2,
            child: Text(r.reasonLabel, textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: ts), overflow: TextOverflow.ellipsis),
          ),
          // Trạng thái
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(r.statusLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w600)),
            ),
          ),
          // Hoàn tiền
          Expanded(
            flex: 2,
            child: Text(r.refundAmount > 0 ? _fmtMoney(r.refundAmount) : '—',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: r.refundAmount > 0 ? const Color(0xFF10B981) : ts)),
          ),
          // Ngày tạo
          Expanded(
            flex: 2,
            child: Text(_fmtDate(r.createdAt),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: ts)),
          ),
          // Thao tác
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionBtn(Icons.visibility_rounded, 'Xem chi tiết', const Color(0xFF3B82F6),
                    () => _showDetailDialog(r)),
                const SizedBox(width: 4),
                if (r.status != RmaStatus.completed && r.status != RmaStatus.rejected)
                  _actionBtn(Icons.check_circle_outline_rounded, 'Cập nhật trạng thái', const Color(0xFF10B981),
                      () => _showStatusDialog(r, provider)),
                const SizedBox(width: 4),
                _actionBtn(Icons.edit_rounded, 'Sửa', const Color(0xFFF59E0B),
                    () => _showRmaDialog(rma: r)),
                const SizedBox(width: 4),
                _actionBtn(Icons.delete_outline_rounded, 'Xóa', const Color(0xFFEF4444),
                    () => _confirmDelete(r)),
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
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Color _statusColor(RmaStatus status) {
    switch (status) {
      case RmaStatus.pendingReview:
        return const Color(0xFFF59E0B);
      case RmaStatus.approved:
        return const Color(0xFF3B82F6);
      case RmaStatus.processing:
        return const Color(0xFF8B5CF6);
      case RmaStatus.completed:
        return const Color(0xFF10B981);
      case RmaStatus.rejected:
        return const Color(0xFFEF4444);
    }
  }

  // ═══════════════════════════════════════════
  // DETAIL DIALOG
  // ═══════════════════════════════════════════
  void _showDetailDialog(RmaModel r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7280);
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB);
    final statusColor = _statusColor(r.status);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 700),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF7C3AED), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.code.isNotEmpty ? r.code : 'Phiếu đổi trả',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp)),
                          const SizedBox(height: 2),
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(r.statusLabel,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                            ),
                            const SizedBox(width: 8),
                            Text(r.typeLabel, style: TextStyle(fontSize: 12, color: ts)),
                          ]),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(Icons.close_rounded, color: ts),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Info sections
                _detailSection('Thông tin khách hàng', [
                  _detailRow('Tên', r.customerName, tp, ts),
                  _detailRow('SĐT', r.customerPhone, tp, ts),
                  _detailRow('Email', r.customerEmail, tp, ts),
                ], bg, isDark),
                const SizedBox(height: 12),

                _detailSection('Thông tin đơn hàng', [
                  _detailRow('Mã đơn hàng', r.orderCode.isNotEmpty ? r.orderCode : r.orderId, tp, ts),
                  _detailRow('Lý do', r.reasonLabel, tp, ts),
                  if (r.reasonNote.isNotEmpty) _detailRow('Chi tiết lý do', r.reasonNote, tp, ts),
                ], bg, isDark),
                const SizedBox(height: 12),

                // Items
                if (r.items.isNotEmpty) ...[
                  _detailSection('Sản phẩm đổi trả (${r.items.length})', [
                    ...r.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.productName, style: TextStyle(fontSize: 13, color: tp, fontWeight: FontWeight.w500)),
                                if (item.sku.isNotEmpty)
                                  Text('SKU: ${item.sku}', style: TextStyle(fontSize: 11, color: ts)),
                                if (item.reason.isNotEmpty)
                                  Text('Lý do: ${item.reason}', style: TextStyle(fontSize: 11, color: ts)),
                              ],
                            ),
                          ),
                          Text('x${item.quantity}', style: TextStyle(fontSize: 12, color: tp)),
                          const SizedBox(width: 12),
                          Text(_fmtMoney(item.totalPrice),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                        ],
                      ),
                    )),
                  ], bg, isDark),
                  const SizedBox(height: 12),
                ],

                _detailSection('Hoàn tiền & Xử lý', [
                  _detailRow('Số tiền hoàn', _fmtMoney(r.refundAmount), tp, ts),
                  if (r.refundMethod.isNotEmpty) _detailRow('Phương thức hoàn', r.refundMethod, tp, ts),
                  if (r.adminNote.isNotEmpty) _detailRow('Ghi chú admin', r.adminNote, tp, ts),
                  if (r.resolution.isNotEmpty) _detailRow('Kết quả xử lý', r.resolution, tp, ts),
                ], bg, isDark),
                const SizedBox(height: 12),

                _detailSection('Thông tin hệ thống', [
                  _detailRow('Ngày tạo', _fmtDate(r.createdAt), tp, ts),
                  _detailRow('Cập nhật', _fmtDate(r.updatedAt), tp, ts),
                  if (r.createdBy.isNotEmpty) _detailRow('Người tạo', r.createdBy, tp, ts),
                  if (r.updatedBy.isNotEmpty) _detailRow('Người cập nhật', r.updatedBy, tp, ts),
                ], bg, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children, Color bg, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF374151))),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color tp, Color ts) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(fontSize: 12, color: ts))),
          Expanded(child: Text(value.isNotEmpty ? value : '—',
              style: TextStyle(fontSize: 12, color: tp, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // STATUS UPDATE DIALOG
  // ═══════════════════════════════════════════
  void _showStatusDialog(RmaModel r, RmaProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    RmaStatus newStatus = r.status;
    final noteCtrl = TextEditingController();

    // Xác định các trạng thái tiếp theo hợp lệ
    List<RmaStatus> nextStatuses;
    switch (r.status) {
      case RmaStatus.pendingReview:
        nextStatuses = [RmaStatus.approved, RmaStatus.rejected];
        break;
      case RmaStatus.approved:
        nextStatuses = [RmaStatus.processing, RmaStatus.rejected];
        break;
      case RmaStatus.processing:
        nextStatuses = [RmaStatus.completed, RmaStatus.rejected];
        break;
      default:
        nextStatuses = [];
    }

    if (nextStatuses.isEmpty) return;
    newStatus = nextStatuses.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Cập nhật trạng thái',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827))),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phiếu: ${r.code}',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Hiện tại: ', style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: _statusColor(r.status).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(r.statusLabel,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(r.status))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Chuyển sang:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF111827))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: nextStatuses.map((s) {
                    final selected = newStatus == s;
                    final c = _statusColor(s);
                    return ChoiceChip(
                      label: Text(_statusLabelFromEnum(s)),
                      selected: selected,
                      selectedColor: c.withValues(alpha: 0.2),
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6),
                      labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                          color: selected ? c : (isDark ? Colors.white60 : const Color(0xFF6B7280))),
                      side: selected ? BorderSide(color: c) : BorderSide.none,
                      onSelected: (_) => setDialogState(() => newStatus = s),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy', style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final ok = await provider.updateStatus(r.id, newStatus, note: noteCtrl.text.trim());
                if (!mounted) return;
                if (ok) {
                  AppSnackBar.success(context, 'Đã cập nhật trạng thái thành công');
                } else {
                  AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi cập nhật');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _statusColor(newStatus),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Cập nhật'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabelFromEnum(RmaStatus s) {
    switch (s) {
      case RmaStatus.pendingReview: return 'Chờ duyệt';
      case RmaStatus.approved: return 'Duyệt';
      case RmaStatus.rejected: return 'Từ chối';
      case RmaStatus.processing: return 'Xử lý';
      case RmaStatus.completed: return 'Hoàn tất';
    }
  }

  // ═══════════════════════════════════════════
  // CREATE / EDIT DIALOG
  // ═══════════════════════════════════════════
  void _showRmaDialog({RmaModel? rma}) {
    final isEdit = rma != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final customerNameCtrl = TextEditingController(text: rma?.customerName ?? '');
    final customerPhoneCtrl = TextEditingController(text: rma?.customerPhone ?? '');
    final customerEmailCtrl = TextEditingController(text: rma?.customerEmail ?? '');
    final orderCodeCtrl = TextEditingController(text: rma?.orderCode ?? '');
    final reasonNoteCtrl = TextEditingController(text: rma?.reasonNote ?? '');
    final refundCtrl = TextEditingController(text: rma != null && rma.refundAmount > 0 ? rma.refundAmount.toStringAsFixed(0) : '');
    final adminNoteCtrl = TextEditingController(text: rma?.adminNote ?? '');

    RmaType type = rma?.type ?? RmaType.returnAndRefund;
    RmaReason reason = rma?.reason ?? RmaReason.other;
    String refundMethod = rma?.refundMethod ?? '';

    // Item controllers
    final itemNameCtrl = TextEditingController();
    final itemQtyCtrl = TextEditingController(text: '1');
    final itemPriceCtrl = TextEditingController();
    List<RmaItem> items = rma?.items.toList() ?? [];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          Widget field(String label, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboardType}) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: ctrl,
                maxLines: maxLines,
                keyboardType: keyboardType,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            );
          }

          Widget dropdown<T>(String label, T value, List<DropdownMenuItem<T>> items, void Function(T?) onChanged) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DropdownButtonFormField<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF7C3AED))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            );
          }

          return Dialog(
            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640, maxHeight: 780),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title bar
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      children: [
                        Icon(isEdit ? Icons.edit_rounded : Icons.add_rounded,
                            color: const Color(0xFF7C3AED), size: 22),
                        const SizedBox(width: 10),
                        Text(isEdit ? 'Sửa phiếu đổi trả' : 'Tạo phiếu đổi trả mới',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF111827))),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: Icon(Icons.close_rounded,
                              color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thông tin khách hàng
                          Text('Thông tin khách hàng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF374151))),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: field('Tên khách hàng *', customerNameCtrl)),
                            const SizedBox(width: 12),
                            Expanded(child: field('Số điện thoại', customerPhoneCtrl)),
                          ]),
                          field('Email', customerEmailCtrl),
                          const SizedBox(height: 8),

                          // Thông tin đổi trả
                          Text('Thông tin đổi trả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF374151))),
                          const SizedBox(height: 8),
                          field('Mã đơn hàng gốc', orderCodeCtrl),
                          Row(children: [
                            Expanded(
                              child: dropdown<RmaType>('Loại yêu cầu', type, [
                                const DropdownMenuItem(value: RmaType.returnAndRefund, child: Text('Trả hàng / Hoàn tiền')),
                                const DropdownMenuItem(value: RmaType.exchange, child: Text('Đổi hàng')),
                              ], (v) => setDialogState(() => type = v!)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: dropdown<RmaReason>('Lý do', reason, [
                                const DropdownMenuItem(value: RmaReason.wrongSize, child: Text('Sai kích thước')),
                                const DropdownMenuItem(value: RmaReason.wrongColor, child: Text('Sai màu sắc')),
                                const DropdownMenuItem(value: RmaReason.wrongItem, child: Text('Sai sản phẩm')),
                                const DropdownMenuItem(value: RmaReason.defective, child: Text('Hàng lỗi')),
                                const DropdownMenuItem(value: RmaReason.changedMind, child: Text('Đổi ý')),
                                const DropdownMenuItem(value: RmaReason.other, child: Text('Khác')),
                              ], (v) => setDialogState(() => reason = v!)),
                            ),
                          ]),
                          field('Chi tiết lý do', reasonNoteCtrl, maxLines: 2),
                          const SizedBox(height: 8),

                          // Sản phẩm
                          Text('Sản phẩm đổi trả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF374151))),
                          const SizedBox(height: 8),
                          ...items.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(child: Text(item.productName, style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)))),
                                  Text('x${item.quantity}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
                                  const SizedBox(width: 8),
                                  Text(_fmtMoney(item.totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: () => setDialogState(() => items.removeAt(i)),
                                    child: const Icon(Icons.close_rounded, size: 16, color: Color(0xFFEF4444)),
                                  ),
                                ],
                              ),
                            );
                          }),
                          // Thêm sản phẩm
                          Row(children: [
                            Expanded(flex: 3, child: TextField(
                              controller: itemNameCtrl,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
                              decoration: InputDecoration(
                                hintText: 'Tên sản phẩm',
                                hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                              ),
                            )),
                            const SizedBox(width: 8),
                            SizedBox(width: 60, child: TextField(
                              controller: itemQtyCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
                              decoration: InputDecoration(
                                hintText: 'SL',
                                hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                              ),
                            )),
                            const SizedBox(width: 8),
                            SizedBox(width: 100, child: TextField(
                              controller: itemPriceCtrl,
                              keyboardType: TextInputType.number,
                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
                              decoration: InputDecoration(
                                hintText: 'Đơn giá',
                                hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                                filled: true,
                                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFD1D5DB))),
                              ),
                            )),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                if (itemNameCtrl.text.trim().isEmpty) return;
                                setDialogState(() {
                                  items.add(RmaItem(
                                    productId: '',
                                    productName: itemNameCtrl.text.trim(),
                                    quantity: int.tryParse(itemQtyCtrl.text) ?? 1,
                                    unitPrice: double.tryParse(itemPriceCtrl.text) ?? 0,
                                  ));
                                  itemNameCtrl.clear();
                                  itemQtyCtrl.text = '1';
                                  itemPriceCtrl.clear();
                                });
                              },
                              icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF7C3AED)),
                            ),
                          ]),
                          const SizedBox(height: 12),

                          // Hoàn tiền
                          Text('Thông tin hoàn tiền', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : const Color(0xFF374151))),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: field('Số tiền hoàn (VNĐ)', refundCtrl, keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: dropdown<String>('Phương thức hoàn', refundMethod.isEmpty ? '' : refundMethod, [
                                const DropdownMenuItem(value: '', child: Text('Chọn...')),
                                const DropdownMenuItem(value: 'Tiền mặt', child: Text('Tiền mặt')),
                                const DropdownMenuItem(value: 'Chuyển khoản', child: Text('Chuyển khoản')),
                                const DropdownMenuItem(value: 'Hoàn gốc', child: Text('Hoàn về phương thức gốc')),
                              ], (v) => setDialogState(() => refundMethod = v ?? '')),
                            ),
                          ]),
                          field('Ghi chú admin', adminNoteCtrl, maxLines: 2),
                        ],
                      ),
                    ),
                  ),
                  // Actions bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(
                          color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Hủy', style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (customerNameCtrl.text.trim().isEmpty) {
                              AppSnackBar.error(context, 'Vui lòng nhập tên khách hàng');
                              return;
                            }
                            final now = DateTime.now();
                            final model = RmaModel(
                              id: rma?.id ?? '',
                              code: rma?.code ?? '',
                              orderId: rma?.orderId ?? '',
                              orderCode: orderCodeCtrl.text.trim(),
                              customerId: rma?.customerId ?? '',
                              customerName: customerNameCtrl.text.trim(),
                              customerPhone: customerPhoneCtrl.text.trim(),
                              customerEmail: customerEmailCtrl.text.trim(),
                              type: type,
                              status: rma?.status ?? RmaStatus.pendingReview,
                              reason: reason,
                              reasonNote: reasonNoteCtrl.text.trim(),
                              items: items,
                              refundAmount: double.tryParse(refundCtrl.text) ?? 0,
                              refundMethod: refundMethod,
                              adminNote: adminNoteCtrl.text.trim(),
                              resolution: rma?.resolution ?? '',
                              createdAt: rma?.createdAt ?? now,
                              updatedAt: now,
                              createdBy: rma?.createdBy ?? '',
                              updatedBy: '',
                            );
                            Navigator.pop(ctx);
                            final provider = Provider.of<RmaProvider>(context, listen: false);
                            bool ok;
                            if (isEdit) {
                              ok = await provider.updateRma(model);
                            } else {
                              ok = await provider.createRma(model);
                            }
                            if (!mounted) return;
                            if (ok) {
                              AppSnackBar.success(context, isEdit ? 'Đã cập nhật phiếu' : 'Đã tạo phiếu đổi trả');
                            } else {
                              AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
                            }
                          },
                          icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded, size: 18),
                          label: Text(isEdit ? 'Lưu thay đổi' : 'Tạo phiếu'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ═══════════════════════════════════════════
  // DELETE CONFIRM
  // ═══════════════════════════════════════════
  Future<void> _confirmDelete(RmaModel rma) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa phiếu đổi trả?'),
        content: Text('Bạn chắc chắn muốn xóa phiếu "${rma.code}"?\nPhiếu sẽ được xóa mềm.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = Provider.of<RmaProvider>(context, listen: false);
    final ok = await provider.deleteRma(rma.id);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã xóa phiếu đổi trả');
    } else {
      AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi xóa');
    }
  }
}
