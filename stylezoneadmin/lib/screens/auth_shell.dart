import 'dart:convert';
import 'dart:ui';
import 'dart:ui_web' as ui_web;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;

import '../providers/auth_provider.dart';
import '../utils/app_snackbar.dart';
import '../widgets/stylezone_loading_overlay.dart';
import 'dashboard_screen.dart';

/// Shared auth shell that hosts a single HTML <video> background.
/// Login and ForgotPassword forms are swapped inside without rebuilding
/// the video, so it continues playing seamlessly.
class AuthShell extends StatefulWidget {
  const AuthShell({super.key});

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  static const _viewType = 'auth-video-bg';
  static bool _viewRegistered = false;

  /// 0 = Login, 1 = Forgot Password
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _registerVideoView();
  }

  void _registerVideoView() {
    if (_viewRegistered) return;
    _viewRegistered = true;

    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final container = web.document.createElement('div') as web.HTMLDivElement;
      container.style
        ..width = '100vw'
        ..height = '100vh'
        ..overflow = 'hidden'
        ..position = 'fixed'
        ..top = '0'
        ..left = '0'
        ..margin = '0'
        ..padding = '0';

      final video =
          web.document.createElement('video') as web.HTMLVideoElement;
      video.src = 'assets/login_bg.mp4';
      video.autoplay = true;
      video.loop = true;
      video.muted = true;
      video.setAttribute('playsinline', 'true');
      video.style
        ..position = 'absolute'
        ..top = '0'
        ..left = '0'
        ..width = '100%'
        ..height = '100%'
        ..objectFit = 'cover';

      // Dark overlay for readability
      final overlay = web.document.createElement('div') as web.HTMLDivElement;
      overlay.style
        ..position = 'absolute'
        ..top = '0'
        ..left = '0'
        ..width = '100%'
        ..height = '100%'
        ..backgroundColor = 'rgba(15, 23, 42, 0.55)';

      container.appendChild(video);
      container.appendChild(overlay);

      return container;
    });
  }

  void _goToForgotPassword() {
    setState(() => _currentPage = 1);
  }

  void _goToLogin() {
    setState(() => _currentPage = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Video background — never rebuilds when switching forms
          const Positioned.fill(
            child: HtmlElementView(viewType: _viewType),
          ),

          // Form content with animated transition
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: _currentPage == 0
                ? _LoginForm(
                    key: const ValueKey('login'),
                    onForgotPassword: _goToForgotPassword,
                  )
                : _ForgotPasswordForm(
                    key: const ValueKey('forgot'),
                    onBackToLogin: _goToLogin,
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// LOGIN FORM
// ─────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  const _LoginForm({super.key, required this.onForgotPassword});

  final VoidCallback onForgotPassword;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  void _loadSavedCredentials() {
    try {
      // Migrate: xóa key cũ nếu từng lưu password plaintext
      final oldData = web.window.localStorage.getItem('admin_remember');
      if (oldData != null) {
        web.window.localStorage.removeItem('admin_remember');
      }

      final savedEmail = web.window.localStorage.getItem('admin_email');
      if (savedEmail != null && savedEmail.isNotEmpty) {
        _emailController.text = savedEmail;
        setState(() => _rememberMe = true);
      }
    } catch (_) {}
  }

  void _saveCredentials() {
    if (_rememberMe) {
      // Chỉ lưu email — KHÔNG lưu password
      web.window.localStorage.setItem('admin_email', _emailController.text.trim());
    } else {
      web.window.localStorage.removeItem('admin_email');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return StylezoneLoadingOverlay(
          isLoading: auth.isLoading,
          message: 'Đang đăng nhập...',
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildLoginCard(context, auth),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginCard(BuildContext context, AuthProvider auth) {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'assets/logo.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 12),

              _buildLabel('Tài khoản'),
              const SizedBox(height: 8),
              _buildEmailField(),
              const SizedBox(height: 20),

              _buildLabel('Mật khẩu'),
              const SizedBox(height: 8),
              _buildPasswordField(),
              const SizedBox(height: 16),

              _buildRememberForgotRow(),
              const SizedBox(height: 24),

              _buildSignInButton(auth),

              if (auth.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    auth.errorMessage!,
                    style: TextStyle(
                      fontSize: 13,
                      color: const Color(0xFFFF6B6B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Logo is now built inline in _buildLoginCard

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
      textInputAction: TextInputAction.next,
      style: TextStyle(fontSize: 14, color: Colors.white),
      decoration: _inputDecoration('name@stylezone.com'),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleSignIn(),
      style: TextStyle(fontSize: 14, color: Colors.white),
      decoration: _inputDecoration('••••••••').copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.white.withValues(alpha: 0.5),
            size: 20,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontSize: 14,
        color: Colors.white.withValues(alpha: 0.35),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
    );
  }

  Widget _buildRememberForgotRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (v) {
                  setState(() => _rememberMe = v ?? false);
                  if (!_rememberMe) {
                    web.window.localStorage.removeItem('admin_email');
                  }
                },
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
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onForgotPassword,
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

  Widget _buildSignInButton(AuthProvider auth) {
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
  }

  void _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      AppSnackBar.info(context, 'Vui lòng nhập email và mật khẩu');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _saveCredentials();
    final success = await authProvider.signIn(email: email, password: password);

    if (!success || !mounted) return;

    final user = authProvider.user;
    if (user == null) return;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) {
        await authProvider.signOut();
        if (mounted) {
          AppSnackBar.error(
              context, 'Tài khoản không có quyền truy cập quản trị');
        }
        return;
      }
    } catch (e) {
      await authProvider.signOut();
      if (mounted) {
        AppSnackBar.error(context, 'Lỗi kiểm tra quyền: $e');
      }
      return;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }
}

// ─────────────────────────────────────────────────
// FORGOT PASSWORD FORM
// ─────────────────────────────────────────────────
class _ForgotPasswordForm extends StatefulWidget {
  const _ForgotPasswordForm({super.key, required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  State<_ForgotPasswordForm> createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<_ForgotPasswordForm> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
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
    return StylezoneLoadingOverlay(
      isLoading: _isLoading,
      message: 'Đang gửi email...',
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _buildCard(),
        ),
      ),
    );
  }

  Widget _buildCard() {
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
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'assets/logo.png',
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Nhập email của bạn để nhận hướng dẫn\nreset mật khẩu',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 12),

              if (!_emailSent) ...[
                _buildLabel('Tài khoản'),
                const SizedBox(height: 8),
                _buildEmailField(),
                const SizedBox(height: 24),
                _buildResetButton(),
                const SizedBox(height: 16),
              ] else ...[
                _buildSuccessMessage(),
                const SizedBox(height: 24),
              ],

              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: widget.onBackToLogin,
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
              ),
            ],
          ),
        ),
      ),
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.15)),
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
}
