import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import '../services/track_sync_service.dart';
import '../../features/track/data/local/local_track_repository.dart';
import '../../features/track/data/repositories/track_repository.dart';
import 'community_binding.dart';
import 'group_binding.dart';
import 'profile_binding.dart';
import 'track_binding.dart';
import 'track_follow_binding.dart';

/// Registers shell dependencies before [MainShellScreen] builds.
///
/// Applies [TrackBinding] so [TrackController] is available for [TrackListScreen].
class MainBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<NavigationController>()) {
      Get.put<NavigationController>(NavigationController(), permanent: true);
    }
    TrackBinding().dependencies();
    TrackFollowBinding().dependencies();
    if (!Get.isRegistered<Connectivity>()) {
      Get.put<Connectivity>(Connectivity(), permanent: true);
    }
    if (!Get.isRegistered<LocalTrackRepository>()) {
      Get.put<LocalTrackRepository>(
        LocalTrackRepository(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<TrackSyncService>()) {
      Get.put<TrackSyncService>(
        TrackSyncService(
          localTrackRepository: Get.find<LocalTrackRepository>(),
          trackRepository: Get.find<TrackRepository>(),
          connectivity: Get.find<Connectivity>(),
        ),
        permanent: true,
      );
    }
    ProfileBinding().dependencies();

    CommunityBinding().dependencies();

    GroupBinding().dependencies();
  }
}
