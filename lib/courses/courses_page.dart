import 'package:flutter/material.dart';
import '../footer_header/app_footer.dart';

class CoursesPage extends StatefulWidget {
  const CoursesPage({super.key});

  @override
  State<CoursesPage> createState() => _CoursesPageState();
}

class _CoursesPageState extends State<CoursesPage> {
  int _navIndex = 1; // Courses tab active
  int _selectedDifficulty = 1; // 0=Easy, 1=Medium, 2=Hard

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _surface = Color(0xFFF2F3F8);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9E9E9E);

  static const Color _easyColor = Color(0xFF4CAF50);
  static const Color _mediumColor = Color(0xFFFF9800);
  static const Color _hardColor = Color(0xFFE91E63);

  // ── Mock test data ─────────────────────────────────────────────────────────
  final List<_MockTest> _allTests = [
    _MockTest(
        number: '01',
        title: 'Arrays & Hashing',
        questions: 30,
        minutes: 45,
        marking: '+2/-0.5',
        difficulty: 'Medium'),
    _MockTest(
        number: '02',
        title: 'Linked Lists',
        questions: 25,
        minutes: 40,
        marking: '+2/-0.5',
        difficulty: 'Medium'),
    _MockTest(
        number: '03',
        title: 'Trees & Graphs',
        questions: 35,
        minutes: 50,
        marking: '+2/-0.5',
        difficulty: 'Medium'),
    _MockTest(
        number: '04',
        title: 'Sorting Algorithms',
        questions: 20,
        minutes: 35,
        marking: '+2/-0.5',
        difficulty: 'Medium'),
    _MockTest(
        number: '05',
        title: 'Dynamic Programming',
        questions: 40,
        minutes: 60,
        marking: '+2/-0.5',
        difficulty: 'Hard'),
    _MockTest(
        number: '06',
        title: 'Stack & Queue Basics',
        questions: 15,
        minutes: 20,
        marking: '+1/-0',
        difficulty: 'Easy'),
    _MockTest(
        number: '07',
        title: 'Binary Search',
        questions: 18,
        minutes: 25,
        marking: '+1/-0',
        difficulty: 'Easy'),
    _MockTest(
        number: '08',
        title: 'Graph Traversal',
        questions: 30,
        minutes: 55,
        marking: '+2/-0.5',
        difficulty: 'Hard'),
  ];

  List<_MockTest> get _filteredTests {
    final labels = ['Easy', 'Medium', 'Hard'];
    return _allTests
        .where((t) => t.difficulty == labels[_selectedDifficulty])
        .toList();
  }

  Color _difficultyColor(String d) {
    switch (d) {
      case 'Easy':
        return _easyColor;
      case 'Hard':
        return _hardColor;
      default:
        return _mediumColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCourseCard(),
                    const SizedBox(height: 24),
                    _buildDifficultySection(),
                    const SizedBox(height: 24),
                    _buildTestsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _textDark),
            splashRadius: 24,
          ),
          const Text(
            'Mock Tests',
            style: TextStyle(
              color: _textDark,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // ── Course header card ─────────────────────────────────────────────────────
  Widget _buildCourseCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon box
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.monitor_rounded,
              color: Color(0xFF2196F3),
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Data Structures',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '42 tests',
                      style: TextStyle(color: _textMuted, fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    const Text('·',
                        style: TextStyle(color: _textMuted, fontSize: 12)),
                    const SizedBox(width: 6),
                    Row(
                      children: [
                        Text(
                          'Enrolled',
                          style: TextStyle(
                            color: _easyColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(Icons.check, color: _easyColor, size: 14),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Difficulty filter ──────────────────────────────────────────────────────
  Widget _buildDifficultySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulty Level',
          style: TextStyle(
            color: _textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _diffChip(label: 'Easy', index: 0, color: _easyColor),
            const SizedBox(width: 10),
            _diffChip(label: 'Medium', index: 1, color: _mediumColor),
            const SizedBox(width: 10),
            _diffChip(label: 'Hard', index: 2, color: _hardColor),
          ],
        ),
      ],
    );
  }

  Widget _diffChip({
    required String label,
    required int index,
    required Color color,
  }) {
    final isActive = _selectedDifficulty == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedDifficulty = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: color,
            width: isActive ? 0 : 1.5,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dot indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: isActive ? Colors.white : color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Tests list ─────────────────────────────────────────────────────────────
  Widget _buildTestsSection() {
    final tests = _filteredTests;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Tests',
          style: TextStyle(
            color: _textDark,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 14),
        if (tests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text(
                'No tests available for this level.',
                style: TextStyle(color: _textMuted, fontSize: 14),
              ),
            ),
          )
        else
          ...tests.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTestCard(t),
              )),
      ],
    );
  }

  Widget _buildTestCard(_MockTest test) {
    final dColor = _difficultyColor(test.difficulty);
    return GestureDetector(
      onTap: () {
        // Navigate to test detail — hook up later
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  test.number,
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title & meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.title,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${test.questions} Qs · ${test.minutes} min · ${test.marking}',
                      style:
                          TextStyle(color: _textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Difficulty badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: dColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  test.difficulty,
                  style: TextStyle(
                    color: dColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _MockTest {
  final String number;
  final String title;
  final int questions;
  final int minutes;
  final String marking;
  final String difficulty;

  const _MockTest({
    required this.number,
    required this.title,
    required this.questions,
    required this.minutes,
    required this.marking,
    required this.difficulty,
  });
}
