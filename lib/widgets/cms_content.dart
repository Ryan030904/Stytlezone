import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/banner_model.dart' as bm;
import '../providers/banner_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'admin_slide_panel.dart';
import 'app_state_widgets.dart';
import 'cloudinary_image_picker.dart';

class CmsContent extends StatefulWidget {
  const CmsContent({super.key});

  @override
  State<CmsContent> createState() => _CmsContentState();
}

class _CmsContentState extends State<CmsContent> {
  int _selectedFilter = 0;
  String _searchQuery = '';
  static const _filters = ['Tất cả', 'Đang hiển thị', 'Nháp', 'Lưu trữ'];

  // ── Slide Panel State ──
  bool _isPanelOpen = false;
  bool _isEditMode = false;
  String _panelTitle = 'Thêm banner mới';
  bm.BannerModel? _editingBanner;

  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  final _linkUrlCtrl = TextEditingController();
  final _sortCtrl = TextEditingController();
  bm.BannerType _bannerType = bm.BannerType.hero;
  bm.BannerStatus _bannerStatus = bm.BannerStatus.draft;
  String _bannerPosition = 'hero';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => Provider.of<BannerProvider>(context, listen: false).loadBanners(),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _imageUrlCtrl.dispose();
    _linkUrlCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _openAddPanel() {
    _isEditMode = false;
    _panelTitle = 'Thêm banner mới';
    _editingBanner = null;
    _titleCtrl.clear();
    _subtitleCtrl.clear();
    _imageUrlCtrl.clear();
    _linkUrlCtrl.clear();
    _sortCtrl.text = '0';
    _bannerType = bm.BannerType.hero;
    _bannerStatus = bm.BannerStatus.draft;
    _bannerPosition = 'hero';
    _startDate = null;
    _endDate = null;
    setState(() => _isPanelOpen = true);
  }

  void _openEditPanel(bm.BannerModel banner) {
    _isEditMode = true;
    _panelTitle = 'Chỉnh sửa banner';
    _editingBanner = banner;
    _titleCtrl.text = banner.title;
    _subtitleCtrl.text = banner.subtitle;
    _imageUrlCtrl.text = banner.imageUrl;
    _linkUrlCtrl.text = banner.linkUrl;
    _sortCtrl.text = '${banner.sortOrder}';
    _bannerType = banner.type;
    _bannerStatus = banner.status;
    _bannerPosition = banner.position;
    _startDate = banner.startDate;
    _endDate = banner.endDate;
    setState(() => _isPanelOpen = true);
  }

  void _closePanel() {
    setState(() => _isPanelOpen = false);
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
    return AdminSlidePanel(
      isOpen: _isPanelOpen,
      title: _panelTitle,
      onClose: _closePanel,
      panelBody: _buildPanelBody(),
      panelFooter: _buildPanelFooter(),
      child: Consumer<BannerProvider>(
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
      ),
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
          onPressed: _openAddPanel,
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
                    () => _openEditPanel(b)),
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
  // PANEL BODY / FOOTER
  // ═══════════════════════════════════════════
  Widget _buildPanelBody() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    Widget field(String label, TextEditingController ctrl, {String hint = '', int maxLines = 1}) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, maxLines: maxLines,
          style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(fontSize: 13, color: ts),
            filled: true, fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          )),
      ]);
    }

    Widget dropdown<T>(String label, T value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(value: value, items: items, onChanged: onChanged,
          dropdownColor: bg, style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(filled: true, fillColor: cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          )),
      ]);
    }

    return Column(children: [
      field('Tiêu đề *', _titleCtrl, hint: 'VD: Flash Sale Mùa Hè'),
      const SizedBox(height: 14),
      field('Phụ đề', _subtitleCtrl, hint: 'VD: Giảm đến 50% toàn bộ sản phẩm'),
      const SizedBox(height: 14),
      CloudinaryImagePicker(controller: _imageUrlCtrl, isDarkMode: isDark, label: 'Hình ảnh banner'),
      const SizedBox(height: 14),
      field('URL liên kết (khi click)', _linkUrlCtrl, hint: 'https://stylezone.com/sale'),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: dropdown<bm.BannerType>('Loại banner', _bannerType, [
          const DropdownMenuItem(value: bm.BannerType.hero, child: Text('Hero')),
          const DropdownMenuItem(value: bm.BannerType.promotion, child: Text('Khuyến mãi')),
          const DropdownMenuItem(value: bm.BannerType.category, child: Text('Danh mục')),
        ], (v) => setState(() => _bannerType = v!))),
        const SizedBox(width: 12),
        Expanded(child: dropdown<String>('Vị trí', _bannerPosition, [
          const DropdownMenuItem(value: 'hero', child: Text('Trang chủ (Hero)')),
          const DropdownMenuItem(value: 'sidebar', child: Text('Sidebar')),
          const DropdownMenuItem(value: 'footer', child: Text('Footer')),
          const DropdownMenuItem(value: 'popup', child: Text('Popup')),
          const DropdownMenuItem(value: 'category', child: Text('Trang danh mục')),
        ], (v) => setState(() => _bannerPosition = v!))),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: dropdown<bm.BannerStatus>('Trạng thái', _bannerStatus, [
          const DropdownMenuItem(value: bm.BannerStatus.active, child: Text('Đang hiển thị')),
          const DropdownMenuItem(value: bm.BannerStatus.draft, child: Text('Nháp')),
          const DropdownMenuItem(value: bm.BannerStatus.archived, child: Text('Lưu trữ')),
        ], (v) => setState(() => _bannerStatus = v!))),
        const SizedBox(width: 12),
        Expanded(child: field('Thứ tự hiển thị', _sortCtrl, hint: '0')),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ngày bắt đầu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: context,
                initialDate: _startDate ?? DateTime.now(),
                firstDate: DateTime(2024), lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED), brightness: isDark ? Brightness.dark : Brightness.light)), child: child!));
              if (picked != null) setState(() => _startDate = picked);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: ts), const SizedBox(width: 8),
                Text(_startDate != null ? _fmtDate(_startDate!) : 'Không giới hạn',
                    style: TextStyle(fontSize: 13, color: _startDate != null ? tp : ts)),
              ])),
          ),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ngày kết thúc', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ts)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(context: context,
                initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
                firstDate: DateTime(2024), lastDate: DateTime(2030),
                builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED), brightness: isDark ? Brightness.dark : Brightness.light)), child: child!));
              if (picked != null) setState(() => _endDate = picked);
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
              child: Row(children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: ts), const SizedBox(width: 8),
                Text(_endDate != null ? _fmtDate(_endDate!) : 'Không giới hạn',
                    style: TextStyle(fontSize: 13, color: _endDate != null ? tp : ts)),
              ])),
          ),
        ])),
      ]),
    ]);
  }

  Widget _buildPanelFooter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ts = isDark ? Colors.white.withValues(alpha: 0.5) : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return Row(children: [
      Expanded(child: OutlinedButton(onPressed: _closePanel,
        style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Hủy'))),
      const SizedBox(width: 12),
      Expanded(child: ElevatedButton(onPressed: () async {
        if (_titleCtrl.text.trim().isEmpty) {
          AppSnackBar.error(context, 'Vui lòng nhập tiêu đề banner');
          return;
        }
        final now = DateTime.now();
        final b = bm.BannerModel(
          id: _editingBanner?.id ?? '',
          title: _titleCtrl.text.trim(),
          subtitle: _subtitleCtrl.text.trim(),
          imageUrl: _imageUrlCtrl.text.trim(),
          linkUrl: _linkUrlCtrl.text.trim(),
          type: _bannerType,
          status: _bannerStatus,
          position: _bannerPosition,
          sortOrder: int.tryParse(_sortCtrl.text) ?? 0,
          startDate: _startDate,
          endDate: _endDate,
          createdAt: _editingBanner?.createdAt ?? now,
          updatedAt: now,
        );
        _closePanel();
        final prov = context.read<BannerProvider>();
        final ok = _isEditMode ? await prov.updateBanner(b) : await prov.createBanner(b);
        if (!mounted) return;
        if (ok) {
          AppSnackBar.success(context, _isEditMode ? 'Đã cập nhật banner' : 'Đã tạo banner mới');
        } else {
          AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
        }
      }, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        child: Text(_isEditMode ? 'Cập nhật' : 'Tạo banner'))),
    ]);
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
