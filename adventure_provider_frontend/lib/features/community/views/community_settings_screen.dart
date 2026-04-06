import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/widgets/auth_button.dart';
import '../../auth/widgets/auth_text_field.dart';
import '../controllers/community_controller.dart';
import '../data/models/community_member_model.dart';
import '../data/models/community_model.dart';

String? _media(String? s) => ApiConfig.resolveMediaUrl(s);

class CommunitySettingsScreen extends StatefulWidget {
  const CommunitySettingsScreen({super.key});

  @override
  State<CommunitySettingsScreen> createState() => _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends State<CommunitySettingsScreen> {
  final _picker = ImagePicker();

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
    if (id.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final match = _c.selectedCommunity.value;
      if (match == null || match.id != id) {
        await _c.fetchCommunityDetail(id);
      }
      final com = _c.selectedCommunity.value;
      if (com != null && com.id == id) {
        _c.editNameController.text = com.name;
        _c.editDescriptionController.text = com.description;
      }
      await _c.fetchMembers(id);
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final id = _communityId;
    if (id.isEmpty) return;
    final x = await _picker.pickImage(source: source, imageQuality: 85);
    if (x != null && mounted) {
      await _c.updateCommunityImageFromSettings(id, File(x.path));
    }
  }

  void _openImagePickerSheet() {
    Get.bottomSheet<void>(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white70),
                title: Text('Choose from gallery', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () async {
                  Get.back<void>();
                  await _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white70),
                title: Text('Take a photo', style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () async {
                  Get.back<void>();
                  await _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditNameSheet(String communityId) {
    Get.bottomSheet<void>(
      _EditNameSheet(communityId: communityId, controller: _c),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showEditDescriptionSheet(String communityId) {
    Get.bottomSheet<void>(
      _EditDescriptionSheet(communityId: communityId, controller: _c),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showVisibilitySheet(CommunityModel community, String communityId) {
    Get.bottomSheet<void>(
      _VisibilitySheet(
        community: community,
        communityId: communityId,
        controller: _c,
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showCategorySheet(CommunityModel community, String communityId) {
    Get.bottomSheet<void>(
      _CategorySheet(
        community: community,
        communityId: communityId,
        controller: _c,
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  void _showMemberActions(CommunityMemberModel member, String communityId) {
    final isViewerAdmin = _c.selectedCommunity.value?.isAdmin ?? false;
    Get.bottomSheet<void>(
      _MemberActionsSheet(
        member: member,
        communityId: communityId,
        controller: _c,
        isViewerAdmin: isViewerAdmin,
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
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

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: Get.back,
        ),
        title: Text(
          'Community Settings',
          style: GoogleFonts.bebasNeue(
            fontSize: 22,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Obx(() {
        final community = _c.selectedCommunity.value;
        if (community == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryLight),
          );
        }

        final isAdmin = community.isAdmin;
        final isModerator = community.isModerator;
        final canEditDescription = isAdmin || isModerator;
        final members = _c.members;
        final displayMembers = members.length > 5 ? members.take(5).toList() : members;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isAdmin) ...[
                _SectionLabel(text: 'COMMUNITY PHOTO'),
                Center(
                  child: SizedBox(
                    width: 104,
                    height: 104,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AppColors.darkSurface,
                          child: community.image != null && community.image!.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: _media(community.image) ?? '',
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorWidget: (_, __, ___) => _LetterAvatar(letter: community.name),
                                  ),
                                )
                              : _LetterAvatar(letter: community.name),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _openImagePickerSheet,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.darkBackground, width: 2),
                              ),
                              child: const Icon(Icons.edit, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              _SectionLabel(text: 'GENERAL INFO'),
              _SettingsCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.group_outlined, color: AppColors.primary, size: 22),
                      title: Text(
                        'Community Name',
                        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      subtitle: Obx(
                        () => Text(
                          _c.selectedCommunity.value?.name ?? community.name,
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      trailing: isAdmin
                          ? const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary)
                          : null,
                      onTap: isAdmin ? () => _showEditNameSheet(id) : null,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
                      title: Text(
                        'Description',
                        style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                      ),
                      subtitle: Obx(
                        () => Text(
                          _c.selectedCommunity.value?.description ?? community.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      trailing: canEditDescription
                          ? const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary)
                          : null,
                      onTap: canEditDescription ? () => _showEditDescriptionSheet(id) : null,
                    ),
                  ],
                ),
              ),
              if (isAdmin) ...[
                _SectionLabel(text: 'COMMUNITY TYPE'),
                _SettingsCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(
                          community.isPublic ? Icons.public : Icons.lock_outline,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        title: Text(
                          'Visibility',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          _visibilitySubtitle(community.visibility),
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () => _showVisibilitySheet(community, id),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.category_outlined, color: AppColors.primary, size: 22),
                        title: Text(
                          'Category',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary),
                        ),
                        subtitle: Text(
                          community.categoryLabel,
                          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                        onTap: () => _showCategorySheet(community, id),
                      ),
                    ],
                  ),
                ),
              ],
              Obx(
                () => _SectionLabel(
                  text: 'MEMBERS  (${_c.members.length})',
                ),
              ),
              _SettingsCard(
                child: Obx(() {
                  if (_c.isMembersLoading.value) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    );
                  }
                  if (members.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No members yet',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(color: AppColors.textSecondary),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < displayMembers.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        _MemberTile(
                          member: displayMembers[i],
                          isAdmin: isAdmin,
                          currentUserId: _auth.user.value?.id,
                          onMore: () => _showMemberActions(displayMembers[i], id),
                        ),
                      ],
                      if (members.length > 5)
                        TextButton(
                          onPressed: () => Get.toNamed(
                            AppRoutes.communityMembers,
                            arguments: id,
                          ),
                          child: Text(
                            'View All ${members.length} Members →',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              if (isAdmin) ...[
                _SectionLabel(text: 'DANGER ZONE'),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD62828).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFD62828).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Obx(
                    () => ListTile(
                      leading: const Icon(Icons.delete_forever, color: AppColors.danger, size: 22),
                      title: Text(
                        'Delete Community',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Permanently delete this community and all posts',
                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      trailing: _c.isSettingsLoading.value
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.danger,
                              ),
                            )
                          : const Icon(Icons.chevron_right, color: AppColors.danger),
                      onTap: _c.isSettingsLoading.value ? null : () => _c.deleteCommunity(id),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }
}

String _visibilitySubtitle(String v) {
  if (v == 'public') return 'Public';
  if (v == 'private') return 'Private';
  return v;
}

class _LetterAvatar extends StatelessWidget {
  const _LetterAvatar({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    final ch = letter.isNotEmpty ? letter[0].toUpperCase() : '?';
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primaryDark,
          ],
        ),
      ),
      child: Center(
        child: Text(
          ch,
          style: GoogleFonts.bebasNeue(fontSize: 32, color: Colors.white),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: AppColors.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2EDE8)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  const _MemberTile({
    required this.member,
    required this.isAdmin,
    required this.currentUserId,
    required this.onMore,
  });

  final CommunityMemberModel member;
  final bool isAdmin;
  final String? currentUserId;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final showMenu = isAdmin && currentUserId != null && member.userId != currentUserId;
    final avatarUrl = _media(member.profileImage);

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: const Color(0xFFE8F5EF),
        backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
            ? CachedNetworkImageProvider(avatarUrl)
            : null,
        child: avatarUrl == null || avatarUrl.isEmpty
            ? const Icon(Icons.person, color: AppColors.textSecondary, size: 22)
            : null,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              member.name,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
      subtitle: Text(
        '${member.totalTracks} tracks · ${member.totalAdventures} adventures',
        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
      ),
      trailing: showMenu
          ? IconButton(
              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
              onPressed: onMore,
            )
          : null,
    );
  }
}

class _EditNameSheet extends StatelessWidget {
  const _EditNameSheet({required this.communityId, required this.controller});

  final String communityId;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Name',
                  style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: controller.editNameController,
                  label: 'Community Name',
                  hint: 'Community name',
                  prefixIcon: Icons.group_outlined,
                  fillColor: AppColors.darkSurface,
                ),
                const SizedBox(height: 16),
                AuthButton(
                  label: 'Save Name',
                  onPressed: () async {
                    await controller.updateCommunitySettings(
                      communityId,
                      name: controller.editNameController.text.trim(),
                    );
                    Get.back<void>();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditDescriptionSheet extends StatelessWidget {
  const _EditDescriptionSheet({required this.communityId, required this.controller});

  final String communityId;
  final CommunityController controller;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Edit Description',
                  style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: controller.editDescriptionController,
                  label: 'Description',
                  hint: 'Describe your community',
                  prefixIcon: Icons.description_outlined,
                  fillColor: AppColors.darkSurface,
                  maxLines: 4,
                  minLines: 3,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                AuthButton(
                  label: 'Save Description',
                  onPressed: () async {
                    await controller.updateCommunitySettings(
                      communityId,
                      description: controller.editDescriptionController.text.trim(),
                    );
                    Get.back<void>();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisibilitySheet extends StatefulWidget {
  const _VisibilitySheet({
    required this.community,
    required this.communityId,
    required this.controller,
  });

  final CommunityModel community;
  final String communityId;
  final CommunityController controller;

  @override
  State<_VisibilitySheet> createState() => _VisibilitySheetState();
}

class _VisibilitySheetState extends State<_VisibilitySheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.community.visibility;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Change Visibility',
              style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _VisibilityOptionCard(
                    selected: _selected == 'public',
                    icon: Icons.public,
                    title: 'Public',
                    subtitle: 'Anyone can join',
                    onTap: () => setState(() => _selected = 'public'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VisibilityOptionCard(
                    selected: _selected == 'private',
                    icon: Icons.lock_outline,
                    title: 'Private',
                    subtitle: 'Invite only',
                    onTap: () => setState(() => _selected = 'private'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AuthButton(
              label: 'Save',
              onPressed: () async {
                await widget.controller.updateCommunitySettings(
                  widget.communityId,
                  visibility: _selected,
                );
                Get.back<void>();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySheet extends StatefulWidget {
  const _CategorySheet({
    required this.community,
    required this.communityId,
    required this.controller,
  });

  final CommunityModel community;
  final String communityId;
  final CommunityController controller;

  @override
  State<_CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<_CategorySheet> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.community.category;
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Change Category',
              style: GoogleFonts.bebasNeue(fontSize: 20, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CategoryOptionCard(
                    selected: _selected == 'hiking',
                    icon: Icons.hiking,
                    label: 'Hiking',
                    onTap: () => setState(() => _selected = 'hiking'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CategoryOptionCard(
                    selected: _selected == 'offroading',
                    icon: Icons.directions_car_outlined,
                    label: 'Off-Road',
                    onTap: () => setState(() => _selected = 'offroading'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _CategoryOptionCard(
                    selected: _selected == 'both',
                    icon: Icons.terrain,
                    label: 'Both',
                    onTap: () => setState(() => _selected = 'both'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            AuthButton(
              label: 'Save',
              onPressed: () async {
                await widget.controller.updateCommunitySettings(
                  widget.communityId,
                  category: _selected,
                );
                Get.back<void>();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOptionCard extends StatelessWidget {
  const _VisibilityOptionCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkSurface : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryLight : const Color(0xFF2A2A2A),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28,
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryOptionCard extends StatelessWidget {
  const _CategoryOptionCard({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.darkSurface : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryLight : const Color(0xFF2A2A2A),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.primaryLight : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
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
