import 'dart:io';

import 'package:dio/dio.dart';

class GroupRepository {
  GroupRepository(this._dio);
  final Dio _dio;

  static const String _groups = '/groups';

  String _messageFromDio(DioException e,
      [String fallback = 'Request failed']) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  Map<String, dynamic> _requireMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Invalid response');
  }

  List<dynamic> _requireList(dynamic data) {
    if (data is List) return data;
    throw Exception('Invalid response');
  }

  /// GET /groups/my
  Future<List<dynamic>> getMyGroups() async {
    try {
      final response = await _dio.get<dynamic>('$_groups/my');
      return _requireList(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /groups
  Future<Map<String, dynamic>> createGroup({
    required String name,
    required String description,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        _groups,
        data: {'name': name, 'description': description},
      );
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// PUT /groups/:id/image (multipart, field name [image])
  Future<void> updateGroupImage(String groupId, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(RegExp(r'[/\\]')).last,
        ),
      });
      await _dio.put<dynamic>('$_groups/$groupId/image', data: formData);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// PUT /groups/:id/cover-image (multipart, field name [coverImage])
  Future<void> updateGroupCoverImage(String groupId, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'coverImage': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(RegExp(r'[/\\]')).last,
        ),
      });
      await _dio.put<dynamic>('$_groups/$groupId/cover-image', data: formData);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /groups/join
  Future<Map<String, dynamic>> joinGroup(String inviteCode) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_groups/join',
        data: {'inviteCode': inviteCode},
      );
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// GET /groups/:id
  Future<Map<String, dynamic>> getGroupById(String id) async {
    try {
      final response = await _dio.get<dynamic>('$_groups/$id');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// GET /groups/:id/live-sessions
  Future<List<dynamic>> getGroupLiveSessions(String groupId) async {
    try {
      final response = await _dio.get<dynamic>('$_groups/$groupId/live-sessions');
      return _requireList(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /groups/:id/start-tracking
  Future<Map<String, dynamic>> startGroupTracking(
    String groupId, {
    String? trackId,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (trackId != null && trackId.isNotEmpty) {
        body['trackId'] = trackId;
      }
      final response = await _dio.post<dynamic>(
        '$_groups/$groupId/start-tracking',
        data: body,
      );
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /groups/:id/stop-tracking
  Future<Map<String, dynamic>> stopGroupTracking(String groupId) async {
    try {
      final response =
          await _dio.post<dynamic>('$_groups/$groupId/stop-tracking');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /groups/:id/location
  Future<void> updateMemberLocation({
    required String groupId,
    required String liveSessionId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      await _dio.post<dynamic>(
        '$_groups/$groupId/location',
        data: {
          'liveSessionId': liveSessionId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// DELETE /groups/:id/leave
  Future<void> leaveGroup(String groupId) async {
    try {
      await _dio.delete<dynamic>('$_groups/$groupId/leave');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }
}
