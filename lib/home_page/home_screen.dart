import 'package:flutter/material.dart';
import '../footer_header/app_footer.dart';
import '../courses/courses_page.dart';
import '../question_papers/question_papers_page.dart';
import '../class/class.dart';
import '../services/auth_provider.dart';
import '../services/class_service.dart';
import '../models/study_class_model.dart';
import 'login_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _surface = Color(0xFFF2F3F8);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _cardBg = Colors.white;

  // ── Dynamic Courses state ──────────────────────────────────────────────────
  bool _isLoadingCourses = true;
  String? _coursesErrorMessage;
  List<StudyClassModel> _apiCourses = [];

  final List<Color> _presetColors = [
    const Color(0xFFE8F5E9), // Light Green
    const Color(0xFFE3F2FD), // Light Blue
    const Color(0xFFFCE4EC), // Light Pink
    const Color(0xFFF3E5F5), // Light Purple
    const Color(0xFFFFF3E0), // Light Orange
    const Color(0xFFE0F7FA), // Light Teal
  ];

  final List<Color> _presetIconColors = [
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFFE91E63), // Pink
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFF00BCD4), // Teal
  ];

  final List<IconData> _presetIcons = [
    Icons.calculate_rounded,
    Icons.language_rounded,
    Icons.memory_rounded,
    Icons.account_tree_rounded,
    Icons.code_rounded,
    Icons.terminal_rounded,
    Icons.auto_stories_rounded,
    Icons.science_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoadingCourses = true;
      _coursesErrorMessage = null;
    });

    final token = AuthProvider.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoadingCourses = false;
        _coursesErrorMessage = 'Authentication token not found.';
      });
      return;
    }

    try {
      final courses = await ClassService.fetchClasses(token: token);
      setState(() {
        _apiCourses = courses;
        _isLoadingCourses = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCourses = false;
        _coursesErrorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  final List<_Practice> _practices = [
    _Practice(
      title: 'Arrays & Hashing',
      questions: 30,
      difficulty: 'Medium',
      minutes: 45,
      icon: Icons.monitor_rounded,
      iconColor: Color(0xFF6C63FF),
      iconBg: Color(0xFFEDE7FF),
    ),
    _Practice(
      title: 'Number Series',
      questions: 25,
      difficulty: 'Easy',
      minutes: 30,
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFF2196F3),
      iconBg: Color(0xFFE3F2FD),
    ),
    _Practice(
      title: 'Logical Reasoning',
      questions: 20,
      difficulty: 'Hard',
      minutes: 60,
      icon: Icons.psychology_rounded,
      iconColor: Color(0xFFE91E63),
      iconBg: Color(0xFFFCE4EC),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    _buildSearchBar(),
                    _buildStatsRow(),
                    _buildSectionHeader('Available Courses'),
                    _buildCoursesList(),
                    _buildSectionHeader('Continue Practising'),
                    _buildPracticeList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentNavIndex,
        onTap: (i) {
          if (i == 1) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const CoursesPage(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            );
          } else if (i == 2) {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (_, animation, __) => const QuestionPapersPage(),
                transitionsBuilder: (_, animation, __, child) =>
                    FadeTransition(opacity: animation, child: child),
                transitionDuration: const Duration(milliseconds: 280),
              ),
            );
          } else if (i == 3) {
            _showProfileMenu();
          } else {
            setState(() => _currentNavIndex = i);
          }
        },
      ),
    );
  }

  // ── Profile menu ──────────────────────────────────────────────────────────
  void _showProfileMenu() {
    final user = AuthProvider.instance.user;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF8B7CF8)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              alignment: Alignment.center,
              child: Text(
                user?.initials ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.name ?? 'User',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              user?.gmail ?? '',
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            ),
            Text(
              '@${user?.userName ?? ''}',
              style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await AuthProvider.instance.logout();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (_, animation, __) => const LoginPage(),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Log Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    final user = AuthProvider.instance.user;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    final emoji = hour < 12 ? '🌤' : hour < 17 ? '☀️' : '🌙';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$greeting ',
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user?.name ?? 'Welcome!',
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          // Avatar — tap to open profile
          GestureDetector(
            onTap: _showProfileMenu,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6C63FF), Color(0xFF8B7CF8)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                user?.initials ?? 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          style: const TextStyle(fontSize: 14, color: _textDark),
          decoration: InputDecoration(
            hintText: 'Search courses, tests...',
            hintStyle: TextStyle(color: _textMuted, fontSize: 14),
            prefixIcon: Icon(Icons.search_rounded, color: _textMuted, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Stats row ──────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _statCell('12', 'Tests Taken'),
            _verticalDivider(),
            _statCell('74%', 'Avg Score'),
            _verticalDivider(),
            _statCell('3', 'Enrolled'),
          ],
        ),
      ),
    );
  }

  Widget _statCell(String value, String label) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: _primary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(width: 1, height: 40, color: const Color(0xFFEEEEEE));
  }

  // ── Section header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: const Text(
              'See all',
              style: TextStyle(
                color: _primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Available Courses horizontal list ──────────────────────────────────────
  Widget _buildCoursesList() {
    if (_isLoadingCourses) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_coursesErrorMessage != null) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _coursesErrorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_apiCourses.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No courses available',
            style: TextStyle(color: _textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 8),
        itemCount: _apiCourses.length,
        itemBuilder: (ctx, i) {
          final course = _apiCourses[i];
          final color = _presetColors[i % _presetColors.length];
          final iconColor = _presetIconColors[i % _presetIconColors.length];
          final icon = _presetIcons[i % _presetIcons.length];
          return _buildCourseCard(course, color, iconColor, icon);
        },
      ),
    );
  }

  Widget _buildCourseCard(
    StudyClassModel course,
    Color bgColor,
    Color iconColor,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassPage(
              classId: course.id,
              initialClassName: course.name,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coloured icon area
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Stack(
                children: [
                  // Decorative blob
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${course.resourcesCount} resources',
                    style: TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Enroll button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_primary, Color(0xFF8B7CF8)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Enroll',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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

  // ── Continue Practising list ───────────────────────────────────────────────
  Widget _buildPracticeList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _practices
            .map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildPracticeCard(p),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPracticeCard(_Practice p) {
    Color diffColor;
    switch (p.difficulty) {
      case 'Easy':
        diffColor = const Color(0xFF4CAF50);
        break;
      case 'Hard':
        diffColor = const Color(0xFFE91E63);
        break;
      default:
        diffColor = const Color(0xFFFF9800);
    }

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: p.iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(p.icon, color: p.iconColor, size: 22),
        ),
        title: Text(
          p.title,
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Text(
                '${p.questions} Qs',
                style: TextStyle(color: _textMuted, fontSize: 11),
              ),
              Text(' · ', style: TextStyle(color: _textMuted, fontSize: 11)),
              Text(
                p.difficulty,
                style: TextStyle(
                  color: diffColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(' · ', style: TextStyle(color: _textMuted, fontSize: 11)),
              Text(
                '${p.minutes} min',
                style: TextStyle(color: _textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
        trailing: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.arrow_forward_ios_rounded,
              size: 13, color: _textMuted),
        ),
        onTap: () {},
      ),
    );
  }

}

// ── Data models ───────────────────────────────────────────────────────────────

class _Practice {
  final String title;
  final int questions;
  final String difficulty;
  final int minutes;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _Practice({
    required this.title,
    required this.questions,
    required this.difficulty,
    required this.minutes,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}
