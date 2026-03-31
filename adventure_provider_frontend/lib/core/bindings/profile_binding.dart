import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../services/image_upload_service.dart';
import '../../features/profile/controllers/profile_controller.dart';
import '../../features/profile/data/repositories/profile_repository.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<ImageUploadService>()) {
      Get.put<ImageUploadService>(ImageUploadService(), permanent: true);
    }
    if (!Get.isRegistered<ProfileRepository>()) {
      Get.put<ProfileRepository>(ProfileRepository(Get.find<Dio>()), permanent: true);
    }
    if (!Get.isRegistered<ProfileController>()) {
      Get.put<ProfileController>(
        ProfileController(
          repository: Get.find<ProfileRepository>(),
          storage: const FlutterSecureStorage(),
          dio: Get.find<Dio>(),
          imageUploadService: Get.find<ImageUploadService>(),
        ),
        permanent: true,
      );
    }
  }
}

