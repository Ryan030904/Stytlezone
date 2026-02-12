import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_theme.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onAddToCartTap;

  const ProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onFavoriteTap,
    this.onAddToCartTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
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
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: Duration(milliseconds: themeChanged ? 0 : 250),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
            border: Border.all(
              color: _hovered
                  ? ShopTheme.primaryPurple.withValues(alpha: 0.3)
                  : colors.border,
            ),
            boxShadow: _hovered ? ShopTheme.cardHoverShadow(context) : ShopTheme.cardShadow(context),
          ),
          transform: _hovered
              ? Matrix4.translationValues(0, -4, 0)
              : Matrix4.identity(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImage(isDark),
                      _buildBadges(),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        top: 8, right: _hovered ? 8 : -50,
                        child: Column(
                          children: [
                            _QuickActionButton(icon: Icons.favorite_border_rounded, onTap: widget.onFavoriteTap),
                            const SizedBox(height: 6),
                            _QuickActionButton(icon: Icons.visibility_outlined, onTap: widget.onTap),
                          ],
                        ),
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        bottom: _hovered ? 0 : -50,
                        left: 0, right: 0,
                        child: GestureDetector(
                          onTap: widget.onAddToCartTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(gradient: ShopTheme.primaryGradient),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 16),
                                SizedBox(width: 8),
                                Text('THEM VAO GIO',
                                  style: TextStyle(color: Colors.white, fontSize: 12,
                                      fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!widget.product.isInStock)
                        Container(
                          color: Colors.black.withValues(alpha: 0.5),
                          child: const Center(
                            child: Text('HET HANG',
                              style: TextStyle(color: Colors.white, fontSize: 16,
                                  fontWeight: FontWeight.w700, letterSpacing: 2)),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.brand.toUpperCase(),
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: ShopTheme.primaryPurple, letterSpacing: 1),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            widget.product.name,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                                color: colors.textPrimary, height: 1.3),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ...List.generate(5, (i) => Icon(
                              i < 4 ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 14, color: ShopTheme.starYellow,
                            )),
                            const SizedBox(width: 4),
                            Text('(4.0)', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildPrice(colors),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(bool isDark) {
    if (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty) {
      return AnimatedScale(
        scale: _hovered ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: Image.network(widget.product.imageUrl!, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(isDark)),
      );
    }
    return _buildPlaceholder(isDark);
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E1036), const Color(0xFF2D1B69)]
              : [const Color(0xFFF5F0FF), const Color(0xFFEDE5FF)],
        ),
      ),
      child: Center(
        child: Icon(Icons.checkroom_rounded, size: 48,
            color: ShopTheme.primaryPurple.withValues(alpha: 0.25)),
      ),
    );
  }

  Widget _buildBadges() {
    return Positioned(
      top: 8, left: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.product.isOnSale)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                gradient: ShopTheme.warmGradient,
                borderRadius: BorderRadius.circular(ShopTheme.radiusSM),
              ),
              child: Text('-${widget.product.discountPercent}%',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          if (_isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: ShopTheme.successGreen,
                borderRadius: BorderRadius.circular(ShopTheme.radiusSM),
              ),
              child: const Text('MOI',
                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  bool get _isNew => DateTime.now().difference(widget.product.createdAt).inDays <= 14;

  Widget _buildPrice(ShopColors colors) {
    if (widget.product.isOnSale) {
      return Row(
        children: [
          Text(widget.product.formattedSalePrice,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: ShopTheme.saleRed)),
          const SizedBox(width: 8),
          Text(widget.product.formattedPrice,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                color: colors.textSecondary, decoration: TextDecoration.lineThrough,
                decorationColor: colors.textSecondary)),
        ],
      );
    }
    return Text(widget.product.formattedPrice,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.textPrimary));
  }
}

class _QuickActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuickActionButton({required this.icon, this.onTap});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        // No theme colors here - white/purple only, no AnimatedContainer needed for theme
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hovered ? ShopTheme.primaryPurple : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8)],
          ),
          child: Icon(widget.icon, size: 18,
              color: _hovered ? Colors.white : ShopTheme.primaryPurple),
        ),
      ),
    );
  }
}
