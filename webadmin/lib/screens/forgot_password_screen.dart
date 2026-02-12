import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_snackbar.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';


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
      AppSnackBar.error(context, 'Vui lÄ‚Â²ng nhĂ¡ÂºÂ­p email');
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
        'Email reset mĂ¡ÂºÂ­t khĂ¡ÂºÂ©u Ă„â€˜Ä‚Â£ Ă„â€˜Ă†Â°Ă¡Â»Â£c gĂ¡Â»Â­i. Vui lÄ‚Â²ng kiĂ¡Â»Æ’m tra hĂ¡Â»â„¢p thĂ†Â°.',
      );
      if (mounted) Navigator.pop(context);
    } else {
      AppSnackBar.error(
        context,
        authProvider.errorMessage ?? 'KhÄ‚Â´ng thĂ¡Â»Æ’ gĂ¡Â»Â­i email reset',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.darkBg : AppTheme.lightBg,
      appBar: AppBar(
        backgroundColor: isDarkMode
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : AppTheme.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? Colors.white : AppTheme.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'QuÄ‚Âªn mĂ¡ÂºÂ­t khĂ¡ÂºÂ©u',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : AppTheme.textDark,
          ),
        ),
        centerTitle: true,
        actions: const [],
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(size, isDarkMode),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildCard(context, isDarkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size, bool isDarkMode) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _blobController1,
        _blobController2,
        _blobController3,
      ]),
      builder: (context, child) {
        return CustomPaint(
          painter: _BlobPainter(
            progress1: _blobController1.value,
            progress2: _blobController2.value,
            progress3: _blobController3.value,
            isDarkMode: isDarkMode,
          ),
          size: size,
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, bool isDarkMode) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF1E293B).withValues(alpha: 0.8)
            : AppTheme.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withValues(alpha: 0.1)
              : AppTheme.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            if (!_emailSent) ...[
              _buildEmailField(),
              const SizedBox(height: 24),
              _buildResetButton(),
            ] else ...[
              _buildSuccessMessage(),
            ],
            const SizedBox(height: 24),
            _buildBackButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
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
          child: const Center(
            child: Text('Ä‘Å¸â€Â', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'QuÄ‚Âªn mĂ¡ÂºÂ­t khĂ¡ÂºÂ©u?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'NhĂ¡ÂºÂ­p email cĂ¡Â»Â§a bĂ¡ÂºÂ¡n Ă„â€˜Ă¡Â»Æ’ nhĂ¡ÂºÂ­n hĂ†Â°Ă¡Â»â€ºng dĂ¡ÂºÂ«n reset mĂ¡ÂºÂ­t khĂ¡ÂºÂ©u',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: 14, color: Colors.white),
          decoration: InputDecoration(
            hintText: 'admin@stylezone.com',
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.35),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C3AED),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: _isLoading ? null : _handleResetPassword,
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Text(
                'GĂ¡Â»Â­i Email Reset',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(
              Icons.check_circle_rounded,
              size: 48,
              color: Color(0xFF10B981),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Email Ă„â€˜Ä‚Â£ Ă„â€˜Ă†Â°Ă¡Â»Â£c gĂ¡Â»Â­i!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Vui lÄ‚Â²ng kiĂ¡Â»Æ’m tra hĂ¡Â»â„¢p thĂ†Â° cĂ¡Â»Â§a bĂ¡ÂºÂ¡n Ă„â€˜Ă¡Â»Æ’ nhĂ¡ÂºÂ­n hĂ†Â°Ă¡Â»â€ºng dĂ¡ÂºÂ«n reset mĂ¡ÂºÂ­t khĂ¡ÂºÂ©u.',
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
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () => Navigator.pop(context),
        child: Text(
          'Quay lĂ¡ÂºÂ¡i Ă„â€˜Ă„Æ’ng nhĂ¡ÂºÂ­p',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  final double progress1;
  final double progress2;
  final double progress3;
  final bool isDarkMode;

  _BlobPainter({
    required this.progress1,
    required this.progress2,
    required this.progress3,
    this.isDarkMode = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawBlob(
      canvas,
      center: Offset(
        size.width * (0.2 + 0.1 * sin(progress1 * pi * 2)),
        size.height * (0.3 + 0.12 * cos(progress1 * pi * 2)),
      ),
      radius: size.width * 0.35,
      colors: [
        const Color(0xFF7C3AED).withValues(alpha: 0.5),
        const Color(0xFF6D28D9).withValues(alpha: 0.2),
        const Color(0xFF7C3AED).withValues(alpha: 0.0),
      ],
    );

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
