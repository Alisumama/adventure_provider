import 'package:cached_network_image/cached_network_image.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/track_controller.dart';
import '../data/models/track_model.dart';
import '../track_flag_type_style.dart';
import '../widgets/track_flag_detail_bottom_sheet.dart';
import 'add_flag_bottom_sheet.dart';

class TrackDetailScreen extends StatefulWidget {
  const TrackDetailScreen({super.key});

  @override
  State<TrackDetailScreen> createState() => _TrackDetailScreenState();
}

class _TrackDetailScreenState extends State<TrackDetailScreen> with SingleTickerProviderStateMixin {
  static const double _heroMapHeight = 280;
  static const double _photoStripGap = 8;

  final MapController _mapController = MapController();
  late final AnimationController _pulseController;
  String? _pulseFlagKey;

  final ImagePicker _imagePicker = ImagePicker();

  TrackModel? _loadedTrack;
  bool _pageLoading = true;
  bool _loadFailed = false;

  Future<void> _loadTrack() async {
    final paramId = Get.parameters['id'] ?? '';
    if (paramId.isEmpty) {
      setState(() {
        _pageLoading = false;
        _loadFailed = true;
      });
      return;
    }
    final c = Get.find<TrackController>();
    await c.fetchTrackById(paramId);
    if (!mounted) return;
    final t = c.selectedTrack.value;
    setState(() {
      _pageLoading = false;
      _loadFailed = t == null || t.id != paramId;
      _loadedTrack = t;
    });
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrack());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Color _difficultyBadgeColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
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

  String _formatKindLabel(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return '—';
    return '${s[0].toUpperCase()}${s.substring(1)}';
  }

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
        _mapController.fitCamera(CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(28)));
      } catch (_) {}
    });
  }

  void _onFlagCardTap(TrackFlag f) {
    final key = f.id ?? '${f.lat}_${f.lng}';
    setState(() => _pulseFlagKey = key);
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(ll.LatLng(f.lat, f.lng), 15);
      } catch (_) {}
    });
  }

  void _onFlagTap(BuildContext context, TrackFlag f) {
    showTrackFlagDetailBottomSheet(context, f);
    _onFlagCardTap(f);
  }

  void _openTrackPhotoSourceSheet(TrackController controller) {
    Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primaryLight),
                title: Text('Choose from gallery', style: GoogleFonts.poppins(color: AppColors.surface)),
                onTap: () async {
                  Get.back<void>();
                  await _pickTrackPhoto(ImageSource.gallery, controller);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primaryLight),
                title: Text('Take a photo', style: GoogleFonts.poppins(color: AppColors.surface)),
                onTap: () async {
                  Get.back<void>();
                  await _pickTrackPhoto(ImageSource.camera, controller);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTrackPhoto(ImageSource source, TrackController c) async {
    try {
      final x = await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (x == null || !mounted) return;
      await c.uploadTrackPhoto(x);
    } catch (_) {
      Get.snackbar('Error', 'Could not pick an image. Please try again.', snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _confirmDeleteFlag(TrackController c, TrackFlag f) async {
    final fid = f.id;
    if (fid == null || fid.isEmpty) return;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Delete this flag?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.surface),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.primaryLight)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await c.deleteFlag(fid);
    }
  }

  Future<void> _confirmDeleteTrackPhoto(TrackController c, int photoIndex) async {
    final ok = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: Text(
          'Delete this photo?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.surface),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('Cancel', style: GoogleFonts.poppins(color: AppColors.primaryLight)),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text('Delete', style: GoogleFonts.poppins(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await c.deleteTrackPhoto(photoIndex);
    }
  }

  Widget _buildHeroMap(BuildContext context, TrackController c, String paramId) {
    return Obx(() {
      final live = c.selectedTrack.value;
      final track = (live != null && live.id == paramId) ? live : _loadedTrack!;
      final pts = _boundsPoints(track);
      final pathPts = track.geoPath.map((p) => ll.LatLng(p.latitude, p.longitude)).toList(growable: false);
      final initialCenter = pts.isNotEmpty ? pts.first : const ll.LatLng(20, 0);
      final initialZoom = pts.isEmpty ? 2.0 : 12.0;

      return SizedBox(
        height: _heroMapHeight,
        width: double.infinity,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FlutterMap(
                key: ValueKey<String>('detail_map_${track.id}'),
                mapController: _mapController,
                options: MapOptions(initialCenter: initialCenter, initialZoom: initialZoom, backgroundColor: AppColors.darkSurface, onMapReady: () => _fitMapToTrack(track)),
                children: [
                  TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'adventure_provider_frontend'),
                  if (pathPts.length >= 2)
                    PolylineLayer(
                      polylines: [Polyline(points: pathPts, color: AppColors.primary, strokeWidth: 4)],
                    ),
                  MarkerLayer(markers: [for (var i = 0; i < track.flags.length; i++) _buildFlagMarker(track.flags[i], i, () => _onFlagTap(context, track.flags[i]))]),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.darkBackground.withValues(alpha: 0), AppColors.darkBackground.withValues(alpha: 0.82)]),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          track.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.bebasNeue(fontSize: 26, letterSpacing: 0.6, color: AppColors.surface),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: AppColors.darkBackground.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'View track on map',
                              onPressed: () {
                                final tid = track.id;
                                if (tid == null || tid.isEmpty) return;
                                Get.toNamed(AppRoutes.trackMapViewNamed(tid));
                              },
                              icon: const Icon(Icons.map_outlined),
                              color: AppColors.surface,
                            ),
                            IconButton(
                              tooltip: 'Follow track',
                              onPressed: () {
                                Get.snackbar('Coming soon', 'Track following will be available in a future update.', snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.darkSurface, colorText: AppColors.surface, margin: const EdgeInsets.all(16));
                              },
                              icon: const Icon(Icons.navigation_rounded),
                              color: AppColors.surface,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Marker _buildFlagMarker(TrackFlag f, int index, VoidCallback onTap) {
    final type = trackFlagTypeFromStored(f);
    final key = f.id ?? '${f.lat}_${f.lng}';
    final pulsing = _pulseFlagKey == key;

    return Marker(
      key: ValueKey<String>('detail_flag_${key}_$index'),
      point: ll.LatLng(f.lat, f.lng),
      width: 52,
      height: 52,
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (pulsing)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  final t = _pulseController.value;
                  final scale = 1.0 + 0.35 * t;
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: 0.35 + 0.35 * (1 - t),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryLight, width: 2),
                        ),
                      ),
                    ),
                  );
                },
              ),
            TrackFlagTypeCircleIcon(type: type, size: 38, iconSize: 20),
          ],
        ),
      ),
    );
  }

  Widget _statBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.homeGreetingGrey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceMono(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.surface),
        ),
      ],
    );
  }

  Widget _badge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: bg.withValues(alpha: 0.55)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.surface),
      ),
    );
  }

  Widget _buildActionRow(TrackController c, TrackModel track) {
    final tid = track.id;
    if (tid == null || tid.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _ActionChip(icon: track.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: '${track.likesCount}', onTap: () => c.toggleLike(tid)),
        _ActionChip(icon: track.isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: '${track.savesCount}', onTap: () => c.toggleSave(tid)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TrackController>();
    final auth = Get.find<AuthController>();

    Widget body;
    if (_pageLoading) {
      body = const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
    } else if (_loadFailed || _loadedTrack == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load this track.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 15, color: AppColors.homeGreetingGrey),
          ),
        ),
      );
    } else {
      final track = _loadedTrack!;
      final desc = track.description?.trim();

      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeroMap(context, c, Get.parameters['id'] ?? ''),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statBlock('Distance (km)', track.distanceKm),
                        const SizedBox(width: 20),
                        _statBlock('Duration', track.durationFormatted),
                        const SizedBox(width: 20),
                        _statBlock('Steps', '${track.steps}'),
                        const SizedBox(width: 20),
                        _statBlock('Calories', '${track.calories}'),
                        const SizedBox(width: 20),
                        _badge(_formatKindLabel(track.difficulty), _difficultyBadgeColor(track.difficulty)),
                        const SizedBox(width: 12),
                        _badge(_formatKindLabel(track.type), AppColors.primaryLight),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (desc != null && desc.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(desc, style: GoogleFonts.poppins(fontSize: 13, height: 1.45, color: AppColors.homeGreetingGrey)),
                    ),
                  if (desc != null && desc.isNotEmpty) const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('PHOTOS', style: GoogleFonts.bebasNeue(fontSize: 18, letterSpacing: 0.8, color: AppColors.surface)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      final photos = c.trackPhotos.toList();
                      final uid = auth.user.value?.id;
                      final oid = track.userId;
                      final isOwner = oid != null && uid != null && oid == uid;
                      if (!isOwner && photos.isEmpty) {
                        return Text('No photos yet.', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.homeGreetingGrey));
                      }
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final maxW = constraints.maxWidth;
                          final visibleSlots = isOwner ? 4 : 3;
                          final tileW = (maxW - (visibleSlots - 1) * _photoStripGap) / visibleSlots;
                          final rowH = tileW * 0.78;
                          final itemCount = photos.length + (isOwner ? 1 : 0);
                          return SizedBox(
                            height: rowH,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: itemCount,
                              separatorBuilder: (_, __) => const SizedBox(width: _photoStripGap),
                              itemBuilder: (context, i) {
                                if (isOwner && i == 0) {
                                  return SizedBox(
                                    width: tileW,
                                    height: rowH,
                                    child: _AddTrackPhotoTile(size: tileW, onTap: () => _openTrackPhotoSourceSheet(c)),
                                  );
                                }
                                final photoIndex = isOwner ? i - 1 : i;
                                final url = photos[photoIndex];
                                final resolved = ApiConfig.resolveMediaUrl(url) ?? url;
                                return SizedBox(
                                  width: tileW,
                                  height: rowH,
                                  child: _TrackPhotoGridTile(imageUrl: resolved, onPhotoTap: () => openTrackPhotoFullscreen(context, url), onDelete: isOwner ? () => _confirmDeleteTrackPhoto(c, photoIndex) : null),
                                );
                              },
                            ),
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('FLAGS', style: GoogleFonts.bebasNeue(fontSize: 22, letterSpacing: 1, color: AppColors.surface)),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Obx(() {
                      final flags = c.trackFlags.toList();
                      final uid = auth.user.value?.id;
                      final oid = track.userId;
                      final isOwner = oid != null && uid != null && oid == uid;
                      final tid = track.id;
                      if (tid == null || tid.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      if (!isOwner && flags.isEmpty) {
                        return Text('No flags on this track.', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.homeGreetingGrey));
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: flags.length + (isOwner ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          if (isOwner && i == flags.length) {
                            return _AddFlagTile(
                              onTap: () {
                                AddFlagBottomSheet.show(context, trackId: tid);
                              },
                            );
                          }
                          final f = flags[i];
                          final type = trackFlagTypeFromStored(f);
                          final note = f.description?.trim();
                          final noteText = (note == null || note.isEmpty) ? 'No note' : note;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Material(
                                color: AppColors.darkSurface,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: () => _onFlagTap(context, f),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(12, 12, isOwner ? 52 : 12, 12),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        TrackFlagTypeCircleIcon(type: type, size: 40, iconSize: 22),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                trackFlagLabel(type),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.surface),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                noteText,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(fontSize: 12, height: 1.3, color: AppColors.homeGreetingGrey),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              if (isOwner)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Material(
                                        color: AppColors.darkBackground.withValues(alpha: 0.62),
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: () {
                                            AddFlagBottomSheet.show(context, trackId: tid, existingFlag: f);
                                          },
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5),
                                            child: Icon(Icons.edit_outlined, size: 16, color: AppColors.surface),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Material(
                                        color: AppColors.darkBackground.withValues(alpha: 0.62),
                                        borderRadius: BorderRadius.circular(8),
                                        child: InkWell(
                                          onTap: () => _confirmDeleteFlag(c, f),
                                          borderRadius: BorderRadius.circular(8),
                                          child: const Padding(
                                            padding: EdgeInsets.all(5),
                                            child: Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.surface),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          );
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), color: AppColors.surface, onPressed: () => Get.back<void>()),
        title: Text("Track Details", style: GoogleFonts.bebasNeue(fontSize: 22, letterSpacing: 1, color: AppColors.surface)),
        centerTitle: false,
        actions: [
          if (!_pageLoading && !_loadFailed && _loadedTrack != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Obx(() {
                final live = c.selectedTrack.value;
                final base = _loadedTrack;
                final tid = base?.id;
                if (base == null || tid == null || tid.isEmpty) {
                  return const SizedBox.shrink();
                }
                final t = (live != null && live.id == tid) ? live : base;
                return _buildActionRow(c, t);
              }),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _AddFlagTile extends StatelessWidget {
  const _AddFlagTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 72,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        color: AppColors.homeGreetingGrey,
        strokeWidth: 1.2,
        dashPattern: const [6, 4],
        child: SizedBox.expand(
          child: Material(
            color: AppColors.darkBackground.withValues(alpha: 0),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add, color: AppColors.primaryLight, size: 26),
                  const SizedBox(width: 10),
                  Text(
                    'Add Flag',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.homeGreetingGrey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddTrackPhotoTile extends StatelessWidget {
  const _AddTrackPhotoTile({required this.onTap, this.size});

  final VoidCallback onTap;

  /// When set (e.g. horizontal photo strip), tile is square at this size.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final inner = Material(
      color: AppColors.darkBackground.withValues(alpha: 0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primaryLight, size: size != null ? 22 : 32),
            SizedBox(height: size != null ? 4 : 8),
            Text(
              'Add Photo',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: size != null ? 10 : 12, fontWeight: FontWeight.w500, color: AppColors.homeGreetingGrey),
            ),
          ],
        ),
      ),
    );

    return DottedBorder(
      borderType: BorderType.RRect,
      radius: const Radius.circular(10),
      color: AppColors.homeGreetingGrey,
      strokeWidth: 1.2,
      dashPattern: const [6, 4],
      child: size != null ? SizedBox(width: size, height: size, child: inner) : SizedBox.expand(child: inner),
    );
  }
}

class _TrackPhotoGridTile extends StatelessWidget {
  const _TrackPhotoGridTile({required this.imageUrl, required this.onPhotoTap, this.onDelete});

  final String imageUrl;
  final VoidCallback onPhotoTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Material(
            color: AppColors.darkSurface,
            child: InkWell(
              onTap: onPhotoTap,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: AppColors.darkSurface,
                  alignment: Alignment.center,
                  child: const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight)),
                ),
                errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: AppColors.homeGreetingGrey),
              ),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: Material(
                color: AppColors.darkBackground.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(5),
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.surface),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const fg = AppColors.surface;
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
