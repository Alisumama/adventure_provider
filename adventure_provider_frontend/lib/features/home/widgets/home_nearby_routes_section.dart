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

  static const _textPrimary = Color(0xFF1A1A2E);
  static const _primary = Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PUBLIC TRACKS',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                    color: _textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 50,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    'See All',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(height: 210, child: _buildContent()),
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
            strokeWidth: 2,
            color: AppColors.primaryLight,
          ),
        ),
      );
    }

    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'No tracks found',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
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
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final track = tracks[index];
          return SizedBox(
            width: 170,
            child: _TrackRouteCard(
              track: track,
              onTap: onRouteTap != null ? () => onRouteTap!(track) : null,
            ),
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

class _DifficultyStyle {
  const _DifficultyStyle(this.label, this.color);

  final String label;
  final Color color;
}

_DifficultyStyle _difficultyStyle(String raw) {
  switch (raw.toLowerCase()) {
    case 'easy':
      return const _DifficultyStyle('EASY', Color(0xFF2D6A4F));
    case 'moderate':
      return const _DifficultyStyle('MODERATE', Color(0xFFC17F3F));
    case 'hard':
      return _DifficultyStyle('HARD', AppColors.danger);
    default:
      final s = raw.trim().isEmpty
          ? 'TRACK'
          : raw.trim().replaceAll(RegExp(r'\s+'), ' ');
      return _DifficultyStyle(s.toUpperCase(), const Color(0xFF374151));
  }
}

String _trackTypeChip(TrackModel t) {
  final raw = t.type.trim();
  if (raw.isEmpty) return 'Track';
  if (raw.length <= 3) return raw.toUpperCase();
  return '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
}

class _TrackRouteCard extends StatelessWidget {
  const _TrackRouteCard({required this.track, this.onTap});

  final TrackModel track;
  final VoidCallback? onTap;

  static const _textPrimary = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final dStyle = _difficultyStyle(track.difficulty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 118,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      Icons.terrain,
                      color: Colors.white.withValues(alpha: 0.95),
                      size: 36,
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      decoration: BoxDecoration(
                        color: dStyle.color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: dStyle.color.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Text(
                        dStyle.label,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: Text(
                      '${track.distanceKm} km',
                      style: GoogleFonts.spaceMono(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 12,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          track.durationFormatted,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFF6B7280),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D6A4F).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        child: Text(
                          _trackTypeChip(track),
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D6A4F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
