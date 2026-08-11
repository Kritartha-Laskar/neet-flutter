// ─────────────────────────────────────────────────────────────────────────────
// API Configuration
// ─────────────────────────────────────────────────────────────────────────────
// • For Android emulator  → 10.0.2.2  (maps to host's localhost)
// • For iOS simulator     → 127.0.0.1
// • For physical devices  → your machine's local IP, e.g. 192.168.1.x
// ─────────────────────────────────────────────────────────────────────────────

class ApiConfig {
  ApiConfig._(); // non-instantiable

  /// For php artisan serve, use '127.0.0.1' or 'localhost' and port '8000'.
  static const String _host = '127.0.0.1'; 
  static const String _port = '8000'; 

  // For php artisan serve, the URL structure is http://host:port/api
  static String get baseUrl => 'http://$_host:$_port/api';

  // ── Endpoints ─────────────────────────────────────────────────────────────
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get logout => '$baseUrl/auth/logout';
  static String get me => '$baseUrl/auth/me';
  static String get questionPapers => '$baseUrl/question-papers';
  static String questionPaperDetail(int id) => '$baseUrl/question-papers/$id';
  static String get classes => '$baseUrl/classes';
  static String classDetail(int id) => '$baseUrl/classes/$id';
  static String get resources => '$baseUrl/resources';
  static String resourceDetail(int id) => '$baseUrl/resources/$id';

  /// Helper to convert relative file path/URL to absolute backend URL
  static String formatUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path.replaceAll('http://localhost:8000', 'http://$_host:$_port');
    }
    final String cleanPath = path.startsWith('/') ? path : '/$path';
    return 'http://$_host:$_port$cleanPath';
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
