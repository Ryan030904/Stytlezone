import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/admin_enums.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import '../utils/csv_export.dart';
import 'admin_slide_panel.dart';
import 'app_state_widgets.dart';

class PaymentContent extends StatefulWidget {
  const PaymentContent({super.key});

  @override
  State<PaymentContent> createState() => _PaymentContentState();
}

class _PaymentContentState extends State<PaymentContent> {
  bool get isDark => mounted ? Theme.of(context).brightness == Brightness.dark : false;
  final _searchCtrl = TextEditingController();

  // ── Slide Panel ──
  bool _isPanelOpen = false;
  PaymentModel? _selectedPayment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PaymentProvider>().loadInitial();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDetail(PaymentModel p) {
    setState(() {
      _selectedPayment = p;
      _isPanelOpen = true;
    });
  }

  void _closePanel() => setState(() => _isPanelOpen = false);

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, prov, _) {
        final payments = prov.payments;

        return AdminSlidePanel(
          isOpen: _isPanelOpen,
          title: 'Chi tiết thanh toán',
          onClose: _closePanel,
          panelBody: _buildDetailBody(prov),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(prov),
                const SizedBox(height: 20),
                if (payments.isNotEmpty) ...[
                  _buildStats(payments),
                  const SizedBox(height: 20),
                ],
                _buildContentCard(payments, prov),
              ],
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════
  Widget _buildHeader(PaymentProvider prov) {
    return Row(
      children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Thanh toán',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.textDark)),
            const SizedBox(height: 4),
            Text('Quản lý và theo dõi thanh toán đơn hàng',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : AppTheme.textLight)),
          ]),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: () => _exportCsv(prov),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Xuất CSV', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
  Widget _buildStats(List<PaymentModel> payments) {
    final total = payments.length;
    final totalAmount = payments.fold<double>(0, (s, p) => s + p.amount);
    final paid = payments.where((p) => p.status == PaymentStatus.paid || p.status == PaymentStatus.reconciled);
    final paidAmount = paid.fold<double>(0, (s, p) => s + p.amount);
    final pending = payments.where((p) => p.status == PaymentStatus.pending);
    final pendingAmount = pending.fold<double>(0, (s, p) => s + p.amount);
    final refunded = payments.fold<double>(0, (s, p) => s + p.refundedAmount);

    return Row(children: [
      _statCard('Tổng giao dịch', '$total', _money(totalAmount),
          Icons.receipt_long_rounded, const Color(0xFF7C3AED)),
      const SizedBox(width: 12),
      _statCard('Đã thanh toán', '${paid.length}', _money(paidAmount),
          Icons.check_circle_rounded, const Color(0xFF10B981)),
      const SizedBox(width: 12),
      _statCard('Chờ xử lý', '${pending.length}', _money(pendingAmount),
          Icons.schedule_rounded, const Color(0xFFF59E0B)),
      const SizedBox(width: 12),
      _statCard('Đã hoàn tiền', '', _money(refunded),
          Icons.replay_rounded, const Color(0xFF3B82F6)),
    ]);
  }

  Widget _statCard(String label, String count, String amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(amount,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827)),
                  overflow: TextOverflow.ellipsis),
              Row(children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
                if (count.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(count,
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CONTENT CARD (search + status tabs + table)
  // ═══════════════════════════════════════
  Widget _buildContentCard(List<PaymentModel> payments, PaymentProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header: search + filters ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Search
            TextField(
              controller: _searchCtrl,
              onChanged: prov.setSearchQuery,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Tìm mã đơn, khách hàng, SĐT...',
                hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFFBBBBBB)),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 14, right: 10),
                  child: Icon(Icons.search_rounded, size: 18,
                      color: isDark ? Colors.white30 : const Color(0xFFBBBBBB)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
              ),
            ),
            const SizedBox(height: 14),
            // Trạng thái filter row
            Row(children: [
              Text('Trạng thái:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF374151))),
              const SizedBox(width: 10),
              _statusPill(null, 'Tất cả', prov),
              _statusPill(PaymentStatus.pending, 'Chờ xử lý', prov),
              _statusPill(PaymentStatus.paid, 'Đã thanh toán', prov),
              _statusPill(PaymentStatus.failed, 'Thất bại', prov),
              _statusPill(PaymentStatus.refunded, 'Hoàn tiền', prov),
            ]),
            const SizedBox(height: 10),
            // Phương thức filter row
            Row(children: [
              Text('Phương thức:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF374151))),
              const SizedBox(width: 10),
              _methodFilter(prov),
            ]),
            const SizedBox(height: 14),
          ]),
        ),
        // ── Divider ──
        Divider(height: 1, thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0F0F0)),
        // ── Table ──
        _buildTable(payments, prov),
        // ── Load more ──
        if (prov.hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: OutlinedButton.icon(
                onPressed: prov.isLoadingMore ? null : () => prov.loadMore(),
                icon: prov.isLoadingMore
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.expand_more_rounded, size: 16),
                label: Text(prov.isLoadingMore ? 'Đang tải...' : 'Tải thêm',
                    style: const TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _statusPill(PaymentStatus? status, String label, PaymentProvider prov) {
    final isActive = prov.statusFilter == status;
    final color = status == null
        ? const Color(0xFF7C3AED)
        : _statusColor(status);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => prov.setStatusFilter(status),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isActive ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? color : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF374151)),
              )),
        ),
      ),
    );
  }

  Widget _methodFilter(PaymentProvider prov) {
    return PopupMenuButton<PaymentMethod?>(
      onSelected: (v) => prov.setMethodFilter(v),
      offset: const Offset(0, 34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      itemBuilder: (_) => [
        PopupMenuItem<PaymentMethod?>(value: null, height: 34,
            child: Text('Tất cả', style: TextStyle(fontSize: 12,
                fontWeight: prov.methodFilter == null ? FontWeight.w600 : FontWeight.w400,
                color: isDark ? Colors.white : const Color(0xFF111827)))),
        ...PaymentMethod.values.map((m) => PopupMenuItem<PaymentMethod?>(
            value: m, height: 34,
            child: Text(m.label, style: TextStyle(fontSize: 12,
                fontWeight: prov.methodFilter == m ? FontWeight.w600 : FontWeight.w400,
                color: isDark ? Colors.white : const Color(0xFF111827))))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: prov.methodFilter != null
              ? const Color(0xFF7C3AED).withValues(alpha: 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: prov.methodFilter != null
                ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(prov.methodFilter?.label ?? 'Tất cả',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                  color: prov.methodFilter != null
                      ? const Color(0xFF7C3AED)
                      : (isDark ? Colors.white70 : const Color(0xFF6B7280)))),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════
  // TABLE
  // ═══════════════════════════════════════
  Widget _buildTable(List<PaymentModel> payments, PaymentProvider prov) {
    if (payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined, size: 40,
              color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFD1D5DB)),
          const SizedBox(height: 10),
          Text('Không tìm thấy giao dịch', style: TextStyle(fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
        ])),
      );
    }

    return Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFB),
        child: Row(children: [
          _th('ĐƠN HÀNG', 2),
          _th('KHÁCH HÀNG', 2),
          _th('SỐ TIỀN', 2),
          _th('PHƯƠNG THỨC', 3),
          _th('TRẠNG THÁI', 3),
          _th('THỜI GIAN', 2),
          _th('THAO TÁC', 2),
        ]),
      ),
      ...payments.map((p) => _tableRow(p, prov)),
    ]);
  }

  Widget _th(String t, int flex) => Expanded(
      flex: flex,
      child: Text(t,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.5,
              color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))));

  Widget _tableRow(PaymentModel p, PaymentProvider prov) {
    final sc = _statusColor(p.status);
    final ln = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6);
    return InkWell(
      onTap: () => _openDetail(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ln))),
        child: Row(children: [
          // Mã đơn
          Expanded(flex: 2, child: Text(
              p.orderCode.isNotEmpty ? p.orderCode : p.orderId.substring(0, 8),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)))),
          // Khách hàng
          Expanded(flex: 2, child: Column(children: [
            Text(p.customerName.isNotEmpty ? p.customerName : '—', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF111827)),
                overflow: TextOverflow.ellipsis),
            if (p.customerPhone.isNotEmpty)
              Text(p.customerPhone, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
          ])),
          // Số tiền
          Expanded(flex: 2, child: Text(_money(p.amount), textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827)))),
          // Phương thức
          Expanded(flex: 3, child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(p.method.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF374151))),
          ))),
          // Trạng thái
          Expanded(flex: 3, child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: sc.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(p.status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc)),
          ))),
          // Thời gian
          Expanded(flex: 2, child: Text(_dateTime(p.paidAt ?? p.createdAt), textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)))),
          // Thao tác
          Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _actionBtn(Icons.visibility_rounded, 'Xem', const Color(0xFF3B82F6),
                () => _openDetail(p)),
            if (p.status == PaymentStatus.pending) ...[
              const SizedBox(width: 4),
              _actionBtn(Icons.check_rounded, 'Xác nhận', const Color(0xFF10B981),
                  () => _markPaid(prov, p)),
            ],
            if (p.status == PaymentStatus.paid) ...[
              const SizedBox(width: 4),
              _actionBtn(Icons.replay_rounded, 'Hoàn tiền', const Color(0xFFF59E0B),
                  () => _refund(prov, p)),
            ],
          ])),
        ]),
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
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: color),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // DETAIL PANEL
  // ═══════════════════════════════════════
  Widget _buildDetailBody(PaymentProvider prov) {
    final p = _selectedPayment;
    if (p == null) return const SizedBox.shrink();
    final sc = _statusColor(p.status);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Status badge
      Center(child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: sc.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(p.status.label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sc)),
      )),
      const SizedBox(height: 4),
      Center(child: Text(_money(p.amount),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827)))),
      const SizedBox(height: 20),

      _detailSection('Thông tin đơn hàng', [
        _detailRow('Mã đơn', p.orderCode.isNotEmpty ? p.orderCode : p.orderId),
        _detailRow('Phương thức', p.method.label),
        _detailRow('Nguồn', p.source),
        if (p.transactionId.isNotEmpty) _detailRow('Mã giao dịch', p.transactionId),
        if (p.bankName.isNotEmpty) _detailRow('Ngân hàng', p.bankName),
      ]),
      const SizedBox(height: 16),
      _detailSection('Khách hàng', [
        _detailRow('Tên', p.customerName.isNotEmpty ? p.customerName : '—'),
        _detailRow('SĐT', p.customerPhone.isNotEmpty ? p.customerPhone : '—'),
      ]),
      const SizedBox(height: 16),
      _detailSection('Thời gian', [
        _detailRow('Tạo lúc', _dateTime(p.createdAt)),
        if (p.paidAt != null) _detailRow('Thanh toán', _dateTime(p.paidAt!)),
        if (p.confirmedAt != null) _detailRow('Xác nhận', _dateTime(p.confirmedAt!)),
      ]),
      if (p.refundedAmount > 0) ...[
        const SizedBox(height: 16),
        _detailSection('Hoàn tiền', [
          _detailRow('Số tiền hoàn', _money(p.refundedAmount)),
          if (p.refundedAt != null) _detailRow('Hoàn lúc', _dateTime(p.refundedAt!)),
        ]),
      ],
      if (p.note.isNotEmpty) ...[
        const SizedBox(height: 16),
        _detailSection('Ghi chú', [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(p.note, style: TextStyle(fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF374151))),
          ),
        ]),
      ],
      const SizedBox(height: 24),
      // Actions
      if (p.status == PaymentStatus.pending)
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markPaid(prov, p),
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Xác nhận thanh toán', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _markFailed(prov, p),
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('Đánh dấu thất bại', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      if (p.status == PaymentStatus.paid)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _refund(prov, p),
            icon: const Icon(Icons.replay_rounded, size: 16),
            label: const Text('Hoàn tiền', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ),
    ]);
  }

  Widget _detailSection(String title, List<Widget> children) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
      const SizedBox(height: 6),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
      ),
    ]);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)))),
        Expanded(child: Text(value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF111827)))),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════
  Future<void> _syncOrders(PaymentProvider prov) async {
    await prov.syncFromOrders();
    if (!mounted) return;
    if (prov.errorMessage == null) {
      AppSnackBar.success(context, 'Đã đồng bộ thanh toán từ đơn hàng');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Đồng bộ thất bại');
    }
  }

  Future<void> _markPaid(PaymentProvider prov, PaymentModel p) async {
    final note = await _askNote('Xác nhận thanh toán', 'Ghi chú (không bắt buộc)');
    if (note == null) return;
    final ok = await prov.markAsPaid(paymentId: p.id, note: note);
    if (!mounted) return;
    if (ok) {
      _closePanel();
      AppSnackBar.success(context, 'Đã xác nhận thanh toán');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
    }
  }

  Future<void> _markFailed(PaymentProvider prov, PaymentModel p) async {
    final note = await _askNote('Đánh dấu thất bại', 'Lý do thất bại');
    if (note == null) return;
    final ok = await prov.markAsFailed(paymentId: p.id, note: note);
    if (!mounted) return;
    if (ok) {
      _closePanel();
      AppSnackBar.success(context, 'Đã đánh dấu thất bại');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
    }
  }

  Future<void> _refund(PaymentProvider prov, PaymentModel p) async {
    final result = await _askRefund(p.amount);
    if (result == null) return;
    final ok = await prov.refund(paymentId: p.id, amount: result.$1, note: result.$2);
    if (!mounted) return;
    if (ok) {
      _closePanel();
      AppSnackBar.success(context, 'Hoàn tiền thành công');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
    }
  }

  Future<void> _exportCsv(PaymentProvider prov) async {
    final rows = await prov.exportCurrentFilter();
    if (rows.isEmpty) {
      if (!mounted) return;
      AppSnackBar.info(context, 'Không có dữ liệu để xuất');
      return;
    }
    CsvExport.download(
      filename: 'payments_${DateTime.now().millisecondsSinceEpoch}.csv',
      headers: const ['id', 'orderCode', 'customerName', 'customerPhone', 'amount', 'method', 'status', 'paidAt', 'createdAt', 'note'],
      rows: rows.map((p) => [
        p.id, p.orderCode, p.customerName, p.customerPhone, p.amount,
        p.method.name, p.status.name, p.paidAt?.toIso8601String() ?? '', p.createdAt.toIso8601String(), p.note,
      ]).toList(),
    );
    if (!mounted) return;
    AppSnackBar.success(context, 'Đã xuất CSV');
  }

  // ═══════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════
  Future<String?> _askNote(String title, String hint) async {
    final ctrl = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: ctrl, maxLines: 3,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return value;
  }

  Future<(double, String)?> _askRefund(double maxAmount) async {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final result = await showDialog<(double, String)>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Hoàn tiền', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 360,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: amtCtrl, keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Số tiền ≤ ${maxAmount.toStringAsFixed(0)}',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl, maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Lý do hoàn tiền',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              final amt = double.tryParse(amtCtrl.text.trim()) ?? 0;
              if (amt <= 0 || amt > maxAmount) {
                AppSnackBar.error(context, 'Số tiền không hợp lệ');
                return;
              }
              Navigator.pop(ctx, (amt, noteCtrl.text.trim()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Hoàn tiền'),
          ),
        ],
      ),
    );
    amtCtrl.dispose();
    noteCtrl.dispose();
    return result;
  }

  // ═══════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════
  Color _statusColor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.pending: return const Color(0xFFF59E0B);
      case PaymentStatus.paid: return const Color(0xFF10B981);
      case PaymentStatus.failed: return const Color(0xFFEF4444);
      case PaymentStatus.refunded: return const Color(0xFF3B82F6);
      case PaymentStatus.partialRefunded: return const Color(0xFF06B6D4);
      case PaymentStatus.reconciled: return const Color(0xFF7C3AED);
    }
  }

  String _money(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  String _dateTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }
}
