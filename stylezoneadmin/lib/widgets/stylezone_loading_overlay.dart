import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium full-screen loading overlay with orbital dots spinner.
/// Wraps a [child] widget and shows the overlay when [isLoading] is true.
class StylezoneLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final String message;
  final Widget child;

  const StylezoneLoadingOverlay({
    super.key,
    required this.isLoading,
    this.message = 'Đang xử lý...',
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading) _LoadingOverlay(message: message),
      ],
    );
  }
}

class _LoadingOverlay extends StatefulWidget {
  final String message;
  const _LoadingOverlay({required this.message});

  @override
  State<_LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<_LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Main orbit rotation
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    // Fade in the overlay
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Pulse animation for the center glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Orbital spinner
                SizedBox(
                  width: 80,
                  height: 80,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _orbitController,
                      _pulseAnimation,
                    ]),
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _OrbitalDotsPainter(
                          progress: _orbitController.value,
                          pulse: _pulseAnimation.value,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                // Loading text
                Text(
                  widget.message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints 3 orbital dots rotating around a center glow
class _OrbitalDotsPainter extends CustomPainter {
  final double progress;
  final double pulse;

  _OrbitalDotsPainter({
    required this.progress,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbitRadius = size.width * 0.32;

    // Center glow (pulsing)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF7C3AED).withValues(alpha: 0.4 * pulse),
          const Color(0xFF7C3AED).withValues(alpha: 0.0),
        ],
      ).createShader(
        Rect.fromCircle(center: center, radius: size.width * 0.3),
      );
    canvas.drawCircle(center, size.width * 0.3, glowPaint);

    // Center dot
    final centerDotPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
      ).createShader(
        Rect.fromCircle(center: center, radius: 4),
      );
    canvas.drawCircle(center, 3.5 * pulse, centerDotPaint);

    // 3 orbital dots
    const dotColors = [
      [Color(0xFF7C3AED), Color(0xFFA855F7)],
      [Color(0xFFEC4899), Color(0xFFF472B6)],
      [Color(0xFF6366F1), Color(0xFF818CF8)],
    ];

    for (int i = 0; i < 3; i++) {
      final angle = (progress * 2 * pi) + (i * 2 * pi / 3);
      final dotCenter = Offset(
        center.dx + orbitRadius * cos(angle),
        center.dy + orbitRadius * sin(angle),
      );

      // Dot trail (fading shadow)
      for (int t = 3; t >= 1; t--) {
        final trailAngle = angle - (t * 0.15);
        final trailCenter = Offset(
          center.dx + orbitRadius * cos(trailAngle),
          center.dy + orbitRadius * sin(trailAngle),
        );
        final trailPaint = Paint()
          ..color = dotColors[i][0].withValues(alpha: 0.12 * (4 - t) / 3);
        canvas.drawCircle(trailCenter, 5.0 - t * 0.8, trailPaint);
      }

      // Main dot with gradient
      final dotSize = 5.0 + (sin(progress * 2 * pi + i * 1.2) * 1.5);
      final dotPaint = Paint()
        ..shader = RadialGradient(
          colors: dotColors[i],
        ).createShader(
          Rect.fromCircle(center: dotCenter, radius: dotSize),
        );
      canvas.drawCircle(dotCenter, dotSize, dotPaint);

      // Dot glow
      final dotGlowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            dotColors[i][0].withValues(alpha: 0.3),
            dotColors[i][0].withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: dotCenter, radius: dotSize * 3),
        );
      canvas.drawCircle(dotCenter, dotSize * 3, dotGlowPaint);
    }

    // Orbit ring (very subtle)
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, orbitRadius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _OrbitalDotsPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.pulse != pulse;
  }
}

/// Custom page route with Fade + Slide transition.
/// Use this for navigating between Login ↔ ForgotPassword screens.
class StylezonePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  StylezonePageRoute({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            );

            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0)
                  .animate(curvedAnimation),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
}
