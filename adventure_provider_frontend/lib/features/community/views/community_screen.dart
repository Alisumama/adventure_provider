import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/community_controller.dart';
import '../data/models/community_model.dart';

String _communityInitial(String? name) {
  final t = (name ?? '').trim();
  if (t.isEmpty) return '?';
  return t[0].toUpperCase();
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  Timer? _searchDebounce;
  late final CommunityController _c = Get.find<CommunityController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _c.fetchCommunities();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _goCreateCommunity() => Get.toNamed(AppRoutes.createCommunity);

  void _goCommunityDetail(CommunityModel community) {
    final id = community.id;
    if (id == null || id.isEmpty) return;
    Get.toNamed(AppRoutes.communityDetailNamed(id));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF7F5F0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Communities',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 28,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Find your adventure tribe',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _goCreateCommunity,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 46,
              margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2EDE8)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _c.searchController,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: 'Search communities...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onChanged: (v) {
                        _searchDebounce?.cancel();
                        _searchDebounce = Timer(
                          const Duration(milliseconds: 400),
                          () => _c.searchCommunities(v),
                        );
                      },
                    ),
                  ),
                  Obx(() {
                    if (_c.searchQuery.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        _searchDebounce?.cancel();
                        _c.searchController.clear();
                        _c.searchCommunities('');
                      },
                    );
                  }),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
              height: 34,
              child: Obx(() {
                final sel = _c.selectedCategory.value;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(
                        label: 'All',
                        selected: sel.isEmpty,
                        onTap: () => _c.setCategory(''),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: '🥾 Hiking',
                        selected: sel == 'hiking',
                        onTap: () => _c.setCategory('hiking'),
                      ),
                      const SizedBox(width: 8),
                      _CategoryChip(
                        label: '🚙 Off-Road',
                        selected: sel == 'offroading',
                        onTap: () => _c.setCategory('offroading'),
                      ),
                    ],
                  ),
                );
              }),
            ),
            Expanded(
              child: Obx(() {
                final my = _c.filteredCommunities
                    .where((x) => x.isMember)
                    .toList();

                if (my.isNotEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 20, left: 16),
                          child: Text(
                            'My Communities',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: my.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, i) {
                              final com = my[i];
                              return GestureDetector(
                                onTap: () => _goCommunityDetail(com),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _CommunityAvatar(
                                      name: com.name ?? '',
                                      imageUrl:
                                          ApiConfig.resolveMediaUrl(com.image),
                                      radius: 28,
                                      letterSize: 20,
                                    ),
                                    const SizedBox(height: 4),
                                    SizedBox(
                                      width: 70,
                                      child: Text(
                                        com.name ?? '',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        _buildDiscoverSection(),
                      ],
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: _buildDiscoverSection(),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverSection() {
    return Obx(() {
      if (_c.isLoading.value) {
        return Padding(
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Discover',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              _ShimmerCommunityCard(),
              _ShimmerCommunityCard(),
              _ShimmerCommunityCard(),
            ],
          ),
        );
      }

      if (_c.filteredCommunities.isEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 60),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.group_off_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No communities yet',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 26,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to create one!',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _goCreateCommunity,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Create Community',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Discover',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _c.filteredCommunities.length,
              itemBuilder: (context, i) {
                final com = _c.filteredCommunities[i];
                return _CommunityListCard(
                  community: com,
                  onOpenDetail: () => _goCommunityDetail(com),
                  onJoin: com.id == null || com.id!.isEmpty
                      ? null
                      : () => _c.joinCommunity(com.id!),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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
          border: selected
              ? null
              : Border.all(color: const Color(0xFFE2EDE8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w500 : FontWeight.normal,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _CommunityAvatar extends StatelessWidget {
  const _CommunityAvatar({
    required this.name,
    required this.imageUrl,
    required this.radius,
    required this.letterSize,
  });

  final String name;
  final String? imageUrl;
  final double radius;
  final double letterSize;

  @override
  Widget build(BuildContext context) {
    final letter = _communityInitial(name);

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: imageUrl!,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => _gradientLetter(letter),
            errorWidget: (_, __, ___) => _gradientLetter(letter),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.transparent,
      child: _gradientLetter(letter),
    );
  }

  Widget _gradientLetter(String letter) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        letter,
        style: GoogleFonts.bebasNeue(
          fontSize: letterSize,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ShimmerCommunityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE8E4DC),
        highlightColor: Colors.white,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EDE8)),
          ),
        ),
      ),
    );
  }
}

class _CommunityListCard extends StatelessWidget {
  const _CommunityListCard({
    required this.community,
    required this.onOpenDetail,
    required this.onJoin,
  });

  final CommunityModel community;
  final VoidCallback onOpenDetail;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    final imageUrl = ApiConfig.resolveMediaUrl(community.image);
    final members = community.membersCount ?? 0;

    return GestureDetector(
      onTap: onOpenDetail,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EDE8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 60,
                height: 60,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _thumbPlaceholder(),
                        errorWidget: (_, __, ___) => _thumbPlaceholder(),
                      )
                    : _thumbPlaceholder(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name ?? '',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!community.isPublic)
                          const Icon(
                            Icons.lock_outline,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.categoryLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      community.description ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$members members',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (community.isMember)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Joined',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppColors.success,
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: onJoin,
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Join',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _communityInitial(community.name),
        style: GoogleFonts.bebasNeue(
          fontSize: 26,
          color: Colors.white,
        ),
      ),
    );
  }
}
