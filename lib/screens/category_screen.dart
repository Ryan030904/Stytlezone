import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_snackbar.dart';
import '../models/category_model.dart';
import '../providers/category_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

import 'login_screen.dart';
import 'dashboard_screen.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productCountController = TextEditingController();
  bool _isEditMode = false;
  Category? _editingCategory;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CategoryProvider>(context, listen: false).loadCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _productCountController.dispose();
    super.dispose();
  }

  void _openAddDialog() {
    _isEditMode = false;
    _editingCategory = null;
    _isActive = true;
    _nameController.clear();
    _descriptionController.clear();
    _productCountController.clear();
    _showCategoryDialog();
  }

  void _openEditDialog(Category category) {
    _isEditMode = true;
    _editingCategory = category;
    _isActive = category.isActive;
    _nameController.text = category.name;
    _descriptionController.text = category.description;
    _productCountController.text = category.productCount.toString();
    _showCategoryDialog();
  }

  void _showCategoryDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _buildCategoryDialog(setDialogState);
        },
      ),
    );
  }

  Widget _buildCategoryDialog(StateSetter setDialogState) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E293B) : AppTheme.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEditMode ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField('Tên danh mục', _nameController, isDarkMode),
            const SizedBox(height: 16),
            _buildTextField('Mô tả', _descriptionController, isDarkMode, maxLines: 3),
            const SizedBox(height: 16),
            _buildProductCountDisplay(isDarkMode),
            const SizedBox(height: 16),
            _buildStatusToggle(setDialogState, isDarkMode),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                  ),
                  onPressed: () => _saveCategory(),
                  child: Text(
                    _isEditMode ? 'Cập nhật' : 'Thêm',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.85)
                : AppTheme.textDark.withValues(alpha: 0.85),
          ),
        ),
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

  Widget _buildProductCountDisplay(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Số sản phẩm',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.85)
                : AppTheme.textDark.withValues(alpha: 0.85),
          ),
        ),
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
              Text(
                '${_editingCategory?.productCount ?? 0} sản phẩm',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppTheme.textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(
                Icons.lock_rounded,
                size: 16,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.4)
                    : AppTheme.textLight,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusToggle(StateSetter setDialogState, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Trạng thái',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.85)
                : AppTheme.textDark.withValues(alpha: 0.85),
          ),
        ),
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
              Text(
                _isActive ? 'Hoạt động' : 'Không hoạt động',
                style: TextStyle(
                  fontSize: 14,
                  color: _isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Switch(
                value: _isActive,
                onChanged: (value) {
                  setDialogState(() {
                    _isActive = value;
                  });
                },
                activeThumbColor: const Color(0xFF10B981),
                inactiveThumbColor: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _saveCategory() async {
    if (_nameController.text.isEmpty) {
      AppSnackBar.error(context, 'Vui lòng nhập tên danh mục');
      return;
    }

    late Category category;

    if (_isEditMode && _editingCategory != null) {
      // Chỉnh sửa: giữ lại dữ liệu cũ
      category = _editingCategory!.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        isActive: _isActive,
        updatedAt: DateTime.now(),
      );
    } else {
      // Tạo mới
      category = Category(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: null,
        productCount: 0,
        isActive: _isActive,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final provider = Provider.of<CategoryProvider>(context, listen: false);
    bool success;

    if (_isEditMode) {
      success = await provider.updateCategory(category);
    } else {
      success = await provider.createCategory(category);
    }

    if (mounted) {
      Navigator.pop(context);
      if (success) {
        AppSnackBar.success(context, _isEditMode ? 'Cập nhật danh mục thành công' : 'Thêm danh mục thành công');
      } else {
        AppSnackBar.error(context, provider.errorMessage ?? 'Có lỗi xảy ra');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBg : AppTheme.lightBg,
      body: Row(
        children: [
          _buildSidebar(isDarkMode),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context, auth, isDarkMode),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildMainContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(bool isDarkMode) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCardBg : AppTheme.white,
        border: Border(
          right: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.borderColor,
          ),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text('✨', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'StyleZone',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.borderColor,
            height: 1,
          ),
          const SizedBox(height: 16),
          _buildMenuItem(
            Icons.dashboard_rounded,
            'Tổng quan',
            false,
            isDarkMode: isDarkMode,
            onTap: () async {
              if (!mounted) return;
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
          _buildMenuItem(
            Icons.shopping_bag_rounded,
            'Sản phẩm',
            false,
            isDarkMode: isDarkMode,
          ),
          _buildMenuItem(
            Icons.receipt_long_rounded,
            'Đơn hàng',
            false,
            isDarkMode: isDarkMode,
          ),
          _buildMenuItem(
            Icons.people_rounded,
            'Khách hàng',
            false,
            isDarkMode: isDarkMode,
          ),
          _buildMenuItem(
            Icons.category_rounded,
            'Danh mục',
            true,
            isDarkMode: isDarkMode,
          ),
          _buildMenuItem(
            Icons.local_offer_rounded,
            'Khuyến mãi',
            false,
            isDarkMode: isDarkMode,
          ),
          _buildMenuItem(
            Icons.bar_chart_rounded,
            'Báo cáo',
            false,
            isDarkMode: isDarkMode,
          ),
          _buildMenuItem(
            Icons.rate_review_rounded,
            'Đánh giá',
            false,
            isDarkMode: isDarkMode,
          ),
          const Spacer(),
          Divider(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.borderColor,
            height: 1,
          ),
          _buildMenuItem(
            Icons.settings_rounded,
            'Cài đặt',
            false,
            isDarkMode: isDarkMode,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  final auth = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  await auth.signOut();
                  if (!mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFEF4444),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
    bool isDarkMode = true,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () {},
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? const Color(0xFF7C3AED)
                      : isDarkMode
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppTheme.textDark,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? const Color(0xFF7C3AED)
                        : isDarkMode
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    AuthProvider auth,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : AppTheme.white,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.borderColor,
          ),
        ),
      ),
      child: Row(
        children: [
          const Spacer(),
          // Notifications
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.lightBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.6)
                        : AppTheme.textLight,
                    size: 22,
                  ),
                ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // User avatar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppTheme.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    Text(
                      auth.user?.email ?? 'admin@example.com',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDarkMode
                            ? Colors.white.withValues(alpha: 0.5)
                            : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý danh mục',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: isDarkMode ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý tất cả danh mục sản phẩm của cửa hàng',
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
              label: const Text('Thêm danh mục'),
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
        const SizedBox(height: 24),
        _buildCategoryTable(isDarkMode),
      ],
    );
  }

  Widget _buildCategoryTable(bool isDarkMode) {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: const Color(0xFF7C3AED)),
          );
        }

        if (provider.categories.isEmpty) {
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
                    Icons.category_rounded,
                    size: 48,
                    color: isDarkMode
                        ? Colors.white.withValues(alpha: 0.2)
                        : AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Chưa có danh mục nào',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode
                          ? Colors.white.withValues(alpha: 0.5)
                          : AppTheme.textLight,
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
              ...provider.categories
                  .where((category) => category.isActive)
                  .map((category) => _buildCategoryRow(category, isDarkMode)),
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
          Expanded(flex: 2, child: _tableHeader('Tên danh mục', isDarkMode)),
          Expanded(flex: 3, child: _tableHeader('Mô tả', isDarkMode)),
          Expanded(flex: 1, child: _tableHeader('Sản phẩm', isDarkMode)),
          Expanded(flex: 1, child: _tableHeader('Trạng thái', isDarkMode)),
          Expanded(flex: 1, child: _tableHeader('Hành động', isDarkMode)),
        ],
      ),
    );
  }

  Widget _tableHeader(String text, bool isDarkMode) {
    return Text(
      text,
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

  Widget _buildCategoryRow(Category category, bool isDarkMode) {
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
          Expanded(
            flex: 2,
            child: Text(
              category.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.9)
                    : AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              category.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.6)
                    : AppTheme.textLight,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${category.productCount}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: category.isActive
                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                    : const Color(0xFFEF4444).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                category.isActive ? 'Hoạt động' : 'Vô hiệu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: category.isActive
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    size: 18,
                    color: Color(0xFF7C3AED),
                  ),
                  onPressed: () => _openEditDialog(category),
                  tooltip: 'Chỉnh sửa',
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_rounded,
                    size: 18,
                    color: Color(0xFFEF4444),
                  ),
                  onPressed: () => _showDeleteDialog(category),
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Category category) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Xác nhận xóa',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa danh mục "${category.name}"?',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await Provider.of<CategoryProvider>(
                context,
                listen: false,
              ).deleteCategory(category.id);
              if (!mounted) return;
              if (success) {
                AppSnackBar.success(context, 'Xóa danh mục thành công');
              }
            },
            child: Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
