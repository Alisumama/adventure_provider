import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/widgets/auth_button.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../controllers/profile_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

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
      case 4:
        return 'Strong';
      case 3:
        return 'Good';
      case 2:
        return 'Fair';
      case 1:
        return 'Weak';
      default:
        return 'Weak';
    }
  }

  Color _barColor(int index, int level) {
    if (index >= level) {
      return AppColors.textSecondary.withValues(alpha: 0.4);
    }
    switch (level) {
      case 1:
        return AppColors.danger;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.primaryLight;
      case 4:
        return AppColors.success;
      default:
        return AppColors.textSecondary.withValues(alpha: 0.4);
    }
  }

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(ProfileController c) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final current = _currentCtrl.text;
    final newPass = _newCtrl.text;
    final confirm = _confirmCtrl.text;
    if (newPass != confirm) {
      Get.snackbar(
        'Mismatch',
        'New password and confirm password must match',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await c.changePassword(current, newPass);
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();
    final password = _newCtrl.text;
    final level = _strengthLevel(password);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Get.back<void>(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: Colors.white,
        ),
        title: Text(
          'CHANGE PASSWORD',
          style: GoogleFonts.bebasNeue(
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthTextField(
                          controller: _currentCtrl,
                          label: 'Current Password',
                          hint: 'Enter current password',
                          prefixIcon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _showCurrent,
                          onTogglePassword: () =>
                              setState(() => _showCurrent = !_showCurrent),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Current password is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _newCtrl,
                          label: 'New Password',
                          hint: 'Enter new password',
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          isPasswordVisible: _showNew,
                          onTogglePassword: () =>
                              setState(() => _showNew = !_showNew),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'New password is required';
                            }
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
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
                        const SizedBox(height: 12),
                        AuthTextField(
                          controller: _confirmCtrl,
                          label: 'Confirm New Password',
                          hint: 'Confirm new password',
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          isPasswordVisible: _showConfirm,
                          onTogglePassword: () =>
                              setState(() => _showConfirm = !_showConfirm),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Confirm password is required';
                            }
                            if (v != _newCtrl.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final loading = c.isUpdating.value;
                  return AuthButton(
                    label: 'Update Password',
                    isLoading: loading,
                    onPressed: () => _submit(c),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

