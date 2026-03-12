import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/review_model.dart';
import '../providers/review_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'admin_slide_panel.dart';

class ReviewContent extends StatefulWidget {
  const ReviewContent({super.key});

  @override
  State<ReviewContent> createState() => _ReviewContentState();
}

class _ReviewContentState extends State<ReviewContent> {
  bool get isDark => mounted ? Theme.of(context).brightness == Brightness.dark : false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _filterRating = 0; // 0 = all
  int _filterStatus = 0; // 0=all, 1=visible, 2=hidden

  bool _isPanelOpen = false;
  ReviewModel? _selectedReview;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ReviewProvider>().loadReviews();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ReviewModel> _applyFilters(List<ReviewModel> all) {
    var list = all.toList();
    // Rating filter
    if (_filterRating > 0) {
      list = list.where((r) => r.rating == _filterRating).toList();
    }
    // Status filter
    if (_filterStatus == 1) {
      list = list.where((r) => !r.isHidden).toList();
    } else if (_filterStatus == 2) {
      list = list.where((r) => r.isHidden).toList();
    }
    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) =>
          r.customerName.toLowerCase().contains(q) ||
          r.productName.toLowerCase().contains(q) ||
          r.comment.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _openDetail(ReviewModel r) {
    setState(() {
      _selectedReview = r;
      _isPanelOpen = true;
    });
  }

  void _closePanel() => setState(() => _isPanelOpen = false);

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, prov, _) {
        final filtered = _applyFilters(prov.reviews);

        return AdminSlidePanel(
          isOpen: _isPanelOpen,
          title: 'Chi tiết đánh giá',
          onClose: _closePanel,
          panelBody: _buildDetailPanel(prov),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(prov),
                const SizedBox(height: 20),
                if (prov.reviews.isNotEmpty) ...[
                  _buildStats(prov.reviews),
                  const SizedBox(height: 20),
                ],
                _buildContentCard(filtered, prov),
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
  Widget _buildHeader(ReviewProvider prov) {
    return Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Đánh giá sản phẩm',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textDark)),
          const SizedBox(height: 4),
          Text('Quản lý bình luận và đánh giá từ khách hàng',
              style: TextStyle(fontSize: 13,
                  color: isDark ? Colors.white54 : AppTheme.textLight)),
        ]),
      ),
    ]);
  }

  // ═══════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════
  Widget _buildStats(List<ReviewModel> reviews) {
    final total = reviews.length;
    final visible = reviews.where((r) => !r.isHidden).length;
    final hidden = reviews.where((r) => r.isHidden).length;
    final avgRating = total > 0
        ? reviews.fold<int>(0, (s, r) => s + r.rating) / total
        : 0.0;

    return Row(children: [
      _statCard('Tổng đánh giá', '$total', Icons.rate_review_rounded, const Color(0xFF7C3AED)),
      const SizedBox(width: 12),
      _statCard('Hiển thị', '$visible', Icons.visibility_rounded, const Color(0xFF10B981)),
      const SizedBox(width: 12),
      _statCard('Đã ẩn', '$hidden', Icons.visibility_off_rounded, const Color(0xFF6B7280)),
      const SizedBox(width: 12),
      _statCard('Trung bình', '${avgRating.toStringAsFixed(1)} ★', Icons.star_rounded, const Color(0xFFF59E0B)),
    ]);
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF111827))),
            Text(label,
                style: TextStyle(fontSize: 10,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
          ]),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CONTENT CARD
  // ═══════════════════════════════════════
  Widget _buildContentCard(List<ReviewModel> reviews, ReviewProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Search + Filters ──
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Tìm theo tên khách, sản phẩm, nội dung...',
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
            // Status filter
            Row(children: [
              Text('Trạng thái:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF374151))),
              const SizedBox(width: 10),
              _pill('Tất cả', _filterStatus == 0, () => setState(() => _filterStatus = 0)),
              _pill('Hiển thị', _filterStatus == 1, () => setState(() => _filterStatus = 1)),
              _pill('Đã ẩn', _filterStatus == 2, () => setState(() => _filterStatus = 2)),
            ]),
            const SizedBox(height: 10),
            // Rating filter
            Row(children: [
              Text('Số sao:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF374151))),
              const SizedBox(width: 10),
              _pill('Tất cả', _filterRating == 0, () => setState(() => _filterRating = 0)),
              for (int i = 5; i >= 1; i--)
                _pill('$i ★', _filterRating == i, () => setState(() => _filterRating = i)),
            ]),
            const SizedBox(height: 14),
          ]),
        ),
        Divider(height: 1, thickness: 1,
            color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF0F0F0)),
        // ── Reviews list ──
        if (prov.isLoading && reviews.isEmpty)
          const Padding(
            padding: EdgeInsets.all(60),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
          )
        else if (reviews.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.rate_review_outlined, size: 40,
                  color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFD1D5DB)),
              const SizedBox(height: 10),
              Text('Không có đánh giá nào',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
            ])),
          )
        else
          ...reviews.map((r) => _reviewCard(r, prov)),
      ]),
    );
  }

  Widget _pill(String label, bool isActive, VoidCallback onTap) {
    final color = const Color(0xFF7C3AED);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
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

  // ═══════════════════════════════════════
  // REVIEW CARD (inline list item)
  // ═══════════════════════════════════════
  Widget _reviewCard(ReviewModel r, ReviewProvider prov) {
    final ln = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6);
    final statusColor = r.isHidden
        ? const Color(0xFF6B7280)
        : const Color(0xFF10B981);
    final statusLabel = r.isHidden ? 'Đã ẩn' : 'Hiển thị';

    return InkWell(
      onTap: () => _openDetail(r),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: ln))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            child: Text(r.customerName.isNotEmpty ? r.customerName[0].toUpperCase() : '?',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(r.customerName.isNotEmpty ? r.customerName : 'Ẩn danh',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827))),
              const Spacer(),
              // Stars
              ...List.generate(5, (i) => Icon(
                  i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 16, color: const Color(0xFFF59E0B))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: statusColor)),
              ),
            ]),
            const SizedBox(height: 2),
            Text(r.productName.isNotEmpty ? r.productName : 'Sản phẩm không xác định',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
            const SizedBox(height: 6),
            Text(r.comment,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, height: 1.5,
                    color: isDark ? Colors.white70 : const Color(0xFF374151))),
            if (r.adminReply.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF5F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.reply_rounded, size: 14, color: const Color(0xFF7C3AED)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(r.adminReply,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF6B7280)))),
                ]),
              ),
            ],
            const SizedBox(height: 4),
            Text(_dateTime(r.createdAt),
                style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFFBBBBBB))),
          ])),
          const SizedBox(width: 8),
          // Quick actions
          Column(mainAxisSize: MainAxisSize.min, children: [
            if (!r.isHidden)
              _actionBtn(Icons.visibility_off_rounded, 'Ẩn', const Color(0xFF6B7280),
                  () => _doHide(prov, r))
            else
              _actionBtn(Icons.visibility_rounded, 'Hiện', const Color(0xFF3B82F6),
                  () => _doUnhide(prov, r)),
            const SizedBox(height: 4),
            _actionBtn(Icons.delete_outline_rounded, 'Xóa', const Color(0xFFEF4444),
                () => _doDelete(prov, r)),
          ]),
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
  Widget _buildDetailPanel(ReviewProvider prov) {
    final r = _selectedReview;
    if (r == null) return const SizedBox.shrink();
    final statusColor = r.isHidden ? const Color(0xFF6B7280) : const Color(0xFF10B981);
    final statusLabel = r.isHidden ? 'Đã ẩn' : 'Hiển thị';

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Status + rating
      Center(child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(statusLabel,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor)),
        ),
        const SizedBox(height: 8),
        Row(mainAxisSize: MainAxisSize.min, children: List.generate(5, (i) => Icon(
            i < r.rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: 28, color: const Color(0xFFF59E0B)))),
      ])),
      const SizedBox(height: 20),

      _detailSection('Khách hàng', [
        _detailRow('Tên', r.customerName.isNotEmpty ? r.customerName : '—'),
        _detailRow('Email', r.customerEmail.isNotEmpty ? r.customerEmail : '—'),
      ]),
      const SizedBox(height: 16),
      _detailSection('Sản phẩm', [
        _detailRow('Tên', r.productName.isNotEmpty ? r.productName : '—'),
      ]),
      const SizedBox(height: 16),
      _detailSection('Nội dung đánh giá', [
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(r.comment.isNotEmpty ? r.comment : 'Không có nội dung',
              style: TextStyle(fontSize: 12, height: 1.6,
                  color: isDark ? Colors.white70 : const Color(0xFF374151))),
        ),
      ]),
      const SizedBox(height: 16),
      _detailSection('Thời gian', [
        _detailRow('Đánh giá', _dateTime(r.createdAt)),
      ]),
      if (r.adminReply.isNotEmpty) ...[
        const SizedBox(height: 16),
        _detailSection('Phản hồi của admin', [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(r.adminReply,
                style: TextStyle(fontSize: 12,
                    color: isDark ? Colors.white70 : const Color(0xFF374151))),
          ),
        ]),
      ],
      const SizedBox(height: 24),

      // Reply input
      Text('Phản hồi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
      const SizedBox(height: 6),
      _ReplyField(
        initialText: r.adminReply,
        onSubmit: (text) => _doReply(prov, r, text),
      ),
      const SizedBox(height: 16),

      // Action buttons
      Row(children: [
        Expanded(child: OutlinedButton.icon(
          onPressed: () => r.isHidden ? _doUnhide(prov, r) : _doHide(prov, r),
          icon: Icon(r.isHidden ? Icons.visibility_rounded : Icons.visibility_off_rounded, size: 16),
          label: Text(r.isHidden ? 'Hiện lại' : 'Ẩn bình luận', style: const TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6B7280),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )),
        const SizedBox(width: 8),
        Expanded(child: OutlinedButton.icon(
          onPressed: () => _doDelete(prov, r),
          icon: const Icon(Icons.delete_outline_rounded, size: 16),
          label: const Text('Xóa', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFEF4444),
            side: const BorderSide(color: Color(0xFFEF4444)),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        )),
      ]),
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
        SizedBox(width: 80, child: Text(label,
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


  Future<void> _doHide(ReviewProvider prov, ReviewModel r) async {
    final ok = await prov.hide(r.id);
    if (!mounted) return;
    if (ok) {
      _closePanel();
      AppSnackBar.success(context, 'Đã ẩn đánh giá');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
    }
  }

  Future<void> _doUnhide(ReviewProvider prov, ReviewModel r) async {
    final ok = await prov.unhide(r.id);
    if (!mounted) return;
    if (ok) {
      _closePanel();
      AppSnackBar.success(context, 'Đã hiện lại đánh giá');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
    }
  }

  Future<void> _doDelete(ReviewProvider prov, ReviewModel r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa đánh giá', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        content: const Text('Bạn chắc chắn muốn xóa đánh giá này?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await prov.deleteReview(r.id);
    if (!mounted) return;
    if (ok) {
      _closePanel();
      AppSnackBar.success(context, 'Đã xóa đánh giá');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
    }
  }

  Future<void> _doReply(ReviewProvider prov, ReviewModel r, String text) async {
    if (text.isEmpty) return;
    final ok = await prov.reply(r.id, text);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã phản hồi');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
    }
  }

  String _dateTime(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }
}

/// Widget phản hồi có state riêng
class _ReplyField extends StatefulWidget {
  final String initialText;
  final Future<void> Function(String) onSubmit;
  const _ReplyField({required this.initialText, required this.onSubmit});

  @override
  State<_ReplyField> createState() => _ReplyFieldState();
}

class _ReplyFieldState extends State<_ReplyField> {
  late final TextEditingController _ctrl;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Expanded(child: TextField(
        controller: _ctrl,
        maxLines: 2,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: 'Nhập phản hồi...',
          hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFFBBBBBB)),
          filled: true,
          fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(12),
        ),
      )),
      const SizedBox(width: 8),
      ElevatedButton(
        onPressed: _sending ? null : () async {
          setState(() => _sending = true);
          await widget.onSubmit(_ctrl.text.trim());
          if (mounted) setState(() => _sending = false);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _sending
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.send_rounded, size: 16),
      ),
    ]);
  }
}
