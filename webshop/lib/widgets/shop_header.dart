import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../utils/theme_provider.dart';

class ShopHeader extends StatelessWidget {
  final bool isScrolled;

  const ShopHeader({super.key, this.isScrolled = false});

  @override
  Widget build(BuildContext context) {
    final isMobile = ShopTheme.isMobile(context);
    final isDark = ShopTheme.isDark(context);
    final colors = ShopTheme.colors(context);

    return Column(
      children: [
        // Top promo bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(gradient: ShopTheme.primaryGradient),
          child: const Text(
            'MIỄN SHIP ĐƠN TỪ 500K • ĐỔI TRẢ MIỄN PHÍ 30 NGÀY',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
          ),
        ),

        // Main nav with glass effect
        ClipRect(
          child: BackdropFilter(
            filter: isScrolled
                ? ImageFilter.blur(sigmaX: 20, sigmaY: 20)
                : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Container(
              decoration: BoxDecoration(
                color: isScrolled
                    ? colors.headerBg.withValues(alpha: isDark ? 0.75 : 0.8)
                    : colors.headerBg,
                border: Border(
                  bottom: BorderSide(
                    color: isScrolled
                        ? colors.border.withValues(alpha: 0.5)
                        : colors.border,
                    width: 1,
                  ),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 40,
                vertical: isMobile ? 12 : 16,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
                  child: isMobile
                      ? _buildMobileNav(context, isDark, colors)
                      : _buildDesktopNav(context, isDark, colors),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopNav(BuildContext context, bool isDark, ShopColors colors) {
    return Row(
      children: [
        // Logo
        ShaderMask(
          shaderCallback: (bounds) => ShopTheme.primaryGradient.createShader(bounds),
          child: const Text('STYLEZONE', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 4)),
        ),
        const SizedBox(width: 48),

        // Nav links
        Expanded(
          child: Row(
            children: [
              _NavLink(text: 'Nam', colors: colors),
              _NavLink(text: 'Nữ', colors: colors),
              _NavLink(text: 'Phụ kiện', colors: colors),
              _NavLink(text: 'Bộ sưu tập', colors: colors),
              _NavLink(text: 'Sale', colors: colors, isSale: true),
            ],
          ),
        ),

        // Action icons
        Row(
          children: [
            _ActionIcon(icon: Icons.search_rounded, onTap: () {}, colors: colors),
            _ActionIcon(icon: Icons.person_outline_rounded, onTap: () {}, colors: colors),
            _ActionIcon(icon: Icons.favorite_border_rounded, onTap: () {}, colors: colors, badge: '3'),
            _ActionIcon(icon: Icons.shopping_bag_outlined, onTap: () {}, colors: colors, badge: '2'),
            const SizedBox(width: 4),
            _ThemeToggle(),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileNav(BuildContext context, bool isDark, ShopColors colors) {
    return Row(
      children: [
        Icon(Icons.menu_rounded, color: colors.textPrimary, size: 24),
        const Spacer(),
        ShaderMask(
          shaderCallback: (bounds) => ShopTheme.primaryGradient.createShader(bounds),
          child: const Text('STYLEZONE', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 3)),
        ),
        const Spacer(),
        _ActionIcon(icon: Icons.search_rounded, onTap: () {}, colors: colors),
        _ActionIcon(icon: Icons.shopping_bag_outlined, onTap: () {}, colors: colors, badge: '2'),
        _ThemeToggle(),
      ],
    );
  }
}

// ═══════════════════════════════════════
// NAV LINK
// ═══════════════════════════════════════
class _NavLink extends StatefulWidget {
  final String text;
  final ShopColors colors;
  final bool isSale;

  const _NavLink({required this.text, required this.colors, this.isSale = false});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {},
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _hovered || widget.isSale ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isSale
                      ? ShopTheme.saleRed
                      : (_hovered ? ShopTheme.primaryPurple : widget.colors.textPrimary),
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2, width: _hovered ? 20 : 0,
                decoration: BoxDecoration(
                  gradient: ShopTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// ACTION ICON
// ═══════════════════════════════════════
class _ActionIcon extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final ShopColors colors;
  final String? badge;

  const _ActionIcon({required this.icon, required this.onTap, required this.colors, this.badge});

  @override
  State<_ActionIcon> createState() => _ActionIconState();
}

class _ActionIconState extends State<_ActionIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _hovered
                      ? ShopTheme.primaryPurple.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(ShopTheme.radiusSM),
                ),
                child: Icon(widget.icon, size: 22,
                    color: _hovered ? ShopTheme.primaryPurple : widget.colors.textPrimary),
              ),
              if (widget.badge != null)
                Positioned(
                  top: 2, right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      gradient: ShopTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Text(widget.badge!,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════
// THEME TOGGLE
// ═══════════════════════════════════════
class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = context.select<ThemeProvider, bool>((p) => p.isDarkMode);
    final colors = ShopTheme.colors(context);

    return GestureDetector(
      onTap: () => context.read<ThemeProvider>().toggleTheme(),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : ShopTheme.primaryPurple.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(ShopTheme.radiusSM),
          ),
          child: AnimatedRotation(
            turns: isDark ? 1 : 0,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                );
              },
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey<bool>(isDark),
                size: 20,
                color: isDark ? starYellow : colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const Color starYellow = Color(0xFFFBBF24);
}
