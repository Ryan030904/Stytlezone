import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category_model.dart';
import '../providers/category_provider.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_slide_panel.dart';
import '../widgets/cloudinary_image_picker.dart';

/// ──────────────────────────────────────────────
/// CATEGORY MANAGEMENT — Parent / Child tree
/// ──────────────────────────────────────────────
class CategoryContent extends StatefulWidget {
  const CategoryContent({super.key});

  @override
  State<CategoryContent> createState() => _CategoryContentState();
}

class _CategoryContentState extends State<CategoryContent> {
  // ─── Panel state ───
  bool _panelOpen = false;
  Category? _editing; // null = create, non-null = edit
  String? _presetParentId; // auto-fill parentId when adding sub-cat

  // ─── Search & Filter ───
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'parent', 'child'

  // ─── Form controllers ───
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _sortCtrl = TextEditingController(text: '0');
  String _gender = 'all';
  String? _parentId;
  bool _isActive = true;

  // ─── Expanded parents ───
  final Set<String> _expanded = {};

  void _closePanelOnTabSwitch() {
    if (_panelOpen) setState(() => _panelOpen = false);
  }

  @override
  void initState() {
    super.initState();
    DashboardScreen.panelCloseNotifier.addListener(_closePanelOnTabSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<CategoryProvider>();
      if (prov.categories.isEmpty) prov.loadCategories();
    });
  }

  @override
  void dispose() {
    DashboardScreen.panelCloseNotifier.removeListener(_closePanelOnTabSwitch);
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _imageCtrl.dispose();
    _noteCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  // ─── Open panel for CREATE ───
  void _openCreate({String? parentId}) {
    _editing = null;
    _presetParentId = parentId;
    _nameCtrl.clear();
    _descCtrl.clear();
    _imageCtrl.clear();
    _noteCtrl.clear();
    _sortCtrl.text = '0';
    _gender = 'all';
    _parentId = parentId;
    _isActive = true;
    setState(() => _panelOpen = true);
  }

  // ─── Open panel for EDIT ───
  void _openEdit(Category cat) {
    _editing = cat;
    _presetParentId = null;
    _nameCtrl.text = cat.name;
    _descCtrl.text = cat.description;
    _imageCtrl.text = cat.imageUrl ?? '';
    _noteCtrl.text = cat.note;
    _sortCtrl.text = cat.sortOrder.toString();
    _gender = cat.gender;
    _parentId = cat.parentId;
    _isActive = cat.isActive;
    setState(() => _panelOpen = true);
  }

  void _closePanel() => setState(() => _panelOpen = false);

  // ─── SAVE (create or update) ───
  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final prov = context.read<CategoryProvider>();
    final now = DateTime.now();

    if (_editing != null) {
      // UPDATE
      final updated = _editing!.copyWith(
        name: name,
        description: _descCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        sortOrder: int.tryParse(_sortCtrl.text) ?? 0,
        gender: _gender,
        parentId: _parentId,
        isActive: _isActive,
        updatedAt: now,
      );
      final ok = await prov.updateCategory(updated);
      if (ok && mounted) _closePanel();
    } else {
      // CREATE
      final newCat = Category(
        id: '',
        name: name,
        description: _descCtrl.text.trim(),
        imageUrl: _imageCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        sortOrder: int.tryParse(_sortCtrl.text) ?? 0,
        gender: _gender,
        parentId: _parentId,
        isActive: _isActive,
        createdAt: now,
        updatedAt: now,
      );
      final ok = await prov.createCategory(newCat);
      if (ok && mounted) _closePanel();
    }
  }

  // ─── DELETE ───
  Future<void> _delete(Category cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xóa danh mục "${cat.name}"?', style: const TextStyle(fontSize: 14)),
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
      final ok = await context.read<CategoryProvider>().deleteCategory(cat.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Đã xóa danh mục "${cat.name}"' : 'Xóa thất bại, vui lòng thử lại'),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CategoryProvider>(
      builder: (context, prov, _) {
        final all = prov.categories;

        // Filter by search
        var filtered = _searchQuery.isEmpty
            ? all
            : all.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

        // Filter by type
        if (_filterType == 'parent') {
          filtered = filtered.where((c) => c.parentId == null || c.parentId!.isEmpty).toList();
        } else if (_filterType == 'child') {
          filtered = filtered.where((c) => c.parentId != null && c.parentId!.isNotEmpty).toList();
        }

        // Build parent/child tree
        final parents = filtered.where((c) => c.parentId == null || c.parentId!.isEmpty).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        List<Category> childrenOf(String parentId) =>
            filtered.where((c) => c.parentId == parentId).toList()
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        // Parent list for dropdown (exclude self when editing)
        final parentOptions = all.where((c) {
          if (c.parentId != null && c.parentId!.isNotEmpty) return false;
          if (_editing != null && c.id == _editing!.id) return false;
          return true;
        }).toList();

        return AdminSlidePanel(
          isOpen: _panelOpen,
          panelWidth: 440,
          title: _editing != null ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới',
          onClose: _closePanel,
          panelBody: _buildPanelForm(isDark, parentOptions),
          panelFooter: _buildPanelFooter(isDark, prov.isLoading),
          child: _buildMainContent(isDark, prov, parents, childrenOf),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // MAIN CONTENT — Header + Category Tree
  // ═══════════════════════════════════════════════
  Widget _buildMainContent(
    bool isDark,
    CategoryProvider prov,
    List<Category> parents,
    List<Category> Function(String) childrenOf,
  ) {
    return Column(
      children: [
        // ─── Header Bar (search + filter + add) ───
        _buildHeaderBar(isDark, prov),

        // ─── Content ───
        Expanded(
          child: prov.isLoading && prov.categories.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
              : parents.isEmpty && _filterType != 'child'
                  ? _buildEmptyState(isDark)
                  : _filterType == 'child'
                      ? _buildChildOnlyList(isDark, prov)
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
                          itemCount: parents.length,
                          itemBuilder: (ctx, i) => _buildParentCard(isDark, parents[i], childrenOf),
                        ),
        ),
      ],
    );
  }

  // ─── Child-only flat list (when filter = 'child') ───
  Widget _buildChildOnlyList(bool isDark, CategoryProvider prov) {
    final allCats = prov.categories;
    var children = allCats.where((c) => c.parentId != null && c.parentId!.isNotEmpty).toList();
    if (_searchQuery.isNotEmpty) {
      children = children.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    if (children.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.subdirectory_arrow_right_rounded, size: 48, color: isDark ? Colors.white12 : const Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text('Không có danh mục con nào', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
        ]),
      );
    }

    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 32),
      itemCount: children.length,
      itemBuilder: (ctx, i) {
        final child = children[i];
        // Find parent name
        final parentCat = allCats.where((c) => c.id == child.parentId).firstOrNull;
        final parentName = parentCat?.name ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: border),
            boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 1))],
          ),
          child: Row(
            children: [
              Container(
                width: 3, height: 28,
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              _categoryAvatar(child, isDark, 36),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(child: Text(child.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    _genderBadge(child.gender, isDark),
                  ]),
                  const SizedBox(height: 2),
                  if (parentName.isNotEmpty)
                    Text('thuộc $parentName', style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA))),
                ],
              )),
              _statusBadge(child.isActive, isDark),
              const SizedBox(width: 8),
              _actionButtons(child, isDark, small: true),
            ],
          ),
        );
      },
    );
  }

  // ─── Header Bar ───
  Widget _buildHeaderBar(bool isDark, CategoryProvider prov) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 220,
            height: 36,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textDark),
              decoration: InputDecoration(
                hintText: 'Tìm danh mục...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Filter dropdown
          _buildFilterDropdown(isDark, border),

          const Spacer(),

          // Add button
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _openCreate(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm danh mục', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

  // ─── Filter Dropdown ───
  Widget _buildFilterDropdown(bool isDark, Color border) {
    final items = [
      ('all', 'Tất cả danh mục'),
      ('parent', 'Danh mục chính'),
      ('child', 'Danh mục con'),
    ];

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF374151)),
          items: items.map((item) {
            final isSelected = _filterType == item.$1;
            return DropdownMenuItem(
              value: item.$1,
              child: Text(item.$2, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _filterType = v ?? 'all'),
        ),
      ),
    );
  }

  // ─── Empty State ───
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.category_rounded, size: 36, color: Color(0xFF7C3AED)),
        ),
        const SizedBox(height: 16),
        Text('Chưa có danh mục nào', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151))),
        const SizedBox(height: 6),
        Text('Bắt đầu bằng cách thêm danh mục đầu tiên', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () => _openCreate(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Thêm danh mục'),
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
  // PARENT CARD — Expandable with children inside
  // ═══════════════════════════════════════════════
  Widget _buildParentCard(bool isDark, Category parent, List<Category> Function(String) childrenOf) {
    final children = childrenOf(parent.id);
    final isExpanded = _expanded.contains(parent.id);
    final hasChildren = children.isNotEmpty;

    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          // ─── Parent Row ───
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: hasChildren ? () => setState(() {
              if (isExpanded) {
                _expanded.remove(parent.id);
              } else {
                _expanded.add(parent.id);
              }
            }) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  // Expand icon
                  if (hasChildren)
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                    )
                  else
                    const SizedBox(width: 20),

                  const SizedBox(width: 10),

                  // Image / Icon
                  _categoryAvatar(parent, isDark, 40),
                  const SizedBox(width: 14),

                  // Name + meta
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(child: Text(parent.name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        _genderBadge(parent.gender, isDark),
                      ]),
                      const SizedBox(height: 3),
                      Row(children: [
                        Text('${parent.productCount} sản phẩm', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                        if (hasChildren) ...[
                          Text(' · ', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                          Text('${children.length} danh mục con', style: TextStyle(fontSize: 11, color: const Color(0xFF3B82F6), fontWeight: FontWeight.w500)),
                        ],
                      ]),
                    ],
                  )),

                  // Status
                  _statusBadge(parent.isActive, isDark),
                  const SizedBox(width: 12),

                  // Actions
                  _actionButtons(parent, isDark),
                ],
              ),
            ),
          ),

          // ─── Children ───
          if (isExpanded && hasChildren) ...[
            Divider(height: 1, color: border, indent: 18, endIndent: 18),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
              child: Column(
                children: [
                  ...children.map((child) => _buildChildRow(isDark, child, border)),
                  // Add child button
                  _addSubCategoryButton(isDark, parent.id),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Child Row ───
  Widget _buildChildRow(bool isDark, Category child, Color border) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          // Indent indicator
          Container(
            width: 2, height: 24,
            decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(1)),
          ),
          const SizedBox(width: 12),

          _categoryAvatar(child, isDark, 32),
          const SizedBox(width: 10),

          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: Text(child.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isDark ? Colors.white.withValues(alpha: 0.85) : const Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 6),
                _genderBadge(child.gender, isDark),
              ]),
              Text('${child.productCount} sản phẩm', style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA))),
            ],
          )),

          _statusBadge(child.isActive, isDark),
          const SizedBox(width: 8),
          _actionButtons(child, isDark, small: true),
        ],
      ),
    );
  }

  // ─── Add Sub-category Button ───
  Widget _addSubCategoryButton(bool isDark, String parentId) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openCreate(parentId: parentId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2), style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 16, color: Color(0xFF7C3AED)),
            SizedBox(width: 6),
            Text('Thêm danh mục con', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
          ],
        ),
      ),
    );
  }

  // ─── Shared Widgets ───
  Widget _categoryAvatar(Category cat, bool isDark, double size) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: Image.network(cat.imageUrl!, width: size, height: size, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _defaultAvatar(cat, isDark, size)),
      );
    }
    return _defaultAvatar(cat, isDark, size);
  }

  Widget _defaultAvatar(Category cat, bool isDark, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.12),
          const Color(0xFF3B82F6).withValues(alpha: 0.08),
        ]),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Center(child: Text(
        cat.name.isNotEmpty ? cat.name[0].toUpperCase() : '?',
        style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.w700, color: const Color(0xFF7C3AED)),
      )),
    );
  }

  Widget _genderBadge(String gender, bool isDark) {
    if (gender == 'all') return const SizedBox.shrink();
    final isMale = gender == 'male';
    final color = isMale ? const Color(0xFF3B82F6) : const Color(0xFFEC4899);
    final label = isMale ? 'Nam' : 'Nữ';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
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

  Widget _actionButtons(Category cat, bool isDark, {bool small = false}) {
    final iconSize = small ? 16.0 : 18.0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _iconButton(Icons.edit_rounded, const Color(0xFF7C3AED), () => _openEdit(cat), isDark, iconSize),
      const SizedBox(width: 4),
      _iconButton(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _delete(cat), isDark, iconSize),
    ]);
  }

  Widget _iconButton(IconData icon, Color color, VoidCallback onTap, bool isDark, double size) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        width: size + 14, height: size + 14,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: size, color: color.withValues(alpha: 0.7)),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PANEL FORM — Create / Edit
  // ═══════════════════════════════════════════════
  Widget _buildPanelForm(bool isDark, List<Category> parentOptions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name
        _formField(
          label: 'Tên danh mục *',
          child: _textInput(_nameCtrl, 'Nhập tên danh mục...', isDark),
        ),
        const SizedBox(height: 20),

        // Description
        _formField(
          label: 'Mô tả',
          child: _textInput(_descCtrl, 'Mô tả ngắn cho danh mục...', isDark, maxLines: 3),
        ),
        const SizedBox(height: 20),

        // Gender
        _formField(
          label: 'Giới tính',
          child: _genderSelector(isDark),
        ),
        const SizedBox(height: 20),

        // Parent category
        _formField(
          label: 'Thuộc danh mục cha',
          child: _parentDropdown(isDark, parentOptions),
        ),
        const SizedBox(height: 20),

        // Image
        CloudinaryImagePicker(controller: _imageCtrl, isDarkMode: isDark, label: 'Hình ảnh danh mục'),
        const SizedBox(height: 20),

        // Status toggle
        _formField(
          label: 'Trạng thái',
          child: _statusToggle(isDark),
        ),
        const SizedBox(height: 20),

        // Sort order
        _formField(
          label: 'Thứ tự hiển thị',
          child: _textInput(_sortCtrl, '0', isDark, inputType: TextInputType.number),
        ),
        const SizedBox(height: 20),

        // Note
        _formField(
          label: 'Ghi chú',
          child: _textInput(_noteCtrl, 'Ghi chú nội bộ...', isDark, maxLines: 2),
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

  Widget _genderSelector(bool isDark) {
    const options = [
      ('all', 'Tất cả', Icons.people_rounded),
      ('male', 'Nam', Icons.male_rounded),
      ('female', 'Nữ', Icons.female_rounded),
    ];
    return Row(
      children: options.map((o) {
        final selected = _gender == o.$1;
        final color = selected ? const Color(0xFF7C3AED) : (isDark ? Colors.white38 : const Color(0xFF9CA3AF));
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _gender = o.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.2 : 0.08) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: selected ? const Color(0xFF7C3AED).withValues(alpha: 0.4) : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB))),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(o.$3, size: 16, color: color),
                const SizedBox(width: 6),
                Text(o.$2, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: color)),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _parentDropdown(bool isDark, List<Category> options) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isExpanded: true,
          value: _parentId,
          hint: Text('Không (danh mục gốc)', style: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA))),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text('Không (danh mục gốc)', style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : const Color(0xFF6B7280)))),
            ...options.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 13)))),
          ],
          onChanged: (v) => setState(() => _parentId = v),
        ),
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
            _isActive ? 'Đang hiển thị — khách hàng có thể thấy' : 'Đã ẩn — không hiển thị cho khách hàng',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF374151)),
          )),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeColor: const Color(0xFF10B981),
          ),
        ]),
      ),
    );
  }

  // ─── Panel Footer ───
  Widget _buildPanelFooter(bool isDark, bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isLoading ? null : _closePanel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE5E7EB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Hủy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : const Color(0xFF6B7280))),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: isLoading ? null : _save,
            icon: isLoading
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Icon(_editing != null ? Icons.check_rounded : Icons.add_rounded, size: 18),
            label: Text(
              _editing != null ? 'Cập nhật' : 'Thêm danh mục',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
