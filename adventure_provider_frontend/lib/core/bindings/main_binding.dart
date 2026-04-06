import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import 'community_binding.dart';
import 'profile_binding.dart';
import 'track_binding.dart';

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
    ProfileBinding().dependencies();
    CommunityBinding().dependencies();
  }
}
