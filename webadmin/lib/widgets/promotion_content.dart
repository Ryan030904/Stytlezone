import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/promotion_model.dart';
import '../providers/promotion_provider.dart';
import '../utils/app_snackbar.dart';

class PromotionContent extends StatefulWidget {
  const PromotionContent({super.key});
  @override
  State<PromotionContent> createState() => _PromotionContentState();
}

class _PromotionContentState extends State<PromotionContent> {
  int _selectedFilter = 0;
  String _searchQuery = '';
  static const _filters = ['Tất cả', 'Đang chạy', 'Sắp tới', 'Đã kết thúc'];

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<PromotionProvider>(
        context,
        listen: false,
      ).loadPromotions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<PromotionProvider>(
      builder: (context, provider, _) {
        final all = provider.promotions;
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

  List<Promotion> _applyFilters(List<Promotion> all) {
    var list = all.toList();
    if (_selectedFilter == 1)
      list = list.where((p) => p.status == 'Đang chạy').toList();
    if (_selectedFilter == 2)
      list = list.where((p) => p.status == 'Sắp tới').toList();
    if (_selectedFilter == 3)
      list = list.where((p) => p.status == 'Đã kết thúc').toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (p) =>
                p.code.toLowerCase().contains(q) ||
                p.name.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  // ═══════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════
  Widget _header(bool isDark, List<Promotion> all) {
    final txtPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final txtSecondary = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF6B7280);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý khuyến mãi',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: txtPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tạo và quản lý mã giảm giá cho cửa hàng',
              style: TextStyle(fontSize: 14, color: txtSecondary),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showPromotionDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tạo khuyến mãi'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════
  Widget _statsRow(bool isDark, List<Promotion> all) {
    final running = all.where((p) => p.status == 'Đang chạy').length;
    final upcoming = all.where((p) => p.status == 'Sắp tới').length;
    final ended = all.where((p) => p.status == 'Đã kết thúc').length;
    return Row(
      children: [
        Expanded(
          child: _statCard(
            isDark,
            'Tổng mã',
            '${all.length}',
            Icons.confirmation_number_rounded,
            const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            isDark,
            'Đang chạy',
            '$running',
            Icons.play_circle_rounded,
            const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            isDark,
            'Sắp tới',
            '$upcoming',
            Icons.schedule_rounded,
            const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            isDark,
            'Đã kết thúc',
            '$ended',
            Icons.stop_circle_rounded,
            const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    bool isDark,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E7EB);
    final txtPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final txtSecondary = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: txtPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: txtSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TOOLBAR
  // ═══════════════════════════════════════════
  Widget _toolbar(bool isDark) {
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E7EB);
    final txtSecondary = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF6B7280);
    return Row(
      children: [
        // Search
        SizedBox(
          width: 280,
          height: 40,
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
            decoration: InputDecoration(
              hintText: 'Tìm mã hoặc tên khuyến mãi...',
              hintStyle: TextStyle(fontSize: 13, color: txtSecondary),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: txtSecondary,
              ),
              filled: true,
              fillColor: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderClr),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: borderClr),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF7C3AED),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Filter tabs
        ..._filters.asMap().entries.map((e) {
          final isActive = _selectedFilter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF7C3AED)
                        : isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isActive ? const Color(0xFF7C3AED) : borderClr,
                    ),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? Colors.white
                          : isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // TABLE
  // ═══════════════════════════════════════════
  Widget _table(bool isDark, List<Promotion> list, PromotionProvider provider) {
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE5E7EB);
    final headerBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF9FAFB);
    final txtSecondary = isDark
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.black.withValues(alpha: 0.55);

    if (provider.isLoading && list.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderClr),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                _col('MÃ', 2, txtSecondary),
                const SizedBox(width: 12),
                _col('TÊN KHUYẾN MÃI', 3, txtSecondary),
                const SizedBox(width: 12),
                _col('LOẠI', 2, txtSecondary),
                const SizedBox(width: 12),
                _col('GIÁ TRỊ', 2, txtSecondary),
                const SizedBox(width: 12),
                _col('THỜI GIAN', 3, txtSecondary),
                const SizedBox(width: 12),
                _col('ĐÃ DÙNG', 2, txtSecondary),
                const SizedBox(width: 12),
                _col('TRẠNG THÁI', 2, txtSecondary),
                const SizedBox(width: 12),
                _col('THAO TÁC', 2, txtSecondary),
              ],
            ),
          ),
          // Rows
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(
                    Icons.confirmation_number_outlined,
                    size: 48,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : const Color(0xFFD1D5DB),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có khuyến mãi nào',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            )
          else
            ...list.map((p) => _row(p, isDark)),
        ],
      ),
    );
  }

  Widget _col(String text, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _row(Promotion p, bool isDark) {
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.04)
        : const Color(0xFFE5E7EB);
    final txtPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final txtSecondary = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF6B7280);

    Color statusColor;
    switch (p.status) {
      case 'Đang chạy':
        statusColor = const Color(0xFF10B981);
        break;
      case 'Sắp tới':
        statusColor = const Color(0xFF3B82F6);
        break;
      default:
        statusColor = const Color(0xFF6B7280);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderClr)),
      ),
      child: Row(
        children: [
          // Code
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.code,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C3AED),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            flex: 3,
            child: Text(
              p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: txtPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Type
          Expanded(
            flex: 2,
            child: Text(
              p.discountTypeLabel,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: txtSecondary),
            ),
          ),
          const SizedBox(width: 12),
          // Value
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.discountLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFEC4899),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Period
          Expanded(
            flex: 3,
            child: Text(
              '${_fmtDate(p.startDate)} - ${_fmtDate(p.endDate)}',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: txtSecondary),
            ),
          ),
          const SizedBox(width: 12),
          // Usage
          Expanded(
            flex: 2,
            child: Text(
              p.maxUses > 0
                  ? '${p.usedCount}/${p.maxUses}'
                  : '${p.usedCount}/∞',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: txtPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                p.status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionBtn(
                  Icons.edit_rounded,
                  const Color(0xFF3B82F6),
                  isDark,
                  () => _showPromotionDialog(promo: p),
                ),
                const SizedBox(width: 6),
                _actionBtn(
                  Icons.delete_rounded,
                  const Color(0xFFEF4444),
                  isDark,
                  () => _confirmDelete(p),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    Color color,
    bool isDark,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ADD / EDIT DIALOG
  // ═══════════════════════════════════════════
  void _showPromotionDialog({Promotion? promo}) {
    final isEdit = promo != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final codeCtrl = TextEditingController(text: promo?.code ?? '');
    final nameCtrl = TextEditingController(text: promo?.name ?? '');
    final descCtrl = TextEditingController(text: promo?.description ?? '');
    final valueCtrl = TextEditingController(
      text: promo != null ? promo.discountValue.toStringAsFixed(0) : '',
    );
    final minOrderCtrl = TextEditingController(
      text: promo != null ? promo.minOrderAmount.toStringAsFixed(0) : '0',
    );
    final maxUsesCtrl = TextEditingController(
      text: promo != null ? '${promo.maxUses}' : '0',
    );

    DiscountType discountType = promo?.discountType ?? DiscountType.percent;
    DateTime startDate = promo?.startDate ?? DateTime.now();
    DateTime endDate =
        promo?.endDate ?? DateTime.now().add(const Duration(days: 30));
    bool isActive = promo?.isActive ?? true;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
          final cardColor = isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF9FAFB);
          final borderClr = isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE5E7EB);
          final txtPrimary = isDark ? Colors.white : const Color(0xFF111827);
          final txtSecondary = isDark
              ? Colors.white.withValues(alpha: 0.5)
              : const Color(0xFF6B7280);

          Widget field(
            String label,
            TextEditingController ctrl, {
            String hint = '',
            TextInputType type = TextInputType.text,
            int maxLines = 1,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: txtSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl,
                  keyboardType: type,
                  maxLines: maxLines,
                  style: TextStyle(fontSize: 13, color: txtPrimary),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(fontSize: 13, color: txtSecondary),
                    filled: true,
                    fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderClr),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: borderClr),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: Color(0xFF7C3AED),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: dialogCtx,
              initialDate: isStart ? startDate : endDate,
              firstDate: DateTime(2024),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.fromSeed(
                    seedColor: const Color(0xFF7C3AED),
                    brightness: isDark ? Brightness.dark : Brightness.light,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              setDialogState(() {
                if (isStart)
                  startDate = picked;
                else
                  endDate = picked;
              });
            }
          }

          return Dialog(
            backgroundColor: bgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.02)
                          : const Color(0xFFF8F7FF),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.confirmation_number_rounded,
                            color: Color(0xFF7C3AED),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit
                                    ? 'Sửa khuyến mãi'
                                    : 'Tạo khuyến mãi mới',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: txtPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit
                                    ? 'Chỉnh sửa thông tin mã ${promo!.code}'
                                    : 'Điền thông tin mã giảm giá',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: txtSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: txtSecondary,
                            size: 20,
                          ),
                          onPressed: () => Navigator.pop(dialogCtx),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Code + Name
                          Row(
                            children: [
                              Expanded(
                                child: field(
                                  'Mã khuyến mãi',
                                  codeCtrl,
                                  hint: 'VD: SALE50',
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: field(
                                  'Tên khuyến mãi',
                                  nameCtrl,
                                  hint: 'VD: Giảm giá mùa hè',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          field(
                            'Mô tả',
                            descCtrl,
                            hint: 'Mô tả ngắn (tuỳ chọn)',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Discount type + value
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Loại giảm giá',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: txtSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: cardColor,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: borderClr),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<DiscountType>(
                                          value: discountType,
                                          isExpanded: true,
                                          dropdownColor: bgColor,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: txtPrimary,
                                          ),
                                          items: const [
                                            DropdownMenuItem(
                                              value: DiscountType.percent,
                                              child: Text('Phần trăm (%)'),
                                            ),
                                            DropdownMenuItem(
                                              value: DiscountType.fixed,
                                              child: Text('Cố định (VNĐ)'),
                                            ),
                                          ],
                                          onChanged: (v) => setDialogState(
                                            () => discountType = v!,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: field(
                                  'Giá trị giảm',
                                  valueCtrl,
                                  hint: discountType == DiscountType.percent
                                      ? 'VD: 20'
                                      : 'VD: 50000',
                                  type: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Min order + max uses
                          Row(
                            children: [
                              Expanded(
                                child: field(
                                  'Đơn tối thiểu (VNĐ)',
                                  minOrderCtrl,
                                  hint: '0 = không giới hạn',
                                  type: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: field(
                                  'Số lần sử dụng tối đa',
                                  maxUsesCtrl,
                                  hint: '0 = không giới hạn',
                                  type: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Dates
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Bắt đầu',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: txtSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => pickDate(true),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(color: borderClr),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 16,
                                              color: txtSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _fmtDate(startDate),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: txtPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Kết thúc',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: txtSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(10),
                                      onTap: () => pickDate(false),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          border: Border.all(color: borderClr),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.calendar_today_rounded,
                                              size: 16,
                                              color: txtSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _fmtDate(endDate),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: txtPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Active toggle
                          Row(
                            children: [
                              Text(
                                'Kích hoạt',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: txtPrimary,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: isActive,
                                onChanged: (v) =>
                                    setDialogState(() => isActive = v),
                                activeColor: const Color(0xFF7C3AED),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // Footer
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogCtx),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: txtSecondary,
                              side: BorderSide(color: borderClr),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _savePromotion(
                              dialogCtx: dialogCtx,
                              isEdit: isEdit,
                              existing: promo,
                              code: codeCtrl.text.trim(),
                              name: nameCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              discountType: discountType,
                              discountValue:
                                  double.tryParse(valueCtrl.text) ?? 0,
                              minOrderAmount:
                                  double.tryParse(minOrderCtrl.text) ?? 0,
                              maxUses: int.tryParse(maxUsesCtrl.text) ?? 0,
                              startDate: startDate,
                              endDate: endDate,
                              isActive: isActive,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(isEdit ? 'Cập nhật' : 'Tạo mới'),
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

  Future<void> _savePromotion({
    required BuildContext dialogCtx,
    required bool isEdit,
    Promotion? existing,
    required String code,
    required String name,
    required String description,
    required DiscountType discountType,
    required double discountValue,
    required double minOrderAmount,
    required int maxUses,
    required DateTime startDate,
    required DateTime endDate,
    required bool isActive,
  }) async {
    if (code.isEmpty || name.isEmpty) {
      AppSnackBar.error(context, 'Vui lòng nhập mã và tên khuyến mãi');
      return;
    }
    if (discountValue <= 0) {
      AppSnackBar.error(context, 'Giá trị giảm phải lớn hơn 0');
      return;
    }
    if (endDate.isBefore(startDate)) {
      AppSnackBar.error(context, 'Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }

    final now = DateTime.now();
    final promo = Promotion(
      id: existing?.id ?? '',
      code: code.toUpperCase(),
      name: name,
      description: description,
      discountType: discountType,
      discountValue: discountValue,
      minOrderAmount: minOrderAmount,
      maxUses: maxUses,
      usedCount: existing?.usedCount ?? 0,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    if (Navigator.of(dialogCtx).canPop()) {
      Navigator.of(dialogCtx).pop();
    }
    final provider = Provider.of<PromotionProvider>(context, listen: false);
    bool success;
    if (isEdit) {
      success = await provider.updatePromotion(promo);
    } else {
      success = await provider.createPromotion(promo);
    }

    if (!mounted) return;

    if (success) {
      AppSnackBar.success(
        context,
        isEdit ? 'Cập nhật khuyến mãi thành công' : 'Tạo khuyến mãi thành công',
      );
    } else {
      AppSnackBar.error(context, provider.errorMessage ?? 'Có lỗi xảy ra');
    }
  }

  // ═══════════════════════════════════════════
  // DELETE DIALOG
  // ═══════════════════════════════════════════
  void _confirmDelete(Promotion promo) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final txtPrimary = isDark ? Colors.white : const Color(0xFF111827);
    final txtSecondary = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF6B7280);
    final borderClr = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFE5E7EB);

    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFEF4444),
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Xóa khuyến mãi?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: txtPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Mã ${promo.code} — "${promo.name}" sẽ bị xóa vĩnh viễn.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: txtSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: txtSecondary,
                        side: BorderSide(color: borderClr),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        final provider = Provider.of<PromotionProvider>(
                          context,
                          listen: false,
                        );
                        final success = await provider.deletePromotion(
                          promo.id,
                        );
                        if (!mounted) return;
                        if (success) {
                          AppSnackBar.success(
                            context,
                            'Đã xóa khuyến mãi ${promo.code}',
                          );
                        } else {
                          AppSnackBar.error(
                            context,
                            provider.errorMessage ?? 'Có lỗi xảy ra',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('Xóa'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
