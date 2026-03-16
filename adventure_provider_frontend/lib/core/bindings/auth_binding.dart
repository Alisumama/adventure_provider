import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/data/repositories/auth_repository.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find<Dio>()));
    Get.lazyPut<AuthController>(
      () => AuthController(
        repository: Get.find<AuthRepository>(),
        storage: const FlutterSecureStorage(),
      ),
    );
  }
}
