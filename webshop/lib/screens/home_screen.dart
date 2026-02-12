import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../theme/app_theme.dart';
import '../widgets/shop_header.dart';
import '../widgets/hero_banner.dart';
import '../widgets/category_card.dart';
import '../widgets/product_card.dart';
import '../widgets/promotion_banner.dart';
import '../widgets/shop_footer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService _productService = ProductService();
  final CategoryService _categoryService = CategoryService();
  final ScrollController _scrollController = ScrollController();

  List<Product> _newArrivals = [];
  List<Product> _saleProducts = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final scrolled = _scrollController.offset > 20;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _productService.getNewArrivals(limit: 8),
        _productService.getSaleProducts(limit: 8),
        _categoryService.getActiveCategories(),
      ]);

      if (mounted) {
        setState(() {
          _newArrivals = results[0] as List<Product>;
          _saleProducts = results[1] as List<Product>;
          _categories = results[2] as List<Category>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ShopTheme.colors(context);

    return Scaffold(
      backgroundColor: colors.bg,
      floatingActionButton: _isScrolled
          ? FloatingActionButton.small(
              onPressed: () => _scrollController.animateTo(0,
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic),
              backgroundColor: ShopTheme.primaryPurple,
              child: const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          ShopHeader(isScrolled: _isScrolled),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: ShopTheme.primaryPurple,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  children: [
                    const HeroBanner(),
                    _buildFeaturesStrip(),
                    _buildCategoriesSection(),
                    _buildProductsSection(
                      title: 'HÀNG MỚI VỀ',
                      subtitle: 'Khám phá những sản phẩm mới nhất từ các thương hiệu hàng đầu',
                      products: _newArrivals,
                    ),
                    _buildPromotionSection(),
                    _buildProductsSection(
                      title: 'ĐANG GIẢM GIÁ',
                      subtitle: 'Những sản phẩm được giảm giá đặc biệt, số lượng có hạn',
                      products: _saleProducts,
                    ),
                    _buildBrandsSection(),
                    _buildProductsSection(
                      title: 'XU HƯỚNG HOT',
                      subtitle: 'Phong cách được yêu thích nhất trong tháng',
                      products: _newArrivals,
                    ),
                    _buildStyleInspirationSection(),
                    _buildTestimonialsSection(),
                    _buildTrustSection(),
                    const ShopFooter(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════
  // FEATURE STRIP — Cards with hover
  // ═══════════════════════════════════════
  Widget _buildFeaturesStrip() {
    final isMobile = ShopTheme.isMobile(context);
    final colors = ShopTheme.colors(context);
    final features = [
      {'icon': Icons.local_shipping_outlined, 'text': 'Miễn phí vận chuyển'},
      {'icon': Icons.refresh_rounded, 'text': 'Đổi trả 30 ngày'},
      {'icon': Icons.verified_outlined, 'text': 'Chính hãng 100%'},
      {'icon': Icons.support_agent_outlined, 'text': 'Hỗ trợ 24/7'},
    ];

    return Container(
      width: double.infinity,
      color: colors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 60,
        vertical: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: isMobile
              ? Wrap(
                  spacing: 12, runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: features.map((f) => _FeatureCard(
                    icon: f['icon'] as IconData, text: f['text'] as String,
                  )).toList(),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: features.map((f) => _FeatureCard(
                    icon: f['icon'] as IconData, text: f['text'] as String,
                  )).toList(),
                ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // CATEGORIES
  // ═══════════════════════════════════════
  Widget _buildCategoriesSection() {
    final isMobile = ShopTheme.isMobile(context);
    final isTablet = ShopTheme.isTablet(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 60,
        vertical: ShopTheme.spacing3XL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: Column(
            children: [
              _buildSectionHeader('DANH MỤC NỔI BẬT', 'Tìm sản phẩm theo phong cách của bạn'),
              const SizedBox(height: 32),
              _isLoading
                  ? _buildLoadingGrid(isMobile ? 2 : 4)
                  : _buildCategoryGrid(isMobile, isTablet),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(bool isMobile, bool isTablet) {
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);
    final cats = _categories.isNotEmpty ? _categories : _placeholderCategories();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isMobile ? 0.85 : 0.9,
        crossAxisSpacing: isMobile ? 12 : 20,
        mainAxisSpacing: isMobile ? 12 : 20,
      ),
      itemCount: cats.length > crossAxisCount * 2 ? crossAxisCount * 2 : cats.length,
      itemBuilder: (_, i) => CategoryCard(category: cats[i], onTap: () {}),
    );
  }

  // ═══════════════════════════════════════
  // PRODUCTS
  // ═══════════════════════════════════════
  Widget _buildProductsSection({
    required String title,
    required String subtitle,
    required List<Product> products,
  }) {
    final isMobile = ShopTheme.isMobile(context);
    final isTablet = ShopTheme.isTablet(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 60,
        vertical: ShopTheme.spacingXXL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: Column(
            children: [
              _buildSectionHeader(title, subtitle),
              const SizedBox(height: 32),
              _isLoading
                  ? _buildLoadingGrid(isMobile ? 2 : 4)
                  : _buildProductGrid(
                      products.isNotEmpty ? products : _placeholderProducts(),
                      isMobile, isTablet),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.grid_view_rounded, size: 16),
                label: const Text('XEM TẤT CẢ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products, bool isMobile, bool isTablet) {
    final crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 4);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isMobile ? 0.56 : 0.6,
        crossAxisSpacing: isMobile ? 12 : 20,
        mainAxisSpacing: isMobile ? 12 : 20,
      ),
      itemCount: products.length > 8 ? 8 : products.length,
      itemBuilder: (_, i) => ProductCard(
        product: products[i],
        onTap: () {},
        onFavoriteTap: () {},
        onAddToCartTap: () {},
      ),
    );
  }

  // ═══════════════════════════════════════
  // PROMOTION
  // ═══════════════════════════════════════
  Widget _buildPromotionSection() {
    final isMobile = ShopTheme.isMobile(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : 60,
        vertical: ShopTheme.spacing3XL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: const PromotionBanner(),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // BRANDS SECTION
  // ═══════════════════════════════════════
  Widget _buildBrandsSection() {
    final isMobile = ShopTheme.isMobile(context);
    final colors = ShopTheme.colors(context);

    final brands = ['GUCCI', 'LOUIS VUITTON', 'PRADA', 'CHANEL',
                     'DIOR', 'VERSACE', 'BALENCIAGA', 'BURBERRY'];

    return Container(
      width: double.infinity,
      color: colors.surface,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 60,
        vertical: ShopTheme.spacing3XL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: Column(
            children: [
              _buildSectionHeader('THƯƠNG HIỆU NỔI BẬT', 'Hợp tác với các thương hiệu thời trang hàng đầu thế giới'),
              const SizedBox(height: 40),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 4,
                  childAspectRatio: isMobile ? 2.0 : 2.2,
                  crossAxisSpacing: isMobile ? 12 : 20,
                  mainAxisSpacing: isMobile ? 12 : 20,
                ),
                itemCount: brands.length,
                itemBuilder: (_, i) => _BrandCard(name: brands[i]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // STYLE INSPIRATION
  // ═══════════════════════════════════════
  Widget _buildStyleInspirationSection() {
    final isMobile = ShopTheme.isMobile(context);

    final styles = [
      {'title': 'Street Style', 'desc': 'Phong cách đường phố cá tính', 'icon': Icons.directions_walk_rounded},
      {'title': 'Office Chic', 'desc': 'Lịch sự nơi công sở', 'icon': Icons.business_center_rounded},
      {'title': 'Weekend Casual', 'desc': 'Thoải mái cuối tuần', 'icon': Icons.wb_sunny_rounded},
      {'title': 'Evening Glam', 'desc': 'Rực rỡ buổi tối', 'icon': Icons.auto_awesome_rounded},
      {'title': 'Sporty Active', 'desc': 'Năng động thể thao', 'icon': Icons.fitness_center_rounded},
      {'title': 'Minimalist', 'desc': 'Đơn giản tinh tế', 'icon': Icons.crop_square_rounded},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 60,
        vertical: ShopTheme.spacing3XL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: Column(
            children: [
              _buildSectionHeader('CẢM HỨNG PHONG CÁCH', 'Tìm kiếm phong cách phù hợp với cá tính của bạn'),
              const SizedBox(height: 40),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 2 : 3,
                  childAspectRatio: isMobile ? 1.4 : 2.2,
                  crossAxisSpacing: isMobile ? 12 : 20,
                  mainAxisSpacing: isMobile ? 12 : 20,
                ),
                itemCount: styles.length,
                itemBuilder: (_, i) => _StyleCard(
                  title: styles[i]['title'] as String,
                  description: styles[i]['desc'] as String,
                  icon: styles[i]['icon'] as IconData,
                  index: i,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // TESTIMONIALS
  // ═══════════════════════════════════════
  Widget _buildTestimonialsSection() {
    final isMobile = ShopTheme.isMobile(context);

    final reviews = [
      {'name': 'Nguyễn Minh Anh', 'review': 'Chất lượng sản phẩm tuyệt vời! Tôi đã mua nhiều lần và luôn hài lòng. Giao hàng nhanh, đóng gói cẩn thận.', 'stars': 5, 'avatar': 'MA'},
      {'name': 'Trần Đức Hiền', 'review': 'Dịch vụ khách hàng rất chuyên nghiệp. Đổi trả dễ dàng, nhân viên tư vấn nhiệt tình và am hiểu thời trang.', 'stars': 5, 'avatar': 'ĐH'},
      {'name': 'Lê Thanh Thủy', 'review': 'Sản phẩm đúng như mô tả, giá cả hợp lý. Sẽ tiếp tục ủng hộ StyleZone. Rất thích bộ sưu tập xuân hè!', 'stars': 4, 'avatar': 'TT'},
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 60,
        vertical: ShopTheme.spacing3XL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: Column(
            children: [
              _buildSectionHeader('KHÁCH HÀNG NÓI GÌ', 'Những đánh giá từ khách hàng đã mua sắm tại StyleZone'),
              const SizedBox(height: 40),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : 3,
                  childAspectRatio: isMobile ? 2.2 : 1.2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: reviews.length,
                itemBuilder: (_, i) => _TestimonialCard(
                  name: reviews[i]['name'] as String,
                  review: reviews[i]['review'] as String,
                  stars: reviews[i]['stars'] as int,
                  avatar: reviews[i]['avatar'] as String,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // TRUST SECTION
  // ═══════════════════════════════════════
  Widget _buildTrustSection() {
    final isMobile = ShopTheme.isMobile(context);
    final isDark = ShopTheme.isDark(context);

    final items = [
      {'icon': Icons.diamond_outlined, 'title': 'Chất Lượng Cao',
       'desc': 'Sản phẩm được kiểm tra nghiêm ngặt trước khi đến tay bạn. Cam kết chính hãng 100%.'},
      {'icon': Icons.workspace_premium_outlined, 'title': 'Thương Hiệu Uy Tín',
       'desc': 'Hợp tác với các thương hiệu thời trang hàng đầu thế giới. Đa dạng phong cách.'},
      {'icon': Icons.shield_outlined, 'title': 'Bảo Mật Thông Tin',
       'desc': 'Thông tin và thanh toán được bảo mật bằng công nghệ tiên tiến. An toàn tuyệt đối.'},
      {'icon': Icons.emoji_events_outlined, 'title': 'Dịch Vụ Xuất Sắc',
       'desc': 'Đội ngũ tư vấn thời trang chuyên nghiệp luôn sẵn sàng hỗ trợ bạn 24/7.'},
    ];

    final colors = ShopTheme.colors(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF5F3FF),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 60,
        vertical: ShopTheme.spacing3XL,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: Column(
            children: [
              Text('TẠI SAO CHỌN STYLEZONE?',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : colors.textPrimary, letterSpacing: 3)),
              const SizedBox(height: 48),
              isMobile
                  ? Column(
                      children: items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _TrustCard(
                          icon: item['icon'] as IconData,
                          title: item['title'] as String,
                          desc: item['desc'] as String,
                        ),
                      )).toList(),
                    )
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: items.asMap().entries.map((entry) {
                          final i = entry.key;
                          final item = entry.value;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                left: i == 0 ? 0 : 8,
                                right: i == items.length - 1 ? 0 : 8,
                              ),
                              child: _TrustCard(
                                icon: item['icon'] as IconData,
                                title: item['title'] as String,
                                desc: item['desc'] as String,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════
  Widget _buildSectionHeader(String title, String subtitle) {
    final colors = ShopTheme.colors(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 40, height: 2,
              decoration: BoxDecoration(
                gradient: ShopTheme.primaryGradient,
                borderRadius: BorderRadius.circular(1),
              )),
            const SizedBox(width: 16),
            Text(title.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                    color: colors.textPrimary, letterSpacing: 3)),
            const SizedBox(width: 16),
            Container(width: 40, height: 2,
              decoration: BoxDecoration(
                gradient: ShopTheme.primaryGradient,
                borderRadius: BorderRadius.circular(1),
              )),
          ],
        ),
        const SizedBox(height: 10),
        Text(subtitle,
            style: TextStyle(fontSize: 14, color: colors.textSecondary),
            textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildLoadingGrid(int count) {
    final colors = ShopTheme.colors(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: count, childAspectRatio: 0.75,
        crossAxisSpacing: 20, mainAxisSpacing: 20),
      itemCount: count,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
          border: Border.all(color: colors.border),
        ),
        child: Center(
          child: SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: ShopTheme.primaryPurple.withValues(alpha: 0.3))),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════
  // PLACEHOLDERS
  // ═══════════════════════════════════════
  List<Category> _placeholderCategories() => [
    Category(id: '1', name: 'Ao', description: '', productCount: 120, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Category(id: '2', name: 'Quan', description: '', productCount: 85, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Category(id: '3', name: 'Giay', description: '', productCount: 64, createdAt: DateTime.now(), updatedAt: DateTime.now()),
    Category(id: '4', name: 'Phu kien', description: '', productCount: 43, createdAt: DateTime.now(), updatedAt: DateTime.now()),
  ];

  List<Product> _placeholderProducts() => List.generate(8, (i) => Product(
    id: 'p_$i',
    name: ['Ao Blazer Premium', 'Quan Tay Slim Fit', 'Dam Du Tiec Stellar',
           'Ao So Mi Classic', 'Giay Oxford Leather', 'Tui Xach Elegant',
           'Kinh Mat Aviator', 'Ao Khoac Bomber'][i],
    description: '',
    brand: ['StyleZone', 'Urban Edge', 'Stellar', 'Classic Line',
            'LeatherCraft', 'Elegance', 'VisionWear', 'StreetStyle'][i],
    price: [1290000, 890000, 2490000, 650000, 1890000, 1590000, 490000, 1190000][i].toDouble(),
    salePrice: i % 3 == 0 ? [990000, 690000, 1990000, 490000, 1490000, 1190000, 350000, 890000][i].toDouble() : null,
    categoryId: '',
    sizes: ['S', 'M', 'L', 'XL'],
    colors: ['den', 'trang', 'xam'],
    stock: 10,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ));
}

// ═══════════════════════════════════════
// TRUST CARD — individual framed card with hover lift
// ═══════════════════════════════════════
class _TrustCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _TrustCard({required this.icon, required this.title, required this.desc});

  @override
  State<_TrustCard> createState() => _TrustCardState();
}

class _TrustCardState extends State<_TrustCard> {
  bool _hovered = false;
  bool? _prevDark;

  @override
  Widget build(BuildContext context) {
    final colors = ShopTheme.colors(context);
    final isDark = ShopTheme.isDark(context);
    final themeChanged = _prevDark != null && _prevDark != isDark;
    _prevDark = isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: themeChanged ? 0 : 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? Colors.white.withValues(alpha: 0.12) : colors.card)
              : (isDark ? Colors.white.withValues(alpha: 0.05) : colors.surface),
          borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
          border: Border.all(
            color: _hovered
                ? ShopTheme.primaryPurpleLight.withValues(alpha: 0.6)
                : (isDark ? Colors.white.withValues(alpha: 0.1) : colors.border),
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [BoxShadow(
                  color: ShopTheme.primaryPurple.withValues(alpha: 0.2),
                  blurRadius: 20, offset: const Offset(0, 8))]
              : [if (!isDark) BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10, offset: const Offset(0, 2))],
        ),
        transform: _hovered
            ? Matrix4.translationValues(0, -6, 0)
            : Matrix4.identity(),
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: themeChanged ? 0 : 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: ShopTheme.primaryGradient,
                borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
                boxShadow: _hovered
                    ? [BoxShadow(
                        color: ShopTheme.primaryPurple.withValues(alpha: 0.4),
                        blurRadius: 16, offset: const Offset(0, 4))]
                    : [],
              ),
              child: Icon(widget.icon, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(widget.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : colors.textPrimary, letterSpacing: 1),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(widget.desc,
                  style: TextStyle(fontSize: 13,
                      color: isDark
                          ? Colors.white.withValues(alpha: _hovered ? 0.7 : 0.5)
                          : colors.textSecondary,
                      height: 1.6),
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// FEATURE CARD — with hover lift
// ═══════════════════════════════════════
class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String text;

  const _FeatureCard({required this.icon, required this.text});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _hovered = false;
  bool? _prevDark;

  @override
  Widget build(BuildContext context) {
    final colors = ShopTheme.colors(context);
    final isDark = ShopTheme.isDark(context);
    final themeChanged = _prevDark != null && _prevDark != isDark;
    _prevDark = isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: themeChanged ? 0 : 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(ShopTheme.radiusMD),
          border: Border.all(
            color: _hovered
                ? ShopTheme.primaryPurple.withValues(alpha: 0.3)
                : colors.border,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: ShopTheme.primaryPurple.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))]
              : ShopTheme.cardShadow(context),
        ),
        transform: _hovered
            ? Matrix4.translationValues(0, -3, 0)
            : Matrix4.identity(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: ShopTheme.primaryGradient,
                borderRadius: BorderRadius.circular(ShopTheme.radiusSM),
              ),
              child: Icon(widget.icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(widget.text,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// BRAND CARD — with hover lift
// ═══════════════════════════════════════
class _BrandCard extends StatefulWidget {
  final String name;

  const _BrandCard({required this.name});

  @override
  State<_BrandCard> createState() => _BrandCardState();
}

class _BrandCardState extends State<_BrandCard> {
  bool _hovered = false;
  bool? _prevDark;

  @override
  Widget build(BuildContext context) {
    final colors = ShopTheme.colors(context);
    final isDark = ShopTheme.isDark(context);
    final themeChanged = _prevDark != null && _prevDark != isDark;
    _prevDark = isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: Duration(milliseconds: themeChanged ? 0 : 200),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: _hovered
                ? ShopTheme.primaryPurple.withValues(alpha: 0.08)
                : colors.card,
            borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
            border: Border.all(
              color: _hovered
                  ? ShopTheme.primaryPurple.withValues(alpha: 0.4)
                  : colors.border,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered ? ShopTheme.cardHoverShadow(context) : ShopTheme.cardShadow(context),
          ),
          transform: _hovered ? Matrix4.translationValues(0, -4, 0) : Matrix4.identity(),
          child: Center(
            child: Text(widget.name,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: _hovered ? ShopTheme.primaryPurple : colors.textPrimary,
                  letterSpacing: 2)),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// STYLE CARD — gradient on hover
// ═══════════════════════════════════════
class _StyleCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final int index;

  const _StyleCard({
    required this.title, required this.description,
    required this.icon, required this.index,
  });

  @override
  State<_StyleCard> createState() => _StyleCardState();
}

class _StyleCardState extends State<_StyleCard> {
  bool _hovered = false;
  bool? _prevDark;

  static const _gradients = [
    [Color(0xFF7C3AED), Color(0xFF9333EA)],
    [Color(0xFFEC4899), Color(0xFFF43F5E)],
    [Color(0xFFF97316), Color(0xFFEAB308)],
    [Color(0xFF22C55E), Color(0xFF059669)],
    [Color(0xFF3B82F6), Color(0xFF6366F1)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ShopTheme.colors(context);
    final isDark = ShopTheme.isDark(context);
    final themeChanged = _prevDark != null && _prevDark != isDark;
    _prevDark = isDark;
    final gradColors = _gradients[widget.index % _gradients.length];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            gradient: _hovered ? LinearGradient(colors: gradColors) : null,
            color: _hovered ? null : colors.card,
            borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
            border: _hovered ? null : Border.all(color: colors.border),
            boxShadow: _hovered ? ShopTheme.cardHoverShadow(context) : ShopTheme.cardShadow(context),
          ),
          transform: _hovered ? Matrix4.translationValues(0, -4, 0) : Matrix4.identity(),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? Colors.white.withValues(alpha: 0.2)
                        : gradColors[0].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(ShopTheme.radiusMD),
                  ),
                  child: Icon(widget.icon, size: 24,
                      color: _hovered ? Colors.white : gradColors[0]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(widget.title,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                            color: _hovered ? Colors.white : colors.textPrimary)),
                      const SizedBox(height: 4),
                      Text(widget.description,
                        style: TextStyle(fontSize: 12,
                            color: _hovered
                                ? Colors.white.withValues(alpha: 0.8)
                                : colors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  transform: Matrix4.translationValues(_hovered ? 4 : 0, 0, 0),
                  child: Icon(Icons.arrow_forward_rounded, size: 18,
                      color: _hovered ? Colors.white : colors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// TESTIMONIAL CARD — customer review card with hover lift
// ═══════════════════════════════════════
class _TestimonialCard extends StatefulWidget {
  final String name;
  final String review;
  final int stars;
  final String avatar;

  const _TestimonialCard({
    required this.name,
    required this.review,
    required this.stars,
    required this.avatar,
  });

  @override
  State<_TestimonialCard> createState() => _TestimonialCardState();
}

class _TestimonialCardState extends State<_TestimonialCard> {
  bool _hovered = false;
  bool? _prevDark;

  @override
  Widget build(BuildContext context) {
    final colors = ShopTheme.colors(context);
    final isDark = ShopTheme.isDark(context);
    final themeChanged = _prevDark != null && _prevDark != isDark;
    _prevDark = isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: Duration(milliseconds: themeChanged ? 0 : 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hovered
              ? (isDark ? colors.card.withValues(alpha: 0.8) : colors.card)
              : colors.card,
          borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
          border: Border.all(
            color: _hovered
                ? ShopTheme.primaryPurpleLight.withValues(alpha: 0.5)
                : colors.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: _hovered
              ? [BoxShadow(
                  color: ShopTheme.primaryPurple.withValues(alpha: 0.15),
                  blurRadius: 20, offset: const Offset(0, 8))]
              : [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10, offset: const Offset(0, 2))],
        ),
        transform: _hovered
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stars
            Row(
              children: List.generate(5, (i) => Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Icon(
                  i < widget.stars ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 18,
                  color: i < widget.stars
                      ? const Color(0xFFFFB800)
                      : colors.textSecondary.withValues(alpha: 0.3),
                ),
              )),
            ),
            const SizedBox(height: 16),
            // Quote icon
            Icon(Icons.format_quote_rounded, size: 24,
                color: ShopTheme.primaryPurple.withValues(alpha: 0.4)),
            const SizedBox(height: 8),
            // Review text
            Expanded(
              child: Text(widget.review,
                  style: TextStyle(fontSize: 13, color: colors.textSecondary,
                      height: 1.6, fontStyle: FontStyle.italic)),
            ),
            const SizedBox(height: 16),
            // Divider
            Container(height: 1, color: colors.border),
            const SizedBox(height: 12),
            // Avatar + Name
            Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    gradient: ShopTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(widget.avatar,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Text(widget.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: colors.textPrimary)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
