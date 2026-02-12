import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../utils/app_snackbar.dart';

class OrderContent extends StatefulWidget {
  const OrderContent({super.key});
  @override
  State<OrderContent> createState() => _OrderContentState();
}

class _OrderContentState extends State<OrderContent> {
  int _selectedTab = 0;
  String _searchQuery = '';
  String _paymentFilter = 'Tất cả';
  final Set<String> _selected = {};
  int _rowsPerPage = 25;
  int _currentPage = 0;
  bool _showDetail = false;
  Order? _detailOrder;

  static const _tabs = ['Tất cả', 'Chờ xử lý', 'Đã xác nhận', 'Đang giao', 'Đã giao', 'Đã hủy'];
  static const _payments = ['Tất cả', 'COD', 'VietQR', 'Banking'];

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtDateTime(DateTime d) => '${_fmtDate(d)}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _fmtMoney(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => Provider.of<OrderProvider>(context, listen: false).loadOrders());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<OrderProvider>(
      builder: (context, provider, _) {
        if (_showDetail && _detailOrder != null) {
          // refresh detail from provider
          final fresh = provider.orders.where((o) => o.id == _detailOrder!.id).toList();
          if (fresh.isNotEmpty) _detailOrder = fresh.first;
          return _buildDetailView(isDark, _detailOrder!, provider);
        }
        final all = provider.orders;
        final filtered = _applyFilters(all);
        final totalPages = (filtered.length / _rowsPerPage).ceil();
        final pageList = filtered.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();
        return Column(children: [
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _header(isDark, all),
              const SizedBox(height: 24),
              _statsRow(isDark, all),
              const SizedBox(height: 24),
              _filterBar(isDark),
              const SizedBox(height: 16),
              _statusTabs(isDark),
              const SizedBox(height: 16),
              if (_selected.isNotEmpty) _bulkBar(isDark, provider),
              if (_selected.isNotEmpty) const SizedBox(height: 12),
              _table(isDark, pageList, all, provider),
              const SizedBox(height: 16),
              _pagination(isDark, filtered.length, totalPages),
            ]),
          )),
        ]);
      },
    );
  }

  List<Order> _applyFilters(List<Order> all) {
    var list = all.toList();
    if (_selectedTab > 0) list = list.where((o) => o.status == _tabs[_selectedTab]).toList();
    if (_paymentFilter != 'Tất cả') list = list.where((o) => o.paymentMethod == _paymentFilter).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((o) =>
          o.code.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.customerPhone.contains(q)).toList();
    }
    return list;
  }

  // ═══════════════════════  HEADER  ═════════════════════
  Widget _header(bool isDark, List<Order> all) {
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quản lý đơn hàng', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(height: 4),
        Text('${all.length} đơn hàng', style: TextStyle(fontSize: 14, color: ts)),
      ]),
      ElevatedButton.icon(
        onPressed: () => _showOrderDialog(),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text('Tạo đơn hàng'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
        ),
      ),
    ]);
  }

  // ═══════════════════════  STATS  ═════════════════════
  Widget _statsRow(bool isDark, List<Order> all) {
    int c(String s) => all.where((o) => o.status == s).length;
    final data = [
      ('Tổng đơn', '${all.length}', Icons.inventory_2_rounded, const Color(0xFF7C3AED)),
      ('Chờ xử lý', '${c('Chờ xử lý')}', Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
      ('Đã xác nhận', '${c('Đã xác nhận')}', Icons.check_circle_rounded, const Color(0xFF3B82F6)),
      ('Đang giao', '${c('Đang giao')}', Icons.local_shipping_rounded, const Color(0xFFEC4899)),
      ('Đã giao', '${c('Đã giao')}', Icons.task_alt_rounded, const Color(0xFF10B981)),
      ('Đã hủy', '${c('Đã hủy')}', Icons.cancel_rounded, const Color(0xFFEF4444)),
    ];
    return Row(children: data.map((d) {
      final idx = data.indexOf(d);
      return Expanded(child: Padding(
        padding: EdgeInsets.only(right: idx < 5 ? 12 : 0),
        child: _statCard(isDark, d.$1, d.$2, d.$3, d.$4),
      ));
    }).toList());
  }

  Widget _statCard(bool isDark, String label, String value, IconData icon, Color color) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: bdr)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 12),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tp)),
          Text(label, style: TextStyle(fontSize: 11, color: ts), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ═══════════════════════  FILTER BAR  ═════════════════════
  Widget _filterBar(bool isDark) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    return Row(children: [
      // Search
      SizedBox(width: 300, height: 40, child: TextField(
        onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 0; }),
        style: TextStyle(fontSize: 13, color: tp),
        decoration: InputDecoration(
          hintText: 'Tìm mã đơn, tên khách, SĐT...', hintStyle: TextStyle(fontSize: 13, color: ts),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: ts), filled: true, fillColor: cardBg,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
        ),
      )),
      const SizedBox(width: 12),
      // Payment filter
      Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: _paymentFilter, dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 13, color: tp),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ts),
          items: _payments.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
          onChanged: (v) => setState(() { _paymentFilter = v!; _currentPage = 0; }),
        )),
      ),
      const Spacer(),
      // Reset
      TextButton.icon(
        onPressed: () => setState(() { _searchQuery = ''; _selectedTab = 0; _paymentFilter = 'Tất cả'; _currentPage = 0; _selected.clear(); }),
        icon: Icon(Icons.refresh_rounded, size: 16, color: ts),
        label: Text('Reset', style: TextStyle(fontSize: 12, color: ts)),
      ),
    ]);
  }

  // ═══════════════════════  STATUS TABS  ═════════════════════
  Widget _statusTabs(bool isDark) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return Row(children: _tabs.asMap().entries.map((e) {
      final active = _selectedTab == e.key;
      return Padding(padding: const EdgeInsets.only(right: 6), child: MouseRegion(cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: () => setState(() { _selectedTab = e.key; _currentPage = 0; _selected.clear(); }),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF7C3AED) : isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: active ? const Color(0xFF7C3AED) : bdr)),
            child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF374151))),
          ),
        ),
      ));
    }).toList());
  }

  // ═══════════════════════  BULK BAR  ═════════════════════
  Widget _bulkBar(bool isDark, OrderProvider provider) {
    final bg = isDark ? const Color(0xFF312E81) : const Color(0xFFEDE9FE);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Text('${_selected.length} đơn đã chọn', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
        const SizedBox(width: 16),
        ...['Đã xác nhận', 'Đang giao', 'Đã giao', 'Đã hủy'].map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _bulkBtn(s, _statusColor(s), provider),
        )),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _selected.clear()),
          child: const Text('Bỏ chọn', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED)))),
      ]),
    );
  }

  Widget _bulkBtn(String status, Color color, OrderProvider provider) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () async {
        final ok = await provider.bulkUpdateStatus(_selected.toList(), status);
        if (!mounted) return;
        if (ok) { AppSnackBar.success(context, 'Đã cập nhật ${_selected.length} đơn → $status'); setState(() => _selected.clear()); }
        else AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  // ═══════════════════════  TABLE  ═════════════════════
  Widget _table(bool isDark, List<Order> page, List<Order> all, OrderProvider provider) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final ts = isDark ? Colors.white.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.55);

    if (provider.isLoading && all.isEmpty) {
      return Container(height: 200, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))));
    }

    final allOnPage = page.map((o) => o.id).toSet();
    final allSelected = allOnPage.isNotEmpty && allOnPage.every((id) => _selected.contains(id));

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(children: [
        // Header
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: headerBg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [
            SizedBox(width: 40, child: Checkbox(value: allSelected, onChanged: (v) => setState(() {
              if (v == true) _selected.addAll(allOnPage); else _selected.removeAll(allOnPage);
            }), activeColor: const Color(0xFF7C3AED), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
            _hdr('MÃ ĐƠN', 2, ts), _hdr('KHÁCH HÀNG', 3, ts), _hdr('SĐT', 2, ts),
            _hdr('TỔNG TIỀN', 2, ts), _hdr('THANH TOÁN', 2, ts), _hdr('TRẠNG THÁI', 2, ts),
            _hdr('NGÀY', 2, ts), _hdr('THAO TÁC', 1, ts),
          ]),
        ),
        if (page.isEmpty)
          Padding(padding: const EdgeInsets.all(48), child: Column(children: [
            Icon(Icons.inbox_rounded, size: 48, color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text('Không có đơn hàng nào', style: TextStyle(fontSize: 14, color: isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9CA3AF))),
          ]))
        else ...page.map((o) => _orderRow(o, isDark, provider)),
      ]),
    );
  }

  Widget _hdr(String t, int flex, Color c) =>
    Expanded(flex: flex, child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c, letterSpacing: 0.5)));

  Widget _orderRow(Order o, bool isDark, OrderProvider provider) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7280);
    final sc = _statusColor(o.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: _selected.contains(o.id)
          ? const Color(0xFF7C3AED).withValues(alpha: 0.04) : Colors.transparent,
        border: Border(bottom: BorderSide(color: bdr))),
      child: Row(children: [
        SizedBox(width: 40, child: Checkbox(value: _selected.contains(o.id),
          onChanged: (v) => setState(() { v == true ? _selected.add(o.id) : _selected.remove(o.id); }),
          activeColor: const Color(0xFF7C3AED), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
        // Code — clickable
        Expanded(flex: 2, child: MouseRegion(cursor: SystemMouseCursors.click, child: GestureDetector(
          onTap: () => setState(() { _showDetail = true; _detailOrder = o; }),
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Text(o.code, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED), fontFamily: 'monospace'))),
        ))),
        const SizedBox(width: 8),
        Expanded(flex: 3, child: Text(o.customerName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tp))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: Text(o.customerPhone, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: ts))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: Text('${_fmtMoney(o.total)}đ', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: _paymentColor(o.paymentMethod).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(o.paymentMethod, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _paymentColor(o.paymentMethod))))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
          child: Text(o.status, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc)))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: Text(_fmtDate(o.createdAt), textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: ts))),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: _actionMenu(o, isDark, provider)),
      ]),
    );
  }

  Widget _actionMenu(Order o, bool isDark, OrderProvider provider) {
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7280)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      position: PopupMenuPosition.under,
      itemBuilder: (_) => [
        _popItem(Icons.visibility_rounded, 'Xem chi tiết', 'detail', tp),
        _popItem(Icons.sync_rounded, 'Cập nhật trạng thái', 'status', tp),
        _popItem(Icons.cancel_rounded, 'Hủy đơn', 'cancel', const Color(0xFFEF4444)),
      ],
      onSelected: (v) {
        if (v == 'detail') setState(() { _showDetail = true; _detailOrder = o; });
        if (v == 'status') _showStatusDialog(o, provider);
        if (v == 'cancel') _confirmCancel(o, provider);
      },
    );
  }

  PopupMenuItem<String> _popItem(IconData icon, String text, String value, Color color) =>
      PopupMenuItem(value: value, child: Row(children: [
        Icon(icon, size: 16, color: color), const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 13, color: color)),
      ]));

  // ═══════════════════════  PAGINATION  ═════════════════════
  Widget _pagination(bool isDark, int totalItems, int totalPages) {
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return Row(children: [
      Text('Hiển thị ${_currentPage * _rowsPerPage + 1}–${((_currentPage + 1) * _rowsPerPage).clamp(0, totalItems)} / $totalItems',
        style: TextStyle(fontSize: 12, color: ts)),
      const Spacer(),
      // Rows per page
      Container(height: 32, padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
        child: DropdownButtonHideUnderline(child: DropdownButton<int>(
          value: _rowsPerPage, isDense: true,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: [10, 25, 50, 100].map((n) => DropdownMenuItem(value: n, child: Text('$n dòng'))).toList(),
          onChanged: (v) => setState(() { _rowsPerPage = v!; _currentPage = 0; }),
        )),
      ),
      const SizedBox(width: 8),
      _pgBtn(Icons.chevron_left_rounded, _currentPage > 0, () => setState(() => _currentPage--), isDark),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text('${_currentPage + 1}/$totalPages', style: TextStyle(fontSize: 12, color: ts))),
      _pgBtn(Icons.chevron_right_rounded, _currentPage < totalPages - 1, () => setState(() => _currentPage++), isDark),
    ]);
  }

  Widget _pgBtn(IconData icon, bool enabled, VoidCallback onTap, bool isDark) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return InkWell(borderRadius: BorderRadius.circular(8), onTap: enabled ? onTap : null,
      child: Container(width: 32, height: 32,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
        child: Icon(icon, size: 18, color: enabled ? (isDark ? Colors.white : const Color(0xFF111827)) : (isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD1D5DB)))),
    );
  }

  // ═══════════════════════  STATUS DIALOG  ═════════════════════
  void _showStatusDialog(Order o, OrderProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 380, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Cập nhật trạng thái', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 6),
        Text('Đơn ${o.code} — hiện: ${o.status}', style: TextStyle(fontSize: 12, color: ts)),
        const SizedBox(height: 20),
        ...OrderStatus.all.map((s) {
          final sc = _statusColor(s);
          final isCurrent = o.status == s;
          return Padding(padding: const EdgeInsets.only(bottom: 8), child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: isCurrent ? null : () async {
              Navigator.pop(ctx);
              final ok = await provider.updateStatus(o.id, s);
              if (!mounted) return;
              if (ok) AppSnackBar.success(context, 'Đã cập nhật → $s'); else AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isCurrent ? sc.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10), border: Border.all(color: isCurrent ? sc : bdr)),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Text(s, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400, color: isCurrent ? sc : tp)),
                if (isCurrent) ...[const Spacer(), Text('Hiện tại', style: TextStyle(fontSize: 11, color: sc))],
              ]),
            ),
          ));
        }),
      ])),
    ));
  }

  // ═══════════════════════  CANCEL CONFIRM  ═════════════════════
  void _confirmCancel(Order o, OrderProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 400, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 28)),
        const SizedBox(height: 16),
        Text('Hủy đơn hàng?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 8),
        Text('Đơn ${o.code} sẽ chuyển sang trạng thái Đã hủy.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: ts)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr), padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Không'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            Navigator.pop(ctx);
            final ok = await provider.updateStatus(o.id, 'Đã hủy');
            if (!mounted) return;
            if (ok) AppSnackBar.success(context, 'Đã hủy đơn ${o.code}'); else AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Hủy đơn'))),
        ]),
      ])),
    ));
  }

  // ═══════════════════════  CREATE ORDER DIALOG  ═════════════════════
  void _showOrderDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);

    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String payment = 'COD';

    Widget field(String label, TextEditingController ctrl, {String hint = '', TextInputType type = TextInputType.text, int maxLines = 1}) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, keyboardType: type, maxLines: maxLines,
          style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(fontSize: 13, color: ts), filled: true, fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          )),
      ]);
    }

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 520, child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Title
        Container(padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8F7FF),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF7C3AED), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tạo đơn hàng mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)),
              Text('Nhập thông tin khách hàng', style: TextStyle(fontSize: 12, color: ts)),
            ])),
            IconButton(icon: Icon(Icons.close_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(ctx)),
          ])),
        // Body
        Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 4), child: Column(children: [
          Row(children: [Expanded(child: field('Tên khách hàng', nameCtrl, hint: 'Nguyễn Văn A')), const SizedBox(width: 16),
            Expanded(child: field('Số điện thoại', phoneCtrl, hint: '0912345678', type: TextInputType.phone))]),
          const SizedBox(height: 16),
          field('Email', emailCtrl, hint: 'email@example.com'),
          const SizedBox(height: 16),
          field('Địa chỉ', addrCtrl, hint: '123 Nguyễn Trãi, Q5, TP.HCM', maxLines: 2),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: field('Tổng tiền (VNĐ)', totalCtrl, hint: '500000', type: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Thanh toán', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: payment, isExpanded: true, dropdownColor: bg,
                  style: TextStyle(fontSize: 13, color: tp),
                  items: ['COD', 'VietQR', 'Banking'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setDialogState(() => payment = v!),
                ))),
            ])),
          ]),
          const SizedBox(height: 16),
          field('Ghi chú', noteCtrl, hint: 'Ghi chú đơn hàng...', maxLines: 2),
          const SizedBox(height: 8),
        ]))),
        // Footer
        Container(padding: const EdgeInsets.fromLTRB(24, 12, 24, 20), child: Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr), padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            if (nameCtrl.text.trim().isEmpty || phoneCtrl.text.trim().isEmpty) {
              AppSnackBar.error(context, 'Vui lòng nhập tên và SĐT khách hàng');
              return;
            }
            final total = double.tryParse(totalCtrl.text.trim()) ?? 0;
            final now = DateTime.now();
            final code = 'DH-${now.millisecondsSinceEpoch.toString().substring(7)}';
            final order = Order(
              id: '', code: code,
              customerName: nameCtrl.text.trim(), customerPhone: phoneCtrl.text.trim(),
              customerEmail: emailCtrl.text.trim(), customerAddress: addrCtrl.text.trim(),
              total: total, paymentMethod: payment, note: noteCtrl.text.trim(),
              activityLog: [ActivityEntry(action: 'Tạo đơn hàng', timestamp: now)],
              createdAt: now, updatedAt: now,
            );
            Navigator.pop(ctx);
            final provider = Provider.of<OrderProvider>(context, listen: false);
            final ok = await provider.createOrder(order);
            if (!mounted) return;
            if (ok) AppSnackBar.success(context, 'Tạo đơn $code thành công'); else AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Tạo đơn'))),
        ])),
      ])),
    )));
  }

  // ═══════════════════════  DETAIL VIEW  ═════════════════════
  Widget _buildDetailView(bool isDark, Order o, OrderProvider provider) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);

    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Back button
        Row(children: [
          InkWell(borderRadius: BorderRadius.circular(8), onTap: () => setState(() { _showDetail = false; _detailOrder = null; }),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back_rounded, size: 16, color: ts), const SizedBox(width: 6),
                Text('Quay lại', style: TextStyle(fontSize: 13, color: ts)),
              ]))),
          const SizedBox(width: 16),
          Text('Chi tiết đơn hàng', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tp)),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Text(o.code, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED), fontFamily: 'monospace'))),
          const Spacer(),
          ElevatedButton.icon(onPressed: () => _showStatusDialog(o, provider),
            icon: const Icon(Icons.sync_rounded, size: 16),
            label: const Text('Cập nhật trạng thái'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0)),
        ]),
        const SizedBox(height: 24),

        // Timeline + Info row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // LEFT: Timeline
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Trạng thái đơn hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp)),
              const SizedBox(height: 20),
              _timeline(isDark, o),
            ]))),
          const SizedBox(width: 20),

          // RIGHT: Customer info
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Thông tin khách hàng', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp)),
              const SizedBox(height: 16),
              _infoRow(Icons.person_rounded, 'Tên', o.customerName, tp, ts),
              _infoRow(Icons.phone_rounded, 'SĐT', o.customerPhone, tp, ts),
              if (o.customerEmail.isNotEmpty) _infoRow(Icons.email_rounded, 'Email', o.customerEmail, tp, ts),
              if (o.customerAddress.isNotEmpty) _infoRow(Icons.location_on_rounded, 'Địa chỉ', o.customerAddress, tp, ts),
            ]))),
        ]),
        const SizedBox(height: 20),

        // Products + Payment
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Products
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sản phẩm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp)),
              const SizedBox(height: 16),
              if (o.items.isEmpty)
                Text('Chưa có sản phẩm', style: TextStyle(fontSize: 13, color: ts))
              else ...[
                // Product table header
                Row(children: [
                  Expanded(flex: 4, child: Text('Tên', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ts))),
                  Expanded(flex: 2, child: Text('Biến thể', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ts))),
                  Expanded(flex: 2, child: Text('Giá', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ts))),
                  Expanded(flex: 1, child: Text('SL', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ts))),
                  Expanded(flex: 2, child: Text('Thành tiền', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ts))),
                ]),
                Divider(color: bdr, height: 16),
                ...o.items.map((item) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
                  Expanded(flex: 4, child: Text(item.productName, style: TextStyle(fontSize: 13, color: tp))),
                  Expanded(flex: 2, child: Text(item.variant.isNotEmpty ? item.variant : '—', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: ts))),
                  Expanded(flex: 2, child: Text('${_fmtMoney(item.price)}đ', textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: ts))),
                  Expanded(flex: 1, child: Text('${item.quantity}', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tp))),
                  Expanded(flex: 2, child: Text('${_fmtMoney(item.total)}đ', textAlign: TextAlign.right, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp))),
                ]))),
              ],
              Divider(color: bdr, height: 24),
              Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Text('Tổng cộng:  ', style: TextStyle(fontSize: 14, color: ts)),
                Text('${_fmtMoney(o.total)}đ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED))),
              ]),
            ]))),
          const SizedBox(width: 20),

          // Payment
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Thanh toán', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp)),
              const SizedBox(height: 16),
              _infoRow(Icons.payment_rounded, 'Phương thức', o.paymentMethod, tp, ts),
              _infoRow(Icons.receipt_rounded, 'Trạng thái', o.paymentStatus, tp, ts),
              const SizedBox(height: 16),
              if (o.note.isNotEmpty) ...[
                Text('Ghi chú', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
                const SizedBox(height: 8),
                Text(o.note, style: TextStyle(fontSize: 13, color: ts, height: 1.5)),
              ],
            ]))),
        ]),
        const SizedBox(height: 20),

        // Activity log
        Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Lịch sử hoạt động', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp)),
            const SizedBox(height: 16),
            if (o.activityLog.isEmpty)
              Text('Chưa có hoạt động nào', style: TextStyle(fontSize: 13, color: ts))
            else ...o.activityLog.reversed.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(color: Color(0xFF7C3AED), shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.action, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tp)),
                  if (entry.note.isNotEmpty) Text(entry.note, style: TextStyle(fontSize: 12, color: ts)),
                  Text(_fmtDateTime(entry.timestamp), style: TextStyle(fontSize: 11, color: ts)),
                ])),
              ]),
            )),
          ])),
      ]))),
    ]);
  }

  Widget _timeline(bool isDark, Order o) {
    final steps = OrderStatus.all;
    final currentIdx = steps.indexOf(o.status);
    final isCancelled = o.status == 'Đã hủy';

    return Column(children: steps.asMap().entries.where((e) => e.key < 4).map((e) {
      final idx = e.key;
      final step = e.value;
      final isDone = !isCancelled && idx <= currentIdx;
      final isLast = idx == 3;
      final sc = isDone ? const Color(0xFF10B981) : isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD1D5DB);

      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 28, height: 28, decoration: BoxDecoration(
            color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.transparent,
            shape: BoxShape.circle, border: Border.all(color: sc, width: 2)),
            child: isDone ? const Icon(Icons.check_rounded, size: 16, color: Color(0xFF10B981)) : null),
          if (!isLast) Container(width: 2, height: 32, color: sc),
        ]),
        const SizedBox(width: 16),
        Padding(padding: const EdgeInsets.only(top: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(step, style: TextStyle(fontSize: 14, fontWeight: isDone ? FontWeight.w600 : FontWeight.w400,
            color: isDone ? (isDark ? Colors.white : const Color(0xFF111827)) : (isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9CA3AF)))),
          if (isCancelled && idx == 0) Text('Đơn đã hủy', style: TextStyle(fontSize: 11, color: const Color(0xFFEF4444))),
        ])),
      ]);
    }).toList());
  }

  Widget _infoRow(IconData icon, String label, String value, Color tp, Color ts) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Icon(icon, size: 16, color: ts), const SizedBox(width: 10),
      Text('$label:', style: TextStyle(fontSize: 12, color: ts)), const SizedBox(width: 8),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tp))),
    ]));
  }

  // ═══════════════════════  HELPERS  ═════════════════════
  Color _statusColor(String s) {
    switch (s) {
      case 'Chờ xử lý': return const Color(0xFFF59E0B);
      case 'Đã xác nhận': return const Color(0xFF3B82F6);
      case 'Đang giao': return const Color(0xFFEC4899);
      case 'Đã giao': return const Color(0xFF10B981);
      case 'Đã hủy': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  Color _paymentColor(String p) {
    switch (p) {
      case 'COD': return const Color(0xFFF59E0B);
      case 'VietQR': return const Color(0xFF3B82F6);
      case 'Banking': return const Color(0xFF10B981);
      default: return const Color(0xFF6B7280);
    }
  }
}
