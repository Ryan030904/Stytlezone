import 'dart:typed_data';
import 'package:flutter/material.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../services/cloudinary_service.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../models/category_model.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../providers/brand_provider.dart';
import '../models/brand_model.dart';
import '../theme/app_theme.dart';
import '../screens/dashboard_screen.dart';
import '../widgets/admin_slide_panel.dart';
import '../widgets/cloudinary_image_picker.dart';

/// ──────────────────────────────────────────────
/// PRODUCT MANAGEMENT
/// ──────────────────────────────────────────────
class ProductContent extends StatefulWidget {
  const ProductContent({super.key});

  @override
  State<ProductContent> createState() => _ProductContentState();
}

class _ProductContentState extends State<ProductContent> {
  // ─── Panel ───
  bool _panelOpen = false;
  Product? _editing;

  // ─── Filters ───
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterParentCat = '';   // parent category id
  String _filterChildCat = '';    // child category id (actual filter)
  String _filterGender = '';      // all | male | female

  // ─── Form controllers ───
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _materialCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '0');
  final _noteCtrl = TextEditingController();
  final _colorInputCtrl = TextEditingController();
  final List<String> _selectedColors = [];
  // Image per color: key = color name, value = TextEditingController
  final Map<String, TextEditingController> _colorImageCtrls = {};
  String _formCategoryId = '';
  String _formCategoryName = '';
  String _formBrandId = '';
  String _formBrandName = '';
  int _sizeTab = 0; // 0 = clothes, 1 = shoes
  final Set<String> _selectedSizes = {};
  String _formGender = 'male';
  bool _formIsActive = true;
  // Variant data: key = 'size|color', value = {price, stock}
  final Map<String, Map<String, dynamic>> _variantData = {};
  String _activeImageColor = ''; // which color's image is being shown

  void _closePanelOnTabSwitch() {
    if (_panelOpen) setState(() => _panelOpen = false);
  }

  @override
  void initState() {
    super.initState();
    DashboardScreen.panelCloseNotifier.addListener(_closePanelOnTabSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prodProv = context.read<ProductProvider>();
      final catProv = context.read<CategoryProvider>();
      final brandProv = context.read<BrandProvider>();
      if (prodProv.products.isEmpty) prodProv.loadProducts();
      if (catProv.categories.isEmpty) catProv.loadCategories();
      if (brandProv.brands.isEmpty) brandProv.loadBrands();
    });
  }

  @override
  void dispose() {
    DashboardScreen.panelCloseNotifier.removeListener(_closePanelOnTabSwitch);
    _searchCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _imageCtrl.dispose();
    _skuCtrl.dispose();
    _materialCtrl.dispose();
    _stockCtrl.dispose();
    _noteCtrl.dispose();
    _colorInputCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers: category tree ───
  List<Category> _parentCats(List<Category> all) =>
      all.where((c) => c.parentId == null || c.parentId!.isEmpty).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Category> _childCats(List<Category> all, String parentId) =>
      all.where((c) => c.parentId == parentId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Only child categories are selectable for products
  List<Category> _selectableChildCats(List<Category> all) =>
      all.where((c) => c.parentId != null && c.parentId!.isNotEmpty).toList();

  // ─── Open panel: CREATE ───
  void _openCreate() {
    _editing = null;
    _nameCtrl.clear();
    _descCtrl.clear();
    _priceCtrl.clear();
    _salePriceCtrl.clear();
    _imageCtrl.clear();
    _skuCtrl.clear();
    _materialCtrl.clear();
    _stockCtrl.text = '0';
    _noteCtrl.clear();
    _colorInputCtrl.clear();
    _selectedColors.clear();
    _formCategoryId = '';
    _formCategoryName = '';
    _formBrandId = '';
    _formBrandName = '';
    _formGender = 'male';
    _formIsActive = true;
    _sizeTab = 0;
    _selectedSizes.clear();
    _variantData.clear();
    _colorImageCtrls.forEach((_, c) => c.dispose());
    _colorImageCtrls.clear();
    _activeImageColor = '';
    setState(() => _panelOpen = true);
  }

  // ─── Open panel: EDIT ───
  void _openEdit(Product p) {
    _editing = p;
    _nameCtrl.text = p.name;
    _descCtrl.text = p.description;
    _priceCtrl.text = p.price > 0 ? p.price.toStringAsFixed(0) : '';
    _salePriceCtrl.text = p.salePrice > 0 ? p.salePrice.toStringAsFixed(0) : '';
    _imageCtrl.text = p.imageUrl ?? '';
    _skuCtrl.text = p.sku;
    _materialCtrl.text = p.material;
    _stockCtrl.text = p.stock.toString();
    _noteCtrl.text = p.note;
    _colorInputCtrl.clear();
    _selectedColors
      ..clear()
      ..addAll(p.colors);
    _formCategoryId = p.categoryId;
    _formCategoryName = p.categoryName;
    _formBrandId = p.brandId;
    _formBrandName = p.brandName;
    _selectedSizes
      ..clear()
      ..addAll(p.sizes);
    // Detect tab: if any size is numeric → shoes tab
    _sizeTab = p.sizes.any((s) => int.tryParse(s) != null) ? 1 : 0;
    _formGender = p.gender;
    _formIsActive = p.isActive;
    // Populate variant data from existing variants
    _variantData.clear();
    for (final v in p.variants) {
      final key = '${v.size}|${v.color}';
      _variantData[key] = {'price': v.price, 'stock': v.stock};
    }
    // Populate color image controllers from product images
    _colorImageCtrls.forEach((_, c) => c.dispose());
    _colorImageCtrls.clear();
    for (int i = 0; i < p.colors.length; i++) {
      _colorImageCtrls[p.colors[i]] = TextEditingController(
        text: i < p.images.length ? p.images[i] : '',
      );
    }
    setState(() => _panelOpen = true);
  }

  void _closePanel() => setState(() => _panelOpen = false);

  // ─── SAVE ───
  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    final prov = context.read<ProductProvider>();
    final now = DateTime.now();
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final salePrice = double.tryParse(_salePriceCtrl.text) ?? 0;
    final stock = int.tryParse(_stockCtrl.text) ?? 0;
    final sizes = _selectedSizes.toList();
    final colors = _selectedColors.toList();
    // Collect images from color image controllers
    final images = <String>[];
    for (final color in colors) {
      final ctrl = _colorImageCtrls[color];
      if (ctrl != null && ctrl.text.trim().isNotEmpty) {
        images.add(ctrl.text.trim());
      }
    }
    // Fallback to single image if no color images
    if (images.isEmpty && _imageCtrl.text.trim().isNotEmpty) {
      images.add(_imageCtrl.text.trim());
    }

    // Build variants from the table
    final variants = <ProductVariant>[];
    for (final size in sizes) {
      for (final color in colors) {
        final key = '$size|$color';
        final data = _variantData[key];
        variants.add(ProductVariant(
          size: size,
          color: color,
          price: (data?['price'] as double?) ?? price,
          stock: (data?['stock'] as int?) ?? 0,
        ));
      }
    }
    // Auto-calc total stock from variants if has variants
    final totalStock = variants.isNotEmpty
        ? variants.fold<int>(0, (sum, v) => sum + v.stock)
        : stock;

    if (_editing != null) {
      final oldCatId = _editing!.categoryId;
      final updated = _editing!.copyWith(
        name: name,
        description: _descCtrl.text.trim(),
        price: price,
        salePrice: salePrice,
        categoryId: _formCategoryId,
        categoryName: _formCategoryName,
        brandId: _formBrandId,
        brandName: _formBrandName,
        gender: _formGender,
        images: images,
        sizes: sizes,
        colors: colors,
        stock: totalStock,
        isActive: _formIsActive,
        sku: _skuCtrl.text.trim(),
        material: _materialCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        variants: variants,
        updatedAt: now,
      );
      final ok = await prov.updateProduct(updated, oldCategoryId: oldCatId != _formCategoryId ? oldCatId : null);
      if (ok && mounted) _closePanel();
    } else {
      final newP = Product(
        id: '',
        name: name,
        description: _descCtrl.text.trim(),
        price: price,
        salePrice: salePrice,
        categoryId: _formCategoryId,
        categoryName: _formCategoryName,
        brandId: _formBrandId,
        brandName: _formBrandName,
        gender: _formGender,
        images: images,
        sizes: sizes,
        colors: colors,
        stock: totalStock,
        isActive: _formIsActive,
        sku: _skuCtrl.text.trim(),
        material: _materialCtrl.text.trim(),
        note: _noteCtrl.text.trim(),
        variants: variants,
        createdAt: now,
        updatedAt: now,
      );
      final ok = await prov.createProduct(newP);
      if (ok && mounted) _closePanel();
    }
  }

  // ─── DELETE ───
  Future<void> _delete(Product p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác nhận xóa', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Text('Bạn có chắc muốn xóa sản phẩm "${p.name}"?', style: const TextStyle(fontSize: 14)),
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
      final ok = await context.read<ProductProvider>().deleteProduct(p.id, p.categoryId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(ok ? 'Đã xóa sản phẩm "${p.name}"' : 'Xóa thất bại, vui lòng thử lại'),
          backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        ));
      }
    }
  }

  // ─── Filter products ───
  List<Product> _applyFilters(List<Product> all) {
    var result = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.categoryName.toLowerCase().contains(q)).toList();
    }
    if (_filterChildCat.isNotEmpty) {
      result = result.where((p) => p.categoryId == _filterChildCat).toList();
    } else if (_filterParentCat.isNotEmpty) {
      // filter by parent: include products in any child of this parent
      final cats = context.read<CategoryProvider>().categories;
      final childIds = _childCats(cats, _filterParentCat).map((c) => c.id).toSet();
      result = result.where((p) => childIds.contains(p.categoryId)).toList();
    }
    if (_filterGender.isNotEmpty) {
      result = result.where((p) => p.gender == _filterGender).toList();
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer3<ProductProvider, CategoryProvider, BrandProvider>(
      builder: (context, prodProv, catProv, brandProv, _) {
        final allCats = catProv.categories;
        final allBrands = brandProv.brands.where((b) => b.isActive).toList();
        final filtered = _applyFilters(prodProv.products);

        return AdminSlidePanel(
          isOpen: _panelOpen,
          panelWidth: 480,
          title: _editing != null ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới',
          onClose: _closePanel,
          panelBody: _buildPanelForm(isDark, allCats, allBrands),
          panelFooter: _buildPanelFooter(isDark, prodProv.isLoading),
          child: Column(
            children: [
              _buildHeaderBar(isDark, prodProv, allCats),
              Expanded(
                child: prodProv.isLoading && prodProv.products.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
                    : filtered.isEmpty
                        ? _buildEmptyState(isDark)
                        : _buildProductGrid(isDark, filtered),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // HEADER BAR — Search + Filters + Add Button (1 row)
  // ═══════════════════════════════════════════════
  Widget _buildHeaderBar(bool isDark, ProductProvider prov, List<Category> allCats) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final parents = _parentCats(allCats);
    final children = _filterParentCat.isEmpty ? <Category>[] : _childCats(allCats, _filterParentCat);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(color: bg, border: Border(bottom: BorderSide(color: border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Left: Search + Filters (2 rows)
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SizedBox(
            height: 36,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppTheme.textDark),
              decoration: InputDecoration(
                hintText: 'Tìm sản phẩm...',
                hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
              ),
            ),
          )),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              SizedBox(width: 180, child: _filterDropdown(
                isDark: isDark,
                value: _filterParentCat.isEmpty ? null : _filterParentCat,
                hint: 'Danh mục chính',
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tất cả danh mục', style: TextStyle(fontSize: 12))),
                  ...parents.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() {
                  _filterParentCat = v ?? '';
                  _filterChildCat = '';
                }),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 170, child: _filterDropdown(
                isDark: isDark,
                value: _filterChildCat.isEmpty ? null : _filterChildCat,
                hint: 'Danh mục con',
                items: [
                  const DropdownMenuItem(value: '', child: Text('Tất cả', style: TextStyle(fontSize: 12))),
                  ...children.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                ],
                onChanged: _filterParentCat.isEmpty ? null : (v) => setState(() => _filterChildCat = v ?? ''),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 140, child: _filterDropdown(
                isDark: isDark,
                value: _filterGender.isEmpty ? null : _filterGender,
                hint: 'Giới tính',
                items: const [
                  DropdownMenuItem(value: '', child: Text('Tất cả', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'male', child: Text('Nam', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'female', child: Text('Nữ', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) => setState(() => _filterGender = v ?? ''),
              )),
            ]),
          ),
        ])),
        // Right: Add button (vertically centered)
        const SizedBox(width: 16),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: _openCreate,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Thêm sản phẩm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _filterDropdown({
    required bool isDark,
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
  }) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final enabled = onChanged != null;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: enabled ? 0.04 : 0.02) : (enabled ? const Color(0xFFF9FAFB) : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: Text(hint, style: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF111827)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // PRODUCT TABLE
  // ═══════════════════════════════════════════════
  Widget _buildProductGrid(bool isDark, List<Product> products) {
    final bg = isDark ? AppTheme.darkCardBg : Colors.white;
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final headerStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : const Color(0xFF6B7280));
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB);

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        // Header row
        Container(
          color: headerBg,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            SizedBox(width: 36, child: Text('#', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            SizedBox(width: 44, child: Text('Ảnh', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 3, child: Text('Sản phẩm', style: headerStyle)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('SKU', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Danh mục', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Thương hiệu', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text('Giá', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: Text('Tồn kho', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            Expanded(flex: 1, child: Text('Trạng thái', style: headerStyle, textAlign: TextAlign.center)),
            const SizedBox(width: 8),
            SizedBox(width: 60, child: Text('', style: headerStyle)),
          ]),
        ),
        // Rows
        Expanded(child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (_, i) => _buildProductRow(isDark, products[i], i + 1, border),
        )),
      ]),
    );
  }

  Widget _buildProductRow(bool isDark, Product p, int index, Color border) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF374151);
    final textStyle = TextStyle(fontSize: 11, color: textColor);
    final hasSale = p.salePrice > 0 && p.salePrice < p.price;

    // Stock status
    Widget stockBadge;
    if (!p.isActive) {
      stockBadge = _statusChip('Ẩn', const Color(0xFF6B7280));
    } else if (p.stock == 0) {
      stockBadge = _statusChip('Hết hàng', const Color(0xFFEF4444));
    } else if (p.stock <= 10) {
      stockBadge = _statusChip('Sắp hết', const Color(0xFFF59E0B));
    } else {
      stockBadge = _statusChip('Đang bán', const Color(0xFF10B981));
    }

    return InkWell(
      onTap: () => _openEdit(p),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
        child: Row(children: [
          SizedBox(width: 36, child: Text('$index', style: textStyle, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          SizedBox(width: 44, child: Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6),
            ),
            clipBehavior: Clip.antiAlias,
            child: p.images.isNotEmpty
                ? Image.network(p.images.first, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.image_rounded, size: 14, color: isDark ? Colors.white24 : const Color(0xFFBBBBBB)))
                : Icon(Icons.image_rounded, size: 14, color: isDark ? Colors.white24 : const Color(0xFFBBBBBB)),
          )),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Row(children: [
            _genderIcon(p.gender, isDark),
            const SizedBox(width: 6),
            Flexible(child: Text(p.name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis)),
          ])),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(p.sku.isNotEmpty ? p.sku : '—', style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(p.categoryName, style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text(p.brandName.isNotEmpty ? p.brandName : '—', style: textStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasSale) ...[
                Text(p.formattedSalePrice, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                Text(p.formattedPrice, style: TextStyle(fontSize: 9, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF), decoration: TextDecoration.lineThrough)),
              ] else
                Text(p.formattedPrice, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF111827))),
            ],
          )),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: Text('${p.stock}', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700,
            color: p.stock == 0 ? const Color(0xFFEF4444) : p.stock <= 10 ? const Color(0xFFF59E0B) : (isDark ? Colors.white : const Color(0xFF111827)),
          ), textAlign: TextAlign.center)),
          const SizedBox(width: 8),
          Expanded(flex: 1, child: Center(child: stockBadge)),
          const SizedBox(width: 8),
          SizedBox(width: 60, child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            _miniBtn(Icons.edit_rounded, const Color(0xFF7C3AED), () => _openEdit(p)),
            const SizedBox(width: 4),
            _miniBtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _delete(p)),
          ])),
        ]),
      ),
    );
  }

  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _genderIcon(String gender, bool isDark) {
    final (IconData icon, Color color) = switch (gender) {
      'male' => (Icons.male_rounded, const Color(0xFF3B82F6)),
      'female' => (Icons.female_rounded, const Color(0xFFEC4899)),
      _ => (Icons.people_rounded, isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
    };
    return Icon(icon, size: 14, color: color);
  }

  Widget _miniBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 16, color: color.withValues(alpha: 0.7))),
    );
  }

  void _showVariantDetail(Product p, bool isDark) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);
    final headerStyle = TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF));

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 500),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
              child: Row(children: [
                const Icon(Icons.view_list_rounded, size: 18, color: Color(0xFF7C3AED)),
                const SizedBox(width: 8),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827)), overflow: TextOverflow.ellipsis),
                  Text('${p.variants.length} bi\u1ebfn th\u1ec3 \u2022 T\u1ed3n kho: ${p.stock}',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
                ])),
                IconButton(icon: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB),
              child: Row(children: [
                SizedBox(width: 60, child: Text('Size', style: headerStyle)),
                Expanded(child: Text('M\u00e0u', style: headerStyle)),
                SizedBox(width: 60, child: Text('T\u1ed3n kho', style: headerStyle, textAlign: TextAlign.center)),
                SizedBox(width: 80, child: Text('Gi\u00e1', style: headerStyle, textAlign: TextAlign.right)),
              ]),
            ),
            // Variant rows
            Flexible(child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: p.variants.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: border),
              itemBuilder: (_, i) {
                final v = p.variants[i];
                final stockColor = v.stock == 0 ? const Color(0xFFEF4444) : v.stock <= 5 ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : const Color(0xFF374151));
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(children: [
                    SizedBox(width: 60, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                      child: Text(v.size, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)), textAlign: TextAlign.center),
                    )),
                    Expanded(child: Text(v.color, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF374151)))),
                    SizedBox(width: 60, child: Text('${v.stock}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: stockColor), textAlign: TextAlign.center)),
                    SizedBox(width: 80, child: Text(v.price > 0 ? '${v.price.toInt()}\u0111' : '\u2014', style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)), textAlign: TextAlign.right)),
                  ]),
                );
              },
            )),
            const SizedBox(height: 12),
          ]),
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
          decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.inventory_2_rounded, size: 36, color: Color(0xFF7C3AED)),
        ),
        const SizedBox(height: 16),
        Text(
          _searchQuery.isNotEmpty || _filterParentCat.isNotEmpty || _filterGender.isNotEmpty
              ? 'Không tìm thấy sản phẩm'
              : 'Chưa có sản phẩm nào',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151)),
        ),
        const SizedBox(height: 6),
        Text('Bắt đầu bằng cách thêm sản phẩm đầu tiên', style: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF))),
      ]),
    );
  }

  // ═══════════════════════════════════════════════
  // PANEL FORM
  // ═══════════════════════════════════════════════
  Widget _buildPanelForm(bool isDark, List<Category> allCats, List<Brand> allBrands) {
    final childCats = _selectableChildCats(allCats);

    // Group child cats by parent for better UX
    final parents = _parentCats(allCats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── Section: Basic Info ───
        _sectionTitle('Thông tin cơ bản', Icons.info_rounded, isDark),
        const SizedBox(height: 12),

        _label('Tên sản phẩm *', isDark),
        const SizedBox(height: 6),
        _input(_nameCtrl, 'Nhập tên sản phẩm...', isDark),
        const SizedBox(height: 16),

        _label('Mô tả', isDark),
        const SizedBox(height: 6),
        _input(_descCtrl, 'Mô tả sản phẩm...', isDark, maxLines: 3),
        const SizedBox(height: 16),

        _label('SKU', isDark),
        const SizedBox(height: 6),
        _input(_skuCtrl, 'Mã SKU...', isDark),
        const SizedBox(height: 16),

        _label('Chất liệu', isDark),
        const SizedBox(height: 6),
        _input(_materialCtrl, 'Cotton, Polyester...', isDark),
        const SizedBox(height: 24),

        // ─── Section: Category & Gender ───
        _sectionTitle('Phân loại', Icons.category_rounded, isDark),
        const SizedBox(height: 12),

        _label('Danh mục con *', isDark),
        const SizedBox(height: 6),
        _categoryDropdown(isDark, parents, allCats),
        const SizedBox(height: 16),

        _label('Thương hiệu', isDark),
        const SizedBox(height: 6),
        _brandDropdown(isDark, allBrands),
        const SizedBox(height: 16),

        _label('Giới tính', isDark),
        const SizedBox(height: 6),
        _genderSelector(isDark),
        const SizedBox(height: 24),

        // ─── Section: Pricing ───
        _sectionTitle('Giá bán', Icons.attach_money_rounded, isDark),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Giá gốc (đ) *', isDark),
            const SizedBox(height: 6),
            _input(_priceCtrl, '0', isDark, inputType: TextInputType.number),
          ])),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _label('Giá sale (đ)', isDark),
            const SizedBox(height: 6),
            _input(_salePriceCtrl, '0', isDark, inputType: TextInputType.number),
          ])),
        ]),
        const SizedBox(height: 24),

        // ─── Section: Variants ───
        _sectionTitle('Size & Màu', Icons.palette_rounded, isDark),
        const SizedBox(height: 12),

        _buildSizeSelector(isDark),
        const SizedBox(height: 16),

        _buildColorInput(isDark),
        const SizedBox(height: 16),

        // Variant table (auto appears when has sizes + colors)
        if (_selectedSizes.isNotEmpty && _selectedColors.isNotEmpty)
          _buildVariantTable(isDark),
        const SizedBox(height: 24),

        // ─── Section: Images per color (compact) ───
        _sectionTitle('Hình ảnh theo màu', Icons.image_rounded, isDark),
        const SizedBox(height: 12),

        _buildCompactColorImages(isDark),
        const SizedBox(height: 24),

        // ─── Section: Status ───
        _sectionTitle('Trạng thái', Icons.toggle_on_rounded, isDark),
        const SizedBox(height: 12),

        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() => _formIsActive = !_formIsActive),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB)),
            ),
            child: Row(children: [
              Icon(
                _formIsActive ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                size: 18,
                color: _formIsActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _formIsActive ? 'Đang bán — hiển thị trên shop' : 'Đã ẩn — không hiển thị',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF374151)),
              )),
              Switch(value: _formIsActive, onChanged: (v) => setState(() => _formIsActive = v), activeColor: const Color(0xFF10B981)),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        _label('Ghi chú nội bộ', isDark),
        const SizedBox(height: 6),
        _input(_noteCtrl, 'Ghi chú...', isDark, maxLines: 2),
      ],
    );
  }

  // ─── Form helpers ───
  Widget _sectionTitle(String title, IconData icon, bool isDark) {
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: border))),
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFF7C3AED)),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF111827))),
      ]),
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF374151)));
  }

  Widget _input(TextEditingController ctrl, String hint, bool isDark, {int maxLines = 1, TextInputType? inputType}) {
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

  /// Category dropdown grouped by parent
  Widget _categoryDropdown(bool isDark, List<Category> parents, List<Category> allCats) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);

    // Build grouped items: parent label (disabled) → children (selectable)
    final items = <DropdownMenuItem<String>>[];
    for (final parent in parents) {
      final children = _childCats(allCats, parent.id);
      if (children.isEmpty) continue;

      // Parent label as disabled header
      items.add(DropdownMenuItem<String>(
        enabled: false,
        value: '__header_${parent.id}',
        child: Text('── ${parent.name} ──', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
      ));

      for (final child in children) {
        items.add(DropdownMenuItem<String>(
          value: child.id,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(child.name, style: const TextStyle(fontSize: 13)),
          ),
        ));
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _formCategoryId.isNotEmpty ? _formCategoryId : null,
          hint: Text('Chọn danh mục con', style: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA))),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
          items: items,
          onChanged: (v) {
            if (v == null || v.startsWith('__header_')) return;
            // Find category name
            final cat = allCats.firstWhere((c) => c.id == v, orElse: () => Category(id: '', name: '', description: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
            setState(() {
              _formCategoryId = v;
              _formCategoryName = cat.name;
              // Auto-detect size tab based on category
              _sizeTab = _autoSizeTab();
              _selectedSizes.clear();
            });
          },
        ),
      ),
    );
  }

  /// Brand dropdown
  Widget _brandDropdown(bool isDark, List<Brand> brands) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _formBrandId.isNotEmpty ? _formBrandId : null,
          hint: Text('Chọn thương hiệu', style: TextStyle(fontSize: 13, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA))),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
          items: [
            const DropdownMenuItem<String>(value: '', child: Text('Không có', style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
            ...brands.map((b) => DropdownMenuItem<String>(
              value: b.id,
              child: Row(
                children: [
                  if (b.logoUrl != null && b.logoUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(b.logoUrl!, width: 20, height: 20, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF7C3AED))),
                    ),
                    const SizedBox(width: 8),
                  ] else ...[
                    const Icon(Icons.verified_rounded, size: 16, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 8),
                  ],
                  Flexible(child: Text(b.name, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
            )),
          ],
          onChanged: (v) {
            if (v == null) return;
            if (v.isEmpty) {
              setState(() {
                _formBrandId = '';
                _formBrandName = '';
              });
              return;
            }
            final brand = brands.firstWhere((b) => b.id == v, orElse: () => Brand(id: '', name: '', description: '', createdAt: DateTime.now(), updatedAt: DateTime.now()));
            setState(() {
              _formBrandId = v;
              _formBrandName = brand.name;
            });
          },
        ),
      ),
    );
  }

  // ─── Size Selector with category-based tabs ───
  static const _clothesSizes = ['XS', 'S', 'M', 'L', 'XL', '2XL', '3XL'];
  static const _shoeSizes = ['35', '36', '37', '38', '39', '40', '41', '42', '43', '44', '45', '46'];
  static const _bagSizes = ['S', 'M', 'L'];
  static const _watchSizes = ['36mm', '38mm', '40mm', '42mm'];
  static const _accessorySizes = ['S/M', 'M/L', 'L/XL'];

  // Auto-detect size tab based on category
  int _autoSizeTab() {
    // Shoes
    if (_formCategoryId.contains('giay')) return 1;
    // Watches
    if (_formCategoryId.contains('dongho')) return 3;
    // Bags / Túi xách
    if (_formCategoryId.contains('tuixach')) return 2;
    // Hats, Mũ nón and other accessories
    if (_formCategoryId.contains('pk_mu') || _formCategoryId.contains('phukien')) return 4;
    // Default: clothing
    return 0;
  }

  List<String> _currentSizeList() {
    switch (_sizeTab) {
      case 1: return _shoeSizes;
      case 2: return _bagSizes;
      case 3: return _watchSizes;
      case 4: return _accessorySizes;
      default: return _clothesSizes;
    }
  }

  Widget _buildSizeSelector(bool isDark) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab header — scrollable row for 5 tabs
        Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(3),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _sizeTabBtn(0, 'Quần áo', Icons.checkroom_rounded, isDark),
              const SizedBox(width: 3),
              _sizeTabBtn(1, 'Giày dép', Icons.ice_skating_rounded, isDark),
              const SizedBox(width: 3),
              _sizeTabBtn(2, 'Túi', Icons.shopping_bag_rounded, isDark),
              const SizedBox(width: 3),
              _sizeTabBtn(3, 'Đồng hồ', Icons.watch_rounded, isDark),
              const SizedBox(width: 3),
              _sizeTabBtn(4, 'Mũ/P.Kiện', Icons.headset_rounded, isDark),
            ]),
          ),
        ),
        const SizedBox(height: 12),

        // Size chips for current tab
        _buildSizeChips(_currentSizeList(), true, isDark, border),

        // Selected count
        if (_selectedSizes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF10B981)),
            const SizedBox(width: 4),
            Text(
              'Đã chọn ${_selectedSizes.length} size: ${_selectedSizes.join(', ')}',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF10B981)),
            ),
            const Spacer(),
            InkWell(
              onTap: () => setState(() => _selectedSizes.clear()),
              child: const Text('Xóa hết', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFFEF4444))),
            ),
          ]),
        ],
      ],
    );
  }

  Widget _sizeTabBtn(int index, String label, IconData icon, bool isDark) {
    final active = _sizeTab == index;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() {
        _sizeTab = index;
        _selectedSizes.clear(); // clear when switching tabs
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: active
              ? (isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.2) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active && !isDark
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14, color: active ? const Color(0xFF7C3AED) : (isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w500, color: active ? const Color(0xFF7C3AED) : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)))),
        ]),
      ),
    );
  }

  Widget _buildSizeChips(List<String> sizes, bool visible, bool isDark, Color border) {
    if (!visible) return const SizedBox.shrink();
    // Determine chip width based on longest label
    final maxLen = sizes.fold<int>(0, (prev, s) => s.length > prev ? s.length : prev);
    final chipW = maxLen > 3 ? 58.0 : (maxLen > 2 ? 52.0 : 44.0);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sizes.map((s) {
        final selected = _selectedSizes.contains(s);
        return InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => setState(() {
            if (selected) {
              _selectedSizes.remove(s);
            } else {
              _selectedSizes.add(s);
            }
          }),
          child: Container(
            width: chipW,
            height: 36,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFF7C3AED)
                  : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? const Color(0xFF7C3AED) : border,
                width: selected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              s,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : (isDark ? Colors.white60 : const Color(0xFF374151)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Color Tag Input ───
  void _addColor(String color) {
    final c = color.trim();
    if (c.isEmpty || _selectedColors.contains(c)) return;
    setState(() {
      _selectedColors.add(c);
      _colorInputCtrl.clear();
    });
  }

  Widget _buildColorInput(bool isDark) {
    final border = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE5E7EB);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Màu sắc', isDark),
      const SizedBox(height: 8),

      // Input + Add button
      Row(children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _colorInputCtrl,
              style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF111827)),
              onSubmitted: _addColor,
              decoration: InputDecoration(
                hintText: 'Nhập tên màu...',
                hintStyle: TextStyle(fontSize: 12, color: isDark ? Colors.white30 : const Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.palette_rounded, size: 16, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: () => _addColor(_colorInputCtrl.text),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Thêm', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]),

      // Color tags
      if (_selectedColors.isNotEmpty) ...[
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _selectedColors.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF7C3AED).withValues(alpha: 0.15) : const Color(0xFF7C3AED).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.2)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(c, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF7C3AED))),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _selectedColors.remove(c)),
                      child: Icon(Icons.close_rounded, size: 12, color: isDark ? Colors.white30 : const Color(0xFF7C3AED).withValues(alpha: 0.5)),
                    ),
                  ]),
                );
              }).toList(),
            ),
            const SizedBox(height: 6),
            Row(children: [
              Text('${_selectedColors.length} màu đã chọn', style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
              const Spacer(),
              InkWell(
                onTap: () => setState(() => _selectedColors.clear()),
                child: const Text('Xóa tất cả', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Color(0xFFEF4444))),
              ),
            ]),
          ]),
        ),
      ],
    ]);
  }

  // ─── Variant Table: Size × Color grid ───
  Widget _buildVariantTable(bool isDark) {
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);
    final headerBg = isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF3F4F6);
    final sizes = _selectedSizes.toList();
    final colors = _selectedColors.toList();
    final defaultPrice = double.tryParse(_priceCtrl.text) ?? 0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _label('Bảng biến thể (${sizes.length * colors.length} tổ hợp)', isDark),
        const Spacer(),
        Text('Size × Màu', style: TextStyle(fontSize: 10, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF))),
      ]),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: headerBg,
            child: Row(children: [
              SizedBox(width: 70, child: Text('Size', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : const Color(0xFF6B7280)))),
              Expanded(child: Text('Màu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : const Color(0xFF6B7280)))),
              SizedBox(width: 90, child: Text('Giá (đ)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : const Color(0xFF6B7280)))),
              const SizedBox(width: 8),
              SizedBox(width: 60, child: Text('Kho', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? Colors.white60 : const Color(0xFF6B7280)))),
            ]),
          ),
          // Rows
          ...sizes.expand((size) => colors.map((color) {
            final key = '$size|$color';
            final data = _variantData.putIfAbsent(key, () => {'price': defaultPrice, 'stock': 0});
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: border))),
              child: Row(children: [
                SizedBox(width: 70, child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF7C3AED).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(4)),
                  child: Text(size, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF7C3AED)), textAlign: TextAlign.center),
                )),
                Expanded(child: Text(color, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF374151)), overflow: TextOverflow.ellipsis)),
                SizedBox(width: 90, child: SizedBox(height: 28, child: TextField(
                  controller: TextEditingController(text: (data['price'] as double).toStringAsFixed(0)),
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF111827)),
                  onChanged: (v) => _variantData[key]!['price'] = double.tryParse(v) ?? 0,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1)),
                  ),
                ))),
                const SizedBox(width: 8),
                SizedBox(width: 60, child: SizedBox(height: 28, child: TextField(
                  controller: TextEditingController(text: (data['stock'] as int).toString()),
                  keyboardType: TextInputType.number,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white : const Color(0xFF111827)),
                  onChanged: (v) => _variantData[key]!['stock'] = int.tryParse(v) ?? 0,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: border)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1)),
                  ),
                ))),
              ]),
            );
          })),
        ]),
      ),
    ]);
  }

  // ─── Compact Color Image Grid ───
  Widget _buildCompactColorImages(bool isDark) {
    final border = isDark ? Colors.white.withValues(alpha: 0.06) : const Color(0xFFE5E7EB);

    if (_selectedColors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Row(children: [
          Icon(Icons.info_outline_rounded, size: 14, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Flexible(child: Text('Thêm màu sắc trước để upload ảnh', style: TextStyle(fontSize: 11, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)))),
        ]),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedColors.map((color) {
        _colorImageCtrls.putIfAbsent(color, () => TextEditingController());
        final ctrl = _colorImageCtrls[color]!;
        final hasImage = ctrl.text.isNotEmpty;

        return Column(children: [
          // Square thumbnail
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _pickImageForColor(color),
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasImage ? const Color(0xFF10B981) : border,
                  width: hasImage ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: hasImage
                  ? Stack(children: [
                      Image.network(ctrl.text, width: 72, height: 72, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Icons.broken_image_rounded, size: 20, color: isDark ? Colors.white30 : const Color(0xFF9CA3AF)),
                        ),
                      ),
                      // Remove button
                      Positioned(top: 2, right: 2, child: InkWell(
                        onTap: () => setState(() => ctrl.clear()),
                        child: Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                          child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
                        ),
                      )),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.add_photo_alternate_rounded, size: 22,
                        color: isDark ? Colors.white24 : const Color(0xFFBBBBBB)),
                    ]),
            ),
          ),
          const SizedBox(height: 4),
          // Color label
          SizedBox(
            width: 72,
            child: Text(color, style: TextStyle(
              fontSize: 10,
              fontWeight: hasImage ? FontWeight.w600 : FontWeight.w500,
              color: hasImage
                  ? const Color(0xFF10B981)
                  : (isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
            ), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
          ),
        ]);
      }).toList(),
    );
  }

  void _pickImageForColor(String color) {
    // ignore: avoid_web_libraries_in_flutter
    // Uses dart:html for web file picking
    final upload = html.FileUploadInputElement()..accept = 'image/*';
    upload.click();
    upload.onChange.listen((event) async {
      final files = upload.files;
      if (files == null || files.isEmpty) return;
      final file = files[0];
      if (file.size > 10 * 1024 * 1024) return; // Max 10MB

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((_) async {
        final bytes = reader.result as Uint8List;
        final url = await CloudinaryService.uploadImage(bytes, fileName: file.name);
        if (!mounted || url == null) return;
        setState(() {
          _colorImageCtrls.putIfAbsent(color, () => TextEditingController());
          _colorImageCtrls[color]!.text = url;
        });
      });
    });
  }

  Widget _genderSelector(bool isDark) {
    const options = [
      ('male', 'Nam', Icons.male_rounded),
      ('female', 'Nữ', Icons.female_rounded),
    ];
    return Row(
      children: options.map((o) {
        final selected = _formGender == o.$1;
        final color = selected ? const Color(0xFF7C3AED) : (isDark ? Colors.white38 : const Color(0xFF9CA3AF));
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _formGender = o.$1),
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
            label: Text(_editing != null ? 'Cập nhật' : 'Thêm sản phẩm', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
