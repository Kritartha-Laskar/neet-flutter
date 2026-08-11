import 'dart:async';
import 'package:flutter/material.dart';
import '../services/question_paper_service.dart';
import '../services/auth_provider.dart';
import '../models/question_paper_model.dart';

class FlatQuestion {
  final SectionModel section;
  final QuestionModel question;
  final int indexInSection;

  FlatQuestion({
    required this.section,
    required this.question,
    required this.indexInSection,
  });
}

class QuestionPaperDetailPage extends StatefulWidget {
  final int paperId;
  const QuestionPaperDetailPage({super.key, required this.paperId});

  @override
  State<QuestionPaperDetailPage> createState() =>
      _QuestionPaperDetailPageState();
}

class _QuestionPaperDetailPageState extends State<QuestionPaperDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _surface = Color(0xFFF5F6FA);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _success = Color(0xFF4CAF50);
  static const Color _errorColor = Color(0xFFF44336);

  QuestionPaperDetailModel? _paper;
  List<FlatQuestion> _flatQuestions = [];
  bool _loading = true;
  String? _error;

  // Test state
  int _currentQuestionIndex = 0;
  final Map<int, int> _selectedAnswers = {}; // questionId -> optionId
  bool _isReviewMode = false;
  bool _isSubmitted = false;

  // Timer state
  Timer? _timer;
  int _secondsRemaining = 0;

  // Score details
  int _score = 0;
  int _correctCount = 0;
  int _incorrectCount = 0;
  int _skippedCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = AuthProvider.instance.token ?? '';
      final detail = await QuestionPaperService.fetchDetail(
        token: token,
        id: widget.paperId,
      );

      // Flatten the sections to a linear list of questions
      final List<FlatQuestion> flattened = [];
      for (var section in detail.sections) {
        for (int i = 0; i < section.questions.length; i++) {
          flattened.add(FlatQuestion(
            section: section,
            question: section.questions[i],
            indexInSection: i,
          ));
        }
      }

      setState(() {
        _paper = detail;
        _flatQuestions = flattened;
        _secondsRemaining = detail.durationMinutes * 60;
        _loading = false;
      });

      _startTimer();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        _autoSubmitTest();
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _selectOption(int questionId, int optionId) {
    if (_isReviewMode || _isSubmitted) return;
    setState(() {
      if (_selectedAnswers[questionId] == optionId) {
        _selectedAnswers.remove(questionId); // Unselect if tapped again
      } else {
        _selectedAnswers[questionId] = optionId;
      }
    });
  }

  void _calculateResults() {
    _correctCount = 0;
    _incorrectCount = 0;
    _skippedCount = 0;

    for (var fq in _flatQuestions) {
      final q = fq.question;
      final selectedOptId = _selectedAnswers[q.id];
      if (selectedOptId == null) {
        _skippedCount++;
      } else {
        final opt = q.options.firstWhere((o) => o.id == selectedOptId);
        if (opt.isCorrect) {
          _correctCount++;
        } else {
          _incorrectCount++;
        }
      }
    }

    final correctVal = int.tryParse(
            _paper!.markingScheme['correct']?.replaceAll('+', '') ?? '4') ??
        4;
    final incorrectVal = int.tryParse(
            _paper!.markingScheme['incorrect']?.replaceAll('-', '') ?? '1') ??
        1;

    _score = (_correctCount * correctVal) - (_incorrectCount * incorrectVal);
  }

  void _autoSubmitTest() {
    _timer?.cancel();
    _calculateResults();
    setState(() {
      _isSubmitted = true;
      _isReviewMode = true;
    });
    _showResultsDialog();
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Submit Test?',
          style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to submit your test?'),
            const SizedBox(height: 16),
            _dialogStatRow('Total Questions:', '${_flatQuestions.length}'),
            _dialogStatRow('Attempted:', '${_selectedAnswers.length}'),
            _dialogStatRow('Remaining:',
                '${_flatQuestions.length - _selectedAnswers.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _autoSubmitTest();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _dialogStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: _textMuted, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _textDark,
                  fontSize: 13)),
        ],
      ),
    );
  }

  void _showResultsDialog() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Test Submitted Successfully!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _resultStatCard('Score', '$_score', _primary),
                _resultStatCard('Correct', '$_correctCount', _success),
                _resultStatCard('Incorrect', '$_incorrectCount', _errorColor),
                _resultStatCard('Skipped', '$_skippedCount', Colors.amber),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close sheet
                      Navigator.pop(context); // Exit back to tests list
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: _primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Exit Test',
                        style: TextStyle(
                            color: _primary, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close sheet
                      setState(() {
                        _isReviewMode = true;
                        _currentQuestionIndex = 0; // Reset index to review
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Review Answers',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultStatCard(String label, String value, Color color) {
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: _textMuted),
          ),
        ],
      ),
    );
  }

  void _confirmExit() {
    if (_isSubmitted) {
      Navigator.of(context).pop();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Test?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Your progress will not be saved. Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Page
            },
            child: const Text('Exit', style: TextStyle(color: _errorColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _confirmExit();
        return false;
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _surface,
        endDrawer: _loading || _error != null || _flatQuestions.isEmpty ? null : _buildQuestionDrawer(),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _primary))
              : _error != null
                  ? _buildError()
                  : _buildTestLayout(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _textMuted, size: 56),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textMuted)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchDetail,
              style: ElevatedButton.styleFrom(backgroundColor: _primary),
              child:
                  const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestLayout() {
    if (_flatQuestions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    final currentFlat = _flatQuestions[_currentQuestionIndex];
    final q = currentFlat.question;

    return Column(
      children: [
        _buildHeader(),
        _buildSectionStatusPanel(currentFlat),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildQuestionCard(currentFlat.indexInSection, q),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Select one answer:',
                    style: TextStyle(
                        color: _textDark,
                        fontWeight: FontWeight.w700,
                        fontSize: 14),
                  ),
                ),
                ...q.options.asMap().entries.map(
                      (oe) => _buildOptionRow(q.id, oe.key, oe.value),
                    ),
              ],
            ),
          ),
        ),
        _buildBottomNavigation(),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final p = _paper!;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: _confirmExit,
            icon: const Icon(Icons.close_rounded, color: _textDark, size: 24),
            splashRadius: 22,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _isReviewMode ? 'Review Mode' : 'Practice Test',
                  style: TextStyle(
                    color: _isReviewMode ? _success : _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (!_isSubmitted) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      color: Colors.redAccent, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _confirmSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  color: _primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
            icon: const Icon(Icons.grid_view_rounded, color: _primary, size: 24),
            tooltip: 'Question Palette',
            splashRadius: 22,
          ),
        ],
      ),
    );
  }

  // ── Section Status Panel ──────────────────────────────────────────────────
  Widget _buildSectionStatusPanel(FlatQuestion flat) {
    final progress = (_currentQuestionIndex + 1) / _flatQuestions.length;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  flat.section.subject.toUpperCase(),
                  style: const TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_flatQuestions.length}',
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFEBEBEB),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
        ],
      ),
    );
  }

  // ── Question Card ─────────────────────────────────────────────────────────
  Widget _buildQuestionCard(int indexInSection, QuestionModel q) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F6FA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Q ${indexInSection + 1}',
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5A623).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${q.marks} Marks',
                      style: const TextStyle(
                        color: Color(0xFFF5A623),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Q ${_currentQuestionIndex + 1} / ${_flatQuestions.length}',
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            q.question,
            style: const TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Option Row ────────────────────────────────────────────────────────────
  Widget _buildOptionRow(int questionId, int idx, OptionModel opt) {
    final letters = ['A', 'B', 'C', 'D', 'E'];
    final letter = idx < letters.length ? letters[idx] : '${idx + 1}';

    final isSelected = _selectedAnswers[questionId] == opt.id;
    final isCorrect = opt.isCorrect;

    // Determine colors based on mode
    Color cardBgColor = Colors.white;
    Color borderColor = const Color(0xFFE2E4E8);
    Color textColor = _textDark;
    Widget selectionIndicator = const SizedBox.shrink();

    if (_isReviewMode) {
      if (isCorrect) {
        cardBgColor = _success.withOpacity(0.08);
        borderColor = _success;
        textColor = _success;
        selectionIndicator = const Icon(Icons.check_circle_rounded,
            color: _success, size: 20);
      } else if (isSelected) {
        cardBgColor = _errorColor.withOpacity(0.08);
        borderColor = _errorColor;
        textColor = _errorColor;
        selectionIndicator = const Icon(Icons.cancel_rounded,
            color: _errorColor, size: 20);
      }
    } else {
      if (isSelected) {
        cardBgColor = _primary.withOpacity(0.06);
        borderColor = _primary;
        textColor = _primary;
        selectionIndicator = Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _primary,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.4),
                blurRadius: 4,
              )
            ],
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectOption(questionId, opt.id),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isSelected && !_isReviewMode
                ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              // Option Letter circle
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected && !_isReviewMode
                      ? _primary
                      : _isReviewMode && isCorrect
                          ? _success
                          : _isReviewMode && isSelected
                              ? _errorColor
                              : const Color(0xFFF5F6FA),
                  border: isSelected || (_isReviewMode && isCorrect)
                      ? null
                      : Border.all(color: const Color(0xFFD2D4D8)),
                ),
                alignment: Alignment.center,
                child: Text(
                  letter,
                  style: TextStyle(
                    color: isSelected || (_isReviewMode && isCorrect)
                        ? Colors.white
                        : _textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  opt.answer,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13.5,
                    fontWeight: isSelected || (_isReviewMode && isCorrect)
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              selectionIndicator,
            ],
          ),
        ),
      ),
    );
  }
  // ── Bottom Navigation ─────────────────────────────────────────────────────
  Widget _buildBottomNavigation() {
    final hasPrev = _currentQuestionIndex > 0;
    final isLast = _currentQuestionIndex == _flatQuestions.length - 1;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          Expanded(
            child: OutlinedButton(
              onPressed: hasPrev
                  ? () {
                      setState(() {
                        _currentQuestionIndex--;
                      });
                    }
                  : null,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: hasPrev ? _primary : Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Previous',
                style: TextStyle(
                  color: hasPrev ? _primary : _textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Next Button
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                if (isLast) {
                  if (_isSubmitted) {
                    Navigator.pop(context); // Go back
                  } else {
                    _confirmSubmit();
                  }
                } else {
                  setState(() {
                    _currentQuestionIndex++;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isLast
                    ? (_isSubmitted ? 'Exit Practice' : 'Submit Test')
                    : 'Next',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drawer Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Questions Panel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: _textDark),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            
            // Stats summary in Drawer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _drawerStatBadge('Attempted', _selectedAnswers.length, _primary.withOpacity(0.1), _primary),
                  _drawerStatBadge('Remaining', _flatQuestions.length - _selectedAnswers.length, Colors.grey.shade100, _textMuted),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),

            // Grid of Question Numbers
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: _flatQuestions.length,
                itemBuilder: (context, index) {
                  final isCurrent = index == _currentQuestionIndex;
                  final fq = _flatQuestions[index];
                  final isAttempted = _selectedAnswers.containsKey(fq.question.id);

                  Color itemBg = Colors.white;
                  Color textCol = _textDark;
                  Border? border = Border.all(color: const Color(0xFFD2D4D8));

                  if (isCurrent) {
                    itemBg = _primary;
                    textCol = Colors.white;
                    border = null;
                  } else if (isAttempted) {
                    itemBg = _primary.withOpacity(0.12);
                    textCol = _primary;
                    border = Border.all(color: _primary.withOpacity(0.3));
                  }

                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context); // Close drawer
                      setState(() {
                        _currentQuestionIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: itemBg,
                        borderRadius: BorderRadius.circular(8),
                        border: border,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: textCol,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _drawerStatBadge(String label, int value, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(color: textCol.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Text(
            '$value',
            style: TextStyle(color: textCol, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
