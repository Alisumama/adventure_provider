import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../features/community/controllers/community_controller.dart';
import '../../features/community/data/repositories/community_repository.dart';

class CommunityBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CommunityRepository>()) {
      Get.put<CommunityRepository>(
        CommunityRepository(Get.find<Dio>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CommunityController>()) {
      Get.put<CommunityController>(
        CommunityController(repository: Get.find<CommunityRepository>()),
        permanent: true,
      );
    }
  }
}
