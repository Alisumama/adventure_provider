import 'package:hive/hive.dart';

import 'track_local_models.dart';

/// Registers track local Hive adapters (typeIds 0–3).
///
/// Call once after [Hive.initFlutter] (or [Hive.init]) and before opening boxes that use these types.
void registerTrackLocalHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TrackPointLocalAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TrackSessionLocalAdapter());
  }
  if (!Hive.isAdapterRegistered(2)) {
    Hive.registerAdapter(TrackFollowPointLocalAdapter());
  }
  if (!Hive.isAdapterRegistered(3)) {
    Hive.registerAdapter(TrackFollowSessionLocalAdapter());
  }
}
