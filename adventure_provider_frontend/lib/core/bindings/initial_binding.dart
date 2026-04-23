import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/data/repositories/auth_repository.dart';
import '../constants/api_config.dart';
import '../services/socket_service.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<Dio>(
      Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      ),
    );
    Get.put<SocketService>(SocketService(), permanent: true);
    Get.lazyPut<AuthRepository>(() => AuthRepository(Get.find<Dio>()));
    // Eagerly create AuthController so auto-login runs on app start (splash won't hang).
    Get.put<AuthController>(
      AuthController(
        repository: Get.find<AuthRepository>(),
        storage: const FlutterSecureStorage(),
      ),
      permanent: true,
    );
  }
}
