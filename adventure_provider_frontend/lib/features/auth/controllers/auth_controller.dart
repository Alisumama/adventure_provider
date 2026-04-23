import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/socket_service.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  AuthController({required AuthRepository repository, required FlutterSecureStorage storage}) : _repository = repository, _storage = storage;

  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxInt resendCooldown = 0.obs; // seconds remaining

  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';

  void clearError() => errorMessage.value = '';
  void clearSuccess() => successMessage.value = '';

  @override
  void onInit() {
    super.onInit();
    _autoLogin();
  }

  void _connectSocket(String token) {
    if (Get.isRegistered<SocketService>()) {
      Get.find<SocketService>().connect(token);
    }
  }

  void _setAuthHeader(String? accessToken) {
    final dio = Get.find<Dio>();
    if (accessToken == null || accessToken.isEmpty) {
      dio.options.headers.remove('Authorization');
    } else {
      dio.options.headers['Authorization'] = 'Bearer $accessToken';
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    _setAuthHeader(null);
  }

  Future<void> _autoLogin() async {
    // Keep splash visible while checking; do not navigate to login until done.
    isLoading.value = true;
    try {
      final accessToken = await _storage.read(key: _kAccessToken);
      final refreshToken = await _storage.read(key: _kRefreshToken);

      if (accessToken == null || accessToken.isEmpty) {
        await _clearTokens();
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      _setAuthHeader(accessToken);

      try {
        final u = await _repository.getMe();
        if (u != null) {
          user.value = u;
          _connectSocket(accessToken);
          Get.offAllNamed(AppRoutes.home);
          return;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode != 401) rethrow;
      }

      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearTokens();
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      final refreshed = await _repository.refreshAccessToken(refreshToken);
      final newAccess = refreshed?['accessToken']?.toString();
      final userJson = refreshed?['user'];
      if (newAccess == null || newAccess.isEmpty || userJson is! Map) {
        await _clearTokens();
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      await _storage.write(key: _kAccessToken, value: newAccess);
      await _storage.write(key: _kRefreshToken, value: refreshToken);
      _setAuthHeader(newAccess);

      user.value = UserModel.fromJson(Map<String, dynamic>.from(userJson));
      _connectSocket(newAccess);
      Get.offAllNamed(AppRoutes.home);
    } catch (_) {
      await _clearTokens();
      Get.offAllNamed(AppRoutes.login);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final session = await _repository.login(email, password);
      if (session != null) {
        user.value = session.user;
        await _storage.write(key: _kAccessToken, value: session.accessToken);
        await _storage.write(key: _kRefreshToken, value: session.refreshToken);
        _setAuthHeader(session.accessToken);
        _connectSocket(session.accessToken);
        Get.offAllNamed(AppRoutes.home);
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({required String name, required String email, required String password, String? phone, EmergencyContactModel? emergencyContact, String? profileImagePath}) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final session = await _repository.register(name: name, email: email, password: password, phone: phone, emergencyContact: emergencyContact);
      if (session != null) {
        user.value = session.user;
        await _storage.write(key: _kAccessToken, value: session.accessToken);
        await _storage.write(key: _kRefreshToken, value: session.refreshToken);
        _setAuthHeader(session.accessToken);
        _connectSocket(session.accessToken);
        Get.offAllNamed(AppRoutes.home);
      }
    } on DioException catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> forgotPassword(String email) async {
    errorMessage.value = '';
    successMessage.value = '';
    isLoading.value = true;
    try {
      await _repository.forgotPassword(email);
      successMessage.value = 'OTP sent to your email';
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final ok = await _repository.verifyOtp(email, otp);
      if (ok) return true;
      errorMessage.value = 'Invalid or expired OTP';
      return false;
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void startResendCooldown() {
    resendCooldown.value = 60;
    Future<void> run() async {
      while (resendCooldown.value > 0) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (resendCooldown.value > 0) resendCooldown.value--;
      }
    }

    run();
  }

  Future<void> resetPassword({required String email, required String otp, required String newPassword}) async {
    errorMessage.value = '';
    successMessage.value = '';
    isLoading.value = true;
    try {
      await _repository.resetPassword(email: email, otp: otp, newPassword: newPassword);
      successMessage.value = 'Password reset successful';
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }
}
