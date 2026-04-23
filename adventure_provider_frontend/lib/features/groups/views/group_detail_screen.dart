import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/group_controller.dart';
import '../data/models/group_model.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  GroupController get _gc => Get.find<GroupController>();
  AuthController get _auth => Get.find<AuthController>();

  late final String _groupId;

  @override
  void initState() {
    super.initState();
    _groupId = Get.parameters['id'] ?? (Get.arguments as String? ?? '');
    _loadGroup();
    if (_groupId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _gc.fetchGroupLiveSessions(_groupId);
      });
    }
  }

  void _loadGroup() {
    final existing = _gc.myGroups.firstWhereOrNull((g) => g.id == _groupId);
    if (existing != null) {
      _gc.selectedGroup.value = existing;
    }
  }

  String? _resolveImage(String? stored) => ApiConfig.resolveMediaUrl(stored);

  String _formatSessionTime(DateTime? dt) {
    if (dt == null) return 'Unknown';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $h:$m';
  }

  void _shareGroup(GroupModel group) {
    final inviteCode = group.inviteCode;
    if (inviteCode == null || inviteCode.trim().isEmpty) {
      Get.snackbar(
        'Unavailable',
        'Invite code is not available yet.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    final message =
        'Join my group "${group.name}" on Adventure Provider.\nInvite code: $inviteCode';
    Share.share(message, subject: 'Join ${group.name}');
  }

  bool _isCurrentUserAdmin(GroupModel group) {
    final uid = _auth.user.value?.id;
    if (uid == null) return false;
    final member =
        group.members.firstWhereOrNull((m) => m.userId == uid && m.isActive);
    return member?.isAdmin ?? false;
  }

  Future<void> _joinLiveSession(String sessionId) async {
    await _gc.joinExistingLiveSession(
      _groupId,
      preferredSessionId: sessionId,
    );
    if (_gc.isTracking.value) {
      Get.toNamed(AppRoutes.liveGroupTracking, arguments: _groupId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Obx(() {
        final group = _gc.selectedGroup.value;
        if (group == null) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryLight));
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(group),
              const SizedBox(height: 20),
              _buildMembersSection(group),
              const SizedBox(height: 20),
              _buildLiveSessionsSection(),
              const SizedBox(height: 24),
              _buildActions(group),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  // ── Header with cover image ──

  Widget _buildHeader(GroupModel group) {
    final url = _resolveImage(group.coverImage);
    final letter = group.name.isNotEmpty ? group.name[0].toUpperCase() : '?';

    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cover image or gradient
          if (url != null && url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              placeholder: (_, __) => _headerGradient(letter),
              errorWidget: (_, __, ___) => _headerGradient(letter),
            )
          else
            _headerGradient(letter),

          // Scrim
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Get.back(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              onPressed: () => _shareGroup(group),
              tooltip: 'Share group',
            ),
          ),

          // Group name
          Positioned(
            bottom: 44,
            left: 16,
            right: 16,
            child: Text(
              group.name,
              style: GoogleFonts.bebasNeue(
                  fontSize: 22, color: Colors.white, letterSpacing: 1),
            ),
          ),

          // Invite code pill
          if (group.inviteCode != null && group.inviteCode!.isNotEmpty)
            Positioned(
              bottom: 12,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: group.inviteCode!));
                  Get.snackbar('Copied', 'Invite code copied to clipboard',
                      snackPosition: SnackPosition.BOTTOM,
                      duration: const Duration(seconds: 2));
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        group.inviteCode!,
                        style: GoogleFonts.spaceMono(
                            fontSize: 11,
                            color: AppColors.primaryLight,
                            letterSpacing: 1.5),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.copy,
                          size: 13, color: AppColors.primaryLight),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _headerGradient(String letter) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: GoogleFonts.bebasNeue(
              fontSize: 72, color: Colors.white.withValues(alpha: 0.3))),
    );
  }

  // ── Members section ──

  Widget _buildMembersSection(GroupModel group) {
    final activeMembers = group.members.where((m) => m.isActive).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('MEMBERS',
              style: GoogleFonts.bebasNeue(
                  fontSize: 16, color: Colors.white70, letterSpacing: 1)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: activeMembers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, index) {
              final member = activeMembers[index];
              return _MemberAvatar(
                member: member,
                resolveImage: _resolveImage,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Action buttons ──

  Widget _buildLiveSessionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LIVE SESSIONS',
              style: GoogleFonts.bebasNeue(
                  fontSize: 16, color: Colors.white70, letterSpacing: 1)),
          const SizedBox(height: 10),
          Obx(() {
            final sessions = _gc.groupLiveSessions;
            if (sessions.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  'No live sessions yet',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.white54),
                ),
              );
            }

            return Column(
              children: List.generate(sessions.length, (index) {
                final s = sessions[index];
                final isLive = s.isActive;
                return Padding(
                  padding: EdgeInsets.only(bottom: index == sessions.length - 1 ? 0 : 8),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: isLive ? () => _joinLiveSession(s.id) : null,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        decoration: BoxDecoration(
                          color: isLive
                              ? AppColors.primaryLight.withValues(alpha: 0.18)
                              : const Color(0xFF111827),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isLive ? AppColors.primaryLight : Colors.white12,
                          ),
                        ),
                        child: Text(
                          'Session ${sessions.length - index} · ${_formatSessionTime(s.startedAt)}${isLive ? ' · LIVE (tap to join)' : ''}',
                          style: GoogleFonts.spaceMono(
                            fontSize: 10,
                            color: isLive ? AppColors.primaryLight : Colors.white70,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActions(GroupModel group) {
    final isAdmin = _isCurrentUserAdmin(group);
    final tracking = group.isTrackingActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isAdmin && !tracking)
            _PrimaryButton(
              label: 'Start Group Tracking',
              onTap: () async {
                await _gc.startGroupTracking(_groupId);
                if (_gc.isTracking.value) {
                  Get.toNamed(AppRoutes.liveGroupTracking,
                      arguments: _groupId);
                }
              },
            ),
          if (tracking)
            _LiveButton(
              onTap: () async {
                await _gc.joinExistingLiveSession(_groupId);
                if (_gc.isTracking.value) {
                  Get.toNamed(
                      AppRoutes.liveGroupTracking, arguments: _groupId);
                }
              },
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  backgroundColor: AppColors.darkSurface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text('Leave Group',
                      style: GoogleFonts.poppins(color: Colors.white)),
                  content: Text('Are you sure you want to leave this group?',
                      style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.white70)),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: Text('Cancel',
                          style: GoogleFonts.poppins(color: Colors.white54)),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.back();
                        _gc.leaveGroup(_groupId);
                        Get.back();
                      },
                      child: Text('Leave',
                          style: GoogleFonts.poppins(color: AppColors.danger)),
                    ),
                  ],
                ),
              );
            },
            child: Text('Leave Group',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Member Avatar ──

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.resolveImage});

  final GroupMember member;
  final String? Function(String?) resolveImage;

  @override
  Widget build(BuildContext context) {
    final url = resolveImage(member.profileImage);
    final initials = member.name.isNotEmpty
        ? member.name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';

    return SizedBox(
      width: 56,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    AppColors.primaryLight.withValues(alpha: 0.2),
                child: url != null && url.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: url,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _Initials(initials),
                        ),
                      )
                    : _Initials(initials),
              ),
              if (member.isAdmin)
                Positioned(
                  top: -4,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.darkBackground,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star,
                        size: 12, color: AppColors.primaryLight),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            member.name.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryLight));
  }
}

// ── Primary action button ──

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(label,
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white)),
    );
  }
}

// ── Live session button with pulsing dot ──

class _LiveButton extends StatefulWidget {
  const _LiveButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_LiveButton> createState() => _LiveButtonState();
}

class _LiveButtonState extends State<_LiveButton>
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: widget.onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Text('Join Live Session',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.white)),
        ],
      ),
    );
  }
}
