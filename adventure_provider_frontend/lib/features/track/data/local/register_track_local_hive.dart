import 'package:hive/hive.dart';

import 'track_local_models.dart';

/// Registers [TrackPointLocal] (typeId 0) and [TrackSessionLocal] (typeId 1) adapters.
///
/// Call once after [Hive.initFlutter] (or [Hive.init]) and before opening boxes that use these types.
void registerTrackLocalHiveAdapters() {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TrackPointLocalAdapter());
  }
  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(TrackSessionLocalAdapter());
  }
}
