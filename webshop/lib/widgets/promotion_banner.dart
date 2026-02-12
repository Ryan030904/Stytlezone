import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';

class PromotionBanner extends StatefulWidget {
  const PromotionBanner({super.key});

  @override
  State<PromotionBanner> createState() => _PromotionBannerState();
}

class _PromotionBannerState extends State<PromotionBanner> {
  bool _hovered = false;
  late Timer _timer;
  Duration _remaining = const Duration(hours: 23, minutes: 45, seconds: 30);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining.inSeconds > 0 && mounted) {
        setState(() => _remaining -= const Duration(seconds: 1));
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ShopTheme.isMobile(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        transform: _hovered
            ? Matrix4.translationValues(0, -4, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF7C3AED), Color(0xFFEC4899), Color(0xFFF97316)],
          ),
          borderRadius: isMobile
              ? BorderRadius.zero
              : BorderRadius.circular(ShopTheme.radiusXL),
          boxShadow: _hovered
              ? [BoxShadow(color: ShopTheme.primaryPurple.withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 10))]
              : [],
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 60,
          vertical: isMobile ? 40 : 48,
        ),
        child: isMobile ? _buildMobile() : _buildDesktop(),
      ),
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(ShopTheme.radiusFull),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 8),
                    Text('FLASH SALE', style: TextStyle(
                        color: Colors.white, fontSize: 12,
                        fontWeight: FontWeight.w700, letterSpacing: 1)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('CUỐI TUẦN\nGIẢM ĐẾN 50%',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800,
                    color: Colors.white, height: 1.1, letterSpacing: 1)),
              const SizedBox(height: 16),
              Text('Áp dụng cho tất cả sản phẩm. Số lượng có hạn!',
                style: TextStyle(fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85), height: 1.5)),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ShopTheme.primaryPurple,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('MUA SẮM NGAY', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 48),
        _buildCountdown(),
      ],
    );
  }

  Widget _buildMobile() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(ShopTheme.radiusFull),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⚡', style: TextStyle(fontSize: 14)),
              SizedBox(width: 8),
              Text('FLASH SALE', style: TextStyle(
                  color: Colors.white, fontSize: 12,
                  fontWeight: FontWeight.w700, letterSpacing: 1)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('CUỐI TUẦN\nGIẢM ĐẾN 50%',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
              color: Colors.white, height: 1.1)),
        const SizedBox(height: 20),
        _buildCountdown(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: ShopTheme.primaryPurple,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('MUA SẮM NGAY', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeBox(hours.toString().padLeft(2, '0'), 'GIỜ'),
        _buildSeparator(),
        _buildTimeBox(minutes.toString().padLeft(2, '0'), 'PHÚT'),
        _buildSeparator(),
        _buildTimeBox(seconds.toString().padLeft(2, '0'), 'GIÂY'),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(ShopTheme.radiusMD),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
              color: Colors.white)),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
          color: Colors.white)),
    );
  }
}
