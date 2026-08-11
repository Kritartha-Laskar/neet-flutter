// ── Option ─────────────────────────────────────────────────────────────────
class OptionModel {
  final int id;
  final String answer;
  final bool isCorrect;

  const OptionModel({
    required this.id,
    required this.answer,
    required this.isCorrect,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) => OptionModel(
        id: (json['id'] as num).toInt(),
        answer: json['answer']?.toString() ?? '',
        isCorrect: json['is_correct'] == true || json['is_correct'] == 1,
      );
}

// ── Question ───────────────────────────────────────────────────────────────
class QuestionModel {
  final int id;
  final int order;
  final int marks;
  final String question;
  final String questionType;
  final List<OptionModel> options;

  const QuestionModel({
    required this.id,
    required this.order,
    required this.marks,
    required this.question,
    required this.questionType,
    required this.options,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
        id: (json['id'] as num).toInt(),
        order: (json['order'] as num? ?? 0).toInt(),
        marks: (json['marks'] as num? ?? 0).toInt(),
        question: json['question']?.toString() ?? '',
        questionType: json['question_type']?.toString() ?? 'mcq',
        options: (json['options'] as List<dynamic>? ?? [])
            .map((o) => OptionModel.fromJson(o as Map<String, dynamic>))
            .toList(),
      );
}

// ── Section (grouped by subject) ──────────────────────────────────────────
class SectionModel {
  final String subject;
  final int totalQuestions;
  final int totalMarks;
  final List<QuestionModel> questions;

  const SectionModel({
    required this.subject,
    required this.totalQuestions,
    required this.totalMarks,
    required this.questions,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) => SectionModel(
        subject: json['subject']?.toString() ?? 'Unknown',
        totalQuestions: (json['total_questions'] as num? ?? 0).toInt(),
        totalMarks: (json['total_marks'] as num? ?? 0).toInt(),
        questions: (json['questions'] as List<dynamic>? ?? [])
            .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
            .toList(),
      );
}

// ── Question Paper (list item) ─────────────────────────────────────────────
class QuestionPaperModel {
  final int id;
  final String title;
  final String? description;
  final String? examName;
  final int? examYear;
  final int totalQuestions;
  final int totalMarks;
  final int durationMinutes;
  final int questionsCount;
  final String createdAt;

  const QuestionPaperModel({
    required this.id,
    required this.title,
    this.description,
    this.examName,
    this.examYear,
    required this.totalQuestions,
    required this.totalMarks,
    required this.durationMinutes,
    required this.questionsCount,
    required this.createdAt,
  });

  factory QuestionPaperModel.fromJson(Map<String, dynamic> json) =>
      QuestionPaperModel(
        id: (json['id'] as num).toInt(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        examName: json['exam_name']?.toString(),
        examYear: json['exam_year'] == null ? null : int.tryParse(json['exam_year'].toString()),
        totalQuestions: (json['total_questions'] as num? ?? 0).toInt(),
        totalMarks: (json['total_marks'] as num? ?? 0).toInt(),
        durationMinutes: (json['duration_minutes'] as num? ?? 0).toInt(),
        questionsCount: (json['questions_count'] as num? ?? 0).toInt(),
        createdAt: json['created_at']?.toString() ?? '',
      );
}

// ── Question Paper Detail ──────────────────────────────────────────────────
class QuestionPaperDetailModel {
  final int id;
  final String title;
  final String? description;
  final String? examName;
  final int? examYear;
  final int totalQuestions;
  final int totalMarks;
  final int durationMinutes;
  final Map<String, String> markingScheme;
  final List<SectionModel> sections;

  const QuestionPaperDetailModel({
    required this.id,
    required this.title,
    this.description,
    this.examName,
    this.examYear,
    required this.totalQuestions,
    required this.totalMarks,
    required this.durationMinutes,
    required this.markingScheme,
    required this.sections,
  });

  factory QuestionPaperDetailModel.fromJson(Map<String, dynamic> json) {
    final scheme = (json['marking_scheme'] as Map<String, dynamic>? ?? {})
        .map((k, v) => MapEntry(k, v.toString()));
    return QuestionPaperDetailModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      examName: json['exam_name']?.toString(),
      examYear: json['exam_year'] == null ? null : int.tryParse(json['exam_year'].toString()),
      totalQuestions: (json['total_questions'] as num? ?? 0).toInt(),
      totalMarks: (json['total_marks'] as num? ?? 0).toInt(),
      durationMinutes: (json['duration_minutes'] as num? ?? 0).toInt(),
      markingScheme: scheme,
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((s) => SectionModel.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
