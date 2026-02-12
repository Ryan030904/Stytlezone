import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/banner_model.dart' as bm;
import '../providers/banner_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'app_state_widgets.dart';

class CmsContent extends StatefulWidget {
  const CmsContent({super.key});

  @override
  State<CmsContent> createState() => _CmsContentState();
}

class _CmsContentState extends State<CmsContent> {
  int _selectedFilter = 0;
  String _searchQuery = '';
  static const _filters = ['Tất cả', 'Đang hiển thị', 'Nháp', 'Lưu trữ'];

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<BannerProvider>(context, listen: false).loadBanners(),
    );
  }

  List<bm.BannerModel> _applyFilters(List<bm.BannerModel> all) {
    var list = all.toList();
    if (_selectedFilter == 1)
      list = list.where((b) => b.status == bm.BannerStatus.active).toList();
    if (_selectedFilter == 2)
      list = list.where((b) => b.status == bm.BannerStatus.draft).toList();
    if (_selectedFilter == 3)
      list = list.where((b) => b.status == bm.BannerStatus.archived).toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where(
            (b) =>
                b.title.toLowerCase().contains(q) ||
                b.subtitle.toLowerCase().contains(q) ||
                b.position.toLowerCase().contains(q),
          )
          .toList();
    }
    return list;
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ═══════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<BannerProvider>(
      builder: (context, provider, _) {
        final all = provider.banners;
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

  // ═══════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════
  Widget _header(bool isDark, List<bm.BannerModel> all) {
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : const Color(0xFF6B7280);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quản lý Banner',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: tp)),
            const SizedBox(height: 4),
            Text('Quản lý banner hiển thị trên website StyleZone',
                style: TextStyle(fontSize: 14, color: ts)),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showBannerDialog(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Thêm banner'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // STATS
  // ═══════════════════════════════════════════
  Widget _statsRow(bool isDark, List<bm.BannerModel> all) {
    final active = all.where((b) => b.status == bm.BannerStatus.active).length;
    final draft = all.where((b) => b.status == bm.BannerStatus.draft).length;
    final archived = all.where((b) => b.status == bm.BannerStatus.archived).length;
    final hero = all.where((b) => b.type == bm.BannerType.hero).length;
    return Row(
      children: [
        Expanded(child: _statCard(isDark, 'Tổng banner', '${all.length}', Icons.image_rounded, const Color(0xFF7C3AED))),
        const SizedBox(width: 16),
        Expanded(child: _statCard(isDark, 'Đang hiển thị', '$active', Icons.visibility_rounded, const Color(0xFF10B981))),
        const SizedBox(width: 16),
        Expanded(child: _statCard(isDark, 'Nháp', '$draft', Icons.edit_note_rounded, const Color(0xFFF59E0B))),
        const SizedBox(width: 16),
        Expanded(child: _statCard(isDark, 'Hero Banner', '$hero', Icons.star_rounded, const Color(0xFF3B82F6))),
      ],
    );
  }

  Widget _statCard(bool isDark, String label, String value, IconData icon, Color color) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
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
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: tp)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 12, color: ts)),
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
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    return Row(
      children: [
        SizedBox(
          width: 280, height: 40,
          child: TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Tìm tiêu đề, vị trí banner...',
              hintStyle: TextStyle(fontSize: 13, color: ts),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: ts),
              filled: true,
              fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ..._filters.asMap().entries.map((e) {
          final isActive = _selectedFilter == e.key;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF7C3AED)
                        : isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isActive ? const Color(0xFF7C3AED) : bdr),
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive ? Colors.white : isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF374151),
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
  Widget _table(bool isDark, List<bm.BannerModel> list, BannerProvider provider) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final ts = isDark ? Colors.white.withValues(alpha: 0.45) : Colors.black.withValues(alpha: 0.55);

    if (provider.isLoading && list.isEmpty) {
      return Container(
        height: 200,
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED))),
      );
    }

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _col('HÌNH ẢNH', 2, ts),
                const SizedBox(width: 12),
                _col('TIÊU ĐỀ', 3, ts),
                const SizedBox(width: 12),
                _col('LOẠI', 2, ts),
                const SizedBox(width: 12),
                _col('VỊ TRÍ', 2, ts),
                const SizedBox(width: 12),
                _col('TRẠNG THÁI', 2, ts),
                const SizedBox(width: 12),
                _col('THỨ TỰ', 1, ts),
                const SizedBox(width: 12),
                _col('CẬP NHẬT', 2, ts),
                const SizedBox(width: 12),
                _col('THAO TÁC', 2, ts),
              ],
            ),
          ),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.image_not_supported_outlined, size: 48,
                      color: isDark ? Colors.white.withValues(alpha: 0.15) : const Color(0xFFD1D5DB)),
                  const SizedBox(height: 12),
                  Text('Chưa có banner nào',
                      style: TextStyle(fontSize: 14,
                          color: isDark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9CA3AF))),
                ],
              ),
            )
          else
            ...list.map((b) => _row(b, isDark)),
        ],
      ),
    );
  }

  Widget _col(String text, int flex, Color color) {
    return Expanded(
      flex: flex,
      child: Text(text, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 0.5)),
    );
  }

  Widget _row(bm.BannerModel b, bool isDark) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF6B7280);

    Color statusColor;
    switch (b.status) {
      case bm.BannerStatus.active:
        statusColor = const Color(0xFF10B981);
        break;
      case bm.BannerStatus.draft:
        statusColor = const Color(0xFFF59E0B);
        break;
      case bm.BannerStatus.archived:
        statusColor = const Color(0xFF6B7280);
        break;
    }

    final posLabel = _positionLabel(b.position);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bdr))),
      child: Row(
        children: [
          // Image preview
          Expanded(
            flex: 2,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: b.imageUrl.isNotEmpty
                    ? Image.network(
                        b.imageUrl,
                        width: 80, height: 45, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(isDark),
                      )
                    : _imagePlaceholder(isDark),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title + Subtitle
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
                if (b.subtitle.isNotEmpty)
                  Text(b.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: ts)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Type
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(b.typeLabel, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
            ),
          ),
          const SizedBox(width: 12),
          // Position
          Expanded(flex: 2, child: Text(posLabel, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ts))),
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
              child: Text(b.statusLabel, textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
            ),
          ),
          const SizedBox(width: 12),
          // Sort order
          Expanded(flex: 1, child: Text('${b.sortOrder}', textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: tp))),
          const SizedBox(width: 12),
          // Updated at
          Expanded(flex: 2, child: Text(_fmtDate(b.updatedAt), textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: ts))),
          const SizedBox(width: 12),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionBtn(Icons.edit_rounded, const Color(0xFF3B82F6), isDark,
                    () => _showBannerDialog(banner: b)),
                const SizedBox(width: 6),
                _actionBtn(Icons.delete_rounded, const Color(0xFFEF4444), isDark,
                    () => _confirmDelete(b)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      width: 80, height: 45,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.image_outlined, size: 20,
          color: isDark ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFD1D5DB)),
    );
  }

  Widget _actionBtn(IconData icon, Color color, bool isDark, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 15, color: color),
      ),
    );
  }

  String _positionLabel(String pos) {
    switch (pos.toLowerCase()) {
      case 'hero': return 'Trang chủ (Hero)';
      case 'sidebar': return 'Sidebar';
      case 'footer': return 'Footer';
      case 'popup': return 'Popup';
      case 'category': return 'Trang danh mục';
      default: return pos;
    }
  }

  // ═══════════════════════════════════════════
  // ADD / EDIT DIALOG
  // ═══════════════════════════════════════════
  void _showBannerDialog({bm.BannerModel? banner}) {
    final isEdit = banner != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleCtrl = TextEditingController(text: banner?.title ?? '');
    final subtitleCtrl = TextEditingController(text: banner?.subtitle ?? '');
    final imageUrlCtrl = TextEditingController(text: banner?.imageUrl ?? '');
    final linkUrlCtrl = TextEditingController(text: banner?.linkUrl ?? '');
    final sortCtrl = TextEditingController(text: banner != null ? '${banner.sortOrder}' : '0');

    bm.BannerType type = banner?.type ?? bm.BannerType.hero;
    bm.BannerStatus status = banner?.status ?? bm.BannerStatus.draft;
    String position = banner?.position ?? 'hero';
    DateTime? startDate = banner?.startDate;
    DateTime? endDate = banner?.endDate;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
          final cardColor = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
          final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
          final tp = isDark ? Colors.white : const Color(0xFF111827);
          final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);

          Widget field(String label, TextEditingController ctrl, {String hint = '', int maxLines = 1}) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                const SizedBox(height: 6),
                TextField(
                  controller: ctrl, maxLines: maxLines,
                  style: TextStyle(fontSize: 13, color: tp),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(fontSize: 13, color: ts),
                    filled: true, fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                  ),
                ),
              ],
            );
          }

          Widget dropdown<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                const SizedBox(height: 6),
                DropdownButtonFormField<T>(
                  value: value,
                  items: items,
                  onChanged: onChanged,
                  dropdownColor: bg,
                  style: TextStyle(fontSize: 13, color: tp),
                  decoration: InputDecoration(
                    filled: true, fillColor: cardColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                  ),
                ),
              ],
            );
          }

          Future<void> pickDate(bool isStart) async {
            final picked = await showDatePicker(
              context: dialogCtx,
              initialDate: isStart ? (startDate ?? DateTime.now()) : (endDate ?? DateTime.now().add(const Duration(days: 30))),
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
                if (isStart) startDate = picked; else endDate = picked;
              });
            }
          }

          return Dialog(
            backgroundColor: bg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFF8F7FF),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.image_rounded, color: Color(0xFF7C3AED), size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isEdit ? 'Chỉnh sửa banner' : 'Thêm banner mới',
                                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: tp)),
                              const SizedBox(height: 2),
                              Text(isEdit ? 'Cập nhật thông tin banner' : 'Điền thông tin banner để hiển thị trên website',
                                  style: TextStyle(fontSize: 12, color: ts)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          icon: Icon(Icons.close_rounded, color: ts),
                        ),
                      ],
                    ),
                  ),
                  // Form body
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Column(
                        children: [
                          field('Tiêu đề *', titleCtrl, hint: 'VD: Flash Sale Mùa Hè'),
                          const SizedBox(height: 14),
                          field('Phụ đề', subtitleCtrl, hint: 'VD: Giảm đến 50% toàn bộ sản phẩm'),
                          const SizedBox(height: 14),
                          field('URL hình ảnh', imageUrlCtrl, hint: 'https://example.com/banner.jpg'),
                          const SizedBox(height: 14),
                          field('URL liên kết (khi click)', linkUrlCtrl, hint: 'https://stylezone.com/sale'),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: dropdown<bm.BannerType>('Loại banner', type, [
                                  const DropdownMenuItem(value: bm.BannerType.hero, child: Text('Hero')),
                                  const DropdownMenuItem(value: bm.BannerType.promotion, child: Text('Khuyến mãi')),
                                  const DropdownMenuItem(value: bm.BannerType.category, child: Text('Danh mục')),
                                ], (v) => setDialogState(() => type = v!)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: dropdown<String>('Vị trí', position, [
                                  const DropdownMenuItem(value: 'hero', child: Text('Trang chủ (Hero)')),
                                  const DropdownMenuItem(value: 'sidebar', child: Text('Sidebar')),
                                  const DropdownMenuItem(value: 'footer', child: Text('Footer')),
                                  const DropdownMenuItem(value: 'popup', child: Text('Popup')),
                                  const DropdownMenuItem(value: 'category', child: Text('Trang danh mục')),
                                ], (v) => setDialogState(() => position = v!)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: dropdown<bm.BannerStatus>('Trạng thái', status, [
                                  const DropdownMenuItem(value: bm.BannerStatus.active, child: Text('Đang hiển thị')),
                                  const DropdownMenuItem(value: bm.BannerStatus.draft, child: Text('Nháp')),
                                  const DropdownMenuItem(value: bm.BannerStatus.archived, child: Text('Lưu trữ')),
                                ], (v) => setDialogState(() => status = v!)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: field('Thứ tự hiển thị', sortCtrl, hint: '0')),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Date pickers
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ngày bắt đầu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () => pickDate(true),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: bdr),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 16, color: ts),
                                            const SizedBox(width: 8),
                                            Text(startDate != null ? _fmtDate(startDate!) : 'Không giới hạn',
                                                style: TextStyle(fontSize: 13, color: startDate != null ? tp : ts)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ngày kết thúc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                                    const SizedBox(height: 6),
                                    InkWell(
                                      onTap: () => pickDate(false),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: cardColor,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: bdr),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today_rounded, size: 16, color: ts),
                                            const SizedBox(width: 8),
                                            Text(endDate != null ? _fmtDate(endDate!) : 'Không giới hạn',
                                                style: TextStyle(fontSize: 13, color: endDate != null ? tp : ts)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Image preview
                          if (imageUrlCtrl.text.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text('Xem trước', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrlCtrl.text,
                                height: 120, width: double.infinity, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 120, width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.broken_image_outlined, size: 32, color: ts),
                                      const SizedBox(height: 4),
                                      Text('Không tải được ảnh', style: TextStyle(fontSize: 11, color: ts)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Action buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text('Hủy'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (titleCtrl.text.trim().isEmpty) {
                              AppSnackBar.error(dialogCtx, 'Vui lòng nhập tiêu đề banner');
                              return;
                            }
                            final now = DateTime.now();
                            final b = bm.BannerModel(
                              id: banner?.id ?? '',
                              title: titleCtrl.text.trim(),
                              subtitle: subtitleCtrl.text.trim(),
                              imageUrl: imageUrlCtrl.text.trim(),
                              linkUrl: linkUrlCtrl.text.trim(),
                              type: type,
                              status: status,
                              position: position,
                              sortOrder: int.tryParse(sortCtrl.text) ?? 0,
                              startDate: startDate,
                              endDate: endDate,
                              createdAt: banner?.createdAt ?? now,
                              updatedAt: now,
                            );
                            Navigator.pop(dialogCtx);
                            final prov = context.read<BannerProvider>();
                            final ok = isEdit
                                ? await prov.updateBanner(b)
                                : await prov.createBanner(b);
                            if (!mounted) return;
                            if (ok) {
                              AppSnackBar.success(context, isEdit ? 'Đã cập nhật banner' : 'Đã tạo banner mới');
                            } else {
                              AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: Text(isEdit ? 'Cập nhật' : 'Tạo banner'),
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

  // ═══════════════════════════════════════════
  // DELETE CONFIRM
  // ═══════════════════════════════════════════
  Future<void> _confirmDelete(bm.BannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa banner'),
        content: Text('Bạn có chắc muốn xóa banner "${banner.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prov = context.read<BannerProvider>();
    final ok = await prov.deleteBanner(banner.id);
    if (!mounted) return;
    if (ok) {
      AppSnackBar.success(context, 'Đã xóa banner');
    } else {
      AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
    }
  }
}
