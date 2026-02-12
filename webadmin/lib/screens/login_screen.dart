import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_snackbar.dart';
import '../providers/auth_provider.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  // Animation controllers for floating blobs
  late AnimationController _blobController1;
  late AnimationController _blobController2;
  late AnimationController _blobController3;

  // Admin email constant
  static const String _adminEmail = 'adminstylezone@gmail.com';

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
    _passwordController.dispose();
    _blobController1.dispose();
    _blobController2.dispose();
    _blobController3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Animated gradient blobs background
          _buildAnimatedBackground(size),

          // Center login card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildLoginCard(context),
            ),
          ),
        ],
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

  Widget _buildLoginCard(BuildContext context) {
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
              // Logo
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
                'Quản trị',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 32),

              // Email field
              _buildLabel('Địa chỉ Email'),
              const SizedBox(height: 8),
              _buildEmailField(),
              const SizedBox(height: 20),

              // Password field
              _buildLabel('Mật khẩu'),
              const SizedBox(height: 8),
              _buildPasswordField(),
              const SizedBox(height: 16),

              // Remember me + Forgot password
              _buildRememberForgotRow(),
              const SizedBox(height: 24),

              // Sign In button
              _buildSignInButton(),

              // Error message
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.errorMessage != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        auth.errorMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFFF6B6B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
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
      child: const Center(child: Text('✨', style: TextStyle(fontSize: 30))),
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

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: 14, color: Colors.white),
      decoration: InputDecoration(
        hintText: '••••••••',
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
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) => setState(() => _rememberMe = v ?? false),
                activeColor: const Color(0xFF7C3AED),
                checkColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Ghi nhớ',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        // Forgot password
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _handleForgotPassword,
            child: Text(
              'Quên mật khẩu?',
              style: TextStyle(
                fontSize: 13,
                color: const Color(0xFFA78BFA),
                decoration: TextDecoration.underline,
                decorationColor: const Color(0xFFA78BFA),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInButton() {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
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
              onPressed: auth.isLoading ? null : _handleSignIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Đăng nhập',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppSnackBar.info(context, 'Vui lòng nhập email và mật khẩu');
      return;
    }

    // Check if the email is the authorized admin
    if (email.toLowerCase() != _adminEmail) {
      AppSnackBar.error(context, 'Tài khoản không có quyền truy cập quản trị');
      return;
    }

    final success = await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).signIn(email: email, password: password);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }
}

// ============================================================
// Custom painter for animated gradient blobs
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
