import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import 'data/models/track_model.dart';

/// Stored [TrackFlag.type], or `other` when missing (legacy rows).
String trackFlagTypeFromStored(TrackFlag f) {
  final t = f.type?.trim();
  if (t != null && t.isNotEmpty) return t;
  return 'other';
}

/// Human-readable label for stored flag `type` values.
String trackFlagLabel(String type) {
  switch (type) {
    case 'rest_area':
      return 'Rest area';
    case 'water_stream':
      return 'Water stream';
    case 'steep_incline':
      return 'Steep incline';
    case 'viewpoint':
      return 'Viewpoint';
    case 'hazard':
      return 'Hazard';
    case 'other':
      return 'Other';
    default:
      return type;
  }
}

IconData trackFlagIcon(String type) {
  switch (type) {
    case 'rest_area':
      return Icons.weekend;
    case 'water_stream':
      return Icons.water;
    case 'steep_incline':
      return Icons.trending_up;
    case 'viewpoint':
      return Icons.visibility;
    case 'hazard':
      return Icons.warning_amber;
    case 'other':
      return Icons.flag;
    default:
      return Icons.flag;
  }
}

Color trackFlagCircleColor(String type) {
  switch (type) {
    case 'rest_area':
      return AppColors.warning;
    case 'water_stream':
      return AppColors.flagWaterStream;
    case 'steep_incline':
      return AppColors.accent;
    case 'viewpoint':
      return AppColors.success;
    case 'hazard':
      return AppColors.danger;
    case 'other':
      return AppColors.homeGreetingGrey;
    default:
      return AppColors.homeGreetingGrey;
  }
}

/// Icon color on top of [trackFlagCircleColor] for contrast.
Color trackFlagIconOnCircleColor(String type) {
  switch (type) {
    case 'rest_area':
      return AppColors.textPrimary;
    default:
      return AppColors.surface;
  }
}

/// Map marker / dropdown: icon inside a colored circle.
class TrackFlagTypeCircleIcon extends StatelessWidget {
  const TrackFlagTypeCircleIcon({
    super.key,
    required this.type,
    this.size = 36,
    this.iconSize = 20,
  });

  final String type;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: trackFlagCircleColor(type),
        boxShadow: const [
          BoxShadow(
            color: AppColors.darkSurface,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        trackFlagIcon(type),
        size: iconSize,
        color: trackFlagIconOnCircleColor(type),
      ),
    );
  }
}
