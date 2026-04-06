import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

class CommunityRepository {
  CommunityRepository(this._dio);

  final Dio _dio;

  static const String _base = '/community';

  String _messageFromDio(DioException e, [String fallback = 'Request failed']) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Invalid response');
  }

  Future<Map<String, dynamic>> getAllCommunities({
    String? search,
    String? category,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      if (category != null && category.trim().isNotEmpty) {
        query['category'] = category.trim();
      }
      final response = await _dio.get<dynamic>(_base, queryParameters: query);
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to load communities');
      }
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to load communities'));
    }
  }

  Future<Map<String, dynamic>> getCommunityDetail(String communityId) async {
    try {
      final response = await _dio.get<dynamic>('$_base/$communityId');
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to load community');
      }
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to load community'));
    }
  }

  Future<Map<String, dynamic>> createCommunity({
    required String name,
    required String description,
    required String visibility,
    required String category,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        _base,
        data: {
          'name': name,
          'description': description,
          'visibility': visibility,
          'category': category,
        },
      );
      if (response.statusCode != 201 || response.data == null) {
        throw Exception('Failed to create community');
      }
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to create community'));
    }
  }

  Future<void> joinCommunity(String communityId) async {
    try {
      final response = await _dio.post<dynamic>('$_base/$communityId/join');
      if (response.statusCode != 200) {
        throw Exception('Failed to join community');
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to join community'));
    }
  }

  Future<void> leaveCommunity(String communityId) async {
    try {
      final response = await _dio.post<dynamic>('$_base/$communityId/leave');
      if (response.statusCode != 200) {
        throw Exception('Failed to leave community');
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to leave community'));
    }
  }

  Future<Map<String, dynamic>> updateCommunity(
    String communityId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<dynamic>('$_base/$communityId', data: data);
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to update community');
      }
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to update community'));
    }
  }

  Future<void> updateCommunityImage(String communityId, File imageFile) async {
    try {
      final form = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: p.basename(imageFile.path),
        ),
      });
      final response = await _dio.put<dynamic>(
        '$_base/$communityId/image',
        data: form,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to upload image');
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to upload image'));
    }
  }

  Future<Map<String, dynamic>> getCommunityPosts(
    String communityId, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_base/$communityId/posts',
        queryParameters: {'page': page, 'limit': 15},
      );
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to load posts');
      }
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to load posts'));
    }
  }

  Future<Map<String, dynamic>> createPost(
    String communityId, {
    required String content,
    String? trackId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_base/$communityId/posts',
        data: {
          'content': content,
          if (trackId != null && trackId.isNotEmpty) 'trackId': trackId,
        },
      );
      if (response.statusCode != 201 || response.data == null) {
        throw Exception('Failed to create post');
      }
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to create post'));
    }
  }

  Future<Map<String, dynamic>> toggleLikePost(String postId) async {
    try {
      final response = await _dio.post<dynamic>('$_base/posts/$postId/like');
      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to toggle like');
      }
      return _asMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to toggle like'));
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final response = await _dio.delete<dynamic>('$_base/posts/$postId');
      if (response.statusCode != 200) {
        throw Exception('Failed to delete post');
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to delete post'));
    }
  }
}
