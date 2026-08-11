import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/study_class_model.dart';
import 'auth_service.dart';

class ClassService {
  /// GET /api/classes
  /// Returns list of all study classes ordered by sort_order.
  static Future<List<StudyClassModel>> fetchClasses({required String token}) async {
    final response = await http
        .get(
          Uri.parse(ApiConfig.classes),
          headers: ApiConfig.authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List<dynamic>)
          .map((e) => StudyClassModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw ApiException('Failed to load study classes (${response.statusCode})');
  }

  /// GET /api/classes/{id}
  /// Returns a single study class with all its assigned materials (ordered by sort_order).
  static Future<StudyClassModel> fetchClassDetail({
    required String token,
    required int id,
  }) async {
    final response = await http
        .get(
          Uri.parse(ApiConfig.classDetail(id)),
          headers: ApiConfig.authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return StudyClassModel.fromJson(data['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to load class detail (${response.statusCode})');
  }
}
