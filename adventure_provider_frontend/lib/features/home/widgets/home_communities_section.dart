import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../community/data/models/community_model.dart';

/// Horizontal strip of community cards on the home screen.
class HomeCommunitiesSection extends StatelessWidget {
  const HomeCommunitiesSection({
    super.key,
    required this.communities,
    this.isLoading = false,
    this.onSeeAll,
    this.onCommunityTap,
  });

  final List<CommunityModel> communities;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final void Function(CommunityModel community)? onCommunityTap;

  static const _textPrimary = Color(0xFF1A1A2E);
  static const _primary = Color(0xFF2D6A4F);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMMUNITIES',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.5,
                    color: _textPrimary,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 54,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const Spacer(),
            GestureDetector(
              onTap: onSeeAll,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(
                    'See All',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _primary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(height: 158, child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (isLoading && communities.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primaryLight,
          ),
        ),
      );
    }

    if (communities.isEmpty) {
      return Center(
        child: Text(
          'No communities yet',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(right: 4),
      itemCount: communities.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (_, index) {
        final c = communities[index];
        return _CommunityCard(
          community: c,
          onTap: onCommunityTap != null ? () => onCommunityTap!(c) : null,
        );
      },
    );
  }
}

class _CommunityCard extends StatelessWidget {
  const _CommunityCard({required this.community, this.onTap});

  final CommunityModel community;
  final VoidCallback? onTap;

  static const _textPrimary = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        ApiConfig.resolveMediaUrl(community.image) ??
        ApiConfig.resolveMediaUrl(community.coverImage);
    final letter = community.name.isNotEmpty
        ? community.name[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 158,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 78,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _FallbackCover(letter: letter),
                    )
                  else
                    _FallbackCover(letter: letter),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.05),
                            Colors.black.withValues(alpha: 0.35),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (community.isMember)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF52B788,
                          ).withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Joined',
                          style: GoogleFonts.spaceMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      community.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${community.membersCount} members · ${community.categoryLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF6B7280),
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
  }
}

class _FallbackCover extends StatelessWidget {
  const _FallbackCover({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B4332), Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.bebasNeue(
          fontSize: 32,
          color: Colors.white.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}
