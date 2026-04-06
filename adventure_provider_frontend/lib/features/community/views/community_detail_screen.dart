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
import '../controllers/community_controller.dart';
import '../data/models/community_model.dart';
import '../data/models/community_post_model.dart';

String _timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 45) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  if (d.inHours < 24) return '${d.inHours}h ago';
  if (d.inDays < 7) return '${d.inDays}d ago';
  return '${t.day}/${t.month}/${t.year}';
}

String? _media(String? s) => ApiConfig.resolveMediaUrl(s);

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
    _tabController = TabController(length: 2, vsync: this);
    final id = _communityId;
    if (id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _c.fetchCommunityDetail(id);
        _c.fetchPosts(id, refresh: true);
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
                      Tab(text: 'About'),
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
              _AboutTab(community: community),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            child: TextField(
              controller: controller.postContentController,
              minLines: 1,
              maxLines: 3,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Share something with the community...',
                filled: false,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => controller.createPost(communityId),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Post',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.currentUserId,
    required this.controller,
  });

  final CommunityPostModel post;
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
    final isMine = currentUserId != null && post.author.id == currentUserId;
    final authorAv = _media(post.author.profileImage);

    return Container(
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
          if (imgs.isNotEmpty) ...[
            const SizedBox(height: 10),
            _PostImageGrid(
              urls: imgs.map(_media).whereType<String>().toList(),
              onTapImage: (u) => _openImage(context, u),
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
              Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Reply',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
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
}

class _PostImageGrid extends StatelessWidget {
  const _PostImageGrid({
    required this.urls,
    required this.onTapImage,
  });

  final List<String> urls;
  final void Function(String url) onTapImage;

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
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        onTap: () => onTapImage(url),
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
