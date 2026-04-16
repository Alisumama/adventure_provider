import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class CreateCommunityEventScreen extends StatelessWidget {
  const CreateCommunityEventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final communityId = Get.arguments?.toString() ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF7F5F0),
      appBar: AppBar(
        title: const Text('Create event'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'TODO: Create event form\n\ncommunityId=$communityId',
          style: GoogleFonts.poppins(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}

