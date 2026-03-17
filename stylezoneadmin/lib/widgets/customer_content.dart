import 'package:flutter/material.dart';
import 'dart:ui_web' as ui;
import 'package:web/web.dart' as web;
import 'package:provider/provider.dart';
import '../models/customer_model.dart';
import '../providers/customer_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

class CustomerContent extends StatefulWidget {
  const CustomerContent({super.key});
  @override
  State<CustomerContent> createState() => _CustomerContentState();
}

class _CustomerContentState extends State<CustomerContent> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _rankFilter = 'all';
  bool _showDetail = false;
  CustomerModel? _detailCustomer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CustomerProvider>().loadCustomers());
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  String _fmtDate(DateTime d) => '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  String _fmtDateTime(DateTime d) => '${_fmtDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  String _fmtVND(double v) {
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf}đ';
  }

  List<CustomerModel> _filtered(List<CustomerModel> all) {
    var list = all.toList();
    if (_rankFilter != 'all') {
      list = list.where((c) => c.rank.toLowerCase() == _rankFilter).toList();
    }
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((c) =>
        c.displayName.toLowerCase().contains(q) ||
        c.email.toLowerCase().contains(q) ||
        c.phone.toLowerCase().contains(q) ||
        c.uid.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  Color _rankColor(String rank) {
    switch (rank.toLowerCase()) {
      case 'silver': return const Color(0xFF94A3B8);
      case 'gold': return const Color(0xFFF59E0B);
      case 'platinum': return const Color(0xFF8B5CF6);
      case 'diamond': return const Color(0xFF06B6D4);
      default: return const Color(0xFFCD7F32);
    }
  }

  static final Set<String> _registeredViews = {};

  Widget _avatar(CustomerModel c, double radius, {double fontSize = 13}) {
    final color = c.isBanned ? const Color(0xFFEF4444) : const Color(0xFF7C3AED);
    if (c.photoURL.isNotEmpty) {
      final viewType = 'avatar-${c.uid}-${radius.toInt()}';
      if (!_registeredViews.contains(viewType)) {
        _registeredViews.add(viewType);
        // ignore: undefined_prefixed_name
        ui.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
          final img = web.HTMLImageElement()
            ..src = c.photoURL
            ..style.width = '100%'
            ..style.height = '100%'
            ..style.objectFit = 'cover'
            ..style.borderRadius = '50%';
          return img;
        });
      }
      return Container(
        width: radius * 2, height: radius * 2,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
        child: ClipOval(child: HtmlElementView(viewType: viewType)),
      );
    }
    return _fallbackAvatar(c, radius, fontSize, color);
  }

  Widget _fallbackAvatar(CustomerModel c, double radius, double fontSize, Color color) {
    return Container(
      width: radius * 2, height: radius * 2,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.1)),
      child: Center(child: _avatarText(c, fontSize, color)),
    );
  }

  Widget _avatarText(CustomerModel c, double fontSize, Color color) =>
    Text(c.displayLabel.isNotEmpty ? c.displayLabel[0].toUpperCase() : '?',
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700, color: color));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<CustomerProvider>(builder: (_, prov, __) {
      if (_showDetail && _detailCustomer != null) {
        final fresh = prov.customers.where((c) => c.id == _detailCustomer!.id).toList();
        if (fresh.isNotEmpty) _detailCustomer = fresh.first;
        return _buildDetail(isDark, _detailCustomer!, prov);
      }
      final list = _filtered(prov.customers);
      return Column(children: [
        _buildHeader(isDark, prov),
        Expanded(child: prov.isLoading && prov.customers.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildKpiRow(isDark, prov.customers),
              const SizedBox(height: 20),
              _buildFilterBar(isDark),
              const SizedBox(height: 14),
              _buildTable(isDark, list, prov),
            ]))),
      ]);
    });
  }

  // ═══════════════════════  HEADER  ═══════════════════════
  Widget _buildHeader(bool isDark, CustomerProvider prov) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final bdr = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: bdr))),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Quản lý khách hàng', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: tp)),
          const SizedBox(height: 2),
          Text('${prov.customers.length} khách hàng', style: TextStyle(fontSize: 13, color: ts)),
        ])),
        OutlinedButton.icon(
          onPressed: () => prov.loadCustomers(),
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Làm mới', style: TextStyle(fontSize: 12)),
          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF7C3AED),
            side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ]),
    );
  }

  // ═══════════════════════  KPI  ═══════════════════════
  Widget _buildKpiRow(bool isDark, List<CustomerModel> all) {
    final total = all.length;
    final google = all.where((c) => c.provider == 'google').length;
    final email = all.where((c) => c.provider == 'email').length;
    final banned = all.where((c) => c.isBanned).length;

    final data = [
      ('Tổng khách hàng', '$total', Icons.people_rounded, const Color(0xFF7C3AED)),
      ('Đăng ký Google', '$google', Icons.g_mobiledata_rounded, const Color(0xFF3B82F6)),
      ('Đăng ký Email', '$email', Icons.email_rounded, const Color(0xFF10B981)),
      ('Bị khóa', '$banned', Icons.block_rounded, const Color(0xFFEF4444)),
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

  // ═══════════════════════  FILTER  ═══════════════════════
  Widget _buildFilterBar(bool isDark) {
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);

    return Row(children: [
      SizedBox(width: 320, height: 38, child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(fontSize: 13, color: tp),
        decoration: InputDecoration(
          hintText: 'Tìm tên, email, SĐT khách hàng...',
          hintStyle: TextStyle(fontSize: 12, color: ts),
          prefixIcon: Icon(Icons.search_rounded, size: 18, color: ts),
          filled: true, fillColor: cardBg, contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
        ),
      )),
      const SizedBox(width: 12),
      Container(height: 38, padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(10), border: Border.all(color: bdr)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(
          value: _rankFilter,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: ts),
          style: TextStyle(fontSize: 12, color: tp),
          items: [
            DropdownMenuItem(value: 'all', child: Text('Tất cả rank', style: TextStyle(fontSize: 12, color: tp))),
            ...['bronze', 'silver', 'gold', 'platinum', 'diamond'].map((r) {
              final labels = {'bronze': 'Đồng', 'silver': 'Bạc', 'gold': 'Vàng', 'platinum': 'Bạch Kim', 'diamond': 'Kim Cương'};
              final clr = _rankColor(r);
              return DropdownMenuItem(value: r, child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: clr)),
                const SizedBox(width: 6),
                Text(labels[r]!, style: TextStyle(fontSize: 12, color: tp)),
              ]));
            }),
          ],
          onChanged: (v) => setState(() => _rankFilter = v ?? 'all'),
        ))),
    ]);
  }

  // ═══════════════════════  TABLE  ═══════════════════════
  Widget _buildTable(bool isDark, List<CustomerModel> list, CustomerProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);
    final hs = isDark ? Colors.white38 : Colors.black45;

    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(color: headerBg, borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16))),
          child: Row(children: [
            Expanded(flex: 3, child: Text('KHÁCH HÀNG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 4, child: Text('EMAIL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('RANK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('TRẠNG THÁI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 2, child: Text('NGÀY TẠO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5))),
            Expanded(flex: 1, child: Text('THAO TÁC', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: hs, letterSpacing: 0.5), textAlign: TextAlign.center)),
          ])),
        if (list.isEmpty)
          Padding(padding: const EdgeInsets.all(48), child: Column(children: [
            Icon(Icons.people_outline_rounded, size: 48, color: isDark ? Colors.white12 : const Color(0xFFD1D5DB)),
            const SizedBox(height: 12),
            Text('Không có khách hàng nào', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
          ]))
        else ...list.map((c) => _tableRow(c, isDark, prov)),
      ]),
    );
  }

  Widget _tableRow(CustomerModel c, bool isDark, CustomerProvider prov) {
    final bdr = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final rc = _rankColor(c.rank);

    return Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: bdr))),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          _avatar(c, 15, fontSize: 12),
          const SizedBox(width: 8),
          Flexible(child: Text(c.displayLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tp,
            decoration: c.isBanned ? TextDecoration.lineThrough : null),
            maxLines: 1, overflow: TextOverflow.ellipsis)),
        ])),
        Expanded(flex: 4, child: Text(c.email, style: TextStyle(fontSize: 12, color: ts), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 2, child: Row(children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: rc)),
          const SizedBox(width: 6),
          Text(c.rankLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: rc)),
        ])),
        Expanded(flex: 2, child: Text(c.isBanned ? 'Bị khóa' : 'Hoạt động',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
            color: c.isBanned ? const Color(0xFFEF4444) : const Color(0xFF10B981)))),
        Expanded(flex: 2, child: Text(_fmtDate(c.createdAt), style: TextStyle(fontSize: 12, color: ts))),
        Expanded(flex: 1, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          InkWell(borderRadius: BorderRadius.circular(6),
            onTap: () => setState(() { _showDetail = true; _detailCustomer = c; }),
            child: Padding(padding: const EdgeInsets.all(5),
              child: Icon(Icons.visibility_outlined, size: 17, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)))),
          const SizedBox(width: 2),
          if (!c.isBanned)
            InkWell(borderRadius: BorderRadius.circular(6),
              onTap: () => _showBanDialog(c, prov),
              child: const Padding(padding: EdgeInsets.all(5),
                child: Icon(Icons.block_rounded, size: 17, color: Color(0xFFEF4444))))
          else
            InkWell(borderRadius: BorderRadius.circular(6),
              onTap: () => _showUnbanDialog(c, prov),
              child: const Padding(padding: EdgeInsets.all(5),
                child: Icon(Icons.lock_open_rounded, size: 17, color: Color(0xFF10B981)))),
        ])),
      ]),
    );
  }


  // ═══════════════════════  BAN / UNBAN DIALOGS  ═══════════════════════
  void _showBanDialog(CustomerModel c, CustomerProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final reasonCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 440, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
          child: const Icon(Icons.gpp_bad_rounded, color: Color(0xFFEF4444), size: 36)),
        const SizedBox(height: 20),
        const Text('KHÓA TÀI KHOẢN', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFFEF4444), letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Text('Bạn có chắc chắn muốn khóa tài khoản này?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: tp)),
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: bdr)),
          child: Row(children: [
            _avatar(c, 20, fontSize: 14),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.displayLabel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tp)),
              Text(c.email, style: TextStyle(fontSize: 11, color: ts)),
            ])),
          ])),
        const SizedBox(height: 16),
        Container(width: double.infinity, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFECACA))),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Sau khi khóa, người dùng sẽ không thể đăng nhập. '
              'Khi cố đăng nhập, họ sẽ nhận được cảnh báo tài khoản đã bị khóa do vi phạm chính sách.',
              style: TextStyle(fontSize: 11, color: Color(0xFFDC2626), height: 1.4))),
          ])),
        const SizedBox(height: 16),
        TextField(controller: reasonCtrl, maxLines: 2, style: TextStyle(fontSize: 13, color: tp),
          decoration: InputDecoration(labelText: 'Lý do khóa tài khoản *', labelStyle: TextStyle(fontSize: 12, color: ts),
            hintText: 'Nhập lý do vi phạm...', hintStyle: TextStyle(fontSize: 12, color: ts),
            filled: true, fillColor: cardBg,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
          )),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx),
            style: OutlinedButton.styleFrom(foregroundColor: ts, side: BorderSide(color: bdr),
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Hủy'))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () async {
            if (reasonCtrl.text.trim().isEmpty) { AppSnackBar.error(ctx, 'Vui lòng nhập lý do'); return; }
            Navigator.pop(ctx);
            final ok = await prov.banCustomer(c.id, reasonCtrl.text.trim());
            if (!mounted) return;
            if (ok) { AppSnackBar.success(context, 'Đã khóa tài khoản ${c.displayLabel}'); setState(() { _showDetail = false; _detailCustomer = null; }); }
            else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
          },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Khóa tài khoản'))),
        ]),
      ])),
    ));
  }

  void _showUnbanDialog(CustomerModel c, CustomerProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);

    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: bg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(width: 400, padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.lock_open_rounded, color: Color(0xFF10B981), size: 28)),
        const SizedBox(height: 16),
        Text('Mở khóa tài khoản?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: tp)),
        const SizedBox(height: 8),
        Text('Tài khoản "${c.displayLabel}" sẽ được mở khóa và có thể đăng nhập lại.',
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
            final ok = await prov.unbanCustomer(c.id);
            if (!mounted) return;
            if (ok) AppSnackBar.success(context, 'Đã mở khóa tài khoản ${c.displayLabel}');
            else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
          },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: const Text('Mở khóa'))),
        ]),
      ])),
    ));
  }

  // ═══════════════════════  DETAIL VIEW  ═══════════════════════
  Widget _buildDetail(bool isDark, CustomerModel c, CustomerProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final rc = _rankColor(c.rank);

    return Column(children: [
      // Header bar
      Container(padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: bdr))),
        child: Row(children: [
          InkWell(borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() { _showDetail = false; _detailCustomer = null; }),
            child: Container(padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: bdr)),
              child: Icon(Icons.arrow_back_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF374151)))),
          const SizedBox(width: 16),
          Text('Chi tiết khách hàng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: tp)),
          const Spacer(),
          if (!c.isBanned)
            OutlinedButton.icon(
              onPressed: () => _showBanDialog(c, prov),
              icon: const Icon(Icons.block_rounded, size: 16, color: Color(0xFFEF4444)),
              label: const Text('Khóa tài khoản', style: TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFEF4444)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _showUnbanDialog(c, prov),
              icon: const Icon(Icons.lock_open_rounded, size: 16, color: Color(0xFF10B981)),
              label: const Text('Mở khóa', style: TextStyle(fontSize: 12, color: Color(0xFF10B981))),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF10B981)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            ),
        ])),
      // Body
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Ban warning
          if (c.isBanned) ...[
            Container(width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA))),
              child: Row(children: [
                const Icon(Icons.gpp_bad_rounded, color: Color(0xFFEF4444), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tài khoản đã bị khóa', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                  if (c.banReason.isNotEmpty) Text('Lý do: ${c.banReason}', style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626))),
                ])),
                if (c.bannedAt != null) Text(_fmtDateTime(c.bannedAt!), style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626))),
              ])),
            const SizedBox(height: 16),
          ],
          // Profile summary card
          Container(width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
            child: Row(children: [
              _avatar(c, 36, fontSize: 24),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(c.displayLabel, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: tp))),
                  const SizedBox(width: 10),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(color: rc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: rc)),
                      const SizedBox(width: 5),
                      Text(c.rankLabel, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: rc)),
                    ])),
                  if (c.isBanned) ...[
                    const SizedBox(width: 6),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: const Text('BỊ KHÓA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)))),
                  ],
                ]),
                const SizedBox(height: 4),
                Text(c.email, style: TextStyle(fontSize: 13, color: ts)),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(c.provider == 'google' ? Icons.g_mobiledata_rounded : Icons.email_rounded,
                    size: 16, color: c.provider == 'google' ? const Color(0xFF3B82F6) : const Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(c.providerLabel, style: TextStyle(fontSize: 11, color: ts)),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today_rounded, size: 12, color: ts),
                  const SizedBox(width: 4),
                  Text('Tham gia ${_fmtDate(c.createdAt)}', style: TextStyle(fontSize: 11, color: ts)),
                ]),
              ])),
            ])),
          const SizedBox(height: 16),
          // 3-column cards — EQUAL HEIGHT
          IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            // Col 1: personal info
            Expanded(child: _card(isDark, 'Thông tin cá nhân', Icons.person_rounded, [
              _infoRow('Tên', c.displayName.isNotEmpty ? c.displayName : '—', tp, ts),
              _infoRow('Email', c.email, tp, ts),
              if (c.phone.isNotEmpty) _infoRow('SĐT', c.phone, tp, ts),
              if (c.genderLabel.isNotEmpty) _infoRow('Giới tính', c.genderLabel, tp, ts),
              if (c.dateOfBirth != null) _infoRow('Ngày sinh', _fmtDate(c.dateOfBirth!), tp, ts),
              if (c.location.isNotEmpty) _infoRow('Vị trí', c.location, tp, ts),
              if (c.address.isNotEmpty) _infoRow('Địa chỉ', c.address, tp, ts),
            ])),
            const SizedBox(width: 16),
            // Col 2: rank — no icon, just colored dot + text
            Expanded(child: Container(padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: rc)),
                  const SizedBox(width: 8),
                  Text('Hạng thành viên', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tp)),
                ]),
                const SizedBox(height: 14),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: rc.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(c.rankLabel.toUpperCase(), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: rc, letterSpacing: 0.8))),
                const SizedBox(height: 14),
                _infoRow('Chi tiêu', _fmtVND(c.totalSpent), tp, ts),
                _infoRow('Ưu đãi', c.rankDiscount > 0 ? 'Giảm ${c.rankDiscount}%' : '—', tp, ts),
                _infoRow('Tiếp theo', c.nextRankInfo, tp, ts),
                const SizedBox(height: 10),
                Divider(color: bdr),
                const SizedBox(height: 6),
                ...['bronze', 'silver', 'gold', 'platinum', 'diamond'].map((r) {
                  final labels = {'bronze': 'Đồng', 'silver': 'Bạc', 'gold': 'Vàng', 'platinum': 'Bạch Kim', 'diamond': 'Kim Cương'};
                  final thresholds = {'bronze': '0đ', 'silver': '2tr', 'gold': '5tr', 'platinum': '15tr', 'diamond': '30tr'};
                  final discounts = {'bronze': 0, 'silver': 3, 'gold': 5, 'platinum': 8, 'diamond': 12};
                  final active = c.rank.toLowerCase() == r;
                  final clr = _rankColor(r);
                  return Padding(padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? clr : Colors.grey.shade300)),
                      const SizedBox(width: 8),
                      SizedBox(width: 65, child: Text(labels[r]!, style: TextStyle(fontSize: 11,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? clr : ts))),
                      Expanded(child: Text('từ ${thresholds[r]!}', style: TextStyle(fontSize: 11, color: ts))),
                      Text(discounts[r]! > 0 ? '-${discounts[r]}%' : '—', style: TextStyle(fontSize: 11,
                        fontWeight: FontWeight.w500, color: active ? clr : ts)),
                    ]));
                }),
              ]))),
            const SizedBox(width: 16),
            // Col 3: account info
            Expanded(child: _card(isDark, 'Tài khoản', Icons.settings_rounded, [
              _infoRow('UID', c.uid.length > 12 ? '${c.uid.substring(0, 12)}...' : c.uid, tp, ts),
              _infoRow('Provider', c.providerLabel, tp, ts),
              _infoRow('Vai trò', c.role.toUpperCase(), tp, ts),
              _infoRow('Trạng thái', c.isBanned ? 'Bị khóa' : 'Hoạt động', tp, ts, valueColor: c.isBanned ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
              _infoRow('Ngày tạo', _fmtDateTime(c.createdAt), tp, ts),
              _infoRow('Cập nhật', _fmtDateTime(c.updatedAt), tp, ts),
            ])),
          ])),
        ]),
      )),
    ]);
  }

  Widget _card(bool isDark, String title, IconData icon, List<Widget> children) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    return Container(width: double.infinity, padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16), border: Border.all(color: bdr)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 18, color: const Color(0xFF7C3AED)), const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: tp))]),
        const SizedBox(height: 12), ...children,
      ]));
  }

  Widget _infoRow(String label, String value, Color tp, Color ts, {Color? valueColor}) =>
    Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 11, color: ts))),
      Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: valueColor ?? tp), overflow: TextOverflow.ellipsis)),
    ]));
}
