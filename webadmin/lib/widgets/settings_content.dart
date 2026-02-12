import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';

/// Trang Cài đặt — form cấu hình thực, đọc/ghi Firestore document `settings/general`.
class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  bool get isDarkMode => mounted ? Theme.of(context).brightness == Brightness.dark : false;
  final _fs = FirebaseFirestore.instance;
  bool _isLoading = true;
  int _expandedSection = -1; // which section is open, -1 = none

  // ── Store info
  final _storeNameCtrl = TextEditingController();
  final _storeAddressCtrl = TextEditingController();
  final _storePhoneCtrl = TextEditingController();
  final _storeEmailCtrl = TextEditingController();

  // ── Payment toggles
  bool _codEnabled = true;
  bool _momoEnabled = false;
  bool _vnpayEnabled = false;
  bool _zalopayEnabled = false;
  bool _vietqrEnabled = false;

  // ── Shipping
  final _defaultShipFeeCtrl = TextEditingController(text: '30000');
  final _freeShipMinCtrl = TextEditingController(text: '500000');

  // ── Notifications
  bool _notiNewOrder = true;
  bool _notiPromotion = false;
  bool _notiEmail = true;
  bool _notiSms = false;
  bool _notiPush = true;

  // ── Appearance
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
        // store
        _storeNameCtrl.text = d['storeName'] ?? '';
        _storeAddressCtrl.text = d['storeAddress'] ?? '';
        _storePhoneCtrl.text = d['storePhone'] ?? '';
        _storeEmailCtrl.text = d['storeEmail'] ?? '';
        // payment
        _codEnabled = d['codEnabled'] ?? true;
        _momoEnabled = d['momoEnabled'] ?? false;
        _vnpayEnabled = d['vnpayEnabled'] ?? false;
        _zalopayEnabled = d['zalopayEnabled'] ?? false;
        _vietqrEnabled = d['vietqrEnabled'] ?? false;
        // shipping
        _defaultShipFeeCtrl.text = (d['defaultShipFee'] ?? 30000).toString();
        _freeShipMinCtrl.text = (d['freeShipMin'] ?? 500000).toString();
        // notifications
        _notiNewOrder = d['notiNewOrder'] ?? true;
        _notiPromotion = d['notiPromotion'] ?? false;
        _notiEmail = d['notiEmail'] ?? true;
        _notiSms = d['notiSms'] ?? false;
        _notiPush = d['notiPush'] ?? true;
        // appearance
        _language = d['language'] ?? 'vi';
        _timezone = d['timezone'] ?? 'Asia/Ho_Chi_Minh';
        _currency = d['currency'] ?? 'VND';
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveSection(String sectionName, Map<String, dynamic> data) async {
    try {
      await _fs.collection('settings').doc('general').set(data, SetOptions(merge: true));
      if (mounted) AppSnackBar.success(context, 'Đã lưu cài đặt $sectionName');
    } catch (e) {
      if (mounted) AppSnackBar.error(context, 'Lỗi: $e');
    }
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
          _buildSection(
            index: 0,
            icon: Icons.store_rounded,
            color: const Color(0xFF7C3AED),
            title: 'Thông tin cửa hàng',
            subtitle: 'Tên, địa chỉ, liên hệ',
            body: _storeInfoForm(),
          ),
          const SizedBox(height: 12),
          _buildSection(
            index: 1,
            icon: Icons.payment_rounded,
            color: const Color(0xFF10B981),
            title: 'Thanh toán',
            subtitle: 'Phương thức thanh toán',
            body: _paymentForm(),
          ),
          const SizedBox(height: 12),
          _buildSection(
            index: 2,
            icon: Icons.local_shipping_rounded,
            color: const Color(0xFF3B82F6),
            title: 'Vận chuyển',
            subtitle: 'Phí ship, miễn phí ship',
            body: _shippingForm(),
          ),
          const SizedBox(height: 12),
          _buildSection(
            index: 3,
            icon: Icons.notifications_rounded,
            color: const Color(0xFFF59E0B),
            title: 'Thông báo',
            subtitle: 'Email, SMS, Push',
            body: _notificationForm(),
          ),
          const SizedBox(height: 12),
          _buildSection(
            index: 4,
            icon: Icons.security_rounded,
            color: const Color(0xFFEF4444),
            title: 'Bảo mật',
            subtitle: 'Đổi mật khẩu',
            body: _securityForm(),
          ),
          const SizedBox(height: 12),
          _buildSection(
            index: 5,
            icon: Icons.palette_rounded,
            color: const Color(0xFFEC4899),
            title: 'Giao diện',
            subtitle: 'Ngôn ngữ, múi giờ, tiền tệ',
            body: _appearanceForm(),
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
              Text('Cài đặt hệ thống',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.white : AppTheme.textDark)),
              SizedBox(height: 4),
              Text('Cấu hình và tùy chỉnh hệ thống quản lý',
                  style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white54 : AppTheme.textLight)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _loadSettings,
          icon: Icon(Icons.refresh_rounded, size: 18),
          label: Text('Tải lại'),
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
  // SECTION CARD (expandable)
  // ═══════════════════════════════════════════════
  Widget _buildSection({
    required int index,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required Widget body,
  }) {
    final isOpen = _expandedSection == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isOpen ? color.withValues(alpha: 0.4) : const Color(0xFFE5E7EB)),
        boxShadow: isOpen
            ? [BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        children: [
          // header — always visible
          InkWell(
            onTap: () => setState(() => _expandedSection = isOpen ? -1 : index),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : const Color(0xFF111827))),
                        SizedBox(height: 2),
                        Text(subtitle, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: Icon(Icons.expand_more_rounded, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ),
          ),
          // body — collapsible
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              children: [
                Divider(height: 1, color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFF3F4F6)),
                Padding(padding: const EdgeInsets.all(20), child: body),
              ],
            ),
            crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SECTION 1: STORE INFO
  // ═══════════════════════════════════════════════
  Widget _storeInfoForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _field('Tên cửa hàng', _storeNameCtrl, 'StyleZone')),
            const SizedBox(width: 16),
            Expanded(child: _field('Email liên hệ', _storeEmailCtrl, 'contact@stylezone.vn')),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _field('Địa chỉ', _storeAddressCtrl, '123 Nguyễn Huệ, Q.1, TP.HCM')),
            const SizedBox(width: 16),
            Expanded(child: _field('Số điện thoại', _storePhoneCtrl, '0901 234 567')),
          ],
        ),
        const SizedBox(height: 16),
        _saveButton(() => _saveSection('cửa hàng', {
          'storeName': _storeNameCtrl.text.trim(),
          'storeAddress': _storeAddressCtrl.text.trim(),
          'storePhone': _storePhoneCtrl.text.trim(),
          'storeEmail': _storeEmailCtrl.text.trim(),
        })),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // SECTION 2: PAYMENT
  // ═══════════════════════════════════════════════
  Widget _paymentForm() {
    return Column(
      children: [
        _toggle('COD (Thanh toán khi nhận hàng)', _codEnabled, (v) => setState(() => _codEnabled = v)),
        _toggle('Ví MoMo', _momoEnabled, (v) => setState(() => _momoEnabled = v)),
        _toggle('VNPay', _vnpayEnabled, (v) => setState(() => _vnpayEnabled = v)),
        _toggle('ZaloPay', _zalopayEnabled, (v) => setState(() => _zalopayEnabled = v)),
        _toggle('VietQR (Chuyển khoản)', _vietqrEnabled, (v) => setState(() => _vietqrEnabled = v)),
        const SizedBox(height: 16),
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

  // ═══════════════════════════════════════════════
  // SECTION 3: SHIPPING
  // ═══════════════════════════════════════════════
  Widget _shippingForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _field('Phí ship mặc định (VNĐ)', _defaultShipFeeCtrl, '30000')),
            const SizedBox(width: 16),
            Expanded(child: _field('Miễn phí ship từ (VNĐ)', _freeShipMinCtrl, '500000')),
          ],
        ),
        const SizedBox(height: 16),
        _saveButton(() => _saveSection('vận chuyển', {
          'defaultShipFee': int.tryParse(_defaultShipFeeCtrl.text.trim()) ?? 30000,
          'freeShipMin': int.tryParse(_freeShipMinCtrl.text.trim()) ?? 500000,
        })),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // SECTION 4: NOTIFICATIONS
  // ═══════════════════════════════════════════════
  Widget _notificationForm() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Loại thông báo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : const Color(0xFF374151))),
        ),
        const SizedBox(height: 8),
        _toggle('Đơn hàng mới', _notiNewOrder, (v) => setState(() => _notiNewOrder = v)),
        _toggle('Khuyến mãi', _notiPromotion, (v) => setState(() => _notiPromotion = v)),
        SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Kênh gửi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : const Color(0xFF374151))),
        ),
        const SizedBox(height: 8),
        _toggle('Email', _notiEmail, (v) => setState(() => _notiEmail = v)),
        _toggle('SMS', _notiSms, (v) => setState(() => _notiSms = v)),
        _toggle('Push Notification', _notiPush, (v) => setState(() => _notiPush = v)),
        const SizedBox(height: 16),
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

  // ═══════════════════════════════════════════════
  // SECTION 5: SECURITY
  // ═══════════════════════════════════════════════
  Widget _securityForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Đổi mật khẩu tài khoản admin đang đăng nhập.',
            style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280))),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          onPressed: _showChangePasswordDialog,
          icon: Icon(Icons.lock_reset_rounded, size: 18),
          label: Text('Đổi mật khẩu'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Đổi mật khẩu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField('Mật khẩu hiện tại', curCtrl, obscure: true),
              const SizedBox(height: 12),
              _dialogField('Mật khẩu mới', newCtrl, obscure: true),
              const SizedBox(height: 12),
              _dialogField('Xác nhận mật khẩu mới', cfmCtrl, obscure: true),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              if (newCtrl.text.trim().length < 6) {
                AppSnackBar.error(context, 'Mật khẩu mới phải ≥ 6 ký tự');
                return;
              }
              if (newCtrl.text != cfmCtrl.text) {
                AppSnackBar.error(context, 'Xác nhận mật khẩu không khớp');
                return;
              }
              try {
                final user = FirebaseAuth.instance.currentUser;
                if (user == null || user.email == null) throw 'Chưa đăng nhập';
                final cred = EmailAuthProvider.credential(email: user.email!, password: curCtrl.text);
                await user.reauthenticateWithCredential(cred);
                await user.updatePassword(newCtrl.text);
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) AppSnackBar.success(context, 'Đã đổi mật khẩu thành công');
              } catch (e) {
                if (mounted) AppSnackBar.error(context, 'Lỗi: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // SECTION 6: APPEARANCE
  // ═══════════════════════════════════════════════
  Widget _appearanceForm() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _dropdown('Ngôn ngữ', _language, {
              'vi': 'Tiếng Việt',
              'en': 'English',
            }, (v) => setState(() => _language = v!))),
            const SizedBox(width: 16),
            Expanded(child: _dropdown('Múi giờ', _timezone, {
              'Asia/Ho_Chi_Minh': 'Việt Nam (UTC+7)',
              'Asia/Bangkok': 'Bangkok (UTC+7)',
              'Asia/Tokyo': 'Tokyo (UTC+9)',
            }, (v) => setState(() => _timezone = v!))),
            const SizedBox(width: 16),
            Expanded(child: _dropdown('Tiền tệ', _currency, {
              'VND': 'VNĐ (₫)',
              'USD': 'USD (\$)',
            }, (v) => setState(() => _currency = v!))),
          ],
        ),
        const SizedBox(height: 16),
        _saveButton(() => _saveSection('giao diện', {
          'language': _language,
          'timezone': _timezone,
          'currency': _currency,
        })),
      ],
    );
  }

  // ═══════════════════════════════════════════════
  // SHARED FORM WIDGETS
  // ═══════════════════════════════════════════════
  Widget _field(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : const Color(0xFF374151))),
        SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : const Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white38 : const Color(0xFF9CA3AF)),
            filled: true,
            fillColor: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _dialogField(String label, TextEditingController ctrl, {bool obscure = false}) {
    return TextField(
      controller: ctrl, obscureText: obscure,
      style: TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : const Color(0xFF6B7280)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : const Color(0xFF374151)))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String label, String value, Map<String, String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white70 : const Color(0xFF374151))),
        SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : const Color(0xFF111827)),
            items: items.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _saveButton(VoidCallback onPressed) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(Icons.save_rounded, size: 18),
        label: Text('Lưu cài đặt'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
      ),
    );
  }
}
