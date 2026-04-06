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

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  CommunityController get _c => Get.find<CommunityController>();

  String? _resolveImage(String? stored) => ApiConfig.resolveMediaUrl(stored);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF7F5F0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Communities', style: GoogleFonts.bebasNeue(fontSize: 28, letterSpacing: 1.5, color: AppColors.textPrimary)),
                      Text('Find your adventure tribe', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Get.toNamed(AppRoutes.createCommunity),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.add, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 46,
              margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2EDE8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _c.searchController,
                      onChanged: _c.scheduleSearchCommunities,
                      style: GoogleFonts.poppins(fontSize: 13),
                      decoration: const InputDecoration(
                        filled: false,
                        isDense: true,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        hintText: 'Search communities...',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (_c.searchQuery.value.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), icon: const Icon(Icons.close, size: 20), color: AppColors.textSecondary, onPressed: _c.clearSearch);
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
              child: Obx(() {
                final selected = _c.selectedCategory.value;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryChip(label: 'All', selected: selected.isEmpty, onTap: () => _c.setCategory('')),
                      const SizedBox(width: 8),
                      _CategoryChip(label: '🥾 Hiking', selected: selected == 'hiking', onTap: () => _c.setCategory('hiking')),
                      const SizedBox(width: 8),
                      _CategoryChip(label: '🚙 Off-Road', selected: selected == 'offroading', onTap: () => _c.setCategory('offroading')),
                    ],
                  ),
                );
              }),
            ),
            Expanded(
              child: Obx(() {
                final mine = _c.communities.where((e) => e.isMember).toList(growable: false);
                final loading = _c.isLoading.value;
                final list = _c.communities;

                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mine.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 20, left: 16),
                          child: Text(
                            'My Communities',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 80,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: mine.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final community = mine[index];
                              return _MyCommunityAvatar(community: community, resolveImage: _resolveImage, onTap: () => Get.toNamed(AppRoutes.communityDetailNamed(community.id)));
                            },
                          ),
                        ),
                      ],
                      Padding(
                        padding: const EdgeInsets.only(top: 20, left: 16),
                        child: Text(
                          'Discover',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (loading)
                        ...List.generate(3, (_) => const _CommunityShimmerCard())
                      else if (list.isEmpty)
                        _EmptyState(onCreate: () => Get.toNamed(AppRoutes.createCommunity))
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            return _CommunityCard(community: list[index], resolveImage: _resolveImage, onOpenDetail: () => Get.toNamed(AppRoutes.communityDetailNamed(list[index].id)), onJoin: () => _c.joinCommunity(list[index].id));
                          },
                        ),
                    ],
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

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

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
          border: Border.all(color: selected ? AppColors.primary : const Color(0xFFE2EDE8)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : AppColors.textSecondary),
        ),
      ),
    );
  }
}

class _MyCommunityAvatar extends StatelessWidget {
  const _MyCommunityAvatar({required this.community, required this.resolveImage, required this.onTap});

  final CommunityModel community;
  final String? Function(String?) resolveImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(community.image);
    final letter = community.name.isNotEmpty ? community.name[0].toUpperCase() : '?';

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primaryLight.withValues(alpha: 0.2),
            child: url != null && url.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: url,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.primaryLight.withValues(alpha: 0.3)),
                    errorWidget: (_, __, ___) => _LetterGradient(letter: letter, fontSize: 20),
                  )
                : _LetterGradient(letter: letter, fontSize: 20),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              community.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityShimmerCard extends StatelessWidget {
  const _CommunityShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2EDE8),
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

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.community, required this.resolveImage, required this.onOpenDetail, required this.onJoin});

  final CommunityModel community;
  final String? Function(String?) resolveImage;
  final VoidCallback onOpenDetail;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(community.image);
    final letter = community.name.isNotEmpty ? community.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onOpenDetail,
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EDE8)),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: url != null && url.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: const Color(0xFFE2EDE8)),
                          errorWidget: (_, __, ___) => _LetterGradient(letter: letter, fontSize: 26),
                        )
                      : _LetterGradient(letter: letter, fontSize: 26),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              community.name,
                              style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                            ),
                          ),
                          if (!community.isPublic)
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 2),
                              child: Icon(Icons.lock_outline, size: 14, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(community.categoryLabel, style: GoogleFonts.poppins(fontSize: 11, color: AppColors.primary)),
                      const SizedBox(height: 4),
                      Text(
                        community.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people_outline, size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text('${community.membersCount} members', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary)),
                          const Spacer(),
                          if (community.isMember)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                              child: Text(
                                'Joined',
                                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.success),
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: onJoin,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                                child: Text(
                                  'Join',
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white),
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
      ),
    );
  }
}

class _LetterGradient extends StatelessWidget {
  const _LetterGradient({required this.letter, required this.fontSize});

  final String letter;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primaryLight])),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.bebasNeue(fontSize: fontSize, color: Colors.white),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text('No communities yet', style: GoogleFonts.bebasNeue(fontSize: 26, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Be the first to create one!', style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onCreate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  'Create Community',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
