import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/shell_layout.dart';
import '../../../core/theme/app_colors.dart';
import 'emergency_sos_bottom_sheet.dart';

/// Emergency SOS FAB: uses [Material] + [CircleBorder] + animated elevation so
/// the pulse shadow stays circular (plain [BoxDecoration.boxShadow] often reads as a square glow).
class SosFab extends StatefulWidget {
  const SosFab({super.key});

  @override
  State<SosFab> createState() => _SosFabState();
}

class _SosFabState extends State<SosFab> with SingleTickerProviderStateMixin {
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

  void _onTap() {
    HapticFeedback.mediumImpact();
    showEmergencySosBottomSheet();
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
        final elevation = 4.0 + t * 12.0;

        return Material(
          color: AppColors.danger,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          elevation: elevation,
          shadowColor: AppColors.danger.withValues(alpha: 0.55),
          surfaceTintColor: Colors.transparent,
          type: MaterialType.button,
          child: InkWell(
            onTap: _onTap,
            customBorder: const CircleBorder(),
            splashColor: AppColors.surface.withValues(alpha: 0.2),
            highlightColor: AppColors.surface.withValues(alpha: 0.08),
            child: SizedBox(
              width: kSosFabDiameter,
              height: kSosFabDiameter,
              child: Icon(
                Icons.sos,
                color: AppColors.surface,
                size: 26,
                semanticLabel: 'SOS emergency',
              ),
            ),
          ),
        );
      },
    );
  }
}
