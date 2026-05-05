import 'package:flutter/widgets.dart';

/// SOS FAB diameter (see [SosFab] in `sos_fab_overlay.dart`).
const double kSosFabDiameter = 56;

/// Bottom padding for scroll views under the main shell SOS FAB
/// (clearance above bottom nav + FAB + margin).
const double kSosFabScrollBottomInset = 148;

/// Pin + expanded heights for collapsing Track / Community pinned headers
/// (chips + search), with floor to reduce flex overflows while scrolling.
({double min, double max}) shellCollapsingHeaderExtents(BuildContext context) {
  final body = MediaQuery.sizeOf(context).height -
      MediaQuery.paddingOf(context).vertical;
  final minE = (body * 0.074).clamp(62.0, 72.0);
  var maxE = (body * 0.205).clamp(188.0, 228.0);
  const expandableFloor = 128.0;
  if (maxE - minE < expandableFloor) {
    maxE = minE + expandableFloor;
  }
  return (min: minE, max: maxE);
}
