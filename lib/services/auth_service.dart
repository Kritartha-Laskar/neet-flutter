import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  // ── Register ───────────────────────────────────────────────────────────────
  /// Returns {'user': UserModel, 'token': String} on success.
  /// Throws [ApiException] on failure.
  static Future<Map<String, dynamic>> register({
    required String name,
    required String userName,
    required String gmail,
    String? phoneNo,
    required String password,
    required String passwordConfirmation,
  }) async {
    final body = {
      'name': name,
      'user_name': userName,
      'gmail': gmail,
      if (phoneNo != null && phoneNo.isNotEmpty) 'phone_no': phoneNo,
      'password': password,
      'password_confirmation': passwordConfirmation,
    };

    final response = await http
        .post(
          Uri.parse(ApiConfig.register),
          headers: ApiConfig.defaultHeaders,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 201 && data['success'] == true) {
      return {
        'user': UserModel.fromJson(data['data']['user'] as Map<String, dynamic>),
        'token': data['data']['token'] as String,
      };
    }
    throw ApiException(_extractMessage(data, response.statusCode));
  }

  // ── Login ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse(ApiConfig.login),
          headers: ApiConfig.defaultHeaders,
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return {
        'user': UserModel.fromJson(data['data']['user'] as Map<String, dynamic>),
        'token': data['data']['token'] as String,
      };
    }
    throw ApiException(_extractMessage(data, response.statusCode));
  }

  // ── Logout ─────────────────────────────────────────────────────────────────
  static Future<void> logout(String token) async {
    await http
        .post(
          Uri.parse(ApiConfig.logout),
          headers: ApiConfig.authHeaders(token),
        )
        .timeout(const Duration(seconds: 10));
  }

  // ── Me ─────────────────────────────────────────────────────────────────────
  static Future<UserModel> me(String token) async {
    final response = await http
        .get(
          Uri.parse(ApiConfig.me),
          headers: ApiConfig.authHeaders(token),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return UserModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw ApiException(_extractMessage(data, response.statusCode));
  }

  // ── Change Password ────────────────────────────────────────────────────────
  static Future<void> changePassword({
    required String token,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final body = {
      'current_password': currentPassword,
      'new_password': newPassword,
      'new_password_confirmation': confirmPassword,
    };

    final response = await http
        .post(
          Uri.parse(ApiConfig.changePassword),
          headers: ApiConfig.authHeaders(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }
    throw ApiException(_extractMessage(data, response.statusCode));
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  static String _extractMessage(Map<String, dynamic> data, int statusCode) {
    if (data['message'] != null) return data['message'].toString();
    if (data['errors'] != null) {
      final errors = data['errors'] as Map<String, dynamic>;
      return errors.values.first is List
          ? (errors.values.first as List).first.toString()
          : errors.values.first.toString();
    }
    return 'Server error ($statusCode)';
  }
}

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);

  @override
  String toString() => message;
}
