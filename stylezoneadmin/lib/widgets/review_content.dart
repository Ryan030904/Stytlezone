import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:provider/provider.dart';
import '../models/review_model.dart';
import '../providers/review_provider.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'admin_slide_panel.dart';

/// ──────────────────────────────────────────────
/// REVIEW MANAGEMENT
/// ──────────────────────────────────────────────
class ReviewContent extends StatefulWidget {
  const ReviewContent({super.key});
  @override
  State<ReviewContent> createState() => _ReviewContentState();
}

class _ReviewContentState extends State<ReviewContent> {
  // ─── Filters ───
  String _searchQuery = '';
  String _ratingFilter = 'all'; // all, 5, 4, 3, 2, 1
  String _statusFilter = 'all'; // all, visible, hidden

  // ─── Panel ───
  bool _panelOpen = false;
  ReviewModel? _selectedReview;
  final _replyCtrl = TextEditingController();

  void _closePanelOnTabSwitch() {
    if (_panelOpen) setState(() => _panelOpen = false);
  }

  @override
  void initState() {
    super.initState();
    DashboardScreen.panelCloseNotifier.addListener(_closePanelOnTabSwitch);
    Future.microtask(() {
      final prov = context.read<ReviewProvider>();
      if (prov.reviews.isEmpty) prov.loadReviews();
    });
  }

  @override
  void dispose() {
    DashboardScreen.panelCloseNotifier.removeListener(_closePanelOnTabSwitch);
    _replyCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ───
  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtDateTime(DateTime d) => '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  List<ReviewModel> _filtered(List<ReviewModel> all) {
    var list = all.toList();
    if (_ratingFilter != 'all') {
      final r = int.tryParse(_ratingFilter) ?? 0;
      list = list.where((rv) => rv.rating == r).toList();
    }
    if (_statusFilter == 'visible') list = list.where((rv) => !rv.isHidden).toList();
    if (_statusFilter == 'hidden') list = list.where((rv) => rv.isHidden).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((rv) =>
        rv.customerName.toLowerCase().contains(q) ||
        rv.comment.toLowerCase().contains(q) ||
        rv.productName.toLowerCase().contains(q) ||
        rv.customerEmail.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  void _openDetail(ReviewModel r) {
    _replyCtrl.text = r.adminReply;
    setState(() { _selectedReview = r; _panelOpen = true; });
  }

  void _closePanel() => setState(() { _panelOpen = false; _selectedReview = null; });

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<ReviewProvider>(builder: (_, prov, __) {
      final filtered = _filtered(prov.reviews);
      return Stack(children: [
        Column(children: [
          _buildHeader(isDark, prov),
          Expanded(child: prov.isLoading && prov.reviews.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _buildKpiRow(isDark, prov.reviews),
                  const SizedBox(height: 16),
                  _buildTable(isDark, filtered, prov),
                ]),
              )),
        ]),
        // Slide panel
        if (_panelOpen && _selectedReview != null)
          AdminSlidePanel(
            isOpen: _panelOpen,
            onClose: _closePanel,
            title: 'Chi tiết đánh giá',
            child: _buildPanelContent(isDark, prov),
          ),
      ]);
    });
  }

  // ═══════════════════════════════════════════════
  // HEADER BAR
  // ═══════════════════════════════════════════════
  Widget _buildHeader(bool isDark, ReviewProvider prov) {
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
              // Search
              SizedBox(width: 320, height: 36, child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên, bình luận, sản phẩm...',
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
              // Rating filter
              _dropdown(isDark: isDark, value: _ratingFilter, hint: 'Rating', width: 120, items: [
                const DropdownMenuItem(value: 'all', child: Text('Tất cả sao', style: TextStyle(fontSize: 12))),
                ...List.generate(5, (i) => DropdownMenuItem(value: '${5 - i}', child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('${5 - i}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 3),
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                ]))),
              ], onChanged: (v) => setState(() => _ratingFilter = v ?? 'all')),
              const SizedBox(width: 12),
              // Status filter
              _dropdown(isDark: isDark, value: _statusFilter, hint: 'Trạng thái', width: 140, items: const [
                DropdownMenuItem(value: 'all', child: Text('Tất cả', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'visible', child: Text('Đang hiện', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'hidden', child: Text('Đã ẩn', style: TextStyle(fontSize: 12))),
              ], onChanged: (v) => setState(() => _statusFilter = v ?? 'all')),
            ]),
          ),
        ),
        const SizedBox(width: 16),
        // Refresh
        SizedBox(height: 36, child: OutlinedButton.icon(
          onPressed: () => prov.loadReviews(),
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

  Widget _dropdown({required bool isDark, required String value, required String hint, required double width, required List<DropdownMenuItem<String>> items, required ValueChanged<String?> onChanged}) {
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
        hint: Text(hint, style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
        items: items,
        onChanged: onChanged,
      )),
    ));
  }

  // ═══════════════════════════════════════════════
  // KPI CARDS
  // ═══════════════════════════════════════════════
  Widget _buildKpiRow(bool isDark, List<ReviewModel> all) {
    final total = all.length;
    final avgRating = total > 0 ? all.map((r) => r.rating).reduce((a, b) => a + b) / total : 0.0;
    final hidden = all.where((r) => r.isHidden).length;
    final fiveStar = all.where((r) => r.rating == 5).length;

    final data = [
      ('Tổng đánh giá', '$total', Icons.rate_review_rounded, const Color(0xFF7C3AED)),
      ('Rating TB', avgRating.toStringAsFixed(1), Icons.star_rounded, const Color(0xFFF59E0B)),
      ('Đã ẩn', '$hidden', Icons.visibility_off_rounded, const Color(0xFFEF4444)),
      ('5 sao', '$fiveStar', Icons.thumb_up_rounded, const Color(0xFF10B981)),
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
  // REVIEW TABLE
  // ═══════════════════════════════════════════════
  Widget _buildTable(bool isDark, List<ReviewModel> reviews, ReviewProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final hs = isDark ? Colors.white38 : Colors.black45;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Header
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            Expanded(flex: 1, child: Text('#', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
            Expanded(flex: 3, child: Text('KHÁCH HÀNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 3, child: Text('SẢN PHẨM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('RATING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: Text('BÌNH LUẬN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('NGÀY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('TRẠNG THÁI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
            Expanded(flex: 2, child: Text('THAO TÁC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
          ]),
        ),
        // Rows
        if (reviews.isEmpty)
          Padding(padding: const EdgeInsets.all(48), child: Column(children: [
            Container(width: 72, height: 72,
              decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.rate_review_rounded, size: 36, color: Color(0xFF7C3AED))),
            const SizedBox(height: 16),
            Text('Chưa có đánh giá nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151))),
            const SizedBox(height: 6),
            Text('Đánh giá từ khách hàng sẽ hiển thị ở đây', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
          ]))
        else
          ...reviews.asMap().entries.map((e) => _tableRow(isDark, e.key + 1, e.value, prov, bdr)),
      ]),
    );
  }

  Widget _tableRow(bool isDark, int idx, ReviewModel r, ReviewProvider prov, Color bdr) {
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);

    return InkWell(
      onTap: () => _openDetail(r),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bdr.withValues(alpha: 0.5)))),
        child: Row(children: [
          Expanded(flex: 1, child: Text('$idx', style: TextStyle(fontSize: 12, color: ts), textAlign: TextAlign.center)),
          // Customer
          Expanded(flex: 3, child: Row(children: [
            _customerAvatar(r, 14),
            const SizedBox(width: 8),
            Flexible(child: Text(r.customerName.isNotEmpty ? r.customerName : 'Ẩn danh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tp), maxLines: 1, overflow: TextOverflow.ellipsis)),
          ])),
          // Product
          Expanded(flex: 3, child: Text(r.productName, style: TextStyle(fontSize: 12, color: ts), maxLines: 1, overflow: TextOverflow.ellipsis)),
          // Rating
          Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('${r.rating}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: tp)),
            const SizedBox(width: 2),
            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
          ])),
          const SizedBox(width: 12),
          // Comment
          Expanded(flex: 5, child: Row(children: [
            Flexible(child: Text(r.comment, style: TextStyle(fontSize: 12, color: ts), maxLines: 2, overflow: TextOverflow.ellipsis)),
            if (r.imageUrls.isNotEmpty) ...[
              const SizedBox(width: 4),
              Icon(Icons.image_rounded, size: 14, color: isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
              Text(' ${r.imageUrls.length}', style: TextStyle(fontSize: 10, color: ts)),
            ],
            if (r.adminReply.isNotEmpty) ...[
              const SizedBox(width: 4),
              const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF7C3AED)),
            ],
          ])),
          // Date
          Expanded(flex: 2, child: Text(_fmtDate(r.createdAt), style: TextStyle(fontSize: 11, color: ts))),
          // Status
          Expanded(flex: 2, child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: r.isHidden ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(r.isHidden ? 'Đã ẩn' : 'Hiển thị', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: r.isHidden ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
          ))),
          // Actions
          Expanded(flex: 2, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _actionIcon(Icons.visibility_outlined, const Color(0xFF3B82F6), () => _openDetail(r)),
            const SizedBox(width: 2),
            r.isHidden
              ? _actionIcon(Icons.visibility_rounded, const Color(0xFF10B981), () => _doUnhide(r, prov))
              : _actionIcon(Icons.visibility_off_rounded, const Color(0xFFF59E0B), () => _doHide(r, prov)),
            const SizedBox(width: 2),
            _actionIcon(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _confirmDelete(r, prov)),
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

  Widget _customerAvatar(ReviewModel r, double radius) {
    final color = const Color(0xFF7C3AED);
    if (r.customerAvatar.isNotEmpty) {
      final viewType = 'review-avatar-${r.id}-$radius';
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final img = web.HTMLImageElement()
          ..src = r.customerAvatar
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '50%';
        return img;
      });
      return Container(
        width: radius * 2, height: radius * 2,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
        child: ClipOval(child: HtmlElementView(viewType: viewType)),
      );
    }
    return Container(
      width: radius * 2, height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
      child: Center(child: Text(
        r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : '?',
        style: TextStyle(fontSize: radius * 0.8, fontWeight: FontWeight.w700, color: color),
      )),
    );
  }

  // ═══════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════
  Future<void> _doHide(ReviewModel r, ReviewProvider prov) async {
    final ok = await prov.hide(r.id);
    if (!mounted) return;
    if (ok) AppSnackBar.success(context, 'Đã ẩn đánh giá');
    else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
  }

  Future<void> _doUnhide(ReviewModel r, ReviewProvider prov) async {
    final ok = await prov.unhide(r.id);
    if (!mounted) return;
    if (ok) AppSnackBar.success(context, 'Đã bỏ ẩn đánh giá');
    else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
  }

  void _confirmDelete(ReviewModel r, ReviewProvider prov) {
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
        Text('Xoá đánh giá?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 8),
        Text('Đánh giá của "${r.customerName}" về "${r.productName}" sẽ bị xoá vĩnh viễn.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: ts)),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr),
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            Navigator.pop(ctx);
            final ok = await prov.deleteReview(r.id);
            if (!mounted) return;
            if (ok) { AppSnackBar.success(context, 'Đã xoá đánh giá'); _closePanel(); }
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
  Widget _buildPanelContent(bool isDark, ReviewProvider prov) {
    final r = _selectedReview!;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ─── Customer info ───
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: bdr)),
          child: Row(children: [
            _customerAvatar(r, 24),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.customerName.isNotEmpty ? r.customerName : 'Ẩn danh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tp)),
              if (r.customerEmail.isNotEmpty) Text(r.customerEmail, style: TextStyle(fontSize: 11, color: ts)),
              Text(_fmtDateTime(r.createdAt), style: TextStyle(fontSize: 11, color: ts)),
            ])),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: r.isHidden ? const Color(0xFFEF4444).withValues(alpha: 0.1) : const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(r.isHidden ? 'Đã ẩn' : 'Hiển thị', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: r.isHidden ? const Color(0xFFEF4444) : const Color(0xFF10B981))),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // ─── Product ───
        _sectionLabel('Sản phẩm', Icons.shopping_bag_rounded, isDark),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
          child: Text(r.productName.isNotEmpty ? r.productName : 'N/A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tp)),
        ),
        const SizedBox(height: 16),

        // ─── Rating ───
        _sectionLabel('Đánh giá', Icons.star_rounded, isDark),
        const SizedBox(height: 8),
        Row(children: List.generate(5, (i) => Icon(
          i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: 28, color: const Color(0xFFF59E0B),
        ))),
        const SizedBox(height: 16),

        // ─── Comment ───
        _sectionLabel('Bình luận', Icons.comment_rounded, isDark),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
          child: Text(r.comment.isNotEmpty ? r.comment : '(Không có bình luận)', style: TextStyle(fontSize: 13, color: tp, height: 1.5)),
        ),
        const SizedBox(height: 16),

        // ─── Images ───
        if (r.imageUrls.isNotEmpty) ...[
          _sectionLabel('Ảnh đính kèm (${r.imageUrls.length})', Icons.photo_library_rounded, isDark),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: r.imageUrls.map((url) => ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 80, height: 80,
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
                child: const Icon(Icons.broken_image_rounded, color: Color(0xFFD1D5DB)))),
          )).toList()),
          const SizedBox(height: 16),
        ],

        // ─── Admin actions ───
        Row(children: [
          Expanded(child: r.isHidden
            ? ElevatedButton.icon(
                onPressed: () async { await _doUnhide(r, prov); _closePanel(); },
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: const Text('Bỏ ẩn', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )
            : ElevatedButton.icon(
                onPressed: () async { await _doHide(r, prov); _closePanel(); },
                icon: const Icon(Icons.visibility_off_rounded, size: 16),
                label: const Text('Ẩn bình luận', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              )),
          const SizedBox(width: 8),
          SizedBox(height: 40, child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(r, prov),
            icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFFEF4444)),
            label: const Text('Xoá', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFEF4444)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          )),
        ]),
        const SizedBox(height: 20),

        // ─── Admin reply ───
        _sectionLabel('Phản hồi từ admin', Icons.reply_rounded, isDark),
        const SizedBox(height: 8),
        if (r.adminReply.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.adminReply, style: TextStyle(fontSize: 13, color: tp, height: 1.4)),
              if (r.adminReplyAt != null) ...[
                const SizedBox(height: 6),
                Text(_fmtDateTime(r.adminReplyAt!), style: TextStyle(fontSize: 10, color: ts)),
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
            final ok = await prov.reply(r.id, _replyCtrl.text.trim());
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

  Widget _sectionLabel(String text, IconData icon, bool isDark) => Row(children: [
    Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
    const SizedBox(width: 6),
    Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
  ]);
}
