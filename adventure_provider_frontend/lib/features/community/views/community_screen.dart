import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../controllers/community_controller.dart';
import '../data/models/community_model.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  CommunityController get _c => Get.find<CommunityController>();

  String? _resolveImage(String? stored) => ApiConfig.resolveMediaUrl(stored);

  static const _scaffoldBg = Color(0xFFF0EDE8);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _primary = Color(0xFF2D6A4F);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _scaffoldBg,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Obx(() {
          final mine =
              _c.communities.where((e) => e.isMember).toList(growable: false);
          final loading = _c.isLoading.value;
          final list = _c.communities;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _CommunityCollapsingHeaderDelegate(
                  pulseDot: const _DiscoverPulseDot(),
                  searchController: _c.searchController,
                  onSearchChanged: _c.scheduleSearchCommunities,
                  searchQueryRx: _c.searchQuery,
                  onClearSearch: _c.clearSearch,
                  selectedCategoryRx: _c.selectedCategory,
                  onCategory: _c.setCategory,
                  onCreateTap: () => Get.toNamed(AppRoutes.createCommunity),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (mine.isNotEmpty) ...[
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'MY COMMUNITIES',
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 20,
                                    letterSpacing: 1.2,
                                    color: _textPrimary,
                                    height: 1,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 36,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: _primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 96,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.zero,
                            itemCount: mine.length,
                            itemBuilder: (context, index) {
                              final community = mine[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  right: index < mine.length - 1 ? 14 : 0,
                                ),
                                child: _MyCommunityStripItem(
                                  community: community,
                                  resolveImage: _resolveImage,
                                  onTap: () => Get.toNamed(
                                    AppRoutes.communityDetailNamed(community.id),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DISCOVER',
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 20,
                                  letterSpacing: 1.2,
                                  color: _textPrimary,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 36,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: _primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '${list.length} communities',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (loading)
                        ...List.generate(
                          3,
                          (_) => const _CommunityShimmerCardNew(),
                        )
                      else if (list.isEmpty)
                        _EmptyStateNew(
                          onCreate: () =>
                              Get.toNamed(AppRoutes.createCommunity),
                        )
                      else
                        ...list.map(
                          (community) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _CommunityCardNew(
                              community: community,
                              resolveImage: _resolveImage,
                              onOpenDetail: () => Get.toNamed(
                                AppRoutes.communityDetailNamed(community.id),
                              ),
                              onJoin: () => _c.joinCommunity(community.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ─── Pulse dot (matches home LIVE dot behavior) ─────────────────────────────

class _DiscoverPulseDot extends StatefulWidget {
  const _DiscoverPulseDot();

  @override
  State<_DiscoverPulseDot> createState() => _DiscoverPulseDotState();
}

class _DiscoverPulseDotState extends State<_DiscoverPulseDot>
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

// ─── Collapsing header: pinned title row + scroll-away search / chips ─────

/// Min height = sticky title + “New”; max adds search row + chips.
class _CommunityCollapsingHeaderDelegate extends SliverPersistentHeaderDelegate {
  _CommunityCollapsingHeaderDelegate({
    required this.pulseDot,
    required this.searchController,
    required this.onSearchChanged,
    required this.searchQueryRx,
    required this.onClearSearch,
    required this.selectedCategoryRx,
    required this.onCategory,
    required this.onCreateTap,
  });

  final Widget pulseDot;
  final TextEditingController searchController;
  final void Function(String) onSearchChanged;
  final RxString searchQueryRx;
  final VoidCallback onClearSearch;
  final RxString selectedCategoryRx;
  final Future<void> Function(String) onCategory;
  final VoidCallback onCreateTap;

  static const _accent = Color(0xFF52B788);

  /// Fits title row + paddings without overflow when pinned.
  static const double minExtentCollapsed = 70;
  /// Extra space for search strip + spacing + chips (scrolls away completely).
  static const double expandableSection = 104;

  @override
  double get minExtent =>
      minExtentCollapsed; // tweak with layout if overflow on device

  @override
  double get maxExtent => minExtentCollapsed + expandableSection;

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
            padding: EdgeInsets.fromLTRB(18, 8 + expandT * 4, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Transform.scale(
                  scale: titleScale,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                  'DISCOVER',
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
                              'COMMUNITIES',
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
                      GestureDetector(
                        onTap: onCreateTap,
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 15 + expandT * 1,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'New',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
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
                  child: ClipRect(
                    child: Opacity(
                      opacity: expandT,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
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
                                        onChanged: onSearchChanged,
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
                                          hintText: 'Search communities...',
                                          hintStyle: GoogleFonts.poppins(
                                            fontSize: 12,
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
                                    child: Icon(
                                      Icons.close,
                                      size: 15,
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Obx(() {
                            final selected = selectedCategoryRx.value;
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _CategoryChipNew(
                                    label: 'All',
                                    active: selected.isEmpty,
                                    onTap: () => onCategory(''),
                                  ),
                                  const SizedBox(width: 8),
                                  _CategoryChipNew(
                                    label: '🥾 Hiking',
                                    active: selected == 'hiking',
                                    onTap: () => onCategory('hiking'),
                                  ),
                                  const SizedBox(width: 8),
                                  _CategoryChipNew(
                                    label: '🚙 Off-Road',
                                    active: selected == 'offroading',
                                    onTap: () => onCategory('offroading'),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
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
  bool shouldRebuild(covariant _CommunityCollapsingHeaderDelegate oldDelegate) {
    return oldDelegate.searchController != searchController ||
        oldDelegate.pulseDot != pulseDot ||
        oldDelegate.selectedCategoryRx != selectedCategoryRx ||
        oldDelegate.searchQueryRx != searchQueryRx ||
        oldDelegate.onCreateTap != onCreateTap;
  }
}

class _CategoryChipNew extends StatelessWidget {
  const _CategoryChipNew({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  static const _primaryDark = Color(0xFF1B4332);
  static const _accent = Color(0xFF52B788);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? _accent : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: active
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.2)),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? _primaryDark : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _MyCommunityStripItem extends StatelessWidget {
  const _MyCommunityStripItem({
    required this.community,
    required this.resolveImage,
    required this.onTap,
  });

  final CommunityModel community;
  final String? Function(String?) resolveImage;
  final VoidCallback onTap;

  static const _primary = Color(0xFF2D6A4F);
  static const _accent = Color(0xFF52B788);
  static const _textPrimary = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(community.image);
    final letter =
        community.name.isNotEmpty ? community.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: url != null && url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            width: 60,
                            height: 60,
                            placeholder: (_, __) => const SizedBox.expand(),
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                letter,
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              letter,
                              style: GoogleFonts.bebasNeue(
                                fontSize: 24,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              community.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityShimmerCardNew extends StatelessWidget {
  const _CommunityShimmerCardNew();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2EDE8),
        highlightColor: Colors.white,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2EDE8)),
          ),
        ),
      ),
    );
  }
}

class _CommunityCardNew extends StatelessWidget {
  const _CommunityCardNew({
    required this.community,
    required this.resolveImage,
    required this.onOpenDetail,
    required this.onJoin,
  });

  final CommunityModel community;
  final String? Function(String?) resolveImage;
  final VoidCallback onOpenDetail;
  final VoidCallback onJoin;

  static const _primary = Color(0xFF2D6A4F);
  static const _accent = Color(0xFF52B788);
  static const _textPrimary = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);
  static const _subtleBorder = Color(0xFFE2EDE8);

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(community.image);
    final letter =
        community.name.isNotEmpty ? community.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onOpenDetail,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _subtleBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: SizedBox(
                    height: 80,
                    width: double.infinity,
                    child: url != null && url.isNotEmpty
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0D2B1E),
                                        Color(0xFF2D6A4F),
                                      ],
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0D2B1E),
                                        Color(0xFF2D6A4F),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.5),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF0D2B1E),
                                  Color(0xFF2D6A4F),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      community.categoryLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 14,
                  child: community.isPublic
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Public',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _accent,
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lock,
                                size: 10,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Private',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                Positioned(
                  bottom: -20,
                  left: 14,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: const Color(0xFF1B4332),
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: url != null && url.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Center(
                              child: Text(
                                letter,
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              letter,
                              style: GoogleFonts.bebasNeue(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 28, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              community.name,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              community.description,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: _muted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      if (community.isMember)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'Joined',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: onJoin,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2D6A4F), Color(0xFF52B788)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: _primary.withValues(alpha: 0.25),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              'Join',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 14,
                        color: _muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${community.membersCount} members',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Icon(
                        Icons.article_outlined,
                        size: 14,
                        color: _muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${community.totalPosts} posts',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _muted,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: _muted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStateNew extends StatelessWidget {
  const _EmptyStateNew({required this.onCreate});

  final VoidCallback onCreate;

  static const _textPrimary = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EDE8)),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFF0EDE8),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.group_off_outlined,
              color: Color(0xFF6B7280),
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No communities yet',
            style: GoogleFonts.bebasNeue(
              fontSize: 24,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to create one!',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _muted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onCreate,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D6A4F).withValues(alpha: 0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Create Community',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
