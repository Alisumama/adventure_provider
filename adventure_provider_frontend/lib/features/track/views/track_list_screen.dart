import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/constants/shell_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/track_controller.dart';
import '../data/models/track_model.dart';

class TrackListScreen extends StatefulWidget {
  const TrackListScreen({super.key});

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  static const List<({String key, String label})> _filters = [
    (key: 'all', label: 'All'),
    (key: 'hiking', label: 'Hiking'),
    (key: 'offroad', label: 'Offroad'),
    (key: 'cycling', label: 'Cycling'),
    (key: 'running', label: 'Running'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.find<TrackController>().fetchMyTracks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TrackController>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'MY TRACKS',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Get.toNamed(AppRoutes.recordTrack),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                    return Obx(() {
                    final active = c.selectedFilter.value == f.key;
                    return ChoiceChip(
                      label: Text(
                        f.label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: active ? Colors.white : Colors.white70,
                        ),
                      ),
                      selected: active,
                      onSelected: (_) => c.selectedFilter.value = f.key,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.darkSurface,
                      side: BorderSide(
                        color: active ? AppColors.primary : AppColors.darkSurface,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                      showCheckmark: false,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Obx(() {
                final loading = c.isLoading.value;
                final filter = c.selectedFilter.value;
                final all = c.myTracks.toList();
                final tracks = filter == 'all'
                    ? all
                    : all
                        .where(
                          (t) => t.type.toLowerCase() == filter,
                        )
                        .toList();

                if (loading && all.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                    ),
                  );
                }

                if (tracks.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.terrain,
                            size: 72,
                            color: AppColors.primaryLight.withValues(alpha: 0.6),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tracks yet. Start your first adventure!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        kSosFabScrollBottomInset,
                      ),
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TrackCard(
                            track: track,
                            onTap: () {
                              final id = track.id;
                              if (id == null || id.isEmpty) return;
                              Get.toNamed(AppRoutes.trackDetailNamed(id));
                            },
                          ),
                        );
                      },
                    ),
                    if (loading)
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primaryLight.withValues(alpha: 0.9),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({
    required this.track,
    required this.onTap,
  });

  final TrackModel track;
  final VoidCallback onTap;

  static IconData _typeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'hiking':
        return Icons.hiking;
      case 'offroad':
        return Icons.directions_car;
      case 'cycling':
        return Icons.directions_bike;
      case 'running':
        return Icons.directions_run;
      default:
        return Icons.map_rounded;
    }
  }

  static Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'moderate':
        return AppColors.accent;
      case 'hard':
        return AppColors.danger;
      default:
        return AppColors.textSecondary;
    }
  }

  static String _formatDate(DateTime? d) {
    if (d == null) return '—';
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(track.difficulty);
    final cover = track.coverImage;

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      track.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: diffColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: diffColor.withValues(alpha: 0.6)),
                    ),
                    child: Text(
                      track.difficulty.isEmpty
                          ? '—'
                          : track.difficulty[0].toUpperCase() +
                              track.difficulty.substring(1).toLowerCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: diffColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: cover != null && cover.isNotEmpty
                      ? Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _TypeGradientPlaceholder(
                            icon: _typeIcon(track.type),
                          ),
                        )
                      : _TypeGradientPlaceholder(
                          icon: _typeIcon(track.type),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatPill(
                      icon: Icons.straighten,
                      text: '${track.distanceKm} km',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatPill(
                      icon: Icons.timer_outlined,
                      text: track.durationFormatted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatPill(
                      icon: Icons.directions_walk,
                      text: '${track.steps}',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _StatPill(
                      icon: Icons.local_fire_department_outlined,
                      text: '${track.calories}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(track.createdAt),
                      style: GoogleFonts.spaceMono(
                        fontSize: 11,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 16, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        '${track.likesCount}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(Icons.bookmark_border, size: 16, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(
                        '${track.savesCount}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeGradientPlaceholder extends StatelessWidget {
  const _TypeGradientPlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 48,
          color: Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.primaryLight),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceMono(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
