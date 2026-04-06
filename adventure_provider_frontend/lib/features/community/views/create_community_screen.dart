import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

/// Placeholder until create-community form is implemented.
class CreateCommunityScreen extends StatelessWidget {
  const CreateCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        title: const Text('Create community'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Center(
        child: Text(
          'Create community form — coming soon',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
