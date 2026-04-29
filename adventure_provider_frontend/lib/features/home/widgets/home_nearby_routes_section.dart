import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../track/data/models/track_model.dart';

/// Horizontal strip of nearby route cards backed by real [TrackModel] data.
class HomeNearbyRoutesSection extends StatelessWidget {
  const HomeNearbyRoutesSection({
    super.key,
    required this.tracks,
    this.isLoading = false,
    this.onSeeAll,
    this.onRouteTap,
  });

  final List<TrackModel> tracks;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final void Function(TrackModel track)? onRouteTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PUBLIC TRACKS',
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
                'See All',
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
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading && tracks.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
              strokeWidth: 2, color: AppColors.primaryLight),
        ),
      );
    }

    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'No tracks found',
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }

    return ScrollConfiguration(
      behavior: _NoScrollbarScrollBehavior(),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        primary: false,
        shrinkWrap: false,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(right: 4),
        itemCount: tracks.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return _TrackRouteCard(
            track: track,
            onTap: onRouteTap != null ? () => onRouteTap!(track) : null,
          );
        },
      ),
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

class _TrackRouteCard extends StatelessWidget {
  const _TrackRouteCard({required this.track, this.onTap});

  final TrackModel track;
  final VoidCallback? onTap;

  LinearGradient _gradientForType(String type) {
    switch (type) {
      case 'hiking':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D6A4F), Color(0xFF74C69D)],
        );
      case 'offroad':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5D4E37), Color(0xFFC9A66B)],
        );
      case 'cycling':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A535C), Color(0xFF4ECDC4)],
        );
      case 'running':
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6B2737), Color(0xFFE76F51)],
        );
      default:
        return const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B4332), Color(0xFF40916C)],
        );
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'hiking':
        return Icons.terrain;
      case 'cycling':
        return Icons.directions_bike;
      case 'running':
        return Icons.directions_run;
      case 'offroad':
        return Icons.landscape;
      default:
        return Icons.route;
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
          constraints: const BoxConstraints(minWidth: 175, maxWidth: 200),
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
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _gradientForType(track.type),
                          ),
                        ),
                      ),
                      Center(
                        child: Icon(
                          _iconForType(track.type),
                          size: 36,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _DifficultyBadge(difficulty: track.difficulty),
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
                        track.title,
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
                        '${track.distanceKm} km · ${track.durationFormatted}',
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
}

class _DifficultyBadge extends StatelessWidget {
  const _DifficultyBadge({required this.difficulty});

  final String difficulty;

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (difficulty.toLowerCase()) {
      'easy' => (
          'EASY',
          AppColors.homeHeaderIconFill,
          AppColors.primaryDark,
        ),
      'moderate' => (
          'MODERATE',
          const Color(0xFFF4E4D4),
          const Color(0xFF8B4513),
        ),
      'hard' => (
          'HARD',
          AppColors.danger.withValues(alpha: 0.14),
          AppColors.danger,
        ),
      _ => (
          difficulty.toUpperCase(),
          AppColors.homeHeaderIconFill,
          AppColors.textPrimary,
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
