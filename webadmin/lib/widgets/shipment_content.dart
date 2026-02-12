import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shipment_model.dart';
import '../models/order_model.dart';
import '../providers/shipment_provider.dart';
import '../providers/order_provider.dart';
import '../utils/app_snackbar.dart';
import '../theme/app_theme.dart';

class ShipmentContent extends StatefulWidget {
  const ShipmentContent({super.key});
  @override
  State<ShipmentContent> createState() => _ShipmentContentState();
}

class _ShipmentContentState extends State<ShipmentContent> {
  int _selectedTab = 0;
  String _searchQuery = '';
  String _carrierFilter = 'Tất cả';
  String _dateFilter = 'Tất cả';
  final Set<String> _selected = {};
  int _rowsPerPage = 25;
  int _currentPage = 0;
  bool _showDetail = false;
  Shipment? _detailShipment;

  static const _tabs = ['Tất cả','Đang xử lý','Đã lấy hàng','Đang vận chuyển','Đang giao','Đã giao','Hoàn / Thất bại'];
  static const _carriers = ['Tất cả','GHN','GHTK','Viettel Post','J&T Express','Ninja Van'];
  static const _dateFilters = ['Tất cả','Hôm nay','7 ngày','30 ngày','Tháng này'];

  // Pipeline stages for Kanban header
  static const _pipelineStages = [
    (ShipmentStatus.processing, Icons.inventory_2_rounded, 'Chờ xử lý'),
    (ShipmentStatus.pickedUp, Icons.check_circle_outline_rounded, 'Đã lấy hàng'),
    (ShipmentStatus.inTransit, Icons.local_shipping_rounded, 'Vận chuyển'),
    (ShipmentStatus.delivering, Icons.delivery_dining_rounded, 'Đang giao'),
    (ShipmentStatus.delivered, Icons.task_alt_rounded, 'Đã giao'),
  ];

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  String _fmtDateTime(DateTime d) => '${_fmtDate(d)}  ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';

  String _fmtVND(double v) {
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
    Future.microtask(() {
      Provider.of<ShipmentProvider>(context, listen: false).loadShipments();
      Provider.of<OrderProvider>(context, listen: false).loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer2<ShipmentProvider, OrderProvider>(
      builder: (context, provider, orderProvider, _) {
        if (_showDetail && _detailShipment != null) {
          final fresh = provider.shipments.where((s) => s.id == _detailShipment!.id).toList();
          if (fresh.isNotEmpty) _detailShipment = fresh.first;
          return _buildDetailView(isDark, _detailShipment!, provider, orderProvider);
        }
        final all = provider.shipments;
        final filtered = _applyFilters(all);
        final totalPages = (filtered.length / _rowsPerPage).ceil().clamp(1, 99999);
        final pageList = filtered.skip(_currentPage * _rowsPerPage).take(_rowsPerPage).toList();
        return Column(children: [
          Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _header(isDark, all, orderProvider),
              const SizedBox(height: 20),
              _pipelineHeader(isDark, all),
              const SizedBox(height: 20),
              _kpiRow(isDark, all),
              const SizedBox(height: 20),
              _filterBar(isDark),
              const SizedBox(height: 14),
              _statusTabs(isDark),
              const SizedBox(height: 14),
              if (_selected.isNotEmpty) ...[_bulkBar(isDark, provider), const SizedBox(height: 12)],
              _table(isDark, pageList, all, provider),
              const SizedBox(height: 14),
              _pagination(isDark, filtered.length, totalPages),
            ]))),
        ]);
      },
    );
  }

  // ═══════════════════════  FILTERS  ═════════════════════
  List<Shipment> _applyFilters(List<Shipment> all) {
    var list = all.toList();
    // Tab filter
    if (_selectedTab == 1) list = list.where((s) => s.status == ShipmentStatus.processing).toList();
    else if (_selectedTab == 2) list = list.where((s) => s.status == ShipmentStatus.pickedUp).toList();
    else if (_selectedTab == 3) list = list.where((s) => s.status == ShipmentStatus.inTransit).toList();
    else if (_selectedTab == 4) list = list.where((s) => s.status == ShipmentStatus.delivering).toList();
    else if (_selectedTab == 5) list = list.where((s) => s.status == ShipmentStatus.delivered).toList();
    else if (_selectedTab == 6) list = list.where((s) => s.status == ShipmentStatus.returned || s.status == ShipmentStatus.failed).toList();
    // Carrier filter
    if (_carrierFilter != 'Tất cả') list = list.where((s) => s.carrier == _carrierFilter).toList();
    // Date filter
    if (_dateFilter != 'Tất cả') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      DateTime start;
      if (_dateFilter == 'Hôm nay') start = today;
      else if (_dateFilter == '7 ngày') start = today.subtract(const Duration(days: 6));
      else if (_dateFilter == '30 ngày') start = today.subtract(const Duration(days: 29));
      else start = DateTime(now.year, now.month, 1); // Tháng này
      list = list.where((s) => s.createdAt.isAfter(start.subtract(const Duration(seconds: 1)))).toList();
    }
    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) => s.trackingCode.toLowerCase().contains(q) || s.orderCode.toLowerCase().contains(q) || s.receiverName.toLowerCase().contains(q) || s.receiverPhone.contains(q)).toList();
    }
    return list;
  }

  // ═══════════════════════  HEADER  ═════════════════════
  Widget _header(bool isDark, List<Shipment> all, OrderProvider orderProv) {
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Quản lý vận chuyển', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(height: 4),
        Text('${all.length} vận đơn · Quản lý quy trình giao hàng từ A đến Z', style: TextStyle(fontSize: 13, color: ts)),
      ]),
      Row(children: [
        OutlinedButton.icon(
          onPressed: () => _exportCSV(all),
          icon: const Icon(Icons.download_rounded, size: 16),
          label: const Text('Xuất CSV'),
          style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
        const SizedBox(width: 10),
        _createShipmentButton(isDark, orderProv),
      ]),
    ]);
  }

  Widget _createShipmentButton(bool isDark, OrderProvider orderProv) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      itemBuilder: (_) => [
        PopupMenuItem(value: 'manual', child: Row(children: [
          Icon(Icons.edit_rounded, size: 16, color: isDark ? Colors.white70 : const Color(0xFF374151)), const SizedBox(width: 10),
          Text('Tạo thủ công', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF374151))),
        ])),
        PopupMenuItem(value: 'from_order', child: Row(children: [
          Icon(Icons.receipt_long_rounded, size: 16, color: isDark ? Colors.white70 : const Color(0xFF374151)), const SizedBox(width: 10),
          Text('Tạo từ đơn hàng', style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF374151))),
        ])),
      ],
      onSelected: (v) {
        if (v == 'manual') _showCreateDialog();
        else _showCreateFromOrderDialog(orderProv);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(12)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.add_rounded, size: 18, color: Colors.white), SizedBox(width: 6),
          Text('Tạo vận đơn', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
          SizedBox(width: 4), Icon(Icons.arrow_drop_down_rounded, size: 18, color: Colors.white70),
        ]),
      ),
    );
  }

  // ═══════════════════════  PIPELINE HEADER  ═════════════════════
  Widget _pipelineHeader(bool isDark, List<Shipment> all) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Row(children: _pipelineStages.asMap().entries.map((e) {
        final idx = e.key;
        final stage = e.value;
        final count = all.where((s) => s.status == stage.$1).length;
        final isLast = idx == _pipelineStages.length - 1;
        final stageColor = _statusColor(stage.$1);
        return Expanded(child: Row(children: [
          Expanded(child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() { _selectedTab = idx + 1; _currentPage = 0; _selected.clear(); }),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: stageColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedTab == idx + 1 ? stageColor : Colors.transparent, width: 1.5),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(stage.$2, size: 22, color: stageColor),
                const SizedBox(height: 6),
                Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: stageColor)),
                const SizedBox(height: 2),
                Text(stage.$3, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white54 : const Color(0xFF6B7280)), textAlign: TextAlign.center),
              ]),
            ),
          )),
          if (!isLast) Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
          ),
        ]));
      }).toList()),
    );
  }

  // ═══════════════════════  KPI CARDS  ═════════════════════
  Widget _kpiRow(bool isDark, List<Shipment> all) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final inTransit = all.where((s) => s.status == ShipmentStatus.inTransit || s.status == ShipmentStatus.delivering).length;
    final deliveredToday = all.where((s) => s.status == ShipmentStatus.delivered && s.deliveredAt != null &&
        s.deliveredAt!.year == today.year && s.deliveredAt!.month == today.month && s.deliveredAt!.day == today.day).length;
    final createdToday = all.where((s) => s.createdAt.year == today.year && s.createdAt.month == today.month && s.createdAt.day == today.day).length;
    final late = all.where((s) => s.isLate).length;
    final returned = all.where((s) => s.status == ShipmentStatus.returned || s.status == ShipmentStatus.failed).length;
    final totalDelivered = all.where((s) => s.status == ShipmentStatus.delivered).length;
    final totalDone = totalDelivered + returned;
    final successRate = totalDone > 0 ? (totalDelivered / totalDone * 100).toStringAsFixed(0) : '—';

    final data = [
      ('Đang vận chuyển', '$inTransit', Icons.local_shipping_rounded, const Color(0xFF3B82F6)),
      ('Giao hôm nay', '$deliveredToday', Icons.task_alt_rounded, const Color(0xFF10B981)),
      ('Tạo hôm nay', '$createdToday', Icons.add_circle_outline_rounded, const Color(0xFF8B5CF6)),
      ('Trễ hạn', '$late', Icons.warning_amber_rounded, const Color(0xFFEF4444)),
      ('Hoàn / Thất bại', '$returned', Icons.replay_rounded, const Color(0xFFF59E0B)),
      ('Tỉ lệ thành công', '$successRate%', Icons.trending_up_rounded, const Color(0xFF10B981)),
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
    return Container(padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: bdr)),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Flexible(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tp)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: ts), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ═══════════════════════  FILTER BAR  ═════════════════════
  Widget _filterBar(bool isDark) {
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    return Wrap(spacing: 10, runSpacing: 10, crossAxisAlignment: WrapCrossAlignment.center, children: [
      SizedBox(width: 280, height: 40, child: TextField(
        onChanged: (v) => setState(() { _searchQuery = v; _currentPage = 0; }),
        style: TextStyle(fontSize: 13, color: tp),
        decoration: InputDecoration(
          hintText: 'Tìm mã vận đơn, đơn hàng, SĐT...', hintStyle: TextStyle(fontSize: 13, color: ts),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: ts), filled: true, fillColor: cardBg,
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
        ),
      )),
      _dropdownFilter(isDark, _carrierFilter, _carriers, (v) => setState(() { _carrierFilter = v!; _currentPage = 0; })),
      _dropdownFilter(isDark, _dateFilter, _dateFilters, (v) => setState(() { _dateFilter = v!; _currentPage = 0; })),
      TextButton.icon(
        onPressed: () => setState(() { _searchQuery = ''; _selectedTab = 0; _carrierFilter = 'Tất cả'; _dateFilter = 'Tất cả'; _currentPage = 0; _selected.clear(); }),
        icon: Icon(Icons.refresh_rounded, size: 14, color: ts),
        label: Text('Reset', style: TextStyle(fontSize: 12, color: ts)),
      ),
    ]);
  }

  Widget _dropdownFilter(bool isDark, String value, List<String> items, ValueChanged<String?> onChanged) {
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    return Container(height: 40, padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        value: value, dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        style: TextStyle(fontSize: 13, color: tp),
        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: ts),
        items: items.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
        onChanged: onChanged,
      )),
    );
  }

  // ═══════════════════════  STATUS TABS  ═════════════════════
  Widget _statusTabs(bool isDark) {
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _tabs.asMap().entries.map((e) {
      final active = _selectedTab == e.key;
      return Padding(padding: const EdgeInsets.only(right: 6), child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() { _selectedTab = e.key; _currentPage = 0; _selected.clear(); }),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF7C3AED) : isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? const Color(0xFF7C3AED) : bdr)),
          child: Text(e.value, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : isDark ? Colors.white70 : const Color(0xFF374151))),
        ),
      ));
    }).toList()));
  }

  // ═══════════════════════  BULK BAR  ═════════════════════
  Widget _bulkBar(bool isDark, ShipmentProvider provider) {
    final bg = isDark ? const Color(0xFF312E81) : const Color(0xFFEDE9FE);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Text('${_selected.length} vận đơn đã chọn', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
        const SizedBox(width: 16),
        ...[ShipmentStatus.inTransit, ShipmentStatus.delivering, ShipmentStatus.delivered, ShipmentStatus.returned].map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(borderRadius: BorderRadius.circular(6), onTap: () async {
            final ok = await provider.bulkUpdateStatus(_selected.toList(), s);
            if (!mounted) return;
            if (ok) { AppSnackBar.success(context, 'Đã cập nhật ${_selected.length} vận đơn → $s'); setState(() => _selected.clear()); }
            else AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
          }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: _statusColor(s).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(s))))),
        )),
        const Spacer(),
        TextButton(onPressed: () => setState(() => _selected.clear()),
          child: const Text('Bỏ chọn', style: TextStyle(fontSize: 12, color: Color(0xFF7C3AED)))),
      ]),
    );
  }

  // ═══════════════════════  TABLE  ═════════════════════
  Widget _table(bool isDark, List<Shipment> page, List<Shipment> all, ShipmentProvider provider) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final ts = isDark ? Colors.white38 : Colors.black54;

    if (provider.isLoading && all.isEmpty) {
      return Container(height: 200, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))));
    }

    final allOnPage = page.map((s) => s.id).toSet();
    final allSel = allOnPage.isNotEmpty && allOnPage.every((id) => _selected.contains(id));

    return Container(decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: headerBg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [
            SizedBox(width: 36, child: Checkbox(value: allSel, onChanged: (v) => setState(() {
              if (v == true) _selected.addAll(allOnPage); else _selected.removeAll(allOnPage);
            }), activeColor: const Color(0xFF7C3AED), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
            _hdr('MÃ VẬN ĐƠN', 2, ts), _hdr('NGƯỜI NHẬN', 2, ts), _hdr('ĐƠN VỊ VC', 1, ts),
            _hdr('TRẠNG THÁI', 2, ts), _hdr('NGÀY TẠO', 1, ts), _hdr('DỰ KIẾN', 1, ts), _hdr('THAO TÁC', 1, ts),
          ])),
        if (page.isEmpty)
          Padding(padding: const EdgeInsets.all(48), child: Column(children: [
            Icon(Icons.local_shipping_outlined, size: 48, color: isDark ? Colors.white12 : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text('Không có vận đơn nào', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
          ]))
        else ...page.map((s) => _shipRow(s, isDark, provider)),
      ]),
    );
  }

  Widget _hdr(String t, int flex, Color c) =>
    Expanded(flex: flex, child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c, letterSpacing: 0.5)));

  Widget _shipRow(Shipment s, bool isDark, ShipmentProvider provider) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final sc = _statusColor(s.status);
    return InkWell(
      onTap: () => setState(() { _showDetail = true; _detailShipment = s; }),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _selected.contains(s.id) ? const Color(0xFF7C3AED).withValues(alpha: 0.04) : Colors.transparent,
          border: Border(bottom: BorderSide(color: bdr))),
        child: Row(children: [
          SizedBox(width: 36, child: Checkbox(value: _selected.contains(s.id),
            onChanged: (v) => setState(() { v == true ? _selected.add(s.id) : _selected.remove(s.id); }),
            activeColor: const Color(0xFF7C3AED), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap)),
          Expanded(flex: 2, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Text(s.trackingCode, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED), fontFamily: 'monospace')))),
          const SizedBox(width: 6),
          Expanded(flex: 2, child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(s.receiverName, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tp)),
            if (s.receiverPhone.isNotEmpty) Text(s.receiverPhone, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: ts)),
          ])),
          const SizedBox(width: 6),
          Expanded(flex: 1, child: Text(s.carrier, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: tp))),
          const SizedBox(width: 6),
          Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(s.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc))),
            if (s.isLate) ...[const SizedBox(width: 4), const Icon(Icons.warning_rounded, size: 14, color: Color(0xFFEF4444))],
          ])),
          const SizedBox(width: 6),
          Expanded(flex: 1, child: Text(_fmtDate(s.createdAt), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: ts))),
          const SizedBox(width: 6),
          Expanded(flex: 1, child: Text(s.estimatedDelivery != null ? _fmtDate(s.estimatedDelivery!) : '—', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: s.isLate ? const Color(0xFFEF4444) : ts, fontWeight: s.isLate ? FontWeight.w600 : FontWeight.w400))),
          const SizedBox(width: 6),
          Expanded(flex: 1, child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white, position: PopupMenuPosition.under,
            itemBuilder: (_) => [
              _popItem(Icons.visibility_rounded, 'Xem chi tiết', 'detail', tp),
              _popItem(Icons.sync_rounded, 'Cập nhật trạng thái', 'status', tp),
              _popItem(Icons.delete_rounded, 'Xóa', 'delete', const Color(0xFFEF4444)),
            ],
            onSelected: (v) {
              if (v == 'detail') setState(() { _showDetail = true; _detailShipment = s; });
              if (v == 'status') _showStatusDialog(s, provider);
              if (v == 'delete') _confirmDelete(s, provider);
            },
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

  // ═══════════════════════  PAGINATION  ═════════════════════
  Widget _pagination(bool isDark, int totalItems, int totalPages) {
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final start = totalItems == 0 ? 0 : _currentPage * _rowsPerPage + 1;
    final end = ((_currentPage + 1) * _rowsPerPage).clamp(0, totalItems);
    return Row(children: [
      Text('Hiển thị $start–$end / $totalItems', style: TextStyle(fontSize: 12, color: ts)),
      const Spacer(),
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
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    return InkWell(borderRadius: BorderRadius.circular(8), onTap: enabled ? onTap : null,
      child: Container(width: 32, height: 32,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
        child: Icon(icon, size: 18, color: enabled ? (isDark ? Colors.white : const Color(0xFF111827)) : (isDark ? Colors.white24 : const Color(0xFFD1D5DB)))));
  }

  // ═══════════════════════  STATUS DIALOG  ═════════════════════
  void _showStatusDialog(Shipment s, ShipmentProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final noteCtrl = TextEditingController();
    final locCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 420, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Cập nhật trạng thái', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 4),
        Text('Vận đơn ${s.trackingCode}', style: TextStyle(fontSize: 12, color: ts)),
        const SizedBox(height: 16),
        // Location field
        TextField(controller: locCtrl, style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(hintText: 'Vị trí hiện tại (VD: Kho HCM, Bưu cục Q1...)', hintStyle: TextStyle(fontSize: 12, color: ts),
            prefixIcon: Icon(Icons.location_on_rounded, size: 16, color: ts), filled: true, fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          )),
        const SizedBox(height: 10),
        // Note field
        TextField(controller: noteCtrl, maxLines: 2, style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(hintText: 'Ghi chú (VD: Đã giao cho shipper, Khách không nhận...)', hintStyle: TextStyle(fontSize: 12, color: ts),
            prefixIcon: Padding(padding: const EdgeInsets.only(bottom: 20), child: Icon(Icons.note_rounded, size: 16, color: ts)),
            filled: true, fillColor: cardBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          )),
        const SizedBox(height: 16),
        ...ShipmentStatus.all.map((st) {
          final sc = _statusColor(st);
          final isCurrent = s.status == st;
          return Padding(padding: const EdgeInsets.only(bottom: 6), child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: isCurrent ? null : () async {
              Navigator.pop(ctx);
              final ok = await provider.updateStatus(s.id, st, location: locCtrl.text.trim(), note: noteCtrl.text.trim());
              if (!mounted) return;
              if (ok) AppSnackBar.success(context, 'Đã cập nhật → $st'); else AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
            },
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: isCurrent ? sc.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(10), border: Border.all(color: isCurrent ? sc : bdr)),
              child: Row(children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: sc, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Text(st, style: TextStyle(fontSize: 13, fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400, color: isCurrent ? sc : tp)),
                if (isCurrent) ...[const Spacer(), Text('Hiện tại', style: TextStyle(fontSize: 11, color: sc))],
              ])),
          ));
        }),
      ])),
    ));
  }

  // ═══════════════════════  DELETE CONFIRM  ═════════════════════
  void _confirmDelete(Shipment s, ShipmentProvider provider) {
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
        Text('Xóa vận đơn?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 8),
        Text('Vận đơn ${s.trackingCode} sẽ bị xóa.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: ts)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr), padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            Navigator.pop(ctx);
            final ok = await provider.deleteShipment(s.id);
            if (!mounted) return;
            if (ok) AppSnackBar.success(context, 'Đã xóa ${s.trackingCode}'); else AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Xóa'))),
        ]),
      ])),
    ));
  }

  // ═══════════════════════  CREATE DIALOG (manual)  ═════════════════════
  void _showCreateDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final trackCtrl = TextEditingController();
    final orderCodeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    String carrier = 'GHN';

    Widget field(String label, TextEditingController ctrl, {String hint = ''}) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, style: TextStyle(fontSize: 13, color: tp),
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
      child: Container(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8F7FF),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF7C3AED), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tạo vận đơn thủ công', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)),
              Text('Nhập thông tin vận đơn', style: TextStyle(fontSize: 12, color: ts)),
            ])),
            IconButton(icon: Icon(Icons.close_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(ctx)),
          ])),
        Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 20, 24, 4), child: Column(children: [
          Row(children: [Expanded(child: field('Mã vận đơn', trackCtrl, hint: 'VD: GHN123456')), const SizedBox(width: 16), Expanded(child: field('Mã đơn hàng', orderCodeCtrl, hint: 'VD: DH-12345'))]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Đơn vị vận chuyển', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
              const SizedBox(height: 6),
              Container(padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
                child: DropdownButtonHideUnderline(child: DropdownButton<String>(
                  value: carrier, isExpanded: true, dropdownColor: bg, style: TextStyle(fontSize: 13, color: tp),
                  items: ['GHN','GHTK','Viettel Post','J&T Express','Ninja Van'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => carrier = v!),
                ))),
            ])),
            const SizedBox(width: 16), Expanded(child: field('Tên người nhận', nameCtrl, hint: 'Nguyễn Văn A')),
          ]),
          const SizedBox(height: 16),
          Row(children: [Expanded(child: field('SĐT', phoneCtrl, hint: '0912345678')), const SizedBox(width: 16), Expanded(child: field('Địa chỉ', addrCtrl, hint: '123 Nguyễn Trãi...'))]),
          const SizedBox(height: 16),
        ]))),
        Container(padding: const EdgeInsets.fromLTRB(24, 12, 24, 20), child: Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr), padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            if (trackCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) { AppSnackBar.error(context, 'Vui lòng nhập mã vận đơn và tên người nhận'); return; }
            final now = DateTime.now();
            final ship = Shipment(id: '', trackingCode: trackCtrl.text.trim().toUpperCase(), orderId: '', orderCode: orderCodeCtrl.text.trim().toUpperCase(),
              carrier: carrier, receiverName: nameCtrl.text.trim(), receiverPhone: phoneCtrl.text.trim(), receiverAddress: addrCtrl.text.trim(),
              shippedAt: now, estimatedDelivery: now.add(const Duration(days: 3)),
              trackingHistory: [TrackingEntry(status: 'Đã tạo vận đơn', timestamp: now)], createdAt: now, updatedAt: now);
            Navigator.pop(ctx);
            final provider = Provider.of<ShipmentProvider>(context, listen: false);
            final ok = await provider.createShipment(ship);
            if (!mounted) return;
            if (ok) AppSnackBar.success(context, 'Tạo vận đơn thành công'); else AppSnackBar.error(context, provider.errorMessage ?? 'Lỗi');
          }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Tạo vận đơn'))),
        ])),
      ])),
    )));
  }

  // ═══════════════════════  CREATE FROM ORDER  ═════════════════════
  void _showCreateFromOrderDialog(OrderProvider orderProv) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    // Get confirmed orders without shipment
    final shipProv = Provider.of<ShipmentProvider>(context, listen: false);
    final linkedOrderIds = shipProv.shipments.map((s) => s.orderId).toSet();
    final availableOrders = orderProv.orders.where((o) => !o.isDeleted && (o.status == 'Đã xác nhận' || o.status == 'Chờ xử lý') && !linkedOrderIds.contains(o.id)).toList();
    String carrier = 'GHN';

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setDialogState) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 520, constraints: const BoxConstraints(maxHeight: 560), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
          decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8F7FF),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
          child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 20)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Tạo vận đơn từ đơn hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)),
              Text('Chọn đơn hàng đã xác nhận', style: TextStyle(fontSize: 12, color: ts)),
            ])),
            IconButton(icon: Icon(Icons.close_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(ctx)),
          ])),
        // Carrier selector
        Padding(padding: const EdgeInsets.fromLTRB(24, 12, 24, 8), child: Row(children: [
          Text('Đơn vị vận chuyển: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
          const SizedBox(width: 8),
          Container(height: 36, padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(
              value: carrier, isDense: true, dropdownColor: bg, style: TextStyle(fontSize: 13, color: tp),
              items: ['GHN','GHTK','Viettel Post','J&T Express','Ninja Van'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setDialogState(() => carrier = v!),
            ))),
        ])),
        Expanded(child: availableOrders.isEmpty
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.inbox_rounded, size: 48, color: isDark ? Colors.white12 : const Color(0xFFD1D5DB)),
              const SizedBox(height: 12),
              Text('Không có đơn hàng nào sẵn sàng', style: TextStyle(fontSize: 14, color: ts)),
              const SizedBox(height: 4),
              Text('Cần có đơn "Đã xác nhận" hoặc "Chờ xử lý" chưa tạo vận đơn', style: TextStyle(fontSize: 12, color: ts)),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              itemCount: availableOrders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final order = availableOrders[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final now = DateTime.now();
                    final code = '${carrier.replaceAll(' ', '').substring(0, 3).toUpperCase()}${now.millisecondsSinceEpoch.toString().substring(7)}';
                    final ship = Shipment(id: '', trackingCode: code, orderId: order.id, orderCode: order.code,
                      carrier: carrier, receiverName: order.customerName, receiverPhone: order.customerPhone, receiverAddress: order.customerAddress,
                      shippedAt: now, estimatedDelivery: now.add(const Duration(days: 3)),
                      trackingHistory: [TrackingEntry(status: 'Đã tạo vận đơn từ đơn hàng ${order.code}', timestamp: now)],
                      createdAt: now, updatedAt: now);
                    final ok = await shipProv.createShipment(ship);
                    if (!mounted) return;
                    if (ok) AppSnackBar.success(context, 'Đã tạo vận đơn $code cho đơn ${order.code}');
                    else AppSnackBar.error(context, shipProv.errorMessage ?? 'Lỗi');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: bdr),
                    ),
                    child: Row(children: [
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.receipt_rounded, color: Color(0xFF7C3AED), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(order.code, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(order.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF10B981))),
                          ),
                        ]),
                        const SizedBox(height: 2),
                        Text('${order.customerName} · ${order.customerPhone}', style: TextStyle(fontSize: 12, color: ts)),
                      ])),
                      Text(order.formattedTotal, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
                      const SizedBox(width: 8),
                      Icon(Icons.arrow_forward_ios_rounded, size: 14, color: ts),
                    ]),
                  ),
                );
              },
            ),
        ),
      ])),
    )));
  }

  // ═══════════════════════  DETAIL VIEW  ═════════════════════
  Widget _buildDetailView(bool isDark, Shipment s, ShipmentProvider provider, OrderProvider orderProv) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final sc = _statusColor(s.status);

    // Find linked order
    Order? linkedOrder;
    if (s.orderId.isNotEmpty) {
      final matches = orderProv.orders.where((o) => o.id == s.orderId).toList();
      if (matches.isNotEmpty) linkedOrder = matches.first;
    }

    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Back + header
        Row(children: [
          InkWell(borderRadius: BorderRadius.circular(8), onTap: () => setState(() { _showDetail = false; _detailShipment = null; }),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back_rounded, size: 16, color: ts), const SizedBox(width: 6),
                Text('Quay lại', style: TextStyle(fontSize: 13, color: ts)),
              ]))),
          const SizedBox(width: 16),
          Text('Chi tiết vận đơn', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tp)),
          const SizedBox(width: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
            child: Text(s.trackingCode, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED), fontFamily: 'monospace'))),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(s.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc))),
          if (s.isLate) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('TRỄ HẠN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))))],
          const Spacer(),
          ElevatedButton.icon(onPressed: () => _showStatusDialog(s, provider),
            icon: const Icon(Icons.sync_rounded, size: 16), label: const Text('Cập nhật'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0)),
        ]),
        const SizedBox(height: 24),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // LEFT: Tracking timeline
          Expanded(flex: 3, child: Container(padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.timeline_rounded, size: 18, color: const Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Text('Lịch sử vận chuyển', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp)),
              ]),
              const SizedBox(height: 20),
              if (s.trackingHistory.isEmpty)
                Text('Chưa có lịch sử', style: TextStyle(fontSize: 13, color: ts))
              else ...s.trackingHistory.reversed.toList().asMap().entries.map((e) {
                final entry = e.value;
                final isFirst = e.key == 0;
                final isLast = e.key == s.trackingHistory.length - 1;
                final ec = isFirst ? const Color(0xFF7C3AED) : isDark ? Colors.white24 : const Color(0xFFD1D5DB);
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Column(children: [
                    Container(width: 14, height: 14, decoration: BoxDecoration(
                      color: isFirst ? const Color(0xFF7C3AED) : Colors.transparent,
                      shape: BoxShape.circle, border: Border.all(color: ec, width: 2))),
                    if (!isLast) Container(width: 2, height: 44, color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
                  ]),
                  const SizedBox(width: 14),
                  Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.status, style: TextStyle(fontSize: 13, fontWeight: isFirst ? FontWeight.w600 : FontWeight.w400, color: isFirst ? tp : ts)),
                    if (entry.location.isNotEmpty) Row(children: [
                      Icon(Icons.location_on_rounded, size: 12, color: ts), const SizedBox(width: 4),
                      Text(entry.location, style: TextStyle(fontSize: 12, color: ts)),
                    ]),
                    if (entry.note.isNotEmpty) Row(children: [
                      Icon(Icons.note_rounded, size: 12, color: ts), const SizedBox(width: 4),
                      Expanded(child: Text(entry.note, style: TextStyle(fontSize: 12, color: ts))),
                    ]),
                    Text(_fmtDateTime(entry.timestamp), style: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : const Color(0xFF9CA3AF))),
                  ]))),
                ]);
              }),
            ]))),
          const SizedBox(width: 20),

          // RIGHT: Info cards
          Expanded(flex: 2, child: Column(children: [
            // Receiver info
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.person_rounded, size: 18, color: const Color(0xFF3B82F6)), const SizedBox(width: 8),
                  Text('Người nhận', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp))]),
                const SizedBox(height: 16),
                _infoRow(Icons.person_outline_rounded, 'Tên', s.receiverName, tp, ts),
                _infoRow(Icons.phone_rounded, 'SĐT', s.receiverPhone, tp, ts),
                if (s.receiverAddress.isNotEmpty) _infoRow(Icons.location_on_rounded, 'Địa chỉ', s.receiverAddress, tp, ts),
              ])),
            const SizedBox(height: 16),
            // Shipment info
            Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [Icon(Icons.local_shipping_rounded, size: 18, color: const Color(0xFF8B5CF6)), const SizedBox(width: 8),
                  Text('Thông tin vận đơn', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp))]),
                const SizedBox(height: 16),
                _infoRow(Icons.business_rounded, 'Đơn vị', s.carrier, tp, ts),
                _infoRow(Icons.receipt_rounded, 'Đơn hàng', s.orderCode.isNotEmpty ? s.orderCode : '—', tp, ts),
                if (s.shippedAt != null) _infoRow(Icons.schedule_rounded, 'Ngày gửi', _fmtDate(s.shippedAt!), tp, ts),
                if (s.estimatedDelivery != null) _infoRow(Icons.event_rounded, 'Dự kiến', _fmtDate(s.estimatedDelivery!), tp, ts),
                if (s.deliveredAt != null) _infoRow(Icons.task_alt_rounded, 'Đã giao', _fmtDate(s.deliveredAt!), tp, ts),
                _infoRow(Icons.calendar_today_rounded, 'Tạo lúc', _fmtDateTime(s.createdAt), tp, ts),
              ])),
            // Linked order info
            if (linkedOrder != null) ...[
              const SizedBox(height: 16),
              Container(padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [Icon(Icons.shopping_bag_rounded, size: 18, color: const Color(0xFF10B981)), const SizedBox(width: 8),
                    Text('Đơn hàng gốc', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: tp))]),
                  const SizedBox(height: 16),
                  _infoRow(Icons.receipt_rounded, 'Mã đơn', linkedOrder.code, tp, ts),
                  _infoRow(Icons.monetization_on_rounded, 'Tổng tiền', linkedOrder.formattedTotal, tp, ts),
                  _infoRow(Icons.payment_rounded, 'Thanh toán', linkedOrder.paymentMethod, tp, ts),
                  _infoRow(Icons.info_outline_rounded, 'TT thanh toán', linkedOrder.paymentStatus, tp, ts),
                  if (linkedOrder.items.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text('Sản phẩm:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                    const SizedBox(height: 6),
                    ...linkedOrder.items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        const SizedBox(width: 26),
                        Expanded(child: Text('${item.productName}${item.variant.isNotEmpty ? ' (${item.variant})' : ''}', style: TextStyle(fontSize: 12, color: tp))),
                        Text('x${item.quantity}', style: TextStyle(fontSize: 12, color: ts)),
                      ]))),
                  ],
                ])),
            ],
          ])),
        ]),
      ]))),
    ]);
  }

  Widget _infoRow(IconData icon, String label, String value, Color tp, Color ts) {
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
      Icon(icon, size: 15, color: ts), const SizedBox(width: 10),
      SizedBox(width: 80, child: Text('$label:', style: TextStyle(fontSize: 12, color: ts))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tp))),
    ]));
  }

  // ═══════════════════════  EXPORT CSV  ═════════════════════
  void _exportCSV(List<Shipment> all) {
    final lines = <String>['Mã vận đơn,Đơn hàng,Đơn vị VC,Người nhận,SĐT,Địa chỉ,Trạng thái,Ngày tạo,Dự kiến giao,Ngày giao'];
    for (final s in all) {
      lines.add('"${s.trackingCode}","${s.orderCode}","${s.carrier}","${s.receiverName}","${s.receiverPhone}","${s.receiverAddress}","${s.status}","${_fmtDate(s.createdAt)}","${s.estimatedDelivery != null ? _fmtDate(s.estimatedDelivery!) : ''}","${s.deliveredAt != null ? _fmtDate(s.deliveredAt!) : ''}"');
    }
    // In web, show the CSV data in a dialog for copying
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 600, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text('Xuất dữ liệu CSV', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)),
          const Spacer(),
          IconButton(icon: Icon(Icons.close_rounded, color: ts, size: 20), onPressed: () => Navigator.pop(ctx)),
        ]),
        const SizedBox(height: 12),
        Text('${all.length} vận đơn · Sao chép nội dung bên dưới và dán vào file .csv', style: TextStyle(fontSize: 12, color: ts)),
        const SizedBox(height: 12),
        Container(height: 300, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: isDark ? Colors.black26 : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
          child: SelectableText(lines.join('\n'), style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: tp))),
      ])),
    ));
  }

  // ═══════════════════════  HELPERS  ═════════════════════
  Color _statusColor(String s) {
    switch (s) {
      case 'Đang xử lý': return const Color(0xFFF59E0B);
      case 'Đã lấy hàng': return const Color(0xFF8B5CF6);
      case 'Đang vận chuyển': return const Color(0xFF3B82F6);
      case 'Đang giao': return const Color(0xFFEC4899);
      case 'Đã giao': return const Color(0xFF10B981);
      case 'Hoàn hàng': return const Color(0xFFEF4444);
      case 'Giao thất bại': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }
}
