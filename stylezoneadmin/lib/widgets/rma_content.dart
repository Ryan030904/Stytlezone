import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/rma_model.dart';
import '../providers/rma_provider.dart';
import '../constants/admin_enums.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

class RmaContent extends StatefulWidget {
  const RmaContent({super.key});
  @override
  State<RmaContent> createState() => _RmaContentState();
}

class _RmaContentState extends State<RmaContent> {
  final _searchCtrl = TextEditingController();
  RmaStatus? _tabStatus;
  String _searchQuery = '';
  bool _showDetail = false;
  RmaModel? _detailRma;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RmaProvider>().loadRmas());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

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

  List<RmaModel> _filtered(List<RmaModel> all) {
    var list = all.toList();
    if (_tabStatus != null) list = list.where((r) => r.status == _tabStatus).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((r) =>
        r.code.toLowerCase().contains(q) ||
        r.orderCode.toLowerCase().contains(q) ||
        r.customerName.toLowerCase().contains(q) ||
        r.customerPhone.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<RmaProvider>(builder: (_, prov, __) {
      if (_showDetail && _detailRma != null) {
        final fresh = prov.rmas.where((r) => r.id == _detailRma!.id).toList();
        if (fresh.isNotEmpty) _detailRma = fresh.first;
        return _buildDetail(isDark, _detailRma!, prov);
      }
      final list = _filtered(prov.rmas);
      return Column(children: [
        _buildHeader(isDark, prov),
        Expanded(child: prov.isLoading && prov.rmas.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildKpiRow(isDark, prov.rmas),
              const SizedBox(height: 20),
              _buildFilterBar(isDark),
              const SizedBox(height: 14),
              _buildStatusTabs(isDark),
              const SizedBox(height: 14),
              _buildTable(isDark, list, prov),
            ]))),
      ]);
    });
  }

  // ═══════════════════════  HEADER  ═══════════════════════
  Widget _buildHeader(bool isDark, RmaProvider prov) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: bdr))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quản lý đổi trả', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tp)),
          const SizedBox(height: 2),
          Text('${prov.rmas.length} phiếu đổi trả', style: TextStyle(fontSize: 13, color: ts)),
        ])),
      ]),
    );
  }

  // ═══════════════════════  KPI  ═══════════════════════
  Widget _buildKpiRow(bool isDark, List<RmaModel> all) {
    final pending = all.where((r) => r.status == RmaStatus.pendingReview).length;
    final approved = all.where((r) => r.status == RmaStatus.approved).length;
    final processing = all.where((r) => r.status == RmaStatus.processing).length;
    final completed = all.where((r) => r.status == RmaStatus.completed).length;
    final rejected = all.where((r) => r.status == RmaStatus.rejected).length;
    final totalRefund = all.where((r) => r.status == RmaStatus.completed).fold(0.0, (s, r) => s + r.refundAmount);

    final data = [
      ('Chờ duyệt', '$pending', Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
      ('Đã duyệt', '$approved', Icons.thumb_up_rounded, const Color(0xFF3B82F6)),
      ('Đang xử lý', '$processing', Icons.autorenew_rounded, const Color(0xFF8B5CF6)),
      ('Hoàn tất', '$completed', Icons.check_circle_rounded, const Color(0xFF10B981)),
      ('Từ chối', '$rejected', Icons.block_rounded, const Color(0xFFEF4444)),
      ('Tổng hoàn tiền', _fmtVND(totalRefund), Icons.payments_rounded, const Color(0xFFF97316)),
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
  Widget _buildFilterBar(bool isDark) {
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);

    return SizedBox(width: 300, height: 38, child: TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _searchQuery = v),
      style: TextStyle(fontSize: 13, color: tp),
      decoration: InputDecoration(
        hintText: 'Tìm mã phiếu, mã đơn, khách hàng...',
        hintStyle: TextStyle(fontSize: 12, color: ts),
        prefixIcon: Icon(Icons.search_rounded, size: 18, color: ts),
        filled: true, fillColor: cardBg, contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
      ),
    ));
  }

  // ═══════════════════════  STATUS TABS  ═══════════════════════
  Widget _buildStatusTabs(bool isDark) {
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tabs = <(RmaStatus?, String, Color)>[
      (null, 'Tất cả', const Color(0xFF6B7280)),
      (RmaStatus.pendingReview, 'Chờ duyệt', const Color(0xFFF59E0B)),
      (RmaStatus.approved, 'Đã duyệt', const Color(0xFF3B82F6)),
      (RmaStatus.processing, 'Đang xử lý', const Color(0xFF8B5CF6)),
      (RmaStatus.completed, 'Hoàn tất', const Color(0xFF10B981)),
      (RmaStatus.rejected, 'Từ chối', const Color(0xFFEF4444)),
    ];

    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: tabs.map((t) {
      final active = _tabStatus == t.$1;
      return Padding(padding: const EdgeInsets.only(right: 6), child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => _tabStatus = t.$1),
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? t.$3 : isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8), border: Border.all(color: active ? t.$3 : bdr)),
          child: Text(t.$2, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? Colors.white : isDark ? Colors.white70 : const Color(0xFF374151)))),
      ));
    }).toList()));
  }

  // ═══════════════════════  TABLE  ═══════════════════════
  Widget _buildTable(bool isDark, List<RmaModel> list, RmaProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final ts = isDark ? Colors.white38 : Colors.black54;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: headerBg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [
            _hdr('MÃ PHIẾU', 2, ts), _hdr('KHÁCH HÀNG', 2, ts), _hdr('LOẠI', 2, ts),
            _hdr('LÝ DO', 2, ts), _hdr('GIÁ TRỊ', 2, ts), _hdr('TRẠNG THÁI', 2, ts), _hdr('THAO TÁC', 1, ts),
          ])),
        if (list.isEmpty)
          Padding(padding: const EdgeInsets.all(48), child: Column(children: [
            Icon(Icons.assignment_return_rounded, size: 48, color: isDark ? Colors.white12 : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text('Không có phiếu đổi trả nào', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
          ]))
        else ...list.map((r) => _tableRow(r, isDark, prov)),
      ]),
    );
  }

  Widget _hdr(String t, int flex, Color c) =>
    Expanded(flex: flex, child: Text(t, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: c, letterSpacing: 0.5)));

  Widget _tableRow(RmaModel r, bool isDark, RmaProvider prov) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final sc = _statusColor(r.status);

    return InkWell(
      onTap: () => setState(() { _showDetail = true; _detailRma = r; }),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bdr))),
        child: Row(children: [
          // Code
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(r.code, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF7C3AED), fontFamily: 'monospace'),
              maxLines: 1, overflow: TextOverflow.ellipsis),
            if (r.orderCode.isNotEmpty) Text('Đơn: ${r.orderCode}', style: TextStyle(fontSize: 10, color: ts), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Customer
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(r.customerName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tp), maxLines: 1, overflow: TextOverflow.ellipsis),
            if (r.customerPhone.isNotEmpty) Text(r.customerPhone, style: TextStyle(fontSize: 11, color: ts)),
          ])),
          // Type
          Expanded(flex: 2, child: Row(children: [
            Icon(r.type == RmaType.exchange ? Icons.swap_horiz_rounded : Icons.replay_rounded,
              size: 16, color: r.type == RmaType.exchange ? const Color(0xFF3B82F6) : const Color(0xFFF97316)),
            const SizedBox(width: 6),
            Flexible(child: Text(r.typeLabel, style: TextStyle(fontSize: 12, color: tp), overflow: TextOverflow.ellipsis)),
          ])),
          // Reason
          Expanded(flex: 2, child: Text(r.reasonLabel, style: TextStyle(fontSize: 12, color: ts), maxLines: 1, overflow: TextOverflow.ellipsis)),
          // Value
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_fmtVND(r.totalItemsValue), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tp)),
            if (r.refundAmount > 0) Text('Hoàn: ${_fmtVND(r.refundAmount)}', style: const TextStyle(fontSize: 10, color: Color(0xFFF97316))),
          ])),
          // Status
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(r.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sc),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          )),
          // Actions
          Expanded(flex: 1, child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, size: 18, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            position: PopupMenuPosition.under,
            itemBuilder: (_) => [
              _popItem(Icons.visibility_rounded, 'Xem chi tiết', 'detail', tp),
              if (r.status == RmaStatus.pendingReview) ...[
                _popItem(Icons.thumb_up_rounded, 'Duyệt', 'approve', const Color(0xFF3B82F6)),
                _popItem(Icons.block_rounded, 'Từ chối', 'reject', const Color(0xFFEF4444)),
              ],
              if (r.status == RmaStatus.approved)
                _popItem(Icons.autorenew_rounded, 'Bắt đầu xử lý', 'process', const Color(0xFF8B5CF6)),
              if (r.status == RmaStatus.processing)
                _popItem(Icons.check_circle_rounded, 'Hoàn tất', 'complete', const Color(0xFF10B981)),
              _popItem(Icons.delete_rounded, 'Xóa', 'delete', const Color(0xFFEF4444)),
            ],
            onSelected: (v) => _handleAction(v, r, prov),
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
  void _handleAction(String action, RmaModel r, RmaProvider prov) async {
    switch (action) {
      case 'detail':
        setState(() { _showDetail = true; _detailRma = r; });
        break;
      case 'approve':
        _showNoteDialog('Duyệt phiếu đổi trả', 'Ghi chú duyệt...', const Color(0xFF3B82F6), (note) async {
          final ok = await prov.updateStatus(r.id, RmaStatus.approved, note: note);
          if (!mounted) return;
          if (ok) AppSnackBar.success(context, 'Đã duyệt phiếu ${r.code}');
          else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
        });
        break;
      case 'reject':
        _showNoteDialog('Từ chối phiếu đổi trả', 'Lý do từ chối...', const Color(0xFFEF4444), (note) async {
          final ok = await prov.updateStatus(r.id, RmaStatus.rejected, note: note);
          if (!mounted) return;
          if (ok) AppSnackBar.success(context, 'Đã từ chối phiếu ${r.code}');
          else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
        });
        break;
      case 'process':
        final ok = await prov.updateStatus(r.id, RmaStatus.processing);
        if (!mounted) return;
        if (ok) AppSnackBar.success(context, 'Đang xử lý phiếu ${r.code}');
        else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
        break;
      case 'complete':
        _showNoteDialog('Hoàn tất đổi trả', 'Kết quả xử lý...', const Color(0xFF10B981), (note) async {
          final ok = await prov.updateStatus(r.id, RmaStatus.completed, note: note);
          if (!mounted) return;
          if (ok) AppSnackBar.success(context, 'Hoàn tất phiếu ${r.code}');
          else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
        });
        break;
      case 'delete':
        _confirmDelete(r, prov);
        break;
    }
  }

  // ═══════════════════════  NOTE DIALOG  ═══════════════════════
  void _showNoteDialog(String title, String hint, Color color, Future<void> Function(String) onConfirm) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final noteCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 420, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(Icons.edit_note_rounded, color: color, size: 24)),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 16),
        TextField(controller: noteCtrl, maxLines: 3, style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(fontSize: 12, color: ts),
            filled: true, fillColor: cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: color, width: 1.5)),
          )),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr),
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(ctx); onConfirm(noteCtrl.text.trim()); },
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Xác nhận'))),
        ]),
      ])),
    ));
  }

  // ═══════════════════════  DELETE  ═══════════════════════
  void _confirmDelete(RmaModel r, RmaProvider prov) {
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
        Text('Xóa phiếu đổi trả?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 8),
        Text('Phiếu ${r.code} sẽ bị xóa.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: ts)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr),
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            Navigator.pop(ctx);
            final ok = await prov.deleteRma(r.id);
            if (!mounted) return;
            if (ok) AppSnackBar.success(context, 'Đã xóa phiếu ${r.code}');
            else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
          },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Xóa'))),
        ]),
      ])),
    ));
  }




  // ═══════════════════════  DETAIL VIEW  ═══════════════════════
  Widget _buildDetail(bool isDark, RmaModel r, RmaProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final sc = _statusColor(r.status);

    return Column(children: [
      // Header
      Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: bdr))),
        child: Row(children: [
          InkWell(borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() { _showDetail = false; _detailRma = null; }),
            child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF374151)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Chi tiết đổi trả', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp)),
            Row(children: [
              Text(r.code, style: TextStyle(fontSize: 12, color: ts, fontFamily: 'monospace')),
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: (r.type == RmaType.exchange ? const Color(0xFF3B82F6) : const Color(0xFFF97316)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4)),
                child: Text(r.typeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: r.type == RmaType.exchange ? const Color(0xFF3B82F6) : const Color(0xFFF97316)))),
            ]),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(color: sc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(r.statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sc))),
        ])),
      // Body
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 3, child: Column(children: [
            _card(isDark, 'Khách hàng', Icons.person_rounded, [
              _row('Tên', r.customerName, tp, ts),
              if (r.customerPhone.isNotEmpty) _row('SĐT', r.customerPhone, tp, ts),
              if (r.customerEmail.isNotEmpty) _row('Email', r.customerEmail, tp, ts),
              if (r.orderCode.isNotEmpty) _row('Mã đơn gốc', r.orderCode, tp, ts),
            ]),
            const SizedBox(height: 16),
            _card(isDark, 'Sản phẩm đổi trả (${r.items.length})', Icons.inventory_2_rounded, [
              ...r.items.map((item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.productName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
                    if (item.sku.isNotEmpty) Text('SKU: ${item.sku}', style: TextStyle(fontSize: 11, color: ts)),
                    if (item.reason.isNotEmpty) Text('Lý do: ${item.reason}', style: TextStyle(fontSize: 11, color: ts)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('x${item.quantity}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
                    Text(_fmtVND(item.totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
                  ]),
                ]),
              )),
              Padding(padding: const EdgeInsets.only(top: 4), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Tổng giá trị:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
                Text(_fmtVND(r.totalItemsValue), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))),
              ])),
            ]),
          ])),
          const SizedBox(width: 20),
          Expanded(flex: 2, child: Column(children: [
            _card(isDark, 'Thông tin xử lý', Icons.info_rounded, [
              _row('Lý do chính', r.reasonLabel, tp, ts),
              if (r.reasonNote.isNotEmpty) _row('Ghi chú', r.reasonNote, tp, ts),
              if (r.refundAmount > 0) _row('Số tiền hoàn', _fmtVND(r.refundAmount), tp, ts, valueColor: const Color(0xFFF97316)),
              if (r.refundMethod.isNotEmpty) _row('Phương thức hoàn', r.refundMethod, tp, ts),
              if (r.adminNote.isNotEmpty) _row('Ghi chú admin', r.adminNote, tp, ts),
              if (r.resolution.isNotEmpty) _row('Kết quả', r.resolution, tp, ts, valueColor: const Color(0xFF10B981)),
            ]),
            const SizedBox(height: 16),
            _card(isDark, 'Lịch sử', Icons.timeline_rounded, [
              _row('Tạo lúc', _fmtDateTime(r.createdAt), tp, ts),
              _row('Cập nhật', _fmtDateTime(r.updatedAt), tp, ts),
              if (r.createdBy.isNotEmpty) _row('Tạo bởi', r.createdBy, tp, ts),
              if (r.updatedBy.isNotEmpty) _row('Cập nhật bởi', r.updatedBy, tp, ts),
            ]),
            const SizedBox(height: 16),
            _card(isDark, 'Thao tác', Icons.touch_app_rounded, [
              const SizedBox(height: 8),
              if (r.status == RmaStatus.pendingReview) ...[
                _actionBtn('Duyệt phiếu', Icons.thumb_up_rounded, const Color(0xFF3B82F6), () => _handleAction('approve', r, prov)),
                const SizedBox(height: 8),
                _actionBtn('Từ chối', Icons.block_rounded, const Color(0xFFEF4444), () => _handleAction('reject', r, prov)),
              ],
              if (r.status == RmaStatus.approved)
                _actionBtn('Bắt đầu xử lý', Icons.autorenew_rounded, const Color(0xFF8B5CF6), () => _handleAction('process', r, prov)),
              if (r.status == RmaStatus.processing)
                _actionBtn('Hoàn tất', Icons.check_circle_rounded, const Color(0xFF10B981), () => _handleAction('complete', r, prov)),
              const SizedBox(height: 8),
            ]),
          ])),
        ]),
      )),
    ]);
  }

  Widget _card(bool isDark, String title, IconData icon, List<Widget> children) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    return Container(width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: const Color(0xFF7C3AED)), const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tp))]),
        const SizedBox(height: 12), ...children,
      ]));
  }

  Widget _row(String label, String value, Color tp, Color ts, {Color? valueColor}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
      SizedBox(width: 110, child: Text(label, style: TextStyle(fontSize: 12, color: ts))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: valueColor ?? tp), overflow: TextOverflow.ellipsis)),
    ]));

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      style: OutlinedButton.styleFrom(side: BorderSide(color: color.withValues(alpha: 0.3)),
        padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))));

  Color _statusColor(RmaStatus s) {
    switch (s) {
      case RmaStatus.pendingReview: return const Color(0xFFF59E0B);
      case RmaStatus.approved: return const Color(0xFF3B82F6);
      case RmaStatus.rejected: return const Color(0xFFEF4444);
      case RmaStatus.processing: return const Color(0xFF8B5CF6);
      case RmaStatus.completed: return const Color(0xFF10B981);
    }
  }
}
