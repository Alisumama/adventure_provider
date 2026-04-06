import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/theme/app_colors.dart';
import '../controllers/track_controller.dart';
import '../data/models/track_model.dart' as tm;
import '../track_flag_type_style.dart';
import 'add_flag_bottom_sheet.dart';

void _showLiveFlagTooltip(BuildContext context, tm.LiveTrackFlag flag) {
  final title = trackFlagLabel(flag.type);
  final raw = flag.description?.trim();
  final body = raw == null || raw.isEmpty ? 'No description added.' : raw;

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  TrackFlagTypeCircleIcon(
                    type: flag.type,
                    size: 32,
                    iconSize: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                body,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  height: 1.35,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// OSM live map during recording: path, location dot, timer, stats, flags, end.
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  Worker? _pathWorker;
  /// Observable so the location dot rebuilds when GPS resolves (path may still be empty).
  final Rxn<ll.LatLng> _gpsDot = Rxn<ll.LatLng>();

  /// After [Geolocator] resolves; map is built only when true.
  bool _mapBootstrapComplete = false;
  /// Non-null only when GPS succeeded; never a placeholder coordinate.
  ll.LatLng? _deviceCenter;

  static const double _kStreetTrailZoom = 16.0;
  static const double _kFallbackWorldZoom = 2.0;

  static String _formatHms(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${sec.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    final c = Get.find<TrackController>();
    _pathWorker = ever(c.pathPoints, (_) => _followLastPoint());
    _loadInitialMapCenter();
  }

  Future<void> _loadInitialMapCenter() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        Get.snackbar(
          'Location off',
          'Turn on location services to center the map on you. Showing world view.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.darkSurface,
          colorText: AppColors.surface,
        );
        setState(() {
          _deviceCenter = null;
          _mapBootstrapComplete = true;
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final target = ll.LatLng(pos.latitude, pos.longitude);
      setState(() {
        _deviceCenter = target;
        _gpsDot.value = target;
        _mapBootstrapComplete = true;
      });
    } catch (_) {
      if (!mounted) return;
      Get.snackbar(
        'Could not get location',
        'We could not read your position. You can still record and move the map.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.darkSurface,
        colorText: AppColors.surface,
      );
      setState(() {
        _deviceCenter = null;
        _mapBootstrapComplete = true;
      });
    }
  }

  void _followLastPoint() {
    if (!_mapBootstrapComplete) return;
    final c = Get.find<TrackController>();
    if (c.pathPoints.isEmpty) return;
    final p = c.pathPoints.last;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      double z = _kStreetTrailZoom;
      try {
        z = _mapController.camera.zoom;
      } catch (_) {}
      _mapController.move(ll.LatLng(p.latitude, p.longitude), z);
    });
  }

  void _onMapReadyCenterDevice() {
    final center = _deviceCenter;
    if (center == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(center, _kStreetTrailZoom);
      } catch (_) {}
    });
  }

  MapOptions _buildMapOptions() {
    void onTap(TapPosition tapPosition, ll.LatLng latLng) {
      Get.find<TrackController>().onMapTap(
        tm.LatLng(latLng.latitude, latLng.longitude),
      );
    }

    final center = _deviceCenter;
    if (center != null) {
      return MapOptions(
        initialCenter: center,
        initialZoom: _kStreetTrailZoom,
        backgroundColor: AppColors.mapPreviewBackground,
        onMapReady: _onMapReadyCenterDevice,
        onTap: onTap,
      );
    }

    return MapOptions(
      initialCameraFit: CameraFit.bounds(
        bounds: LatLngBounds(
          const ll.LatLng(-85, -180),
          const ll.LatLng(85, 180),
        ),
        maxZoom: _kFallbackWorldZoom,
        minZoom: _kFallbackWorldZoom,
      ),
      backgroundColor: AppColors.mapPreviewBackground,
      onTap: onTap,
    );
  }

  @override
  void dispose() {
    _pathWorker?.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TrackController>();

    if (!_mapBootstrapComplete) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: const Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryLight,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: _buildMapOptions(),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'adventure_provider_frontend',
              ),
              Obx(() {
                final pts = c.pathPoints
                    .map((p) => ll.LatLng(p.latitude, p.longitude))
                    .toList(growable: false);
                if (pts.length < 2) {
                  return const SizedBox.shrink();
                }
                return PolylineLayer(
                  polylines: [
                    Polyline(
                      points: pts,
                      color: AppColors.primary,
                      strokeWidth: 4,
                    ),
                  ],
                );
              }),
              Obx(() {
                final c0 = Get.find<TrackController>();
                c0.currentLocation.value;
                c0.pathPoints.length;
                _gpsDot.value;
                ll.LatLng? dot;
                final cl = c0.currentLocation.value;
                if (cl != null) {
                  dot = ll.LatLng(cl.latitude, cl.longitude);
                } else if (c0.pathPoints.isNotEmpty) {
                  final p = c0.pathPoints.last;
                  dot = ll.LatLng(p.latitude, p.longitude);
                } else {
                  dot = _gpsDot.value;
                }
                if (dot == null) {
                  return const SizedBox.shrink();
                }
                return CircleLayer(
                  circles: [
                    CircleMarker(
                      point: dot,
                      radius: 9,
                      color: AppColors.primaryLight,
                      borderStrokeWidth: 2,
                      borderColor: AppColors.surface,
                    ),
                  ],
                );
              }),
              Obx(() {
                final flags = c.liveFlags.toList(growable: false);
                if (flags.isEmpty) {
                  return const SizedBox.shrink();
                }
                return MarkerLayer(
                  markers: [
                    for (var i = 0; i < flags.length; i++)
                      Marker(
                        key: ValueKey<String>(
                          'live_flag_${flags[i].lat}_${flags[i].lng}_${flags[i].type}_$i',
                        ),
                        point: ll.LatLng(flags[i].lat, flags[i].lng),
                        width: 40,
                        height: 40,
                        alignment: Alignment.bottomCenter,
                        child: Material(
                          color: AppColors.surface.withValues(alpha: 0),
                          child: InkWell(
                            onTap: () => _showLiveFlagTooltip(
                              context,
                              flags[i],
                            ),
                            customBorder: const CircleBorder(),
                            child: TrackFlagTypeCircleIcon(
                              type: flags[i].type,
                              size: 36,
                              iconSize: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  if (!c.liveTestingMode.value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Material(
                      color: AppColors.warning.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          'TAP MAP TO SIMULATE',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 16,
                            letterSpacing: 1.2,
                            color: AppColors.surface,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Material(
                    color: AppColors.darkSurface.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Obx(() {
                              final name = c.liveTrackName.value.trim();
                              return Text(
                                name.isEmpty ? 'Live track' : name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 20,
                                  color: AppColors.surface,
                                  letterSpacing: 0.5,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(width: 12),
                          Obx(() {
                            final t = _formatHms(c.recordingDuration.value);
                            return Text(
                              t,
                              style: GoogleFonts.spaceMono(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryLight,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Material(
                  color: AppColors.darkSurface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'DISTANCE (M)',
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() {
                                    final m = c.recordingDistance.value.round();
                                    return Text(
                                      '$m',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.surface,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'STEPS',
                                    style: GoogleFonts.bebasNeue(
                                      fontSize: 11,
                                      letterSpacing: 1,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Obx(() {
                                    final st = c.recordingSteps.value;
                                    return Text(
                                      '$st',
                                      style: GoogleFonts.spaceMono(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.surface,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => AddFlagBottomSheet.show(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primaryLight,
                                  side: const BorderSide(
                                    color: AppColors.primaryLight,
                                    width: 1.5,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Add Flag',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: () async {
                                  await c.endTrack();
                                },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.danger,
                                  foregroundColor: AppColors.surface,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'End Track',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
