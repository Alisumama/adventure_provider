import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController(text: '');
  bool _obscurePassword = true;

  static const _bg = Color(0xFF1B4332);
  static const _accent = Color(0xFF52B788);
  static const _danger = Color(0xFFD62828);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showServerSettingsDialog() {
    final ipCtrl = TextEditingController(text: ApiConfig.currentIp ?? '');

    Get.dialog<void>(
      Dialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Server Settings',
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ipCtrl,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. 192.168.1.100',
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  prefixIcon: Icon(
                    Icons.router_outlined,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Get.back<void>();
                      },
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final ip = ipCtrl.text.trim();
                        if (ip.isEmpty) {
                          Get.snackbar(
                            'Invalid',
                            'Please enter an IP address',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                          return;
                        }
                        await ApiConfig.setIpAddress(ip);
                        Get.find<Dio>().options.baseUrl = ApiConfig.baseUrl;
                        Get.back<void>();
                        Get.snackbar(
                          'Server Updated',
                          'Base URL set to ${ApiConfig.baseUrl}',
                          snackPosition: SnackPosition.BOTTOM,
                          duration: const Duration(seconds: 3),
                        );
                      },
                      child: Text(
                        'Save',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(ipCtrl.dispose);
  }

  static final _fieldOutlineNormal = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: Colors.white.withValues(alpha: 0.2),
      width: 1,
    ),
  );

  static final _fieldOutlineFocused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(14),
    borderSide: BorderSide(
      color: Colors.white.withValues(alpha: 0.6),
      width: 1.5,
    ),
  );

  InputDecoration _loginFieldDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.4),
        letterSpacing: 2.0,
      ),
      filled: true,
      fillColor: Colors.transparent,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      prefixIcon: Icon(
        prefixIcon,
        color: Colors.white.withValues(alpha: 0.5),
        size: 18,
      ),
      suffixIcon: suffixIcon,
      border: _fieldOutlineNormal,
      enabledBorder: _fieldOutlineNormal,
      focusedBorder: _fieldOutlineFocused,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _danger.withValues(alpha: 0.8)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _danger.withValues(alpha: 0.9), width: 1.5),
      ),
      errorStyle: GoogleFonts.poppins(
        fontSize: 11,
        color: _danger,
        height: 1.2,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final mq = MediaQuery.of(context);
    final minScrollHeight = mq.size.height - mq.padding.vertical;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minScrollHeight),
                child: IntrinsicHeight(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBranding(),
                        const SizedBox(height: 48),
                        _buildMiddleForm(controller),
                        _buildBottomSignUp(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              minimum: EdgeInsets.zero,
              child: GestureDetector(
                onTap: _showServerSettingsDialog,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.settings_outlined,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBranding() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.terrain,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Adventure Providers',
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              fontSize: 32,
              color: Colors.white,
              letterSpacing: 2.0,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 30,
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 12),
              Text(
                'Explore. Track. Share.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 30,
                height: 1,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiddleForm(AuthController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
            cursorColor: Colors.white,
            decoration: _loginFieldDecoration(
              hint: 'E-MAIL',
              prefixIcon: Icons.mail_outline,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Email is required';
              }
              if (!v.contains('@')) {
                return 'Enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white,
            ),
            cursorColor: Colors.white,
            decoration: _loginFieldDecoration(
              hint: 'PASSWORD',
              prefixIcon: Icons.lock_outline,
              suffixIcon: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 40,
                  minHeight: 40,
                ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'Password is required';
              }
              if (v.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => Get.toNamed(AppRoutes.forgotPassword),
                child: Text(
                  'Forgot Password?',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Obx(
            () => GestureDetector(
              onTap: controller.isLoading.value
                  ? null
                  : () {
                      if (_formKey.currentState?.validate() ?? false) {
                        controller.login(
                          _emailController.text.trim(),
                          _passwordController.text,
                        );
                      }
                    },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Log In',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _bg,
                          letterSpacing: 1.5,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.white.withValues(alpha: 0.1),
          ),
          Obx(() {
            if (controller.errorMessage.value.isEmpty) {
              return const SizedBox.shrink();
            }
            return Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _danger.withValues(alpha: 0.4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: _danger,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      controller.errorMessage.value,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: _danger,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomSignUp() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Not a member? ',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          GestureDetector(
            onTap: () => Get.toNamed(AppRoutes.register),
            child: Text(
              'Join now',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _accent,
                decoration: TextDecoration.underline,
                decorationColor: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
