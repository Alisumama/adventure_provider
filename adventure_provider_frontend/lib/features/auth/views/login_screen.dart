import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showIpSettingsSheet() {
    final ipController = TextEditingController(text: ApiConfig.currentIp ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _IpSettingsSheet(ipController: ipController),
    ).then((_) => ipController.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final topHeight = MediaQuery.sizeOf(context).height * 0.28;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: AppColors.darkSurface,
        onPressed: _showIpSettingsSheet,
        child: const Icon(Icons.settings, color: AppColors.primaryLight, size: 20),
      ),
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
                        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primaryDark, AppColors.primaryDark.withOpacity(0.8)]),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(width: 48, height: 48, child: Icon(Icons.terrain, size: 48, color: AppColors.primaryLight)),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome Back',
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        Text('Your adventure awaits', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AuthTextField(
                          controller: _emailController,
                          label: 'Email',
                          hint: 'Enter your email',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
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
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter your password',
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          isPasswordVisible: !_obscurePassword,
                          onTogglePassword: () => setState(() => _obscurePassword = !_obscurePassword),
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
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Get.toNamed(AppRoutes.forgotPassword),
                            child: Text('Forgot Password?', style: GoogleFonts.poppins(color: AppColors.primaryLight)),
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
                                child: Text(controller.errorMessage.value, style: const TextStyle(color: AppColors.danger)),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                        Obx(
                          () => AuthButton(
                            label: 'Login',
                            isLoading: controller.isLoading.value,
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                controller.login(_emailController.text.trim(), _passwordController.text);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ", style: GoogleFonts.poppins(color: AppColors.textSecondary)),
                            TextButton(
                              onPressed: () => Get.toNamed(AppRoutes.register),
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.poppins(color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
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

// ── IP Settings Bottom Sheet ──

class _IpSettingsSheet extends StatefulWidget {
  const _IpSettingsSheet({required this.ipController});

  final TextEditingController ipController;

  @override
  State<_IpSettingsSheet> createState() => _IpSettingsSheetState();
}

class _IpSettingsSheetState extends State<_IpSettingsSheet> {
  late List<String> _history;

  @override
  void initState() {
    super.initState();
    _history = ApiConfig.getIpHistory();
  }

  Future<void> _applyIp() async {
    final ip = widget.ipController.text.trim();
    if (ip.isEmpty) {
      Get.snackbar('Invalid', 'Please enter an IP address',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await ApiConfig.setIpAddress(ip);

    // Update the Dio instance's baseUrl at runtime.
    final dio = Get.find<Dio>();
    dio.options.baseUrl = ApiConfig.baseUrl;

    setState(() => _history = ApiConfig.getIpHistory());

    if (mounted) Navigator.of(context).pop();
    Get.snackbar('Server Updated', 'Base URL set to ${ApiConfig.baseUrl}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'SERVER SETTINGS',
            style: GoogleFonts.bebasNeue(
                fontSize: 18, color: Colors.white, letterSpacing: 1),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the server IP address (e.g. 192.168.1.5)',
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: widget.ipController,
            style: GoogleFonts.spaceMono(fontSize: 14, color: Colors.white),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '192.168.x.x',
              hintStyle:
                  GoogleFonts.spaceMono(fontSize: 14, color: Colors.white24),
              prefixIcon:
                  const Icon(Icons.dns_outlined, color: AppColors.primaryLight),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryLight),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _applyIp,
            child: Text('Apply',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white)),
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'RECENT',
              style: GoogleFonts.bebasNeue(
                  fontSize: 14, color: Colors.white54, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            ...List.generate(_history.length, (i) {
              final ip = _history[i];
              final isCurrent = ip == ApiConfig.currentIp;
              return Padding(
                padding: EdgeInsets.only(bottom: i < _history.length - 1 ? 6 : 0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        widget.ipController.text = ip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.primaryLight.withValues(alpha: 0.12)
                            : const Color(0xFF111827),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.primaryLight
                              : Colors.white12,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCurrent
                                ? Icons.check_circle
                                : Icons.history,
                            size: 16,
                            color: isCurrent
                                ? AppColors.primaryLight
                                : Colors.white38,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              ip,
                              style: GoogleFonts.spaceMono(
                                fontSize: 12,
                                color: isCurrent
                                    ? AppColors.primaryLight
                                    : Colors.white70,
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              'ACTIVE',
                              style: GoogleFonts.spaceMono(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryLight),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
