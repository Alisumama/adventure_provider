import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../features/track/controllers/track_follow_controller.dart';
import '../../features/track/data/local/local_follow_repository.dart';
import '../../features/track/data/repositories/track_follow_repository.dart';

/// Registers follow-mode dependencies: [LocalFollowRepository], [TrackFollowRepository], [TrackFollowController].
class TrackFollowBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<LocalFollowRepository>()) {
      Get.put<LocalFollowRepository>(
        LocalFollowRepository(),
        permanent: true,
      );
    }
    if (!Get.isRegistered<TrackFollowRepository>()) {
      Get.put<TrackFollowRepository>(
        TrackFollowRepository(Get.find<Dio>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<TrackFollowController>()) {
      Get.put<TrackFollowController>(
        TrackFollowController(
          Get.find<TrackFollowRepository>(),
          Get.find<LocalFollowRepository>(),
          Get.find<Connectivity>(),
        ),
        permanent: true,
      );
    }
  }
}
