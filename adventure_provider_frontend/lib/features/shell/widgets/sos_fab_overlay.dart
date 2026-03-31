import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'emergency_sos_bottom_sheet.dart';

/// Red SOS FAB fixed above the bottom navigation bar (see [MainShellScreen] Stack).
class SosFabOverlay extends StatelessWidget {
  const SosFabOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      right: 16,
      bottom: 80,
      child: _SosFab(),
    );
  }
}

class _SosFab extends StatefulWidget {
  const _SosFab();

  @override
  State<_SosFab> createState() => _SosFabState();
}

class _SosFabState extends State<_SosFab> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = CurvedAnimation(
          parent: _controller,
          curve: Curves.easeInOut,
        ).value;
        final blur = 6 + t * 14;
        final spread = t * 4;
        final alpha = 0.26 + t * 0.38;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: showEmergencySosBottomSheet,
            customBorder: const CircleBorder(),
            child: Ink(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.danger.withValues(alpha: alpha),
                    blurRadius: blur,
                    spreadRadius: spread,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.sos,
                  color: AppColors.surface,
                  size: 26,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
