import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../constants/api_config.dart';

class SocketService {
  io.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    // Dispose any existing socket before creating a new one
    _socket?.dispose();

    final url = '${ApiConfig.serverOrigin}/group';
    debugPrint('[SocketService] connecting to $url');

    _socket = io.io(
      url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .enableForceNew()
          .build(),
    );

    _socket!.onConnect((_) => debugPrint('[SocketService] connected'));
    _socket!.onDisconnect((_) => debugPrint('[SocketService] disconnected'));
    _socket!.onConnectError(
        (err) => debugPrint('[SocketService] connect_error: $err'));

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  // ── Emitters ──

  void joinGroupRoom(String groupId, String liveSessionId) {
    debugPrint('[SocketService] joinGroupRoom groupId=$groupId sessionId=$liveSessionId connected=$isConnected');
    _socket?.emit('join_group_room', {
      'groupId': groupId,
      'liveSessionId': liveSessionId,
    });
  }

  void leaveGroupRoom(String groupId, String liveSessionId) {
    _socket?.emit('leave_group_room', {
      'groupId': groupId,
      'liveSessionId': liveSessionId,
    });
  }

  void sendLocationUpdate(
      String groupId, String liveSessionId, double lat, double lng) {
    debugPrint('[SocketService] sendLocationUpdate lat=$lat lng=$lng connected=$isConnected');
    _socket?.emit('location_update', {
      'groupId': groupId,
      'liveSessionId': liveSessionId,
      'latitude': lat,
      'longitude': lng,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  void sendSOS(String groupId, double lat, double lng) {
    _socket?.emit('emergency_sos', {
      'groupId': groupId,
      'latitude': lat,
      'longitude': lng,
    });
  }

  // ── Listeners ──

  void onMemberLocation(Function(Map<String, dynamic>) callback) {
    _socket?.on('member_location', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onMemberJoined(Function(Map<String, dynamic>) callback) {
    _socket?.on('member_joined', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onMemberLeft(Function(Map<String, dynamic>) callback) {
    _socket?.on('member_left', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void onEmergencyAlert(Function(Map<String, dynamic>) callback) {
    _socket?.on('emergency_alert', (data) {
      callback(Map<String, dynamic>.from(data as Map));
    });
  }

  void offMemberLocation() {
    _socket?.off('member_location');
  }

  void offMemberJoined() {
    _socket?.off('member_joined');
  }

  void offMemberLeft() {
    _socket?.off('member_left');
  }

  void offEmergencyAlert() {
    _socket?.off('emergency_alert');
  }

  void offAllGroupListeners() {
    _socket?.off('member_location');
    _socket?.off('member_joined');
    _socket?.off('member_left');
    _socket?.off('emergency_alert');
  }

  void offAll() {
    _socket?.clearListeners();
  }
}
