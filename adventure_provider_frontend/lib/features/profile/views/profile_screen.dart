import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/profile_controller.dart';
import '../data/models/profile_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>();

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Obx(() {
          final loading = c.isLoading.value;
          final p = c.profile.value;
          if (loading && p == null) {
            return const _ProfileLoadingShimmer();
          }
          return _ProfileContent(
            profile: p,
            onChangePhoto: c.updateProfileImage,
            onChangeCover: c.updateCoverImage,
            onLogout: c.logout,
            onDeleteAccount: c.deleteAccount,
          );
        }),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.profile,
    required this.onChangePhoto,
    required this.onChangeCover,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final ProfileModel? profile;
  final VoidCallback onChangePhoto;
  final VoidCallback onChangeCover;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  static const BoxDecoration _coverGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.primaryDark,
        AppColors.primary,
        AppColors.primaryLight,
      ],
    ),
  );

  static String _initials(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '?';
    final parts = n.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final s = parts[0];
      return (s.length >= 2 ? s.substring(0, 2) : s.substring(0, 1))
          .toUpperCase();
    }
    final a = parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts[1].isNotEmpty ? parts[1][0] : '';
    return ('$a$b').toUpperCase();
  }

  Future<void> _showEditBottomSheet(
    BuildContext context, {
    required String title,
    required String initialValue,
    required String fieldKey,
    required bool Function(String v) validator,
    required Map<String, dynamic> Function(String v) buildPayload,
  }) async {
    final c = Get.find<ProfileController>();
    final ctrl = TextEditingController(text: initialValue);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.viewInsetsOf(ctx).bottom;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottom),
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
                title.toUpperCase(),
                style: GoogleFonts.bebasNeue(
                  fontSize: 20,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  labelText: fieldKey,
                  labelStyle: GoogleFonts.poppins(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final loading = c.isUpdating.value;
                return FilledButton(
                  onPressed: loading
                      ? null
                      : () async {
                          final v = ctrl.text.trim();
                          if (!validator(v)) {
                            Get.snackbar(
                              'Invalid',
                              'Please enter a valid value.',
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            return;
                          }
                          await c.updateProfile(buildPayload(v));
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                );
              }),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: Colors.white54),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ensure controller is instantiated for Obx/save actions in edit sheets.
    Get.find<ProfileController>();
    const coverHeight = 160.0;

    return Column(
      children: [
        SizedBox(
          height: coverHeight + 44,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  height: coverHeight,
                  width: double.infinity,
                  child: _ProfileCover(
                    coverImageUrl: profile?.coverImage,
                    gradientDecoration: _coverGradientDecoration,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                left: 6,
                child: IconButton(
                  onPressed: () {
                    Get.snackbar(
                      'Settings',
                      'Settings coming soon',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },
                  icon: const Icon(Icons.settings_rounded),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton(
                  onPressed: onChangeCover,
                  icon: const Icon(Icons.photo_camera_outlined),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                  tooltip: 'Change cover',
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Center(
                  child: _Avatar(
                    imageUrl: profile?.profileImage,
                    initials: _initials(profile?.name),
                    onChangePhoto: onChangePhoto,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (profile?.name ?? 'Explorer').toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.bebasNeue(
                  fontSize: 22,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                (profile?.bio ?? '').trim().isEmpty
                    ? 'No bio yet'
                    : (profile?.bio ?? ''),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsRow(profile: profile),
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Profile Info',
                      children: [
                        _InfoRow(
                          icon: Icons.badge_outlined,
                          label: 'Full Name',
                          value: profile?.name ?? '—',
                          onEdit: () => _showEditBottomSheet(
                            context,
                            title: 'Edit name',
                            initialValue: profile?.name ?? '',
                            fieldKey: 'Full Name',
                            validator: (v) => v.isNotEmpty,
                            buildPayload: (v) => {'name': v},
                          ),
                        ),
                        _DividerLine(),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: (profile?.phone ?? '').isEmpty
                              ? '—'
                              : (profile?.phone ?? ''),
                          onEdit: () => _showEditBottomSheet(
                            context,
                            title: 'Edit phone',
                            initialValue: profile?.phone ?? '',
                            fieldKey: 'Phone',
                            validator: (v) => v.isNotEmpty,
                            buildPayload: (v) => {'phone': v},
                          ),
                        ),
                        _DividerLine(),
                        _InfoRow(
                          icon: Icons.short_text_rounded,
                          label: 'Bio',
                          value: (profile?.bio ?? '').isEmpty
                              ? '—'
                              : (profile?.bio ?? ''),
                          onEdit: () => _showEditBottomSheet(
                            context,
                            title: 'Edit bio',
                            initialValue: profile?.bio ?? '',
                            fieldKey: 'Bio',
                            validator: (v) => true,
                            buildPayload: (v) => {'bio': v},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SectionCard(
                      title: 'Emergency Contact',
                      children: [
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Contact Name',
                          value: (profile?.emergencyName ?? '').isEmpty
                              ? '—'
                              : (profile?.emergencyName ?? ''),
                          onEdit: () => _showEditBottomSheet(
                            context,
                            title: 'Emergency contact name',
                            initialValue: profile?.emergencyName ?? '',
                            fieldKey: 'Contact Name',
                            validator: (v) => true,
                            buildPayload: (v) => {
                              'emergencyContact': {
                                'name': v,
                                'phone': profile?.emergencyPhone ?? '',
                                'relation': profile?.emergencyRelation ?? '',
                              }
                            },
                          ),
                        ),
                        _DividerLine(),
                        _InfoRow(
                          icon: Icons.call_outlined,
                          label: 'Phone',
                          value: (profile?.emergencyPhone ?? '').isEmpty
                              ? '—'
                              : (profile?.emergencyPhone ?? ''),
                          onEdit: () => _showEditBottomSheet(
                            context,
                            title: 'Emergency contact phone',
                            initialValue: profile?.emergencyPhone ?? '',
                            fieldKey: 'Emergency Phone',
                            validator: (v) => true,
                            buildPayload: (v) => {
                              'emergencyContact': {
                                'name': profile?.emergencyName ?? '',
                                'phone': v,
                                'relation': profile?.emergencyRelation ?? '',
                              }
                            },
                          ),
                        ),
                        _DividerLine(),
                        _InfoRow(
                          icon: Icons.link_outlined,
                          label: 'Relation',
                          value: (profile?.emergencyRelation ?? '').isEmpty
                              ? '—'
                              : (profile?.emergencyRelation ?? ''),
                          onEdit: () => _showEditBottomSheet(
                            context,
                            title: 'Emergency relation',
                            initialValue: profile?.emergencyRelation ?? '',
                            fieldKey: 'Relation',
                            validator: (v) => true,
                            buildPayload: (v) => {
                              'emergencyContact': {
                                'name': profile?.emergencyName ?? '',
                                'phone': profile?.emergencyPhone ?? '',
                                'relation': v,
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ActionButton(
                      icon: Icons.lock_outline,
                      text: 'Change Password',
                      textColor: AppColors.primaryLight,
                      onTap: () => Get.toNamed(AppRoutes.changePassword),
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.logout_rounded,
                      text: 'Logout',
                      textColor: AppColors.danger,
                      onTap: onLogout,
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      icon: Icons.delete_outline,
                      text: 'Delete Account',
                      textColor: Colors.white60,
                      fontSize: 12,
                      onTap: onDeleteAccount,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }
}

class _ProfileCover extends StatelessWidget {
  const _ProfileCover({
    required this.coverImageUrl,
    required this.gradientDecoration,
  });

  final String? coverImageUrl;
  final BoxDecoration gradientDecoration;

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.resolveMediaUrl(coverImageUrl);
    if (url != null && url.trim().isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: double.infinity,
        height: 160,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: double.infinity,
          height: 160,
          decoration: gradientDecoration,
        ),
        errorWidget: (_, __, ___) => Container(
          width: double.infinity,
          height: 160,
          decoration: gradientDecoration,
        ),
      );
    }
    return Container(
      width: double.infinity,
      height: 160,
      decoration: gradientDecoration,
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.imageUrl,
    required this.initials,
    required this.onChangePhoto,
  });

  final String? imageUrl;
  final String initials;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final resolved = ApiConfig.resolveMediaUrl(imageUrl);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onChangePhoto,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.18),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.35)),
              ),
              child: ClipOval(
                child: resolved != null && resolved.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resolved,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _Initials(initials),
                        errorWidget: (_, __, ___) => _Initials(initials),
                      )
                    : _Initials(initials),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onChangePhoto,
              child: const SizedBox(
                width: 26,
                height: 26,
                child: Icon(
                  Icons.camera_alt,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials(this.initials);
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.bebasNeue(
          fontSize: 28,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.profile});

  final ProfileModel? profile;

  @override
  Widget build(BuildContext context) {
    final tracks = (profile?.totalTracks ?? 0).toString();
    final km = profile?.totalDistanceKm ?? '0.0';
    final steps = (profile?.totalSteps ?? 0).toString();
    final adventures = (profile?.totalAdventures ?? 0).toString();

    return Row(
      children: [
        Expanded(child: _StatBox(value: tracks, label: 'TRACKS')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(value: km, label: 'DIST KM')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(value: steps, label: 'STEPS')),
        const SizedBox(width: 10),
        Expanded(child: _StatBox(value: adventures, label: 'ADVENTURES')),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              fontSize: 20,
              color: AppColors.primaryLight,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceMono(
              fontSize: 9,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryLight),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          color: Colors.white60,
          tooltip: 'Edit',
        ),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.text,
    required this.textColor,
    required this.onTap,
    this.fontSize = 14,
  });

  final IconData icon;
  final String text;
  final Color textColor;
  final VoidCallback onTap;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.darkSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 10),
              Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadingShimmer extends StatelessWidget {
  const _ProfileLoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.35, end: 0.75),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeInOut,
      builder: (context, v, _) {
        return Opacity(
          opacity: v,
          child: Column(
            children: [
              SizedBox(
                height: 160 + 44,
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 160,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primaryDark,
                              AppColors.primary,
                              AppColors.primaryLight,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: 88,
                        height: 88,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          Expanded(child: _SkeletonBox(height: 62)),
                          SizedBox(width: 10),
                          Expanded(child: _SkeletonBox(height: 62)),
                          SizedBox(width: 10),
                          Expanded(child: _SkeletonBox(height: 62)),
                          SizedBox(width: 10),
                          Expanded(child: _SkeletonBox(height: 62)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const _SkeletonBox(height: 150),
                      const SizedBox(height: 12),
                      const _SkeletonBox(height: 160),
                      const SizedBox(height: 16),
                      const _SkeletonBox(height: 52),
                      const SizedBox(height: 10),
                      const _SkeletonBox(height: 52),
                      const SizedBox(height: 10),
                      const _SkeletonBox(height: 52),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onEnd: () {},
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12.withValues(alpha: 0.06)),
      ),
    );
  }
}

