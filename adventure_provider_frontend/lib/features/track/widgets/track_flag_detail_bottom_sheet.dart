import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../data/models/track_model.dart';
import '../track_flag_type_style.dart';

List<String> flagMediaUrlsForTrackFlag(TrackFlag f) {
  final out = <String>[];
  final seen = <String>{};
  for (final u in f.images) {
    final s = u.trim();
    if (s.isEmpty || seen.contains(s)) continue;
    seen.add(s);
    out.add(s);
  }
  final p = f.photo?.trim();
  if (p != null && p.isNotEmpty && !seen.contains(p)) {
    out.add(p);
  }
  return out;
}

void openTrackPhotoFullscreen(BuildContext context, String storedUrl) {
  final resolved = ApiConfig.resolveMediaUrl(storedUrl) ?? storedUrl;
  showDialog<void>(
    context: context,
    barrierColor: AppColors.darkBackground.withValues(alpha: 0.94),
    builder: (ctx) {
      return Dialog(
        backgroundColor: AppColors.darkBackground.withValues(alpha: 0),
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: resolved,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox(
                    width: 48,
                    height: 48,
                    child: CircularProgressIndicator(
                      color: AppColors.primaryLight,
                    ),
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.homeGreetingGrey,
                    size: 48,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showTrackFlagDetailBottomSheet(BuildContext context, TrackFlag f) {
  final type = trackFlagTypeFromStored(f);
  final desc = f.description?.trim();
  final urls = flagMediaUrlsForTrackFlag(f);

  Get.bottomSheet<void>(
    SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.paddingOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.homeHeaderBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TrackFlagTypeCircleIcon(
                    type: type,
                    size: 44,
                    iconSize: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      trackFlagLabel(type),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ],
              ),
              if (f.title.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  f.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.homeGreetingGrey,
                  ),
                ),
              ],
              if (desc != null && desc.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.primaryLight,
                  ),
                ),
              ],
              if (urls.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Photos',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: urls.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final u = urls[i];
                      final resolved = ApiConfig.resolveMediaUrl(u) ?? u;
                      return Material(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => openTrackPhotoFullscreen(context, u),
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: CachedNetworkImage(
                              imageUrl: resolved,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.background,
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.homeGreetingGrey,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
    isScrollControlled: true,
    backgroundColor: AppColors.darkSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
  );
}
