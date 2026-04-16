import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/widgets/auth_button.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../controllers/community_controller.dart';
import '../data/models/community_model.dart';
import '../data/models/community_post_model.dart';
import 'create_post_bottom_sheet.dart';

String _timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 45) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day}/${t.month}/${t.year}';
}

String? _media(String? s) => ApiConfig.resolveMediaUrl(s);

String _trackTypeLabel(String raw) {
  switch (raw) {
    case 'hiking':
      return '🥾 Hiking';
    case 'offroading':
    case 'offroad':
      return '🚙 Off-Road';
    case 'both':
      return '🏔️ Both';
    default:
      return raw.isEmpty ? 'Route' : raw;
  }
}

/// Detail page; pass [communityId] via `Get.arguments` (String) or route param `id`.
class CommunityDetailScreen extends StatefulWidget {
  const CommunityDetailScreen({super.key});

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _postsScrollController = ScrollController();

  CommunityController get _c => Get.find<CommunityController>();
  AuthController get _auth => Get.find<AuthController>();

  String get _communityId {
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) return args;
    return Get.parameters['id'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final id = _communityId;
    if (id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _c.fetchCommunityDetail(id);
        _c.fetchPosts(id, refresh: true);
        _c.fetchAnnouncements(id);
        _c.fetchEvents(id);
        _c.fetchRules(id);
      });
    }
    _postsScrollController.addListener(_onPostsScroll);
  }

  void _onPostsScroll() {
    final id = _communityId;
    if (id.isEmpty) return;
    final pos = _postsScrollController.position;
    if (!pos.hasViewportDimension) return;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    if (_c.isPostsLoading.value || !_c.hasMorePosts.value) return;
    _c.fetchPosts(id, refresh: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final id = _communityId;
    if (id.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: Get.back,
          ),
        ),
        body: const Center(
          child: Text('Invalid community', style: TextStyle(color: Colors.white70)),
        ),
      );
    }

    return Obx(() {
      final community = _c.selectedCommunity.value;
      if (community == null) {
        return Scaffold(
          backgroundColor: AppColors.darkBackground,
          appBar: AppBar(
            backgroundColor: AppColors.darkBackground,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: Get.back,
            ),
          ),
          body: const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight),
          ),
        );
      }

      return Scaffold(
        backgroundColor: AppColors.darkBackground,
        floatingActionButton: Obx(() {
          final c = _c.selectedCommunity.value;
          if (c == null || c.isMember) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: AppColors.primary,
            onPressed: () => _c.joinCommunity(id, navigateToDetail: false),
            icon: const Icon(Icons.group_add, color: Colors.white),
            label: Text(
              'Join Community',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          );
        }),
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  pinned: true,
                  expandedHeight: 220,
                  backgroundColor: AppColors.darkBackground,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: Get.back,
                  ),
                  actions: [
                    if (community.userRole == 'admin' ||
                        community.userRole == 'moderator')
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () => Get.toNamed(
                          AppRoutes.communitySettings,
                          arguments: id,
                        ),
                      ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _HeaderCover(community: community),
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    onTap: (i) => _c.selectedTab.value = i,
                    indicatorColor: AppColors.primaryLight,
                    labelColor: Colors.white,
                    unselectedLabelColor: AppColors.textSecondary,
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    unselectedLabelStyle: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'Posts'),
                      Tab(text: 'Announcements'),
                      Tab(text: 'Events'),
                      Tab(text: 'Rules'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [
              _PostsTab(
                communityId: id,
                community: community,
                scrollController: _postsScrollController,
                auth: _auth,
                controller: _c,
              ),
              _AnnouncementsTab(communityId: id, community: community, controller: _c),
              _EventsTab(communityId: id, community: community, controller: _c),
              _RulesTab(communityId: id, community: community, controller: _c),
            ],
          ),
        ),
      );
    });
  }
}

class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  _StickyTabBarDelegate(this.tabBar);

  final TabBar tabBar;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColors.darkBackground,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar;
  }
}

class _HeaderCover extends StatelessWidget {
  const _HeaderCover({required this.community});

  final CommunityModel community;

  @override
  Widget build(BuildContext context) {
    final cover = _media(community.coverImage ?? community.image);
    final avatar = _media(community.image);
    final letter = community.name.isNotEmpty
        ? community.name[0].toUpperCase()
        : '?';

    return Stack(
      fit: StackFit.expand,
      children: [
        if (cover != null && cover.isNotEmpty)
          CachedNetworkImage(
            imageUrl: cover,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: AppColors.darkSurface),
            errorWidget: (_, __, ___) => _gradientBg(),
          )
        else
          _gradientBg(),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16,
          bottom: 12,
          right: 16,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.darkSurface,
                  child: avatar != null && avatar.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatar,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) =>
                                _letterAvatar(letter, 24),
                          ),
                        )
                      : _letterAvatar(letter, 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      community.name,
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      community.categoryLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${community.membersCount} members',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        if (!community.isPublic) ...[
                          const SizedBox(width: 10),
                          Icon(
                            Icons.lock,
                            size: 11,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Private',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gradientBg() {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
        ),
      ),
    );
  }

  Widget _letterAvatar(String letter, double size) {
    return Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.bebasNeue(
          fontSize: size,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.communityId,
    required this.community,
    required this.scrollController,
    required this.auth,
    required this.controller,
  });

  final String communityId;
  final CommunityModel community;
  final ScrollController scrollController;
  final AuthController auth;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    final locked = !community.isPublic && !community.isMember;

    return ColoredBox(
      color: const Color(0xFFF7F5F0),
      child: Builder(
        builder: (context) {
          return CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              if (locked)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _PrivateLock(
                    communityId: communityId,
                    controller: controller,
                  ),
                )
              else ...[
                if (community.isMember)
                  SliverToBoxAdapter(
                    child: _PostComposer(
                      communityId: communityId,
                      controller: controller,
                      auth: auth,
                    ),
                  ),
                Obx(() {
                  final loading = controller.isPostsLoading.value;
                  final list = controller.posts;
                  if (loading && list.isEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Shimmer.fromColors(
                              baseColor: const Color(0xFFE2EDE8),
                              highlightColor: Colors.white,
                              child: Container(
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          childCount: 3,
                        ),
                      ),
                    );
                  }
                  if (list.isEmpty) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          'No posts yet',
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = list[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _PostCard(
                              post: post,
                              communityId: communityId,
                              currentUserId: auth.user.value?.id,
                              controller: controller,
                            ),
                          );
                        },
                        childCount: list.length,
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AnnouncementsTab extends StatelessWidget {
  const _AnnouncementsTab({
    required this.communityId,
    required this.community,
    required this.controller,
  });

  final String communityId;
  final CommunityModel community;
  final CommunityController controller;

  bool get _canPost =>
      community.userRole == 'admin' || community.userRole == 'moderator';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F5F0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Announcements',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_canPost)
                  GestureDetector(
                    onTap: () => _showCreateAnnouncementBottomSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isAnnouncementsLoading.value) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: 3,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Shimmer.fromColors(
                      baseColor: const Color(0xFFE2EDE8),
                      highlightColor: Colors.white,
                      child: Container(
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final list = controller.announcements;
              if (list.isEmpty) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.campaign_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No announcements yet',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_canPost)
                          Text(
                            'Create one to inform your members',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final a = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2EDE8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (a.isPinned)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.push_pin,
                                      size: 12,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pinned',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            Text(
                              a.timeAgo,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            if (_canPost)
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, size: 18),
                                onSelected: (v) {
                                  if (v == 'pin') controller.togglePin(a.id);
                                  if (v == 'delete') controller.deleteAnnouncement(a.id);
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Text(a.isPinned ? 'Unpin' : 'Pin'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          a.title,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          a.content,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                              backgroundImage: _media(a.author.profileImage) != null
                                  ? CachedNetworkImageProvider(_media(a.author.profileImage)!)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'by ${a.author.name}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showCreateAnnouncementBottomSheet(BuildContext context) {
    Get.bottomSheet<void>(
      _CreateAnnouncementBottomSheet(
        communityId: communityId,
        controller: controller,
      ),
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }
}

class _CreateAnnouncementBottomSheet extends StatefulWidget {
  const _CreateAnnouncementBottomSheet({
    required this.communityId,
    required this.controller,
  });

  final String communityId;
  final CommunityController controller;

  @override
  State<_CreateAnnouncementBottomSheet> createState() =>
      _CreateAnnouncementBottomSheetState();
}

class _CreateAnnouncementBottomSheetState extends State<_CreateAnnouncementBottomSheet> {
  final RxBool _isPinned = false.obs;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: bottomSafe + bottomInset + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF444444),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'New Announcement',
                style: GoogleFonts.bebasNeue(fontSize: 22, color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AuthTextField(
                controller: widget.controller.announcementTitleController,
                label: 'Title',
                hint: 'Title',
                prefixIcon: Icons.title,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AuthTextField(
                controller: widget.controller.announcementContentController,
                label: 'Content',
                hint: 'Write your announcement...',
                prefixIcon: Icons.article_outlined,
                minLines: 3,
                maxLines: 5,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Pin this announcement',
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
                  ),
                  const Spacer(),
                  Obx(() {
                    return Switch(
                      value: _isPinned.value,
                      activeColor: AppColors.primary,
                      onChanged: (v) => _isPinned.value = v,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: AuthButton(
                label: 'Post Announcement',
                onPressed: () => widget.controller
                    .createAnnouncement(widget.communityId, _isPinned.value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventsTab extends StatefulWidget {
  const _EventsTab({
    required this.communityId,
    required this.community,
    required this.controller,
  });

  final String communityId;
  final CommunityModel community;
  final CommunityController controller;

  @override
  State<_EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends State<_EventsTab> {
  bool _upcoming = true;

  bool get _canCreate =>
      widget.community.userRole == 'admin' || widget.community.userRole == 'moderator';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F5F0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Events',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_canCreate)
                  GestureDetector(
                    onTap: () => Get.toNamed(
                      AppRoutes.createCommunityEvent,
                      arguments: widget.communityId,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Upcoming',
                  selected: _upcoming,
                  onTap: () {
                    setState(() => _upcoming = true);
                    widget.controller.fetchEvents(widget.communityId, upcoming: true);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Past',
                  selected: !_upcoming,
                  onTap: () {
                    setState(() => _upcoming = false);
                    widget.controller.fetchEvents(widget.communityId, upcoming: false);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Obx(() {
              if (widget.controller.isEventsLoading.value) {
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: 3,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Shimmer.fromColors(
                      baseColor: const Color(0xFFE2EDE8),
                      highlightColor: Colors.white,
                      child: Container(
                        height: 170,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final list = widget.controller.events;
              if (list.isEmpty) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.event_outlined,
                          size: 48,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No events yet',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 20,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final isAdmin = widget.community.userRole == 'admin';
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final e = list[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2EDE8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.event, color: AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.title,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    e.formattedDate,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAdmin)
                              PopupMenuButton<String>(
                                padding: EdgeInsets.zero,
                                icon: const Icon(Icons.more_vert, size: 18),
                                onSelected: (v) {
                                  if (v == 'delete') {
                                    widget.controller.deleteEvent(widget.communityId, e.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (e.description.trim().isNotEmpty) ...[
                          Text(
                            e.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Row(
                          children: [
                            Text(
                              e.typeLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: e.difficultyColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                e.difficulty,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: e.difficultyColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.people_outline,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${e.participantsCount}/${e.maxParticipants}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        if (e.meetingPoint.address.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  e.meetingPoint.address,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(color: Color(0xFFE2EDE8), height: 1),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            if (e.isFull && !e.isJoined)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Event Full',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            else if (e.isPast)
                              Expanded(
                                child: Text(
                                  'This event has passed',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            else if (e.isJoined) ...[
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        size: 16,
                                        color: AppColors.success,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Joined',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => widget.controller.leaveEvent(widget.communityId, e.id),
                                child: Text(
                                  'Leave',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ] else
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => widget.controller.joinEvent(widget.communityId, e.id),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Join Event',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _RulesTab extends StatelessWidget {
  const _RulesTab({
    required this.communityId,
    required this.community,
    required this.controller,
  });

  final String communityId;
  final CommunityModel community;
  final CommunityController controller;

  bool get _isAdmin => community.userRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F5F0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Community Rules',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (_isAdmin)
                  GestureDetector(
                    onTap: () {
                      final role = controller.selectedCommunity.value?.userRole;
                      if (role != 'admin') {
                        Get.snackbar(
                          'Access denied',
                          'Only admins can edit rules.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                        return;
                      }
                      Get.toNamed(
                        AppRoutes.editRules,
                        arguments: communityId,
                      );
                    },
                    child: Text(
                      'Edit',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(() {
                final list = controller.rules.toList()
                  ..sort((a, b) => a.order.compareTo(b.order));
                if (list.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 40),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.gavel_outlined,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No rules set yet',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 20,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_isAdmin)
                            Text(
                              'Tap Edit to add community rules',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) {
                    final r = list[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2EDE8)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${i + 1}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.title,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (r.description.trim().isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    r.description,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      height: 1.4,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: selected ? null : Border.all(color: const Color(0xFFE2EDE8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _PrivateLock extends StatelessWidget {
  const _PrivateLock({
    required this.communityId,
    required this.controller,
  });

  final String communityId;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            'This is a private community',
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              fontSize: 22,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'Join to see posts',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          AuthButton(
            label: 'Request to Join',
            onPressed: () =>
                controller.joinCommunity(communityId, navigateToDetail: false),
          ),
        ],
      ),
    );
  }
}

class _PostComposer extends StatelessWidget {
  const _PostComposer({
    required this.communityId,
    required this.controller,
    required this.auth,
  });

  final String communityId;
  final CommunityController controller;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final u = auth.user.value;
    final avatarUrl = _media(u?.profileImage);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EDE8)),
      ),
      child: GestureDetector(
        onTap: () => _showCreatePostBottomSheet(context),
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
              backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                  ? CachedNetworkImageProvider(avatarUrl)
                  : null,
              child: avatarUrl == null || avatarUrl.isEmpty
                  ? Text(
                      (u?.name?.isNotEmpty ?? false)
                          ? u!.name![0].toUpperCase()
                          : '?',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDE8),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Share something...',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePostBottomSheet(BuildContext context) {
    Get.bottomSheet<void>(
      CreatePostBottomSheet(communityId: communityId),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.communityId,
    required this.currentUserId,
    required this.controller,
  });

  final CommunityPostModel post;
  final String communityId;
  final String? currentUserId;
  final CommunityController controller;

  void _openImage(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.of(ctx).pop(),
        child: ColoredBox(
          color: Colors.transparent,
          child: Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: url),
            ),
          ),
        ),
      ),
    );
  }

  void _showPostMenu(BuildContext context) {
    Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                title: Text(
                  'Delete',
                  style: GoogleFonts.poppins(color: AppColors.danger),
                ),
                onTap: () {
                  Get.back<void>();
                  controller.deletePost(post.id, showConfirmDialog: false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imgs = post.images.take(4).toList();
    final track = post.track;
    final attached = post.attachedTrack;
    final isMine = currentUserId != null && post.author.id == currentUserId;
    final authorAv = _media(post.author.profileImage);

    return GestureDetector(
      onLongPress: () => _showReactionPicker(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EDE8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                backgroundImage: authorAv != null && authorAv.isNotEmpty
                    ? CachedNetworkImageProvider(authorAv)
                    : null,
                child: authorAv == null || authorAv.isEmpty
                    ? Text(
                        post.author.name.isNotEmpty
                            ? post.author.name[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author.name,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _timeAgo(post.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isMine)
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
                  onPressed: () => _showPostMenu(context),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.content,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
          if (attached != null && attached.trackId.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.trackDetailNamed(attached.trackId)),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB7DEC8)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: _media(attached.coverImage) != null
                            ? CachedNetworkImage(
                                imageUrl: _media(attached.coverImage)!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => _attachedTrackFallback(),
                              )
                            : _attachedTrackFallback(),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📍 Attached Route',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            attached.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${_trackTypeLabel(attached.type)} · ${attached.distanceKm}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (imgs.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PostImageGrid(
              urls: imgs.map(_media).whereType<String>().toList(),
              onTapIndex: (idx) => Get.toNamed(
                AppRoutes.imageGallery,
                arguments: {
                  'images': post.images.map(_media).whereType<String>().toList(),
                  'initialIndex': idx,
                },
              ),
            ),
          ],
          if (track != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.trackDetailNamed(track.id)),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: _media(track.coverImage) != null
                            ? CachedNetworkImage(
                                imageUrl: _media(track.coverImage)!,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _trackPlaceholder(track.title),
                              )
                            : _trackPlaceholder(track.title),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${track.type} · ${track.distanceKm}',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: () => controller.toggleLikePost(post.id),
                child: Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 18,
                      color: post.isLiked ? AppColors.danger : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: () => Get.toNamed(
                  AppRoutes.postComments,
                  arguments: {'postId': post.id, 'communityId': communityId},
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount} Comments',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Obx(() {
            final idx = controller.posts.indexWhere((p) => p.id == post.id);
            final p = idx >= 0 ? controller.posts[idx] : post;
            final top = p.reactionSummary.topReactions;
            if (p.reactionSummary.totalReactions <= 0 || top.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: top
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0EDE8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: const Color(0xFFE2EDE8)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.key, style: const TextStyle(fontSize: 14)),
                                const SizedBox(width: 6),
                                Text(
                                  '${e.value}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            );
          }),
        ],
      ),
    ),
  );
  }

  void _showReactionPicker(BuildContext context) {
    Get.bottomSheet<void>(
      _ReactionPickerSheet(
        postId: post.id,
        controller: controller,
      ),
      isDismissible: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  Widget _trackPlaceholder(String title) {
    return Container(
      color: AppColors.primaryLight.withValues(alpha: 0.3),
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title[0].toUpperCase() : '?',
        style: GoogleFonts.bebasNeue(color: Colors.white, fontSize: 18),
      ),
    );
  }

  Widget _attachedTrackFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.terrain, color: Colors.white, size: 20),
    );
  }
}

class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({
    required this.urls,
    required this.onTapIndex,
  });

  final List<String> urls;
  final void Function(int index) onTapIndex;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) return const SizedBox.shrink();
    if (urls.length == 1) {
      return _tile(urls[0], height: 200);
    }
    if (urls.length == 2) {
      return Row(
        children: [
          Expanded(child: _tile(urls[0], height: 120)),
          const SizedBox(width: 8),
          Expanded(child: _tile(urls[1], height: 120)),
        ],
      );
    }
    if (urls.length == 3) {
      return Column(
        children: [
          _tile(urls[0], height: 140),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _tile(urls[1], height: 100)),
              const SizedBox(width: 8),
              Expanded(child: _tile(urls[2], height: 100)),
            ],
          ),
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _tile(urls[0], height: 100)),
            const SizedBox(width: 8),
            Expanded(child: _tile(urls[1], height: 100)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _tile(urls[2], height: 100)),
            const SizedBox(width: 8),
            Expanded(child: _tile(urls[3], height: 100)),
          ],
        ),
      ],
    );
  }

  Widget _tile(String url, {required double height}) {
    final idx = urls.indexOf(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        onTap: () => onTapIndex(idx < 0 ? 0 : idx),
        child: CachedNetworkImage(
          imageUrl: url,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _ReactionPickerSheet extends StatelessWidget {
  const _ReactionPickerSheet({
    required this.postId,
    required this.controller,
  });

  final String postId;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    const emojis = ['🔥', '❤️', '👏', '😮', '😂', '💪'];

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomSafe + 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF444444),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'React to post',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final idx = controller.posts.indexWhere((p) => p.id == postId);
                final userReaction =
                    idx >= 0 ? controller.posts[idx].reactionSummary.userReaction : null;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: emojis.map((emoji) {
                      final selected = userReaction == emoji;
                      return GestureDetector(
                        onTap: () async {
                          await controller.reactToPost(postId, emoji);
                          Get.back<void>();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selected ? AppColors.primaryLight : const Color(0xFF2A2A2A),
                            ),
                          ),
                          child: const Text('', style: TextStyle(fontSize: 0)),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: emojis
                      .map((emoji) => SizedBox(
                            width: 44,
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreatePostBottomSheet extends StatelessWidget {
  const _CreatePostBottomSheet({
    required this.communityId,
    required this.auth,
    required this.controller,
  });

  final String communityId;
  final AuthController auth;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final u = auth.user.value;
    final avatarUrl = _media(u?.profileImage);

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(bottom: bottomSafe + bottomInset + 16),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Create post',
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(avatarUrl)
                        : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(
                            (u?.name?.isNotEmpty ?? false) ? u!.name![0].toUpperCase() : '?',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller.postContentController,
                      minLines: 3,
                      maxLines: 6,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Share something...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF7F5F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              AuthButton(
                label: 'Post',
                onPressed: () async {
                  await controller.createPost(communityId);
                  Get.back<void>();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutTab extends StatelessWidget {
  const _AboutTab({required this.community});

  final CommunityModel community;

  @override
  Widget build(BuildContext context) {
    final desc = community.description.trim();
    final creator = community.createdBy;

    return ColoredBox(
      color: const Color(0xFFF7F5F0),
      child: Builder(
        builder: (context) {
          return CustomScrollView(
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'About',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 22,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2EDE8)),
                      ),
                      child: desc.isEmpty
                          ? Text(
                              'No description added yet',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            )
                          : Text(
                              community.description,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.6,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Details',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2EDE8)),
                      ),
                      child: Column(
                        children: [
                          _detailRow(
                            Icons.category_outlined,
                            'Category',
                            community.categoryLabel,
                          ),
                          const Divider(height: 20),
                          _detailRow(
                            Icons.visibility_outlined,
                            'Visibility',
                            community.isPublic ? 'Public' : 'Private',
                          ),
                          const Divider(height: 20),
                          _detailRow(
                            Icons.people_outline,
                            'Members',
                            '${community.membersCount} members',
                          ),
                          const Divider(height: 20),
                          _detailRow(
                            Icons.post_add_outlined,
                            'Posts',
                            '${community.totalPosts} posts',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Created by',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => Get.toNamed(AppRoutes.profile),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2EDE8)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  AppColors.primaryLight.withValues(alpha: 0.2),
                              backgroundImage: _media(creator.profileImage) != null
                                  ? CachedNetworkImageProvider(
                                      _media(creator.profileImage)!,
                                    )
                                  : null,
                              child: _media(creator.profileImage) == null
                                  ? Text(
                                      creator.name.isNotEmpty
                                          ? creator.name[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                creator.name,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
