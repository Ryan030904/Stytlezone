import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../utils/app_snackbar.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../providers/product_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';

/// Widget nội dung trang Sản phẩm — đầy đủ CRUD + lọc theo danh mục.
class ProductContent extends StatefulWidget {
  const ProductContent({super.key});

  @override
  State<ProductContent> createState() => _ProductContentState();
}

class _ProductContentState extends State<ProductContent> {
  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _skuController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _salePriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _materialController = TextEditingController();
  final _imageUrlController = TextEditingController();

  // State
  bool _isEditMode = false;
  Product? _editingProduct;
  bool _isActive = true;
  String _selectedCategoryId = '';
  String _selectedCategoryName = '';
  List<String> _selectedSizes = [];
  List<String> _selectedColors = [];

  // Available options
  static const _availableSizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    'XXL',
    '2XL',
    '3XL',
  ];
  static const _availableColors = [
    {'name': 'Đen', 'color': Colors.black},
    {'name': 'Trắng', 'color': Colors.white},
    {'name': 'Đỏ', 'color': Colors.red},
    {'name': 'Xanh dương', 'color': Colors.blue},
    {'name': 'Xanh lá', 'color': Colors.green},
    {'name': 'Vàng', 'color': Colors.amber},
    {'name': 'Hồng', 'color': Colors.pink},
    {'name': 'Tím', 'color': Colors.purple},
    {'name': 'Cam', 'color': Colors.orange},
    {'name': 'Nâu', 'color': Colors.brown},
    {'name': 'Xám', 'color': Colors.grey},
    {'name': 'Be', 'color': Color(0xFFF5F5DC)},
    {'name': 'Navy', 'color': Color(0xFF000080)},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<ProductProvider>(context, listen: false).loadProducts();
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _salePriceController.dispose();
    _stockController.dispose();
    _materialController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    _isEditMode = false;
    _editingProduct = null;
    _isActive = true;
    _selectedCategoryId = '';
    _selectedCategoryName = '';
    _selectedSizes = [];
    _selectedColors = [];
    _nameController.clear();
    _descriptionController.clear();
    _skuController.clear();
    _brandController.clear();
    _priceController.clear();
    _salePriceController.clear();
    _stockController.clear();
    _materialController.clear();
    _imageUrlController.clear();
    _showProductDialog();
  }

  void _openEditDialog(Product product) {
    _isEditMode = true;
    _editingProduct = product;
    _isActive = product.isActive;
    _selectedCategoryId = product.categoryId;
    _selectedCategoryName = product.categoryName;
    _selectedSizes = List<String>.from(product.sizes);
    _selectedColors = List<String>.from(product.colors);
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _skuController.text = product.sku;
    _brandController.text = product.brand;
    _priceController.text = product.price.toStringAsFixed(0);
    _salePriceController.text = product.salePrice?.toStringAsFixed(0) ?? '';
    _stockController.text = product.stock.toString();
    _materialController.text = product.material;
    _imageUrlController.text = product.imageUrl ?? '';
    _showProductDialog();
  }

  void _showProductDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _buildProductDialog(setDialogState);
        },
      ),
    );
  }

  // ============================================================
  // DIALOG
  // ============================================================
  Widget _buildProductDialog(StateSetter setDialogState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final categories = Provider.of<CategoryProvider>(
      context,
      listen: false,
    ).categories.where((c) => c.isActive).toList();

    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEditMode ? 'Chỉnh sửa sản phẩm' : 'Thêm sản phẩm mới',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textLight,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(right: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Section 1: Thông tin cơ bản ──
                    _buildSectionTitle(
                      'Thông tin cơ bản',
                      Icons.info_outline_rounded,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      'Tên sản phẩm *',
                      _nameController,
                      isDarkMode,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Mã SKU',
                            _skuController,
                            isDarkMode,
                            hintText: 'VD: SP-001',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            'Thương hiệu',
                            _brandController,
                            isDarkMode,
                            hintText: 'VD: Nike, Adidas',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      'Mô tả sản phẩm',
                      _descriptionController,
                      isDarkMode,
                      maxLines: 3,
                      hintText: 'Mô tả chi tiết về sản phẩm...',
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      'Link hình ảnh',
                      _imageUrlController,
                      isDarkMode,
                      hintText: 'https://example.com/image.jpg',
                    ),

                    const SizedBox(height: 24),

                    // ── Section 2: Danh mục & Giá ──
                    _buildSectionTitle(
                      'Danh mục & Giá',
                      Icons.sell_rounded,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),

                    // Category dropdown
                    _buildLabel('Danh mục *', isDarkMode),
                    const SizedBox(height: 8),
                    _buildCategoryDropdown(
                      categories,
                      setDialogState,
                      isDarkMode,
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Giá bán (đ) *',
                            _priceController,
                            isDarkMode,
                            keyboardType: TextInputType.number,
                            hintText: 'VD: 350000',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            'Giá khuyến mãi (đ)',
                            _salePriceController,
                            isDarkMode,
                            keyboardType: TextInputType.number,
                            hintText: 'Tùy chọn',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Section 3: Kích thước & Màu sắc ──
                    _buildSectionTitle(
                      'Kích thước & Màu sắc',
                      Icons.straighten_rounded,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),

                    // Sizes
                    _buildLabel('Kích thước', isDarkMode),
                    const SizedBox(height: 8),
                    _buildSizeSelector(setDialogState, isDarkMode),

                    const SizedBox(height: 14),

                    // Colors
                    _buildLabel('Màu sắc', isDarkMode),
                    const SizedBox(height: 8),
                    _buildColorSelector(setDialogState, isDarkMode),

                    const SizedBox(height: 24),

                    // ── Section 4: Kho hàng & Chi tiết ──
                    _buildSectionTitle(
                      'Kho hàng & Chi tiết',
                      Icons.inventory_2_rounded,
                      isDarkMode,
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Tồn kho *',
                            _stockController,
                            isDarkMode,
                            keyboardType: TextInputType.number,
                            hintText: 'VD: 100',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildTextField(
                            'Chất liệu',
                            _materialController,
                            isDarkMode,
                            hintText: 'VD: Cotton, Polyester',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Status toggle
                    _buildStatusToggle(setDialogState, isDarkMode),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Footer buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    'Hủy',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.6)
                          : AppTheme.textLight,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _saveProduct(),
                  icon: Icon(
                    _isEditMode ? Icons.save_rounded : Icons.add_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    _isEditMode ? 'Cập nhật' : 'Thêm sản phẩm',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIALOG HELPER WIDGETS
  // ============================================================

  Widget _buildSectionTitle(String title, IconData icon, bool isDarkMode) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF7C3AED).withValues(alpha: 0.8),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.borderColor,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(
    List<Category> categories,
    StateSetter setDialogState,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : AppTheme.lightBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.15)
              : AppTheme.borderColor,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategoryId.isEmpty ? null : _selectedCategoryId,
          hint: Text(
            'Chọn danh mục',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppTheme.textLight,
            ),
          ),
          isExpanded: true,
          dropdownColor: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white : AppTheme.textDark,
          ),
          items: categories.map((cat) {
            return DropdownMenuItem<String>(
              value: cat.id,
              child: Text(cat.name),
            );
          }).toList(),
          onChanged: (value) {
            setDialogState(() {
              _selectedCategoryId = value ?? '';
              _selectedCategoryName = categories
                  .firstWhere(
                    (c) => c.id == value,
                    orElse: () => Category(
                      id: '',
                      name: '',
                      description: '',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                    ),
                  )
                  .name;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSizeSelector(StateSetter setDialogState, bool isDarkMode) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableSizes.map((size) {
        final isSelected = _selectedSizes.contains(size);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setDialogState(() {
                if (isSelected) {
                  _selectedSizes.remove(size);
                } else {
                  _selectedSizes.add(size);
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7C3AED)
                    : isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppTheme.lightBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : isDarkMode
                      ? Colors.white.withValues(alpha: 0.15)
                      : AppTheme.borderColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Text(
                size,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : isDarkMode
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textDark,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorSelector(StateSetter setDialogState, bool isDarkMode) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableColors.map((colorInfo) {
        final name = colorInfo['name'] as String;
        final color = colorInfo['color'] as Color;
        final isSelected = _selectedColors.contains(name);
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              setDialogState(() {
                if (isSelected) {
                  _selectedColors.remove(name);
                } else {
                  _selectedColors.add(name);
                }
              });
            },
            child: Tooltip(
              message: name,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.12),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF7C3AED,
                            ).withValues(alpha: 0.3),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        size: 16,
                        color: color.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      )
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String label, bool isDarkMode) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.85)
            : AppTheme.textDark.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool isDarkMode, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String hintText = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, isDarkMode),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white : AppTheme.textDark,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.3)
                  : AppTheme.textLight.withValues(alpha: 0.5),
            ),
            filled: true,
            fillColor: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.lightBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.borderColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.15)
                    : AppTheme.borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(StateSetter setDialogState, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Trạng thái', isDarkMode),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.lightBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isActive ? 'Đang bán' : 'Ngừng bán',
                    style: TextStyle(
                      fontSize: 14,
                      color: _isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _isActive,
                onChanged: (value) {
                  setDialogState(() => _isActive = value);
                },
                activeColor: const Color(0xFF10B981),
                inactiveThumbColor: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE / DELETE
  // ============================================================
  void _saveProduct() async {
    if (_nameController.text.isEmpty) {
      _showError('Vui lòng nhập tên sản phẩm');
      return;
    }
    if (_selectedCategoryId.isEmpty) {
      _showError('Vui lòng chọn danh mục');
      return;
    }
    if (_priceController.text.isEmpty) {
      _showError('Vui lòng nhập giá sản phẩm');
      return;
    }

    final price = double.tryParse(_priceController.text) ?? 0;
    final salePrice = _salePriceController.text.isNotEmpty
        ? double.tryParse(_salePriceController.text)
        : null;
    final stock = int.tryParse(_stockController.text) ?? 0;

    late Product product;
    String? oldCategoryId;

    if (_isEditMode && _editingProduct != null) {
      oldCategoryId = _editingProduct!.categoryId;
      product = _editingProduct!.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        sku: _skuController.text,
        brand: _brandController.text,
        price: price,
        salePrice: salePrice,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        imageUrl: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : null,
        sizes: _selectedSizes,
        colors: _selectedColors,
        material: _materialController.text,
        stock: stock,
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );
    } else {
      product = Product(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        description: _descriptionController.text,
        sku: _skuController.text,
        brand: _brandController.text,
        price: price,
        salePrice: salePrice,
        categoryId: _selectedCategoryId,
        categoryName: _selectedCategoryName,
        imageUrl: _imageUrlController.text.isNotEmpty
            ? _imageUrlController.text
            : null,
        sizes: _selectedSizes,
        colors: _selectedColors,
        material: _materialController.text,
        stock: stock,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final provider = Provider.of<ProductProvider>(context, listen: false);
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    bool success;
    if (_isEditMode) {
      success = await provider.updateProduct(
        product,
        oldCategoryId: oldCategoryId,
      );
    } else {
      success = await provider.createProduct(product);
    }

    if (mounted) {
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
      if (success) {
        _showSuccess(
          _isEditMode
              ? 'Cập nhật sản phẩm thành công'
              : 'Thêm sản phẩm thành công',
        );
      } else {
        _showError(provider.errorMessage ?? 'Có lỗi xảy ra');
      }
    }
  }

  void _showDeleteDialog(Product product) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            const Icon(
              Icons.warning_rounded,
              color: Color(0xFFEF4444),
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              'Xác nhận xóa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "${product.name}"?\nHành động này không thể hoàn tác.',
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.7)
                : AppTheme.textLight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Hủy',
              style: TextStyle(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.textLight,
              ),
            ),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await Provider.of<ProductProvider>(
                context,
                listen: false,
              ).deleteProduct(product.id, product.categoryId);
              if (!mounted) return;
              Provider.of<CategoryProvider>(
                context,
                listen: false,
              ).loadCategories();
              if (success) {
                _showSuccess('Xóa sản phẩm thành công');
              }
            },
            icon: const Icon(
              Icons.delete_rounded,
              size: 16,
              color: Colors.white,
            ),
            label: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String message) => AppSnackBar.error(context, message);
  void _showSuccess(String message) => AppSnackBar.success(context, message);

  // ============================================================
  // MAIN BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Header + filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý sản phẩm',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: isDarkMode ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quản lý tất cả sản phẩm của cửa hàng',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.5)
                              : AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _openAddDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Thêm sản phẩm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Category filter chips
              _buildCategoryFilter(isDarkMode),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Product table
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: _buildProductTable(isDarkMode),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CATEGORY FILTER CHIPS
  // ============================================================
  Widget _buildCategoryFilter(bool isDarkMode) {
    return Consumer<CategoryProvider>(
      builder: (context, catProvider, _) {
        return Consumer<ProductProvider>(
          builder: (context, prodProvider, _) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildFilterChip(
                  'Tất cả',
                  prodProvider.selectedCategoryId.isEmpty,
                  isDarkMode,
                  count: prodProvider.products.length,
                  onTap: () => prodProvider.clearFilter(),
                ),
                ...catProvider.categories.where((c) => c.isActive).map((cat) {
                  final count = prodProvider.getProductCountByCategory(cat.id);
                  return _buildFilterChip(
                    cat.name,
                    prodProvider.selectedCategoryId == cat.id,
                    isDarkMode,
                    count: count,
                    onTap: () => prodProvider.filterByCategory(cat.id),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    bool isDarkMode, {
    required int count,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                : isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.lightBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.4)
                  : isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : isDarkMode
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textDark,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7C3AED).withValues(alpha: 0.2)
                      : isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF7C3AED)
                        : isDarkMode
                        ? Colors.white.withValues(alpha: 0.5)
                        : AppTheme.textLight,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRODUCT TABLE
  // ============================================================
  Widget _buildProductTable(bool isDarkMode) {
    return Consumer<ProductProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.products.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(color: const Color(0xFF7C3AED)),
            ),
          );
        }

        final products = provider.filteredProducts;

        if (products.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppTheme.borderColor,
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_bag_rounded,
                    size: 48,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có sản phẩm nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _openAddDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Thêm sản phẩm đầu tiên'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.borderColor,
            ),
          ),
          child: Column(
            children: [
              _buildTableHeader(isDarkMode),
              ...products.map(
                (product) => _buildProductRow(product, isDarkMode),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.03)
            : AppTheme.lightBg,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _tableHeader('Sản phẩm', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _tableHeader('Danh mục', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 2, child: _tableHeader('Giá', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _tableHeader('Tồn kho', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _tableHeader('Trạng thái', isDarkMode)),
          const SizedBox(width: 16),
          Expanded(flex: 1, child: _tableHeader('Hành động', isDarkMode)),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, bool isDarkMode) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.65),
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildProductRow(Product product, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.04)
                : AppTheme.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          // Product image + name + brand + sizes
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Product image thumbnail
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.image_rounded,
                            size: 20,
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.15),
                          ),
                        )
                      : Icon(
                          Icons.image_rounded,
                          size: 20,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.2)
                              : Colors.black.withValues(alpha: 0.15),
                        ),
                ),
                const SizedBox(width: 12),
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.9)
                              : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (product.brand.isNotEmpty)
                            Text(
                              product.brand,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.4)
                                    : AppTheme.textLight,
                              ),
                            ),
                          if (product.brand.isNotEmpty &&
                              product.sku.isNotEmpty)
                            Text(
                              ' · ',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.3)
                                    : AppTheme.textLight,
                              ),
                            ),
                          if (product.sku.isNotEmpty)
                            Text(
                              product.sku,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDarkMode
                                    ? Colors.white.withValues(alpha: 0.35)
                                    : AppTheme.textLight,
                              ),
                            ),
                        ],
                      ),
                      if (product.sizes.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 4,
                          children: product.sizes
                              .map(
                                (s) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : Colors.black.withValues(alpha: 0.04),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDarkMode
                                          ? Colors.white.withValues(alpha: 0.5)
                                          : AppTheme.textLight,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Category
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  product.categoryName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF7C3AED),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Price
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  product.formattedPrice,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.9)
                        : AppTheme.textDark,
                    decoration: product.salePrice != null
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: isDarkMode
                        ? Colors.white.withValues(alpha: 0.4)
                        : AppTheme.textLight,
                  ),
                ),
                if (product.salePrice != null)
                  Text(
                    product.formattedSalePrice,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFEF4444),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Stock
          Expanded(
            flex: 1,
            child: Text(
              '${product.stock}',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: product.stock == 0
                    ? const Color(0xFFEF4444)
                    : isDarkMode
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: product.isActive
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                product.isActive ? 'Đang bán' : 'Ngừng bán',
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: product.isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Actions
          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    iconSize: 16,
                    icon: const Icon(
                      Icons.edit_rounded,
                      color: Color(0xFF7C3AED),
                    ),
                    onPressed: () => _openEditDialog(product),
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    iconSize: 16,
                    icon: const Icon(
                      Icons.delete_rounded,
                      color: Color(0xFFEF4444),
                    ),
                    onPressed: () => _showDeleteDialog(product),
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
