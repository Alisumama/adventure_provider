import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.isPasswordVisible = false,
    this.onTogglePassword,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.minLines,
    this.fillColor,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final bool isPasswordVisible;
  final VoidCallback? onTogglePassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;
  final int? minLines;
  /// When null, uses the default auth screen fill color.
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    const borderRadius = 14.0;
    const defaultBorderColor = Color(0xFF2D4A35);

    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      keyboardType: keyboardType,
      validator: validator,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white54,
        ),
        hintStyle: const TextStyle(
          fontSize: 14,
          color: Colors.white38,
        ),
        prefixIcon: Icon(
          prefixIcon,
          size: 20,
          color: AppColors.primaryLight,
        ),
        suffixIcon: isPassword && onTogglePassword != null
            ? IconButton(
                icon: Icon(
                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        filled: true,
        fillColor: fillColor ?? const Color(0xFF1A2A1F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: defaultBorderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: defaultBorderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryLight,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
        ),
      ),
    );
  }
}
