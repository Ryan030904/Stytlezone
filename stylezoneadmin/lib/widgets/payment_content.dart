import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_model.dart';
import '../providers/payment_provider.dart';
import '../constants/admin_enums.dart';
import '../theme/app_theme.dart';
import '../services/payment_service.dart';
import '../utils/app_snackbar.dart';

class PaymentContent extends StatefulWidget {
  const PaymentContent({super.key});
  @override
  State<PaymentContent> createState() => _PaymentContentState();
}

class _PaymentContentState extends State<PaymentContent> {
  final _searchCtrl = TextEditingController();
  PaymentStatus? _tabStatus;
  bool _showDetail = false;
  PaymentModel? _detailPayment;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<PaymentProvider>(context, listen: false).loadInitial());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _fmtVND(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtDateTime(DateTime d) => '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<PaymentProvider>(builder: (context, prov, _) {
      if (_showDetail && _detailPayment != null) {
        final fresh = prov.payments.where((p) => p.id == _detailPayment!.id).toList();
        if (fresh.isNotEmpty) _detailPayment = fresh.first;
        return _buildDetail(isDark, _detailPayment!, prov);
      }
      final list = prov.payments;
      return Column(children: [
        _buildHeader(isDark, prov),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildKpiRow(isDark, list),
            const SizedBox(height: 20),
            _buildFilterBar(isDark, prov),
            const SizedBox(height: 14),
            _buildStatusTabs(isDark, prov),
            const SizedBox(height: 14),
            _buildTable(isDark, list, prov),
            if (prov.hasMore) ...[
              const SizedBox(height: 16),
              Center(child: prov.isLoadingMore
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)))
                : OutlinedButton.icon(
                    onPressed: () => prov.loadMore(),
                    icon: const Icon(Icons.expand_more_rounded, size: 18),
                    label: const Text('Tải thêm', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  ),
              ),
            ],
          ],
        ))),
      ]);
    });
  }

  // ═══════════════════════  HEADER  ═══════════════════════
  Widget _buildHeader(bool isDark, PaymentProvider prov) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: border))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quản lý thanh toán', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tp)),
          const SizedBox(height: 2),
          Text('${prov.payments.length} giao dịch', style: TextStyle(fontSize: 13, color: ts)),
        ])),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: prov.isSyncing ? null : () async {
            await prov.syncFromOrders();
            if (!mounted) return;
            if (prov.errorMessage != null) { AppSnackBar.error(context, prov.errorMessage!); }
            else { AppSnackBar.success(context, 'Đồng bộ thành công'); }
          },
          icon: prov.isSyncing
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C3AED)))
            : const Icon(Icons.sync_rounded, size: 16),
          label: Text(prov.isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ đơn hàng', style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C3AED),
            side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ]),
    );
  }

  // ═══════════════════════  KPI  ═══════════════════════
  Widget _buildKpiRow(bool isDark, List<PaymentModel> all) {
    final totalAmount = all.fold(0.0, (s, p) => s + p.amount);
    final paidAmount = all.where((p) => p.status == PaymentStatus.paid || p.status == PaymentStatus.reconciled)
        .fold(0.0, (s, p) => s + p.amount);
    final pendingCount = all.where((p) => p.status == PaymentStatus.pending).length;
    final refundedAmount = all.fold(0.0, (s, p) => s + p.refundedAmount);
    final failedCount = all.where((p) => p.status == PaymentStatus.failed).length;
    final reconciledCount = all.where((p) => p.status == PaymentStatus.reconciled).length;

    final data = [
      ('Tổng giao dịch', _fmtVND(totalAmount), Icons.account_balance_wallet_rounded, const Color(0xFF7C3AED)),
      ('Đã thanh toán', _fmtVND(paidAmount), Icons.check_circle_rounded, const Color(0xFF10B981)),
      ('Chờ xác nhận', '$pendingCount', Icons.schedule_rounded, const Color(0xFFF59E0B)),
      ('Đã hoàn tiền', _fmtVND(refundedAmount), Icons.replay_rounded, const Color(0xFFEF4444)),
      ('Thất bại', '$failedCount', Icons.cancel_rounded, const Color(0xFFEF4444)),
      ('Đã đối soát', '$reconciledCount', Icons.verified_rounded, const Color(0xFF3B82F6)),
    ];

    return Wrap(spacing: 14, runSpacing: 14, children: data.map((d) => SizedBox(
      width: (MediaQuery.of(context).size.width - 260 - 48 - 70) / 3,
      child: _kpiCard(isDark, d.$1, d.$2, d.$3, d.$4),
    )).toList());
  }

  Widget _kpiCard(bool isDark, String label, String value, IconData icon, Color color) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    return Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: bdr)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: ts), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ═══════════════════════  FILTER  ═══════════════════════
  Widget _buildFilterBar(bool isDark, PaymentProvider prov) {
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
      SizedBox(width: 260, height: 38, child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => prov.setSearchQuery(v),
        style: TextStyle(fontSize: 13, color: tp),
        decoration: InputDecoration(
          hintText: 'Tìm mã đơn, khách hàng, mã GD...',
          hintStyle: TextStyle(fontSize: 12, color: ts),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: ts),
          filled: true, fillColor: cardBg, contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
        ),
      )),
      const SizedBox(width: 10),
      // Method filter
      Container(height: 38, padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
        child: DropdownButtonHideUnderline(child: DropdownButton<PaymentMethod?>(
          value: prov.methodFilter,
          hint: Text('Phương thức', style: TextStyle(fontSize: 12, color: ts)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 12, color: tp),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: ts),
          items: [
            DropdownMenuItem<PaymentMethod?>(value: null, child: Text('Tất cả', style: TextStyle(fontSize: 12, color: tp))),
            ...PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label, style: TextStyle(fontSize: 12, color: tp)))),
          ],
          onChanged: (v) => prov.setMethodFilter(v),
        )),
      ),

    ]));
  }

  // ═══════════════════════  STATUS TABS  ═══════════════════════
  Widget _buildStatusTabs(bool isDark, PaymentProvider prov) {
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tabs = <(PaymentStatus?, String, Color)>[
      (null, 'Tất cả', const Color(0xFF6B7280)),
      (PaymentStatus.pending, 'Chờ xác nhận', const Color(0xFFF59E0B)),
      (PaymentStatus.paid, 'Đã thanh toán', const Color(0xFF10B981)),
      (PaymentStatus.failed, 'Thất bại', const Color(0xFFEF4444)),
      (PaymentStatus.refunded, 'Đã hoàn tiền', const Color(0xFF8B5CF6)),
      (PaymentStatus.partialRefunded, 'Hoàn một phần', const Color(0xFFF97316)),
      (PaymentStatus.reconciled, 'Đã đối soát', const Color(0xFF3B82F6)),
    ];

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: tabs.map((t) {
      final active = _tabStatus == t.$1;
      return Padding(padding: const EdgeInsets.only(right: 6), child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () { setState(() => _tabStatus = t.$1); prov.setStatusFilter(t.$1); },
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? t.$3 : isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? t.$3 : bdr)),
          child: Text(t.$2, style: TextStyle(fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : isDark ? Colors.white70 : const Color(0xFF374151)))),
      ));
    }).toList()));
  }

  // ═══════════════════════  TABLE  ═══════════════════════
  Widget _buildTable(bool isDark, List<PaymentModel> list, PaymentProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final ts = isDark ? Colors.white38 : Colors.black54;

    if (prov.isLoading) {
      return Container(height: 200, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))));
    }

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(children: [
        // Header
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: headerBg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [
            _hdr('MÃ ĐƠN', 2, ts),
            _hdr('KHÁCH HÀNG', 2, ts),
            _hdr('SỐ TIỀN', 2, ts),
            _hdr('PHƯƠNG THỨC', 2, ts),
            _hdr('TRẠNG THÁI', 2, ts),
            _hdr('NGÀY TẠO', 2, ts),
            _hdr('THAO TÁC', 1, ts),
          ])),
        if (list.isEmpty)
          Padding(padding: const EdgeInsets.all(48), child: Column(children: [
            Icon(Icons.payment_rounded, size: 48, color: isDark ? Colors.white12 : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text('Không có giao dịch nào', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
          ]))
        else ...list.map((p) => _tableRow(p, isDark, prov)),
      ]),
    );
  }

  Widget _hdr(String t, int flex, Color c) =>
    Expanded(flex: flex, child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c, letterSpacing: 0.5)));

  Widget _tableRow(PaymentModel p, bool isDark, PaymentProvider prov) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final sc = _statusColor(p.status);

    return InkWell(
      onTap: () => setState(() { _showDetail = true; _detailPayment = p; }),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bdr))),
        child: Row(children: [
          // Order code
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(p.orderCode.isNotEmpty ? p.orderCode : '—', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED), fontFamily: 'monospace'),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            if (p.transactionId.isNotEmpty) Text(p.transactionId, style: TextStyle(fontSize: 10, color: ts), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Customer
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(p.customerName.isNotEmpty ? p.customerName : '—', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tp),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            if (p.customerPhone.isNotEmpty) Text(p.customerPhone, style: TextStyle(fontSize: 11, color: ts)),
          ])),
          // Amount
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_fmtVND(p.amount), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: tp)),
            if (p.refundedAmount > 0) Text('Hoàn: ${_fmtVND(p.refundedAmount)}', style: const TextStyle(fontSize: 10, color: Color(0xFFEF4444))),
          ])),
          // Method
          Expanded(flex: 2, child: Row(children: [
            Icon(_methodIcon(p.method), size: 16, color: _methodColor(p.method)),
            const SizedBox(width: 6),
            Flexible(child: Text(p.method.label, style: TextStyle(fontSize: 12, color: tp), overflow: TextOverflow.ellipsis)),
          ])),
          // Status
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(p.status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          // Date
          Expanded(flex: 2, child: Text(_fmtDate(p.createdAt), style: TextStyle(fontSize: 11, color: ts))),
          // Actions
          Expanded(flex: 1, child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            position: PopupMenuPosition.under,
            itemBuilder: (_) => [
              _popItem(Icons.visibility_rounded, 'Xem chi tiết', 'detail', tp),
              if (p.status == PaymentStatus.pending) ...[
                _popItem(Icons.check_circle_rounded, 'Xác nhận thanh toán', 'confirm', const Color(0xFF10B981)),
                _popItem(Icons.cancel_rounded, 'Đánh dấu thất bại', 'fail', const Color(0xFFEF4444)),
              ],
              if (p.status == PaymentStatus.paid)
                _popItem(Icons.replay_rounded, 'Hoàn tiền', 'refund', const Color(0xFF8B5CF6)),
              if (p.status == PaymentStatus.paid || p.status == PaymentStatus.partialRefunded)
                _popItem(Icons.verified_rounded, 'Đối soát', 'reconcile', const Color(0xFF3B82F6)),
              _popItem(Icons.delete_rounded, 'Xóa', 'delete', const Color(0xFFEF4444)),
            ],
            onSelected: (v) => _handleAction(v, p, prov),
          )),
        ]),
      ),
    );
  }

  PopupMenuItem<String> _popItem(IconData icon, String text, String value, Color color) =>
    PopupMenuItem(value: value, child: Row(children: [
      Icon(icon, size: 16, color: color), const SizedBox(width: 8),
      Text(text, style: TextStyle(fontSize: 13, color: color)),
    ]));

  // ═══════════════════════  ACTIONS  ═══════════════════════
  void _handleAction(String action, PaymentModel p, PaymentProvider prov) async {
    switch (action) {
      case 'detail':
        setState(() { _showDetail = true; _detailPayment = p; });
        break;
      case 'confirm':
        final ok = await prov.markAsPaid(paymentId: p.id);
        if (!mounted) return;
        if (ok) AppSnackBar.success(context, 'Đã xác nhận thanh toán ${p.orderCode}');
        else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
        break;
      case 'fail':
        final ok = await prov.markAsFailed(paymentId: p.id);
        if (!mounted) return;
        if (ok) AppSnackBar.success(context, 'Đã đánh dấu thất bại ${p.orderCode}');
        else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
        break;
      case 'refund':
        _showRefundDialog(p, prov);
        break;
      case 'reconcile':
        final ok = await prov.reconcile(paymentId: p.id);
        if (!mounted) return;
        if (ok) AppSnackBar.success(context, 'Đã đối soát ${p.orderCode}');
        else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
        break;
      case 'delete':
        _confirmDelete(p, prov);
        break;
    }
  }

  // ═══════════════════════  REFUND DIALOG  ═══════════════════════
  void _showRefundDialog(PaymentModel p, PaymentProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final maxRefund = p.amount - p.refundedAmount;

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 420, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.replay_rounded, color: Color(0xFF8B5CF6), size: 24)),
        const SizedBox(height: 16),
        Text('Hoàn tiền', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 4),
        Text('Đơn: ${p.orderCode}  •  Tối đa: ${_fmtVND(maxRefund)}', style: TextStyle(fontSize: 12, color: ts)),
        const SizedBox(height: 20),
        TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(fontSize: 14, color: tp),
          decoration: InputDecoration(
            labelText: 'Số tiền hoàn', labelStyle: TextStyle(fontSize: 12, color: ts),
            hintText: maxRefund.toStringAsFixed(0), hintStyle: TextStyle(fontSize: 13, color: ts),
            prefixIcon: Icon(Icons.attach_money_rounded, size: 18, color: ts),
            filled: true, fillColor: cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: noteCtrl, maxLines: 2,
          style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(
            labelText: 'Ghi chú', labelStyle: TextStyle(fontSize: 12, color: ts),
            hintText: 'Lý do hoàn tiền...', hintStyle: TextStyle(fontSize: 12, color: ts),
            filled: true, fillColor: cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr),
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            final amount = double.tryParse(amountCtrl.text.trim()) ?? maxRefund;
            if (amount <= 0 || amount > maxRefund) {
              AppSnackBar.error(context, 'Số tiền không hợp lệ (tối đa ${_fmtVND(maxRefund)})');
              return;
            }
            Navigator.pop(ctx);
            final ok = await prov.refund(paymentId: p.id, amount: amount, note: noteCtrl.text.trim());
            if (!mounted) return;
            if (ok) AppSnackBar.success(context, 'Hoàn tiền ${_fmtVND(amount)} thành công');
            else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
          },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Hoàn tiền'))),
        ]),
      ])),
    ));
  }

  // ═══════════════════════  DELETE DIALOG  ═══════════════════════
  void _confirmDelete(PaymentModel p, PaymentProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 400, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 28)),
        const SizedBox(height: 16),
        Text('Xóa giao dịch?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 8),
        Text('Giao dịch ${p.orderCode} sẽ bị xóa.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: ts)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr),
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            Navigator.pop(ctx);
            try {
              await PaymentService().softDelete(p.id);
              await prov.loadInitial();
              if (!mounted) return;
              AppSnackBar.success(context, 'Đã xóa giao dịch');
            } catch (e) {
              if (!mounted) return;
              AppSnackBar.error(context, 'Lỗi: $e');
            }
          },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Xóa'))),
        ]),
      ])),
    ));
  }

  // ═══════════════════════  DETAIL VIEW  ═══════════════════════
  Widget _buildDetail(bool isDark, PaymentModel p, PaymentProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final sc = _statusColor(p.status);

    return Column(children: [
      // Header
      Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: bdr))),
        child: Row(children: [
          InkWell(borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() { _showDetail = false; _detailPayment = null; }),
            child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF374151)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chi tiết thanh toán', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp)),
            Text(p.orderCode, style: TextStyle(fontSize: 12, color: ts)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(p.status.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc))),
        ])),
      // Body
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Left: info
          Expanded(flex: 3, child: Column(children: [
            _detailCard(isDark, 'Thông tin giao dịch', Icons.payment_rounded, [
              _detailRow('Mã đơn hàng', p.orderCode, tp, ts),
              _detailRow('Mã giao dịch', p.transactionId.isNotEmpty ? p.transactionId : '—', tp, ts),
              _detailRow('Số tiền', _fmtVND(p.amount), tp, ts, valueColor: const Color(0xFF10B981)),
              _detailRow('Phương thức', p.method.label, tp, ts),
              _detailRow('Nguồn', p.source, tp, ts),
              if (p.bankName.isNotEmpty) _detailRow('Ngân hàng', p.bankName, tp, ts),
              if (p.bankCode.isNotEmpty) _detailRow('Mã NH', p.bankCode, tp, ts),
            ]),
            const SizedBox(height: 16),
            _detailCard(isDark, 'Khách hàng', Icons.person_rounded, [
              _detailRow('Tên', p.customerName, tp, ts),
              _detailRow('SĐT', p.customerPhone, tp, ts),
            ]),
          ])),
          const SizedBox(width: 20),
          // Right: timeline
          Expanded(flex: 2, child: Column(children: [
            _detailCard(isDark, 'Mốc thời gian', Icons.timeline_rounded, [
              _detailRow('Tạo lúc', _fmtDateTime(p.createdAt), tp, ts),
              if (p.paidAt != null) _detailRow('Thanh toán', _fmtDateTime(p.paidAt!), tp, ts, valueColor: const Color(0xFF10B981)),
              if (p.confirmedAt != null) _detailRow('Xác nhận', _fmtDateTime(p.confirmedAt!), tp, ts),
              if (p.confirmedBy.isNotEmpty) _detailRow('Xác nhận bởi', p.confirmedBy, tp, ts),
              if (p.reconciledAt != null) _detailRow('Đối soát', _fmtDateTime(p.reconciledAt!), tp, ts, valueColor: const Color(0xFF3B82F6)),
              if (p.reconciledBy.isNotEmpty) _detailRow('Đối soát bởi', p.reconciledBy, tp, ts),
              if (p.refundedAt != null) _detailRow('Hoàn tiền', _fmtDateTime(p.refundedAt!), tp, ts, valueColor: const Color(0xFFEF4444)),
              if (p.refundedAmount > 0) _detailRow('Số tiền hoàn', _fmtVND(p.refundedAmount), tp, ts, valueColor: const Color(0xFFEF4444)),
              if (p.refundBy.isNotEmpty) _detailRow('Hoàn bởi', p.refundBy, tp, ts),
            ]),
            if (p.note.isNotEmpty) ...[
              const SizedBox(height: 16),
              _detailCard(isDark, 'Ghi chú', Icons.note_rounded, [
                Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(p.note, style: TextStyle(fontSize: 13, color: tp, height: 1.5))),
              ]),
            ],
            const SizedBox(height: 16),
            // Action buttons
            _detailCard(isDark, 'Thao tác', Icons.touch_app_rounded, [
              const SizedBox(height: 8),
              if (p.status == PaymentStatus.pending) ...[
                _actionBtn('Xác nhận thanh toán', Icons.check_circle_rounded, const Color(0xFF10B981), () => _handleAction('confirm', p, prov)),
                const SizedBox(height: 8),
                _actionBtn('Đánh dấu thất bại', Icons.cancel_rounded, const Color(0xFFEF4444), () => _handleAction('fail', p, prov)),
              ],
              if (p.status == PaymentStatus.paid) ...[
                _actionBtn('Hoàn tiền', Icons.replay_rounded, const Color(0xFF8B5CF6), () => _showRefundDialog(p, prov)),
                const SizedBox(height: 8),
                _actionBtn('Đối soát', Icons.verified_rounded, const Color(0xFF3B82F6), () => _handleAction('reconcile', p, prov)),
              ],
              if (p.status == PaymentStatus.partialRefunded)
                _actionBtn('Đối soát', Icons.verified_rounded, const Color(0xFF3B82F6), () => _handleAction('reconcile', p, prov)),
              const SizedBox(height: 8),
            ]),
          ])),
        ]),
      )),
    ]);
  }

  Widget _detailCard(bool isDark, String title, IconData icon, List<Widget> children) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tp)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _detailRow(String label, String value, Color tp, Color ts, {Color? valueColor}) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      SizedBox(width: 120, child: Text(label, style: TextStyle(fontSize: 12, color: ts))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? tp),
        overflow: TextOverflow.ellipsis)),
    ]));
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(width: double.infinity, child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ));
  }

  // ═══════════════════════  HELPERS  ═══════════════════════
  Color _statusColor(PaymentStatus s) {
    switch (s) {
      case PaymentStatus.pending: return const Color(0xFFF59E0B);
      case PaymentStatus.paid: return const Color(0xFF10B981);
      case PaymentStatus.failed: return const Color(0xFFEF4444);
      case PaymentStatus.refunded: return const Color(0xFF8B5CF6);
      case PaymentStatus.partialRefunded: return const Color(0xFFF97316);
      case PaymentStatus.reconciled: return const Color(0xFF3B82F6);
    }
  }

  IconData _methodIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cod: return Icons.local_shipping_rounded;
      case PaymentMethod.vietQr: return Icons.qr_code_rounded;
      case PaymentMethod.bankTransfer: return Icons.account_balance_rounded;
      case PaymentMethod.momo: return Icons.phone_iphone_rounded;
      case PaymentMethod.vnpay: return Icons.credit_card_rounded;
      case PaymentMethod.zaloPay: return Icons.wallet_rounded;
    }
  }

  Color _methodColor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cod: return const Color(0xFF6B7280);
      case PaymentMethod.vietQr: return const Color(0xFF3B82F6);
      case PaymentMethod.bankTransfer: return const Color(0xFF10B981);
      case PaymentMethod.momo: return const Color(0xFFEC4899);
      case PaymentMethod.vnpay: return const Color(0xFF7C3AED);
      case PaymentMethod.zaloPay: return const Color(0xFF3B82F6);
    }
  }
}
