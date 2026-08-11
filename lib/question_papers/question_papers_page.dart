import 'package:flutter/material.dart';
import '../services/question_paper_service.dart';
import '../services/auth_provider.dart';
import '../models/question_paper_model.dart';
import '../footer_header/app_footer.dart';
import 'question_paper_detail_page.dart';

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

  List<QuestionPaperModel> _papers = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;
  final int _navIndex = 2;

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
          token: token, page: _currentPage);
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
          token: token, page: _currentPage + 1);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == _navIndex) return;
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.description_rounded,
                color: _primary, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Question Papers',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Browse & attempt NEET mock tests',
                  style: TextStyle(color: _textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _fetchPapers(refresh: true),
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            splashRadius: 22,
          ),
        ],
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
                child: const Text('Retry',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }
    if (_papers.isEmpty) {
      return const Center(
        child: Text('No question papers available.',
            style: TextStyle(color: _textMuted)),
      );
    }
    return RefreshIndicator(
      color: _primary,
      onRefresh: () => _fetchPapers(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: _papers.length + (_loadingMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == _papers.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child:
                  Center(child: CircularProgressIndicator(color: _primary)),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PaperCard(
              paper: _papers[i],
              onTap: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (_, animation, __) =>
                        QuestionPaperDetailPage(paperId: _papers[i].id),
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

// ── Paper Card ────────────────────────────────────────────────────────────────

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
                              paper.title,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
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
                      style: const TextStyle(
                          color: _textMuted, fontSize: 12),
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
