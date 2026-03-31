import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../models/nearby_route_item.dart';

/// Horizontal strip of nearby route cards (sample data).
class HomeNearbyRoutesSection extends StatelessWidget {
  const HomeNearbyRoutesSection({
    super.key,
    this.routes = NearbyRouteItem.samples,
    this.onSeeAll,
    this.onRouteTap,
  });

  final List<NearbyRouteItem> routes;
  final VoidCallback? onSeeAll;
  final void Function(NearbyRouteItem route)? onRouteTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '🔍 Nearby Routes',
              style: GoogleFonts.bebasNeue(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.5,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'See All →',
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
        SizedBox(
          height: 160,
          child: ScrollConfiguration(
            behavior: _NoScrollbarScrollBehavior(),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              primary: false,
              shrinkWrap: false,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 4),
              itemCount: routes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final route = routes[index];
                return _NearbyRouteCard(
                  route: route,
                  onTap: onRouteTap != null ? () => onRouteTap!(route) : null,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class _NearbyRouteCard extends StatelessWidget {
  const _NearbyRouteCard({
    required this.route,
    this.onTap,
  });

  final NearbyRouteItem route;
  final VoidCallback? onTap;

  static LinearGradient _gradientFor(NearbyRouteItem route) {
    switch (route.kind) {
      case NearbyRouteKind.hike:
        if (route.difficulty == NearbyRouteDifficulty.hard) {
          return const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1B4332),
              Color(0xFF40916C),
            ],
          );
        }
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D6A4F),
            Color(0xFF74C69D),
          ],
        );
      case NearbyRouteKind.offroad:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF5D4E37),
            Color(0xFFC9A66B),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 175,
            maxWidth: 200,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.homeHeaderBorder, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 88,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _gradientFor(route),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          route.emoji,
                          style: const TextStyle(fontSize: 38),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _DifficultyBadge(difficulty: route.difficulty),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_formatKm(route.distanceKm)} · ⭐${route.rating.toStringAsFixed(1)}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatKm(double km) {
    if (km == km.roundToDouble()) {
      return '${km.toStringAsFixed(0)} km';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final NearbyRouteDifficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (difficulty) {
      NearbyRouteDifficulty.easy => (
          'EASY',
          AppColors.homeHeaderIconFill,
          AppColors.primaryDark,
        ),
      NearbyRouteDifficulty.moderate => (
          'MODERATE',
          const Color(0xFFF4E4D4),
          const Color(0xFF8B4513),
        ),
      NearbyRouteDifficulty.hard => (
          'HARD',
          AppColors.danger.withValues(alpha: 0.14),
          AppColors.danger,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
