import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../groups/data/models/group_model.dart';

/// Vertical list of the user's groups, replacing the old upcoming-plans section.
class HomeMyGroupsSection extends StatelessWidget {
  const HomeMyGroupsSection({
    super.key,
    required this.groups,
    this.onSeeAll,
    this.onGroupTap,
  });

  final List<GroupModel> groups;
  final VoidCallback? onSeeAll;
  final void Function(GroupModel group)? onGroupTap;

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
                  'MY GROUPS',
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
                  width: 44,
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
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No groups yet. Join or create one!',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          for (var i = 0; i < groups.length; i++) ...[
            _GroupCard(
              group: groups[i],
              onTap: onGroupTap != null ? () => onGroupTap!(groups[i]) : null,
            ),
            if (i < groups.length - 1) const SizedBox(height: 12),
          ],
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, this.onTap});

  final GroupModel group;
  final VoidCallback? onTap;

  static const _textPrimary = Color(0xFF1A1A2E);

  @override
  Widget build(BuildContext context) {
    final activeCount = group.members.where((m) => m.isActive).length;
    final imageUrl = ApiConfig.resolveMediaUrl(group.coverImage);
    final letter = group.name.isNotEmpty ? group.name[0].toUpperCase() : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B4332), Color(0xFF52B788)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Center(
                            child: Text(
                              letter,
                              style: GoogleFonts.bebasNeue(
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            letter,
                            style: GoogleFonts.bebasNeue(
                              fontSize: 22,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$activeCount active member${activeCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                if (group.isTrackingActive) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF52B788).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF52B788),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'LIVE',
                          style: GoogleFonts.spaceMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D6A4F),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
