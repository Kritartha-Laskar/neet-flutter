// ── Option ─────────────────────────────────────────────────────────────────
class OptionModel {
  final int id;
  final String answer;
  final bool isCorrect;
  final String? reason;

  const OptionModel({
    required this.id,
    required this.answer,
    required this.isCorrect,
    this.reason,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) => OptionModel(
        id: (json['id'] as num).toInt(),
        answer: json['answer']?.toString() ?? '',
        isCorrect: json['is_correct'] == true || json['is_correct'] == 1,
        reason: json['reason']?.toString() ??
            json['reasion']?.toString() ??
            json['explanation']?.toString() ??
            json['solution']?.toString(),
      );
}

// ── Question ───────────────────────────────────────────────────────────────
class QuestionModel {
  final int id;
  final int order;
  final int marks;
  final String question;
  final String? imageUrl;
  final String questionType;
  final List<OptionModel> options;
  final String? reason;

  const QuestionModel({
    required this.id,
    required this.order,
    required this.marks,
    required this.question,
    this.imageUrl,
    required this.questionType,
    required this.options,
    this.reason,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) => QuestionModel(
        id: (json['id'] as num).toInt(),
        order: (json['order'] as num? ?? 0).toInt(),
        marks: (json['marks'] as num? ?? 0).toInt(),
        question: json['question']?.toString() ?? '',
        imageUrl: json['image_url']?.toString() ?? json['image']?.toString(),
        questionType: json['question_type']?.toString() ?? 'mcq',
        options: (json['options'] as List<dynamic>? ?? [])
            .map((o) => OptionModel.fromJson(o as Map<String, dynamic>))
            .toList(),
        reason: json['reason']?.toString() ??
            json['reasion']?.toString() ??
            json['explanation']?.toString() ??
            json['solution']?.toString() ??
            json['answer_reason']?.toString(),
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
  final String? paperType;
  final int? subjectId;
  final String? subjectName;
  final String? chapterName;
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
    this.paperType,
    this.subjectId,
    this.subjectName,
    this.chapterName,
    this.examYear,
    required this.totalQuestions,
    required this.totalMarks,
    required this.durationMinutes,
    required this.questionsCount,
    required this.createdAt,
  });

  static String? parseChapterName(Map<String, dynamic> json) {
    // 1. Direct key strings
    final direct = json['chapter_name'] ??
        json['chapter_title'] ??
        json['chapterName'] ??
        json['chapterTitle'] ??
        json['topic'] ??
        json['topic_name'] ??
        json['topic_title'];
    if (direct != null &&
        direct.toString().trim().isNotEmpty &&
        direct.toString().trim().toLowerCase() != 'null') {
      return direct.toString().trim();
    }

    // 2. 'chapter' as Map or String
    final chap = json['chapter'];
    if (chap is Map) {
      final name = chap['name'] ??
          chap['title'] ??
          chap['chapter_name'] ??
          chap['chapter_title'] ??
          chap['full_title'];
      if (name != null &&
          name.toString().trim().isNotEmpty &&
          name.toString().trim().toLowerCase() != 'null') {
        return name.toString().trim();
      }
    } else if (chap is String &&
        chap.trim().isNotEmpty &&
        chap.trim().toLowerCase() != 'null') {
      return chap.trim();
    }

    // 3. 'chapters' as List
    if (json['chapters'] is List && (json['chapters'] as List).isNotEmpty) {
      final first = (json['chapters'] as List).first;
      if (first is Map) {
        final name = first['name'] ?? first['title'] ?? first['chapter_name'];
        if (name != null && name.toString().trim().isNotEmpty) {
          return name.toString().trim();
        }
      } else if (first is String && first.trim().isNotEmpty) {
        return first.trim();
      }
    }

    return null;
  }

  /// Returns the actual chapter title of the paper.
  /// If not directly provided in API payload, extracts it from the description or title.
  String get effectiveChapterTitle {
    // 1. Direct chapterName from API
    if (chapterName != null) {
      final name = chapterName!.trim();
      if (name.isNotEmpty &&
          name.toLowerCase() != 'null' &&
          name != '{}' &&
          !name.startsWith('{')) {
        return name;
      }
    }

    // 2. Extract from description (e.g. "...preparation for Sexual Reproduction in Flowering Plants.")
    if (description != null && description!.trim().isNotEmpty) {
      final desc = description!.trim();

      // Match "preparation for <Chapter>"
      final prepMatch = RegExp(
        r'preparation for\s+([^.]+)',
        caseSensitive: false,
      ).firstMatch(desc);
      if (prepMatch != null) {
        final extracted = prepMatch.group(1)!.trim();
        if (extracted.isNotEmpty) return extracted;
      }

      // Match "chapter test for <Chapter>" or "test for <Chapter>"
      final testOnMatch = RegExp(
        r'(?:chapter test|practice test|mock test|test)\s+(?:for|on|covering)\s+([^.]+)',
        caseSensitive: false,
      ).firstMatch(desc);
      if (testOnMatch != null) {
        final extracted = testOnMatch.group(1)!.trim();
        if (extracted.isNotEmpty &&
            !extracted.toLowerCase().startsWith('mock test') &&
            !extracted.toLowerCase().startsWith('neet') &&
            !extracted.toLowerCase().startsWith('all subject')) {
          return extracted;
        }
      }

      // Match "Chapter: <Chapter>" or "Topic: <Chapter>"
      final labelMatch = RegExp(
        r'(?:chapter|topic)[:\-]\s*([^.,\n]+)',
        caseSensitive: false,
      ).firstMatch(desc);
      if (labelMatch != null) {
        final extracted = labelMatch.group(1)!.trim();
        if (extracted.isNotEmpty) return extracted;
      }
    }

    // 3. Extract from title
    final trimmedTitle = title.trim();
    if (trimmedTitle.isNotEmpty) {
      // Match "Chapter 1: Cell" or "Chapter 1"
      final chapNumMatch = RegExp(
        r'(Chapter\s*\d+[^:#\-]*)',
        caseSensitive: false,
      ).firstMatch(trimmedTitle);
      if (chapNumMatch != null) {
        return chapNumMatch.group(1)!.trim();
      }

      // Match "<Chapter> - Mock Test"
      final prefixMatch = RegExp(
        r'^(.+?)\s*[-:]\s*(?:Mock Test|Chapter Test|Test Paper|Practice Test)',
        caseSensitive: false,
      ).firstMatch(trimmedTitle);
      if (prefixMatch != null) {
        final extracted = prefixMatch.group(1)!.trim();
        if (extracted.isNotEmpty && !extracted.toLowerCase().contains('neet')) {
          return extracted;
        }
      }

      // Non-generic title (e.g. title is the actual chapter name)
      final isGeneric = RegExp(
        r'^(mock test|test paper|practice test|neet mock test|mock test \d{4})$',
        caseSensitive: false,
      ).hasMatch(trimmedTitle);

      if (!isGeneric && trimmedTitle.length > 3) {
        return trimmedTitle;
      }
    }

    // 4. Default clean fallback for subject mock tests
    if (subjectName != null && subjectName!.trim().isNotEmpty) {
      return '${subjectName!.trim()} - Full Syllabus Mock Test';
    }

    return 'Full Syllabus Mock Test';
  }

  factory QuestionPaperModel.fromJson(Map<String, dynamic> json) =>
      QuestionPaperModel(
        id: (json['id'] as num).toInt(),
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        examName: json['exam_name']?.toString(),
        paperType: json['paper_type']?.toString(),
        subjectId: json['subject_id'] == null
            ? null
            : int.tryParse(json['subject_id'].toString()),
        subjectName: json['subject_name']?.toString(),
        chapterName: parseChapterName(json),
        examYear: json['exam_year'] == null
            ? null
            : int.tryParse(json['exam_year'].toString()),
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
  final String? chapterName;
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
    this.chapterName,
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
      chapterName: QuestionPaperModel.parseChapterName(json),
      examYear: json['exam_year'] == null
          ? null
          : int.tryParse(json['exam_year'].toString()),
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

