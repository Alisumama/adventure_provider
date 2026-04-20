import 'dart:math' as math;

import '../../features/track/data/models/track_model.dart';

/// Spherical helpers to measure distance from the user to a polyline track.
///
/// Distances use the Earth radius [earthRadiusM] (mean spherical radius,
/// WGS84 ~6371 km). Point-to-segment distance follows great-circle segments
/// between consecutive vertices (cross-track / clamped to endpoints).
class OffTrackDetector {
  OffTrackDetector._();

  static const double earthRadiusM = 6371000.0;
  static const double _offTrackThresholdM = 10.0;

  static double _degToRad(double deg) => deg * math.pi / 180.0;

  /// Haversine distance in meters between two WGS84 points.
  static double _haversineMeters(LatLng a, LatLng b) {
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final h = math.sin((lat2 - lat1) / 2) * math.sin((lat2 - lat1) / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusM * c;
  }

  /// Central angle (radians) between [a] and [b] on the unit sphere.
  static double _angularDistanceRad(LatLng a, LatLng b) {
    return _haversineMeters(a, b) / earthRadiusM;
  }

  /// Initial bearing from [from] to [to] in radians, range (−π, π].
  static double _bearingRad(LatLng from, LatLng to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);
    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return math.atan2(y, x);
  }

  /// Shortest distance in meters from [p] to the great-circle arc **segment** A→B,
  /// clamped to endpoints when the perpendicular foot lies outside the arc.
  static double _distancePointToSegmentMeters(LatLng a, LatLng b, LatLng p) {
    final segRad = _angularDistanceRad(a, b);
    if (segRad < 1e-14) {
      return _haversineMeters(p, a);
    }

    final d13 = _angularDistanceRad(a, p);
    final brng12 = _bearingRad(a, b);
    final brng13 = _bearingRad(a, p);

    final sinD13 = math.sin(d13);
    final deltaBrng = brng13 - brng12;
    final u = (sinD13 * math.sin(deltaBrng)).clamp(-1.0, 1.0);
    final xtd = math.asin(u);

    final cosXtd = math.cos(xtd);
    final ratio = cosXtd.abs() < 1e-12
        ? double.nan
        : (math.cos(d13) / cosXtd).clamp(-1.0, 1.0);
    final dAt = math.acos(ratio);

    if (dAt.isNaN) {
      return math.min(_haversineMeters(p, a), _haversineMeters(p, b));
    }

    if (dAt <= 1e-12) {
      return _haversineMeters(p, a);
    }
    if (dAt >= segRad - 1e-12) {
      final da = _haversineMeters(p, a);
      final db = _haversineMeters(p, b);
      return math.min(da, db);
    }

    return earthRadiusM * xtd.abs();
  }

  /// Shortest distance (m) from [userPosition] to any segment of [trackPath].
  ///
  /// For each consecutive pair (A, B), uses perpendicular distance to the
  /// great-circle arc, clamped to [A] or [B] when the foot lies off the segment.
  static double distanceToPath(LatLng userPosition, List<LatLng> trackPath) {
    if (trackPath.isEmpty) {
      return double.infinity;
    }
    if (trackPath.length == 1) {
      return _haversineMeters(userPosition, trackPath.first);
    }
    var minD = double.infinity;
    for (var i = 0; i < trackPath.length - 1; i++) {
      final d = _distancePointToSegmentMeters(
        trackPath[i],
        trackPath[i + 1],
        userPosition,
      );
      if (d < minD) {
        minD = d;
      }
    }
    return minD;
  }

  /// `true` if [userPosition] is more than 10 m from the nearest track segment.
  static bool isOffTrack(LatLng userPosition, List<LatLng> trackPath) {
    return distanceToPath(userPosition, trackPath) > _offTrackThresholdM;
  }

  /// Haversine distance in meters from [userPosition] to the **nearest vertex**
  /// in [trackPath] (does not use segment interiors).
  static double getDeviationDistance(LatLng userPosition, List<LatLng> trackPath) {
    if (trackPath.isEmpty) {
      return double.infinity;
    }
    var best = double.infinity;
    for (final q in trackPath) {
      final d = _haversineMeters(userPosition, q);
      if (d < best) {
        best = d;
      }
    }
    return best;
  }

  static double _segmentLengthMeters(LatLng a, LatLng b) => _haversineMeters(a, b);

  /// Along-segment distance in meters from [a] toward [b] to the closest point on
  /// the arc A→B to [p]. Result is in `[0, segmentLength]`.
  static double _alongSegmentMetersFromA(LatLng a, LatLng b, LatLng p) {
    final segM = _segmentLengthMeters(a, b);
    if (segM < 1e-6) {
      return 0;
    }
    final segRad = _angularDistanceRad(a, b);
    final d13 = _angularDistanceRad(a, p);
    final brng12 = _bearingRad(a, b);
    final brng13 = _bearingRad(a, p);
    final u = (math.sin(d13) * math.sin(brng13 - brng12)).clamp(-1.0, 1.0);
    final xtd = math.asin(u);
    final cosXtd = math.cos(xtd);
    final ratio = cosXtd.abs() < 1e-12
        ? double.nan
        : (math.cos(d13) / cosXtd).clamp(-1.0, 1.0);
    final dAt = math.acos(ratio);

    if (dAt.isNaN) {
      return _haversineMeters(p, a) <= _haversineMeters(p, b) ? 0 : segM;
    }
    if (dAt <= 1e-12) {
      return 0;
    }
    if (dAt >= segRad - 1e-12) {
      return _haversineMeters(p, a) <= _haversineMeters(p, b) ? 0 : segM;
    }

    return (earthRadiusM * dAt).clamp(0.0, segM);
  }

  /// Fraction `[0, 1]` of total path length to the point on [trackPath] that is
  /// closest to [userPosition] (perpendicular to segments, clamped to endpoints).
  static double _fractionAlongPath(LatLng userPosition, List<LatLng> trackPath) {
    if (trackPath.length < 2) {
      return 0;
    }

    var totalM = 0.0;
    final segmentLengths = List<double>.filled(trackPath.length - 1, 0);
    for (var i = 0; i < trackPath.length - 1; i++) {
      final len = _segmentLengthMeters(trackPath[i], trackPath[i + 1]);
      segmentLengths[i] = len;
      totalM += len;
    }
    if (totalM < 1e-9) {
      return 0;
    }

    var minD = double.infinity;
    var bestDistanceAlong = 0.0;

    var prefix = 0.0;
    for (var i = 0; i < trackPath.length - 1; i++) {
      final a = trackPath[i];
      final b = trackPath[i + 1];
      final d = _distancePointToSegmentMeters(a, b, userPosition);
      if (d < minD) {
        minD = d;
        final along = _alongSegmentMetersFromA(a, b, userPosition);
        bestDistanceAlong = prefix + along;
      }
      prefix += segmentLengths[i];
    }

    return (bestDistanceAlong / totalM).clamp(0.0, 1.0);
  }

  /// Percentage `0.0` … `100.0` of path length to the closest point on the polyline
  /// (same projection rule as [distanceToPath]).
  static double getCompletionPercentage(
    LatLng userPosition,
    List<LatLng> trackPath,
  ) {
    if (trackPath.isEmpty) {
      return 0;
    }
    if (trackPath.length == 1) {
      return _haversineMeters(userPosition, trackPath.first) < 1e-6 ? 100.0 : 0.0;
    }
    return (_fractionAlongPath(userPosition, trackPath) * 100.0).clamp(0.0, 100.0);
  }
}
