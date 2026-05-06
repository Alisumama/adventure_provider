import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/constants/api_config.dart';
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

  late final TextEditingController _searchCtrl;

  static const _scaffoldBg = Color(0xFFF0EDE8);
  static const _muted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Get.find<TrackController>().fetchPublicTracks();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Get.find<TrackController>();
    final headerExt = shellCollapsingHeaderExtents(context);

    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Obx(() {
          final loading = c.isLoading.value;
          final filter = c.selectedFilter.value;
          final q = c.trackSearchQuery.value.trim().toLowerCase();
          final all = c.myTracks.toList();
          final byType = filter == 'all'
              ? all
              : all.where((t) => t.type.toLowerCase() == filter).toList();
          final tracks = q.isEmpty
              ? byType
              : byType.where((t) {
                  final title = t.title.toLowerCase();
                  final desc = (t.description ?? '').toLowerCase();
                  return title.contains(q) || desc.contains(q);
                }).toList();

          return RefreshIndicator(
            color: const Color(0xFF52B788),
            onRefresh: () => c.fetchPublicTracks(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PublicTracksCollapsingHeaderDelegate(
                    minExtent: headerExt.min,
                    maxExtent: headerExt.max,
                    pulseDot: const _ExplorePulseDot(),
                    searchController: _searchCtrl,
                    searchQueryRx: c.trackSearchQuery,
                    filters: _filters,
                    selectedFilterRx: c.selectedFilter,
                    onRefresh: c.fetchPublicTracks,
                    onAddTap: () => Get.toNamed(AppRoutes.recordTrack),
                    onClearSearch: () {
                      _searchCtrl.clear();
                      c.trackSearchQuery.value = '';
                    },
                  ),
                ),
                if (loading && tracks.isNotEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 6, bottom: 10),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF52B788),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (loading && all.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary.withValues(alpha: 0.9),
                      ),
                    ),
                  )
                else if (tracks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    fillOverscroll: true,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.terrain_outlined,
                              size: 64,
                              color: _muted.withValues(alpha: 0.7),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              q.isNotEmpty
                                  ? 'No tracks match your search.'
                                  : 'No tracks found yet.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: _muted,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = tracks[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index < tracks.length - 1 ? 16 : 0,
                            ),
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
                        childCount: tracks.length,
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: kSosFabScrollBottomInset),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─── Pulse dot (same behavior as Communities) ───────────────────────────────

class _ExplorePulseDot extends StatefulWidget {
  const _ExplorePulseDot();

  @override
  State<_ExplorePulseDot> createState() => _ExplorePulseDotState();
}

class _ExplorePulseDotState extends State<_ExplorePulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.6, end: 1.4).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF52B788),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// Pinned title + actions; collapses filter chips + search (matches Communities).
class _PublicTracksCollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  _PublicTracksCollapsingHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.pulseDot,
    required this.searchController,
    required this.searchQueryRx,
    required this.filters,
    required this.selectedFilterRx,
    required this.onRefresh,
    required this.onAddTap,
    required this.onClearSearch,
  });

  @override
  final double minExtent;
  @override
  final double maxExtent;

  final Widget pulseDot;
  final TextEditingController searchController;
  final RxString searchQueryRx;
  final List<({String key, String label})> filters;
  final RxString selectedFilterRx;
  final VoidCallback onRefresh;
  final VoidCallback onAddTap;
  final VoidCallback onClearSearch;

  static const _accent = Color(0xFF52B788);

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final deltaRange = maxExtent - minExtent;
        final expandT = deltaRange > 0
            ? ((constraints.maxHeight - minExtent) / deltaRange).clamp(
                0.0,
                1.0,
              )
            : 0.0;

        final titleScale = expandT > 0.35 ? 1.0 : 0.96 + expandT * 0.04;

        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0D2B1E),
                        Color(0xFF1B4332),
                        Color(0xFF2D6A4F),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -20,
              right: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.85,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.035),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -28,
              left: -28,
              child: IgnorePointer(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.02),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -4,
              right: 48,
              child: IgnorePointer(
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _accent.withValues(alpha: 0.06),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                MediaQuery.paddingOf(context).top + 8 + expandT * 4,
                18,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Transform.scale(
                    scale: titleScale,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  pulseDot,
                                  const SizedBox(width: 5),
                                  Text(
                                    'EXPLORE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: _accent,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'YOUR TRACKS',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 26,
                                  color: Colors.white,
                                  letterSpacing: 1.3,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _OutlineHeaderIconButton(
                          icon: Icons.refresh_rounded,
                          onTap: onRefresh,
                        ),
                        const SizedBox(width: 6),
                        _OutlineHeaderIconButton(
                          icon: Icons.add,
                          onTap: onAddTap,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: expandT.clamp(0.0, 1.0),
                        child: Opacity(
                          opacity: expandT,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 0),
                              child: Obx(() {
                                final selected = selectedFilterRx.value;
                                return SizedBox(
                                  height: 36,
                                  child: ListView.separated(
                                    clipBehavior: Clip.none,
                                    padding: EdgeInsets.zero,
                                    scrollDirection: Axis.horizontal,
                                    itemCount: filters.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (context, i) {
                                      final f = filters[i];
                                      final active = selected == f.key;
                                      return _TrackFilterChip(
                                        label: f.label,
                                        active: active,
                                        onTap: () =>
                                            selectedFilterRx.value = f.key,
                                      );
                                    },
                                  ),
                                );
                              }),
                            ),
                            SizedBox(height: 8 + expandT * 12),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search_rounded,
                                    size: 16,
                                    color: Colors.white.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Theme(
                                      data: Theme.of(context).copyWith(
                                        inputDecorationTheme:
                                            const InputDecorationTheme(
                                          filled: false,
                                          fillColor: Colors.transparent,
                                          border: InputBorder.none,
                                          focusedBorder: InputBorder.none,
                                          enabledBorder: InputBorder.none,
                                          isDense: true,
                                        ),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: TextField(
                                          controller: searchController,
                                          onChanged: (v) =>
                                              searchQueryRx.value = v,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.white,
                                            height: 1.25,
                                          ),
                                          cursorColor: Colors.white,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Colors.transparent,
                                            isDense: true,
                                            hintText:
                                                'Search tracks by title or description',
                                            hintStyle: GoogleFonts.poppins(
                                              fontSize: 11,
                                              color: Colors.white
                                                  .withValues(alpha: 0.42),
                                            ),
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                            disabledBorder: InputBorder.none,
                                            errorBorder: InputBorder.none,
                                            focusedErrorBorder: InputBorder.none,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Obx(() {
                                    if (searchQueryRx.value.isEmpty) {
                                      return const SizedBox.shrink();
                                    }
                                    return GestureDetector(
                                      onTap: onClearSearch,
                                      behavior: HitTestBehavior.opaque,
                                      child: Icon(
                                        Icons.close_rounded,
                                        size: 15,
                                        color: Colors.white
                                            .withValues(alpha: 0.5),
                                      ),
                                    );
                                  }),
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
            ),
          ],
        );
      },
    );
  }

  @override
  bool shouldRebuild(
    covariant _PublicTracksCollapsingHeaderDelegate oldDelegate,
  ) {
    return oldDelegate.minExtent != minExtent ||
        oldDelegate.maxExtent != maxExtent ||
        oldDelegate.searchController != searchController ||
        oldDelegate.pulseDot != pulseDot ||
        oldDelegate.filters != filters ||
        oldDelegate.searchQueryRx != searchQueryRx ||
        oldDelegate.selectedFilterRx != selectedFilterRx ||
        oldDelegate.onRefresh != onRefresh ||
        oldDelegate.onAddTap != onAddTap ||
        oldDelegate.onClearSearch != onClearSearch;
  }
}

class _OutlineHeaderIconButton extends StatelessWidget {
  const _OutlineHeaderIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}

class _TrackFilterChip extends StatelessWidget {
  const _TrackFilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  static const _primaryDarkGreen = Color(0xFF1B4332);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _primaryDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? _primaryDarkGreen
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.track, required this.onTap});

  final TrackModel track;
  final VoidCallback onTap;

  static const _textPrimary = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);
  static const _cardBorder = Color(0xFFE2EDE8);

  static Color _difficultyColor(String d) {
    switch (d.toLowerCase()) {
      case 'easy':
        return const Color(0xFF2D6A4F);
      case 'moderate':
        return const Color(0xFFE8A317);
      case 'hard':
        return const Color(0xFFC53030);
      default:
        return _muted;
    }
  }

  static String _difficultyLabel(String d) {
    if (d.isEmpty) return '—';
    return '${d[0].toUpperCase()}${d.substring(1).toLowerCase()}';
  }

  String? _previewImageUrl() {
    final cover = ApiConfig.resolveMediaUrl(track.coverImage);
    if (cover != null && cover.isNotEmpty) return cover;
    if (track.photos.isNotEmpty) {
      final first = ApiConfig.resolveMediaUrl(track.photos.first);
      if (first != null && first.isNotEmpty) return first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final diffColor = _difficultyColor(track.difficulty);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: _TrackHeaderPreview(
                    track: track,
                    imageUrl: _previewImageUrl(),
                  ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.straighten, size: 14, color: _muted),
                        const SizedBox(width: 4),
                        Text(
                          '${track.distanceKm} km',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Icon(Icons.landscape_outlined, size: 14, color: _muted),
                        const SizedBox(width: 4),
                        Text(
                          '— m',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: _muted,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: diffColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _difficultyLabel(track.difficulty),
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: diffColor,
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
      ),
    );
  }
}

class _TrackHeaderPreview extends StatelessWidget {
  const _TrackHeaderPreview({required this.track, required this.imageUrl});

  final TrackModel track;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            IgnorePointer(child: _TrackRoutePreviewMap(track: track)),
      );
    }
    return IgnorePointer(child: _TrackRoutePreviewMap(track: track));
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
            color: Colors.grey.withValues(alpha: 0.45),
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
        interactionOptions:
            const InteractionOptions(flags: InteractiveFlag.none),
        onMapReady: _fitBounds,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                borderColor: Colors.white,
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
                borderColor: Colors.white,
              ),
          ],
        ),
      ],
    );
  }
}
