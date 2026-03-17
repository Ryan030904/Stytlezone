import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/order_model.dart';
import '../providers/order_provider.dart';
import '../theme/app_theme.dart';

/// ──────────────────────────────────────────────
/// Đơn hàng — Order Management
/// ──────────────────────────────────────────────
class OrderContent extends StatefulWidget {
  const OrderContent({super.key});

  @override
  State<OrderContent> createState() => _OrderContentState();
}

class _OrderContentState extends State<OrderContent> {
  String _searchQuery = '';
  String _statusFilter = '';
  String? _selectedOrderId;

  static const _statusMeta = <String, (Color, IconData)>{
    'Chờ xử lý':   (Color(0xFFF59E0B), Icons.schedule_rounded),
    'Đã xác nhận':  (Color(0xFF3B82F6), Icons.check_circle_rounded),
    'Đang giao':    (Color(0xFF8B5CF6), Icons.local_shipping_rounded),
    'Đã giao':      (Color(0xFF10B981), Icons.done_all_rounded),
    'Đã hủy':       (Color(0xFFEF4444), Icons.cancel_rounded),
    'Hoàn trả':     (Color(0xFF6B7280), Icons.undo_rounded),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<OrderProvider>();
      if (prov.orders.isEmpty) prov.loadOrders();
    });
  }

  List<Order> _filter(List<Order> all) {
    var result = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((o) =>
          o.code.toLowerCase().contains(q) ||
          o.customerName.toLowerCase().contains(q) ||
          o.customerPhone.contains(q)).toList();
    }
    if (_statusFilter.isNotEmpty) {
      result = result.where((o) => o.status == _statusFilter).toList();
    }
    return result;
  }

  Color _color(String s) => _statusMeta[s]?.$1 ?? const Color(0xFF9CA3AF);
  IconData _icon(String s) => _statusMeta[s]?.$2 ?? Icons.help_outline_rounded;

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<OrderProvider>(
      builder: (context, prov, _) {
        final all = prov.orders;
        final filtered = _filter(all);
        final selectedOrder = _selectedOrderId != null
            ? all.where((o) => o.id == _selectedOrderId).firstOrNull
            : null;

        return Row(children: [
          Expanded(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(children: [
              _buildToolbar(isDark, all),
              const SizedBox(height: 12),
              Expanded(
                child: prov.isLoading && all.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                    : filtered.isEmpty
                        ? _buildEmpty(isDark)
                        : _buildTable(isDark, filtered),
              ),
            ]),
          )),
          if (selectedOrder != null) ...[
            Container(width: 1, color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
            SizedBox(width: 400, child: _buildDetail(isDark, selectedOrder, prov)),
          ],
        ]);
      },
    );
  }

  // ═══════════════════════════════════════════════
  // TOOLBAR: status tabs + search (single bar)
  // ═══════════════════════════════════════════════
  Widget _buildToolbar(bool isDark, List<Order> all) {
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Search
        SizedBox(height: 34, child: TextField(
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: 'Tìm mã đơn, tên khách, SĐT...',
            hintStyle: TextStyle(fontSize: 11, color: isDark ? Colors.white24 : const Color(0xFFBBBBBB)),
            prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF9CA3AF)),
            prefixIconConstraints: const BoxConstraints(minWidth: 32),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          ),
          onChanged: (v) => setState(() => _searchQuery = v),
        )),
        const SizedBox(height: 10),
        // Status tabs — aligned left
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            _tab('', 'Tất cả', all.length, Icons.receipt_long_rounded, isDark),
            ...OrderStatus.all.map((s) {
              final count = all.where((o) => o.status == s).length;
              return _tab(s, s, count, _icon(s), isDark);
            }),
          ]),
        ),
      ]),
    );
  }

  Widget _tab(String value, String label, int count, IconData icon, bool isDark) {
    final active = _statusFilter == value;
    final color = value.isEmpty ? const Color(0xFF7C3AED) : _color(value);

    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _statusFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: isDark ? 0.18 : 0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: active ? color.withValues(alpha: 0.25) : Colors.transparent),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 13, color: active ? color : (isDark ? Colors.white30 : const Color(0xFFBBBBBB))),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? color : (isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280)))),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: active ? color.withValues(alpha: 0.12) : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('$count', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: active ? color : (isDark ? Colors.white30 : const Color(0xFFBBBBBB)))),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TABLE
  // ═══════════════════════════════════════════════
  Widget _buildTable(bool isDark, List<Order> orders) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final hStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF));
    final hBg = isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFB);

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          color: hBg,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(children: [
            SizedBox(width: 80, child: Text('MÃ ĐƠN', style: hStyle)),
            Expanded(flex: 2, child: Text('KHÁCH HÀNG', style: hStyle)),
            SizedBox(width: 36, child: Text('SP', style: hStyle, textAlign: TextAlign.center)),
            SizedBox(width: 80, child: Text('TỔNG', style: hStyle, textAlign: TextAlign.right)),
            SizedBox(width: 60, child: Text('TT', style: hStyle, textAlign: TextAlign.center)),
            SizedBox(width: 80, child: Text('TRẠNG THÁI', style: hStyle, textAlign: TextAlign.center)),
            SizedBox(width: 80, child: Text('NGÀY', style: hStyle, textAlign: TextAlign.right)),
          ]),
        ),
        Expanded(child: ListView.builder(
          itemCount: orders.length,
          itemBuilder: (_, i) => _row(isDark, orders[i], border),
        )),
      ]),
    );
  }

  Widget _row(bool isDark, Order o, Color border) {
    final selected = _selectedOrderId == o.id;
    final sColor = _color(o.status);
    final txt = TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF374151));

    return InkWell(
      onTap: () => setState(() => _selectedOrderId = selected ? null : o.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.1 : 0.03) : null,
          border: Border(bottom: BorderSide(color: border)),
        ),
        child: Row(children: [
          SizedBox(width: 80, child: Text(o.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)))),
          Expanded(flex: 2, child: Row(children: [
            // Avatar
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              ),
              child: Center(child: Text(
                o.customerName.isNotEmpty ? o.customerName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
              )),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(o.customerName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
          ])),
          SizedBox(width: 36, child: Text('${o.items.length}', style: txt, textAlign: TextAlign.center)),
          SizedBox(width: 80, child: Text(o.formattedTotal, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), textAlign: TextAlign.right)),
          SizedBox(width: 60, child: Center(child: _payBadge(o.paymentStatus))),
          SizedBox(width: 80, child: Center(child: _badge(o.status, sColor))),
          SizedBox(width: 80, child: Text(_fmtDate(o.createdAt), style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFFBBBBBB)), textAlign: TextAlign.right)),
        ]),
      ),
    );
  }

  Widget _badge(String text, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(5)),
    child: Text(text, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: c)),
  );

  Widget _payBadge(String s) {
    final paid = s == 'Đã thanh toán';
    final c = paid ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Icon(paid ? Icons.check_circle_rounded : Icons.schedule_rounded, size: 14, color: c);
  }

  Widget _buildEmpty(bool isDark) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.receipt_long_outlined, size: 40, color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
    const SizedBox(height: 8),
    Text('Không có đơn hàng', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white24 : const Color(0xFFBBBBBB))),
  ]));

  // ═══════════════════════════════════════════════
  // DETAIL PANEL
  // ═══════════════════════════════════════════════
  Widget _buildDetail(bool isDark, Order o, OrderProvider prov) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final sColor = _color(o.status);

    return Container(color: bg, child: Column(children: [
      // Header
      Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.receipt_long_rounded, size: 16, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(o.code, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
              const SizedBox(width: 8),
              _badge(o.status, sColor),
            ]),
            Text('${_fmtDate(o.createdAt)} • ${o.paymentMethod}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
          ])),
          IconButton(
            icon: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white30 : const Color(0xFFBBBBBB)),
            onPressed: () => setState(() => _selectedOrderId = null),
            splashRadius: 14,
          ),
        ]),
      ),

      // Body
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Pipeline
          _buildPipeline(isDark, o),
          const SizedBox(height: 16),

          // Customer
          _section('Khách hàng', Icons.person_rounded, isDark),
          const SizedBox(height: 6),
          _info(o.customerName, Icons.person_outline_rounded, isDark),
          _info(o.customerPhone, Icons.phone_rounded, isDark),
          if (o.customerEmail.isNotEmpty) _info(o.customerEmail, Icons.email_outlined, isDark),
          if (o.customerAddress.isNotEmpty) _info(o.customerAddress, Icons.place_outlined, isDark),
          const SizedBox(height: 14),

          // Items
          _section('Sản phẩm (${o.items.length})', Icons.shopping_bag_rounded, isDark),
          const SizedBox(height: 6),
          ...o.items.map((item) => Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFB),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: border),
            ),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.productName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white : const Color(0xFF111827))),
                if (item.variant.isNotEmpty) Text(item.variant, style: TextStyle(fontSize: 9, color: isDark ? Colors.white30 : const Color(0xFFBBBBBB))),
              ])),
              Text('×${item.quantity}', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
              const SizedBox(width: 8),
              Text(_fmtVND(item.total), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
            ]),
          )),
          const SizedBox(height: 6),

          // Totals
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(6), border: Border.all(color: border)),
            child: Column(children: [
              _sumRow('Tạm tính', _fmtVND(o.subtotal), isDark),
              if (o.discount > 0) _sumRow('Giảm giá', '-${_fmtVND(o.discount)}', isDark, color: const Color(0xFFEF4444)),
              _sumRow('Ship', _fmtVND(o.shippingFee), isDark),
              Divider(height: 12, color: border),
              _sumRow('Tổng', o.formattedTotal, isDark, bold: true),
            ]),
          ),
          const SizedBox(height: 14),

          // Activity log
          if (o.activityLog.isNotEmpty) ...[
            _section('Hoạt động', Icons.history_rounded, isDark),
            const SizedBox(height: 6),
            ...o.activityLog.reversed.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 5, height: 5, margin: const EdgeInsets.only(top: 4, right: 6), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF7C3AED).withValues(alpha: 0.4))),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.action, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : const Color(0xFF374151))),
                  if (a.note.isNotEmpty) Text(a.note, style: TextStyle(fontSize: 9, color: isDark ? Colors.white24 : const Color(0xFFBBBBBB))),
                  Text(_fmtDate(a.timestamp), style: TextStyle(fontSize: 8, color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD1D5DB))),
                ])),
              ]),
            )),
          ],

          if (o.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            _section('Ghi chú', Icons.note_outlined, isDark),
            const SizedBox(height: 4),
            Text(o.note, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
          ],
        ]),
      )),

      // Actions
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
        child: _actions(isDark, o, prov),
      ),
    ]));
  }

  // ─── Pipeline ───
  Widget _buildPipeline(bool isDark, Order o) {
    final stages = ['Chờ xử lý', 'Đã xác nhận', 'Đang giao', 'Đã giao'];
    final cancelled = o.status == 'Đã hủy' || o.status == 'Hoàn trả';
    final cur = cancelled ? -1 : stages.indexOf(o.status);

    if (cancelled) {
      final c = _color(o.status);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: c.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: c.withValues(alpha: 0.15))),
        child: Row(children: [
          Icon(_icon(o.status), size: 16, color: c),
          const SizedBox(width: 6),
          Text(o.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final idx = i ~/ 2;
          final done = idx < cur;
          return Expanded(child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: done ? const Color(0xFF10B981) : (isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
            ),
          ));
        }
        final idx = i ~/ 2;
        final done = idx < cur;
        final active = idx == cur;
        final c = active ? _color(stages[idx]) : done ? const Color(0xFF10B981) : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB));

        return Column(mainAxisSize: MainAxisSize.min, children: [
          Builder(builder: (_) {
            final stageIcon = done ? Icons.check_rounded : _icon(stages[idx]);
            final iconColor = (done || active) ? c : (isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFBBBBBB));
            return Container(
              width: 24, height: 24,
              decoration: BoxDecoration(shape: BoxShape.circle, color: (done || active) ? c.withValues(alpha: 0.12) : c, border: Border.all(color: c, width: active ? 2 : 1)),
              child: Icon(stageIcon, size: 12, color: iconColor),
            );
          }),
          const SizedBox(height: 3),
          Text(stages[idx], style: TextStyle(fontSize: 7, fontWeight: active ? FontWeight.w700 : FontWeight.w400, color: active ? c : (isDark ? Colors.white30 : const Color(0xFFBBBBBB)))),
        ]);
      })),
    );
  }

  // ─── Actions ───
  Widget _actions(bool isDark, Order o, OrderProvider prov) {
    switch (o.status) {
      case 'Chờ xử lý':
        return Row(children: [
          _actBtn('Xác nhận', Icons.check_circle_rounded, const Color(0xFF3B82F6), () => _update(o, 'Đã xác nhận', prov)),
          const SizedBox(width: 6),
          _actBtn('Hủy', Icons.cancel_rounded, const Color(0xFFEF4444), () => _update(o, 'Đã hủy', prov)),
        ]);
      case 'Đã xác nhận':
        return Row(children: [
          _actBtn('Giao hàng', Icons.local_shipping_rounded, const Color(0xFF8B5CF6), () => _update(o, 'Đang giao', prov)),
          const SizedBox(width: 6),
          _actBtn('Hủy', Icons.cancel_rounded, const Color(0xFFEF4444), () => _update(o, 'Đã hủy', prov)),
        ]);
      case 'Đang giao':
        return Row(children: [
          _actBtn('Đã giao', Icons.done_all_rounded, const Color(0xFF10B981), () => _update(o, 'Đã giao', prov)),
          const SizedBox(width: 6),
          _actBtn('Hoàn trả', Icons.undo_rounded, const Color(0xFF6B7280), () => _update(o, 'Hoàn trả', prov)),
        ]);
      case 'Đã giao':
        return Row(children: [
          _actBtn('Hoàn trả', Icons.undo_rounded, const Color(0xFF6B7280), () => _update(o, 'Hoàn trả', prov)),
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actBtn(String label, IconData icon, Color c, VoidCallback onTap) => Expanded(child: SizedBox(height: 32, child: ElevatedButton.icon(
    onPressed: onTap, icon: Icon(icon, size: 14),
    label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    style: ElevatedButton.styleFrom(backgroundColor: c, foregroundColor: Colors.white, elevation: 0, padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7))),
  )));

  Future<void> _update(Order o, String s, OrderProvider prov) async {
    await prov.updateStatus(o.id, s, note: 'Admin → $s');
  }

  // ─── Helpers ───
  Widget _section(String t, IconData icon, bool isDark) => Row(children: [
    Icon(icon, size: 13, color: const Color(0xFF7C3AED)),
    const SizedBox(width: 5),
    Text(t, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
  ]);

  Widget _info(String t, IconData icon, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(children: [
      Icon(icon, size: 12, color: isDark ? Colors.white24 : const Color(0xFFBBBBBB)),
      const SizedBox(width: 5),
      Flexible(child: Text(t, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF374151)))),
    ]),
  );

  Widget _sumRow(String l, String v, bool isDark, {bool bold = false, Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(l, style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
      Text(v, style: TextStyle(fontSize: bold ? 12 : 10, fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: color ?? (isDark ? Colors.white : const Color(0xFF111827)))),
    ]),
  );

  String _fmtVND(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mn';
  }
}
