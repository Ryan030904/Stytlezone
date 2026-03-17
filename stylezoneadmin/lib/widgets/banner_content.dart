import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
import '../models/banner_model.dart';
import '../providers/banner_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_snackbar.dart';
import 'cloudinary_image_picker.dart';

/// ──────────────────────────────────────────────
/// BANNER MANAGEMENT — Image-only, visual layout
/// ──────────────────────────────────────────────
class BannerContent extends StatefulWidget {
  const BannerContent({super.key});
  @override
  State<BannerContent> createState() => _BannerContentState();
}

class _BannerContentState extends State<BannerContent> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final prov = context.read<BannerProvider>();
      if (prov.banners.isEmpty) prov.loadBanners();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<BannerProvider>(builder: (_, prov, __) {
      final heroBanners = prov.banners.where((b) => b.position == 'hero').toList();
      final promoBanners = prov.banners.where((b) => b.position == 'promo').toList();

      return Column(children: [
        _buildHeader(isDark, prov),
        Expanded(
          child: prov.isLoading && prov.banners.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _buildSection(isDark, 'Hero Banner', 'hero', heroBanners, prov),
                    const SizedBox(height: 32),
                    _buildSection(isDark, 'Khuyến Mãi Banner', 'promo', promoBanners, prov),
                  ]),
                ),
        ),
      ]);
    });
  }

  // ═══════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════
  Widget _buildHeader(bool isDark, BannerProvider prov) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final tp = isDark ? Colors.white : const Color(0xFF111827);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: border))),
      child: Row(children: [
        const Icon(Icons.image_rounded, size: 20, color: Color(0xFF7C3AED)),
        const SizedBox(width: 10),
        Text('Quản lý Banner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tp)),
        const Spacer(),
        SizedBox(
          height: 36,
          child: OutlinedButton.icon(
            onPressed: () => prov.loadBanners(),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Làm mới', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF7C3AED),
              side: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE5E7EB)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════
  // SECTION
  // ═══════════════════════════════════════════════
  Widget _buildSection(bool isDark, String title, String position, List<BannerModel> banners, BannerProvider prov) {
    final tp = isDark ? Colors.white : const Color(0xFF111827);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF7C3AED), borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: tp)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text('${banners.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED))),
        ),
        const Spacer(),
        SizedBox(
          height: 32,
          child: TextButton.icon(
            onPressed: () => _showAddDialog(isDark, position, prov),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Thêm ảnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF7C3AED), padding: const EdgeInsets.symmetric(horizontal: 12)),
          ),
        ),
      ]),
      const SizedBox(height: 16),
      if (banners.isEmpty)
        _buildEmptyState(isDark, position, prov)
      else
        Wrap(spacing: 16, runSpacing: 16, children: banners.map((b) => _buildBannerCard(isDark, b, prov)).toList()),
    ]);
  }

  Widget _buildEmptyState(bool isDark, String position, BannerProvider prov) {
    final ts = isDark ? Colors.white38 : const Color(0xFF9CA3AF);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bdr),
      ),
      child: Column(children: [
        Icon(Icons.add_photo_alternate_rounded, size: 40, color: ts),
        const SizedBox(height: 12),
        Text('Chưa có banner nào', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: ts)),
        const SizedBox(height: 16),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: () => _showAddDialog(isDark, position, prov),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Thêm ảnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
              elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════
  // BANNER CARD — Image-focused
  // ═══════════════════════════════════════════════
  Widget _buildBannerCard(bool isDark, BannerModel b, BannerProvider prov) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final cardW = _cardWidth();

    return Container(
      width: cardW,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: b.isLive ? const Color(0xFF10B981).withValues(alpha: 0.3) : bdr),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // ── Image area (clickable) ──
        _buildImageArea(isDark, b, prov),
        // ── Action bar ──
        _buildActionBar(isDark, b, prov),
      ]),
    );
  }

  double _cardWidth() {
    final screenW = MediaQuery.of(context).size.width;
    final available = screenW - 260 - 48 - 16;
    if (available > 900) return (available - 32) / 3;
    if (available > 500) return (available - 16) / 2;
    return available;
  }

  // ── Image area ──
  Widget _buildImageArea(bool isDark, BannerModel b, BannerProvider prov) {
    return Stack(children: [
      Container(
        height: 200,
        width: double.infinity,
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6),
        child: b.imageUrl.isNotEmpty
            ? _webImage(b.imageUrl, b.id)
            : Center(child: Icon(Icons.image_outlined, size: 48, color: isDark ? Colors.white24 : const Color(0xFFD1D5DB))),
      ),
      // Click overlay
      Positioned.fill(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showChangeImageDialog(isDark, b, prov),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                  SizedBox(width: 4),
                  Text('Đổi ảnh', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white)),
                ]),
              ),
            ),
          ),
        ),
      ),
      // Live badge
      if (b.isLive)
        Positioned(
          top: 8, left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(6)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.circle, size: 6, color: Colors.white),
              SizedBox(width: 4),
              Text('Live', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
            ]),
          ),
        ),
    ]);
  }

  // ── Simple action bar below image ──
  Widget _buildActionBar(bool isDark, BannerModel b, BannerProvider prov) {
    final ts = isDark ? Colors.white54 : const Color(0xFF6B7280);
    final isActive = b.status == BannerStatus.active;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(children: [
        // Position label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            b.position == 'hero' ? 'Hero' : 'Promo',
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)),
          ),
        ),
        const SizedBox(width: 6),
        // Sort order
        Text('#${b.sortOrder}', style: TextStyle(fontSize: 10, color: ts)),
        const Spacer(),
        // Toggle active
        _miniBtn(
          icon: isActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
          color: isActive ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          onTap: () => _toggleStatus(b, prov),
        ),
        const SizedBox(width: 4),
        // Delete
        _miniBtn(
          icon: Icons.delete_outline_rounded,
          color: const Color(0xFFEF4444),
          onTap: () => _confirmDelete(b, prov),
        ),
      ]),
    );
  }

  static final Set<String> _registeredViewTypes = {};

  Widget _webImage(String url, String id) {
    final viewType = 'banner-img-$id-${url.hashCode}';
    if (!_registeredViewTypes.contains(viewType)) {
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final img = web.HTMLImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';
        return img;
      });
      _registeredViewTypes.add(viewType);
    }
    return HtmlElementView(key: ValueKey(viewType), viewType: viewType);
  }

  Widget _miniBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // TOGGLE STATUS
  // ═══════════════════════════════════════════════
  Future<void> _toggleStatus(BannerModel b, BannerProvider prov) async {
    final newStatus = b.status == BannerStatus.active ? BannerStatus.archived : BannerStatus.active;
    final updated = b.copyWith(status: newStatus, updatedAt: DateTime.now());
    final ok = await prov.updateBanner(updated);
    if (!mounted) return;
    if (ok) AppSnackBar.success(context, newStatus == BannerStatus.active ? 'Đã kích hoạt' : 'Đã ẩn banner');
    else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
  }

  // ═══════════════════════════════════════════════
  // CHANGE IMAGE DIALOG
  // ═══════════════════════════════════════════════
  void _showChangeImageDialog(bool isDark, BannerModel b, BannerProvider prov) {
    final imageCtrl = TextEditingController(text: b.imageUrl);
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.camera_alt_rounded, size: 20, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 12),
              Text('Đổi ảnh banner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tp)),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
              ),
            ]),
            const SizedBox(height: 20),
            CloudinaryImagePicker(controller: imageCtrl, isDarkMode: isDark, label: 'Chọn ảnh mới'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton(
                onPressed: () async {
                  if (imageCtrl.text.isEmpty) return;
                  Navigator.pop(ctx);
                  final updated = b.copyWith(imageUrl: imageCtrl.text, updatedAt: DateTime.now());
                  final ok = await prov.updateBanner(updated);
                  if (!mounted) return;
                  if (ok) AppSnackBar.success(context, 'Đã đổi ảnh');
                  else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Lưu ảnh mới', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // ADD BANNER — Just upload image
  // ═══════════════════════════════════════════════
  void _showAddDialog(bool isDark, String position, BannerProvider prov) {
    final imageCtrl = TextEditingController();
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.add_photo_alternate_rounded, size: 20, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Thêm banner', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tp)),
                Text(
                  'Vị trí: ${position == 'hero' ? 'Hero' : 'Khuyến mãi'}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : const Color(0xFF6B7280)),
                ),
              ]),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Icon(Icons.close_rounded, size: 20, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
              ),
            ]),
            const SizedBox(height: 20),
            CloudinaryImagePicker(controller: imageCtrl, isDarkMode: isDark, label: 'Chọn ảnh banner'),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 44,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (imageCtrl.text.trim().isEmpty) {
                    AppSnackBar.error(ctx, 'Vui lòng chọn ảnh');
                    return;
                  }
                  Navigator.pop(ctx);
                  final now = DateTime.now();
                  final banner = BannerModel(
                    id: '',
                    title: position == 'hero' ? 'Hero Banner' : 'Promo Banner',
                    imageUrl: imageCtrl.text.trim(),
                    position: position,
                    status: BannerStatus.active,
                    sortOrder: 0,
                    startDate: now,
                    endDate: DateTime(2030, 12, 31),
                    createdAt: now,
                    updatedAt: now,
                  );
                  final ok = await prov.createBanner(banner);
                  if (!mounted) return;
                  if (ok) AppSnackBar.success(context, 'Đã thêm banner');
                  else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
                },
                icon: const Icon(Icons.check_rounded, size: 16),
                label: const Text('Thêm banner', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED), foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DELETE CONFIRM
  // ═══════════════════════════════════════════════
  void _confirmDelete(BannerModel b, BannerProvider prov) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final tp = isDark ? Colors.white : const Color(0xFF111827);
    final ts = isDark ? Colors.white60 : const Color(0xFF6B7280);
    final bdr = isDark ? Colors.white10 : const Color(0xFFE5E7EB);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 16),
            Text('Xoá banner này?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tp)),
            const SizedBox(height: 8),
            Text('Banner sẽ bị xoá khỏi website.', style: TextStyle(fontSize: 13, color: ts)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  foregroundColor: ts, side: BorderSide(color: bdr),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Hủy'),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final ok = await prov.deleteBanner(b.id);
                  if (!mounted) return;
                  if (ok) AppSnackBar.success(context, 'Đã xoá banner');
                  else AppSnackBar.error(context, prov.errorMessage ?? 'Lỗi');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Xoá'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}
