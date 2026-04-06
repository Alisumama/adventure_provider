import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

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
                        color: AppColors.surface,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Material(
                    color: AppColors.darkSurface,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => c.fetchMyTracks(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primaryLight,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Get.toNamed(AppRoutes.recordTrack),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(Icons.add, color: AppColors.surface, size: 22),
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
                          color: active
                              ? AppColors.surface
                              : AppColors.homeGreetingGrey,
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
                  return RefreshIndicator(
                    color: AppColors.primaryLight,
                    onRefresh: () => c.fetchMyTracks(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: constraints.maxHeight > 200
                                  ? constraints.maxHeight * 0.65
                                  : 280,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.terrain,
                                        size: 72,
                                        color: AppColors.primaryLight
                                            .withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No tracks yet. Start your first adventure!',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          color: AppColors.homeGreetingGrey,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  );
                }

                return Stack(
                  children: [
                    RefreshIndicator(
                      color: AppColors.primaryLight,
                      onRefresh: () => c.fetchMyTracks(),
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                              color: AppColors.primaryLight.withValues(
                                alpha: 0.9,
                              ),
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

  static Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return AppColors.success;
      case 'moderate':
        return AppColors.warning;
      case 'hard':
        return AppColors.danger;
      default:
        return AppColors.homeGreetingGrey;
    }
  }

  static String _difficultyLabel(String d) {
    if (d.isEmpty) return '—';
    return '${d[0].toUpperCase()}${d.substring(1).toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(track.difficulty);

    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 160,
                width: double.infinity,
                child: _TrackRoutePreviewMap(track: track),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    track.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.surface,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${track.distanceKm} km',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.homeGreetingGrey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          track.durationFormatted,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.homeGreetingGrey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: diffColor.withValues(alpha: 0.55),
                          ),
                        ),
                        child: Text(
                          _difficultyLabel(track.difficulty),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        track.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: AppColors.homeGreetingGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${track.likesCount}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          color: AppColors.surface,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        track.isSaved
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        size: 16,
                        color: AppColors.homeGreetingGrey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${track.savesCount}',
                        style: GoogleFonts.spaceMono(
                          fontSize: 11,
                          color: AppColors.surface,
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

/// OSM preview: route polyline, start/end dots, bounds fit. Non-interactive.
class _TrackRoutePreviewMap extends StatefulWidget {
  const _TrackRoutePreviewMap({required this.track});

  final TrackModel track;

  @override
  State<_TrackRoutePreviewMap> createState() => _TrackRoutePreviewMapState();
}

class _TrackRoutePreviewMapState extends State<_TrackRoutePreviewMap> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<ll.LatLng> _pathPoints() {
    return widget.track.geoPath
        .map((p) => ll.LatLng(p.latitude, p.longitude))
        .toList(growable: false);
  }

  ll.LatLng? _startPoint() {
    final path = _pathPoints();
    if (path.isNotEmpty) return path.first;
    final s = widget.track.startPoint;
    if (s == null) return null;
    return ll.LatLng(s.latitude, s.longitude);
  }

  ll.LatLng? _endPoint() {
    final path = _pathPoints();
    if (path.length >= 2) return path.last;
    if (path.length == 1) return path.first;
    final e = widget.track.endPoint;
    if (e == null) return null;
    return ll.LatLng(e.latitude, e.longitude);
  }

  List<ll.LatLng> _fitPoints() {
    final pts = <ll.LatLng>[];
    pts.addAll(_pathPoints());
    final s = widget.track.startPoint;
    final e = widget.track.endPoint;
    if (s != null) {
      pts.add(ll.LatLng(s.latitude, s.longitude));
    }
    if (e != null) {
      pts.add(ll.LatLng(e.latitude, e.longitude));
    }
    return pts;
  }

  void _fitBounds() {
    final pts = _fitPoints();
    if (pts.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        if (pts.length == 1) {
          _mapController.move(pts.first, 14);
          return;
        }
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(pts),
            padding: const EdgeInsets.all(10),
          ),
        );
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final path = _pathPoints();
    final start = _startPoint();
    final end = _endPoint();
    final hasPath = path.length >= 2;
    final initialCenter = start ?? end ?? const ll.LatLng(20, 0);
    final initialZoom = (start != null || end != null) ? 12.0 : 2.0;

    if (start == null && end == null && path.isEmpty) {
      return ColoredBox(
        color: AppColors.mapPreviewBackground,
        child: Center(
          child: Icon(
            Icons.route,
            size: 40,
            color: AppColors.homeGreetingGrey.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    return FlutterMap(
      key: ValueKey<String>('list_map_${widget.track.id}_${path.length}'),
      mapController: _mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        backgroundColor: AppColors.mapPreviewBackground,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
        onMapReady: _fitBounds,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'adventure_provider_frontend',
        ),
        if (hasPath)
          PolylineLayer(
            polylines: [
              Polyline(
                points: path,
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            ],
          ),
        CircleLayer(
          circles: [
            if (start != null)
              CircleMarker(
                point: start,
                radius: 5,
                color: AppColors.primary,
                borderStrokeWidth: 1.5,
                borderColor: AppColors.surface,
              ),
            if (end != null &&
                (start == null ||
                    end.latitude != start.latitude ||
                    end.longitude != start.longitude))
              CircleMarker(
                point: end,
                radius: 5,
                color: AppColors.danger,
                borderStrokeWidth: 1.5,
                borderColor: AppColors.surface,
              ),
          ],
        ),
      ],
    );
  }
}
