import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/group_controller.dart';
import '../data/models/live_session_model.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with TickerProviderStateMixin {
  GroupController get _gc => Get.find<GroupController>();

  final MapController _mapController = MapController();

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseSize;
  late final Animation<double> _pulseOpacity;

  late final AnimationController _dotCtrl;
  late final Animation<double> _dotOpacity;

  Worker? _positionWorker;

  @override
  void initState() {
    super.initState();

    final argGroupId = Get.arguments?.toString();
    final selectedGroupId = _gc.selectedGroup.value?.id;
    final groupId = (argGroupId != null && argGroupId.isNotEmpty)
        ? argGroupId
        : selectedGroupId;
    if (groupId != null && groupId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gc.fetchGroupLiveSessions(groupId);
      });
    }

    // Blue pulsing animation for current user marker
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _pulseSize =
        Tween<double>(begin: 14, end: 28).animate(CurvedAnimation(
            parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseOpacity =
        Tween<double>(begin: 0.6, end: 0.0).animate(CurvedAnimation(
            parent: _pulseCtrl, curve: Curves.easeOut));

    // Green pulsing dot for header
    _dotCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _dotOpacity = Tween<double>(begin: 0.4, end: 1.0).animate(_dotCtrl);

    // Follow controller's GPS position to move the map camera
    _positionWorker = ever(_gc.currentPosition, (ll.LatLng? pos) {
      if (pos != null) {
        _mapController.move(pos, _mapController.camera.zoom);
      }
    });

    // Initial center
    final initial = _gc.currentPosition.value;
    if (initial != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(initial, 15);
      });
    }
  }

  @override
  void dispose() {
    _positionWorker?.dispose();
    _pulseCtrl.dispose();
    _dotCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String? _resolveImage(String? stored) => ApiConfig.resolveMediaUrl(stored);

  String _formatSessionTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──
          Obx(() {
            // Touch observables to rebuild when they change
            (_gc.currentPosition.value ?? ll.LatLng(0, 0));
            _gc.memberLocations.length;
            _gc.memberLocations.values
                .fold<int>(0, (sum, m) => sum + m.locationPath.length);

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: (_gc.currentPosition.value ?? ll.LatLng(0, 0)),
                initialZoom: 15,
                backgroundColor: AppColors.mapPreviewBackground,
                // Testing: tap to simulate user position
                onTap: (_, point) {
                  if (!_gc.isTracking.value) return;
                  _gc.simulatePosition(point.latitude, point.longitude);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.adventureproviders.app',
                ),
                // Historical path line for each member in this live session
                _buildMemberPathPolylines(),
                // Member markers
                _buildMemberMarkers(),
                // Current user marker
                _buildCurrentUserMarker(),
              ],
            );
          }),

          // ── Top overlay ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopOverlay(),
          ),

          // ── Bottom panel ──
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomPanel(),
          ),
        ],
      ),
    );
  }

  // ── Member markers layer ──

  Widget _buildMemberPathPolylines() {
    final members = _gc.memberLocations.values.toList();
    final lines = <Polyline>[];
    for (final m in members) {
      if (m.locationPath.length < 2) continue;
      lines.add(
        Polyline(
          points: m.locationPath,
          color: m.isOnline
              ? AppColors.primaryLight.withValues(alpha: 0.85)
              : Colors.grey.withValues(alpha: 0.55),
          strokeWidth: 3,
        ),
      );
    }
    if (lines.isEmpty) return const SizedBox.shrink();
    return PolylineLayer(polylines: lines);
  }

  Widget _buildMemberMarkers() {
    final members = _gc.memberLocations.values.toList();
    final markers = <Marker>[];

    for (final m in members) {
      if (m.lastLatitude == null || m.lastLongitude == null) continue;
      markers.add(
        Marker(
          point: ll.LatLng(m.lastLatitude!, m.lastLongitude!),
          width: 80,
          height: 70,
          child: _MemberMarkerWidget(member: m, resolveImage: _resolveImage),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  // ── Current user marker ──

  Widget _buildCurrentUserMarker() {
    return MarkerLayer(
      markers: [
        Marker(
          point: (_gc.currentPosition.value ?? ll.LatLng(0, 0)),
          width: 32,
          height: 32,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Pulsing outer ring
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) => Container(
                  width: _pulseSize.value,
                  height: _pulseSize.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withValues(alpha: _pulseOpacity.value),
                  ),
                ),
              ),
              // Inner dot
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
              Positioned(
                top: 36,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'You',
                    style: GoogleFonts.spaceMono(fontSize: 9, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Top overlay ──

  Widget _buildTopOverlay() {
    return Container(
      color: Colors.black54,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      child: Obx(() {
        final group = _gc.selectedGroup.value;
        final onlineCount = _gc.memberLocations.values
            .where((m) => m.isOnline)
            .length;

        return Row(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                group?.name ?? 'Group',
                textAlign: TextAlign.center,
                style: GoogleFonts.bebasNeue(
                    fontSize: 18, color: Colors.white, letterSpacing: 1),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '$onlineCount online',
              style: GoogleFonts.spaceMono(
                  fontSize: 11, color: AppColors.primaryLight),
            ),
          ],
        );
      }),
    );
  }

  // ── Bottom panel ──

  Widget _buildBottomPanel() {
    return Container(
      height: 260,
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: LIVE SESSION + pulsing dot
          Row(
            children: [
              Text('LIVE SESSION',
                  style: GoogleFonts.bebasNeue(
                      fontSize: 16, color: Colors.white, letterSpacing: 1)),
              const SizedBox(width: 8),
              FadeTransition(
                opacity: _dotOpacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppColors.primaryLight, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: All group live sessions
          SizedBox(
            height: 38,
            child: Obx(() {
              final sessions = _gc.groupLiveSessions;
              if (sessions.isEmpty) {
                return Center(
                  child: Text('No live sessions yet',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white38)),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sessions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  final s = sessions[index];
                  final active = s.isActive;
                  final selected = _gc.liveSessionId.value == s.id;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _gc.selectSessionForMap(s.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primaryLight.withValues(alpha: 0.28)
                              : (active
                                  ? AppColors.primaryLight.withValues(alpha: 0.2)
                                  : const Color(0xFF1A2A1F)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selected
                                ? AppColors.primaryLight
                                : (active ? AppColors.primaryLight : Colors.white24),
                          ),
                        ),
                        child: Text(
                          'Session ${index + 1} · ${_formatSessionTime(s.startedAt)}${active ? ' · LIVE' : ' · ENDED'}',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: (active || selected)
                                ? AppColors.primaryLight
                                : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 10),

          // Row 3: Member status chips (active session)
          SizedBox(
            height: 34,
            child: Obx(() {
              final members = _gc.memberLocations.values.toList();
              if (members.isEmpty) {
                return Center(
                  child: Text('Waiting for members...',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.white38)),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) =>
                    _MemberChip(member: members[index], resolveImage: _resolveImage),
              );
            }),
          ),
          const SizedBox(height: 12),

          // Row 4: SOS + End Session
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _gc.sendSOS(),
                  child: Text('\u{1F198} SOS',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.white)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.danger),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final groupId = _gc.selectedGroup.value?.id;
                    if (groupId != null) {
                      await _gc.stopGroupTracking(groupId);
                    }
                    Get.back();
                  },
                  child: Text('End Session',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.danger)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Member marker widget ──

class _MemberMarkerWidget extends StatelessWidget {
  const _MemberMarkerWidget(
      {required this.member, required this.resolveImage});

  final MemberSession member;
  final String? Function(String?) resolveImage;

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(member.profileImage);
    final initials = member.name.isNotEmpty
        ? member.name
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: member.isOnline ? AppColors.primaryLight : Colors.grey,
              width: 2,
            ),
          ),
          child: ClipOval(
            child: url != null && url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        _MarkerInitials(initials),
                  )
                : _MarkerInitials(initials),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xCC1B4332),
            borderRadius: BorderRadius.circular(8),
          ),
          child: member.isOnline
              ? Text(
                  member.shortName.isNotEmpty
                      ? member.shortName
                      : member.name.split(' ').first,
                  style: GoogleFonts.spaceMono(
                      fontSize: 10, color: Colors.white),
                )
              : Text('Away',
                  style: GoogleFonts.spaceMono(
                      fontSize: 9, color: Colors.grey)),
        ),
      ],
    );
  }
}

class _MarkerInitials extends StatelessWidget {
  const _MarkerInitials(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primaryDark,
      alignment: Alignment.center,
      child: Text(text,
          style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white)),
    );
  }
}

// ── Member status chip ──

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member, required this.resolveImage});

  final MemberSession member;
  final String? Function(String?) resolveImage;

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(member.profileImage);
    final initials = member.name.isNotEmpty
        ? member.name[0].toUpperCase()
        : '?';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A1F),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.primaryDark,
            child: url != null && url.isNotEmpty
                ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 24,
                      height: 24,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Text(initials,
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.white)),
                    ),
                  )
                : Text(initials,
                    style: GoogleFonts.poppins(
                        fontSize: 10, color: Colors.white)),
          ),
          const SizedBox(width: 6),
          Text(
            member.shortName.isNotEmpty
                ? member.shortName
                : member.name.split(' ').first,
            style:
                GoogleFonts.spaceMono(fontSize: 10, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: member.isOnline ? AppColors.primaryLight : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
