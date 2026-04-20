import 'package:dio/dio.dart';

import '../models/track_follow_model.dart';

class TrackFollowRepository {
  TrackFollowRepository(this._dio);

  final Dio _dio;

  static const String _follow = '/follow';

  String _messageFromDio(DioException e, [String fallback = 'Request failed']) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? fallback;
  }

  void _throwIfBadResponse(
    Response<dynamic> response, [
    String fallback = 'Request failed',
  ]) {
    final ok = response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300;
    if (ok) return;
    final data = response.data;
    final message =
        data is Map && data['message'] != null ? data['message'].toString() : fallback;
    throw Exception(message);
  }

  TrackFollowModel _parseFollow(Map<String, dynamic> raw) {
    return TrackFollowModel.fromJson(Map<String, dynamic>.from(raw));
  }

  List<TrackFollowModel> _parseFollowList(dynamic data) {
    if (data is! List) {
      throw Exception('Invalid response');
    }
    return data
        .map(
          (e) => _parseFollow(Map<String, dynamic>.from(e as Map)),
        )
        .toList();
  }

  /// Builds `{ latitude, longitude }` entries for the sync body.
  List<Map<String, double>> _normalizePoints(List<dynamic> points) {
    final out = <Map<String, double>>[];
    for (final p in points) {
      if (p is! Map) {
        throw Exception('Each point must be a map');
      }
      final m = Map<String, dynamic>.from(p);
      final lat = m['latitude'] ?? m['lat'];
      final lng = m['longitude'] ?? m['lng'];
      if (lat is! num || lng is! num) {
        throw Exception('Each point needs latitude and longitude');
      }
      out.add({
        'latitude': lat.toDouble(),
        'longitude': lng.toDouble(),
      });
    }
    return out;
  }

  /// POST /follow/start
  Future<TrackFollowModel> startFollowing(String trackId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_follow/start',
        data: {'trackId': trackId},
      );
      final code = response.statusCode ?? 0;
      if ((code != 200 && code != 201) || response.data == null) {
        _throwIfBadResponse(response, 'Could not start following this track');
      }
      return _parseFollow(Map<String, dynamic>.from(response.data!));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Could not start following this track'));
    }
  }

  /// POST /follow/:followId/sync — [stats] typically includes distance, duration, steps, calories.
  Future<void> syncFollowPoints(
    String followId,
    List<dynamic> points,
    Map<String, dynamic> stats,
  ) async {
    try {
      final body = <String, dynamic>{
        'points': _normalizePoints(points),
        ...stats,
      };
      final response = await _dio.post<dynamic>(
        '$_follow/$followId/sync',
        data: body,
      );
      if (response.statusCode != 200) {
        _throwIfBadResponse(response, 'Could not sync your route');
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Could not sync your route'));
    }
  }

  /// POST /follow/:followId/deviation
  Future<void> recordDeviation(
    String followId,
    double lat,
    double lng,
    double distance,
  ) async {
    try {
      final response = await _dio.post<dynamic>(
        '$_follow/$followId/deviation',
        data: {
          'latitude': lat,
          'longitude': lng,
          'distanceFromTrack': distance,
        },
      );
      if (response.statusCode != 200) {
        _throwIfBadResponse(response, 'Could not record deviation');
      }
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Could not record deviation'));
    }
  }

  /// POST /follow/:followId/complete
  Future<TrackFollowModel> completeFollowing(
    String followId,
    Map<String, dynamic> stats,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_follow/$followId/complete',
        data: stats,
      );
      if (response.statusCode != 200 || response.data == null) {
        _throwIfBadResponse(response, 'Could not complete this follow session');
      }
      return _parseFollow(Map<String, dynamic>.from(response.data!));
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Could not complete this follow session'));
    }
  }

  /// GET /follow/track/:trackId
  Future<List<TrackFollowModel>> getTrackFollowers(String trackId) async {
    try {
      final response = await _dio.get<dynamic>('$_follow/track/$trackId');
      if (response.statusCode != 200) {
        _throwIfBadResponse(response, 'Could not load followers');
      }
      return _parseFollowList(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Could not load followers'));
    }
  }

  /// GET /follow/my
  Future<List<TrackFollowModel>> getMyFollowHistory() async {
    try {
      final response = await _dio.get<dynamic>('$_follow/my');
      if (response.statusCode != 200) {
        _throwIfBadResponse(response, 'Could not load follow history');
      }
      return _parseFollowList(response.data);
    } on DioException catch (e) {
      throw Exception(_messageFromDio(e, 'Could not load follow history'));
    }
  }
}
