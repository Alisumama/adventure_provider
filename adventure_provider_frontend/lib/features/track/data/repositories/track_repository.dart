import 'package:dio/dio.dart';

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
      return _parseTrack(response.data);
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
}
