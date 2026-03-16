import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';

class AuthController extends GetxController {
  AuthController({
    required AuthRepository repository,
    required FlutterSecureStorage storage,
  })  : _repository = repository,
        _storage = storage;

  final AuthRepository _repository;
  final FlutterSecureStorage _storage;

  final Rxn<UserModel> user = Rxn<UserModel>();
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString successMessage = ''.obs;
  final RxInt resendCooldown = 0.obs; // seconds remaining

  void clearError() => errorMessage.value = '';
  void clearSuccess() => successMessage.value = '';

  Future<void> login(String email, String password) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final u = await _repository.login(email, password);
      if (u != null) {
        user.value = u;
        // TODO: store tokens, navigate to home
      }
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    EmergencyContactModel? emergencyContact,
    String? profileImagePath,
  }) async {
    errorMessage.value = '';
    isLoading.value = true;
    try {
      final u = await _repository.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        emergencyContact: emergencyContact,
      );
      if (u != null) {
        user.value = u;
        // TODO: store tokens, navigate to home
      }
    } catch (e) {
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

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    errorMessage.value = '';
    successMessage.value = '';
    isLoading.value = true;
    try {
      await _repository.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      successMessage.value = 'Password reset successful';
    } catch (e) {
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }
}
