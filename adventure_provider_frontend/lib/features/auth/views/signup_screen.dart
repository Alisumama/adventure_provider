import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../data/models/user_model.dart';
import '../widgets/auth_button.dart';
import '../widgets/auth_text_field.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _relationController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  File? _profileImageFile;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primaryLight),
                title: Text(
                  'Camera',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryLight),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final xFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 400,
    );
    if (xFile != null && mounted) {
      setState(() => _profileImageFile = File(xFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthController>();
    final topHeight = MediaQuery.sizeOf(context).height * 0.28;

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
                        const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.terrain,
                            size: 48,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Join the Adventure',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Create your explorer profile',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white60,
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
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: GestureDetector(
                            onTap: _showImageSourceSheet,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.darkSurface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.primaryLight,
                                  width: 2,
                                ),
                              ),
                              child: _profileImageFile != null
                                  ? ClipOval(
                                      child: Image.file(
                                        _profileImageFile!,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: AppColors.primaryLight,
                                      size: 22,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _nameController,
                          label: 'Full Name',
                          hint: 'Enter your full name',
                          prefixIcon: Icons.person_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
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
                            if (!v.contains('@') || !v.contains('.')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _phoneController,
                          label: 'Phone Number',
                          hint: 'Enter your phone number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              final digits = v.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 10) {
                                return 'Phone must be at least 10 digits';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _passwordController,
                          label: 'Password',
                          hint: 'Enter password (min 6 characters)',
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          isPasswordVisible: !_obscurePassword,
                          onTogglePassword: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
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
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirm Password',
                          hint: 'Confirm your password',
                          prefixIcon: Icons.lock_outlined,
                          isPassword: true,
                          isPasswordVisible: !_obscureConfirm,
                          onTogglePassword: () =>
                              setState(() => _obscureConfirm = !_obscureConfirm),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Expanded(
                              child: Divider(
                                color: Color(0xFF2D4A35),
                                thickness: 1,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'EMERGENCY CONTACT',
                                style: GoogleFonts.poppins(
                                  color: AppColors.primaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const Expanded(
                              child: Divider(
                                color: Color(0xFF2D4A35),
                                thickness: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _emergencyNameController,
                          label: 'Contact Name',
                          hint: 'Full name of contact',
                          prefixIcon: Icons.contact_emergency_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Contact name is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _emergencyPhoneController,
                          label: 'Contact Phone',
                          hint: 'Phone number',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Contact phone is required';
                            }
                            final digits = v.replaceAll(RegExp(r'\D'), '');
                            if (digits.length < 10) {
                              return 'At least 10 digits required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        AuthTextField(
                          controller: _relationController,
                          label: 'Relation',
                          hint: 'e.g. Father, Friend',
                          prefixIcon: Icons.people_outlined,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Relation is required';
                            }
                            return null;
                          },
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
                        Obx(
                          () => AuthButton(
                            label: 'Create Account',
                            isLoading: controller.isLoading.value,
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                controller.register(
                                  name: _nameController.text.trim(),
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text,
                                  phone: _phoneController.text.trim().isEmpty
                                      ? null
                                      : _phoneController.text.trim(),
                                  emergencyContact: EmergencyContactModel(
                                    name: _emergencyNameController.text.trim(),
                                    phone: _emergencyPhoneController.text.trim(),
                                    relation: _relationController.text.trim(),
                                  ),
                                  profileImagePath: _profileImageFile?.path,
                                );
                              }
                            },
                          ),
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
