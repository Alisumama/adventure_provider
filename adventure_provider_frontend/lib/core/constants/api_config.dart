/// Base URL for the backend API.
///
/// - **Android emulator**: `10.0.2.2` (emulator's alias for host machine's localhost).
/// - **iOS simulator**: `127.0.0.1`.
/// - **Real device**: set [baseUrlOverride] to your PC's LAN IP (e.g. `http://192.168.1.5:5000/api`)
///   so the phone can reach the backend on your computer.
class ApiConfig {
  ApiConfig._();

  /// Override when testing on a **real device**. Set to your PC's IP, e.g. `http://192.168.1.5:5000/api`.
  /// Leave null for emulator/simulator.
  static const String? baseUrlOverride = null;

  static const int _port = 9090;
  // static const int _port = 5000;
  static const String _path = '/api';

  static String get baseUrl {
    if (baseUrlOverride != null && baseUrlOverride!.isNotEmpty) {
      final url = baseUrlOverride!;
      return url.endsWith('/') ? url : url;
    }
    // Android emulator uses 10.0.2.2 to reach host localhost; iOS simulator uses 127.0.0.1
    // final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    final host = '10.0.2.2';
    // final host = '192.168.1.103';
    return 'http://$host:$_port$_path';
  }

  /// Server origin for static files (no `/api`). Uploads are served at `[origin]/uploads/...`.
  static String get serverOrigin {
    if (baseUrlOverride != null && baseUrlOverride!.isNotEmpty) {
      final raw = baseUrlOverride!.trim();
      final uri = Uri.parse(raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw);
      return uri.origin;
    }
    final host = '10.0.2.2';
    // final host = '192.168.1.103';
    return 'http://$host:$_port';
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
