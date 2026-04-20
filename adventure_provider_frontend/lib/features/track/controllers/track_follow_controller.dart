import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/services/off_track_detector.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/local/local_follow_repository.dart';
import '../data/local/track_local_models.dart';
import '../data/models/track_follow_model.dart';
import '../data/models/track_model.dart';
import '../data/repositories/track_follow_repository.dart';

/// Live session: follow a published track with offline-first GPS sync to `/api/follow`.
class TrackFollowController extends GetxController {
  TrackFollowController(
    this._followRepository,
    this._localFollow,
    this._connectivity,
  );

  final TrackFollowRepository _followRepository;
  final LocalFollowRepository _localFollow;
  final Connectivity _connectivity;

  static const double _avgStepMeters = 0.762;
  static const double _kcalPerMeter = 0.055;
  static const int _maxPointsPerSync = 50;

  final RxBool isFollowing = false.obs;
  final Rxn<TrackFollowModel> currentFollowSession = Rxn<TrackFollowModel>();
  final RxList<LatLng> activeTrackPath = <LatLng>[].obs;
  final RxList<LatLng> userFollowPath = <LatLng>[].obs;

  /// Same length as [userFollowPath]: whether each GPS point was off the published route.
  final RxList<bool> userFollowOffTrack = <bool>[].obs;
  final RxBool isOffTrack = false.obs;
  final RxDouble deviationDistance = 0.0.obs;
  final RxDouble completionPercentage = 0.0.obs;
  final Rxn<LatLng> currentPosition = Rxn<LatLng>();
  final RxBool isOnline = true.obs;
  final RxInt pendingPointsCount = 0.obs;

  final RxDouble followDistance = 0.0.obs;
  final RxInt followDuration = 0.obs;
  final RxInt followSteps = 0.obs;
  final RxInt followCalories = 0.obs;

  /// Set when [stopFollowing] completes successfully; consume in UI for completion UX.
  final Rxn<TrackFollowModel> lastCompletedFollow = Rxn<TrackFollowModel>();

  String _localFollowSessionId = '';
  StreamSubscription<Position>? _positionSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _durationTimer;
  Timer? _syncTimer;

  Future<void> _mutex = Future<void>.value();
  int _pointSeq = 0;

  /// Latest off-route sample to send with the next successful sync (cleared after [recordDeviation]).
  double? _pendingDeviationLat;
  double? _pendingDeviationLng;
  double? _pendingDeviationDistance;

  @override
  void onInit() {
    super.onInit();
    _connectivitySub =
        _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    unawaited(_seedIsOnline());
  }

  @override
  void onClose() {
    unawaited(_positionSub?.cancel() ?? Future<void>.value());
    _durationTimer?.cancel();
    _syncTimer?.cancel();
    _connectivitySub?.cancel();
    super.onClose();
  }

  Future<void> _seedIsOnline() async {
    final r = await _connectivity.checkConnectivity();
    isOnline.value = r.any((x) => x != ConnectivityResult.none);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    isOnline.value = results.any((r) => r != ConnectivityResult.none);
  }

  String _friendlyMessage(Object e) {
    final s = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    if (s.isEmpty) return 'Something went wrong. Please try again.';
    return s;
  }

  void _updateStepsAndCalories() {
    followSteps.value =
        (followDistance.value / _avgStepMeters).floor().clamp(0, 1 << 30);
    followCalories.value =
        (followDistance.value * _kcalPerMeter).round().clamp(0, 1 << 30);
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location off',
        'Turn on location services to follow a track.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    var ph = await Permission.location.status;
    if (ph.isDenied) {
      ph = await Permission.location.request();
    }
    if (ph.isPermanentlyDenied) {
      Get.snackbar(
        'Location needed',
        'Enable location permission in Settings to follow a route.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    if (!ph.isGranted) {
      Get.snackbar(
        'Permission denied',
        'Location permission is required to follow this track.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  Future<T> _runLocked<T>(Future<T> Function() fn) async {
    final prev = _mutex;
    final done = Completer<void>();
    _mutex = done.future;
    await prev;
    try {
      return await fn();
    } finally {
      done.complete();
    }
  }

  /// Starts an authenticated follow session: server row + Hive + GPS + 3s sync.
  Future<void> startFollowing(TrackModel track) async {
    if (isFollowing.value) {
      return;
    }
    final auth = Get.find<AuthController>();
    if (auth.user.value?.id == null || auth.user.value!.id!.isEmpty) {
      Get.snackbar(
        'Sign in required',
        'Please sign in to follow a track.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final trackId = track.id;
    if (trackId == null || trackId.isEmpty) {
      Get.snackbar('Error', 'Invalid track.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final locOk = await _ensureLocationPermission();
    if (!locOk) return;

    try {
      final model = await _followRepository.startFollowing(trackId);
      final serverFollowId = model.id;
      if (serverFollowId == null || serverFollowId.isEmpty) {
        throw Exception('Missing follow id from server.');
      }

      _localFollowSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      _pointSeq = 0;

      final session = TrackFollowSessionLocal(
        followSessionId: _localFollowSessionId,
        trackId: trackId,
        followId: serverFollowId,
        startedAt: DateTime.now(),
      );
      _localFollow.saveSession(session);

      currentFollowSession.value = model;
      activeTrackPath.assignAll(track.geoPath);
      userFollowPath.clear();
      userFollowOffTrack.clear();
      lastCompletedFollow.value = null;
      followDistance.value = 0;
      followDuration.value = 0;
      followSteps.value = 0;
      followCalories.value = 0;
      completionPercentage.value = 0;
      deviationDistance.value = 0;
      isOffTrack.value = false;
      _pendingDeviationLat = null;
      currentPosition.value = null;

      pendingPointsCount.value = 0;

      isFollowing.value = true;

      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (isFollowing.value) {
          followDuration.value++;
        }
      });

      _syncTimer?.cancel();
      _syncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!isFollowing.value) return;
        unawaited(_runLocked(_syncFollowFromLocal));
      });
      unawaited(_runLocked(_syncFollowFromLocal));

      await _positionSub?.cancel();
      _positionSub = null;

      const settings =
          LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);
      _positionSub =
          Geolocator.getPositionStream(locationSettings: settings).listen(
        (position) {
          _onPosition(LatLng(position.latitude, position.longitude));
        },
        onError: (_) {
          Get.snackbar(
            'GPS error',
            'Location update failed.',
            snackPosition: SnackPosition.BOTTOM,
          );
        },
      );
    } catch (e) {
      Get.snackbar(
        'Could not start',
        _friendlyMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _onPosition(LatLng point) {
    if (!isFollowing.value) return;

    final path = activeTrackPath.toList(growable: false);
    final off = path.isEmpty
        ? false
        : OffTrackDetector.isOffTrack(point, path);
    final distToPath =
        path.isEmpty ? 0.0 : OffTrackDetector.distanceToPath(point, path);

    if (off) {
      isOffTrack.value = true;
      deviationDistance.value = distToPath;
      _pendingDeviationLat = point.latitude;
      _pendingDeviationLng = point.longitude;
      _pendingDeviationDistance = distToPath;
    } else {
      isOffTrack.value = false;
      deviationDistance.value = 0;
    }

    final pct = path.isEmpty
        ? 0.0
        : OffTrackDetector.getCompletionPercentage(point, path);
    completionPercentage.value = pct;

    if (userFollowPath.isNotEmpty) {
      final last = userFollowPath.last;
      final delta = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        point.latitude,
        point.longitude,
      );
      followDistance.value += delta;
      _updateStepsAndCalories();
    }

    userFollowPath.add(point);
    userFollowOffTrack.add(off);
    currentPosition.value = point;

    _pointSeq++;
    final pid = '${_localFollowSessionId}_p$_pointSeq';
    final localPoint = TrackFollowPointLocal(
      id: pid,
      followSessionId: _localFollowSessionId,
      latitude: point.latitude,
      longitude: point.longitude,
      timestamp: DateTime.now(),
      isOffTrack: off,
      distanceFromTrack: distToPath,
    );
    _localFollow.saveFollowPoint(localPoint);

    final s = _localFollow.getSession(_localFollowSessionId);
    if (s != null) {
      s.totalDistance = followDistance.value;
      s.duration = followDuration.value;
      s.steps = followSteps.value;
      s.calories = followCalories.value;
      _localFollow.updateSession(s);
    }

    pendingPointsCount.value =
        _localFollow.getUnsyncedPoints(_localFollowSessionId).length;
  }

  /// Treat [point] like the next GPS fix: path, off-track, distance, Hive, sync.
  /// For simulator / map-tap testing (real [Geolocator] stream may still emit fixes).
  void applyMapTapAsUserLocation(LatLng point) {
    _onPosition(point);
  }

  Future<void> _syncFollowFromLocal() async {
    if (!isFollowing.value) return;
    final results = await _connectivity.checkConnectivity();
    if (!results.any((r) => r != ConnectivityResult.none)) {
      return;
    }

    final session = _localFollow.getSession(_localFollowSessionId);
    if (session == null) return;

    final followId = session.followId;
    if (followId.isEmpty) return;

    while (true) {
      final unsynced = _localFollow.getUnsyncedPoints(_localFollowSessionId);
      if (unsynced.isEmpty) break;

      final chunk = unsynced.length > _maxPointsPerSync
          ? unsynced.sublist(0, _maxPointsPerSync)
          : unsynced;

      final points = chunk
          .map(
            (p) => <String, double>{
              'latitude': p.latitude,
              'longitude': p.longitude,
            },
          )
          .toList();

      final stats = <String, dynamic>{
        'totalDistance': followDistance.value,
        'duration': followDuration.value,
        'steps': followSteps.value,
        'calories': followCalories.value,
      };

      try {
        await _followRepository.syncFollowPoints(followId, points, stats);
        _localFollow.markPointsSynced(chunk.map((p) => p.id).toList());
      } catch (_) {
        return;
      }
    }

    if (_pendingDeviationLat != null &&
        _pendingDeviationLng != null &&
        _pendingDeviationDistance != null) {
      try {
        await _followRepository.recordDeviation(
          followId,
          _pendingDeviationLat!,
          _pendingDeviationLng!,
          _pendingDeviationDistance!,
        );
        _pendingDeviationLat = null;
        _pendingDeviationLng = null;
        _pendingDeviationDistance = null;
      } catch (_) {
        // keep pending for next interval
      }
    }

    pendingPointsCount.value =
        _localFollow.getUnsyncedPoints(_localFollowSessionId).length;
  }

  Future<void> _forceSyncFollow() async {
    for (var i = 0; i < 64; i++) {
      await _runLocked(_syncFollowFromLocal);
      final remaining =
          _localFollow.getUnsyncedPoints(_localFollowSessionId).length;
      final pendingDev = _pendingDeviationLat != null;
      if (remaining == 0 && !pendingDev) {
        break;
      }
    }
  }

  /// Ends follow mode: stops GPS, flushes Hive, completes on server, shows summary.
  Future<void> stopFollowing() async {
    if (!isFollowing.value) return;

    final followId = currentFollowSession.value?.id;
    if (followId == null || followId.isEmpty) {
      if (_localFollowSessionId.isNotEmpty) {
        _localFollow.deleteSession(_localFollowSessionId);
      }
      await _resetFollowState();
      return;
    }

    _durationTimer?.cancel();
    _durationTimer = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    await _positionSub?.cancel();
    _positionSub = null;

    try {
      await _forceSyncFollow();

      final stats = <String, dynamic>{
        'totalDistance': followDistance.value,
        'duration': followDuration.value,
        'steps': followSteps.value,
        'calories': followCalories.value,
        'completionPercentage': completionPercentage.value.clamp(0, 100),
      };

      final completed =
          await _followRepository.completeFollowing(followId, stats);

      final sess = _localFollow.getSession(_localFollowSessionId);
      if (sess != null) {
        sess.isCompleted = true;
        sess.isSynced = true;
        _localFollow.updateSession(sess);
      }

      lastCompletedFollow.value = completed;
    } catch (e) {
      Get.snackbar(
        'Could not finish',
        _friendlyMessage(e),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (_localFollowSessionId.isNotEmpty) {
        _localFollow.deleteSession(_localFollowSessionId);
      }
      await _resetFollowState();
    }
  }

  /// Clears [lastCompletedFollow] after the UI has shown the completion sheet.
  void clearLastCompletedFollow() {
    lastCompletedFollow.value = null;
  }

  Future<void> _resetFollowState() async {
    isFollowing.value = false;
    currentFollowSession.value = null;
    activeTrackPath.clear();
    userFollowPath.clear();
    userFollowOffTrack.clear();
    isOffTrack.value = false;
    deviationDistance.value = 0;
    completionPercentage.value = 0;
    currentPosition.value = null;
    pendingPointsCount.value = 0;
    followDistance.value = 0;
    followDuration.value = 0;
    followSteps.value = 0;
    followCalories.value = 0;
    _localFollowSessionId = '';
    _pendingDeviationLat = null;
    _pendingDeviationLng = null;
    _pendingDeviationDistance = null;
    _pointSeq = 0;
  }
}
