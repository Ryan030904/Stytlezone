import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({super.key});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  bool _ctaHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = ShopTheme.isMobile(context);
    final isDark = ShopTheme.isDark(context);

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isMobile ? 420 : 520),
      decoration: BoxDecoration(
        gradient: isDark ? ShopTheme.heroGradientDark : ShopTheme.heroGradientLight,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 60,
        vertical: isMobile ? 40 : 60,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
          child: isMobile ? _buildMobile(isDark) : _buildDesktop(isDark),
        ),
      ),
    );
  }

  Widget _buildDesktop(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: _buildContent(isDark, false)),
        const SizedBox(width: 60),
        Expanded(flex: 2, child: _buildStatCards()),
      ],
    );
  }

  Widget _buildMobile(bool isDark) {
    return Column(
      children: [
        _buildContent(isDark, true),
        const SizedBox(height: 32),
        _buildStatCards(),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    final ctaButtonWidth = isMobile ? 220.0 : 248.0;
    const ctaButtonHeight = 52.0;

    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(ShopTheme.radiusFull),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\u{1F525}', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text('TRENDING XU\u00C2N H\u00C8 2026',
                style: TextStyle(color: Colors.white, fontSize: 12,
                    fontWeight: FontWeight.w600, letterSpacing: 1)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Phong C\u00E1ch\nKh\u00F4ng Gi\u1EDBi H\u1EA1n',
          style: TextStyle(
            fontSize: isMobile ? 36 : 48,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.1,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 16),
        Text(
          'Kh\u00E1m ph\u00E1 b\u1ED9 s\u01B0u t\u1EADp m\u1EDBi nh\u1EA5t v\u1EDBi h\u01A1n 500+ s\u1EA3n ph\u1EA9m th\u1EDDi\ntrang t\u1EEB nh\u1EEFng th\u01B0\u01A1ng hi\u1EC7u h\u00E0ng \u0111\u1EA7u.',
          style: TextStyle(fontSize: 15, color: Colors.white.withValues(alpha: 0.8), height: 1.6),
          textAlign: isMobile ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 16, runSpacing: 12,
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            SizedBox(
              width: ctaButtonWidth,
              height: ctaButtonHeight,
              child: MouseRegion(
                onEnter: (_) => setState(() => _ctaHovered = true),
                onExit: (_) => setState(() => _ctaHovered = false),
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {},
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    height: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(ShopTheme.radiusFull),
                      boxShadow: _ctaHovered
                          ? [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 20)]
                          : [],
                    ),
                    transform: _ctaHovered
                        ? Matrix4.translationValues(0, -2, 0)
                        : Matrix4.identity(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 16,
                            color: ShopTheme.primaryPurple),
                        SizedBox(width: 8),
                        Text('MUA S\u1EAEM NGAY',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                              color: ShopTheme.primaryPurple, letterSpacing: 0.5)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: ctaButtonWidth,
              height: ctaButtonHeight,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
                child: const Text('XEM B\u1ED8 S\u01AFU T\u1EACP', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    final stats = [
      {'icon': Icons.inventory_2_outlined, 'value': '500+', 'label': 'S\u1EA3n ph\u1EA9m', 'color': const Color(0xFFF97316)},
      {'icon': Icons.favorite_rounded, 'value': '50+', 'label': 'Th\u01B0\u01A1ng hi\u1EC7u', 'color': const Color(0xFFEC4899)},
      {'icon': Icons.people_alt_rounded, 'value': '10K+', 'label': 'Kh\u00E1ch h\u00E0ng', 'color': const Color(0xFF8B5CF6)},
    ];

    return Column(
      children: [
        _StatCard(data: stats[0]),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _StatCard(data: stats[1])),
            const SizedBox(width: 16),
            Expanded(child: _StatCard(data: stats[2])),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatefulWidget {
  final Map<String, dynamic> data;
  const _StatCard({required this.data});

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.data['color'] as Color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // No AnimatedContainer -- just a plain Container
      // This is on a gradient bg so no theme colors needed
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _hovered ? 0.2 : 0.12),
          borderRadius: BorderRadius.circular(ShopTheme.radiusLG),
          border: Border.all(color: Colors.white.withValues(alpha: _hovered ? 0.3 : 0.15)),
        ),
        transform: _hovered ? Matrix4.translationValues(0, -3, 0) : Matrix4.identity(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(ShopTheme.radiusMD),
              ),
              child: Icon(widget.data['icon'] as IconData, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.data['value'] as String,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text(widget.data['label'] as String,
                      style: TextStyle(fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7)),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
