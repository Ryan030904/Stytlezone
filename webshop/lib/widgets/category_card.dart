import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../theme/app_theme.dart';

class CategoryCard extends StatefulWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryCard({super.key, required this.category, this.onTap});

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _hovered = false;
  bool? _prevDark;

  @override
  Widget build(BuildContext context) {
    final colors = ShopTheme.colors(context);
    final isDark = ShopTheme.isDark(context);

    // Detect if this rebuild is due to theme change vs hover change
    final themeChanged = _prevDark != null && _prevDark != isDark;
    _prevDark = isDark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          // Duration = 0 when theme changes (instant), 250ms for hover (smooth)
          duration: Duration(milliseconds: themeChanged ? 0 : 250),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
            border: Border.all(
              color: _hovered
                  ? ShopTheme.primaryPurple.withValues(alpha: 0.4)
                  : colors.border,
              width: _hovered ? 2 : 1,
            ),
            boxShadow: _hovered ? ShopTheme.cardHoverShadow(context) : ShopTheme.cardShadow(context),
          ),
          transform: _hovered
              ? Matrix4.translationValues(0, -6, 0)
              : Matrix4.identity(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildImage(isDark),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                    ),
                  ),
                ),
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: ShopTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(ShopTheme.radiusFull),
                    ),
                    child: Text(
                      '${widget.category.productCount} SP',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16, left: 16, right: 16,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.category.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white.withValues(alpha: _hovered ? 1.0 : 0.6), size: 20),
                    ],
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
    if (widget.category.imageUrl != null && widget.category.imageUrl!.isNotEmpty) {
      return Image.network(widget.category.imageUrl!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(isDark));
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
        child: Icon(Icons.category_rounded, size: 48,
            color: ShopTheme.primaryPurple.withValues(alpha: 0.3)),
      ),
    );
  }
}
