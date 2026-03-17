import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/brand_model.dart';
import '../providers/brand_provider.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_slide_panel.dart';
import '../widgets/cloudinary_image_picker.dart';

/// ──────────────────────────────────────────────
/// BRAND MANAGEMENT
/// ──────────────────────────────────────────────
class BrandContent extends StatefulWidget {
  const BrandContent({super.key});

  @override
  State<BrandContent> createState() => _BrandContentState();
}

class _BrandContentState extends State<BrandContent> {
  // ─── Panel ───
  bool _panelOpen = false;
  Brand? _editing;

  // ─── Search & Filter ───
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _sortOrder = ''; // '' = default, 'az' = A→Z, 'za' = Z→A


  // ─── Form controllers ───
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  bool _isActive = true;

  void _closePanelOnTabSwitch() {
    if (_panelOpen) setState(() => _panelOpen = false);
  }

  @override
  void initState() {
    super.initState();
    DashboardScreen.panelCloseNotifier.addListener(_closePanelOnTabSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<BrandProvider>();
      if (prov.brands.isEmpty) prov.loadBrands();
    });
  }

  @override
  void dispose() {
    DashboardScreen.panelCloseNotifier.removeListener(_closePanelOnTabSwitch);
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ─── Open panel: CREATE ───
  void _openCreate() {
    _editing = null;
    _nameCtrl.clear();
    _descCtrl.clear();
    _isActive = true;
    setState(() => _panelOpen = true);
  }

  // ─── Open panel: EDIT ───
  void _openEdit(Brand brand) {
    _editing = brand;
    _nameCtrl.text = brand.name;
    _descCtrl.text = brand.description;
    _isActive = brand.isActive;
    setState(() => _panelOpen = true);
  }

  void _closePanel() => setState(() => _panelOpen = false);

  // ─── SAVE ───
  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final prov = context.read<BrandProvider>();
    final now = DateTime.now();

    if (_editing != null) {
      final updated = _editing!.copyWith(
        name: name,
        description: _descCtrl.text.trim(),
        isActive: _isActive,
        updatedAt: now,
      );
      final ok = await prov.updateBrand(updated);
      if (ok && mounted) _closePanel();
    } else {
      final newBrand = Brand(
        id: '',
        name: name,
        description: _descCtrl.text.trim(),
        isActive: _isActive,
        createdAt: now,
        updatedAt: now,
      );
      final ok = await prov.createBrand(newBrand);
      if (ok && mounted) _closePanel();
    }
  }

  // ─── DELETE ───
  Future<void> _delete(Brand brand) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xóa thương hiệu "${brand.name}"?', style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await context.read<BrandProvider>().deleteBrand(brand.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Đã xóa thương hiệu "${brand.name}"' : 'Xóa thất bại, vui lòng thử lại'),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ));
      }
    }
  }

  // ─── Filter & Sort brands ───
  List<Brand> _applyFilters(List<Brand> all) {
    var result = all.toList();
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((b) =>
          b.name.toLowerCase().contains(q) ||
          b.description.toLowerCase().contains(q)).toList();
    }
    if (_sortOrder == 'az') {
      result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortOrder == 'za') {
      result.sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<BrandProvider>(
      builder: (context, prov, _) {
        final filtered = _applyFilters(prov.brands);

        return AdminSlidePanel(
          isOpen: _panelOpen,
          panelWidth: 440,
          title: _editing != null ? 'Chỉnh sửa thương hiệu' : 'Thêm thương hiệu mới',
          onClose: _closePanel,
          panelBody: _buildPanelForm(isDark),
          panelFooter: _buildPanelFooter(isDark, prov.isLoading),
          child: Column(
            children: [
              _buildHeaderBar(isDark, prov),
              Expanded(
                child: prov.isLoading && prov.brands.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                    : filtered.isEmpty
                        ? _buildEmptyState(isDark)
                        : _buildBrandList(isDark, filtered),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // HEADER BAR
  // ═══════════════════════════════════════════════
  Widget _buildHeaderBar(bool isDark, BrandProvider prov) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: border))),
      child: Row(
        children: [
          // ── Search field (constrained width) ──
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textDark),
                decoration: InputDecoration(
                  hintText: 'Tìm thương hiệu...',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                  filled: true,
                  fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ── Sort dropdown ──
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sortOrder.isEmpty ? null : _sortOrder,
                hint: Row(children: [
                  Icon(Icons.sort_by_alpha_rounded, size: 16, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                  const SizedBox(width: 6),
                  Text('Sắp xếp', style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
                ]),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
                icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Mặc định', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'az', child: Text('A → Z', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'za', child: Text('Z → A', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _sortOrder = v ?? ''),
              ),
            ),
          ),

          const Spacer(),

          // ── Add button ──
          SizedBox(
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _openCreate,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm thương hiệu', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }



  // ═══════════════════════════════════════════════
  // BRAND LIST
  // ═══════════════════════════════════════════════
  Widget _buildBrandList(bool isDark, List<Brand> brands) {
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
      itemCount: brands.length,
      itemBuilder: (ctx, i) {
        final brand = brands[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                // Logo
                _brandAvatar(brand, isDark),
                const SizedBox(width: 14),

                // Info
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(brand.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Text('${brand.productCount} sản phẩm', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                      if (brand.website != null && brand.website!.isNotEmpty) ...[
                        Text(' · ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                        Flexible(child: Text(brand.website!, style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                      ],
                    ]),
                    if (brand.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(brand.description, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA)), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ],
                )),

                const SizedBox(width: 12),

                // Status
                _statusBadge(brand.isActive, isDark),
                const SizedBox(width: 12),

                // Actions
                _actionButtons(brand, isDark),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _brandAvatar(Brand brand, bool isDark) {
    if (brand.logoUrl != null && brand.logoUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(brand.logoUrl!, width: 44, height: 44, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(brand, isDark)),
      );
    }
    return _defaultAvatar(brand, isDark);
  }

  Widget _defaultAvatar(Brand brand, bool isDark) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.12),
          const Color(0xFF3B82F6).withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(child: Text(
        brand.name.isNotEmpty ? brand.name[0].toUpperCase() : '?',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED)),
      )),
    );
  }

  Widget _statusBadge(bool isActive, bool isDark) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(isActive ? 'Hoạt động' : 'Ẩn', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _actionButtons(Brand brand, bool isDark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _iconButton(Icons.edit_rounded, const Color(0xFF7C3AED), () => _openEdit(brand), isDark),
      const SizedBox(width: 4),
      _iconButton(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _delete(brand), isDark),
    ]);
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: color.withValues(alpha: 0.7)),
      ),
    );
  }

  // ─── Empty State ───
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.verified_rounded, size: 36, color: Color(0xFF7C3AED)),
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty
              ? 'Không tìm thấy thương hiệu'
              : 'Chưa có thương hiệu nào',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        Text('Bắt đầu bằng cách thêm thương hiệu đầu tiên', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _openCreate,
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Thêm thương hiệu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════
  // PANEL FORM
  // ═══════════════════════════════════════════════
  Widget _buildPanelForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        _formField(
          label: 'Tên thương hiệu *',
          child: _textInput(_nameCtrl, 'Nhập tên thương hiệu...', isDark),
        ),
        const SizedBox(height: 20),

        // Description
        _formField(
          label: 'Mô tả',
          child: _textInput(_descCtrl, 'Mô tả ngắn về thương hiệu...', isDark, maxLines: 3),
        ),
        const SizedBox(height: 20),

        // Status toggle
        _formField(
          label: 'Trạng thái',
          child: _statusToggle(isDark),
        ),
      ],
    );
  }

  Widget _formField({required String label, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151))),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _textInput(TextEditingController ctrl, String hint, bool isDark, {int maxLines = 1, TextInputType? inputType}) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: inputType,
      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA)),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
      ),
    );
  }

  Widget _statusToggle(bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _isActive = !_isActive),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
        ),
        child: Row(children: [
          Icon(
            _isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 18,
            color: _isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            _isActive ? 'Đang hoạt động — hiển thị trên shop' : 'Đã ẩn — không hiển thị',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF374151)),
          )),
          Switch(value: _isActive, onChanged: (v) => setState(() => _isActive = v), activeColor: const Color(0xFF10B981)),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PANEL FOOTER
  // ═══════════════════════════════════════════════
  Widget _buildPanelFooter(bool isDark, bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : _closePanel,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDark ? Colors.white70 : const Color(0xFF374151),
              side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hủy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: isLoading ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(_editing != null ? 'Cập nhật' : 'Tạo mới', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
