import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/exam_model.dart';

class ExamService {
  ExamService._();

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Fetch Performance Analytics (Mock Test ratio %, Combined Paper ratio %, Overall Combined ratio %)
  static Future<PerformanceAnalyticsModel> fetchAnalytics({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.examAnalytics),
        headers: _headers(token),
      );

      debugPrint('[ExamService] fetchAnalytics HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        dynamic data = json['data'] ?? json['analytics'] ?? json;
        if (data is List && data.isNotEmpty) {
          data = data.first;
        }
        if (data is Map) {
          return PerformanceAnalyticsModel.fromJson(Map<String, dynamic>.from(data));
        }
      }
    } catch (e, stack) {
      debugPrint('[ExamService] fetchAnalytics error: $e\n$stack');
    }
    return PerformanceAnalyticsModel(
      mockTestRatio: 0.0,
      combinedPaperRatio: 0.0,
      overallCombinedRatio: 0.0,
      totalAttempts: 0,
      completedAttempts: 0,
    );
  }

  static List<ExamAttemptModel> _extractAttemptModelsFromJson(dynamic json) {
    if (json == null) return [];
    List<Map<String, dynamic>> maps = [];

    void search(dynamic obj) {
      if (obj is List) {
        for (var item in obj) {
          search(item);
        }
      } else if (obj is Map) {
        final mapObj = Map<String, dynamic>.from(obj);
        if (mapObj.containsKey('percentage') ||
            mapObj.containsKey('score') ||
            mapObj.containsKey('total_marks') ||
            mapObj.containsKey('completed_at') ||
            mapObj.containsKey('started_at') ||
            mapObj.containsKey('question_paper_id')) {
          maps.add(mapObj);
        } else {
          mapObj.forEach((k, v) => search(v));
        }
      }
    }

    search(json);

    return maps.map((m) {
      try {
        return ExamAttemptModel.fromJson(m);
      } catch (e) {
        debugPrint('ExamAttemptModel parse error: $e');
        return null;
      }
    }).whereType<ExamAttemptModel>().toList();
  }

  /// Fetch Exam Attempt History
  static Future<List<ExamAttemptModel>> fetchHistory({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.examHistory),
        headers: _headers(token),
      );

      debugPrint('[ExamService] fetchHistory HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final list = _extractAttemptModelsFromJson(json);
        if (list.isNotEmpty) return list;
      }

      // Fallback: If /api/exam/history is 404 or empty, fetch attempts from /api/exam/analytics
      debugPrint('[ExamService] fetchHistory falling back to /api/exam/analytics');
      final analyticsRes = await http.get(
        Uri.parse(ApiConfig.examAnalytics),
        headers: _headers(token),
      );
      if (analyticsRes.statusCode == 200) {
        final json = jsonDecode(analyticsRes.body);
        return _extractAttemptModelsFromJson(json);
      }
    } catch (e, stack) {
      debugPrint('[ExamService] fetchHistory error: $e\n$stack');
    }
    return [];
  }

  /// Fetch Question-by-Question Attempt Detail
  static Future<List<ExamAnswerDetailModel>> fetchAttemptDetail({
    required String token,
    required int attemptId,
  }) async {
    if (attemptId <= 0) {
      throw Exception('Invalid attempt ID ($attemptId)');
    }

    final response = await http.get(
      Uri.parse(ApiConfig.examAttemptDetail(attemptId)),
      headers: _headers(token),
    );

    debugPrint('[ExamService] fetchAttemptDetail HTTP ${response.statusCode}: ${response.body}');

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      dynamic raw = json['data'] ?? json['questions'] ?? json['answers'] ?? json['details'] ?? json;

      if (raw is Map) {
        raw = raw['questions'] ??
            raw['answers'] ??
            raw['user_exam_answers'] ??
            raw['user_answers'] ??
            raw['details'] ??
            raw['data'] ??
            [];
      }

      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((e) => ExamAnswerDetailModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    } else {
      throw Exception('Failed to load attempt detail (${response.statusCode})');
    }
    return [];
  }

  /// Start an Exam Attempt Session
  static Future<Map<String, dynamic>> startExam({
    required String token,
    required int paperId,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.examStart),
      headers: _headers(token),
      body: jsonEncode({'question_paper_id': paperId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to start exam (${response.statusCode})');
    }
  }

  /// Save / Update Answer instantly per question
  static Future<void> saveAnswer({
    required String token,
    required int attemptId,
    required int questionId,
    int? selectedAnswerId,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.examSaveAnswer),
      headers: _headers(token),
      body: jsonEncode({
        'attempt_id': attemptId,
        'question_id': questionId,
        'selected_answer_id': selectedAnswerId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save answer (${response.statusCode}): ${response.body}');
    }
  }

  /// Submit Exam
  static Future<Map<String, dynamic>> submitExam({
    required String token,
    required int attemptId,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.examSubmit),
      headers: _headers(token),
      body: jsonEncode({'attempt_id': attemptId}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to submit exam (${response.statusCode}): ${response.body}');
    }
  }
}
