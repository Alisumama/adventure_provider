import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../../features/groups/controllers/group_controller.dart';
import '../../features/groups/data/repositories/group_repository.dart';

class GroupBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<GroupRepository>()) {
      Get.put<GroupRepository>(
        GroupRepository(Get.find<Dio>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GroupController>()) {
      Get.put<GroupController>(
        GroupController(Get.find<GroupRepository>()),
        permanent: true,
      );
    }
  }
}
