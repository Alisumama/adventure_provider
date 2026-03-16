import 'package:dio/dio.dart';
import 'package:get/get.dart';

import '../constants/api_config.dart';

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
  }
}
