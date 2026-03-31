import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/upcoming_plan_item.dart';

/// Vertical list of upcoming plan cards (sample data).
class HomeUpcomingPlansSection extends StatelessWidget {
  const HomeUpcomingPlansSection({
    super.key,
    this.plans = UpcomingPlanItem.samples,
    this.onViewAll,
    this.onPlanTap,
  });

  final List<UpcomingPlanItem> plans;
  final VoidCallback? onViewAll;
  final void Function(UpcomingPlanItem plan)? onPlanTap;

  static const List<Color> _avatarFillColors = [
    AppColors.primary,
    Color(0xFF8B6914),
    Color(0xFF2A9D8F),
    AppColors.primaryDark,
    Color(0xFFB08968),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '📅 Upcoming Plans',
              style: GoogleFonts.bebasNeue(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'View All →',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < plans.length; i++) ...[
          _UpcomingPlanCard(
            plan: plans[i],
            avatarColors: _avatarFillColors,
            onTap: onPlanTap != null ? () => onPlanTap!(plans[i]) : null,
          ),
          if (i < plans.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _UpcomingPlanCard extends StatelessWidget {
  const _UpcomingPlanCard({
    required this.plan,
    required this.avatarColors,
    this.onTap,
  });

  final UpcomingPlanItem plan;
  final List<Color> avatarColors;
  final VoidCallback? onTap;

  static const double _avatarSize = 22;
  static const double _avatarOverlap = 6;

  @override
  Widget build(BuildContext context) {
    final initials = plan.participantInitials;
    final stackWidth = initials.isEmpty
        ? 0.0
        : _avatarSize + (initials.length - 1) * (_avatarSize - _avatarOverlap);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.homeHeaderBorder, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.homeHeaderIconFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${plan.dayOfMonth}',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      plan.monthLabel,
                      style: GoogleFonts.spaceMono(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.timeLabel} · ${plan.joinedCount} joined',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (initials.isNotEmpty) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: stackWidth,
                  height: _avatarSize,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      for (var i = 0; i < initials.length; i++)
                        Positioned(
                          left: i * (_avatarSize - _avatarOverlap),
                          child: _PlanAvatarCircle(
                            letter: initials[i],
                            fill: avatarColors[i % avatarColors.length],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanAvatarCircle extends StatelessWidget {
  const _PlanAvatarCircle({
    required this.letter,
    required this.fill,
  });

  final String letter;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final ch = letter.isNotEmpty ? letter[0].toUpperCase() : '?';
    return Container(
      width: _UpcomingPlanCard._avatarSize,
      height: _UpcomingPlanCard._avatarSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: fill,
        border: Border.all(color: AppColors.surface, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        ch,
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.surface,
          height: 1,
        ),
      ),
    );
  }
}
