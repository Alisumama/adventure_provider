import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../services/image_upload_service.dart';
import '../services/track_sync_service.dart';
import '../../features/track/controllers/track_controller.dart';
import '../../features/track/data/local/local_track_repository.dart';
import '../../features/track/data/repositories/track_repository.dart';

class TrackBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ImageUploadService>()) {
      Get.put<ImageUploadService>(ImageUploadService(), permanent: true);
    }
    if (!Get.isRegistered<TrackRepository>()) {
      Get.put<TrackRepository>(
        TrackRepository(Get.find<Dio>()),
        permanent: true,
      );
    }
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
    if (!Get.isRegistered<TrackController>()) {
      Get.put<TrackController>(
        TrackController(
          Get.find<TrackRepository>(),
          Get.find<ImageUploadService>(),
          Get.find<LocalTrackRepository>(),
          Get.find<TrackSyncService>(),
          Get.find<Connectivity>(),
        ),
        permanent: true,
      );
    }
  }
}
