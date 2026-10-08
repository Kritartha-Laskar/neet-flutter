import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';
import '../services/auth_provider.dart';
import '../widgets/math_text.dart';

class AttemptDetailDialog extends StatefulWidget {
  final ExamAttemptModel attempt;
  const AttemptDetailDialog({super.key, required this.attempt});

  @override
  State<AttemptDetailDialog> createState() => _AttemptDetailDialogState();
}

class _AttemptDetailDialogState extends State<AttemptDetailDialog> {
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _success = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFF44336);

  bool _loading = true;
  String? _error;
  List<ExamAnswerDetailModel> _answers = [];

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final token = AuthProvider.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Not authenticated';
      });
      return;
    }

    try {
      final list = await ExamService.fetchAttemptDetail(
        token: token,
        attemptId: widget.attempt.id,
      );
      setState(() {
        _answers = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final att = widget.attempt;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FE),
                border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          att.paperTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Score: ${att.score} / ${att.totalMarks} (${att.percentage.toStringAsFixed(1)}%)',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: _textDark),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: _errorColor, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : _answers.isEmpty
                          ? const Center(
                              child: Text(
                                'No question detail found for this attempt.',
                                style: TextStyle(color: _textMuted, fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _answers.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final ans = _answers[i];
                                final isCorrect = ans.isCorrect == true;
                                final isSkipped = ans.selectedAnswerText == null ||
                                    ans.selectedAnswerText!.isEmpty;

                                final Color badgeBg = isSkipped
                                    ? Colors.grey.shade100
                                    : isCorrect
                                        ? const Color(0xFFE8F5E9)
                                        : const Color(0xFFFFEBEE);

                                final Color badgeColor = isSkipped
                                    ? _textMuted
                                    : isCorrect
                                        ? _success
                                        : _errorColor;

                                final String badgeText = isSkipped
                                    ? 'Skipped'
                                    : isCorrect
                                        ? 'Correct (+4)'
                                        : 'Incorrect (-1)';

                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAFAFE),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: badgeColor.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: _primary.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Q${i + 1}',
                                              style: const TextStyle(
                                                color: _primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              ans.questionText,
                                              style: const TextStyle(
                                                color: _textDark,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: badgeBg,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              badgeText,
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Selected Answer
                                      Row(
                                        children: [
                                          const Text(
                                            'Selected: ',
                                            style: TextStyle(
                                              color: _textMuted,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              ans.selectedAnswerText ?? 'Not Answered',
                                              style: TextStyle(
                                                color: isSkipped
                                                    ? _textMuted
                                                    : isCorrect
                                                        ? _success
                                                        : _errorColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Correct Answer (if wrong or skipped)
                                      if (!isCorrect && ans.correctAnswerText != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Text(
                                              'Correct: ',
                                              style: TextStyle(
                                                color: _textMuted,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                ans.correctAnswerText!,
                                                style: const TextStyle(
                                                  color: _success,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      
                                       // Reason / Explanation Box
                                       const SizedBox(height: 8),
                                       Container(
                                         padding: const EdgeInsets.all(10),
                                         decoration: BoxDecoration(
                                           color: const Color(0xFFF4F3FF),
                                           borderRadius: BorderRadius.circular(8),
                                           border: Border.all(
                                             color: _primary.withOpacity(0.2),
                                           ),
                                         ),
                                         child: Column(
                                           crossAxisAlignment:
                                               CrossAxisAlignment.start,
                                           children: [
                                             const Row(
                                               children: [
                                                 Icon(Icons.lightbulb_rounded,
                                                     color: _primary, size: 14),
                                                 SizedBox(width: 4),
                                                 Text(
                                                   'Reason / Explanation:',
                                                   style: TextStyle(
                                                     color: _primary,
                                                     fontWeight: FontWeight.w800,
                                                     fontSize: 11.5,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                             const SizedBox(height: 4),
                                             Text(
                                               (ans.reason != null &&
                                                       ans.reason!.trim().isNotEmpty &&
                                                       ans.reason!.trim() != 'null')
                                                   ? ans.reason!.trim()
                                                   : (ans.correctAnswerText != null &&
                                                           ans.correctAnswerText!.isNotEmpty)
                                                       ? 'The correct answer for this question is: ${ans.correctAnswerText}.'
                                                       : 'Correct answer recorded for this question.',
                                               style: const TextStyle(
                                                 color: _textDark,
                                                 fontSize: 12,
                                                 height: 1.35,
                                               ),
                                             ),
                                           ],
                                         ),
                                       ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
