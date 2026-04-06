import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/community_controller.dart';
import '../data/models/community_member_model.dart';

String? _media(String? s) => ApiConfig.resolveMediaUrl(s);

const Color _kPageBackground = Color(0xFFF7F5F0);
const Color _kSectionHeaderBg = Color(0xFFF0EDE8);

/// Full member list; [Get.arguments] is `communityId` (String).
class CommunityMembersScreen extends StatefulWidget {
  const CommunityMembersScreen({super.key});

  @override
  State<CommunityMembersScreen> createState() => _CommunityMembersScreenState();
}

class _CommunityMembersScreenState extends State<CommunityMembersScreen> {
  CommunityController get _c => Get.find<CommunityController>();
  AuthController get _auth => Get.find<AuthController>();

  String get _communityId {
    final args = Get.arguments;
    if (args is String && args.isNotEmpty) return args;
    return '';
  }

  @override
  void initState() {
    super.initState();
    final id = _communityId;
    if (id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _c.fetchMembers(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _communityId;
    if (id.isEmpty) {
      return Scaffold(
        backgroundColor: _kPageBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkBackground,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: Get.back,
          ),
        ),
        body: Center(
          child: Text(
            'Invalid community',
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _kPageBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: Get.back,
        ),
        title: Text(
          'Members',
          style: GoogleFonts.bebasNeue(
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Obx(() {
        final loading = _c.isMembersLoading.value;
        final members = _c.members;
        final viewerIsAdmin = _c.selectedCommunity.value?.isAdmin ?? false;

        if (loading && members.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        final admins = members.where((m) => m.isAdmin).toList();
        final moderators = members.where((m) => m.isModerator).toList();
        final regularMembers = members.where((m) => m.role == 'member').toList();

        final slivers = <Widget>[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _StatsRow(
                    adminCount: admins.length,
                    moderatorCount: moderators.length,
                    memberCount: regularMembers.length,
                  ),
                  if (viewerIsAdmin && (admins.isNotEmpty || moderators.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    Text(
                      'ADMINS & MODERATORS',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                  if (admins.isNotEmpty || moderators.isNotEmpty || regularMembers.isNotEmpty)
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ];

        void addRoleSection(String title, List<CommunityMemberModel> items) {
          if (items.isEmpty) return;
          slivers.add(
            SliverToBoxAdapter(child: _RoleSectionHeader(label: title)),
          );
          slivers.add(
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final m = items[index];
                  return _MemberTile(
                    member: m,
                    communityId: id,
                    currentUserId: _auth.user.value?.id,
                    viewerIsAdmin: viewerIsAdmin,
                    controller: _c,
                  );
                },
                childCount: items.length,
              ),
            ),
          );
        }

        addRoleSection('Admins', admins);
        addRoleSection('Moderators', moderators);
        addRoleSection('Members', regularMembers);

        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 32)));

        return CustomScrollView(slivers: slivers);
      }),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.adminCount,
    required this.moderatorCount,
    required this.memberCount,
  });

  final int adminCount;
  final int moderatorCount;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            value: adminCount.toString(),
            label: 'Admin',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: moderatorCount.toString(),
            label: 'Moderators',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatChip(
            value: memberCount.toString(),
            label: 'Members',
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2EDE8)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleSectionHeader extends StatelessWidget {
  const _RoleSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: _kSectionHeaderBg,
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: AppColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.communityId,
    required this.currentUserId,
    required this.viewerIsAdmin,
    required this.controller,
  });

  final CommunityMemberModel member;
  final String communityId;
  final String? currentUserId;
  final bool viewerIsAdmin;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    final showMenu =
        viewerIsAdmin && currentUserId != null && member.userId != currentUserId;
    final avatarUrl = _media(member.profileImage);

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE8E8E8),
                  backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(avatarUrl)
                      : null,
                  child: avatarUrl == null || avatarUrl.isEmpty
                      ? Icon(Icons.person, color: AppColors.textSecondary.withValues(alpha: 0.6), size: 28)
                      : null,
                ),
                if (member.isAdmin)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.star, size: 8, color: Colors.white),
                    ),
                  )
                else if (member.isModerator)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.shield, size: 8, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: member.roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        member.roleLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: member.roleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.totalTracks} tracks explored',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (showMenu)
            IconButton(
              icon: Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
              onPressed: () => _openMemberActions(context),
            ),
        ],
      ),
    );
  }

  void _openMemberActions(BuildContext context) {
    Get.bottomSheet<void>(
      _MemberActionsSheet(
        member: member,
        communityId: communityId,
        controller: controller,
        isViewerAdmin: viewerIsAdmin,
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }
}

class _MemberActionsSheet extends StatelessWidget {
  const _MemberActionsSheet({
    required this.member,
    required this.communityId,
    required this.controller,
    required this.isViewerAdmin,
  });

  final CommunityMemberModel member;
  final String communityId;
  final CommunityController controller;
  final bool isViewerAdmin;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.darkSurface,
            backgroundImage: _media(member.profileImage) != null &&
                    _media(member.profileImage)!.isNotEmpty
                ? CachedNetworkImageProvider(_media(member.profileImage)!)
                : null,
            child: _media(member.profileImage) == null || _media(member.profileImage)!.isEmpty
                ? Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: GoogleFonts.bebasNeue(fontSize: 24, color: Colors.white),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            member.name,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (member.role == 'member' && isViewerAdmin)
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppColors.primaryLight),
              title: Text(
                'Promote to Moderator',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              onTap: () {
                Get.back<void>();
                controller.promoteMember(communityId, member.userId);
              },
            ),
          if (member.role == 'moderator' && isViewerAdmin)
            ListTile(
              leading: const Icon(Icons.shield_outlined, color: AppColors.textSecondary),
              title: Text(
                'Demote to Member',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              ),
              onTap: () {
                Get.back<void>();
                controller.demoteModerator(communityId, member.userId);
              },
            ),
          if (member.role != 'admin') ...[
            if (isViewerAdmin) ...[
              const Divider(height: 1, color: Color(0x22FFFFFF)),
              ListTile(
                leading: const Icon(Icons.swap_horiz, color: AppColors.accent),
                title: Text(
                  'Transfer Admin Role',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                ),
                onTap: () {
                  Get.back<void>();
                  controller.transferAdmin(communityId, member.userId, member.name);
                },
              ),
            ],
            const Divider(height: 1, color: Color(0x22FFFFFF)),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined, color: AppColors.danger),
              title: Text(
                'Remove from Community',
                style: GoogleFonts.poppins(fontSize: 14, color: AppColors.danger),
              ),
              onTap: () {
                Get.back<void>();
                controller.removeMember(communityId, member.userId, member.name);
              },
            ),
          ],
        ],
      ),
    );
  }
}
