import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../data/models/track_model.dart';
import '../data/repositories/track_repository.dart';

class TrackController extends GetxController {
  TrackController(this._repository);

  final TrackRepository _repository;

  final RxList<TrackModel> myTracks = <TrackModel>[].obs;
  final RxList<TrackModel> nearbyTracks = <TrackModel>[].obs;
  final Rxn<TrackModel> selectedTrack = Rxn<TrackModel>();

  final RxBool isLoading = false.obs;
  final RxBool isRecording = false.obs;

  /// Track list filter: `all` | `hiking` | `offroad` | `cycling` | `running`.
  final RxString selectedFilter = 'all'.obs;

  final RxList<LatLng> recordingPath = <LatLng>[].obs;
  final RxDouble recordingDistance = 0.0.obs;
  final RxInt recordingDuration = 0.obs;
  final RxInt recordingSteps = 0.obs;
  final RxInt recordingCalories = 0.obs;

  StreamSubscription<Position>? _positionSub;
  Timer? _durationTimer;

  static const double _avgStepMeters = 0.762;
  static const double _kcalPerMeter = 0.055;

  String _cleanError(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

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
    }
  }

  void _updateStepsAndCalories() {
    recordingSteps.value =
        (recordingDistance.value / _avgStepMeters).floor().clamp(0, 1 << 30);
    recordingCalories.value =
        (recordingDistance.value * _kcalPerMeter).round().clamp(0, 1 << 30);
  }

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location off',
        'Turn on location services to record a track.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission denied',
        'Location permission is required to record.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }
    return true;
  }

  Future<void> fetchMyTracks() async {
    isLoading.value = true;
    try {
      final list = await _repository.getMyTracks();
      myTracks.assignAll(list);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
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
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTrackById(String id) async {
    isLoading.value = true;
    try {
      final track = await _repository.getTrackById(id);
      selectedTrack.value = track;
      _replaceTrackInList(myTracks, track);
      _replaceTrackInList(nearbyTracks, track);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> startRecording() async {
    if (isRecording.value) return;
    final ok = await _ensureLocationPermission();
    if (!ok) return;

    recordingPath.clear();
    recordingDistance.value = 0;
    recordingDuration.value = 0;
    recordingSteps.value = 0;
    recordingCalories.value = 0;

    isRecording.value = true;

    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isRecording.value) {
        recordingDuration.value++;
      }
    });

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        final point = LatLng(position.latitude, position.longitude);
        if (recordingPath.isNotEmpty) {
          final last = recordingPath.last;
          final delta = Geolocator.distanceBetween(
            last.latitude,
            last.longitude,
            point.latitude,
            point.longitude,
          );
          recordingDistance.value += delta;
          _updateStepsAndCalories();
        }
        recordingPath.add(point);
      },
      onError: (Object e) {
        Get.snackbar(
          'GPS error',
          _cleanError(e),
          snackPosition: SnackPosition.BOTTOM,
        );
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

  void _discardRecording() {
    recordingPath.clear();
    recordingDistance.value = 0;
    recordingDuration.value = 0;
    recordingSteps.value = 0;
    recordingCalories.value = 0;
  }

  /// Stops GPS and timer. UI (e.g. [RecordTrackScreen]) should show save flow.
  Future<void> stopRecording() async {
    if (!isRecording.value) return;
    await _stopRecordingCore();

    if (recordingPath.isEmpty) {
      Get.snackbar(
        'No path',
        'No GPS points were recorded.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Map<String, dynamic> _buildCreatePayload({
    required String title,
    required String description,
    required String type,
    required String difficulty,
  }) {
    final path = List<LatLng>.from(recordingPath);
    final start = path.isNotEmpty ? path.first : null;
    final end = path.isNotEmpty ? path.last : null;

    return {
      'title': title,
      'description': description,
      'type': type,
      'difficulty': difficulty,
      'distance': recordingDistance.value.round(),
      'duration': recordingDuration.value,
      'steps': recordingSteps.value,
      'calories': recordingCalories.value,
      'isPublic': true,
      'geoPath': {
        'type': 'LineString',
        'coordinates':
            path.map((p) => [p.longitude, p.latitude]).toList(growable: false),
      },
      if (start != null)
        'startPoint': {
          'type': 'Point',
          'coordinates': [start.longitude, start.latitude],
        },
      if (end != null)
        'endPoint': {
          'type': 'Point',
          'coordinates': [end.longitude, end.latitude],
        },
    };
  }

  Future<void> saveRecordedTrack(
    String title,
    String description,
    String type,
    String difficulty,
  ) async {
    if (recordingPath.isEmpty) {
      Get.snackbar(
        'Nothing to save',
        'Record a route before saving.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    isLoading.value = true;
    try {
      final data = _buildCreatePayload(
        title: title,
        description: description,
        type: type,
        difficulty: difficulty,
      );
      final created = await _repository.createTrack(data);
      myTracks.insert(0, created);
      _discardRecording();
      Get.snackbar(
        'Saved',
        'Track saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(String id) async {
    try {
      final updated = await _repository.likeTrack(id);
      _applyTrackUpdate(updated);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> toggleSave(String id) async {
    try {
      final updated = await _repository.saveTrack(id);
      _applyTrackUpdate(updated);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    _durationTimer?.cancel();
    _positionSub?.cancel();
    super.onClose();
  }
}
