import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:hive/hive.dart';

/// Base URL for the backend API.
///
/// - **Android emulator**: `10.0.2.2` (emulator's alias for host machine's localhost).
/// - **iOS simulator**: `127.0.0.1`.
/// - **Real device**: call [setIpAddress] from the login settings sheet
///   so the phone can reach the backend on your computer.
class ApiConfig {
  ApiConfig._();

  static const String _boxName = 'api_config';
  static const String _ipKey = 'server_ip';
  static const String _ipHistoryKey = 'ip_history';

  /// Default backend IP for real devices (used when no IP is saved yet).
  static const String _defaultIp = '192.168.1.101';

  /// Runtime override set via [setIpAddress]. Loaded from Hive on [init].
  static String? _runtimeIp;

  static const int _port = 9090;
  static const String _path = '/api';

  /// Call once at app startup (before bindings) to restore the saved IP.
  static Future<void> init() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    final saved = box.get(_ipKey) as String?;
    if (saved != null && saved.trim().isNotEmpty) {
      _runtimeIp = saved.trim();
    } else {
      _runtimeIp = _defaultIp;
    }
  }

  /// Persist and apply a new server IP at runtime.
  static Future<void> setIpAddress(String ip) async {
    final trimmed = ip.trim();
    _runtimeIp = trimmed.isEmpty ? null : trimmed;
    final box = Hive.box<dynamic>(_boxName);
    await box.put(_ipKey, trimmed);
    // Save to history
    if (trimmed.isNotEmpty) {
      final history = getIpHistory();
      history.remove(trimmed);
      history.insert(0, trimmed);
      // Keep max 10 entries
      if (history.length > 10) history.removeLast();
      await box.put(_ipHistoryKey, history);
    }
  }

  /// Returns the list of previously used IP addresses.
  static List<String> getIpHistory() {
    final box = Hive.box<dynamic>(_boxName);
    final raw = box.get(_ipHistoryKey);
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  /// Current IP (if set).
  static String? get currentIp => _runtimeIp;

  /// Loopback to the machine running Metro/backend (emulator / simulator only).
  static String get _loopbackHost {
    if (kIsWeb) return '127.0.0.1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  static String get baseUrl {
    if (_runtimeIp != null && _runtimeIp!.isNotEmpty) {
      return 'http://$_runtimeIp:$_port$_path';
    }
    return 'http://$_loopbackHost:$_port$_path';
  }

  /// Server origin for static files (no `/api`). Uploads are served at `[origin]/uploads/...`.
  static String get serverOrigin {
    if (_runtimeIp != null && _runtimeIp!.isNotEmpty) {
      return 'http://$_runtimeIp:$_port';
    }
    return 'http://$_loopbackHost:$_port';
  }

  /// `uploads/profiles/x.jpg` → full URL; legacy absolute URLs are returned as-is.
  static String? resolveMediaUrl(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    final s = stored.trim();
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    final path = s.startsWith('/') ? s.substring(1) : s;
    final origin = serverOrigin.replaceAll(RegExp(r'/+$'), '');
    return '$origin/$path';
  }
}
