// ─────────────────────────────────────────────────────────────────────────────
// API Configuration
// ─────────────────────────────────────────────────────────────────────────────
// • For Android emulator  → 10.0.2.2  (maps to host's localhost)
// • For iOS simulator     → 127.0.0.1
// • For physical devices  → your machine's local IP, e.g. 192.168.1.x
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._(); // non-instantiable

  /// Set to `true` for local server, or `false` for live production server (`168.144.30.253`).
  static const bool useLocalServer = false;

  /// Default local server port (e.g. '8000' for php artisan serve, or '' if using WAMP Apache on port 80)
  static const String _localPort = '8000';

  /// Set to `true` if running on a real physical device over Wi-Fi
  static const bool usePhysicalDevice = false;

  /// Host PC Wi-Fi IP address for physical device debugging
  static const String customDeviceIp = '10.214.208.100';

  /// Live production host & port
  static const String _prodHost = '168.144.30.253';
  static const String _prodPort = '';

  /// Returns appropriate host depending on target platform:
  /// • Android Emulator  → 10.0.2.2
  /// • iOS Simulator / Web / Windows / macOS → 127.0.0.1
  /// • Physical Device   → host PC's Wi-Fi IP (10.214.208.100)
  static String get _localHost {
    if (usePhysicalDevice) return customDeviceIp;
    if (kIsWeb) return '127.0.0.1';
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }

  static String get _host => useLocalServer ? _localHost : _prodHost;
  static String get _port => useLocalServer ? _localPort : _prodPort;

  static String get baseUrl =>
      _port.isEmpty ? 'http://$_host/api' : 'http://$_host:$_port/api';

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';
  static String get changePassword => '$baseUrl/auth/change-password';
  static String get questionPapers => '$baseUrl/question-papers';
  static String questionPaperDetail(int id) => '$baseUrl/question-papers/$id';
  static String get classes => '$baseUrl/classes';
  static String classDetail(int id) => '$baseUrl/classes/$id';
  static String get resources => '$baseUrl/resources';
  static String resourceDetail(int id) => '$baseUrl/resources/$id';

  // ── Exam Endpoints ────────────────────────────────────────────────────────
  static String get examStart => '$baseUrl/exam/start';
  static String get examSaveAnswer => '$baseUrl/exam/save-answer';
  static String get examSubmit => '$baseUrl/exam/submit';
  static String get examAnalytics => '$baseUrl/exam/analytics';
  static String get examHistory => '$baseUrl/exam/history';
  static String examAttemptDetail(int id) => '$baseUrl/exam/attempt/$id';

  /// Helper to convert relative file path/URL to absolute backend URL
  static String formatUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final String hostPort = _port.isEmpty ? _host : '$_host:$_port';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path.replaceAll('http://localhost:8000', 'http://$hostPort');
    }
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return 'http://$hostPort$cleanPath';
  }

  // ── Default headers (no auth) ─────────────────────────────────────────────
  static Map<String, String> get defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Headers with Bearer token for protected routes.
  static Map<String, String> authHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };
}
