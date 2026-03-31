import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../features/track/controllers/track_controller.dart';
import '../../features/track/data/repositories/track_repository.dart';

class TrackBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TrackRepository>()) {
      Get.put<TrackRepository>(
        TrackRepository(Get.find<Dio>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<TrackController>()) {
      Get.put<TrackController>(
        TrackController(Get.find<TrackRepository>()),
        permanent: true,
      );
    }
  }
}
