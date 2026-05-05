import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/controllers/navigation_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../community/controllers/community_controller.dart';
import '../../groups/controllers/group_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../track/controllers/track_controller.dart';
import '../models/active_session_data.dart';
import '../widgets/home_communities_section.dart';
import '../widgets/home_header_status_strip.dart';
import '../widgets/home_nearby_routes_section.dart';
import '../widgets/home_quick_map_section.dart';
import '../widgets/home_my_groups_section.dart';
import '../widgets/home_session_hero_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TrackController get _tc => Get.find<TrackController>();
  GroupController get _gc => Get.find<GroupController>();
  CommunityController get _cc => Get.find<CommunityController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tc.fetchPublicTracks();
      _gc.fetchMyGroups();
      _cc.fetchCommunities();
    });
  }

  String _resolveDisplayName() {
    try {
      final p = Get.find<ProfileController>().profile.value;
      final n = p?.name;
      if (n != null && n.trim().isNotEmpty) return n.trim();
    } catch (_) {}
    if (Get.isRegistered<AuthController>()) {
      final n = Get.find<AuthController>().user.value?.name;
      if (n != null && n.trim().isNotEmpty) return n.trim();
    }
    return 'Explorer';
  }

  String? _resolveProfileImageUrl() {
    try {
      final raw = Get.find<ProfileController>().profile.value?.profileImage;
      return ApiConfig.resolveMediaUrl(raw);
    } catch (_) {
      return null;
    }
  }

  String _timeOfDayWord() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  ActiveSessionData? _buildActiveSession() {
    if (!_tc.isRecording.value) return null;
    final dist = _tc.recordingDistance.value;
    final dur = _tc.recordingDuration.value;
    final h = dur ~/ 3600;
    final m = (dur % 3600) ~/ 60;
    final timeLabel = h > 0 ? '${h}h ${m}m' : '${m}m';
    return ActiveSessionData(
      trailName: _tc.liveTrackName.value.isNotEmpty
          ? _tc.liveTrackName.value
          : 'Recording...',
      activityLabel: 'Tracking',
      startedAgoLabel: '$timeLabel ago',
      km: dist / 1000,
      timeLabel: timeLabel,
      steps: _tc.recordingSteps.value,
      kcal: _tc.recordingCalories.value,
    );
  }

  void _navigateToTab(int tab) {
    Get.find<NavigationController>().changePage(tab);
  }

  @override
  Widget build(BuildContext context) {
    const scaffoldBg = Color(0xFFF0EDE8);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(() {
              final displayName = _resolveDisplayName();
              final imageUrl = _resolveProfileImageUrl();
              return _AdvancedHomeHeader(
                displayName: displayName,
                imageUrl: imageUrl,
                timeOfDayWord: _timeOfDayWord(),
                onNotificationsTap: () {
                  Get.snackbar(
                    'Notifications',
                    'Notifications coming soon.',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 2),
                  );
                },
                onAvatarTap: () =>
                    _navigateToTab(NavigationController.tabProfile),
              );
            }),
            Expanded(
              child: Obx(() {
                final activeSession = _buildActiveSession();
                final tracks = _tc.myTracks;
                final groups = _gc.myGroups;
                final communities = _cc.communities;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          child: HomeSessionHeroCard(
                            activeSession: activeSession,
                            onStartAdventure: () =>
                                Get.toNamed(AppRoutes.recordTrack),
                            onViewMap: () {
                              if (_tc.liveTrackId.value.isNotEmpty) {
                                Get.toNamed(AppRoutes.liveMapRecording);
                              }
                            },
                            onEndSession: () => _tc.stopRecording(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        HomeQuickMapSection(
                          onOpenFullMap: () =>
                              Get.toNamed(AppRoutes.exploreMap),
                          onOpenMapPreview: () =>
                              Get.toNamed(AppRoutes.exploreMap),
                        ),
                        const SizedBox(height: 28),
                        HomeNearbyRoutesSection(
                          tracks: tracks,
                          isLoading: _tc.isLoading.value,
                          onSeeAll: () =>
                              _navigateToTab(NavigationController.tabTrack),
                          onRouteTap: (track) {
                            if (track.id != null) {
                              Get.toNamed(
                                  AppRoutes.trackDetailNamed(track.id!));
                            }
                          },
                        ),
                        const SizedBox(height: 28),
                        HomeMyGroupsSection(
                          groups: groups,
                          onSeeAll: () =>
                              _navigateToTab(NavigationController.tabGroups),
                          onGroupTap: (group) {
                            Get.toNamed(
                                AppRoutes.groupDetailNamed(group.id));
                          },
                        ),
                        const SizedBox(height: 28),
                        HomeCommunitiesSection(
                          communities: communities,
                          isLoading: _cc.isLoading.value,
                          onSeeAll: () =>
                              _navigateToTab(NavigationController.tabCommunity),
                          onCommunityTap: (community) {
                            Get.toNamed(AppRoutes.communityDetailNamed(
                                community.id));
                          },
                        ),
                        const SizedBox(height: 24),
                        const SizedBox(height: 110),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveGpsPulseDot extends StatefulWidget {
  const _LiveGpsPulseDot({super.key});

  @override
  State<_LiveGpsPulseDot> createState() => _LiveGpsPulseDotState();
}

class _LiveGpsPulseDotState extends State<_LiveGpsPulseDot>
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

class _AdvancedHomeHeader extends StatelessWidget {
  const _AdvancedHomeHeader({
    required this.displayName,
    required this.imageUrl,
    required this.timeOfDayWord,
    required this.onNotificationsTap,
    this.onAvatarTap,
  });

  final String displayName;
  final String? imageUrl;
  final String timeOfDayWord;
  final VoidCallback onNotificationsTap;
  final VoidCallback? onAvatarTap;

  static const _forestDeep = Color(0xFF0D2B1E);
  static const _primaryDark = Color(0xFF1B4332);
  static const _primary = Color(0xFF2D6A4F);
  static const _accent = Color(0xFF52B788);

  String get _avatarLetter {
    final t = displayName.trim();
    if (t.isEmpty) return '?';
    return t[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top + 12;
    final url = imageUrl?.trim();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -20,
          right: -20,
          child: IgnorePointer(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -30,
          child: IgnorePointer(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.02),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 60,
          child: IgnorePointer(
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accent.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(20, topPad, 20, 20),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const _LiveGpsPulseDot(),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE · GPS ACTIVE',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: _accent,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.65),
                              height: 1.25,
                            ),
                            children: [
                              TextSpan(text: 'Good $timeOfDayWord,\n'),
                              TextSpan(
                                text: displayName.toUpperCase(),
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  height: 1.05,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onTap: onNotificationsTap,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              Positioned(
                                top: 9,
                                right: 9,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE07B39),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _forestDeep,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: onAvatarTap,
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 21,
                                backgroundColor:
                                    _accent.withValues(alpha: 0.3),
                                backgroundImage: (url != null &&
                                        url.isNotEmpty)
                                    ? CachedNetworkImageProvider(url)
                                    : null,
                                child: (url == null || url.isEmpty)
                                    ? Text(
                                        _avatarLetter,
                                        style: GoogleFonts.bebasNeue(
                                          fontSize: 18,
                                          color: Colors.white,
                                          height: 1,
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _accent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _primaryDark,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const HomeHeaderStatusStrip(),
            ],
          ),
        ),
      ],
    );
  }
}
