import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/question_paper_model.dart';
import 'auth_service.dart'; // reuse ApiException

class QuestionPaperService {
  // ── GET /api/question-papers ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchList({
    required String token,
    int page = 1,
  }) async {
    final uri =
        Uri.parse(ApiConfig.questionPapers).replace(queryParameters: {'page': '$page'});
    final response = await http
        .get(uri, headers: ApiConfig.authHeaders(token))
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      final papers = (data['data'] as List<dynamic>)
          .map((e) => QuestionPaperModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = data['meta'] as Map<String, dynamic>? ?? {};
      return {
        'papers': papers,
        'current_page': (meta['current_page'] as num? ?? 1).toInt(),
        'last_page': (meta['last_page'] as num? ?? 1).toInt(),
        'total': (meta['total'] as num? ?? 0).toInt(),
      };
    }
    throw ApiException('Failed to load question papers (${response.statusCode})');
  }

  // ── GET /api/question-papers/{id} ─────────────────────────────────────────
  static Future<QuestionPaperDetailModel> fetchDetail({
    required String token,
    required int id,
  }) async {
    final response = await http
        .get(
          Uri.parse(ApiConfig.questionPaperDetail(id)),
          headers: ApiConfig.authHeaders(token),
        )
        .timeout(const Duration(seconds: 15));

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && data['success'] == true) {
      return QuestionPaperDetailModel.fromJson(
          data['data'] as Map<String, dynamic>);
    }
    throw ApiException('Failed to load paper detail (${response.statusCode})');
  }
}
