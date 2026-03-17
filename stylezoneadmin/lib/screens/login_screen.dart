import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:web/web.dart' as web;
import '../utils/app_snackbar.dart';
import '../providers/auth_provider.dart';
import '../widgets/stylezone_loading_overlay.dart';
import 'dashboard_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
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
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return StylezoneLoadingOverlay(
            isLoading: auth.isLoading,
            message: 'Đang đăng nhập...',
            child: Stack(
              children: [
                // Static gradient background
                _buildStaticBackground(),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildLoginCard(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaticBackground() {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.6, 0.4),
            radius: 1.2,
            colors: [
              Color(0xFF1E1346),
              Color(0xFF0F172A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Purple glow — bottom left
            Positioned(
              left: -80,
              bottom: -60,
              child: Container(
                width: 360,
                height: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF5B21B6).withValues(alpha: 0.35),
                      const Color(0xFF5B21B6).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Pink glow — top right
            Positioned(
              right: -60,
              top: -40,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFEC4899).withValues(alpha: 0.18),
                      const Color(0xFFEC4899).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Indigo glow — center bottom
            Positioned(
              right: 60,
              bottom: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      const Color(0xFF3B82F6).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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
              _buildLabel('Tài khoản'),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        'assets/logo.png',
        width: 100,
        height: 100,
        fit: BoxFit.contain,
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
    return GestureDetector(
      onTap: () => _emailFocus.requestFocus(),
      child: TextField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofocus: true,
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
    ),
    ),
    );
  }

  Widget _buildPasswordField() {
    return GestureDetector(
      onTap: () => _passwordFocus.requestFocus(),
      child: TextField(
        controller: _passwordController,
        focusNode: _passwordFocus,
        obscureText: _obscurePassword,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _handleSignIn(),
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
      StylezonePageRoute(page: const ForgotPasswordScreen()),
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

    // Check if user is in `admins` collection
    final user = authProvider.user;
    if (user == null) return;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();

      if (!adminDoc.exists) {
        // Not an admin → sign out and show error
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
        StylezonePageRoute(page: const DashboardScreen()),
      );
    }
  }
}
