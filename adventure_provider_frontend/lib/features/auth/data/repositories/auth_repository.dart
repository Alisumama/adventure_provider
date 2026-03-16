import 'package:dio/dio.dart';

import '../models/user_model.dart';

class AuthRepository {
  AuthRepository(this._dio);

  final Dio _dio;

  static const String _auth = '/auth';

  void _throwFromResponse(Response<dynamic> response) {
    final message = response.data is Map && response.data['message'] != null
        ? response.data['message'].toString()
        : 'Request failed';
    throw Exception(message);
  }

  Future<UserModel?> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_auth/login',
      data: {'email': email, 'password': password},
    );
    if (response.statusCode != 200 || response.data == null) return null;
    final data = response.data!;
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) return null;
    return UserModel.fromJson(userJson);
  }

  Future<UserModel?> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    EmergencyContactModel? emergencyContact,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (emergencyContact != null) 'emergencyContact': emergencyContact.toJson(),
        },
      );
      if (response.statusCode != 201 || response.data == null) return null;
      final data = response.data!;
      final userJson = data['user'] as Map<String, dynamic>?;
      if (userJson == null) return null;
      return UserModel.fromJson(userJson);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['message'] != null
          ? data['message'].toString()
          : e.message ?? 'Registration failed';
      throw Exception(message);
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_auth/forgot-password',
        data: {'email': email},
      );
      if (response.statusCode != 200) _throwFromResponse(response);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response!.data['message'].toString()
          : e.message ?? 'Request failed';
      throw Exception(msg);
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_auth/verify-otp',
        data: {'email': email, 'otp': otp},
      );
      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        final msg = e.response?.data is Map && e.response?.data['message'] != null
            ? e.response!.data['message'].toString()
            : 'Invalid or expired OTP';
        throw Exception(msg);
      }
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_auth/reset-password',
        data: {
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        },
      );
      if (response.statusCode != 200) _throwFromResponse(response);
    } on DioException catch (e) {
      final msg = e.response?.data is Map && e.response?.data['message'] != null
          ? e.response!.data['message'].toString()
          : e.message ?? 'Reset failed';
      throw Exception(msg);
    }
  }

  Future<Map<String, String>?> refreshToken(String refreshToken) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    if (response.statusCode != 200 || response.data == null) return null;
    final data = response.data!;
    final access = data['accessToken'] as String?;
    final refresh = data['refreshToken'] as String?;
    if (access == null) return null;
    return {'accessToken': access, 'refreshToken': refresh ?? access};
  }

  Future<UserModel?> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>('$_auth/me');
    if (response.statusCode != 200 || response.data == null) return null;
    final data = response.data!;
    final userJson = data['user'] as Map<String, dynamic>?;
    if (userJson == null) return null;
    return UserModel.fromJson(userJson);
  }
}
