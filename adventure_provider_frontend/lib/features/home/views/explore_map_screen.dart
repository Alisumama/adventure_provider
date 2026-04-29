import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../track/controllers/track_controller.dart';


/// Full-screen map showing the user's current location and nearby public tracks.
class ExploreMapScreen extends StatefulWidget {
  const ExploreMapScreen({super.key});

  @override
  State<ExploreMapScreen> createState() => _ExploreMapScreenState();
}

class _ExploreMapScreenState extends State<ExploreMapScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  ll.LatLng? _currentPosition;
  bool _loading = true;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseSize;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _pulseSize = Tween<double>(begin: 14, end: 28)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseOpacity = Tween<double>(begin: 0.6, end: 0.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _loading = false);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      setState(() {
        _currentPosition =
            ll.LatLng(position.latitude, position.longitude);
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentPosition != null && mounted) {
          _mapController.move(_currentPosition!, 15);
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  List<Polyline> _buildTrackPolylines() {
    if (!Get.isRegistered<TrackController>()) return [];
    final tracks = Get.find<TrackController>().myTracks;
    final lines = <Polyline>[];
    for (final t in tracks) {
      if (t.geoPath.length < 2) continue;
      lines.add(Polyline(
        points:
            t.geoPath.map((p) => ll.LatLng(p.latitude, p.longitude)).toList(),
        color: AppColors.primaryLight.withValues(alpha: 0.6),
        strokeWidth: 3,
      ));
    }
    return lines;
  }

  List<Marker> _buildTrackMarkers() {
    if (!Get.isRegistered<TrackController>()) return [];
    final tracks = Get.find<TrackController>().myTracks;
    final markers = <Marker>[];
    for (final t in tracks) {
      final start =
          t.startPoint ?? (t.geoPath.isNotEmpty ? t.geoPath.first : null);
      if (start == null) continue;
      markers.add(Marker(
        point: ll.LatLng(start.latitude, start.longitude),
        width: 120,
        height: 40,
        child: GestureDetector(
          onTap: () {
            if (t.id != null) Get.toNamed(AppRoutes.trackDetailNamed(t.id!));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryLight, width: 1),
            ),
            child: Text(
              t.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
            ),
          ),
        ),
      ));
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition ?? ll.LatLng(33.6844, 73.0479);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _currentPosition != null ? 15 : 5,
              backgroundColor: AppColors.mapPreviewBackground,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.adventureproviders.app',
              ),
              PolylineLayer(polylines: _buildTrackPolylines()),
              MarkerLayer(markers: _buildTrackMarkers()),
              if (_currentPosition != null)
                MarkerLayer(markers: [
                  Marker(
                    point: _currentPosition!,
                    width: 32,
                    height: 32,
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: _pulseSize.value,
                            height: _pulseSize.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue
                                  .withValues(alpha: _pulseOpacity.value),
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]),
            ],
          ),

          // Top bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 12,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Explore Map',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.bebasNeue(
                          fontSize: 18,
                          color: Colors.white,
                          letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),

          // Re-center button
          if (_currentPosition != null)
            Positioned(
              bottom: 24,
              right: 16,
              child: FloatingActionButton.small(
                backgroundColor: AppColors.primaryLight,
                onPressed: () =>
                    _mapController.move(_currentPosition!, 15),
                child:
                    const Icon(Icons.my_location, color: Colors.white),
              ),
            ),

          // Loading
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryLight),
            ),
        ],
      ),
    );
  }
}
