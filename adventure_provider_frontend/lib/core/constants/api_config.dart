import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Base URL for the backend API.
///
/// - **Android emulator**: `10.0.2.2` (emulator's alias for host machine's localhost).
/// - **iOS simulator**: `127.0.0.1`.
/// - **Real device**: set [baseUrlOverride] to your PC's LAN IP (e.g. `http://192.168.1.5:9090/api`)
///   so the phone can reach the backend on your computer.
class ApiConfig {
  ApiConfig._();

  /// Override when testing on a **real device**. Set to your PC's IP, e.g. `http://192.168.1.5:9090/api`.
  /// Leave null for emulator/simulator.
  static const String? baseUrlOverride = 'http://192.168.1.101:9090/api';

  static const int _port = 9090;
  static const String _path = '/api';

  /// Loopback to the machine running Metro/backend (emulator / simulator only).
  static String get _loopbackHost {
    if (kIsWeb) return '127.0.0.1';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '10.0.2.2';
    }
    return '127.0.0.1';
  }

  static String get baseUrl {
    if (baseUrlOverride != null && baseUrlOverride!.isNotEmpty) {
      final url = baseUrlOverride!;
      return url.endsWith('/') ? url : url;
    }
    return 'http://$_loopbackHost:$_port$_path';
  }

  /// Server origin for static files (no `/api`). Uploads are served at `[origin]/uploads/...`.
  static String get serverOrigin {
    if (baseUrlOverride != null && baseUrlOverride!.isNotEmpty) {
      final raw = baseUrlOverride!.trim();
      final uri = Uri.parse(raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw);
      return uri.origin;
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
