import 'dart:io';

import 'package:dio/dio.dart';

class CommunityRepository {
  CommunityRepository(this._dio);

  final Dio _dio;

  static const String _community = '/community';

  String _messageFromDio(DioException e, [String fallback = 'Request failed']) {
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

  /// GET /community?search=&category=
  Future<Map<String, dynamic>> getAllCommunities({
    String? search,
    String? category,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        _community,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      if (response.data == null) {
        throw Exception('Invalid response');
      }
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// GET /community/:id
  Future<Map<String, dynamic>> getCommunityDetail(String communityId) async {
    try {
      final response = await _dio.get<dynamic>('$_community/$communityId');
      if (response.data == null) {
        throw Exception('Invalid response');
      }
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community
  Future<Map<String, dynamic>> createCommunity({
    required String name,
    required String description,
    required String visibility,
    required String category,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        _community,
        data: {
          'name': name,
          'description': description,
          'visibility': visibility,
          'category': category,
        },
      );
      if (response.data == null) {
        throw Exception('Invalid response');
      }
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community/:id/join
  Future<void> joinCommunity(String communityId) async {
    try {
      await _dio.post<dynamic>('$_community/$communityId/join');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community/:id/leave
  Future<void> leaveCommunity(String communityId) async {
    try {
      await _dio.post<dynamic>('$_community/$communityId/leave');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// PUT /community/:id
  Future<Map<String, dynamic>> updateCommunity(
    String communityId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '$_community/$communityId',
        data: data,
      );
      if (response.data == null) {
        throw Exception('Invalid response');
      }
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// PUT /community/:id/image (multipart, field name [image])
  Future<void> updateCommunityImage(String communityId, File imageFile) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split(RegExp(r'[/\\]')).last,
        ),
      });
      await _dio.put<dynamic>(
        '$_community/$communityId/image',
        data: formData,
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// GET /community/:id/posts?page=
  Future<Map<String, dynamic>> getCommunityPosts(
    String communityId, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/$communityId/posts',
        queryParameters: {'page': page},
      );
      if (response.data == null) {
        throw Exception('Invalid response');
      }
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// POST /community/:id/posts
  Future<Map<String, dynamic>> createPost(
    String communityId, {
    required String content,
    String? trackId,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_community/$communityId/posts',
        data: {
          'content': content,
          if (trackId != null && trackId.isNotEmpty) 'trackId': trackId,
        },
      );
      if (response.data == null) {
        throw Exception('Invalid response');
      }
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// POST /community/posts/:postId/like
  Future<Map<String, dynamic>> toggleLikePost(String postId) async {
    try {
      final response = await _dio.post<dynamic>('$_community/posts/$postId/like');
      if (response.data == null) {
        throw Exception('Invalid response');
      }
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// DELETE /community/posts/:postId
  Future<void> deletePost(String postId) async {
    try {
      await _dio.delete<dynamic>('$_community/posts/$postId');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// GET /community/:communityId/members
  Future<Map<String, dynamic>> getCommunityMembers(String communityId) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/$communityId/members',
      );
      if (response.data == null) {
        throw Exception('Invalid response');
      }
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// DELETE /community/:communityId/members/:userId
  Future<void> removeMember(String communityId, String userId) async {
    try {
      await _dio.delete<dynamic>('$_community/$communityId/members/$userId');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// PATCH /community/:communityId/members/:userId/promote
  Future<void> promoteMember(String communityId, String userId) async {
    try {
      await _dio.patch<dynamic>(
        '$_community/$communityId/members/$userId/promote',
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// PATCH /community/:communityId/members/:userId/demote
  Future<void> demoteModerator(String communityId, String userId) async {
    try {
      await _dio.patch<dynamic>(
        '$_community/$communityId/members/$userId/demote',
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// PATCH /community/:communityId/transfer-admin/:userId
  Future<void> transferAdmin(String communityId, String userId) async {
    try {
      await _dio.patch<dynamic>(
        '$_community/$communityId/transfer-admin/$userId',
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// DELETE /community/:communityId
  Future<void> deleteCommunity(String communityId) async {
    try {
      await _dio.delete<dynamic>('$_community/$communityId');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // ── COMMENTS ──────────────────────────────────────────
  /// GET /community/posts/:postId/comments?page=
  Future<Map<String, dynamic>> getComments(
    String postId, {
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/posts/$postId/comments',
        queryParameters: {'page': page},
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community/posts/:postId/comments
  /// Body: { content, mentions }
  Future<Map<String, dynamic>> addComment(
    String postId, {
    required String content,
    List<Map>? mentions,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_community/posts/$postId/comments',
        data: {
          'content': content,
          if (mentions != null) 'mentions': mentions,
        },
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// DELETE /community/comments/:commentId
  Future<void> deleteComment(String commentId) async {
    try {
      await _dio.delete<dynamic>('$_community/comments/$commentId');
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community/comments/:commentId/like
  Future<Map<String, dynamic>> toggleCommentLike(String commentId) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_community/comments/$commentId/like',
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  // ── REACTIONS ─────────────────────────────────────────
  /// POST /community/posts/:postId/react
  Future<Map<String, dynamic>> reactToPost(String postId, String emoji) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_community/posts/$postId/react',
        data: {'emoji': emoji},
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// GET /community/posts/:postId/reactions
  Future<Map<String, dynamic>> getPostReactions(String postId) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/posts/$postId/reactions',
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  // ── EVENTS ────────────────────────────────────────────
  /// GET /community/:communityId/events?upcoming=
  Future<Map<String, dynamic>> getCommunityEvents(
    String communityId, {
    bool upcoming = true,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/$communityId/events',
        queryParameters: {'upcoming': upcoming},
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community/:communityId/events
  Future<Map<String, dynamic>> createCommunityEvent(
    String communityId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_community/$communityId/events',
        data: data,
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community/:communityId/events/:eventId/join
  Future<void> joinCommunityEvent(String communityId, String eventId) async {
    try {
      await _dio.post<dynamic>(
        '$_community/$communityId/events/$eventId/join',
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community/:communityId/events/:eventId/leave
  Future<void> leaveCommunityEvent(String communityId, String eventId) async {
    try {
      await _dio.post<dynamic>(
        '$_community/$communityId/events/$eventId/leave',
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// DELETE /community/:communityId/events/:eventId
  Future<void> deleteCommunityEvent(String communityId, String eventId) async {
    try {
      await _dio.delete<dynamic>(
        '$_community/$communityId/events/$eventId',
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  // ── ANNOUNCEMENTS ─────────────────────────────────────
  /// GET /community/:communityId/announcements
  Future<Map<String, dynamic>> getAnnouncements(String communityId) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/$communityId/announcements',
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// POST /community/:communityId/announcements
  Future<Map<String, dynamic>> createAnnouncement(
    String communityId, {
    required String title,
    required String content,
    bool isPinned = false,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_community/$communityId/announcements',
        data: {
          'title': title,
          'content': content,
          'isPinned': isPinned,
        },
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// PATCH /community/announcements/:announcementId/pin
  Future<Map<String, dynamic>> togglePinAnnouncement(String announcementId) async {
    try {
      final response = await _dio.patch<dynamic>(
        '$_community/announcements/$announcementId/pin',
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// DELETE /community/announcements/:announcementId
  Future<void> deleteAnnouncement(String announcementId) async {
    try {
      await _dio.delete<dynamic>(
        '$_community/announcements/$announcementId',
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  // ── RULES ─────────────────────────────────────────────
  /// GET /community/:communityId/rules
  Future<Map<String, dynamic>> getCommunityRules(String communityId) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/$communityId/rules',
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// PUT /community/:communityId/rules
  /// Body: { rules }
  Future<Map<String, dynamic>> updateCommunityRules(
    String communityId,
    List<Map> rules,
  ) async {
    try {
      final response = await _dio.put<dynamic>(
        '$_community/$communityId/rules',
        data: {'rules': rules},
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  // ── SEARCH & MENTION ──────────────────────────────────
  /// GET /community/:communityId/posts/search?q=
  Future<Map<String, dynamic>> searchCommunityPosts(
    String communityId,
    String q,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/$communityId/posts/search',
        queryParameters: {'q': q},
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }

  /// GET /community/:communityId/members/mention?q=
  Future<Map<String, dynamic>> getMembersForMention(
    String communityId,
    String q,
  ) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_community/$communityId/members/mention',
        queryParameters: {'q': q},
      );
      if (response.data == null) throw Exception('Invalid response');
      return _requireMap(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e));
    }
  }
}
