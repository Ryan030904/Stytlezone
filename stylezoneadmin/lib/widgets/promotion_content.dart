import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/promotion_model.dart';
import '../providers/promotion_provider.dart';
import '../screens/dashboard_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_slide_panel.dart';

/// ──────────────────────────────────────────────
/// PROMOTION MANAGEMENT — CRUD with DataTable
/// ──────────────────────────────────────────────
class PromotionContent extends StatefulWidget {
  const PromotionContent({super.key});

  @override
  State<PromotionContent> createState() => _PromotionContentState();
}

class _PromotionContentState extends State<PromotionContent> {
  // ─── Panel state ───
  bool _panelOpen = false;
  Promotion? _editing; // null = create

  // ─── Filters ───
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // all | running | upcoming | ended | off

  // ─── Form controllers ───
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _discountValueCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController();
  final _maxUsesCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DiscountType _discountType = DiscountType.percent;
  bool _isActive = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 30));

  // ─── Date helpers ───
  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtDateTime(DateTime d) => '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _closePanelOnTabSwitch() {
    if (_panelOpen) setState(() => _panelOpen = false);
  }

  @override
  void initState() {
    super.initState();
    DashboardScreen.panelCloseNotifier.addListener(_closePanelOnTabSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prov = context.read<PromotionProvider>();
      if (prov.promotions.isEmpty) prov.loadPromotions();
    });
  }

  @override
  void dispose() {
    DashboardScreen.panelCloseNotifier.removeListener(_closePanelOnTabSwitch);
    _searchCtrl.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _discountValueCtrl.dispose();
    _minOrderCtrl.dispose();
    _maxUsesCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ─── Open panel for CREATE ───
  void _openCreate() {
    _editing = null;
    _codeCtrl.clear();
    _nameCtrl.clear();
    _descCtrl.clear();
    _discountValueCtrl.clear();
    _minOrderCtrl.clear();
    _maxUsesCtrl.clear();
    _noteCtrl.clear();
    _discountType = DiscountType.percent;
    _isActive = true;
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 30));
    setState(() => _panelOpen = true);
  }

  // ─── Open panel for EDIT ───
  void _openEdit(Promotion promo) {
    _editing = promo;
    _codeCtrl.text = promo.code;
    _nameCtrl.text = promo.name;
    _descCtrl.text = promo.description;
    _discountValueCtrl.text = promo.discountValue.toStringAsFixed(0);
    _minOrderCtrl.text = promo.minOrderAmount > 0 ? promo.minOrderAmount.toStringAsFixed(0) : '';
    _maxUsesCtrl.text = promo.maxUses > 0 ? promo.maxUses.toString() : '';
    _noteCtrl.text = promo.note;
    _discountType = promo.discountType;
    _isActive = promo.isActive;
    _startDate = promo.startDate;
    _endDate = promo.endDate;
    setState(() => _panelOpen = true);
  }

  void _closePanel() => setState(() => _panelOpen = false);

  // ─── SAVE (create or update) ───
  Future<void> _save() async {
    final code = _codeCtrl.text.trim().toUpperCase();
    final name = _nameCtrl.text.trim();
    if (code.isEmpty || name.isEmpty) {
      _showSnack('Vui lòng nhập mã và tên khuyến mãi');
      return;
    }
    final discountValue = double.tryParse(_discountValueCtrl.text.trim()) ?? 0;
    if (discountValue <= 0) {
      _showSnack('Giá trị giảm phải lớn hơn 0');
      return;
    }
    if (_discountType == DiscountType.percent && discountValue > 100) {
      _showSnack('Phần trăm giảm không thể lớn hơn 100%');
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      _showSnack('Ngày kết thúc phải sau ngày bắt đầu');
      return;
    }

    final prov = context.read<PromotionProvider>();
    final now = DateTime.now();

    if (_editing != null) {
      final updated = _editing!.copyWith(
        code: code,
        name: name,
        description: _descCtrl.text.trim(),
        discountType: _discountType,
        discountValue: discountValue,
        minOrderAmount: double.tryParse(_minOrderCtrl.text.trim()) ?? 0,
        maxUses: int.tryParse(_maxUsesCtrl.text.trim()) ?? 0,
        note: _noteCtrl.text.trim(),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        updatedAt: now,
      );
      final ok = await prov.updatePromotion(updated);
      if (ok && mounted) {
        _closePanel();
        _showSnack('Cập nhật khuyến mãi thành công', success: true);
      }
    } else {
      final newPromo = Promotion(
        id: '',
        code: code,
        name: name,
        description: _descCtrl.text.trim(),
        discountType: _discountType,
        discountValue: discountValue,
        minOrderAmount: double.tryParse(_minOrderCtrl.text.trim()) ?? 0,
        maxUses: int.tryParse(_maxUsesCtrl.text.trim()) ?? 0,
        note: _noteCtrl.text.trim(),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        createdAt: now,
        updatedAt: now,
      );
      final ok = await prov.createPromotion(newPromo);
      if (ok && mounted) {
        _closePanel();
        _showSnack('Tạo khuyến mãi thành công', success: true);
      }
    }
  }

  // ─── DELETE ───
  Future<void> _delete(Promotion promo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xóa khuyến mãi "${promo.name}"?', style: const TextStyle(fontSize: 14)),
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
      final ok = await context.read<PromotionProvider>().deletePromotion(promo.id);
      if (ok && mounted) _showSnack('Đã xóa khuyến mãi', success: true);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  // ─── Pick date ───
  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7C3AED)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  // ─── Filter promotions ───
  List<Promotion> _applyFilters(List<Promotion> all) {
    var result = all.toList();

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
          p.code.toLowerCase().contains(q) ||
          p.name.toLowerCase().contains(q)).toList();
    }

    // Status filter
    if (_statusFilter != 'all') {
      result = result.where((p) {
        switch (_statusFilter) {
          case 'running': return p.status == 'Đang chạy';
          case 'upcoming': return p.status == 'Sắp tới';
          case 'ended': return p.status == 'Đã kết thúc';
          case 'off': return p.status == 'Tắt';
          default: return true;
        }
      }).toList();
    }

    return result;
  }

  // ═══════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<PromotionProvider>(
      builder: (context, prov, _) {
        final filtered = _applyFilters(prov.promotions);

        return AdminSlidePanel(
          isOpen: _panelOpen,
          panelWidth: 460,
          title: _editing != null ? 'Chỉnh sửa khuyến mãi' : 'Thêm khuyến mãi mới',
          onClose: _closePanel,
          panelBody: _buildPanelForm(isDark),
          panelFooter: _buildPanelFooter(isDark, prov.isLoading),
          child: _buildMainContent(isDark, prov, filtered),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // MAIN CONTENT = Header + Table
  // ═══════════════════════════════════════════════
  Widget _buildMainContent(bool isDark, PromotionProvider prov, List<Promotion> data) {
    return Column(
      children: [
        _buildHeaderBar(isDark, prov),
        Expanded(
          child: prov.isLoading && prov.promotions.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
              : data.isEmpty
                  ? _buildEmptyState(isDark)
                  : _buildDataTable(isDark, data),
        ),
      ],
    );
  }

  // ─── Header Bar ───
  Widget _buildHeaderBar(bool isDark, PromotionProvider prov) {
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
          // Left: Filter + Search (scrollable)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Status filter dropdown
                  SizedBox(
                    height: 36,
                    child: _filterDropdown(isDark, border),
                  ),
                  const SizedBox(width: 10),

                  // Search
                  SizedBox(
                    width: 200,
                    height: 36,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textDark),
                      decoration: InputDecoration(
                        hintText: 'Tìm mã, tên...',
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
                ],
              ),
            ),
          ),
          // Right: Add button
          const SizedBox(width: 16),
          SizedBox(
            height: 36,
            child: ElevatedButton.icon(
              onPressed: () => _openCreate(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Thêm khuyến mãi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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

  Widget _filterDropdown(bool isDark, Color border) {
    const filters = [
      ('all', 'Tất cả'),
      ('running', 'Đang chạy'),
      ('upcoming', 'Sắp tới'),
      ('ended', 'Đã kết thúc'),
      ('off', 'Đã tắt'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _statusFilter,
          isDense: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
          items: filters.map((f) => DropdownMenuItem(value: f.$1, child: Text(f.$2, style: const TextStyle(fontSize: 12)))).toList(),
          onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
        ),
      ),
    );
  }

  Widget _statsChip(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ]),
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
          child: const Icon(Icons.local_offer_rounded, size: 36, color: Color(0xFF7C3AED)),
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty || _statusFilter != 'all'
              ? 'Không tìm thấy khuyến mãi'
              : 'Chưa có khuyến mãi nào',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        Text(
          _searchQuery.isNotEmpty || _statusFilter != 'all'
              ? 'Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm'
              : 'Tạo mã khuyến mãi đầu tiên cho cửa hàng',
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
        ),
        if (_searchQuery.isEmpty && _statusFilter == 'all') ...[
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _openCreate(),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm khuyến mãi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ]),
    );
  }

  // ═══════════════════════════════════════════════
  // DATA TABLE
  // ═══════════════════════════════════════════════
  Widget _buildDataTable(bool isDark, List<Promotion> data) {
    final cardBg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAFAFB);
    final headerText = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white54 : const Color(0xFF6B7280), letterSpacing: 0.5);

    return Container(
      margin: const EdgeInsets.fromLTRB(28, 16, 28, 28),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(headerBg),
              headingRowHeight: 44,
              dataRowMinHeight: 56,
              dataRowMaxHeight: 56,
              horizontalMargin: 20,
              columnSpacing: 16,
              dividerThickness: 0.5,
              columns: [
                DataColumn(label: Text('MÃ', style: headerText)),
                DataColumn(label: Text('TÊN KHUYẾN MÃI', style: headerText)),
                DataColumn(label: Text('GIẢM', style: headerText)),
                DataColumn(label: Text('ĐƠN TỐI THIỂU', style: headerText)),
                DataColumn(label: Text('SỐ LƯỢNG', style: headerText)),
                DataColumn(label: Text('THỜI GIAN', style: headerText)),
                DataColumn(label: Text('TRẠNG THÁI', style: headerText)),
                DataColumn(label: Text('', style: headerText)),
              ],
              rows: data.map((promo) => _buildDataRow(promo, isDark)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(Promotion promo, bool isDark) {
    return DataRow(
      cells: [
        // Code
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              promo.code,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF7C3AED), letterSpacing: 0.5),
            ),
          ),
        ),
        // Name
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(promo.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis),
              if (promo.description.isNotEmpty)
                Text(promo.description, style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        // Discount
        DataCell(
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              promo.discountType == DiscountType.percent ? Icons.percent_rounded : Icons.payments_rounded,
              size: 14,
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 4),
            Text(promo.discountLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
          ]),
        ),
        // Min order
        DataCell(Text(
          promo.minOrderAmount > 0 ? _formatCurrency(promo.minOrderAmount) : '—',
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
        )),
        // Uses
        DataCell(Text(
          promo.maxUses > 0 ? '${promo.usedCount}/${promo.maxUses}' : '${promo.usedCount}/∞',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : const Color(0xFF6B7280)),
        )),
        // Date range
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_fmtDate(promo.startDate), style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
              Text('→ ${_fmtDate(promo.endDate)}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
            ],
          ),
        ),
        // Status
        DataCell(_statusBadge(promo.status, isDark)),
        // Actions
        DataCell(Row(mainAxisSize: MainAxisSize.min, children: [
          _iconButton(Icons.edit_rounded, const Color(0xFF7C3AED), () => _openEdit(promo), isDark),
          const SizedBox(width: 4),
          _iconButton(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _delete(promo), isDark),
        ])),
      ],
    );
  }

  // ─── Status badge ───
  Widget _statusBadge(String status, bool isDark) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Đang chạy':
        color = const Color(0xFF10B981);
        icon = Icons.play_circle_fill_rounded;
        break;
      case 'Sắp tới':
        color = const Color(0xFFF59E0B);
        icon = Icons.schedule_rounded;
        break;
      case 'Đã kết thúc':
        color = const Color(0xFF6B7280);
        icon = Icons.stop_circle_rounded;
        break;
      default: // Tắt
        color = const Color(0xFFEF4444);
        icon = Icons.cancel_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
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

  String _formatCurrency(double value) {
    final s = value.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()}đ';
  }

  // ═══════════════════════════════════════════════
  // PANEL FORM
  // ═══════════════════════════════════════════════
  Widget _buildPanelForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Code + Name in one row
        Row(children: [
          Expanded(
            flex: 2,
            child: _formField(
              label: 'Mã khuyến mãi *',
              child: _textInput(_codeCtrl, 'VD: SALE50', isDark, textCap: TextCapitalization.characters),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: _formField(
              label: 'Tên khuyến mãi *',
              child: _textInput(_nameCtrl, 'VD: Giảm 50% toàn sàn', isDark),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // Description
        _formField(
          label: 'Mô tả',
          child: _textInput(_descCtrl, 'Mô tả chi tiết chương trình...', isDark, maxLines: 2),
        ),
        const SizedBox(height: 20),

        // Discount type selector + value
        _formField(
          label: 'Loại giảm giá *',
          child: Row(children: [
            _typePill('Phần trăm (%)', DiscountType.percent, isDark),
            const SizedBox(width: 8),
            _typePill('Cố định (đ)', DiscountType.fixed, isDark),
            const SizedBox(width: 14),
            Expanded(child: _textInput(
              _discountValueCtrl,
              _discountType == DiscountType.percent ? 'VD: 50' : 'VD: 100000',
              isDark,
              inputType: TextInputType.number,
            )),
          ]),
        ),
        const SizedBox(height: 20),

        // Min order + Max uses
        Row(children: [
          Expanded(
            child: _formField(
              label: 'Đơn tối thiểu (đ)',
              child: _textInput(_minOrderCtrl, '0 = không giới hạn', isDark, inputType: TextInputType.number),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _formField(
              label: 'Số lượt dùng tối đa',
              child: _textInput(_maxUsesCtrl, '0 = không giới hạn', isDark, inputType: TextInputType.number),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // Date range
        Row(children: [
          Expanded(
            child: _formField(
              label: 'Ngày bắt đầu *',
              child: _datePickerButton(isDark, _startDate, () => _pickDate(isStart: true)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _formField(
              label: 'Ngày kết thúc *',
              child: _datePickerButton(isDark, _endDate, () => _pickDate(isStart: false)),
            ),
          ),
        ]),
        const SizedBox(height: 20),

        // Status toggle
        _formField(
          label: 'Trạng thái',
          child: _statusToggle(isDark),
        ),
        const SizedBox(height: 20),

        // Note
        _formField(
          label: 'Ghi chú nội bộ',
          child: _textInput(_noteCtrl, 'Ghi chú dành cho admin...', isDark, maxLines: 2),
        ),

        // Show metadata if editing
        if (_editing != null) ...[
          const SizedBox(height: 24),
          Divider(color: isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB)),
          const SizedBox(height: 12),
          _metaRow('Đã sử dụng', '${_editing!.usedCount} lượt', isDark),
          _metaRow('Tạo lúc', _fmtDateTime(_editing!.createdAt), isDark),
          _metaRow('Cập nhật lúc', _fmtDateTime(_editing!.updatedAt), isDark),
          if (_editing!.createdBy.isNotEmpty) _metaRow('Tạo bởi', _editing!.createdBy, isDark),
        ],
      ],
    );
  }

  Widget _typePill(String label, DiscountType type, bool isDark) {
    final selected = _discountType == type;
    final color = selected ? const Color(0xFF7C3AED) : (isDark ? Colors.white38 : const Color(0xFF9CA3AF));
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _discountType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C3AED).withValues(alpha: isDark ? 0.2 : 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF7C3AED).withValues(alpha: 0.4) : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB))),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w500, color: color)),
      ),
    );
  }

  Widget _datePickerButton(bool isDark, DateTime date, VoidCallback onTap) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded, size: 16, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Text(_fmtDate(date), style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827))),
        ]),
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
            _isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: _isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(
            _isActive ? 'Kích hoạt — khuyến mãi sẽ áp dụng trong thời gian quy định' : 'Đã tắt — khuyến mãi sẽ không được áp dụng',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF374151)),
          )),
          Switch(
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            activeThumbColor: const Color(0xFF10B981),
          ),
        ]),
      ),
    );
  }

  Widget _metaRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
        ),
        Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white60 : const Color(0xFF6B7280)))),
      ]),
    );
  }

  // ─── Shared Form Helpers ───
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

  Widget _textInput(TextEditingController ctrl, String hint, bool isDark, {int maxLines = 1, TextInputType? inputType, TextCapitalization textCap = TextCapitalization.none}) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: inputType,
      textCapitalization: textCap,
      inputFormatters: inputType == TextInputType.number ? [FilteringTextInputFormatter.digitsOnly] : null,
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
              _editing != null ? 'Cập nhật' : 'Tạo mới',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
