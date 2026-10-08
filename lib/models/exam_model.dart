double _parseDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

int _parseInt(dynamic val) {
  if (val == null) return 0;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? 0;
  return 0;
}

class PerformanceAnalyticsModel {
  final double mockTestRatio;
  final double combinedPaperRatio;
  final double overallCombinedRatio;
  final int totalAttempts;
  final int completedAttempts;

  PerformanceAnalyticsModel({
    required this.mockTestRatio,
    required this.combinedPaperRatio,
    required this.overallCombinedRatio,
    required this.totalAttempts,
    required this.completedAttempts,
  });

  factory PerformanceAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final mockVal = json['mock_test_ratio'] ??
        json['mockTestRatio'] ??
        json['mock_test_percentage'] ??
        json['mock_ratio'] ??
        json['mock_accuracy'];

    final combinedVal = json['combined_paper_ratio'] ??
        json['combinedPaperRatio'] ??
        json['combined_paper_percentage'] ??
        json['combined_ratio'] ??
        json['combined_score'];

    final overallVal = json['overall_combined_ratio'] ??
        json['overallCombinedRatio'] ??
        json['overall_ratio'] ??
        json['overall_percentage'] ??
        json['overall_both_ratio'] ??
        json['overall_score'];

    final totalAtt = json['total_attempts'] ??
        json['totalAttempts'] ??
        json['total_papers'];

    final compAtt = json['completed_attempts'] ??
        json['completedAttempts'] ??
        json['completed_papers'];

    return PerformanceAnalyticsModel(
      mockTestRatio: _parseDouble(mockVal),
      combinedPaperRatio: _parseDouble(combinedVal),
      overallCombinedRatio: _parseDouble(overallVal),
      totalAttempts: _parseInt(totalAtt),
      completedAttempts: _parseInt(compAtt),
    );
  }
}

class ExamAttemptModel {
  final int id;
  final int questionPaperId;
  final String paperTitle;
  final String paperType; // mocktest, combined, chapter, etc.
  final String status; // in_progress, completed, abandoned
  final int totalQuestions;
  final int totalAnswered;
  final int correctAnswers;
  final int wrongAnswers;
  final int totalMarks;
  final int score;
  final double percentage;
  final String? startedAt;
  final String? completedAt;

  ExamAttemptModel({
    required this.id,
    required this.questionPaperId,
    required this.paperTitle,
    required this.paperType,
    required this.status,
    required this.totalQuestions,
    required this.totalAnswered,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.totalMarks,
    required this.score,
    required this.percentage,
    this.startedAt,
    this.completedAt,
  });

  factory ExamAttemptModel.fromJson(Map<String, dynamic> json) {
    final paper = json['question_paper'] is Map
        ? Map<String, dynamic>.from(json['question_paper'] as Map)
        : <String, dynamic>{};

    final pctVal = json['percentage'] ?? json['score_percentage'] ?? json['accuracy'];
    double pct = _parseDouble(pctVal);
    if (pct == 0.0) {
      final scoreVal = _parseDouble(json['score']);
      final totalMarksVal = _parseDouble(json['total_marks']);
      if (totalMarksVal > 0) {
        pct = (scoreVal / totalMarksVal) * 100;
        if (pct < 0) pct = 0;
      }
    }

    final idVal = _parseInt(
        json['id'] ?? json['attempt_id'] ?? json['user_exam_attempt_id'] ?? json['attemptId']);

    return ExamAttemptModel(
      id: idVal,
      questionPaperId: _parseInt(
          json['question_paper_id'] ?? json['paper_id'] ?? paper['id']),
      paperTitle: paper['title']?.toString() ??
          json['paper_title']?.toString() ??
          'Exam Paper #${idVal > 0 ? idVal : ''}',
      paperType: paper['type']?.toString() ??
          json['paper_type']?.toString() ??
          'Mock Test',
      status: json['status']?.toString() ?? 'completed',
      totalQuestions: _parseInt(json['total_questions']),
      totalAnswered: _parseInt(json['total_answered']),
      correctAnswers: _parseInt(json['correct_answers']),
      wrongAnswers: _parseInt(json['wrong_answers']),
      totalMarks: _parseInt(json['total_marks']),
      score: _parseInt(json['score']),
      percentage: pct,
      startedAt: json['started_at']?.toString(),
      completedAt: json['completed_at']?.toString(),
    );
  }
}

class ExamAnswerDetailModel {
  final int questionId;
  final String questionText;
  final String? selectedAnswerText;
  final String? correctAnswerText;
  final bool? isCorrect;
  final String? reason;

  ExamAnswerDetailModel({
    required this.questionId,
    required this.questionText,
    this.selectedAnswerText,
    this.correctAnswerText,
    this.isCorrect,
    this.reason,
  });

  factory ExamAnswerDetailModel.fromJson(Map<String, dynamic> json) {
    final qObj = json['question'];
    final q = qObj is Map
        ? Map<String, dynamic>.from(qObj as Map)
        : <String, dynamic>{};

    final qText = (qObj is String && qObj.isNotEmpty)
        ? qObj
        : (q['question_text']?.toString() ??
            q['question']?.toString() ??
            json['question_text']?.toString() ??
            json['question']?.toString() ??
            'Question');

    // Extract options list if present
    final List answersList = json['answers'] is List
        ? (json['answers'] as List)
        : (q['answers'] is List
            ? (q['answers'] as List)
            : (q['options'] is List ? (q['options'] as List) : []));

    final selectedOptMap = json['selected_answer'] is Map
        ? Map<String, dynamic>.from(json['selected_answer'] as Map)
        : <String, dynamic>{};

    final correctOptMap = json['correct_answer'] is Map
        ? Map<String, dynamic>.from(json['correct_answer'] as Map)
        : <String, dynamic>{};

    String? selectedText = selectedOptMap['option_text']?.toString() ??
        selectedOptMap['answer']?.toString() ??
        json['selected_answer_text']?.toString();

    String? correctText = correctOptMap['option_text']?.toString() ??
        correctOptMap['answer']?.toString() ??
        json['correct_answer_text']?.toString();

    final selId = _parseInt(
        json['selected_answer_id'] ?? json['selected_option_id'] ?? json['answer_id']);

    if (answersList.isNotEmpty) {
      for (var opt in answersList.whereType<Map>()) {
        final optId = _parseInt(opt['id']);
        final isOptCorrect = opt['is_correct'] == true ||
            opt['is_correct'] == 1 ||
            opt['is_correct'] == '1';
        final optText = opt['answer']?.toString() ??
            opt['option_text']?.toString() ??
            opt['text']?.toString();

        if (selId > 0 && optId == selId) {
          selectedText ??= optText;
        }
        if (isOptCorrect && optText != null) {
          correctText ??= optText;
        }
      }
    }

    String? reasonVal = json['reason']?.toString() ??
        json['reasion']?.toString() ??
        json['explanation']?.toString() ??
        json['solution']?.toString() ??
        json['description']?.toString() ??
        json['remark']?.toString() ??
        q['reason']?.toString() ??
        q['reasion']?.toString() ??
        q['explanation']?.toString() ??
        q['solution']?.toString() ??
        q['description']?.toString() ??
        q['remark']?.toString() ??
        selectedOptMap['reason']?.toString() ??
        correctOptMap['reason']?.toString() ??
        correctOptMap['explanation']?.toString();

    if (reasonVal == 'null' || (reasonVal != null && reasonVal.trim().isEmpty)) {
      reasonVal = null;
    }

    if (answersList.isNotEmpty) {
      for (var opt in answersList.whereType<Map>()) {
        final optId = _parseInt(opt['id']);
        final isOptCorrect = opt['is_correct'] == true ||
            opt['is_correct'] == 1 ||
            opt['is_correct'] == '1';
        final optText = opt['answer']?.toString() ??
            opt['option_text']?.toString() ??
            opt['text']?.toString();

        final optReason = opt['reason']?.toString() ??
            opt['reasion']?.toString() ??
            opt['explanation']?.toString() ??
            opt['solution']?.toString();

        if (optReason != null && optReason != 'null' && optReason.trim().isNotEmpty) {
          reasonVal ??= optReason;
        }

        if (selId > 0 && optId == selId) {
          selectedText ??= optText;
        }
        if (isOptCorrect && optText != null) {
          correctText ??= optText;
          if (optReason != null && optReason != 'null' && optReason.trim().isNotEmpty) {
            reasonVal ??= optReason;
          }
        }
      }
    }

    final isCorrVal = json['is_correct'] ?? q['is_correct'];

    return ExamAnswerDetailModel(
      questionId: _parseInt(json['question_id'] ?? json['id'] ?? q['id']),
      questionText: qText,
      selectedAnswerText: selectedText,
      correctAnswerText: correctText,
      isCorrect: isCorrVal == true || isCorrVal == 1 || isCorrVal == '1',
      reason: reasonVal,
    );
  }
}
