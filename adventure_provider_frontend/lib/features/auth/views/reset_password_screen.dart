import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String get _email {
    final args = Get.arguments;
    if (args is Map && args.containsKey('email')) return args['email'] as String? ?? '';
    return '';
  }

  String get _otp {
    final args = Get.arguments;
    if (args is Map && args.containsKey('otp')) return args['otp'] as String? ?? '';
    return '';
  }

  int _strengthLevel(String password) {
    if (password.isEmpty) return 0;
    final len = password.length;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (len >= 12 && hasUpper && hasNumber && hasSymbol) return 4;
    if (len >= 9) return 3;
    if (len >= 6) return 2;
    if (len >= 3) return 1;
    return 0;
  }

  String _strengthLabel(String password) {
    switch (_strengthLevel(password)) {
      case 4: return 'Strong';
      case 3: return 'Good';
      case 2: return 'Fair';
      case 1: return 'Weak';
      default: return 'Weak';
    }
  }

  Color _barColor(int index, int level) {
    if (index >= level) return AppColors.textSecondary.withOpacity(0.4);
    switch (level) {
      case 1: return AppColors.danger;
      case 2: return AppColors.warning;
      case 3: return AppColors.primaryLight;
      case 4: return AppColors.success;
      default: return AppColors.textSecondary.withOpacity(0.4);
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final topHeight = MediaQuery.sizeOf(context).height * 0.35;
    final password = _passwordController.text;
    final level = _strengthLevel(password);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: topHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.primaryDark,
                            AppColors.primaryDark.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.key_outlined,
                          size: 60,
                          color: AppColors.primaryLight,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'New Password',
                          style: GoogleFonts.poppins(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make it strong and memorable',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthTextField(
                          controller: _passwordController,
                          label: 'New Password',
                          hint: 'Enter new password',
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          isPasswordVisible: !_obscurePassword,
                          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password is required';
                            if (v.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _confirmController,
                          label: 'Confirm Password',
                          hint: 'Confirm new password',
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          isPasswordVisible: !_obscureConfirm,
                          onTogglePassword: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (v) {
                            if (v != _passwordController.text) return 'Passwords do not match';
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: List.generate(4, (i) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(right: i < 3 ? 4 : 0),
                                child: Container(
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: _barColor(i, level),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _strengthLabel(password),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Obx(() {
                          if (controller.errorMessage.value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.danger.withOpacity(0.15),
                                  border: Border.all(color: AppColors.danger),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  controller.errorMessage.value,
                                  style: const TextStyle(color: AppColors.danger),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        Obx(() {
                          if (controller.successMessage.value.isNotEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  border: Border.all(color: AppColors.success),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  controller.successMessage.value,
                                  style: const TextStyle(color: AppColors.success),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        AuthButton(
                          label: 'Reset Password',
                          isLoading: controller.isLoading.value,
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              controller.resetPassword(
                                email: _email,
                                otp: _otp,
                                newPassword: _passwordController.text,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
