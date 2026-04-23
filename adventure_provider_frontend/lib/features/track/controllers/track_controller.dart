import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/controllers/navigation_controller.dart';
import '../../../core/services/image_upload_service.dart';
import '../../../core/services/track_sync_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/local/local_track_repository.dart';
import '../data/local/track_local_models.dart';
import '../data/models/add_flag_data.dart';
import '../data/models/track_model.dart';
import '../data/repositories/track_repository.dart';

class TrackController extends GetxController {
  TrackController(this._repository, this._imageUpload, this._local, this._trackSync, this._connectivity);

  final TrackRepository _repository;
  final ImageUploadService _imageUpload;
  final LocalTrackRepository _local;
  final TrackSyncService _trackSync;
  final Connectivity _connectivity;

  final RxList<TrackModel> myTracks = <TrackModel>[].obs;
  final RxList<TrackModel> nearbyTracks = <TrackModel>[].obs;
  final Rxn<TrackModel> selectedTrack = Rxn<TrackModel>();

  /// Mirrors [TrackModel.photos] for the current [selectedTrack] detail view.
  final RxList<String> trackPhotos = <String>[].obs;

  /// Mirrors [TrackModel.flags] for the current [selectedTrack] detail view.
  final RxList<TrackFlag> trackFlags = <TrackFlag>[].obs;

  final RxBool isLoading = false.obs;
  final RxBool isRecording = false.obs;

  /// True when device has network (used for offline recording UX).
  final RxBool isOnline = true.obs;

  /// Unsynced GPS points for the active legacy session ([activeSessionId]).
  final RxInt pendingPointsCount = 0.obs;

  /// Local Hive session id for [startRecording] (not the live-map draft id).
  final RxString activeSessionId = ''.obs;

  /// Track list filter: `all` | `hiking` | `offroad` | `cycling` | `running`.
  final RxString selectedFilter = 'all'.obs;
  final RxString trackSearchQuery = ''.obs;

  /// Legacy list (kept in sync with [pathPoints] during live recording).
  final RxList<LatLng> recordingPath = <LatLng>[].obs;

  /// Live polyline + socket path (primary during live session).
  final RxList<LatLng> pathPoints = <LatLng>[].obs;
  final Rxn<LatLng> currentLocation = Rxn<LatLng>();

  final RxDouble recordingDistance = 0.0.obs;
  final RxInt recordingDuration = 0.obs;
  final RxInt recordingSteps = 0.obs;
  final RxInt recordingCalories = 0.obs;

  /// Live map UI: title from track info form; testing banner when simulating GPS.
  final RxString liveTrackName = ''.obs;
  final RxBool liveTestingMode = false.obs;

  /// Draft track id from POST /tracks/draft; Socket.io room id.
  final RxString liveTrackId = ''.obs;

  /// Flags dropped during live recording (shown on the map immediately).
  final RxList<LiveTrackFlag> liveFlags = <LiveTrackFlag>[].obs;

  sio.Socket? _socket;

  /// Legacy recording ([startRecording]) GPS stream.
  StreamSubscription<Position>? _positionSub;

  /// Live session GPS ([startGpsTracking] / [pauseGps] / [resumeGps]).
  StreamSubscription<Position>? _gpsPositionSub;
  Timer? _durationTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// Hive [TrackPointLocal.id] must be unique; [microsecondsSinceEpoch] alone can repeat in one frame.
  int _legacyPointSeq = 0;
  int _livePointSeq = 0;

  static const double _avgStepMeters = 0.762;
  static const double _kcalPerMeter = 0.055;

  String _cleanError(Object e) => e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  String _friendlyMessage(Object e) {
    final s = _cleanError(e);
    if (s.isEmpty) return 'Something went wrong. Please try again.';
    return s;
  }

  String _friendlySocketMessage(dynamic data) {
    if (data is Map && data['message'] != null) {
      final m = data['message'].toString().trim();
      if (m.isNotEmpty) return m;
    }
    return 'Something went wrong. Please try again.';
  }

  void _replaceTrackInList(RxList<TrackModel> list, TrackModel updated) {
    final id = updated.id;
    if (id == null) return;
    final i = list.indexWhere((t) => t.id == id);
    if (i >= 0) {
      list[i] = updated;
    }
  }

  void _applyTrackUpdate(TrackModel updated) {
    _replaceTrackInList(myTracks, updated);
    _replaceTrackInList(nearbyTracks, updated);
    if (selectedTrack.value?.id == updated.id) {
      selectedTrack.value = updated;
      trackPhotos.assignAll(updated.photos);
      trackFlags.assignAll(updated.flags);
    }
  }

  void _updateStepsAndCalories() {
    recordingSteps.value = (recordingDistance.value / _avgStepMeters).floor().clamp(0, 1 << 30);
    recordingCalories.value = (recordingDistance.value * _kcalPerMeter).round().clamp(0, 1 << 30);
  }

  @override
  void onInit() {
    super.onInit();
    _connectivitySub = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
    unawaited(_seedIsOnline());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_handleInterruptedSessionsIfAny());
    });
  }

  /// Prompts when local Hive has [TrackSessionLocal] rows with [TrackSessionLocal.isCompleted] == false.
  Future<void> _handleInterruptedSessionsIfAny() async {
    final incomplete = _local.getAllIncompleteSessions();
    if (incomplete.isEmpty) return;

    final save = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Unfinished session'),
        content: const Text('You have an unfinished track session. Would you like to save it or discard it?'),
        actions: [
          TextButton(onPressed: () => Get.back<bool>(result: false), child: const Text('Discard')),
          FilledButton(onPressed: () => Get.back<bool>(result: true), child: const Text('Save')),
        ],
      ),
      barrierDismissible: false,
    );

    if (save == true) {
      incomplete.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      final primary = incomplete.first;
      for (final s in incomplete) {
        if (s.sessionId != primary.sessionId) {
          _local.deleteSession(s.sessionId);
        }
      }
      await _restoreInterruptedSessionForSave(primary);
      final points = _local.getSessionPoints(primary.sessionId);
      if (points.isEmpty) {
        Get.snackbar('Nothing to save', 'This session has no GPS points.', snackPosition: SnackPosition.BOTTOM);
        _local.deleteSession(primary.sessionId);
        _discardLegacyRecordingAfterSave();
        return;
      }
      _showRecordingCompleteSheet();
    } else {
      for (final s in incomplete) {
        _local.deleteSession(s.sessionId);
      }
    }
  }

  /// Rehydrates [recordingPath] / stats from Hive after a crash or force-close during recording.
  Future<void> _restoreInterruptedSessionForSave(TrackSessionLocal session) async {
    final sid = session.sessionId;
    final points = _local.getSessionPoints(sid);
    points.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final latLngs = points.map((p) => LatLng(p.latitude, p.longitude)).toList();
    recordingPath.assignAll(latLngs);
    pathPoints.assignAll(latLngs);

    var dist = 0.0;
    for (var i = 1; i < latLngs.length; i++) {
      final a = latLngs[i - 1];
      final b = latLngs[i];
      dist += Geolocator.distanceBetween(a.latitude, a.longitude, b.latitude, b.longitude);
    }
    recordingDistance.value = dist;
    _updateStepsAndCalories();

    final durationSec = session.duration > 0 ? session.duration : (points.isNotEmpty ? points.last.timestamp.difference(session.startedAt).inSeconds.clamp(0, 1 << 30) : 0);
    recordingDuration.value = durationSec;

    currentLocation.value = latLngs.isNotEmpty ? latLngs.last : null;

    activeSessionId.value = sid;
    pendingPointsCount.value = _local.getUnsyncedPoints(sid).length;

    final updated = _local.getSession(sid);
    if (updated != null) {
      updated.isCompleted = true;
      updated.totalPoints = latLngs.length;
      updated.distance = dist;
      updated.steps = recordingSteps.value;
      updated.calories = recordingCalories.value;
      updated.duration = recordingDuration.value;
      _local.updateSession(updated);
    }

    await _trackSync.forceSync(sid);
    _trackSync.stopSync();
    await _tryCreateServerTrackForSession(sid);
    pendingPointsCount.value = _local.getUnsyncedPoints(sid).length;
  }

  Future<void> _seedIsOnline() async {
    final r = await _connectivity.checkConnectivity();
    isOnline.value = r.any((x) => x != ConnectivityResult.none);
    if (isOnline.value) {
      await _flushLocalTracksWhenOnline();
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    isOnline.value = results.any((r) => r != ConnectivityResult.none);
    if (isOnline.value) {
      unawaited(_flushLocalTracksWhenOnline());
    }
  }

  /// Creates server tracks for any local session missing [TrackSessionLocal.serverTrackId], then
  /// pushes all unsynced [TrackPointLocal] rows from Hive via [TrackSyncService].
  Future<void> _flushLocalTracksWhenOnline() async {
    final sessionsWithPending = _local.getSessionIdsWithUnsyncedPoints();
    for (final sid in sessionsWithPending) {
      final s = _local.getSession(sid);
      if (s != null && s.serverTrackId.isEmpty) {
        await _tryCreateServerTrackForSession(sid);
      }
    }
    await _trackSync.syncAllUnsyncedSessions();
    final active = activeSessionId.value;
    if (active.isNotEmpty) {
      pendingPointsCount.value = _local.getUnsyncedPoints(active).length;
    }
  }

  /// POST /tracks with minimal payload; persists [TrackSessionLocal.serverTrackId] when online.
  Future<void> _tryCreateServerTrackForSession(String sessionId) async {
    final existing = _local.getSession(sessionId);
    if (existing == null || existing.serverTrackId.isNotEmpty) return;
    try {
      final created = await _repository.createTrack(<String, dynamic>{
        'title': 'Recording',
        'description': '',
        'type': 'hiking',
        'difficulty': 'moderate',
        'distance': 0,
        'duration': 0,
        'steps': 0,
        'calories': 0,
        'isPublic': true,
        'geoPath': <String, dynamic>{'type': 'LineString', 'coordinates': <dynamic>[]},
      });
      final id = created.id;
      if (id == null || id.isEmpty) return;
      final s = _local.getSession(sessionId);
      if (s == null) return;
      s.serverTrackId = id;
      _local.updateSession(s);
      await _trackSync.forceSync(sessionId);
      pendingPointsCount.value = _local.getUnsyncedPoints(sessionId).length;
    } catch (_) {
      // Offline or failed; retry when connectivity updates.
    }
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Location off', 'Turn on location services to record a track.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      Get.snackbar('Permission denied', 'Location permission is required to record.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    return true;
  }

  void _ensureSocketConnected() {
    if (_socket != null) {
      return;
    }
    final url = ApiConfig.serverOrigin.replaceAll(RegExp(r'/+$'), '');
    _socket = sio.io(url, sio.OptionBuilder().setTransports(['websocket']).enableAutoConnect().build());
    _socket!.on('track_error', (dynamic data) {
      Get.snackbar('Track', _friendlySocketMessage(data), snackPosition: SnackPosition.BOTTOM);
    });
  }

  void _emitStartTrack({required String userId, required String trackId}) {
    _ensureSocketConnected();
    final s = _socket;
    if (s == null) return;

    void emit() {
      s.emit('start_track', <String, dynamic>{'userId': userId, 'trackId': trackId});
    }

    if (s.connected) {
      emit();
    } else {
      s.once('connect', (_) => emit());
    }
  }

  void _disconnectSocket() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {
      // ignore
    }
    _socket = null;
  }

  Future<void> fetchMyTracks() async {
    isLoading.value = true;
    try {
      final list = await _repository.getMyTracks();
      myTracks.assignAll(list);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchPublicTracks() async {
    isLoading.value = true;
    try {
      final list = await _repository.getPublicTracks();
      myTracks.assignAll(list);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchNearbyTracks(double lat, double lng) async {
    isLoading.value = true;
    try {
      final list = await _repository.getNearbyTracks(lat, lng);
      nearbyTracks.assignAll(list);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTrackById(String id) async {
    isLoading.value = true;
    try {
      final track = await _repository.getTrackById(id);
      selectedTrack.value = track;
      trackPhotos.assignAll(track.photos);
      trackFlags.assignAll(track.flags);
      _replaceTrackInList(myTracks, track);
      _replaceTrackInList(nearbyTracks, track);
    } catch (e) {
      selectedTrack.value = null;
      trackPhotos.clear();
      trackFlags.clear();
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteTrack(String id) async {
    isLoading.value = true;
    try {
      await _repository.deleteTrack(id);
      myTracks.removeWhere((t) => t.id == id);
      nearbyTracks.removeWhere((t) => t.id == id);
      if (selectedTrack.value?.id == id) {
        selectedTrack.value = null;
        trackPhotos.clear();
        trackFlags.clear();
      }
      Get.back<void>();
      Get.snackbar('Deleted', 'Track removed.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates draft track, joins Socket.io room, starts timer + GPS (or tap-only in testing mode), opens live map.
  Future<void> startTrack({required String trackName, required String description, required String trackType, required String difficulty, required bool isPublic, required bool isTestingMode}) async {
    final auth = Get.find<AuthController>();
    final uid = auth.user.value?.id;
    if (uid == null || uid.isEmpty) {
      Get.snackbar('Sign in required', 'Please sign in to record a track.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    liveTrackName.value = trackName;
    liveTestingMode.value = isTestingMode;

    isLoading.value = true;
    try {
      final created = await _repository.createDraftTrack(<String, dynamic>{'title': trackName, 'description': description, 'type': trackType, 'difficulty': difficulty, 'isPublic': isPublic, 'isTesting': isTestingMode});

      final id = created.id;
      if (id == null || id.isEmpty) {
        Get.snackbar('Error', 'Could not start track. Please try again.', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      liveTrackId.value = id;
      _emitStartTrack(userId: uid, trackId: id);

      pathPoints.clear();
      recordingPath.clear();
      liveFlags.clear();
      recordingDistance.value = 0;
      recordingDuration.value = 0;
      recordingSteps.value = 0;
      recordingCalories.value = 0;
      currentLocation.value = null;

      // Create local Hive session for offline-first sync.
      final session = TrackSessionLocal(sessionId: id, startedAt: DateTime.now(), serverTrackId: id);
      _local.saveSession(session);
      activeSessionId.value = id;
      _livePointSeq = 0;
      _trackSync.startSync(id);

      isRecording.value = true;

      _durationTimer?.cancel();
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (isRecording.value) {
          recordingDuration.value++;
        }
      });

      _gpsPositionSub?.cancel();
      _gpsPositionSub = null;

      if (!isTestingMode) {
        final gpsOk = await startGpsTracking();
        if (!gpsOk) {
          await _resetLiveSession(clearDraftId: true);
          return;
        }
      }

      Get.toNamed(AppRoutes.liveMapRecording);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Starts live GPS: [permission_handler] + position stream (5 m updates). Returns `false` if permission denied.
  Future<bool> startGpsTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Location off', 'Turn on location services to record a track.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    var ph = await Permission.location.status;
    if (ph.isDenied) {
      ph = await Permission.location.request();
    }
    if (ph.isPermanentlyDenied) {
      Get.snackbar('Location needed', 'Enable location permission in Settings to record your route.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    if (!ph.isGranted) {
      Get.snackbar('Permission denied', 'Location permission is required to record.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    await _gpsPositionSub?.cancel();
    _gpsPositionSub = null;

    const settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);

    _gpsPositionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        onLocationUpdate(LatLng(position.latitude, position.longitude));
      },
      onError: (_) {
        Get.snackbar('GPS error', 'Location update failed. Please try again.', snackPosition: SnackPosition.BOTTOM);
      },
    );
    return true;
  }

  /// Stops the live GPS position stream (e.g. pause). Does not end the track session.
  Future<void> pauseGps() async {
    await _gpsPositionSub?.cancel();
    _gpsPositionSub = null;
  }

  /// Restarts the live GPS stream after [pauseGps] (non-testing live session only).
  Future<void> resumeGps() async {
    if (!isRecording.value || liveTrackId.value.isEmpty || liveTestingMode.value) {
      return;
    }
    await startGpsTracking();
  }

  /// Appends a point to the path, updates stats, emits `location_update` to the server.
  void onLocationUpdate(LatLng point) {
    if (pathPoints.isNotEmpty) {
      final last = pathPoints.last;
      final delta = Geolocator.distanceBetween(last.latitude, last.longitude, point.latitude, point.longitude);
      recordingDistance.value += delta;
      _updateStepsAndCalories();
    }

    pathPoints.add(point);
    recordingPath.add(point);
    currentLocation.value = point;

    final tid = liveTrackId.value;
    if (tid.isEmpty) return;

    // Persist to Hive — sync service pushes unsynced points via HTTP every 3 s.
    _livePointSeq++;
    final pid = '${tid}_p$_livePointSeq';
    final localPoint = TrackPointLocal(id: pid, trackSessionId: tid, latitude: point.latitude, longitude: point.longitude, altitude: 0, speed: 0, timestamp: DateTime.now());
    _local.saveTrackPoint(localPoint);
    pendingPointsCount.value = _local.getUnsyncedPoints(tid).length;
  }

  /// Testing mode: simulate GPS by tapping the map.
  void onMapTap(LatLng point) {
    if (!liveTestingMode.value || !isRecording.value) return;
    onLocationUpdate(point);
  }

  /// Uploads images, emits `add_flag`, and appends [liveFlags] for immediate map feedback.
  ///
  /// Returns `true` if the flag was sent; `false` if validation failed or an error occurred
  /// (snackbar already shown).
  Future<bool> addFlag(AddFlagData flagData) async {
    final tid = liveTrackId.value;
    if (tid.isEmpty) {
      Get.snackbar('Track', 'No active track session.', snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    try {
      final imageUrls = <String>[];
      for (final file in flagData.images) {
        imageUrls.add(await _imageUpload.uploadTrackFlagImage(tid, file));
      }

      final lat = flagData.coordinate.latitude;
      final lng = flagData.coordinate.longitude;

      _ensureSocketConnected();
      final s = _socket;
      if (s == null) {
        throw Exception('Could not connect to the server. Try again.');
      }

      void emit() {
        s.emit('add_flag', <String, dynamic>{
          'trackId': tid,
          'flag': <String, dynamic>{
            'type': flagData.type,
            'description': flagData.description,
            'images': imageUrls,
            'location': <String, double>{'lng': lng, 'lat': lat},
          },
        });
      }

      if (s.connected) {
        emit();
      } else {
        s.once('connect', (_) => emit());
      }

      liveFlags.add(LiveTrackFlag(type: flagData.type, description: flagData.description.isEmpty ? null : flagData.description, images: imageUrls, lat: lat, lng: lng));

      Get.snackbar('Flag added', 'Your flag was saved to this track.', snackPosition: SnackPosition.BOTTOM);
      return true;
    } catch (e) {
      Get.snackbar('Could not add flag', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }

  Future<void> _resetLiveSession({required bool clearDraftId}) async {
    _trackSync.stopSync();
    _durationTimer?.cancel();
    _durationTimer = null;
    await _gpsPositionSub?.cancel();
    _gpsPositionSub = null;
    await _positionSub?.cancel();
    _positionSub = null;
    isRecording.value = false;
    pathPoints.clear();
    recordingPath.clear();
    recordingDistance.value = 0;
    recordingDuration.value = 0;
    recordingSteps.value = 0;
    recordingCalories.value = 0;
    currentLocation.value = null;
    liveTrackName.value = '';
    liveTestingMode.value = false;
    if (clearDraftId) {
      liveTrackId.value = '';
    }
    liveFlags.clear();
    activeSessionId.value = '';
    pendingPointsCount.value = 0;
    _disconnectSocket();
  }

  /// Ends live recording: emits `end_track`, tears down GPS/socket, pops the live map.
  Future<void> endTrack() async {
    final tid = liveTrackId.value;
    if (tid.isEmpty) return;

    final end = currentLocation.value ?? (pathPoints.isNotEmpty ? pathPoints.last : null);
    if (end == null) {
      Get.snackbar('No location', 'Add at least one point before ending the track.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Flush all remaining offline points to the server before finalizing.
    await _trackSync.forceSync(tid);
    _trackSync.stopSync();

    // Mark Hive session complete and clean up synced rows.
    final session = _local.getSession(tid);
    if (session != null) {
      session.isCompleted = true;
      session.totalPoints = pathPoints.length;
      session.distance = recordingDistance.value;
      session.steps = recordingSteps.value;
      session.calories = recordingCalories.value;
      session.duration = recordingDuration.value;
      _local.updateSession(session);
    }
    _local.clearSyncedPoints(tid);

    try {
      _socket?.emit('end_track', <String, dynamic>{
        'trackId': tid,
        'endPoint': <String, double>{'lng': end.longitude, 'lat': end.latitude},
        'distance': recordingDistance.value.round(),
        'duration': recordingDuration.value,
        'steps': recordingSteps.value,
        'calories': recordingCalories.value,
      });
    } catch (_) {
      Get.snackbar('Error', 'Could not finish track. Please try again.', snackPosition: SnackPosition.BOTTOM);
    }

    await _resetLiveSession(clearDraftId: true);
    Get.until((route) => route.settings.name == AppRoutes.home);
    Get.find<NavigationController>().changePage(NavigationController.tabTrack);
    await fetchMyTracks();
  }

  Future<void> startRecording() async {
    if (isRecording.value) return;
    if (liveTrackId.value.isNotEmpty) {
      return;
    }

    final auth = Get.find<AuthController>();
    final uid = auth.user.value?.id;
    if (uid == null || uid.isEmpty) {
      Get.snackbar('Sign in required', 'Please sign in to record a track.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final ok = await _ensureLocationPermission();
    if (!ok) return;

    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    activeSessionId.value = sessionId;
    pendingPointsCount.value = 0;
    _legacyPointSeq = 0;

    recordingPath.clear();
    pathPoints.clear();
    recordingDistance.value = 0;
    recordingDuration.value = 0;
    recordingSteps.value = 0;
    recordingCalories.value = 0;
    currentLocation.value = null;

    final session = TrackSessionLocal(sessionId: sessionId, startedAt: DateTime.now());
    _local.saveSession(session);

    await _tryCreateServerTrackForSession(sessionId);
    _trackSync.startSync(sessionId);

    isRecording.value = true;

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isRecording.value) {
        recordingDuration.value++;
      }
    });

    const settings = LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5);

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        final point = LatLng(position.latitude, position.longitude);
        if (recordingPath.isNotEmpty) {
          final last = recordingPath.last;
          final delta = Geolocator.distanceBetween(last.latitude, last.longitude, point.latitude, point.longitude);
          recordingDistance.value += delta;
          _updateStepsAndCalories();
        }
        recordingPath.add(point);
        pathPoints.add(point);
        currentLocation.value = point;

        _legacyPointSeq++;
        final pid = '${sessionId}_p$_legacyPointSeq';
        final localPoint = TrackPointLocal(id: pid, trackSessionId: sessionId, latitude: position.latitude, longitude: position.longitude, altitude: position.altitude.isFinite ? position.altitude : 0, speed: position.speed.isFinite ? position.speed : 0, timestamp: position.timestamp);
        _local.saveTrackPoint(localPoint);
        pendingPointsCount.value = _local.getUnsyncedPoints(sessionId).length;
      },
      onError: (Object e) {
        Get.snackbar('GPS error', 'Location update failed. Please try again.', snackPosition: SnackPosition.BOTTOM);
      },
    );
  }

  Future<void> _stopRecordingCore() async {
    _durationTimer?.cancel();
    _durationTimer = null;
    await _positionSub?.cancel();
    _positionSub = null;
    isRecording.value = false;
  }

  void _discardLegacyRecordingAfterSave() {
    recordingPath.clear();
    pathPoints.clear();
    recordingDistance.value = 0;
    recordingDuration.value = 0;
    recordingSteps.value = 0;
    recordingCalories.value = 0;
    currentLocation.value = null;
    activeSessionId.value = '';
    pendingPointsCount.value = 0;
  }

  /// Stops GPS and timer. For live sessions, use [endTrack] instead.
  Future<void> stopRecording() async {
    if (liveTrackId.value.isNotEmpty) {
      await endTrack();
      return;
    }
    if (!isRecording.value) return;

    final sid = activeSessionId.value;
    await _stopRecordingCore();

    if (recordingPath.isEmpty) {
      Get.snackbar('No path', 'No GPS points were recorded.', snackPosition: SnackPosition.BOTTOM);
      if (sid.isNotEmpty) {
        _local.deleteSession(sid);
        activeSessionId.value = '';
        pendingPointsCount.value = 0;
      }
      _trackSync.stopSync();
      return;
    }

    if (sid.isNotEmpty) {
      await _trackSync.forceSync(sid);
      _trackSync.stopSync();

      final s = _local.getSession(sid);
      if (s != null) {
        s.isCompleted = true;
        s.totalPoints = recordingPath.length;
        s.distance = recordingDistance.value;
        s.steps = recordingSteps.value;
        s.calories = recordingCalories.value;
        s.duration = recordingDuration.value;
        _local.updateSession(s);
      }
      pendingPointsCount.value = _local.getUnsyncedPoints(sid).length;
    }

    _showRecordingCompleteSheet();
  }

  void _showRecordingCompleteSheet() {
    final titleCtrl = TextEditingController(text: 'My track');
    final descCtrl = TextEditingController();
    var trackType = 'hiking';
    var difficulty = 'moderate';

    const types = <String>['hiking', 'offroad', 'cycling', 'running'];
    const diffs = <String>['easy', 'moderate', 'hard'];

    Get.bottomSheet<void>(
      StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Save track', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: trackType,
                          isExpanded: true,
                          items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setSheetState(() => trackType = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Difficulty', border: OutlineInputBorder()),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: difficulty,
                          isExpanded: true,
                          items: diffs.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setSheetState(() => difficulty = v);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: () async {
                        await saveRecordedTrack(titleCtrl.text.trim(), descCtrl.text.trim(), trackType, difficulty);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      isScrollControlled: true,
    ).then((_) {
      titleCtrl.dispose();
      descCtrl.dispose();
    });
  }

  Future<void> saveRecordedTrack(String title, String description, String type, String difficulty) async {
    if (recordingPath.isEmpty) {
      Get.snackbar('Nothing to save', 'Record a route before saving.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      Get.snackbar('Title required', 'Enter a title for your track.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final sid = activeSessionId.value;
    if (sid.isEmpty) {
      Get.snackbar('No session', 'Nothing to save.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    await _tryCreateServerTrackForSession(sid);
    var session = _local.getSession(sid);
    var trackId = session?.serverTrackId ?? '';
    if (trackId.isEmpty) {
      Get.snackbar('Offline', 'Could not create the track on the server yet. Go online and tap Save again.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    isLoading.value = true;
    try {
      final completed = await _repository.completeTrack(trackId, <String, dynamic>{
        'title': trimmedTitle,
        'description': description,
        'type': type,
        'difficulty': difficulty,
        'distance': recordingDistance.value.round(),
        'duration': recordingDuration.value,
        'steps': recordingSteps.value,
        'calories': recordingCalories.value,
      });
      myTracks.insert(0, completed);
      _local.clearSyncedPoints(sid);
      session = _local.getSession(sid);
      if (session != null) {
        session.isSynced = true;
        _local.updateSession(session);
      }
      _discardLegacyRecordingAfterSave();
      if (Get.isBottomSheetOpen == true) {
        Get.back<void>();
      }
      Get.snackbar('Saved', 'Track saved successfully.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.dialog<void>(
        AlertDialog(
          title: const Text('Could not save'),
          content: Text(_friendlyMessage(e)),
          actions: [
            TextButton(onPressed: Get.back<void>, child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                Get.back<void>();
                unawaited(saveRecordedTrack(trimmedTitle, description, type, difficulty));
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(String id) async {
    try {
      final updated = await _repository.likeTrack(id);
      _applyTrackUpdate(updated);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> toggleSave(String id) async {
    try {
      final updated = await _repository.saveTrack(id);
      _applyTrackUpdate(updated);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> uploadTrackPhoto(XFile imageFile) async {
    try {
      final id = selectedTrack.value?.id;
      if (id == null || id.isEmpty) {
        Get.snackbar('Error', 'No track selected.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final track = await _repository.uploadTrackPhoto(id, imageFile);
      _applyTrackUpdate(track);
      Get.snackbar('Photo added', 'Your photo was added to the track.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteTrackPhoto(int photoIndex) async {
    try {
      final id = selectedTrack.value?.id;
      if (id == null || id.isEmpty) {
        Get.snackbar('Error', 'No track selected.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final track = await _repository.deleteTrackPhoto(id, photoIndex);
      _applyTrackUpdate(track);
      Get.snackbar('Photo removed', 'The photo was removed from the track.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Map<String, dynamic> _flagApiPayload(AddFlagData data, List<String> imageUrls) {
    return <String, dynamic>{
      'type': data.type,
      'description': data.description,
      'location': <String, double>{'lng': data.coordinate.longitude, 'lat': data.coordinate.latitude},
      'images': imageUrls,
    };
  }

  Future<void> addFlagToTrack(AddFlagData data) async {
    try {
      final id = selectedTrack.value?.id;
      if (id == null || id.isEmpty) {
        Get.snackbar('Error', 'No track selected.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final urls = <String>[...data.existingImageUrls];
      for (final f in data.images) {
        urls.add(await _repository.uploadTrackFlagImage(id, f));
      }
      final track = await _repository.postTrackFlag(id, _flagApiPayload(data, urls));
      _applyTrackUpdate(track);
      Get.snackbar('Flag added', 'Your flag was saved to this track.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> editFlag(String flagId, AddFlagData data) async {
    try {
      final id = selectedTrack.value?.id;
      if (id == null || id.isEmpty || flagId.isEmpty) {
        Get.snackbar('Error', 'No track selected.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final urls = <String>[...data.existingImageUrls];
      for (final f in data.images) {
        urls.add(await _repository.uploadTrackFlagImage(id, f));
      }
      final track = await _repository.putTrackFlag(id, flagId, _flagApiPayload(data, urls));
      _applyTrackUpdate(track);
      Get.snackbar('Flag updated', 'Your changes were saved.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteFlag(String flagId) async {
    try {
      final id = selectedTrack.value?.id;
      if (id == null || id.isEmpty || flagId.isEmpty) {
        Get.snackbar('Error', 'No track selected.', snackPosition: SnackPosition.BOTTOM);
        return;
      }
      final track = await _repository.deleteTrackFlag(id, flagId);
      _applyTrackUpdate(track);
      Get.snackbar('Flag removed', 'The flag was removed from this track.', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _friendlyMessage(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _durationTimer?.cancel();
    _gpsPositionSub?.cancel();
    _positionSub?.cancel();
    _disconnectSocket();
    super.onClose();
  }
}
