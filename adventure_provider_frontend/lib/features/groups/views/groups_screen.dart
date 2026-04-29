import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/shell_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/group_controller.dart';
import '../data/models/group_model.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  GroupController get _gc => Get.find<GroupController>();

  final RxInt _activeTab = 0.obs;

  @override
  void initState() {
    super.initState();
    _gc.fetchMyGroups();
  }

  String? _resolveImage(String? stored) => ApiConfig.resolveMediaUrl(stored);

  void _showCreateGroupDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Create Group',
            style: GoogleFonts.bebasNeue(
                fontSize: 22, color: Colors.white, letterSpacing: 1)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Group name',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.white38),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              maxLines: 2,
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Description (optional)',
                hintStyle: GoogleFonts.poppins(
                    fontSize: 14, color: Colors.white38),
                filled: true,
                fillColor: AppColors.darkBackground,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Get.back();
              _gc.createGroup(name, descCtrl.text.trim());
            },
            child: Text('Create',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog() {
    final codeCtrl = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Join Group',
            style: GoogleFonts.bebasNeue(
                fontSize: 22, color: Colors.white, letterSpacing: 1)),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          style: GoogleFonts.spaceMono(
              fontSize: 18, color: AppColors.primaryLight, letterSpacing: 4),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'INVITE CODE',
            hintStyle: GoogleFonts.spaceMono(
                fontSize: 14, color: Colors.white38, letterSpacing: 2),
            filled: true,
            fillColor: AppColors.darkBackground,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryLight,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              final code = codeCtrl.text.trim();
              if (code.isEmpty) return;
              Get.back();
              _gc.joinGroup(code);
            },
            child: Text('Join',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.darkBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 12),
              child: Row(
                children: [
                  Text('GROUPS',
                      style: GoogleFonts.bebasNeue(
                          fontSize: 24,
                          color: Colors.white,
                          letterSpacing: 1.5)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.white70),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle_outline,
                        color: AppColors.primaryLight),
                    onPressed: _showCreateGroupDialog,
                  ),
                ],
              ),
            ),

            // // ── Tabs ──
            // Padding(
            //   padding:
            //       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            //   child: Obx(() {
            //     return Row(
            //       children: [
            //         _TabButton(
            //           label: 'My Groups',
            //           isActive: _activeTab.value == 0,
            //           onTap: () => _activeTab.value = 0,
            //         ),
            //         const SizedBox(width: 12),
            //         _TabButton(
            //           label: 'Discover',
            //           isActive: _activeTab.value == 1,
            //           onTap: () => _activeTab.value = 1,
            //         ),
            //       ],
            //     );
            //   }),
            // ),

            // ── Body ──
            Expanded(
              child: Obx(() {
                if (_activeTab.value == 0) {
                  return _buildMyGroupsTab();
                }
                return _buildDiscoverTab();
              }),
            ),

            // ── Bottom action buttons ──
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, bottom: 12, top: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryLight,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showCreateGroupDialog,
                      child: Text('Create Group',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryLight),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _showJoinGroupDialog,
                      child: Text('Join with Code',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.primaryLight)),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: kSosFabScrollBottomInset - 100),
          ],
        ),
      ),
    );
  }

  Widget _buildMyGroupsTab() {
    final loading = _gc.isLoading.value;
    final groups = _gc.myGroups;

    if (loading && groups.isEmpty) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight));
    }

    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.group_off_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            Text('No groups yet',
                style: GoogleFonts.bebasNeue(
                    fontSize: 26, color: Colors.white54)),
            const SizedBox(height: 8),
            Text('Create or join one!',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white38)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _gc.fetchMyGroups,
      color: AppColors.primaryLight,
      backgroundColor: AppColors.darkSurface,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return _GroupCard(
            group: groups[index],
            resolveImage: _resolveImage,
            onTap: () =>
                Get.toNamed(AppRoutes.groupDetailNamed(groups[index].id)),
          );
        },
      ),
    );
  }

  Widget _buildDiscoverTab() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.explore_outlined, size: 64, color: Colors.white24),
          const SizedBox(height: 16),
          Text('Coming Soon',
              style:
                  GoogleFonts.bebasNeue(fontSize: 26, color: Colors.white54)),
          const SizedBox(height: 8),
          Text('Discover groups near you',
              style:
                  GoogleFonts.poppins(fontSize: 13, color: Colors.white38)),
        ],
      ),
    );
  }
}

// ── Tab Button ──

class _TabButton extends StatelessWidget {
  const _TabButton(
      {required this.label, required this.isActive, required this.onTap});

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color:
                  isActive ? AppColors.primaryLight : Colors.white24),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : Colors.white54,
          ),
        ),
      ),
    );
  }
}

// ── Group Card ──

class _GroupCard extends StatelessWidget {
  const _GroupCard(
      {required this.group, required this.resolveImage, required this.onTap});

  final GroupModel group;
  final String? Function(String?) resolveImage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(group.coverImage);
    final letter =
        group.name.isNotEmpty ? group.name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              // ── Cover image / placeholder ──
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: url != null && url.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _GradientPlaceholder(
                              letter: letter),
                          errorWidget: (_, __, ___) =>
                              _GradientPlaceholder(letter: letter),
                        )
                      : _GradientPlaceholder(letter: letter),
                ),
              ),
              const SizedBox(width: 12),

              // ── Info ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                        '${group.memberCount} member${group.memberCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: Colors.white38)),
                    if (group.inviteCode != null &&
                        group.inviteCode!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(group.inviteCode!,
                          style: GoogleFonts.spaceMono(
                              fontSize: 10,
                              color: AppColors.primaryLight,
                              letterSpacing: 1.5)),
                    ],
                  ],
                ),
              ),

              // ── Live badge ──
              if (group.isTrackingActive) const _LiveBadge(),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Gradient placeholder ──

class _GradientPlaceholder extends StatelessWidget {
  const _GradientPlaceholder({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primaryLight])),
      alignment: Alignment.center,
      child: Text(letter,
          style: GoogleFonts.bebasNeue(fontSize: 22, color: Colors.white)),
    );
  }
}

// ── Live badge with pulsing animation ──

class _LiveBadge extends StatefulWidget {
  const _LiveBadge();

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text('LIVE',
                style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryLight)),
          ],
        ),
      ),
    );
  }
}
