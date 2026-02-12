import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ShopFooter extends StatelessWidget {
  const ShopFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ShopTheme.isMobile(context);
    final isDark = ShopTheme.isDark(context);

    return Column(
      children: [
        // Newsletter
        _buildNewsletter(context, isMobile),

        // Main footer
        Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF5F3FF),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 60,
            vertical: 48,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
              child: isMobile
                  ? _buildMobileFooter(context)
                  : _buildDesktopFooter(context),
            ),
          ),
        ),

        // Bottom bar
        Container(
          width: double.infinity,
          color: isDark ? const Color(0xFF070D1A) : const Color(0xFFEDE9FE),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 24 : 60,
            vertical: 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: ShopTheme.maxContentWidth),
              child: isMobile
                  ? _buildMobileBottomBar(context)
                  : _buildDesktopBottomBar(context),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsletter(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 60,
        vertical: 48,
      ),
      decoration: BoxDecoration(
        gradient: ShopTheme.isDark(context)
            ? ShopTheme.heroGradientDark
            : ShopTheme.primaryGradient,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              const Icon(Icons.mail_outline_rounded, color: Colors.white, size: 36),
              const SizedBox(height: 16),
              const Text(
                'ĐĂNG KÝ NHẬN ƯU ĐÃI',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nhận ngay giảm 10% cho đơn hàng đầu tiên và cập nhật xu hướng mới nhất',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Email của bạn...',
                        fillColor: Colors.white.withValues(alpha: 0.15),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ShopTheme.radiusFull),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(ShopTheme.radiusFull),
                          borderSide: const BorderSide(color: Colors.white, width: 2),
                        ),
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        prefixIcon: Icon(Icons.email_outlined,
                            color: Colors.white.withValues(alpha: 0.6), size: 20),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: ShopTheme.primaryPurple,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(ShopTheme.radiusFull),
                      ),
                    ),
                    child: const Text('ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopFooter(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Brand column
        Expanded(
          flex: 2,
          child: _buildBrandColumn(context),
        ),
        const SizedBox(width: 48),
        Expanded(child: _buildLinkColumn(context, 'Giới thiệu', [
          'Về chúng tôi',
          'Đội ngũ',
          'Tuyển dụng',
          'Liên hệ',
        ])),
        Expanded(child: _buildLinkColumn(context, 'Chính sách', [
          'Vận chuyển',
          'Đổi trả',
          'Bảo mật',
          'Điều khoản',
        ])),
        Expanded(child: _buildLinkColumn(context, 'Hỗ trợ', [
          'Blog',
          'FAQ',
          'Hướng dẫn mua',
          'Liên hệ',
        ])),
      ],
    );
  }

  Widget _buildMobileFooter(BuildContext context) {
    return Column(
      children: [
        _buildBrandColumn(context),
        const SizedBox(height: 32),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildLinkColumn(context, 'Giới thiệu', [
              'Về chúng tôi', 'Đội ngũ', 'Tuyển dụng', 'Liên hệ',
            ])),
            Expanded(child: _buildLinkColumn(context, 'Chính sách', [
              'Vận chuyển', 'Đổi trả', 'Bảo mật', 'Điều khoản',
            ])),
          ],
        ),
        const SizedBox(height: 24),
        _buildLinkColumn(context, 'Hỗ trợ', ['Blog', 'FAQ', 'Hướng dẫn mua', 'Liên hệ']),
      ],
    );
  }

  Widget _buildBrandColumn(BuildContext context) {
    final isDark = ShopTheme.isDark(context);
    final colors = ShopTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => ShopTheme.primaryGradient.createShader(bounds),
          child: const Text(
            'STYLEZONE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Địa chỉ thời trang hàng đầu Việt Nam.\nPhong cách không giới hạn.',
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : colors.textSecondary,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        // Social icons
        Row(
          children: [
            _SocialIcon(Icons.facebook_rounded),
            _SocialIcon(Icons.camera_alt_outlined),
            _SocialIcon(Icons.play_arrow_rounded),
            _SocialIcon(Icons.alternate_email_rounded),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkColumn(BuildContext context, String title, List<String> links) {
    final isDark = ShopTheme.isDark(context);
    final colors = ShopTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : colors.textPrimary,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _FooterLink(text: link),
            )),
      ],
    );
  }

  Widget _buildDesktopBottomBar(BuildContext context) {
    final isDark = ShopTheme.isDark(context);
    final colors = ShopTheme.colors(context);

    return Row(
      children: [
        Text(
          '© 2026 StyleZone. All rights reserved.',
          style: TextStyle(
            fontSize: 13,
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : colors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            _BottomLink('Điều khoản'),
            _BottomLink('Bảo mật'),
            _BottomLink('Cookie'),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileBottomBar(BuildContext context) {
    final isDark = ShopTheme.isDark(context);
    final colors = ShopTheme.colors(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BottomLink('Điều khoản'),
            _BottomLink('Bảo mật'),
            _BottomLink('Cookie'),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '© 2026 StyleZone. All rights reserved.',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? Colors.white.withValues(alpha: 0.4)
                : colors.textSecondary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  const _SocialIcon(this.icon);

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hovered = false;
  bool? _prevDark;

  @override
  Widget build(BuildContext context) {
    final isDark = ShopTheme.isDark(context);
    final colors = ShopTheme.colors(context);
    final themeChanged = _prevDark != null && _prevDark != isDark;
    _prevDark = isDark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {},
          child: AnimatedContainer(
            duration: Duration(milliseconds: themeChanged ? 0 : 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _hovered
                  ? ShopTheme.primaryPurple
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : colors.surface),
              borderRadius: BorderRadius.circular(ShopTheme.radiusMD),
              border: Border.all(
                color: _hovered
                    ? ShopTheme.primaryPurple
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.15)
                        : colors.border),
              ),
            ),
            child: Icon(
              widget.icon,
              size: 18,
              color: _hovered
                  ? Colors.white
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String text;
  const _FooterLink({required this.text});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = ShopTheme.isDark(context);
    final colors = ShopTheme.colors(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: 14,
            color: _hovered
                ? ShopTheme.primaryPurpleLight
                : (isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : colors.textSecondary),
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}

class _BottomLink extends StatelessWidget {
  final String text;
  const _BottomLink(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = ShopTheme.isDark(context);
    final colors = ShopTheme.colors(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? Colors.white.withValues(alpha: 0.35)
              : colors.textSecondary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
