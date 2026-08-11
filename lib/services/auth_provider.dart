import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

/// Persists the auth token and current user in SharedPreferences.
/// Use [AuthProvider.instance] to access it globally.
class AuthProvider {
  static final AuthProvider _instance = AuthProvider._();
  static AuthProvider get instance => _instance;
  AuthProvider._();

  static const _keyToken = 'auth_token';
  static const _keyName = 'user_name_field';
  static const _keyUserName = 'user_user_name';
  static const _keyGmail = 'user_gmail';
  static const _keyPhone = 'user_phone';
  static const _keyUserType = 'user_type';
  static const _keyUserId = 'user_id';

  String? _token;
  UserModel? _user;

  String? get token => _token;
  UserModel? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty;

  // ── Init from disk ─────────────────────────────────────────────────────────
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);
    final id = prefs.getInt(_keyUserId);
    if (_token != null && id != null) {
      _user = UserModel(
        id: id,
        name: prefs.getString(_keyName) ?? '',
        userName: prefs.getString(_keyUserName) ?? '',
        gmail: prefs.getString(_keyGmail) ?? '',
        phoneNo: prefs.getString(_keyPhone),
        userType: prefs.getString(_keyUserType) ?? 'user',
      );
    }
  }

  // ── Persist after login / register ────────────────────────────────────────
  Future<void> saveSession(String token, UserModel user) async {
    _token = token;
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setInt(_keyUserId, user.id);
    await prefs.setString(_keyName, user.name);
    await prefs.setString(_keyUserName, user.userName);
    await prefs.setString(_keyGmail, user.gmail);
    if (user.phoneNo != null) await prefs.setString(_keyPhone, user.phoneNo!);
    await prefs.setString(_keyUserType, user.userType);
  }

  // ── Clear on logout ────────────────────────────────────────────────────────
  Future<void> clearSession() async {
    _token = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyName);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyGmail);
    await prefs.remove(_keyPhone);
    await prefs.remove(_keyUserType);
  }

  /// Call API logout then wipe local session.
  Future<void> logout() async {
    if (_token != null) {
      try {
        await AuthService.logout(_token!);
      } catch (_) {
        // Ignore network errors on logout; clear locally anyway.
      }
    }
    await clearSession();
  }
}
