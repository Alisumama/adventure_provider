import 'package:dio/dio.dart';
import 'package:get/get.dart' hide FormData, MultipartFile, Response;
import 'package:image_picker/image_picker.dart';

import '../../../auth/controllers/auth_controller.dart';
import '../models/track_model.dart';

class TrackRepository {
  TrackRepository(this._dio);

  final Dio _dio;

  static const String _tracks = '/tracks';

  String _messageFromDio(DioException e, [String fallback = 'Request failed']) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  void _throwIfBadResponse(Response<dynamic> response, [String fallback = 'Request failed']) {
    final ok = response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;
    if (ok) return;
    final data = response.data;
    final message = data is Map && data['message'] != null
        ? data['message'].toString()
        : fallback;
    throw Exception(message);
  }

  List<TrackModel> _parseTrackList(dynamic data) {
    if (data is! List) {
      throw Exception('Invalid response');
    }
    return data
        .map((e) => TrackModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  TrackModel _parseTrack(dynamic data) {
    if (data is! Map) {
      throw Exception('Invalid response');
    }
    return TrackModel.fromJson(Map<String, dynamic>.from(data));
  }

  /// POST /tracks/draft — minimal track for live recording (returns `_id` for Socket.io room).
  Future<TrackModel> createDraftTrack(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_tracks/draft',
        data: data,
      );
      if (response.statusCode != 201 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to start track');
      }
      return _parseTrack(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to start track'));
    }
  }

  /// POST /tracks
  Future<TrackModel> createTrack(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _tracks,
        data: data,
      );
      if (response.statusCode != 201 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to create track');
      }
      return _parseTrack(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to create track'));
    }
  }

  /// GET /tracks/my
  Future<List<TrackModel>> getMyTracks() async {
    try {
      final response = await _dio.get<dynamic>('$_tracks/my');
      if (response.statusCode != 200) {
        _throwIfBadResponse(response, 'Failed to load tracks');
      }
      return _parseTrackList(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to load tracks'));
    }
  }

  /// GET /tracks/nearby?lat=&lng=&radius=
  Future<List<TrackModel>> getNearbyTracks(
    double lat,
    double lng, {
    double radius = 10000,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '$_tracks/nearby',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'radius': radius,
        },
      );
      if (response.statusCode != 200) {
        _throwIfBadResponse(response, 'Failed to load nearby tracks');
      }
      return _parseTrackList(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to load nearby tracks'));
    }
  }

  /// GET /tracks/:id
  Future<TrackModel> getTrackById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_tracks/$id');
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to load track');
      }
      String? uid;
      try {
        uid = Get.find<AuthController>().user.value?.id;
      } catch (_) {
        uid = null;
      }
      return TrackModel.fromJson(
        Map<String, dynamic>.from(response.data!),
        currentUserId: uid,
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to load track'));
    }
  }

  /// PUT /tracks/:id
  Future<TrackModel> updateTrack(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_tracks/$id',
        data: data,
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to update track');
      }
      return _parseTrack(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to update track'));
    }
  }

  /// DELETE /tracks/:id
  Future<void> deleteTrack(String id) async {
    try {
      final response = await _dio.delete<dynamic>('$_tracks/$id');
      if (response.statusCode != 200) {
        _throwIfBadResponse(response, 'Failed to delete track');
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to delete track'));
    }
  }

  /// POST /tracks/:id/like
  Future<TrackModel> likeTrack(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('$_tracks/$id/like');
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to update like');
      }
      return _parseTrack(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to update like'));
    }
  }

  /// POST /tracks/:id/save
  Future<TrackModel> saveTrack(String id) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('$_tracks/$id/save');
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to update save');
      }
      return _parseTrack(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to update save'));
    }
  }

  /// POST /tracks/:id/flag-image — multipart field `image`; returns public `url` for Socket `add_flag`.
  Future<String> uploadTrackFlagImage(String trackId, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final name = file.name.trim();
      final filename = name.isNotEmpty ? name : 'flag.jpg';
      final formData = FormData.fromMap({
        'image': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '$_tracks/$trackId/flag-image',
        data: formData,
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to upload image');
      }
      final url = response.data!['url'];
      if (url is! String || url.isEmpty) {
        throw Exception('Invalid response from server');
      }
      return url;
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to upload image'));
    }
  }

  /// POST /tracks/:id/flag
  Future<TrackModel> addFlag(String trackId, Map<String, dynamic> flagData) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_tracks/$trackId/flag',
        data: flagData,
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to add flag');
      }
      return _parseTrack(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to add flag'));
    }
  }

  /// POST /tracks/:id/photo
  Future<TrackModel> addPhoto(String trackId, String photoUrl) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_tracks/$trackId/photo',
        data: {'photoUrl': photoUrl},
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to add photo');
      }
      return _parseTrack(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to add photo'));
    }
  }

  /// POST /tracks/:id/photos — multipart field `photo`.
  Future<TrackModel> uploadTrackPhoto(String trackId, XFile file) async {
    try {
      final bytes = await file.readAsBytes();
      final name = file.name.trim();
      final filename = name.isNotEmpty ? name : 'photo.jpg';
      final formData = FormData.fromMap({
        'photo': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });
      final response = await _dio.post<Map<String, dynamic>>(
        '$_tracks/$trackId/photos',
        data: formData,
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to upload photo');
      }
      String? uid;
      try {
        uid = Get.find<AuthController>().user.value?.id;
      } catch (_) {
        uid = null;
      }
      return TrackModel.fromJson(
        Map<String, dynamic>.from(response.data!),
        currentUserId: uid,
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to upload photo'));
    }
  }

  /// DELETE /tracks/:id/photos/:photoIndex
  Future<TrackModel> deleteTrackPhoto(String trackId, int photoIndex) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '$_tracks/$trackId/photos/$photoIndex',
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to delete photo');
      }
      String? uid;
      try {
        uid = Get.find<AuthController>().user.value?.id;
      } catch (_) {
        uid = null;
      }
      return TrackModel.fromJson(
        Map<String, dynamic>.from(response.data!),
        currentUserId: uid,
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to delete photo'));
    }
  }

  String? _currentUserId() {
    try {
      return Get.find<AuthController>().user.value?.id;
    } catch (_) {
      return null;
    }
  }

  /// POST /tracks/:id/flags — JSON body.
  Future<TrackModel> postTrackFlag(
    String trackId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_tracks/$trackId/flags',
        data: body,
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to add flag');
      }
      return TrackModel.fromJson(
        Map<String, dynamic>.from(response.data!),
        currentUserId: _currentUserId(),
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to add flag'));
    }
  }

  /// PUT /tracks/:id/flags/:flagId
  Future<TrackModel> putTrackFlag(
    String trackId,
    String flagId,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.put<Map<String, dynamic>>(
        '$_tracks/$trackId/flags/$flagId',
        data: body,
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to update flag');
      }
      return TrackModel.fromJson(
        Map<String, dynamic>.from(response.data!),
        currentUserId: _currentUserId(),
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to update flag'));
    }
  }

  /// DELETE /tracks/:id/flags/:flagId
  Future<TrackModel> deleteTrackFlag(String trackId, String flagId) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>(
        '$_tracks/$trackId/flags/$flagId',
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Failed to delete flag');
      }
      return TrackModel.fromJson(
        Map<String, dynamic>.from(response.data!),
        currentUserId: _currentUserId(),
      );
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Failed to delete flag'));
    }
  }
}
