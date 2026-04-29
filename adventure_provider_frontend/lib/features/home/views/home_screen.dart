import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/shell_layout.dart';
import '../../../core/controllers/navigation_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../community/controllers/community_controller.dart';
import '../../groups/controllers/group_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../track/controllers/track_controller.dart';
import '../models/active_session_data.dart';
import '../widgets/home_communities_section.dart';
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

  static String initialsFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final s = parts[0];
      if (s.length >= 2) return s.substring(0, 2).toUpperCase();
      return s[0].toUpperCase();
    }
    final a = parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts[1].isNotEmpty ? parts[1][0] : '';
    return ('$a$b').toUpperCase();
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

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning,';
    if (hour < 17) return 'Good afternoon,';
    return 'Good evening,';
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
    const headerBodyHeight = 68.0;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: headerBodyHeight,
              child: Obx(() {
                final displayName = _resolveDisplayName();
                final initials = initialsFromName(displayName);
                final imageUrl = _resolveProfileImageUrl();
                return _HomeHeaderBar(
                  displayName: displayName,
                  initials: initials,
                  imageUrl: imageUrl,
                  greeting: _greeting(),
                  onAvatarTap: () =>
                      _navigateToTab(NavigationController.tabProfile),
                );
              }),
            ),
            Expanded(
              child: Obx(() {
                final activeSession = _buildActiveSession();
                final tracks = _tc.myTracks;
                final groups = _gc.myGroups;
                final communities = _cc.communities;

                return ListView(
                  primary: false,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  children: [
                    HomeSessionHeroCard(
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
                    const SizedBox(height: 20),
                    HomeQuickMapSection(
                      onOpenFullMap: () =>
                          Get.toNamed(AppRoutes.exploreMap),
                      onOpenMapPreview: () =>
                          Get.toNamed(AppRoutes.exploreMap),
                    ),
                    const SizedBox(height: 20),
                    HomeNearbyRoutesSection(
                      tracks: tracks,
                      isLoading: _tc.isLoading.value,
                      onSeeAll: () =>
                          _navigateToTab(NavigationController.tabTrack),
                      onRouteTap: (track) {
                        if (track.id != null) {
                          Get.toNamed(AppRoutes.trackDetailNamed(track.id!));
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    HomeMyGroupsSection(
                      groups: groups,
                      onSeeAll: () =>
                          _navigateToTab(NavigationController.tabGroups),
                      onGroupTap: (group) {
                        Get.toNamed(AppRoutes.groupDetailNamed(group.id));
                      },
                    ),
                    const SizedBox(height: 20),
                    HomeCommunitiesSection(
                      communities: communities,
                      isLoading: _cc.isLoading.value,
                      onSeeAll: () =>
                          _navigateToTab(NavigationController.tabCommunity),
                      onCommunityTap: (community) {
                        Get.toNamed(
                            AppRoutes.communityDetailNamed(community.id));
                      },
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(height: kSosFabScrollBottomInset),
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

class _HomeHeaderBar extends StatelessWidget {
  const _HomeHeaderBar({
    required this.displayName,
    required this.initials,
    required this.imageUrl,
    required this.greeting,
    this.onAvatarTap,
  });

  final String displayName;
  final String initials;
  final String? imageUrl;
  final String greeting;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
            bottom: BorderSide(color: AppColors.homeHeaderBorder, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    greeting,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.homeGreetingGrey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bebasNeue(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 1.5,
                        color: AppColors.textPrimary,
                        height: 1.1),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onAvatarTap,
              child: _HomeAvatarCircle(
                  initials: initials, imageUrl: imageUrl),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAvatarCircle extends StatelessWidget {
  const _HomeAvatarCircle({required this.initials, required this.imageUrl});

  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryLight, AppColors.primary]),
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: (url != null && url.trim().isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                placeholder: (_, __) => _InitialsText(initials: initials),
                errorWidget: (_, __, ___) =>
                    _InitialsText(initials: initials),
              )
            : _InitialsText(initials: initials),
      ),
    );
  }
}

class _InitialsText extends StatelessWidget {
  const _InitialsText({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.bebasNeue(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.5,
            color: AppColors.surface,
            height: 1),
      ),
    );
  }
}
