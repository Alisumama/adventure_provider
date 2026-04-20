import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/track_follow_controller.dart';
import '../data/models/track_follow_model.dart';
import '../data/models/track_model.dart';

String _formatHms(int totalSeconds) {
  final s = totalSeconds < 0 ? 0 : totalSeconds;
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  return '${h.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')}:'
      '${sec.toString().padLeft(2, '0')}';
}

/// Full-screen OSM map while following a published track.
///
/// Expects [Get.arguments] to be a [TrackModel].
class FollowTrackScreen extends StatefulWidget {
  const FollowTrackScreen({super.key});

  @override
  State<FollowTrackScreen> createState() => _FollowTrackScreenState();
}

class _FollowTrackScreenState extends State<FollowTrackScreen> with TickerProviderStateMixin {
  TrackModel? _track;
  final MapController _mapController = MapController();

  late final AnimationController _warnSlideController;
  late final AnimationController _panelSlideController;

  Worker? _cameraWorker;
  Worker? _completionWorker;
  Worker? _warnWorker;

  static const double _kZoom = 16.0;
  static const Color _offRouteRed = Color(0xFFD62828);
  static const double _bottomPanelHeight = 220;

  @override
  void initState() {
    super.initState();
    _track = Get.arguments is TrackModel ? Get.arguments as TrackModel : null;

    _warnSlideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _panelSlideController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _panelSlideController.forward();

    final fc = Get.find<TrackFollowController>();

    _warnWorker = ever<bool>(fc.isOffTrack, (off) {
      if (off) {
        _warnSlideController.forward();
      } else {
        _warnSlideController.reverse();
      }
    });

    _cameraWorker = ever<LatLng?>(fc.currentPosition, (pos) {
      if (pos == null) return;
      try {
        final z = _mapController.camera.zoom;
        _mapController.move(ll.LatLng(pos.latitude, pos.longitude), z);
      } catch (_) {}
    });

    _completionWorker = ever<TrackFollowModel?>(fc.lastCompletedFollow, (m) {
      if (m != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showSessionCompleteSheet(m);
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final t = _track;
      if (!mounted) return;
      if (t == null) {
        Get.snackbar('Error', 'Missing track.', snackPosition: SnackPosition.BOTTOM);
        Get.back<void>();
        return;
      }
      await fc.startFollowing(t);
      final start = t.geoPath.isNotEmpty ? t.geoPath.first : (fc.currentPosition.value ?? const LatLng(0, 0));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      try {
        _mapController.move(ll.LatLng(start.latitude, start.longitude), _kZoom);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _cameraWorker?.dispose();
    _completionWorker?.dispose();
    _warnWorker?.dispose();
    _warnSlideController.dispose();
    _panelSlideController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Builds user-walked polylines coloured by on/off track status.
  List<Polyline> _buildUserDotPolylines(List<LatLng> path, List<bool> off) {
    if (path.length < 2 || path.length != off.length) return [];
    final out = <Polyline>[];
    var i = 0;
    while (i < path.length - 1) {
      final segOff = off[i + 1];
      var j = i + 1;
      while (j < path.length - 1 && off[j + 1] == segOff) {
        j++;
      }
      final pts = path.sublist(i, j + 1).map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
      out.add(Polyline(points: pts, color: segOff ? _offRouteRed : AppColors.primaryLight, strokeWidth: 6, pattern: const StrokePattern.dotted()));
      i = j;
    }
    return out;
  }

  void _showSessionCompleteSheet(TrackFollowModel m) {
    final fc = Get.find<TrackFollowController>();
    final track = _track;
    Get.bottomSheet<void>(
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Session Complete! 🎉',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              _statLine('Distance', '${(m.totalDistance / 1000).toStringAsFixed(2)} km'),
              _statLine('Duration', m.durationFormatted),
              _statLine('Completion', '${m.completionPercentage.toStringAsFixed(0)}%'),
              _statLine('Deviations', '${m.deviationCount}'),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        fc.clearLastCompletedFollow();
                        Get.back<void>();
                        final id = track?.id;
                        if (id != null && id.isNotEmpty) {
                          Get.offNamed(AppRoutes.trackDetailNamed(id));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: const BorderSide(color: AppColors.primaryLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('View Summary', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        fc.clearLastCompletedFollow();
                        Get.back<void>();
                        Get.back<void>();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Back to Track', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ).then((_) {
      fc.clearLastCompletedFollow();
    });
  }

  Widget _statLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fc = Get.find<TrackFollowController>();
    final t = _track;

    final initialCenter = t != null && t.geoPath.isNotEmpty ? ll.LatLng(t.geoPath.first.latitude, t.geoPath.first.longitude) : const ll.LatLng(33.6844, 73.0479);

    return Scaffold(
      backgroundColor: AppColors.darkSurface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: _kZoom,
              backgroundColor: AppColors.mapPreviewBackground,
              // Testing: tap = simulated user fix (same pipeline as GPS).
              onTap: (tapPosition, point) {
                if (!fc.isFollowing.value) return;
                fc.applyMapTapAsUserLocation(LatLng(point.latitude, point.longitude));
                // final text =
                //     '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}';
                // debugPrint('[FollowTrackScreen] simulated user position: $text');
                // Get.snackbar(
                //   'Simulated position',
                //   text,
                //   snackPosition: SnackPosition.BOTTOM,
                //   duration: const Duration(seconds: 3),
                //   margin: const EdgeInsets.only(
                //     left: 16,
                //     right: 16,
                //     bottom: _bottomPanelHeight + 8,
                //   ),
                // );
              },
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'adventure_provider_frontend'),
              // Original track route polyline
              Obx(() {
                final pts = fc.activeTrackPath.map((p) => ll.LatLng(p.latitude, p.longitude)).toList(growable: false);
                if (pts.length < 2) return const SizedBox.shrink();
                return PolylineLayer(
                  polylines: [Polyline(points: pts, color: AppColors.primaryLight, strokeWidth: 4)],
                );
              }),
              // User walked path (dotted, red when off track)
              Obx(() {
                final userPath = fc.userFollowPath.toList(growable: false);
                final offFlags = fc.userFollowOffTrack.toList(growable: false);
                final lines = _buildUserDotPolylines(userPath, offFlags);
                if (lines.isEmpty) return const SizedBox.shrink();
                return PolylineLayer(polylines: lines);
              }),
              // Start / end markers
              Builder(
                builder: (_) {
                  if (t == null || t.geoPath.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final s = t.geoPath.first;
                  final e = t.geoPath.last;
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: ll.LatLng(s.latitude, s.longitude),
                        width: 36,
                        height: 36,
                        alignment: Alignment.bottomCenter,
                        child: const Icon(Icons.flag_rounded, color: Colors.green, size: 32),
                      ),
                      Marker(
                        point: ll.LatLng(e.latitude, e.longitude),
                        width: 36,
                        height: 36,
                        alignment: Alignment.bottomCenter,
                        child: const Icon(Icons.flag_rounded, color: Colors.red, size: 32),
                      ),
                    ],
                  );
                },
              ),
              // User position dot
              Obx(() {
                final cp = fc.currentPosition.value;
                if (cp == null) return const SizedBox.shrink();
                return CircleLayer(
                  circles: [CircleMarker(point: ll.LatLng(cp.latitude, cp.longitude), radius: 9, color: AppColors.primaryLight, borderStrokeWidth: 2, borderColor: AppColors.surface)],
                );
              }),
            ],
          ),
          // Bottom stats panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _bottomPanelHeight,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(CurvedAnimation(parent: _panelSlideController, curve: Curves.easeOutCubic)),
              child: Obx(
                () => Material(
                  elevation: 12,
                  color: AppColors.darkSurface,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (t?.title ?? 'Track').trim().isEmpty ? 'Track' : t!.title.trim(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.bebasNeue(fontSize: 18, color: AppColors.surface, letterSpacing: 0.5),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primaryLight, width: 1),
                              ),
                              child: Text(
                                '${fc.completionPercentage.value.toStringAsFixed(0)}%',
                                style: GoogleFonts.spaceMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryLight),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ClipRect(
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(CurvedAnimation(parent: _warnSlideController, curve: Curves.easeOutCubic)),
                          child: !fc.isOffTrack.value
                              ? const SizedBox(height: 0)
                              : Container(
                                  width: double.infinity,
                                  color: AppColors.danger,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    '⚠️ OFF TRACK — ${fc.deviationDistance.value.toStringAsFixed(0)}m from path',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.surface),
                                  ),
                                ),
                        ),
                      ),
                      SizedBox(
                        height: 50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: _miniStat(
                                  'DISTANCE (M)',
                                  Text(
                                    '${fc.followDistance.value.round()}',
                                    style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.surface),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _miniStat(
                                  'DURATION',
                                  Text(
                                    _formatHms(fc.followDuration.value),
                                    style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.surface),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _miniStat(
                                  'STEPS',
                                  Text(
                                    '${fc.followSteps.value}',
                                    style: GoogleFonts.spaceMono(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.surface),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _miniStat(
                                  'KCAL',
                                  Text(
                                    '${fc.followCalories.value}',
                                    style: GoogleFonts.spaceMono(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.surface),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Obx(() {
                              final online = fc.isOnline.value;
                              final pending = fc.pendingPointsCount.value;
                              final Color dotColor;
                              final String statusLabel;
                              if (!online) {
                                dotColor = AppColors.accent;
                                statusLabel = 'Offline — saving locally';
                              } else if (pending > 0) {
                                dotColor = AppColors.success;
                                statusLabel = 'Syncing to cloud...';
                              } else {
                                dotColor = AppColors.success;
                                statusLabel = 'All points synced';
                              }
                              final pendingLabel = pending == 1 ? '1 point pending' : '$pending points pending';
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(statusLabel, style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.homeGreetingGrey)),
                                  ),
                                  Text(pendingLabel, style: GoogleFonts.spaceMono(fontSize: 10, color: AppColors.homeGreetingGrey)),
                                ],
                              );
                            }),
                            const SizedBox(height: 6),
                            OutlinedButton(
                              onPressed: () async {
                                await fc.stopFollowing();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.danger,
                                side: const BorderSide(color: AppColors.danger, width: 1.5),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('End Follow Session', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, Widget value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: GoogleFonts.bebasNeue(fontSize: 9, letterSpacing: 0.8, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        value,
      ],
    );
  }
}
