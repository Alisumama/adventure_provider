import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/constants/shell_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../models/active_session_data.dart';
import '../models/nearby_route_item.dart';
import '../widgets/home_nearby_routes_section.dart';
import '../widgets/home_upcoming_plans_section.dart';
import '../widgets/home_quick_map_section.dart';
import '../widgets/home_session_hero_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.userName, this.activeSession});

  /// When set, shown as the display name; otherwise uses [AuthController] if registered.
  final String? userName;

  /// When non-null, shows the gradient active-session hero; otherwise the dashed start card.
  final ActiveSessionData? activeSession;

  static String initialsFromName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      final s = parts[0];
      if (s.length >= 2) {
        return s.substring(0, 2).toUpperCase();
      }
      return s[0].toUpperCase();
    }
    final a = parts[0].isNotEmpty ? parts[0][0] : '';
    final b = parts[1].isNotEmpty ? parts[1][0] : '';
    return ('$a$b').toUpperCase();
  }

  String _resolveDisplayName() {
    if (userName != null && userName!.trim().isNotEmpty) {
      return userName!.trim();
    }
    try {
      final p = Get.find<ProfileController>().profile.value;
      final n = p?.name;
      if (n != null && n.trim().isNotEmpty) return n.trim();
    } catch (_) {}
    if (Get.isRegistered<AuthController>()) {
      final n = Get.find<AuthController>().user.value?.name;
      if (n != null && n.trim().isNotEmpty) return n.trim();
    }
    return 'Explorer';
  }

  String? _resolveProfileImageUrl() {
    try {
      final raw = Get.find<ProfileController>().profile.value?.profileImage;
      return ApiConfig.resolveMediaUrl(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    const headerBodyHeight = 68.0;

    return Material(
      color: AppColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: headerBodyHeight,
              child: Obx(() {
                final displayName = _resolveDisplayName();
                final initials = initialsFromName(displayName);
                final imageUrl = _resolveProfileImageUrl();
                return _HomeHeaderBar(
                  displayName: displayName,
                  initials: initials,
                  imageUrl: imageUrl,
                );
              }),
            ),
            Expanded(
              child: ListView(
                primary: false,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                children: [
                  HomeSessionHeroCard(
                    activeSession: activeSession,
                  ),
                  const SizedBox(height: 20),
                  const HomeQuickMapSection(),
                  const SizedBox(height: 20),
                  HomeNearbyRoutesSection(
                    routes: NearbyRouteItem.samples,
                  ),
                  const SizedBox(height: 20),
                  const HomeUpcomingPlansSection(),
                  const SizedBox(height: 24),
                  const SizedBox(height: kSosFabScrollBottomInset),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeHeaderBar extends StatelessWidget {
  const _HomeHeaderBar({
    required this.displayName,
    required this.initials,
    required this.imageUrl,
  });

  final String displayName;
  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.homeHeaderBorder,
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Good morning,',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.homeGreetingGrey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bebasNeue(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.5,
                      color: AppColors.textPrimary,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HomeNotificationButton(),
                const SizedBox(width: 10),
                _HomeAvatarCircle(
                  initials: initials,
                  imageUrl: imageUrl,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeNotificationButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        customBorder: const CircleBorder(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: AppColors.homeHeaderIconFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_outlined,
                size: 20,
                color: AppColors.textPrimary.withValues(alpha: 0.85),
              ),
            ),
            Positioned(
              right: 6,
              top: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAvatarCircle extends StatelessWidget {
  const _HomeAvatarCircle({
    required this.initials,
    required this.imageUrl,
  });

  final String initials;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return Container(
      width: 38,
      height: 38,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.primary,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: ClipOval(
        child: (url != null && url.trim().isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                placeholder: (_, __) => _InitialsText(initials: initials),
                errorWidget: (_, __, ___) => _InitialsText(initials: initials),
              )
            : _InitialsText(initials: initials),
      ),
    );
  }
}

class _InitialsText extends StatelessWidget {
  const _InitialsText({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.bebasNeue(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: AppColors.surface,
          height: 1,
        ),
      ),
    );
  }
}
