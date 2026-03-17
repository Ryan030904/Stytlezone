import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/settings_model.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

/// Settings tab — store configuration management.
class SettingsContent extends StatefulWidget {
  const SettingsContent({super.key});

  @override
  State<SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<SettingsContent> {
  // ── Store Information ──
  late TextEditingController _storeNameCtrl;
  late TextEditingController _sloganCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _logoUrlCtrl;

  // ── Payment ──
  late TextEditingController _bankAccountCtrl;
  late TextEditingController _bankAccountNameCtrl;

  // ── Shipping ──
  late TextEditingController _shippingFeeCtrl;
  late TextEditingController _freeShipCtrl;
  late TextEditingController _deliveryTimeCtrl;

  // ── Social ──
  late TextEditingController _fbCtrl;
  late TextEditingController _igCtrl;
  late TextEditingController _tiktokCtrl;

  // ── Rank thresholds ──
  late TextEditingController _rankSilverCtrl;
  late TextEditingController _rankGoldCtrl;
  late TextEditingController _rankPlatinumCtrl;
  late TextEditingController _rankDiamondCtrl;
  late TextEditingController _rankBronzeDiscountCtrl;
  late TextEditingController _rankSilverDiscountCtrl;
  late TextEditingController _rankGoldDiscountCtrl;
  late TextEditingController _rankPlatinumDiscountCtrl;
  late TextEditingController _rankDiamondDiscountCtrl;

  String _selectedBankId = 'VCB';
  bool _codEnabled = true;
  bool _bankTransferEnabled = true;
  bool _momoEnabled = true;

  bool _initialized = false;

  static const List<Map<String, String>> _bankOptions = [
    {'id': 'VCB', 'name': 'Vietcombank (VCB)'},
    {'id': 'MB', 'name': 'MB Bank'},
    {'id': 'ACB', 'name': 'ACB'},
    {'id': 'TCB', 'name': 'Techcombank (TCB)'},
    {'id': 'BIDV', 'name': 'BIDV'},
    {'id': 'VTB', 'name': 'VietinBank (VTB)'},
    {'id': 'TPB', 'name': 'TPBank'},
    {'id': 'VPB', 'name': 'VPBank'},
    {'id': 'STB', 'name': 'Sacombank (STB)'},
    {'id': 'MSB', 'name': 'MSB'},
  ];

  @override
  void initState() {
    super.initState();
    _storeNameCtrl = TextEditingController();
    _sloganCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _logoUrlCtrl = TextEditingController();
    _bankAccountCtrl = TextEditingController();
    _bankAccountNameCtrl = TextEditingController();
    _shippingFeeCtrl = TextEditingController();
    _freeShipCtrl = TextEditingController();
    _deliveryTimeCtrl = TextEditingController();
    _fbCtrl = TextEditingController();
    _igCtrl = TextEditingController();
    _tiktokCtrl = TextEditingController();
    _rankSilverCtrl = TextEditingController();
    _rankGoldCtrl = TextEditingController();
    _rankPlatinumCtrl = TextEditingController();
    _rankDiamondCtrl = TextEditingController();
    _rankBronzeDiscountCtrl = TextEditingController();
    _rankSilverDiscountCtrl = TextEditingController();
    _rankGoldDiscountCtrl = TextEditingController();
    _rankPlatinumDiscountCtrl = TextEditingController();
    _rankDiamondDiscountCtrl = TextEditingController();

    // Fetch on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().fetchSettings();
    });
  }

  @override
  void dispose() {
    _storeNameCtrl.dispose();
    _sloganCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _logoUrlCtrl.dispose();
    _bankAccountCtrl.dispose();
    _bankAccountNameCtrl.dispose();
    _shippingFeeCtrl.dispose();
    _freeShipCtrl.dispose();
    _deliveryTimeCtrl.dispose();
    _fbCtrl.dispose();
    _igCtrl.dispose();
    _tiktokCtrl.dispose();
    _rankSilverCtrl.dispose();
    _rankGoldCtrl.dispose();
    _rankPlatinumCtrl.dispose();
    _rankDiamondCtrl.dispose();
    _rankBronzeDiscountCtrl.dispose();
    _rankSilverDiscountCtrl.dispose();
    _rankGoldDiscountCtrl.dispose();
    _rankPlatinumDiscountCtrl.dispose();
    _rankDiamondDiscountCtrl.dispose();
    super.dispose();
  }

  /// Populate text controllers from settings (once after fetch).
  void _populateControllers(StoreSettings s) {
    _storeNameCtrl.text = s.storeName;
    _sloganCtrl.text = s.slogan;
    _emailCtrl.text = s.contactEmail;
    _phoneCtrl.text = s.contactPhone;
    _addressCtrl.text = s.storeAddress;
    _logoUrlCtrl.text = s.logoUrl;
    _bankAccountCtrl.text = s.bankAccount;
    _bankAccountNameCtrl.text = s.bankAccountName;
    _shippingFeeCtrl.text = s.defaultShippingFee.toStringAsFixed(0);
    _freeShipCtrl.text = s.freeShippingThreshold.toStringAsFixed(0);
    _deliveryTimeCtrl.text = s.estimatedDeliveryTime;
    _fbCtrl.text = s.facebookUrl;
    _igCtrl.text = s.instagramUrl;
    _tiktokCtrl.text = s.tiktokUrl;
    _rankSilverCtrl.text = s.rankSilverThreshold.toStringAsFixed(0);
    _rankGoldCtrl.text = s.rankGoldThreshold.toStringAsFixed(0);
    _rankPlatinumCtrl.text = s.rankPlatinumThreshold.toStringAsFixed(0);
    _rankDiamondCtrl.text = s.rankDiamondThreshold.toStringAsFixed(0);
    _rankBronzeDiscountCtrl.text = s.rankBronzeDiscount.toString();
    _rankSilverDiscountCtrl.text = s.rankSilverDiscount.toString();
    _rankGoldDiscountCtrl.text = s.rankGoldDiscount.toString();
    _rankPlatinumDiscountCtrl.text = s.rankPlatinumDiscount.toString();
    _rankDiamondDiscountCtrl.text = s.rankDiamondDiscount.toString();
    _selectedBankId = s.bankId;
    _codEnabled = s.codEnabled;
    _bankTransferEnabled = s.bankTransferEnabled;
    _momoEnabled = s.momoEnabled;
  }

  /// Build updated StoreSettings from current controller values.
  StoreSettings _buildSettingsFromForm(StoreSettings current) {
    return current.copyWith(
      storeName: _storeNameCtrl.text.trim(),
      slogan: _sloganCtrl.text.trim(),
      contactEmail: _emailCtrl.text.trim(),
      contactPhone: _phoneCtrl.text.trim(),
      storeAddress: _addressCtrl.text.trim(),
      logoUrl: _logoUrlCtrl.text.trim(),
      bankId: _selectedBankId,
      bankAccount: _bankAccountCtrl.text.trim(),
      bankAccountName: _bankAccountNameCtrl.text.trim(),
      codEnabled: _codEnabled,
      bankTransferEnabled: _bankTransferEnabled,
      momoEnabled: _momoEnabled,
      defaultShippingFee: double.tryParse(_shippingFeeCtrl.text) ?? 0,
      freeShippingThreshold: double.tryParse(_freeShipCtrl.text) ?? 500000,
      estimatedDeliveryTime: _deliveryTimeCtrl.text.trim(),
      facebookUrl: _fbCtrl.text.trim(),
      instagramUrl: _igCtrl.text.trim(),
      tiktokUrl: _tiktokCtrl.text.trim(),
      rankSilverThreshold: double.tryParse(_rankSilverCtrl.text) ?? 2000000,
      rankGoldThreshold: double.tryParse(_rankGoldCtrl.text) ?? 5000000,
      rankPlatinumThreshold: double.tryParse(_rankPlatinumCtrl.text) ?? 15000000,
      rankDiamondThreshold: double.tryParse(_rankDiamondCtrl.text) ?? 30000000,
      rankBronzeDiscount: int.tryParse(_rankBronzeDiscountCtrl.text) ?? 0,
      rankSilverDiscount: int.tryParse(_rankSilverDiscountCtrl.text) ?? 3,
      rankGoldDiscount: int.tryParse(_rankGoldDiscountCtrl.text) ?? 5,
      rankPlatinumDiscount: int.tryParse(_rankPlatinumDiscountCtrl.text) ?? 8,
      rankDiamondDiscount: int.tryParse(_rankDiamondDiscountCtrl.text) ?? 12,
    );
  }

  void _onFieldChanged() {
    final provider = context.read<SettingsProvider>();
    final updated = _buildSettingsFromForm(provider.settings);
    provider.updateSettings(updated);
  }

  Future<void> _handleSave() async {
    final provider = context.read<SettingsProvider>();
    final updated = _buildSettingsFromForm(provider.settings);
    provider.updateSettings(updated);
    final success = await provider.saveSettings();

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Đã lưu cài đặt thành công!'),
            ],
          ),
          backgroundColor: const Color(0xFF22C55E),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(provider.error ?? 'Lưu cài đặt thất bại'),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  int _activeTab = 0;

  static const List<_SettingsTab> _tabs = [
    _SettingsTab(Icons.storefront_rounded, 'Cửa hàng', Color(0xFF7C3AED)),
    _SettingsTab(Icons.account_balance_wallet_rounded, 'Thanh toán', Color(0xFF3B82F6)),
    _SettingsTab(Icons.local_shipping_rounded, 'Vận chuyển', Color(0xFF22C55E)),
    _SettingsTab(Icons.share_rounded, 'Mạng xã hội', Color(0xFFEC4899)),
    _SettingsTab(Icons.military_tech_rounded, 'Hạng thành viên', Color(0xFFF59E0B)),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Populate controllers once after data is loaded
    if (!_initialized && !provider.isLoading) {
      _populateControllers(provider.settings);
      _initialized = true;
    }

    if (provider.isLoading && !_initialized) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32, height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 12),
            Text('Đang tải cài đặt...', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
          ],
        ),
      );
    }

    return Container(
      color: isDark ? AppTheme.darkBg : AppTheme.lightBg,
      child: Column(
        children: [
          // ── Header bar with save button ──
          _buildHeader(provider, isDark),
          // ── Tab bar ──
          _buildTabBar(isDark),
          // ── Tab content ──
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildActiveTabContent(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDark) {
    switch (_activeTab) {
      case 0: return _buildStoreInfoCard(isDark);
      case 1: return _buildPaymentCard(isDark);
      case 2: return _buildShippingCard(isDark);
      case 3: return _buildSocialCard(isDark);
      case 4: return _buildRankCard(isDark);
      default: return _buildStoreInfoCard(isDark);
    }
  }

  // ─── TAB BAR ───
  Widget _buildTabBar(bool isDark) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : AppTheme.borderColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: List.generate(_tabs.length, (i) {
          final tab = _tabs[i];
          final isActive = _activeTab == i;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => setState(() => _activeTab = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive
                      ? tab.color.withValues(alpha: isDark ? 0.18 : 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive
                        ? tab.color.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(tab.icon, size: 15,
                        color: isActive ? tab.color : (isDark ? Colors.white38 : AppTheme.textLight)),
                    const SizedBox(width: 6),
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? tab.color : (isDark ? Colors.white54 : AppTheme.textLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ─── HEADER ───
  Widget _buildHeader(SettingsProvider provider, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCardBg : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title area
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cấu hình hệ thống',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quản lý thông tin cửa hàng, thanh toán, vận chuyển và liên kết mạng xã hội',
                  style: TextStyle(fontSize: 11, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          // Unsaved indicator
          if (provider.hasUnsavedChanges)
            Container(
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, size: 13, color: Color(0xFFF59E0B)),
                  SizedBox(width: 4),
                  Text('Chưa lưu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFF59E0B))),
                ],
              ),
            ),
          // Save button
          SizedBox(
            height: 34,
            child: ElevatedButton.icon(
              onPressed: provider.isSaving ? null : _handleSave,
              icon: provider.isSaving
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_rounded, size: 15),
              label: Text(provider.isSaving ? 'Đang lưu...' : 'Lưu cài đặt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SECTION CARD WRAPPER ───
  Widget _sectionCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderColor;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: border)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 10.5, color: AppTheme.textLight)),
              ],
            ),
          ),
          // Card body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ─── STORE INFORMATION CARD ───
  Widget _buildStoreInfoCard(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Thông tin cửa hàng',
      subtitle: 'Tên, slogan, thông tin liên hệ',
      children: [
        _buildTextField('Tên cửa hàng', _storeNameCtrl),
        const SizedBox(height: 12),
        _buildTextField('Slogan', _sloganCtrl),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildTextField('Email liên hệ', _emailCtrl)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Số điện thoại', _phoneCtrl)),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField('Địa chỉ cửa hàng', _addressCtrl),
        const SizedBox(height: 12),
        _buildTextField('URL Logo', _logoUrlCtrl),
        // Logo preview
        if (_logoUrlCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            height: 48,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    _logoUrlCtrl.text,
                    height: 32, width: 32,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 20, color: Color(0xFFEF4444)),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Xem trước logo', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ─── PAYMENT CARD ───
  Widget _buildPaymentCard(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Cấu hình thanh toán',
      subtitle: 'Ngân hàng, phương thức thanh toán',
      children: [
        _buildLabel('Ngân hàng (VietQR)'),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppTheme.borderColor),
            color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedBankId,
              isExpanded: true,
              style: const TextStyle(fontSize: 12.5, color: AppTheme.textDark),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: AppTheme.textLight),
              items: _bankOptions.map((b) => DropdownMenuItem(
                value: b['id'],
                child: Text(b['name']!, style: const TextStyle(fontSize: 12.5)),
              )).toList(),
              onChanged: (val) {
                if (val == null) return;
                setState(() => _selectedBankId = val);
                _onFieldChanged();
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildTextField('Số tài khoản', _bankAccountCtrl),
        const SizedBox(height: 12),
        _buildTextField('Tên chủ tài khoản', _bankAccountNameCtrl),
        const SizedBox(height: 16),
        _buildLabel('Phương thức thanh toán'),
        const SizedBox(height: 8),
        _buildToggleRow('COD (Thanh toán khi nhận hàng)', _codEnabled, (v) {
          setState(() => _codEnabled = v);
          _onFieldChanged();
        }),
        const SizedBox(height: 6),
        _buildToggleRow('Chuyển khoản ngân hàng', _bankTransferEnabled, (v) {
          setState(() => _bankTransferEnabled = v);
          _onFieldChanged();
        }),
        const SizedBox(height: 6),
        _buildToggleRow('Ví MoMo', _momoEnabled, (v) {
          setState(() => _momoEnabled = v);
          _onFieldChanged();
        }),
      ],
    );
  }

  // ─── SHIPPING CARD ───
  Widget _buildShippingCard(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Cấu hình vận chuyển',
      subtitle: 'Phí ship, ngưỡng miễn phí, thời gian giao hàng',
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                'Phí vận chuyển (đ)',
                _shippingFeeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                'Miễn phí ship từ (đ)',
                _freeShipCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField('Thời gian giao hàng dự kiến', _deliveryTimeCtrl),
      ],
    );
  }

  // ─── SOCIAL MEDIA CARD ───
  Widget _buildSocialCard(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Mạng xã hội',
      subtitle: 'Liên kết tới các kênh social media',
      children: [
        _buildTextField('Facebook URL', _fbCtrl),
        const SizedBox(height: 12),
        _buildTextField('Instagram URL', _igCtrl),
        const SizedBox(height: 12),
        _buildTextField('TikTok URL', _tiktokCtrl),
      ],
    );
  }

  // ─── RANK MANAGEMENT CARD ───
  Widget _buildRankCard(bool isDark) {
    return Column(
      children: [
        _sectionCard(
          isDark: isDark,
          title: 'Mức chi tiêu thăng hạng',
          subtitle: 'Tổng chi tiêu tối thiểu (VNĐ) để đạt mỗi hạng',
          children: [
            _buildRankRow('Đồng (Bronze)', null, null, const Color(0xFFCD7F32), isDark, isBase: true),
            const SizedBox(height: 10),
            _buildRankRow('Bạc (Silver)', _rankSilverCtrl, 'Ví dụ: 2000000', const Color(0xFFA0AEC0), isDark),
            const SizedBox(height: 10),
            _buildRankRow('Vàng (Gold)', _rankGoldCtrl, 'Ví dụ: 5000000', const Color(0xFFF59E0B), isDark),
            const SizedBox(height: 10),
            _buildRankRow('Bạch Kim (Platinum)', _rankPlatinumCtrl, 'Ví dụ: 15000000', const Color(0xFF60A5FA), isDark),
            const SizedBox(height: 10),
            _buildRankRow('Kim Cương (Diamond)', _rankDiamondCtrl, 'Ví dụ: 30000000', const Color(0xFFA78BFA), isDark),
          ],
        ),
        const SizedBox(height: 16),
        _sectionCard(
          isDark: isDark,
          title: 'Phần trăm giảm giá theo hạng',
          subtitle: 'Ưu đãi giảm giá (%) cho mỗi hạng thành viên',
          children: [
            _buildDiscountRow('Đồng', _rankBronzeDiscountCtrl, const Color(0xFFCD7F32), isDark),
            const SizedBox(height: 10),
            _buildDiscountRow('Bạc', _rankSilverDiscountCtrl, const Color(0xFFA0AEC0), isDark),
            const SizedBox(height: 10),
            _buildDiscountRow('Vàng', _rankGoldDiscountCtrl, const Color(0xFFF59E0B), isDark),
            const SizedBox(height: 10),
            _buildDiscountRow('Bạch Kim', _rankPlatinumDiscountCtrl, const Color(0xFF60A5FA), isDark),
            const SizedBox(height: 10),
            _buildDiscountRow('Kim Cương', _rankDiamondDiscountCtrl, const Color(0xFFA78BFA), isDark),
          ],
        ),
      ],
    );
  }

  Widget _buildRankRow(String label, TextEditingController? ctrl, String? hint, Color color, bool isDark, {bool isBase = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isBase
                ? Text('0đ (Hạng mặc định)', style: TextStyle(fontSize: 12, color: AppTheme.textLight, fontStyle: FontStyle.italic))
                : SizedBox(
                    height: 34,
                    child: TextField(
                      controller: ctrl,
                      onChanged: (_) => _onFieldChanged(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : AppTheme.textDark),
                      decoration: InputDecoration(
                        hintText: hint,
                        hintStyle: TextStyle(fontSize: 12, color: AppTheme.textLight.withValues(alpha: 0.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        suffixText: 'đ',
                        suffixStyle: TextStyle(fontSize: 12, color: AppTheme.textLight),
                        filled: true,
                        fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 1.5)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscountRow(String label, TextEditingController ctrl, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: isDark ? 0.08 : 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textDark)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            height: 34,
            child: TextField(
              controller: ctrl,
              onChanged: (_) => _onFieldChanged(),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppTheme.textDark),
              decoration: InputDecoration(
                suffixText: '%',
                suffixStyle: TextStyle(fontSize: 12, color: AppTheme.textLight),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: AppTheme.borderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: color, width: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHARED WIDGETS ───

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textLight),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 4),
        SizedBox(
          height: 38,
          child: TextField(
            controller: controller,
            onChanged: (_) => _onFieldChanged(),
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 12.5, color: AppTheme.textDark),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: AppTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: value
            ? const Color(0xFF7C3AED).withValues(alpha: 0.04)
            : const Color(0xFFF9FAFB),
        border: Border.all(
          color: value
              ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: value ? AppTheme.textDark : AppTheme.textLight,
              ),
            ),
          ),
          SizedBox(
            height: 24,
            width: 40,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF7C3AED),
                activeTrackColor: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for settings tab definition.
class _SettingsTab {
  final IconData icon;
  final String label;
  final Color color;
  const _SettingsTab(this.icon, this.label, this.color);
}
