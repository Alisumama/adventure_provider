import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/theme/app_colors.dart';
import '../controllers/track_controller.dart';
import '../data/models/track_model.dart';
import '../track_flag_type_style.dart';
import '../widgets/track_flag_detail_bottom_sheet.dart';

/// Full-screen map for a single track (route polyline + flag markers).
class TrackMapViewScreen extends StatefulWidget {
  const TrackMapViewScreen({super.key});

  @override
  State<TrackMapViewScreen> createState() => _TrackMapViewScreenState();
}

class _TrackMapViewScreenState extends State<TrackMapViewScreen> {
  final MapController _mapController = MapController();

  bool _loading = true;
  bool _failed = false;

  List<ll.LatLng> _boundsPoints(TrackModel track) {
    final pts = <ll.LatLng>[];
    for (final p in track.geoPath) {
      pts.add(ll.LatLng(p.latitude, p.longitude));
    }
    for (final f in track.flags) {
      pts.add(ll.LatLng(f.lat, f.lng));
    }
    return pts;
  }

  void _fitMapToTrack(TrackModel track) {
    final pts = _boundsPoints(track);
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
            padding: const EdgeInsets.all(48),
          ),
        );
      } catch (_) {}
    });
  }

  Future<void> _load() async {
    final id = Get.parameters['id'] ?? '';
    if (id.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
      return;
    }
    final c = Get.find<TrackController>();
    if (c.selectedTrack.value?.id != id) {
      await c.fetchTrackById(id);
    }
    if (!mounted) return;
    final t = c.selectedTrack.value;
    setState(() {
      _loading = false;
      _failed = t == null || t.id != id;
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Marker _buildFlagMarker(
    TrackFlag f,
    int index,
    VoidCallback onTap,
  ) {
    final type = trackFlagTypeFromStored(f);
    final key = f.id ?? '${f.lat}_${f.lng}';

    return Marker(
      key: ValueKey<String>('map_view_flag_${key}_$index'),
      point: ll.LatLng(f.lat, f.lng),
      width: 52,
      height: 52,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: TrackFlagTypeCircleIcon(
          type: type,
          size: 38,
          iconSize: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paramId = Get.parameters['id'] ?? '';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.surface,
          onPressed: () => Get.back<void>(),
        ),
        title: Text(
          'Track map',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            color: AppColors.surface,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight),
            )
          : _failed
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Could not load this track.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: AppColors.homeGreetingGrey,
                      ),
                    ),
                  ),
                )
              : Obx(() {
                  final c = Get.find<TrackController>();
                  final live = c.selectedTrack.value;
                  final track = (live != null && live.id == paramId)
                      ? live
                      : null;
                  if (track == null) {
                    return Center(
                      child: Text(
                        'Could not load this track.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: AppColors.homeGreetingGrey,
                        ),
                      ),
                    );
                  }
                  final pathPts = track.geoPath
                      .map((p) => ll.LatLng(p.latitude, p.longitude))
                      .toList(growable: false);
                  final pts = _boundsPoints(track);
                  final initialCenter =
                      pts.isNotEmpty ? pts.first : const ll.LatLng(20, 0);
                  final initialZoom = pts.isEmpty ? 2.0 : 12.0;

                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: initialCenter,
                      initialZoom: initialZoom,
                      backgroundColor: AppColors.darkSurface,
                      onMapReady: () => _fitMapToTrack(track),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'adventure_provider_frontend',
                      ),
                      if (pathPts.length >= 2)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: pathPts,
                              color: AppColors.primary,
                              strokeWidth: 4,
                            ),
                          ],
                        ),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < track.flags.length; i++)
                            _buildFlagMarker(
                              track.flags[i],
                              i,
                              () => showTrackFlagDetailBottomSheet(
                                context,
                                track.flags[i],
                              ),
                            ),
                        ],
                      ),
                    ],
                  );
                }),
    );
  }
}
