import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart' as ll;

import '../../../core/services/socket_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../data/models/group_model.dart';
import '../data/models/live_session_model.dart';
import '../data/repositories/group_repository.dart';

class GroupController extends GetxController {
  GroupController(this._repository);

  final GroupRepository _repository;

  // ── Observables ──

  final RxList<GroupModel> myGroups = <GroupModel>[].obs;
  final Rxn<GroupModel> selectedGroup = Rxn<GroupModel>();
  final Rxn<LiveSessionModel> liveSession = Rxn<LiveSessionModel>();
  final RxList<LiveSessionModel> groupLiveSessions = <LiveSessionModel>[].obs;
  final RxMap<String, MemberSession> memberLocations =
      <String, MemberSession>{}.obs;
  final RxBool isTracking = false.obs;
  final RxBool isLoading = false.obs;
  final RxString liveSessionId = ''.obs;
  final Rxn<ll.LatLng> currentPosition = Rxn<ll.LatLng>();

  StreamSubscription<Position>? _gpsSub;

  String _cleanError(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');

  // ── API Methods ──

  Future<void> fetchMyGroups() async {
    isLoading.value = true;
    try {
      final data = await _repository.getMyGroups();
      myGroups.value =
          data.map((e) => GroupModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      Get.snackbar('Error', _cleanError(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> createGroup(String name, String description) async {
    isLoading.value = true;
    try {
      final data = await _repository.createGroup(
          name: name, description: description);
      final group = GroupModel.fromJson(data);
      myGroups.add(group);
      Get.snackbar(
        'Group Created',
        'Invite code: ${group.inviteCode}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    } catch (e) {
      Get.snackbar('Error', _cleanError(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinGroup(String inviteCode) async {
    isLoading.value = true;
    try {
      final data = await _repository.joinGroup(inviteCode);
      final group = GroupModel.fromJson(data);
      final idx = myGroups.indexWhere((g) => g.id == group.id);
      if (idx >= 0) {
        myGroups[idx] = group;
      } else {
        myGroups.add(group);
      }
      Get.snackbar(
        'Success',
        'Joined group successfully!',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('Error', _cleanError(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  // ── Tracking ──

  Future<bool> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar('Location off', 'Turn on location services',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      Get.snackbar('Permission denied', 'Location permission is required',
          snackPosition: SnackPosition.BOTTOM);
      return false;
    }
    return true;
  }

  Future<void> startGroupTracking(String groupId) async {
    isLoading.value = true;
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        isLoading.value = false;
        return;
      }

      final data = await _repository.startGroupTracking(groupId);
      final sessionId = data['liveSessionId']?.toString() ?? '';
      liveSessionId.value = sessionId;

      if (data['group'] != null) {
        final group =
            GroupModel.fromJson(Map<String, dynamic>.from(data['group'] as Map));
        selectedGroup.value = group;
        final idx = myGroups.indexWhere((g) => g.id == group.id);
        if (idx >= 0) myGroups[idx] = group;
      }

      final socket = Get.find<SocketService>();
      socket.joinGroupRoom(groupId, sessionId);
      _bindGroupSocketListeners(socket);
      _startGpsStream(groupId, sessionId, socket);

      isTracking.value = true;
      await fetchGroupLiveSessions(groupId);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> joinExistingLiveSession(
    String groupId, {
    String? preferredSessionId,
  }) async {
    isLoading.value = true;
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        isLoading.value = false;
        return;
      }

      await fetchGroupLiveSessions(groupId);

      String targetSessionId = '';
      if (preferredSessionId != null && preferredSessionId.isNotEmpty) {
        targetSessionId = preferredSessionId;
      } else {
        for (final s in groupLiveSessions) {
          if (s.isActive) {
            targetSessionId = s.id;
            break;
          }
        }
      }

      if (targetSessionId.isEmpty) {
        Get.snackbar('No active session', 'There is no active live session to join.',
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      liveSessionId.value = targetSessionId;
      final selected = groupLiveSessions.firstWhereOrNull((s) => s.id == targetSessionId);
      if (selected != null) {
        liveSession.value = selected;
      }

      final socket = Get.find<SocketService>();
      socket.joinGroupRoom(groupId, targetSessionId);
      _bindGroupSocketListeners(socket);
      _startGpsStream(groupId, targetSessionId, socket);

      isTracking.value = true;
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  void _bindGroupSocketListeners(SocketService socket) {
    socket.offAllGroupListeners();

    socket.onMemberLocation((data) {
      final incomingSessionId = data['liveSessionId']?.toString();
      final currentSessionId = liveSessionId.value;
      if (incomingSessionId != null &&
          incomingSessionId.isNotEmpty &&
          currentSessionId.isNotEmpty &&
          incomingSessionId != currentSessionId) {
        // Ignore updates from a different session while user is viewing history.
        return;
      }
      final userId = data['userId']?.toString() ?? '';
      if (userId.isEmpty) return;
      final existing = memberLocations[userId];
      final newPath = existing?.locationPath.toList() ?? <ll.LatLng>[];
      final lat = (data['latitude'] as num?)?.toDouble();
      final lng = (data['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        newPath.add(ll.LatLng(lat, lng));
      }
      memberLocations[userId] = MemberSession(
        userId: userId,
        name: data['name']?.toString() ?? existing?.name ?? '',
        shortName: data['shortName']?.toString() ?? existing?.shortName ?? '',
        profileImage: data['profileImage']?.toString() ?? existing?.profileImage,
        lastLatitude: lat ?? existing?.lastLatitude,
        lastLongitude: lng ?? existing?.lastLongitude,
        lastSeenAt: DateTime.now(),
        isOnline: true,
        locationPath: newPath,
        totalDistance: existing?.totalDistance ?? 0,
      );
    });

    socket.onMemberJoined((data) {
      final userId = data['userId']?.toString() ?? '';
      final name = data['name']?.toString() ?? '';
      if (userId.isNotEmpty) {
        memberLocations[userId] = MemberSession(
          userId: userId,
          name: name,
          profileImage: data['profileImage']?.toString(),
          shortName: name.split(' ').first,
          isOnline: true,
        );
      }
      Get.snackbar('Member Joined', '$name joined',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    });

    socket.onMemberLeft((data) {
      final userId = data['userId']?.toString() ?? '';
      final name = data['name']?.toString() ?? '';
      final existing = memberLocations[userId];
      if (existing != null) {
        memberLocations[userId] = existing.copyWith(isOnline: false);
      }
      Get.snackbar('Member Left', '$name left',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2));
    });

    socket.onEmergencyAlert((data) {
      final name = data['name']?.toString() ?? 'A member';
      final lat = data['latitude'];
      final lng = data['longitude'];
      Get.dialog(
        AlertDialog(
          title: const Text('EMERGENCY SOS'),
          content:
              Text('$name triggered an emergency alert!\n\nLocation: $lat, $lng'),
          actions: [
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK'),
            ),
          ],
        ),
        barrierDismissible: false,
      );
    });
  }

  void _startGpsStream(String groupId, String sessionId, SocketService socket) {
    unawaited(_gpsSub?.cancel() ?? Future<void>.value());
    _gpsSub = null;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    _gpsSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        currentPosition.value = ll.LatLng(position.latitude, position.longitude);
        _upsertSelfLocation(position.latitude, position.longitude);
        socket.sendLocationUpdate(
          groupId,
          sessionId,
          position.latitude,
          position.longitude,
        );
        // Reliable DB persistence fallback even if socket delivery lags/fails.
        unawaited(
          _repository.updateMemberLocation(
            groupId: groupId,
            liveSessionId: sessionId,
            latitude: position.latitude,
            longitude: position.longitude,
          ).catchError((_) {}),
        );
      },
      onError: (_) {
        Get.snackbar('GPS error', 'Location update failed',
            snackPosition: SnackPosition.BOTTOM);
      },
    );
  }

  Future<void> fetchGroupLiveSessions(String groupId) async {
    if (groupId.isEmpty) return;
    try {
      final data = await _repository.getGroupLiveSessions(groupId);
      groupLiveSessions.value = data
          .map((e) => LiveSessionModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      LiveSessionModel? active;
      for (final s in groupLiveSessions) {
        if (s.isActive) {
          active = s;
          break;
        }
      }
      if (active != null) {
        if (liveSessionId.value.isEmpty) {
          liveSessionId.value = active.id;
          selectSessionForMap(active.id);
        } else {
          final exists =
              groupLiveSessions.any((s) => s.id == liveSessionId.value);
          if (!exists) {
            liveSessionId.value = active.id;
            selectSessionForMap(active.id);
          } else {
            selectSessionForMap(liveSessionId.value);
          }
        }
      }
    } catch (e) {
      Get.snackbar('Error', _cleanError(e), snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Load any session (active or ended) into map layers.
  void selectSessionForMap(String sessionId) {
    final selected = groupLiveSessions.firstWhereOrNull((s) => s.id == sessionId);
    if (selected == null) return;
    liveSession.value = selected;
    liveSessionId.value = selected.id;

    final hydrated = <String, MemberSession>{};
    for (final m in selected.memberSessions) {
      if (m.userId.isEmpty) continue;
      hydrated[m.userId] = m;
    }
    memberLocations.assignAll(hydrated);
  }

  Future<void> stopGroupTracking(String groupId) async {
    isLoading.value = true;
    try {
      await _repository.stopGroupTracking(groupId);

      final socket = Get.find<SocketService>();
      socket.leaveGroupRoom(groupId, liveSessionId.value);
      socket.offAllGroupListeners();

      await _gpsSub?.cancel();
      _gpsSub = null;

      memberLocations.clear();
      groupLiveSessions.clear();
      liveSession.value = null;
      liveSessionId.value = '';
      isTracking.value = false;
    } catch (e) {
      Get.snackbar('Error', _cleanError(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  /// Simulate a GPS position from a map tap (for testing on emulators).
  void simulatePosition(double lat, double lng) {
    currentPosition.value = ll.LatLng(lat, lng);
    _upsertSelfLocation(lat, lng);
    final groupId = selectedGroup.value?.id;
    final sessionId = liveSessionId.value;
    if (groupId != null && sessionId.isNotEmpty) {
      Get.find<SocketService>().sendLocationUpdate(
          groupId, sessionId, lat, lng);
      unawaited(
        _repository.updateMemberLocation(
          groupId: groupId,
          liveSessionId: sessionId,
          latitude: lat,
          longitude: lng,
        ).catchError((_) {}),
      );
    }
  }

  void _upsertSelfLocation(double lat, double lng) {
    if (!Get.isRegistered<AuthController>()) return;
    final auth = Get.find<AuthController>();
    final uid = auth.user.value?.id;
    if (uid == null || uid.isEmpty) return;
    final existing = memberLocations[uid];
    final path = existing?.locationPath.toList() ?? <ll.LatLng>[];
    path.add(ll.LatLng(lat, lng));
    final name = auth.user.value?.name ?? existing?.name ?? 'You';
    memberLocations[uid] = MemberSession(
      userId: uid,
      name: name,
      shortName: name.split(' ').first,
      profileImage: auth.user.value?.profileImage ?? existing?.profileImage,
      lastLatitude: lat,
      lastLongitude: lng,
      lastSeenAt: DateTime.now(),
      isOnline: true,
      locationPath: path,
      totalDistance: existing?.totalDistance ?? 0,
    );
  }

  Future<void> leaveGroup(String groupId) async {
    isLoading.value = true;
    try {
      await _repository.leaveGroup(groupId);
      myGroups.removeWhere((g) => g.id == groupId);
      selectedGroup.value = null;
      Get.snackbar('Success', 'Left group successfully',
          snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', _cleanError(e),
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendSOS() async {
    try {
      final groupId = selectedGroup.value?.id;
      if (groupId == null) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      Get.find<SocketService>()
          .sendSOS(groupId, position.latitude, position.longitude);
    } catch (e) {
      Get.snackbar('Error', 'Could not send SOS',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void onClose() {
    _gpsSub?.cancel();
    super.onClose();
  }
}
