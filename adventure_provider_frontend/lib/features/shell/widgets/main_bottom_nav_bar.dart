import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/controllers/navigation_controller.dart';
import '../../../core/theme/app_colors.dart';

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({super.key});

  static const _tabs = <_TabSpec>[
    _TabSpec(
      iconFilled: Icons.home_rounded,
      iconOutlined: Icons.home_outlined,
      label: 'HOME',
    ),
    _TabSpec(
      iconFilled: Icons.map_rounded,
      iconOutlined: Icons.map_outlined,
      label: 'TRACK',
    ),
    _TabSpec(
      iconFilled: Icons.group_rounded,
      iconOutlined: Icons.group_outlined,
      label: 'GROUPS',
    ),
    _TabSpec(
      iconFilled: Icons.forum_rounded,
      iconOutlined: Icons.forum_outlined,
      label: 'COMMUNITY',
    ),
    _TabSpec(
      iconFilled: Icons.person_rounded,
      iconOutlined: Icons.person_outlined,
      label: 'PROFILE',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = Get.find<NavigationController>();

    return Material(
      color: AppColors.surface,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.homeHeaderBorder, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Obx(() {
              final active = nav.currentIndex.value;
              return Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _NavTabItem(
                        spec: _tabs[i],
                        isActive: active == i,
                        onTap: () => nav.changePage(i),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.iconFilled,
    required this.iconOutlined,
    required this.label,
  });

  final IconData iconFilled;
  final IconData iconOutlined;
  final String label;
}

class _NavTabItem extends StatelessWidget {
  const _NavTabItem({
    required this.spec,
    required this.isActive,
    required this.onTap,
  });

  final _TabSpec spec;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        isActive ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      splashColor: AppColors.primaryLight.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.translate(
              offset: Offset(0, isActive ? -2 : 0),
              child: Icon(
                isActive ? spec.iconFilled : spec.iconOutlined,
                size: 22,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              spec.label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 4,
              child: Center(
                child: isActive
                    ? Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
