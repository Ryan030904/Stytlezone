import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

/// Trang Cài đặt — pill-tabs giống Quản lý kho, đọc/ghi Firestore `settings/general`.
class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool get isDark => mounted ? Theme.of(context).brightness == Brightness.dark : false;
  final _fs = FirebaseFirestore.instance;
  bool _isLoading = true;
  int _activeTab = 0;

  // ── Tab definitions ──
  static const _tabs = [
    _TabDef(Icons.store_rounded, 'Cửa hàng'),
    _TabDef(Icons.payment_rounded, 'Thanh toán'),
    _TabDef(Icons.local_shipping_rounded, 'Vận chuyển'),
    _TabDef(Icons.notifications_rounded, 'Thông báo'),
    _TabDef(Icons.security_rounded, 'Bảo mật'),
    _TabDef(Icons.palette_rounded, 'Giao diện'),
  ];

  // ── Store info ──
  final _storeNameCtrl = TextEditingController();
  final _storeAddressCtrl = TextEditingController();
  final _storePhoneCtrl = TextEditingController();
  final _storeEmailCtrl = TextEditingController();

  // ── Payment toggles ──
  bool _codEnabled = true;
  bool _momoEnabled = false;
  bool _vnpayEnabled = false;
  bool _zalopayEnabled = false;
  bool _vietqrEnabled = false;

  // ── Shipping ──
  final _defaultShipFeeCtrl = TextEditingController(text: '30000');
  final _freeShipMinCtrl = TextEditingController(text: '500000');

  // ── Notifications ──
  bool _notiNewOrder = true;
  bool _notiPromotion = false;
  bool _notiEmail = true;
  bool _notiSms = false;
  bool _notiPush = true;

  // ── Appearance ──
  String _language = 'vi';
  String _timezone = 'Asia/Ho_Chi_Minh';
  String _currency = 'VND';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _storeAddressCtrl.dispose();
    _storePhoneCtrl.dispose();
    _storeEmailCtrl.dispose();
    _defaultShipFeeCtrl.dispose();
    _freeShipMinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final doc = await _fs.collection('settings').doc('general').get();
      if (doc.exists) {
        final d = doc.data()!;
        _storeNameCtrl.text = d['storeName'] ?? '';
        _storeAddressCtrl.text = d['storeAddress'] ?? '';
        _storePhoneCtrl.text = d['storePhone'] ?? '';
        _storeEmailCtrl.text = d['storeEmail'] ?? '';
        _codEnabled = d['codEnabled'] ?? true;
        _momoEnabled = d['momoEnabled'] ?? false;
        _vnpayEnabled = d['vnpayEnabled'] ?? false;
        _zalopayEnabled = d['zalopayEnabled'] ?? false;
        _vietqrEnabled = d['vietqrEnabled'] ?? false;
        _defaultShipFeeCtrl.text = (d['defaultShipFee'] ?? 30000).toString();
        _freeShipMinCtrl.text = (d['freeShipMin'] ?? 500000).toString();
        _notiNewOrder = d['notiNewOrder'] ?? true;
        _notiPromotion = d['notiPromotion'] ?? false;
        _notiEmail = d['notiEmail'] ?? true;
        _notiSms = d['notiSms'] ?? false;
        _notiPush = d['notiPush'] ?? true;
        _language = d['language'] ?? 'vi';
        _timezone = d['timezone'] ?? 'Asia/Ho_Chi_Minh';
        _currency = d['currency'] ?? 'VND';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSection(String name, Map<String, dynamic> data) async {
    try {
      await _fs.collection('settings').doc('general').set(data, SetOptions(merge: true));
      if (mounted) AppSnackBar.success(context, 'Đã lưu $name');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Lỗi: $e');
    }
  }

  // ═══════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(80),
              child: CircularProgressIndicator(color: Color(0xFF7C3AED))));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildContentCard(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cài đặt hệ thống',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppTheme.textDark)),
        const SizedBox(height: 4),
        Text('Cấu hình và tùy chỉnh hệ thống quản lý',
            style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : AppTheme.textLight)),
      ],
    );
  }

  // ═══════════════════════════════════════
  // CONTENT CARD (tabs + body)
  // ═══════════════════════════════════════
  Widget _buildContentCard() {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : const Color(0xFFE5E7EB);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tab header ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF0F0F0))),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tabs.asMap().entries.map((e) {
                return _pillTab(e.key, e.value.icon, e.value.label);
              }).toList(),
            ),
          ),
          // ── Tab body ──
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildTabBody(),
          ),
        ],
      ),
    );
  }

  Widget _pillTab(int index, IconData icon, String label) {
    final isActive = _activeTab == index;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFF7C3AED).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.35)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE5E7EB)),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon,
                size: 15,
                color: isActive
                    ? const Color(0xFF7C3AED)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : const Color(0xFF9CA3AF))),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? const Color(0xFF7C3AED)
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : const Color(0xFF6B7280)),
                )),
          ]),
        ),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_activeTab) {
      case 0:
        return _storeInfoTab();
      case 1:
        return _paymentTab();
      case 2:
        return _shippingTab();
      case 3:
        return _notificationTab();
      case 4:
        return _securityTab();
      case 5:
        return _appearanceTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════
  // TAB 0: STORE INFO
  // ═══════════════════════════════════════
  Widget _storeInfoTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Thông tin cửa hàng', 'Cập nhật tên, địa chỉ và thông tin liên hệ'),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _field('Tên cửa hàng', _storeNameCtrl, 'StyleZone')),
          const SizedBox(width: 16),
          Expanded(child: _field('Email liên hệ', _storeEmailCtrl, 'contact@stylezone.vn')),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _field('Địa chỉ', _storeAddressCtrl, '123 Nguyễn Huệ, Q.1, TP.HCM')),
          const SizedBox(width: 16),
          Expanded(child: _field('Số điện thoại', _storePhoneCtrl, '0901 234 567')),
        ]),
        const SizedBox(height: 24),
        _saveButton(() => _saveSection('thông tin cửa hàng', {
              'storeName': _storeNameCtrl.text.trim(),
              'storeAddress': _storeAddressCtrl.text.trim(),
              'storePhone': _storePhoneCtrl.text.trim(),
              'storeEmail': _storeEmailCtrl.text.trim(),
            })),
      ],
    );
  }

  // ═══════════════════════════════════════
  // TAB 1: PAYMENT
  // ═══════════════════════════════════════
  Widget _paymentTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Phương thức thanh toán', 'Bật/tắt các cổng thanh toán'),
        const SizedBox(height: 20),
        _paymentToggle('COD (Thanh toán khi nhận hàng)', 'Khách hàng trả tiền khi nhận hàng',
            Icons.money_rounded, const Color(0xFF10B981), _codEnabled, (v) => setState(() => _codEnabled = v)),
        _paymentToggle('Ví MoMo', 'Thanh toán qua ví điện tử MoMo',
            Icons.account_balance_wallet_rounded, const Color(0xFFEC4899), _momoEnabled, (v) => setState(() => _momoEnabled = v)),
        _paymentToggle('VNPay', 'Cổng thanh toán VNPay',
            Icons.credit_card_rounded, const Color(0xFF3B82F6), _vnpayEnabled, (v) => setState(() => _vnpayEnabled = v)),
        _paymentToggle('ZaloPay', 'Thanh toán qua ZaloPay',
            Icons.phone_android_rounded, const Color(0xFF0EA5E9), _zalopayEnabled, (v) => setState(() => _zalopayEnabled = v)),
        _paymentToggle('VietQR (Chuyển khoản)', 'Quét mã QR chuyển khoản ngân hàng',
            Icons.qr_code_rounded, const Color(0xFF7C3AED), _vietqrEnabled, (v) => setState(() => _vietqrEnabled = v)),
        const SizedBox(height: 24),
        _saveButton(() => _saveSection('thanh toán', {
              'codEnabled': _codEnabled,
              'momoEnabled': _momoEnabled,
              'vnpayEnabled': _vnpayEnabled,
              'zalopayEnabled': _zalopayEnabled,
              'vietqrEnabled': _vietqrEnabled,
            })),
      ],
    );
  }

  Widget _paymentToggle(String title, String subtitle, IconData icon, Color color, bool value, ValueChanged<bool> onChanged) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? color.withValues(alpha: 0.3) : bdr),
      ),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF111827))),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white54 : const Color(0xFF9CA3AF))),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // TAB 2: SHIPPING
  // ═══════════════════════════════════════
  Widget _shippingTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cài đặt vận chuyển', 'Phí ship mặc định và điều kiện miễn phí ship'),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
            child: _infoCard(
                Icons.local_shipping_rounded,
                const Color(0xFF3B82F6),
                'Phí ship mặc định',
                _defaultShipFeeCtrl,
                'VNĐ'),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _infoCard(
                Icons.card_giftcard_rounded,
                const Color(0xFF10B981),
                'Miễn phí ship từ',
                _freeShipMinCtrl,
                'VNĐ'),
          ),
        ]),
        const SizedBox(height: 24),
        _saveButton(() => _saveSection('vận chuyển', {
              'defaultShipFee': int.tryParse(_defaultShipFeeCtrl.text.trim()) ?? 30000,
              'freeShipMin': int.tryParse(_freeShipMinCtrl.text.trim()) ?? 500000,
            })),
      ],
    );
  }

  Widget _infoCard(IconData icon, Color color, String label, TextEditingController ctrl, String suffix) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827))),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: bdr)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: bdr)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: color, width: 1.5)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // TAB 3: NOTIFICATIONS
  // ═══════════════════════════════════════
  Widget _notificationTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Cài đặt thông báo', 'Chọn loại thông báo và kênh gửi'),
        const SizedBox(height: 20),
        _subHeader('Loại thông báo'),
        const SizedBox(height: 10),
        _notiCard(Icons.shopping_bag_rounded, const Color(0xFF7C3AED),
            'Đơn hàng mới', 'Nhận thông báo khi có đơn hàng mới',
            _notiNewOrder, (v) => setState(() => _notiNewOrder = v)),
        _notiCard(Icons.local_offer_rounded, const Color(0xFFF59E0B),
            'Khuyến mãi', 'Nhận thông báo về chương trình khuyến mãi',
            _notiPromotion, (v) => setState(() => _notiPromotion = v)),
        const SizedBox(height: 16),
        _subHeader('Kênh gửi'),
        const SizedBox(height: 10),
        _notiCard(Icons.email_rounded, const Color(0xFF3B82F6),
            'Email', 'Gửi thông báo qua email',
            _notiEmail, (v) => setState(() => _notiEmail = v)),
        _notiCard(Icons.sms_rounded, const Color(0xFF10B981),
            'SMS', 'Gửi thông báo qua tin nhắn SMS',
            _notiSms, (v) => setState(() => _notiSms = v)),
        _notiCard(Icons.notifications_active_rounded, const Color(0xFFEC4899),
            'Push Notification', 'Gửi thông báo đẩy trên app',
            _notiPush, (v) => setState(() => _notiPush = v)),
        const SizedBox(height: 24),
        _saveButton(() => _saveSection('thông báo', {
              'notiNewOrder': _notiNewOrder,
              'notiPromotion': _notiPromotion,
              'notiEmail': _notiEmail,
              'notiSms': _notiSms,
              'notiPush': _notiPush,
            })),
      ],
    );
  }

  Widget _notiCard(IconData icon, Color color, String title, String sub, bool value, ValueChanged<bool> onChanged) {
    final bg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB);
    final bdr = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: value ? color.withValues(alpha: 0.3) : bdr),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF111827))),
            Text(sub,
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
          ]),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: color,
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // TAB 4: SECURITY
  // ═══════════════════════════════════════
  Widget _securityTab() {
    final user = FirebaseAuth.instance.currentUser;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Bảo mật tài khoản', 'Quản lý mật khẩu và bảo mật'),
        const SizedBox(height: 20),
        // Current account info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : const Color(0xFFE5E7EB)),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor:
                  const Color(0xFF7C3AED).withValues(alpha: 0.12),
              child: Icon(Icons.person_rounded,
                  size: 24, color: const Color(0xFF7C3AED)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tài khoản hiện tại',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF6B7280))),
                    const SizedBox(height: 2),
                    Text(user?.email ?? 'Chưa đăng nhập',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF111827))),
                  ]),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Đang hoạt động',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF10B981))),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _showChangePasswordDialog,
          icon: const Icon(Icons.lock_reset_rounded, size: 18),
          label: const Text('Đổi mật khẩu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  void _showChangePasswordDialog() {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final cfmCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Đổi mật khẩu',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 380,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _dialogField('Mật khẩu hiện tại', curCtrl, obscure: true),
            const SizedBox(height: 12),
            _dialogField('Mật khẩu mới', newCtrl, obscure: true),
            const SizedBox(height: 12),
            _dialogField('Xác nhận mật khẩu mới', cfmCtrl, obscure: true),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text.trim().length < 6) {
                AppSnackBar.error(context, 'Mật khẩu mới phải ≥ 6 ký tự');
                return;
              }
              if (newCtrl.text != cfmCtrl.text) {
                AppSnackBar.error(
                    context, 'Xác nhận mật khẩu không khớp');
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) {
                  throw 'Chưa đăng nhập';
                }
                final cred = EmailAuthProvider.credential(
                    email: user.email!, password: curCtrl.text);
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  AppSnackBar.success(
                      context, 'Đã đổi mật khẩu thành công');
                }
              } catch (e) {
                if (mounted) AppSnackBar.error(context, 'Lỗi: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // TAB 5: APPEARANCE
  // ═══════════════════════════════════════
  Widget _appearanceTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Giao diện & Khu vực', 'Ngôn ngữ, múi giờ và tiền tệ hiển thị'),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: _dropdown('Ngôn ngữ', _language, {
            'vi': 'Tiếng Việt',
            'en': 'English',
          }, (v) => setState(() => _language = v!))),
          const SizedBox(width: 16),
          Expanded(
              child: _dropdown('Múi giờ', _timezone, {
            'Asia/Ho_Chi_Minh': 'Việt Nam (UTC+7)',
            'Asia/Bangkok': 'Bangkok (UTC+7)',
            'Asia/Tokyo': 'Tokyo (UTC+9)',
          }, (v) => setState(() => _timezone = v!))),
          const SizedBox(width: 16),
          Expanded(
              child: _dropdown('Tiền tệ', _currency, {
            'VND': 'VNĐ (₫)',
            'USD': 'USD (\$)',
          }, (v) => setState(() => _currency = v!))),
        ]),
        const SizedBox(height: 24),
        _saveButton(() => _saveSection('giao diện', {
              'language': _language,
              'timezone': _timezone,
              'currency': _currency,
            })),
      ],
    );
  }

  // ═══════════════════════════════════════
  // SHARED WIDGETS
  // ═══════════════════════════════════════
  Widget _sectionTitle(String title, String subtitle) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827))),
      const SizedBox(height: 2),
      Text(subtitle,
          style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : const Color(0xFF6B7280))),
    ]);
  }

  Widget _subHeader(String text) {
    return Text(text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : const Color(0xFF374151)));
  }

  Widget _field(String label, TextEditingController ctrl, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF374151))),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE5E7EB))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE5E7EB))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  Widget _dialogField(String label, TextEditingController ctrl,
      {bool obscure = false}) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> items,
      ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF374151))),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB)),
        ),
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF111827)),
          dropdownColor:
              isDark ? const Color(0xFF1E293B) : Colors.white,
          items: items.entries
              .map((e) =>
                  DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    ]);
  }

  Widget _saveButton(VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_rounded, size: 18),
        label: const Text('Lưu cài đặt'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef(this.icon, this.label);
}
