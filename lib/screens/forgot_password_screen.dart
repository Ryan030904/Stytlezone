import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_snackbar.dart';
import '../providers/auth_provider.dart';
import '../widgets/stylezone_loading_overlay.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  late AnimationController _blobController1;
  late AnimationController _blobController2;
  late AnimationController _blobController3;

  @override
  void initState() {
    super.initState();
    _blobController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _blobController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
    _blobController3 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _blobController1.dispose();
    _blobController2.dispose();
    _blobController3.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      AppSnackBar.error(context, 'Vui lòng nhập email');
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.sendPasswordResetEmail(email: email);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      setState(() => _emailSent = true);
      AppSnackBar.success(
        context,
        'Email reset mật khẩu đã được gửi. Vui lòng kiểm tra hộp thư.',
      );
    } else {
      AppSnackBar.error(
        context,
        authProvider.errorMessage ?? 'Không thể gửi email reset',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: StylezoneLoadingOverlay(
        isLoading: _isLoading,
        message: 'Đang gửi email...',
        child: Stack(
          children: [
            // Same animated gradient blobs background as login
            _buildAnimatedBackground(size),

            // Center card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: _buildForgotPasswordCard(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _blobController1,
        _blobController2,
        _blobController3,
      ]),
      builder: (context, _) {
        return CustomPaint(
          size: size,
          painter: _BlobPainter(
            progress1: _blobController1.value,
            progress2: _blobController2.value,
            progress3: _blobController3.value,
          ),
        );
      },
    );
  }

  Widget _buildForgotPasswordCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo — same style as login
              _buildLogo(),
              const SizedBox(height: 8),
              // Title
              Text(
                'StyleZone',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Quên mật khẩu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Nhập email của bạn để nhận hướng dẫn\nreset mật khẩu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 32),

              if (!_emailSent) ...[
                // Email field
                _buildLabel('Địa chỉ Email'),
                const SizedBox(height: 8),
                _buildEmailField(),
                const SizedBox(height: 24),

                // Send reset button
                _buildResetButton(),
                const SizedBox(height: 16),
              ] else ...[
                // Success message
                _buildSuccessMessage(),
                const SizedBox(height: 24),
              ],

              // Back to login
              _buildBackButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFFEC4899)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Center(child: Text('🔑', style: TextStyle(fontSize: 30))),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      style: TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: 'name@stylezone.com',
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.35),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
        ),
      ),
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF7C3AED),
              Color(0xFF9333EA),
              Color(0xFFA855F7),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _handleResetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Đang gửi...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                )
              : Text(
                  'Gửi Email Reset',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle_rounded,
              size: 40,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Email đã được gửi!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lòng kiểm tra hộp thư của bạn để nhận hướng dẫn reset mật khẩu.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Text(
          'Quay lại đăng nhập',
          style: TextStyle(
            fontSize: 13,
            color: const Color(0xFFA78BFA),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFFA78BFA),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// Same BlobPainter as login screen for consistent background
// ============================================================
class _BlobPainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final double progress3;

  _BlobPainter({
    required this.progress1,
    required this.progress2,
    required this.progress3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base dark background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0F172A),
    );

    // Blob 1 — Large purple, bottom-left
    _drawBlob(
      canvas,
      center: Offset(
        size.width * (0.15 + 0.1 * sin(progress1 * pi * 2)),
        size.height * (0.7 + 0.08 * cos(progress1 * pi * 2)),
      ),
      radius: size.width * 0.35,
      colors: [
        const Color(0xFF5B21B6).withValues(alpha: 0.6),
        const Color(0xFF7C3AED).withValues(alpha: 0.3),
        const Color(0xFF7C3AED).withValues(alpha: 0.0),
      ],
    );

    // Blob 2 — Pink/magenta, top-right
    _drawBlob(
      canvas,
      center: Offset(
        size.width * (0.8 + 0.08 * cos(progress2 * pi * 2)),
        size.height * (0.25 + 0.1 * sin(progress2 * pi * 2)),
      ),
      radius: size.width * 0.3,
      colors: [
        const Color(0xFFEC4899).withValues(alpha: 0.5),
        const Color(0xFFBE185D).withValues(alpha: 0.2),
        const Color(0xFFEC4899).withValues(alpha: 0.0),
      ],
    );

    // Blob 3 — Blue/indigo, center-bottom
    _drawBlob(
      canvas,
      center: Offset(
        size.width * (0.55 + 0.12 * sin(progress3 * pi * 2)),
        size.height * (0.85 + 0.06 * cos(progress3 * pi * 2)),
      ),
      radius: size.width * 0.28,
      colors: [
        const Color(0xFF3B82F6).withValues(alpha: 0.4),
        const Color(0xFF6366F1).withValues(alpha: 0.2),
        const Color(0xFF3B82F6).withValues(alpha: 0.0),
      ],
    );

    // Blob 4 — Small purple accent, top-left
    _drawBlob(
      canvas,
      center: Offset(
        size.width * (0.3 + 0.06 * cos(progress1 * pi * 2)),
        size.height * (0.15 + 0.05 * sin(progress2 * pi * 2)),
      ),
      radius: size.width * 0.18,
      colors: [
        const Color(0xFF8B5CF6).withValues(alpha: 0.4),
        const Color(0xFFA78BFA).withValues(alpha: 0.15),
        const Color(0xFF8B5CF6).withValues(alpha: 0.0),
      ],
    );
  }

  void _drawBlob(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required List<Color> colors,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: colors,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.progress1 != progress1 ||
        oldDelegate.progress2 != progress2 ||
        oldDelegate.progress3 != progress3;
  }
}
