import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/shell_layout.dart';
import '../../../core/theme/app_colors.dart';

class CommunityPlaceholderScreen extends StatelessWidget {
  const CommunityPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Padding(
        padding: const EdgeInsets.only(bottom: kSosFabScrollBottomInset),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.group_rounded,
                size: 64,
                color: AppColors.primaryLight,
              ),
              const SizedBox(height: 16),
              Text(
                'Community Coming Soon',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
