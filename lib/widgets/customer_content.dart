import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'admin_slide_panel.dart';
import 'app_state_widgets.dart';

/// Trang quản lý Khách hàng — chỉ xem chi tiết và xóa.
/// Admin KHÔNG tạo / sửa khách hàng.
class CustomerContent extends StatefulWidget {
  const CustomerContent({super.key});

  @override
  State<CustomerContent> createState() => _CustomerContentState();
}

class _CustomerContentState extends State<CustomerContent> {
  bool get isDarkMode =>
      mounted ? Theme.of(context).brightness == Brightness.dark : false;
  final _fs = FirebaseFirestore.instance;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _statusTab = 0; // 0=all, 1=active, 2=inactive

  List<_Customer> _customers = [];
  bool _isLoading = true;
  String? _error;

  // ── Slide Panel State (detail only) ──
  bool _isPanelOpen = false;
  _Customer? _detailCustomer;

  static const _statusTabs = ['Tất cả', 'Hoạt động', 'Không hoạt động'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openDetailPanel(_Customer c) {
    _detailCustomer = c;
    setState(() => _isPanelOpen = true);
  }

  void _closePanel() {
    setState(() => _isPanelOpen = false);
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final snap = await _fs.collection('customers').limit(200).get();
      _customers = snap.docs.map((d) => _Customer.fromDoc(d)).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<_Customer> get _filtered {
    var list = _customers;
    if (_statusTab == 1) {
      list = list.where((c) => c.status == 'active').toList();
    }
    if (_statusTab == 2) {
      list = list.where((c) => c.status != 'active').toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list
          .where((c) =>
              c.name.toLowerCase().contains(q) ||
              c.email.toLowerCase().contains(q) ||
              c.phone.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppLoadingState(message: 'Đang tải khách hàng...');
    }
    if (_error != null && _customers.isEmpty) {
      return AppErrorState(message: _error!, onRetry: _load);
    }

    final list = _filtered;

    return AdminSlidePanel(
      isOpen: _isPanelOpen,
      title: 'Chi tiết khách hàng',
      onClose: _closePanel,
      panelBody: _buildDetailPanelBody(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatCards(),
            const SizedBox(height: 20),
            _buildFilterBar(),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const AppEmptyState(
                title: 'Không tìm thấy khách hàng',
                message: 'Thử thay đổi bộ lọc.',
                icon: Icons.people_outline_rounded,
              ),
            if (list.isNotEmpty) _buildTable(list),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quản lý khách hàng',
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: isDarkMode ? Colors.white : AppTheme.textDark)),
        const SizedBox(height: 4),
        Text(
            'Xem thông tin và theo dõi khách hàng',
            style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white54 : AppTheme.textLight)),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // STAT CARDS
  // ═══════════════════════════════════════════════
  Widget _buildStatCards() {
    final total = _customers.length;
    final active = _customers.where((c) => c.status == 'active').length;
    final inactive = total - active;
    final totalSpent =
        _customers.fold<double>(0, (s, c) => s + c.totalSpent);
    final totalOrders =
        _customers.fold<int>(0, (s, c) => s + c.totalOrders);

    return Row(
      children: [
        _statCard('Tổng KH', total.toString(), Icons.people_rounded,
            const Color(0xFF7C3AED)),
        const SizedBox(width: 12),
        _statCard('Hoạt động', active.toString(),
            Icons.check_circle_rounded, const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _statCard('Không hoạt động', inactive.toString(),
            Icons.cancel_rounded, const Color(0xFFEF4444)),
        const SizedBox(width: 12),
        _statCard('Tổng đơn hàng', totalOrders.toString(),
            Icons.shopping_bag_rounded, const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        _statCard('Tổng chi tiêu', _fmtVND(totalSpent),
            Icons.attach_money_rounded, const Color(0xFFF59E0B)),
      ],
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF111827)),
                      overflow: TextOverflow.ellipsis),
                  Text(label,
                      style: TextStyle(
                          fontSize: 10,
                          color: isDarkMode
                              ? Colors.white54
                              : const Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // FILTER BAR (search + status tabs stacked)
  // ═══════════════════════════════════════════════
  Widget _buildFilterBar() {
    final cardBg = isDarkMode ? AppTheme.darkCardBg : Colors.white;
    final bdr = isDarkMode
        ? Colors.white.withValues(alpha: 0.1)
        : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search ──
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded,
                    size: 18,
                    color: isDarkMode
                        ? Colors.white38
                        : const Color(0xFF9CA3AF)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.trim()),
                    style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, email, SĐT...',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDarkMode
                              ? Colors.white38
                              : const Color(0xFF9CA3AF)),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      filled: false,
                      isCollapsed: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.close_rounded,
                        size: 16,
                        color: isDarkMode
                            ? Colors.white38
                            : const Color(0xFF9CA3AF)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // ── Status pills ──
          Row(
            children: [
              Text('Trạng thái:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode
                          ? Colors.white54
                          : const Color(0xFF6B7280))),
              const SizedBox(width: 10),
              ..._statusTabs.asMap().entries.map((e) {
                final isActive = e.key == _statusTab;
                final colors = [
                  const Color(0xFF7C3AED),
                  const Color(0xFF10B981),
                  const Color(0xFFEF4444),
                ];
                final c = colors[e.key];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _statusTab = e.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? c
                            : (isDarkMode
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF3F4F6)),
                        borderRadius: BorderRadius.circular(20),
                        border: isActive
                            ? null
                            : Border.all(
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : const Color(0xFFE5E7EB)),
                      ),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? Colors.white
                              : (isDarkMode
                                  ? Colors.white70
                                  : const Color(0xFF374151)),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  // =======================================================================
  // DATA TABLE
  // =======================================================================
  Widget _buildTable(List<_Customer> list) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.1)
                : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFF9FAFB),
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                _hdr('Tên', 3),
                _hdr('Liên hệ', 3),
                _hdr('Trạng thái', 2),
                _hdr('Đơn hàng', 1),
                _hdr('Tổng chi tiêu', 2),
                _hdr('Cập nhật', 2),
                _hdr('Thao tác', 2),
              ],
            ),
          ),
          ...list.map((c) => _buildRow(c)),
        ],
      ),
    );
  }

  Widget _hdr(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDarkMode
                  ? Colors.white54
                  : const Color(0xFF6B7280))),
    );
  }

  Widget _buildRow(_Customer c) {
    final isActive = c.status == 'active';
    final statusColor =
        isActive ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          // Tên
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      const Color(0xFF7C3AED).withValues(alpha: 0.12),
                  child: Text(
                      c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF7C3AED))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(c.name,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode
                              ? Colors.white
                              : const Color(0xFF111827)),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          // Liên hệ
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (c.email.isNotEmpty)
                  Text(c.email,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode
                              ? Colors.white70
                              : const Color(0xFF374151)),
                      overflow: TextOverflow.ellipsis),
                if (c.phone.isNotEmpty)
                  Text(c.phone,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDarkMode
                              ? Colors.white54
                              : const Color(0xFF6B7280))),
              ],
            ),
          ),
          // Trạng thái
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                    isActive ? 'Hoạt động' : 'Không hoạt động',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor)),
              ),
            ),
          ),
          // Đơn hàng
          Expanded(
            flex: 1,
            child: Text(c.totalOrders.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.white
                        : const Color(0xFF111827))),
          ),
          // Tổng chi tiêu
          Expanded(
            flex: 2,
            child: Text(_fmtVND(c.totalSpent),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981))),
          ),
          // Cập nhật
          Expanded(
            flex: 2,
            child: Text(_fmtDate(c.updatedAt),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode
                        ? Colors.white54
                        : const Color(0xFF6B7280))),
          ),
          // Thao tác: chỉ Xem + Xóa
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionBtn(Icons.visibility_rounded, 'Xem',
                    const Color(0xFF3B82F6), () => _openDetailPanel(c)),
                const SizedBox(width: 4),
                _actionBtn(Icons.delete_outline_rounded, 'Xóa',
                    const Color(0xFFEF4444), () => _confirmDelete(c)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String tooltip, Color color, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DETAIL PANEL BODY
  // ═══════════════════════════════════════════════
  Widget _buildDetailPanelBody() {
    final c = _detailCustomer;
    if (c == null) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
          child: CircleAvatar(
        radius: 32,
        backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.12),
        child: Text(
            c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7C3AED))),
      )),
      const SizedBox(height: 12),
      Center(
          child: Text(c.name,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode
                      ? Colors.white
                      : const Color(0xFF111827)))),
      Center(
          child: Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: (c.status == 'active'
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444))
              .withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
            c.status == 'active' ? 'Hoạt động' : 'Không hoạt động',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: c.status == 'active'
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444))),
      )),
      const SizedBox(height: 20),
      _detailRow('Email', c.email.isNotEmpty ? c.email : '—'),
      _detailRow('Số điện thoại', c.phone.isNotEmpty ? c.phone : '—'),
      _detailRow('Địa chỉ', c.address.isNotEmpty ? c.address : '—'),
      _detailRow('Tổng đơn hàng', c.totalOrders.toString()),
      _detailRow('Tổng chi tiêu', _fmtVND(c.totalSpent)),
      _detailRow('Ghi chú', c.note.isNotEmpty ? c.note : '—'),
      _detailRow('Ngày tạo', _fmtDate(c.createdAt)),
      _detailRow('Cập nhật', _fmtDate(c.updatedAt)),
    ]);
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 120,
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white54
                          : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white
                          : const Color(0xFF111827),
                      fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DELETE
  // ═══════════════════════════════════════════════
  Future<void> _confirmDelete(_Customer c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa khách hàng?'),
        content: Text(
            'Bạn chắc chắn muốn xóa khách hàng "${c.name}"?\nHành động này không thể hoàn tác.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _fs.collection('customers').doc(c.id).delete();
      if (mounted) {
        AppSnackBar.success(context, 'Đã xóa khách hàng');
        _load();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Lỗi: $e');
    }
  }

  // ═══════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════
  String _fmtVND(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  String _fmtDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mi';
  }
}

// ═══════════════════════════════════════════════
// MODEL
// ═══════════════════════════════════════════════
class _Customer {
  final String id, name, email, phone, address, status, note;
  final int totalOrders;
  final double totalSpent;
  final DateTime createdAt, updatedAt;

  _Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.status,
    required this.note,
    required this.totalOrders,
    required this.totalSpent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory _Customer.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ca = _toDate(d['createdAt']) ?? DateTime(2000);
    final ua = _toDate(d['updatedAt']) ?? ca;
    return _Customer(
      id: doc.id,
      name: _str(d['name']).isNotEmpty
          ? _str(d['name'])
          : _str(d['customerName']).isNotEmpty
              ? _str(d['customerName'])
              : doc.id,
      email: _str(d['email']),
      phone: _str(d['phone']).isNotEmpty
          ? _str(d['phone'])
          : _str(d['customerPhone']),
      address: _str(d['address']).isNotEmpty
          ? _str(d['address'])
          : _str(d['customerAddress']),
      status:
          _str(d['status']).isNotEmpty ? _str(d['status']) : 'active',
      note: _str(d['note']),
      totalOrders: _int(d['totalOrders']),
      totalSpent: _dbl(d['totalSpent']),
      createdAt: ca,
      updatedAt: ua,
    );
  }

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  static String _str(dynamic v) => (v ?? '').toString().trim();
  static int _int(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  static double _dbl(dynamic v) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '') ?? 0;
  }
}
