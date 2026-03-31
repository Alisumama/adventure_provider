import 'package:dio/dio.dart';

import '../models/profile_model.dart';

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  static const String _auth = '/auth';

  String _messageFromDio(DioException e, [String fallback = 'Request failed']) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  ProfileModel _parseProfile(dynamic data) {
    if (data is Map && data['user'] is Map) {
      return ProfileModel.fromJson(Map<String, dynamic>.from(data['user'] as Map));
    }
    if (data is Map) {
      return ProfileModel.fromJson(Map<String, dynamic>.from(data));
    }
    throw Exception('Invalid response');
  }

  /// GET /auth/profile
  Future<ProfileModel> getProfile() async {
    try {
      final response = await _dio.get<dynamic>('$_auth/profile');
      if (response.statusCode != 200) {
        final msg = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to load profile';
        throw Exception(msg);
      }
      return _parseProfile(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to load profile'));
    }
  }

  /// PUT /auth/profile
  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put<dynamic>(
        '$_auth/profile',
        data: data,
      );
      if (response.statusCode != 200) {
        final msg = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to update profile';
        throw Exception(msg);
      }
      return _parseProfile(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to update profile'));
    }
  }

  /// PUT /auth/profile/image
  Future<ProfileModel> updateProfileImage(String imageUrl) async {
    try {
      final response = await _dio.put<dynamic>(
        '$_auth/profile/image',
        data: {'profileImage': imageUrl},
      );
      if (response.statusCode != 200) {
        final msg = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to update profile image';
        throw Exception(msg);
      }
      return _parseProfile(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to update profile image'));
    }
  }

  /// PUT /auth/change-password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _dio.put<dynamic>(
        '$_auth/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode != 200) {
        final msg = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to change password';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      final fallback = e.response?.statusCode == 401
          ? 'Current password is incorrect'
          : 'Failed to change password';
      throw Exception(_messageFromDio(e, fallback));
    }
  }

  /// DELETE /auth/account
  Future<void> deleteAccount() async {
    try {
      final response = await _dio.delete<dynamic>('$_auth/account');
      if (response.statusCode != 200) {
        final msg = response.data is Map && response.data['message'] != null
            ? response.data['message'].toString()
            : 'Failed to delete account';
        throw Exception(msg);
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to delete account'));
    }
  }
}

