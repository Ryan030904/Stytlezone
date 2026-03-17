import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/feedback_model.dart';
import '../providers/feedback_provider.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'admin_slide_panel.dart';

/// ──────────────────────────────────────────────
/// FEEDBACK MANAGEMENT
/// ──────────────────────────────────────────────
class FeedbackContent extends StatefulWidget {
  const FeedbackContent({super.key});
  @override
  State<FeedbackContent> createState() => _FeedbackContentState();
}

class _FeedbackContentState extends State<FeedbackContent> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, pending, replied, closed
  String _subjectFilter = 'all'; // all, order, product, return, business, other

  bool _panelOpen = false;
  FeedbackModel? _selected;
  final _replyCtrl = TextEditingController();

  void _closePanelOnTabSwitch() {
    if (_panelOpen) setState(() => _panelOpen = false);
  }

  @override
  void initState() {
    super.initState();
    DashboardScreen.panelCloseNotifier.addListener(_closePanelOnTabSwitch);
    Future.microtask(() {
      final prov = context.read<FeedbackProvider>();
      if (prov.feedbacks.isEmpty) prov.loadFeedbacks();
    });
  }

  @override
  void dispose() {
    DashboardScreen.panelCloseNotifier.removeListener(_closePanelOnTabSwitch);
    _replyCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtDateTime(DateTime d) => '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  List<FeedbackModel> _filtered(List<FeedbackModel> all) {
    var list = all.toList();
    if (_statusFilter != 'all') list = list.where((f) => f.status == _statusFilter).toList();
    if (_subjectFilter != 'all') list = list.where((f) => f.subject == _subjectFilter).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((f) =>
        f.name.toLowerCase().contains(q) ||
        f.email.toLowerCase().contains(q) ||
        f.message.toLowerCase().contains(q) ||
        f.phone.contains(q)
      ).toList();
    }
    return list;
  }

  void _openDetail(FeedbackModel f) {
    _replyCtrl.text = f.adminReply;
    setState(() { _selected = f; _panelOpen = true; });
  }

  void _closePanel() => setState(() { _panelOpen = false; _selected = null; });

  Color _statusColor(String status) {
    switch (status) {
      case 'replied': return const Color(0xFF10B981);
      case 'closed': return const Color(0xFF6B7280);
      default: return const Color(0xFFF59E0B);
    }
  }

  Color _subjectColor(String subject) {
    switch (subject) {
      case 'order': return const Color(0xFF3B82F6);
      case 'product': return const Color(0xFF7C3AED);
      case 'return': return const Color(0xFFEF4444);
      case 'business': return const Color(0xFF10B981);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<FeedbackProvider>(builder: (_, prov, __) {
      final filtered = _filtered(prov.feedbacks);
      final mainContent = Column(children: [
        _buildHeader(isDark, prov),
        Expanded(child: prov.isLoading && prov.feedbacks.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildKpiRow(isDark, prov.feedbacks),
                const SizedBox(height: 16),
                _buildTable(isDark, filtered, prov),
              ]),
            )),
      ]);

      return AdminSlidePanel(
        isOpen: _panelOpen && _selected != null,
        onClose: _closePanel,
        title: 'Chi tiết phản hồi',
        panelBody: (_panelOpen && _selected != null) ? _buildPanelContent(isDark, prov) : null,
        child: mainContent,
      );
    });
  }

  // ═══════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader(bool isDark, FeedbackProvider prov) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: border))),
      child: Row(children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              SizedBox(width: 320, height: 36, child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, email, nội dung...',
                  hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                ),
              )),
              const SizedBox(width: 12),
              _dropdown(isDark: isDark, value: _statusFilter, width: 140, items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'pending', child: Text('Chờ xử lý', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'replied', child: Text('Đã phản hồi', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'closed', child: Text('Đã đóng', style: TextStyle(fontSize: 12))),
              ], onChanged: (v) => setState(() => _statusFilter = v ?? 'all')),
              const SizedBox(width: 12),
              _dropdown(isDark: isDark, value: _subjectFilter, width: 140, items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả chủ đề', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'order', child: Text('Đơn hàng', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'product', child: Text('Sản phẩm', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'return', child: Text('Đổi trả', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'business', child: Text('Hợp tác', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'other', child: Text('Khác', style: TextStyle(fontSize: 12))),
              ], onChanged: (v) => setState(() => _subjectFilter = v ?? 'all')),
            ]),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(height: 36, child: OutlinedButton.icon(
          onPressed: () => prov.loadFeedbacks(),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Làm mới', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF7C3AED),
            side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )),
      ]),
    );
  }

  Widget _dropdown({required bool isDark, required String value, required double width, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return SizedBox(width: width, child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(
        isExpanded: true,
        value: value,
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
        items: items,
        onChanged: onChanged,
      )),
    ));
  }

  // ═══════════════════════════════════════════════
  // KPI
  // ═══════════════════════════════════════════════
  Widget _buildKpiRow(bool isDark, List<FeedbackModel> all) {
    final total = all.length;
    final pending = all.where((f) => f.status == 'pending').length;
    final replied = all.where((f) => f.status == 'replied').length;
    final closed = all.where((f) => f.status == 'closed').length;

    final data = [
      ('Tổng phản hồi', '$total', Icons.inbox_rounded, const Color(0xFF7C3AED)),
      ('Chờ xử lý', '$pending', Icons.pending_rounded, const Color(0xFFF59E0B)),
      ('Đã phản hồi', '$replied', Icons.reply_rounded, const Color(0xFF10B981)),
      ('Đã đóng', '$closed', Icons.check_circle_rounded, const Color(0xFF6B7280)),
    ];

    return Wrap(spacing: 14, runSpacing: 14, children: data.map((d) => SizedBox(
      width: (MediaQuery.of(context).size.width - 260 - 48 - 42) / 4,
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
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tp)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: ts), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }

  // ═══════════════════════════════════════════════
  // TABLE
  // ═══════════════════════════════════════════════
  Widget _buildTable(bool isDark, List<FeedbackModel> list, FeedbackProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final hs = isDark ? Colors.white38 : Colors.black45;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            Expanded(flex: 1, child: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
            Expanded(flex: 3, child: Text('NGƯỜI GỬI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('CHỦ ĐỀ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: Text('NỘI DUNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('NGÀY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('TRẠNG THÁI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text('THAO TÁC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
          ]),
        ),
        if (list.isEmpty)
          Padding(padding: const EdgeInsets.all(48), child: Column(children: [
            Container(width: 72, height: 72,
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.inbox_rounded, size: 36, color: Color(0xFF7C3AED))),
            const SizedBox(height: 16),
            Text('Chưa có phản hồi nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151))),
            const SizedBox(height: 6),
            Text('Phản hồi từ khách hàng sẽ hiển thị ở đây', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
          ]))
        else
          ...list.asMap().entries.map((e) => _tableRow(isDark, e.key + 1, e.value, prov, bdr)),
      ]),
    );
  }

  Widget _tableRow(bool isDark, int idx, FeedbackModel f, FeedbackProvider prov, Color bdr) {
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return InkWell(
      onTap: () => _openDetail(f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bdr.withValues(alpha: 0.5)))),
        child: Row(children: [
          Expanded(flex: 1, child: Text('$idx', style: TextStyle(fontSize: 12, color: ts), textAlign: TextAlign.center)),
          // Sender
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(f.name.isNotEmpty ? f.name : 'Ẩn danh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tp), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(f.email, style: TextStyle(fontSize: 10, color: ts), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          // Subject
          Expanded(flex: 2, child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _subjectColor(f.subject).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(f.subjectLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _subjectColor(f.subject))),
          ))),
          const SizedBox(width: 12),
          // Message
          Expanded(flex: 5, child: Row(children: [
            Flexible(child: Text(f.message, style: TextStyle(fontSize: 12, color: ts), maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (f.adminReply.isNotEmpty) ...[
              const SizedBox(width: 4),
              const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF7C3AED)),
            ],
          ])),
          // Date
          Expanded(flex: 2, child: Text(_fmtDate(f.createdAt), style: TextStyle(fontSize: 11, color: ts))),
          // Status
          Expanded(flex: 2, child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: _statusColor(f.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
            child: Text(f.statusLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusColor(f.status))),
          ))),
          // Actions
          Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _actionIcon(Icons.visibility_outlined, const Color(0xFF3B82F6), () => _openDetail(f)),
            const SizedBox(width: 2),
            if (f.status == 'pending')
              _actionIcon(Icons.reply_rounded, const Color(0xFF7C3AED), () => _openDetail(f))
            else if (f.status == 'replied')
              _actionIcon(Icons.check_circle_outline_rounded, const Color(0xFF6B7280), () => _doClose(f, prov))
            else
              _actionIcon(Icons.refresh_rounded, const Color(0xFF10B981), () => _doReopen(f, prov)),
            const SizedBox(width: 2),
            _actionIcon(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _confirmDelete(f, prov)),
          ])),
        ]),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) => InkWell(
    borderRadius: BorderRadius.circular(6),
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 16, color: color)),
  );

  // ═══════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════
  Future<void> _doClose(FeedbackModel f, FeedbackProvider prov) async {
    final ok = await prov.close(f.id);
    if (!mounted) return;
    if (ok) AppSnackBar.success(context, 'Đã đóng phản hồi');
    else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
  }

  Future<void> _doReopen(FeedbackModel f, FeedbackProvider prov) async {
    final ok = await prov.reopen(f.id);
    if (!mounted) return;
    if (ok) AppSnackBar.success(context, 'Đã mở lại phản hồi');
    else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
  }

  void _confirmDelete(FeedbackModel f, FeedbackProvider prov) {
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
        Text('Xoá phản hồi?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 8),
        Text('Phản hồi từ "${f.name}" sẽ bị xoá vĩnh viễn.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: ts)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr),
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            Navigator.pop(ctx);
            final ok = await prov.deleteFeedback(f.id);
            if (!mounted) return;
            if (ok) { AppSnackBar.success(context, 'Đã xoá phản hồi'); _closePanel(); }
            else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
          },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Xoá'))),
        ]),
      ])),
    ));
  }

  // ═══════════════════════════════════════════════
  // DETAIL PANEL
  // ═══════════════════════════════════════════════
  Widget _buildPanelContent(bool isDark, FeedbackProvider prov) {
    final f = _selected!;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Sender info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: bdr)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF7C3AED).withValues(alpha: 0.1)),
                child: Center(child: Text(f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED))))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(f.name.isNotEmpty ? f.name : 'Ẩn danh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tp)),
                Text(f.email, style: TextStyle(fontSize: 11, color: ts)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _statusColor(f.status).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(f.statusLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(f.status))),
              ),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              if (f.phone.isNotEmpty) ...[
                Icon(Icons.phone_rounded, size: 14, color: ts),
                const SizedBox(width: 4),
                Text(f.phone, style: TextStyle(fontSize: 11, color: ts)),
                const SizedBox(width: 16),
              ],
              Icon(Icons.access_time_rounded, size: 14, color: ts),
              const SizedBox(width: 4),
              Text(_fmtDateTime(f.createdAt), style: TextStyle(fontSize: 11, color: ts)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // Subject
        _sectionLabel('Chủ đề', Icons.topic_rounded, isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: _subjectColor(f.subject).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(f.subjectLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _subjectColor(f.subject))),
        ),
        const SizedBox(height: 16),

        // Message
        _sectionLabel('Nội dung', Icons.message_rounded, isDark),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
          child: Text(f.message, style: TextStyle(fontSize: 13, color: tp, height: 1.5)),
        ),
        const SizedBox(height: 16),

        // Actions
        Row(children: [
          if (f.status == 'pending') ...[
            Expanded(child: _actionButton('Đóng', Icons.check_circle_outline_rounded, const Color(0xFF6B7280),
              () async {
                await _doClose(f, prov);
                _closePanel();
              })),
          ] else if (f.status == 'replied') ...[
            Expanded(child: _actionButton('Đóng', Icons.check_circle_outline_rounded, const Color(0xFF6B7280),
              () async {
                await _doClose(f, prov);
                _closePanel();
              })),
          ] else ...[
            Expanded(child: _actionButton('Mở lại', Icons.refresh_rounded, const Color(0xFF10B981),
              () async {
                await _doReopen(f, prov);
                _closePanel();
              })),
          ],
          const SizedBox(width: 8),
          SizedBox(height: 40, child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(f, prov),
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
            label: const Text('Xoá', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
        ]),
        const SizedBox(height: 20),

        // Admin reply
        _sectionLabel('Phản hồi từ admin', Icons.reply_rounded, isDark),
        const SizedBox(height: 8),
        if (f.adminReply.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.adminReply, style: TextStyle(fontSize: 13, color: tp, height: 1.4)),
              if (f.adminReplyAt != null) ...[
                const SizedBox(height: 6),
                Text(_fmtDateTime(f.adminReplyAt!), style: TextStyle(fontSize: 10, color: ts)),
              ],
            ]),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _replyCtrl,
          maxLines: 3,
          style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(
            hintText: 'Nhập phản hồi cho khách hàng...',
            hintStyle: TextStyle(fontSize: 12, color: ts),
            filled: true, fillColor: cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, height: 40, child: ElevatedButton.icon(
          onPressed: () async {
            if (_replyCtrl.text.trim().isEmpty) { AppSnackBar.error(context, 'Vui lòng nhập nội dung phản hồi'); return; }
            final ok = await prov.reply(f.id, _replyCtrl.text.trim());
            if (!mounted) return;
            if (ok) { AppSnackBar.success(context, 'Đã gửi phản hồi'); _closePanel(); }
            else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
          },
          icon: const Icon(Icons.send_rounded, size: 16),
          label: const Text('Gửi phản hồi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        )),
      ]),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) =>
    SizedBox(height: 40, child: ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14), elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    ));

  Widget _sectionLabel(String text, IconData icon, bool isDark) => Row(children: [
    Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
    const SizedBox(width: 6),
    Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
  ]);
}
