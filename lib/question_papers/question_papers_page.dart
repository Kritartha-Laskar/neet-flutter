import 'package:flutter/material.dart';
import '../services/question_paper_service.dart';
import '../services/auth_provider.dart';
import '../models/question_paper_model.dart';
import '../footer_header/app_footer.dart';
import 'question_paper_detail_page.dart';

// ── Subject Definition ────────────────────────────────────────────────────────
class SubjectInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Color arrowBgColor;
  final Color arrowColor;

  const SubjectInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.arrowBgColor,
    required this.arrowColor,
  });
}

class QuestionPapersPage extends StatefulWidget {
  const QuestionPapersPage({super.key});

  @override
  State<QuestionPapersPage> createState() => _QuestionPapersPageState();
}

class _QuestionPapersPageState extends State<QuestionPapersPage> {
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _surface = Color(0xFFF2F3F8);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9E9E9E);

  // Preset theme styles for matching backend subjects by name
  static const List<SubjectInfo> _presetStyles = [
    SubjectInfo(
      name: 'Biology',
      description: 'Practice chapter wise mock tests and improve your concepts.',
      icon: Icons.health_and_safety_rounded,
      color: Color(0xFF20C997),
      arrowBgColor: Color(0xFFE6F8F3),
      arrowColor: Color(0xFF0CA678),
    ),
    SubjectInfo(
      name: 'Physics',
      description: 'Practice chapter wise mock tests and improve your concepts.',
      icon: Icons.science_rounded,
      color: Color(0xFF4F369B),
      arrowBgColor: Color(0xFFE8F5E9),
      arrowColor: Color(0xFF2E7D32),
    ),
    SubjectInfo(
      name: 'Chemistry',
      description: 'Practice chapter wise mock tests and improve your concepts.',
      icon: Icons.biotech_rounded,
      color: Color(0xFF388E3C),
      arrowBgColor: Color(0xFFE8F5E9),
      arrowColor: Color(0xFF2E7D32),
    ),
    SubjectInfo(
      name: 'Botany',
      description: 'Practice chapter wise mock tests and improve your concepts.',
      icon: Icons.eco_rounded,
      color: Color(0xFF4CAF50),
      arrowBgColor: Color(0xFFE8F5E9),
      arrowColor: Color(0xFF2E7D32),
    ),
    SubjectInfo(
      name: 'Mathematics',
      description: 'Practice chapter wise mock tests and improve your concepts.',
      icon: Icons.calculate_rounded,
      color: Color(0xFF5E35B1),
      arrowBgColor: Color(0xFFE8F5E9),
      arrowColor: Color(0xFF2E7D32),
    ),
    SubjectInfo(
      name: 'General Aptitude',
      description: 'Practice chapter wise mock tests and improve your concepts.',
      icon: Icons.extension_rounded,
      color: Color(0xFF43A047),
      arrowBgColor: Color(0xFFE8F5E9),
      arrowColor: Color(0xFF2E7D32),
    ),
    SubjectInfo(
      name: 'Zoology',
      description: 'Practice chapter wise mock tests and improve your concepts.',
      icon: Icons.pets_rounded,
      color: Color(0xFF00897B),
      arrowBgColor: Color(0xFFE0F2F1),
      arrowColor: Color(0xFF00695C),
    ),
  ];

  List<QuestionPaperModel> _papers = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;
  final int _navIndex = 1;

  String _selectedSection = 'mocktest'; // 'mocktest' or 'combined'
  String? _selectedSubject; // null = subject view, String = subject papers view

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchPapers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _currentPage < _lastPage) {
      _fetchMore();
    }
  }

  Future<void> _fetchPapers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _error = null;
        _currentPage = 1;
        _papers = [];
      });
    }
    try {
      final token = AuthProvider.instance.token ?? '';
      final result = await QuestionPaperService.fetchList(
        token: token,
        page: _currentPage,
        paperType: _selectedSection,
      );
      setState(() {
        _papers = result['papers'] as List<QuestionPaperModel>;
        _lastPage = result['last_page'] as int;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fetchMore() async {
    setState(() => _loadingMore = true);
    try {
      final token = AuthProvider.instance.token ?? '';
      final result = await QuestionPaperService.fetchList(
        token: token,
        page: _currentPage + 1,
        paperType: _selectedSection,
      );
      setState(() {
        _papers.addAll(result['papers'] as List<QuestionPaperModel>);
        _currentPage++;
        _lastPage = result['last_page'] as int;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  SubjectInfo _getSubjectInfo(String name) {
    final lower = name.trim().toLowerCase();
    for (final s in _presetStyles) {
      if (s.name.toLowerCase() == lower) return s;
    }
    return SubjectInfo(
      name: name,
      description: 'Practice chapter wise mock tests and improve your concepts.',
      icon: Icons.assignment_rounded,
      color: _primary,
      arrowBgColor: const Color(0xFFEDE7FF),
      arrowColor: _primary,
    );
  }

  String _getEffectiveChapterName(QuestionPaperModel paper) {
    return paper.effectiveChapterTitle;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            if (_selectedSubject == null) _buildSectionTabs(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == _navIndex) return;
          Navigator.of(context).pop(i);
        },
      ),
    );
  }

  // ── Section Tabs ──────────────────────────────────────────────────────────
  Widget _buildSectionTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF2F3F8),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedSection != 'mocktest') {
                    setState(() {
                      _selectedSection = 'mocktest';
                      _selectedSubject = null;
                    });
                    _fetchPapers(refresh: true);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _selectedSection == 'mocktest'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _selectedSection == 'mocktest'
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.layers_rounded,
                        size: 16,
                        color: _selectedSection == 'mocktest'
                            ? _primary
                            : _textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Mock Test',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedSection == 'mocktest'
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedSection == 'mocktest'
                              ? _primary
                              : _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_selectedSection != 'combined') {
                    setState(() {
                      _selectedSection = 'combined';
                      _selectedSubject = null;
                    });
                    _fetchPapers(refresh: true);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _selectedSection == 'combined'
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: _selectedSection == 'combined'
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.article_rounded,
                        size: 16,
                        color: _selectedSection == 'combined'
                            ? _primary
                            : _textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Test Paper',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: _selectedSection == 'combined'
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: _selectedSection == 'combined'
                              ? _primary
                              : _textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: _primary),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _textMuted, size: 56),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textMuted, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _fetchPapers(refresh: true),
                style: ElevatedButton.styleFrom(backgroundColor: _primary),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_selectedSection == 'mocktest') {
      if (_selectedSubject == null) {
        return _buildSubjectsList();
      } else {
        return _buildChapterWisePapersList();
      }
    } else {
      return _buildCombinedPapersList();
    }
  }

  // ── Subjects List View (Strictly calculated from Backend Data) ──────────────
  Widget _buildSubjectsList() {
    final Map<String, List<QuestionPaperModel>> groupedBySubject = {};

    for (final paper in _papers) {
      final String rawSubject =
          (paper.subjectName != null && paper.subjectName!.trim().isNotEmpty)
              ? paper.subjectName!.trim()
              : (paper.paperType == 'mocktest' ? 'General' : 'Combined');
      final String key = rawSubject.toLowerCase();

      if (!groupedBySubject.containsKey(key)) {
        groupedBySubject[key] = [];
      }
      groupedBySubject[key]!.add(paper);
    }

    if (groupedBySubject.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.layers_outlined,
                size: 56,
                color: _textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No mock test papers available.',
                style: TextStyle(color: _textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final List<MapEntry<SubjectInfo, List<QuestionPaperModel>>> subjectEntries = [];

    groupedBySubject.forEach((key, papers) {
      final String displayName =
          (papers.first.subjectName != null && papers.first.subjectName!.trim().isNotEmpty)
              ? papers.first.subjectName!.trim()
              : (papers.first.paperType == 'mocktest' ? 'General' : 'Combined');
      final SubjectInfo info = _getSubjectInfo(displayName);
      subjectEntries.add(MapEntry(info, papers));
    });

    return RefreshIndicator(
      color: _primary,
      onRefresh: () => _fetchPapers(refresh: true),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: subjectEntries.length,
        itemBuilder: (ctx, i) {
          final entry = subjectEntries[i];
          final subjectInfo = entry.key;
          final matchingPapers = entry.value;

          final int testCount = matchingPapers.length;
          final int questionCount = matchingPapers.fold(
            0,
            (sum, p) =>
                sum +
                (p.totalQuestions > 0 ? p.totalQuestions : p.questionsCount),
          );

          return _SubjectCard(
            subject: subjectInfo,
            testCount: testCount,
            questionCount: questionCount,
            onTap: () {
              setState(() {
                _selectedSubject = subjectInfo.name;
              });
            },
          );
        },
      ),
    );
  }

  // ── Chapter-Wise Papers List View (Matching Web Design) ─────────────────────
  Widget _buildChapterWisePapersList() {
    final subjectPapers = _papers.where((p) {
      if (_selectedSubject == null) return true;
      final String pSubject =
          (p.subjectName != null && p.subjectName!.trim().isNotEmpty)
              ? p.subjectName!.trim()
              : (p.paperType == 'mocktest' ? 'General' : 'Combined');
      return pSubject.toLowerCase() == _selectedSubject!.trim().toLowerCase();
    }).toList();

    if (subjectPapers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.description_outlined,
                size: 56,
                color: _textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No mock test papers available for $_selectedSubject yet.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _textMuted, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _selectedSubject = null;
                  });
                },
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back to Subjects'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group papers by Chapter
    final Map<String, List<QuestionPaperModel>> chapterMap = {};
    for (final paper in subjectPapers) {
      final String chap = _getEffectiveChapterName(paper);
      if (!chapterMap.containsKey(chap)) {
        chapterMap[chap] = [];
      }
      chapterMap[chap]!.add(paper);
    }

    final List<String> chaptersList = chapterMap.keys.toList();
    final SubjectInfo subjectTheme = _getSubjectInfo(_selectedSubject ?? '');

    return RefreshIndicator(
      color: subjectTheme.color,
      onRefresh: () => _fetchPapers(refresh: true),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Green / Theme Subject Header Banner (Matching Web Screenshot) ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: subjectTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: subjectTheme.color.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedSubject = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(subjectTheme.icon,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_selectedSubject?.toUpperCase()} MOCK TEST PAPERS',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${subjectPapers.length} Question Paper(s) across ${chaptersList.length} Chapter Group(s)',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${subjectPapers.length} Papers',
                      style: TextStyle(
                        color: subjectTheme.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Question Paper Cards ─────────────────────────────────────────
            ...chaptersList.expand((chap) {
              final papersList = chapterMap[chap] ?? [];
              return papersList.map((paper) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _WebStylePaperCard(
                    paper: paper,
                    subjectTheme: subjectTheme,
                    chapterTitle: chap,
                    onTap: () {
                      Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder: (_, animation, __) =>
                              QuestionPaperDetailPage(paperId: paper.id),
                          transitionsBuilder: (_, animation, __, child) =>
                              FadeTransition(opacity: animation, child: child),
                          transitionDuration:
                              const Duration(milliseconds: 200),
                        ),
                      );
                    },
                  ),
                );
              });
            }),
          ],
        ),
      ),
    );
  }

  // ── Combined Papers List View ─────────────────────────────────────────────
  Widget _buildCombinedPapersList() {
    final filteredPapers = _papers.where((p) {
      return p.paperType == 'combined' || p.subjectId == null;
    }).toList();

    if (filteredPapers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_outlined,
                size: 56,
                color: _textMuted.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'No combined test papers available.',
                style: TextStyle(color: _textMuted, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: _primary,
      onRefresh: () => _fetchPapers(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: filteredPapers.length + (_loadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == filteredPapers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: _primary)),
            );
          }
          final paper = filteredPapers[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PaperCard(
              paper: paper,
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) =>
                        QuestionPaperDetailPage(paperId: paper.id),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                    transitionDuration: const Duration(milliseconds: 280),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Subject Card (Level 1 View) ──────────────────────────────────────────────

class _SubjectCard extends StatelessWidget {
  final SubjectInfo subject;
  final int testCount;
  final int questionCount;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.subject,
    required this.testCount,
    required this.questionCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Subject Icon + Name & Subtitle + Chevron Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon Box
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: subject.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        subject.icon,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subject.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF757575),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Chevron Circle Button
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: subject.arrowBgColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: subject.arrowColor,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Bottom Stats Box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F5FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Stat 1: Tests Count
                      const Icon(
                        Icons.description_outlined,
                        size: 15,
                        color: Color(0xFF6A5AE0),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$testCount Tests',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const Spacer(),
                      // Vertical Line
                      Container(
                        height: 12,
                        width: 1,
                        color: const Color(0xFFD0D0D0),
                      ),
                      const Spacer(),
                      // Stat 2: Questions Count
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 15,
                        color: Color(0xFF6A5AE0),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$questionCount Questions',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Web-Style Paper Card (Matching User Web Screenshot) ─────────────────────

class _WebStylePaperCard extends StatefulWidget {
  final QuestionPaperModel paper;
  final SubjectInfo subjectTheme;
  final String chapterTitle;
  final VoidCallback onTap;

  const _WebStylePaperCard({
    required this.paper,
    required this.subjectTheme,
    required this.chapterTitle,
    required this.onTap,
  });

  @override
  State<_WebStylePaperCard> createState() => _WebStylePaperCardState();
}

class _WebStylePaperCardState extends State<_WebStylePaperCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Green / Subject Header Banner (Click to Expand / Collapse) ──
            Material(
              color: widget.subjectTheme.color,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.shield_outlined,
                                    color: Colors.white, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  (widget.paper.subjectName ??
                                          widget.subjectTheme.name)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${widget.paper.examYear ?? 2026}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              AnimatedRotation(
                                turns: _isExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.chapterTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                        ),
                      ),
                      if (_isExpanded) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.paper.title.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (widget.paper.examName != null &&
                                widget.paper.examName!.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.paper.examName!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // ── Collapsible Card Body (Description, Stats, View Paper) ──
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.paper.description != null &&
                        widget.paper.description!.isNotEmpty) ...[
                      Text(
                        widget.paper.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Color(0xFF64748B), fontSize: 12),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── 3 Stats Grid ──
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${widget.paper.totalQuestions > 0 ? widget.paper.totalQuestions : widget.paper.questionsCount}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: widget.subjectTheme.color,
                                  ),
                                ),
                                const Text('Questions',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Container(
                              height: 20,
                              width: 1,
                              color: const Color(0xFFE2E8F0)),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${widget.paper.totalMarks}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: widget.subjectTheme.color,
                                  ),
                                ),
                                const Text('Marks',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          Container(
                              height: 20,
                              width: 1,
                              color: const Color(0xFFE2E8F0)),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${widget.paper.durationMinutes}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                                const Text('Minutes',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── View Paper Button ──
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: widget.onTap,
                        icon: const Icon(Icons.visibility_rounded, size: 18),
                        label: const Text(
                          'View Paper',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00CED1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Simple Paper Card (Fallback / Combined view) ─────────────────────────────

class _PaperCard extends StatelessWidget {
  final QuestionPaperModel paper;
  final VoidCallback onTap;

  const _PaperCard({required this.paper, required this.onTap});

  static const Color _primary = Color(0xFF6C63FF);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_primary, Color(0xFF8B7CF8)],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.article_rounded,
                            color: _primary, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              paper.effectiveChapterTitle,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (paper.title != paper.effectiveChapterTitle) ...[
                              const SizedBox(height: 3),
                              Text(
                                paper.title,
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                            if (paper.examName != null) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.school_rounded,
                                      color: _primary, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${paper.examName}${paper.examYear != null ? ' ${paper.examYear}' : ''}',
                                    style: const TextStyle(
                                      color: _primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${paper.id}',
                          style: const TextStyle(
                            color: _primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (paper.description != null &&
                      paper.description!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      paper.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(color: _textMuted, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 14),
                  // Stats row
                  Row(
                    children: [
                      _statChip(
                        Icons.help_outline_rounded,
                        '${paper.totalQuestions} Qs',
                        const Color(0xFF2196F3),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        Icons.timer_rounded,
                        '${paper.durationMinutes} min',
                        const Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 8),
                      _statChip(
                        Icons.stars_rounded,
                        '${paper.totalMarks} marks',
                        const Color(0xFFF5A623),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Attempt button
                  SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_primary, Color(0xFF8B7CF8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_circle_filled_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'View Paper',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
