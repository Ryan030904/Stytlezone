import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Trang Báo cáo — hiển thị dữ liệu thực từ Firestore.
class ReportContent extends StatefulWidget {
  const ReportContent({super.key});

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  bool get isDarkMode => mounted ? Theme.of(context).brightness == Brightness.dark : false;
  final _fs = FirebaseFirestore.instance;

  // summary
  int _totalOrders = 0;
  double _totalRevenue = 0;
  int _totalProducts = 0;
  int _totalCustomers = 0;
  int _completedOrders = 0;
  int _pendingOrders = 0;

  // tables
  List<Map<String, dynamic>> _topProducts = [];
  List<Map<String, dynamic>> _lowStock = [];
  List<Map<String, dynamic>> _recentOrders = [];
  List<Map<String, dynamic>> _recentReceipts = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([_loadOrderStats(), _loadProductStats(), _loadReceipts()]);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadOrderStats() async {
    final snap = await _fs.collection('orders').get();
    final docs = snap.docs.where((d) => d.data()['isDeleted'] != true).toList();
    double rev = 0;
    int completed = 0, pending = 0;
    final customers = <String>{};
    final recent = <Map<String, dynamic>>[];

    for (final d in docs) {
      final data = d.data();
      final total = (data['total'] ?? data['subtotal'] ?? 0).toDouble();
      rev += total;
      final status = (data['status'] ?? '').toString().toLowerCase();
      if (status == 'delivered' || status == 'completed') completed++;
      if (status == 'pending' || status == 'confirmed') pending++;
      final name = (data['customerName'] ?? '').toString();
      if (name.isNotEmpty) customers.add(name);
      recent.add({...data, 'id': d.id});
    }

    recent.sort((a, b) {
      final aTime = _toDate(a['createdAt']) ?? DateTime(2000);
      final bTime = _toDate(b['createdAt']) ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });

    _totalOrders = docs.length;
    _totalRevenue = rev;
    _completedOrders = completed;
    _pendingOrders = pending;
    _totalCustomers = customers.length;
    _recentOrders = recent.take(10).toList();
  }

  Future<void> _loadProductStats() async {
    final snap = await _fs.collection('products').get();
    final docs = snap.docs.where((d) => d.data()['isDeleted'] != true).toList();
    _totalProducts = docs.length;

    // top bán chạy — sort by sold or stock
    final all = docs.map((d) => {...d.data(), 'id': d.id}).toList();
    all.sort((a, b) => ((b['sold'] ?? 0) as num).compareTo((a['sold'] ?? 0) as num));
    _topProducts = all.take(10).toList();

    // tồn kho thấp
    final low = all.where((p) => (p['stock'] ?? 0) <= 10 && (p['isActive'] != false)).toList();
    low.sort((a, b) => ((a['stock'] ?? 0) as num).compareTo((b['stock'] ?? 0) as num));
    _lowStock = low.take(10).toList();
  }

  Future<void> _loadReceipts() async {
    try {
      final snap = await _fs.collection('warehouse_receipts').orderBy('updatedAt', descending: true).limit(10).get();
      _recentReceipts = snap.docs.map((d) => {...d.data(), 'id': d.id}).where((d) => d['isDeleted'] != true).toList();
    } catch (_) {
      _recentReceipts = [];
    }
  }

  DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(80),
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      ));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStatCards(),
          const SizedBox(height: 24),
          // 2 columns: recent orders + top products
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildRecentOrders()),
              const SizedBox(width: 16),
              Expanded(child: _buildTopProducts()),
            ],
          ),
          const SizedBox(height: 16),
          // 2 columns: low stock + recent receipts
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildLowStock()),
              const SizedBox(width: 16),
              Expanded(child: _buildRecentReceipts()),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Báo cáo tổng hợp',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : AppTheme.textDark)),
              SizedBox(height: 4),
              Text('Phân tích dữ liệu kinh doanh từ hệ thống',
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : AppTheme.textLight)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _loadAll,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Tải lại'),
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

  // ═══════════════════════════════════════════════
  // STAT CARDS
  // ═══════════════════════════════════════════════
  Widget _buildStatCards() {
    return Row(
      children: [
        _statCard('Tổng doanh thu', _fmtVND(_totalRevenue), Icons.attach_money_rounded, const Color(0xFF10B981)),
        const SizedBox(width: 12),
        _statCard('Tổng đơn hàng', _totalOrders.toString(), Icons.shopping_bag_rounded, const Color(0xFF7C3AED)),
        const SizedBox(width: 12),
        _statCard('Đơn hoàn tất', _completedOrders.toString(), Icons.check_circle_rounded, const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        _statCard('Đang chờ xử lý', _pendingOrders.toString(), Icons.pending_actions_rounded, const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _statCard('Sản phẩm', _totalProducts.toString(), Icons.inventory_2_rounded, const Color(0xFFEC4899)),
        const SizedBox(width: 12),
        _statCard('Khách hàng', _totalCustomers.toString(), Icons.people_rounded, const Color(0xFF6366F1)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : const Color(0xFF111827)),
                      overflow: TextOverflow.ellipsis),
                  Text(label, style: TextStyle(fontSize: 10, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // RECENT ORDERS
  // ═══════════════════════════════════════════════
  Widget _buildRecentOrders() {
    return _section(
      title: 'Đơn hàng gần đây',
      icon: Icons.shopping_bag_rounded,
      color: const Color(0xFF7C3AED),
      child: _recentOrders.isEmpty
          ? _emptyMsg('Chưa có đơn hàng')
          : Column(
              children: [
                _tableHeader(['Mã đơn', 'Khách hàng', 'Tổng tiền', 'Trạng thái']),
                ..._recentOrders.map((o) {
                  final code = (o['code'] ?? o['id']?.toString().substring(0, 8) ?? '').toString();
                  final customer = (o['customerName'] ?? '-').toString();
                  final total = (o['total'] ?? o['subtotal'] ?? 0).toDouble();
                  final status = (o['status'] ?? 'pending').toString();
                  return _tableRow([
                    _cellText(code, bold: true, color: const Color(0xFF7C3AED)),
                    _cellText(customer),
                    _cellText(_fmtVND(total)),
                    _statusBadge(_orderStatusLabel(status), _orderStatusColor(status)),
                  ]);
                }),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════
  // TOP PRODUCTS
  // ═══════════════════════════════════════════════
  Widget _buildTopProducts() {
    return _section(
      title: 'Sản phẩm bán chạy',
      icon: Icons.local_fire_department_rounded,
      color: const Color(0xFFEC4899),
      child: _topProducts.isEmpty
          ? _emptyMsg('Chưa có dữ liệu sản phẩm')
          : Column(
              children: [
                _tableHeader(['Sản phẩm', 'Giá', 'Tồn kho', 'Đã bán']),
                ..._topProducts.map((p) {
                  final name = (p['name'] ?? '-').toString();
                  final price = (p['price'] ?? 0).toDouble();
                  final stock = (p['stock'] ?? 0);
                  final sold = (p['sold'] ?? 0);
                  return _tableRow([
                    _cellText(name, bold: true),
                    _cellText(_fmtVND(price)),
                    _cellText(stock.toString(), color: stock <= 10 ? const Color(0xFFEF4444) : null),
                    _cellText(sold.toString(), color: const Color(0xFF10B981)),
                  ]);
                }),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════
  // LOW STOCK
  // ═══════════════════════════════════════════════
  Widget _buildLowStock() {
    return _section(
      title: 'Tồn kho thấp (≤ 10)',
      icon: Icons.warning_amber_rounded,
      color: const Color(0xFFEF4444),
      child: _lowStock.isEmpty
          ? _emptyMsg('Không có sản phẩm tồn kho thấp')
          : Column(
              children: [
                _tableHeader(['Sản phẩm', 'SKU', 'Tồn kho', 'Giá']),
                ..._lowStock.map((p) {
                  final name = (p['name'] ?? '-').toString();
                  final sku = (p['sku'] ?? '-').toString();
                  final stock = (p['stock'] ?? 0);
                  final price = (p['price'] ?? 0).toDouble();
                  return _tableRow([
                    _cellText(name, bold: true),
                    _cellText(sku),
                    _cellText(stock.toString(), color: const Color(0xFFEF4444), bold: true),
                    _cellText(_fmtVND(price)),
                  ]);
                }),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════
  // RECENT WAREHOUSE RECEIPTS
  // ═══════════════════════════════════════════════
  Widget _buildRecentReceipts() {
    return _section(
      title: 'Phiếu kho gần đây',
      icon: Icons.receipt_long_rounded,
      color: const Color(0xFF3B82F6),
      child: _recentReceipts.isEmpty
          ? _emptyMsg('Chưa có phiếu kho')
          : Column(
              children: [
                _tableHeader(['Mã phiếu', 'Loại', 'Kho', 'Trạng thái']),
                ..._recentReceipts.map((r) {
                  final code = (r['code'] ?? r['id']?.toString().substring(0, 8) ?? '').toString();
                  final type = _receiptTypeLabel((r['type'] ?? '').toString());
                  final wh = (r['warehouse'] ?? '-').toString();
                  final status = (r['status'] ?? 'draft').toString();
                  return _tableRow([
                    _cellText(code, bold: true, color: const Color(0xFF7C3AED)),
                    _cellText(type),
                    _cellText(wh),
                    _statusBadge(_receiptStatusLabel(status), _receiptStatusColor(status)),
                  ]);
                }),
              ],
            ),
    );
  }

  // ═══════════════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════════════
  Widget _section({required String title, required IconData icon, required Color color, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(14), topRight: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 16),
                ),
                SizedBox(width: 10),
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : const Color(0xFF111827))),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _tableHeader(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)))),
      child: Row(
        children: cols.map((c) => Expanded(
          child: Text(c, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
        )).toList(),
      ),
    );
  }

  Widget _tableRow(List<Widget> cells) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6)))),
      child: Row(children: cells.map((c) => Expanded(child: c)).toList()),
    );
  }

  Widget _cellText(String text, {bool bold = false, Color? color}) {
    return Text(text, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: color ?? const Color(0xFF374151)));
  }

  Widget _statusBadge(String label, Color color) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ),
    );
  }

  Widget _emptyMsg(String msg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text(msg, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)))),
    );
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

  String _orderStatusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'pending': return 'Chờ xử lý';
      case 'confirmed': return 'Đã xác nhận';
      case 'processing': return 'Đang xử lý';
      case 'shipping': return 'Đang giao';
      case 'delivered': return 'Đã giao';
      case 'completed': return 'Hoàn tất';
      case 'cancelled': return 'Đã hủy';
      case 'returned': return 'Đã hoàn';
      default: return s;
    }
  }

  Color _orderStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'delivered': case 'completed': return const Color(0xFF10B981);
      case 'shipping': case 'processing': return const Color(0xFF3B82F6);
      case 'pending': case 'confirmed': return const Color(0xFFF59E0B);
      case 'cancelled': case 'returned': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  String _receiptTypeLabel(String s) {
    switch (s.toLowerCase()) {
      case 'import': case 'stockin': return 'Nhập kho';
      case 'export': case 'stockout': return 'Xuất kho';
      case 'transfer': return 'Chuyển kho';
      case 'stock_check': case 'stockcheck': return 'Kiểm kho';
      default: return s;
    }
  }

  String _receiptStatusLabel(String s) {
    switch (s.toLowerCase()) {
      case 'draft': return 'Nháp';
      case 'processing': return 'Đang xử lý';
      case 'completed': return 'Hoàn tất';
      case 'cancelled': return 'Đã hủy';
      default: return s;
    }
  }

  Color _receiptStatusColor(String s) {
    switch (s.toLowerCase()) {
      case 'completed': return const Color(0xFF10B981);
      case 'processing': return const Color(0xFFF59E0B);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }
}
