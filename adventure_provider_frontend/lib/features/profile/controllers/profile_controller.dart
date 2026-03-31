import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/services/image_upload_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/data/models/user_model.dart';
import '../data/models/profile_model.dart';
import '../data/repositories/profile_repository.dart';

class ProfileController extends GetxController {
  ProfileController({
    required ProfileRepository repository,
    required FlutterSecureStorage storage,
    required dio.Dio dio,
    required ImageUploadService imageUploadService,
  })  : _repository = repository,
        _storage = storage,
        _dio = dio,
        _imageUploadService = imageUploadService;

  final ProfileRepository _repository;
  final FlutterSecureStorage _storage;
  final dio.Dio _dio;
  final ImageUploadService _imageUploadService;

  final Rxn<ProfileModel> profile = Rxn<ProfileModel>();
  final RxBool isLoading = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isSaving = false.obs;

  static const String _kAccessToken = 'access_token';
  static const String _kRefreshToken = 'refresh_token';

  String _cleanError(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  @override
  void onInit() {
    super.onInit();
    fetchProfile();
  }

  void _syncAuthUser(ProfileModel p) {
    if (!Get.isRegistered<AuthController>()) return;
    final auth = Get.find<AuthController>();
    final current = auth.user.value;

    final emergency = EmergencyContactModel(
      name: p.emergencyName,
      phone: p.emergencyPhone,
      relation: p.emergencyRelation,
    );

    if (current != null) {
      auth.user.value = current.copyWith(
        name: p.name,
        phone: p.phone,
        bio: p.bio,
        profileImage: p.profileImage,
        coverImage: p.coverImage,
        emergencyContact: emergency,
        totalTracks: p.totalTracks,
        totalDistance: p.totalDistance,
        totalSteps: p.totalSteps,
        totalAdventures: p.totalAdventures,
      );
    } else {
      auth.user.value = UserModel(
        id: p.id,
        name: p.name,
        email: p.email,
        phone: p.phone,
        profileImage: p.profileImage,
        coverImage: p.coverImage,
        bio: p.bio,
        emergencyContact: emergency,
        totalTracks: p.totalTracks,
        totalDistance: p.totalDistance,
        totalSteps: p.totalSteps,
        totalAdventures: p.totalAdventures,
      );
    }
  }

  Future<void> fetchProfile() async {
    isLoading.value = true;
    try {
      final p = await _repository.getProfile();
      profile.value = p;
      _syncAuthUser(p);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    isUpdating.value = true;
    try {
      await _repository.updateProfile(data);
      Get.snackbar(
        'Success',
        'Profile updated successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      await fetchProfile();
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdating.value = false;
    }
  }

  Future<bool?> _askImageSource() {
    return Get.bottomSheet<bool?>(
      SafeArea(
        child: Material(
          color: Get.theme.cardColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ListTile(
                title: Text('Choose photo source'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () => Get.back<bool?>(result: true),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Get.back<bool?>(result: false),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      isDismissible: true,
      enableDrag: true,
    );
  }

  void _showBlockingLoader() {
    Get.dialog<void>(
      const Center(child: CircularProgressIndicator()),
      barrierDismissible: false,
    );
  }

  void _hideBlockingLoader() {
    for (var i = 0; i < 3; i++) {
      if (Get.isDialogOpen == true) {
        Get.back<void>();
      } else {
        break;
      }
    }
  }

  /// Picks an image (camera/gallery), uploads to backend, updates profileImage locally.
  Future<void> updateProfileImage() async {
    final sourceIsCamera = await _askImageSource();
    if (sourceIsCamera == null) return;

    try {
      final picked = await _imageUploadService.pickImage(fromCamera: sourceIsCamera);
      if (picked == null) return;

      isSaving.value = true;
      _showBlockingLoader();
      final url = await _imageUploadService.uploadProfileImage(picked);

      final current = profile.value;
      if (current != null) {
        final next = current.copyWith(profileImage: url);
        profile.value = next;
        _syncAuthUser(next);
      }
      Get.snackbar(
        'Success',
        'Profile photo updated!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      _hideBlockingLoader();
      isSaving.value = false;
    }
  }

  /// Picks an image (camera/gallery), uploads to backend, updates coverImage locally.
  Future<void> updateCoverImage() async {
    final sourceIsCamera = await _askImageSource();
    if (sourceIsCamera == null) return;

    try {
      final picked = await _imageUploadService.pickImage(fromCamera: sourceIsCamera);
      if (picked == null) return;

      isSaving.value = true;
      _showBlockingLoader();
      final url = await _imageUploadService.uploadCoverImage(picked);

      final current = profile.value;
      if (current != null) {
        final next = current.copyWith(coverImage: url);
        profile.value = next;
        _syncAuthUser(next);
      }

      Get.snackbar(
        'Success',
        'Cover photo updated!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      _hideBlockingLoader();
      isSaving.value = false;
    }
  }

  Future<void> changePassword(String current, String newPass) async {
    isUpdating.value = true;
    try {
      await _repository.changePassword(current, newPass);
      Get.snackbar(
        'Success',
        'Password changed successfully',
        snackPosition: SnackPosition.BOTTOM,
      );
      Get.back<void>();
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdating.value = false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    _dio.options.headers.remove('Authorization');
    profile.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> deleteAccount() async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will deactivate your account. You can contact support to restore access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<bool>(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Get.back<bool>(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    isUpdating.value = true;
    try {
      await _repository.deleteAccount();
      await logout();
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUpdating.value = false;
    }
  }
}

