import 'package:flutter/material.dart';
import '../footer_header/app_footer.dart';
import '../courses/courses_page.dart';
import '../question_papers/question_papers_page.dart';
import '../dashboard/dashboard_page.dart';
import '../profile/profile_details_page.dart';
import '../profile/health_support_page.dart';
import '../class/class.dart';
import '../services/auth_provider.dart';
import '../services/class_service.dart';
import '../services/resource_service.dart';
import '../models/study_class_model.dart';
import '../models/resource_model.dart';
import '../models/question_paper_model.dart';
import '../services/auth_service.dart';
import '../services/question_paper_service.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
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
  String? _coursesErrorMessage = null;
  List<StudyClassModel> _apiCourses = [];

  // ── Home Page Media (Photos & Videos) state ─────────────────────────────────
  bool _isLoadingResources = true;
  List<ResourceModel> _resources = [];

  // ── Dynamic Question Papers & Stats state ──────────────────────────────────
  bool _isLoadingQuestionPaperStats = true;
  int _totalMockTests = 0;
  int _totalPracticeQuestions = 0;

  Map<String, List<StudyClassModel>> get _groupedCourses {
    final Map<String, List<StudyClassModel>> groups = {};
    for (final course in _apiCourses) {
      final subjectName = course.subject ?? 'General';
      groups.putIfAbsent(subjectName, () => []).add(course);
    }
    return groups;
  }

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

  @override
  void initState() {
    super.initState();
    _fetchCourses();
    _fetchResources();
    _fetchQuestionPaperStats();
  }

  Future<void> _fetchQuestionPaperStats() async {
    final token = AuthProvider.instance.token;
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _isLoadingQuestionPaperStats = false);
      return;
    }

    try {
      final res = await QuestionPaperService.fetchList(token: token, page: 1);
      final int totalPapers = (res['total'] as num? ?? 0).toInt();
      final List<QuestionPaperModel> papers =
          (res['papers'] as List<dynamic>? ?? []).cast<QuestionPaperModel>();

      int sumQ = 0;
      for (final p in papers) {
        final q = p.totalQuestions > 0 ? p.totalQuestions : p.questionsCount;
        sumQ += q;
      }

      int estimatedTotalQuestions = sumQ;
      if (papers.isNotEmpty && totalPapers > papers.length) {
        final double avgQ = sumQ / papers.length;
        estimatedTotalQuestions = (avgQ * totalPapers).round();
      }

      if (mounted) {
        setState(() {
          _totalMockTests = totalPapers > 0 ? totalPapers : papers.length;
          _totalPracticeQuestions = estimatedTotalQuestions;
          _isLoadingQuestionPaperStats = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingQuestionPaperStats = false);
      }
    }
  }

  String _formatCount(int count, {bool isK = false}) {
    if (count <= 0) return '0+';
    if (isK && count >= 1000) {
      if (count >= 10000) {
        return '${(count / 1000).toStringAsFixed(0)}K+';
      } else {
        final double k = count / 1000;
        return k == k.roundToDouble()
            ? '${k.toInt()}K+'
            : '${k.toStringAsFixed(1)}K+';
      }
    }
    return '$count+';
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

  Future<void> _fetchResources() async {
    final token = AuthProvider.instance.token;
    if (token == null || token.isEmpty) {
      setState(() => _isLoadingResources = false);
      return;
    }

    try {
      final list = await ResourceService.fetchResources(token: token);
      setState(() {
        _resources = list;
        _isLoadingResources = false;
      });
    } catch (_) {
      setState(() => _isLoadingResources = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: _primary,
                onRefresh: () async {
                  await _fetchCourses();
                  await _fetchResources();
                  await _fetchQuestionPaperStats();
                },
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(),
                      _buildPhotosSlider(),
                      _buildVideosSection(),
                      const SizedBox(height: 16),
                      _buildCoursesList(),
                      const SizedBox(height: 20),
                      _buildConnectAndStatsSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _currentNavIndex,
        onTap: _onFooterTap,
      ),
    );
  }

  void _onFooterTap(int i) async {
    if (i == 1) {
      // Tests Tab
      final targetIndex = await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const QuestionPapersPage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      );
      if (targetIndex is int) {
        _onFooterTap(targetIndex);
      }
    } else if (i == 2) {
      // Dashboard Tab
      final targetIndex = await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, animation, __) => const DashboardPage(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 280),
        ),
      );
      if (targetIndex is int) {
        _onFooterTap(targetIndex);
      }
    } else if (i == 3) {
      // Profile Tab
      _showProfileMenu();
    } else {
      setState(() => _currentNavIndex = i);
    }
  }

  // ── Profile menu ──────────────────────────────────────────────────────────
  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ProfileSheetContent(),
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
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

  // ── Photos / Banner Slider (Directly from Backend Uploads) ──────────────
  Widget _buildPhotosSlider() {
    final photos = _resources.where((r) => r.isImage).toList();
    if (_isLoadingResources) {
      return Container(
        height: 160,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(color: _primary)),
      );
    }
    if (photos.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Column(
        children: photos.map((photo) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            height: 170,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    photo.fileUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF6C63FF).withOpacity(0.1),
                      child: const Icon(Icons.image,
                          color: _primary, size: 40),
                    ),
                  ),
                  if (photo.title.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Text(
                          photo.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Videos Section (Directly from Backend Uploads) ──────────────────────
  Widget _buildVideosSection() {
    final videos = _resources.where((r) => r.isVideo).toList();
    if (videos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 200,
      child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 8),
            itemCount: videos.length,
            itemBuilder: (ctx, i) {
              final video = videos[i];
              return GestureDetector(
                onTap: () => _openVideoModal(video),
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video Thumbnail Area
                      SizedBox(
                        height: 120,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              child: video.thumbnailUrl != null &&
                                      video.thumbnailUrl!.isNotEmpty
                                  ? Image.network(
                                      video.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _videoPlaceholder(),
                                    )
                                  : _videoPlaceholder(),
                            ),
                            // Play Icon Overlay
                            Center(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Info Area
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              video.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textDark,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              video.description ??
                                  video.subject ??
                                  'Video Lecture',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _textMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }

  Widget _videoPlaceholder() {
    return Container(
      color: const Color(0xFF1E1E2E),
      child: const Center(
        child: Icon(Icons.movie_creation_rounded,
            color: Colors.white54, size: 36),
      ),
    );
  }

  void _openVideoModal(ResourceModel video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AppVideoPlayerModal(video: video),
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

    final grouped = _groupedCourses;

    if (grouped.isEmpty) {
      return const SizedBox.shrink();
    }

    final subjectKeys = grouped.keys.toList();

    return SizedBox(
      height: 195,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(left: 20, right: 8),
        itemCount: subjectKeys.length,
        itemBuilder: (ctx, i) {
          final subjectName = subjectKeys[i];
          final classes = grouped[subjectName]!;
          final color = _presetColors[i % _presetColors.length];
          final iconColor = _presetIconColors[i % _presetIconColors.length];
          return _buildSubjectCard(subjectName, classes, color, iconColor);
        },
      ),
    );
  }

  Widget _buildSubjectCard(
    String subjectName,
    List<StudyClassModel> classes,
    Color bgColor,
    Color iconColor,
  ) {
    final count = classes.length;
    final countText = count == 1 ? '1 Class' : '$count Classes';

    return GestureDetector(
      onTap: () {
        _showClassesBottomSheet(subjectName, classes);
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
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
                      child: Icon(Icons.folder_rounded,
                          color: iconColor, size: 28),
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
                    subjectName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    countText,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Open Folder',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 9,
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

  void _showClassesBottomSheet(
      String subjectName, List<StudyClassModel> classes) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.folder_open_rounded,
                      color: _primary, size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      subjectName,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${classes.length} Available Classes',
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, index) {
                    final studyClass = classes[index];
                    final color =
                        _presetIconColors[index % _presetIconColors.length];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ClassPage(
                              classId: studyClass.id,
                              initialClassName: studyClass.name,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: Colors.black.withOpacity(0.03)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.class_rounded,
                                  color: color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studyClass.name,
                                    style: const TextStyle(
                                      color: _textDark,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (studyClass.description != null &&
                                      studyClass.description!.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      studyClass.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _textMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.arrow_forward_ios_rounded,
                                color: _textMuted.withOpacity(0.7), size: 14),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Connect With Us & Stats Section ─────────────────────────────────────────
  Widget _buildConnectAndStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.black.withOpacity(0.04)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Connect With Us',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Social Media Cards Row
            Row(
              children: [
                Expanded(
                  child: _buildSocialCard(
                    title: 'Instagram',
                    subtitle: 'Follow us',
                    url: 'https://instagram.com',
                    iconWidget: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: [
                            Color(0xFF833AB4),
                            Color(0xFFE1306C),
                            Color(0xFFFD1D1D),
                            Color(0xFFF77737),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSocialCard(
                    title: 'Telegram',
                    subtitle: 'Join our channel',
                    url: 'https://t.me',
                    iconWidget: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2AABEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildSocialCard(
                    title: 'Facebook',
                    subtitle: 'Follow us',
                    url: 'https://facebook.com',
                    iconWidget: Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1877F2),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.facebook,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Statistics Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFECEFF8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.menu_book_rounded,
                      iconBg: const Color(0xFFEDE7FF),
                      iconColor: _primary,
                      number: _isLoadingQuestionPaperStats
                          ? '...'
                          : _formatCount(_totalMockTests),
                      label: 'Mock Tests',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.check_rounded,
                      iconBg: const Color(0xFF00C853),
                      iconColor: Colors.white,
                      number: _isLoadingQuestionPaperStats
                          ? '...'
                          : _formatCount(_totalPracticeQuestions, isK: true),
                      label: 'Practice Questions',
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.emoji_events_rounded,
                      iconBg: const Color(0xFFEDE7FF),
                      iconColor: _primary,
                      number: '5000+',
                      label: 'Rank Boosters',
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

  Widget _buildSocialCard({
    required String title,
    required String subtitle,
    required String url,
    required Widget iconWidget,
  }) {
    return GestureDetector(
      onTap: () => _launchSocialURL(url),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFECEFF8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                iconWidget,
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.north_east_rounded,
                    color: Color(0xFF2E7D32),
                    size: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textDark,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String number,
    required String label,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              color: iconColor,
              size: 17,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                number,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _launchSocialURL(String urlString) async {
    final Uri uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Could not launch $urlString: $e');
    }
  }
}

class _ProfileSheetContent extends StatelessWidget {
  const _ProfileSheetContent();

  @override
  Widget build(BuildContext context) {
    final user = AuthProvider.instance.user;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileDetailsPage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.transparent,
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Student',
                          style: const TextStyle(
                            color: Color(0xFF1A1A2E),
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.gmail ?? '',
                          style: const TextStyle(
                            color: Color(0xFF9E9E9E),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'View Profile & Change Password ›',
                          style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFF9E9E9E), size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.health_and_safety_rounded,
                color: Color(0xFF6C63FF), size: 22),
            title: const Text(
              'Health & Support',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: const Text(
              'App status, FAQs & customer support',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HealthSupportPage()),
              );
            },
          ),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading:
                const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            title: const Text(
              'Sign Out',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            onTap: () async {
              Navigator.of(context).pop();
              await AuthProvider.instance.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ── Interactive Video Player Modal ───────────────────────────────────────────

class AppVideoPlayerModal extends StatefulWidget {
  final ResourceModel video;

  const AppVideoPlayerModal({super.key, required this.video});

  @override
  State<AppVideoPlayerModal> createState() => _AppVideoPlayerModalState();
}

class _AppVideoPlayerModalState extends State<AppVideoPlayerModal> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final uri = Uri.parse(widget.video.fileUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller.initialize();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
        _controller.play();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = true;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_initialized) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.play_circle_fill_rounded,
                  color: Color(0xFFFF4757), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.video.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          if (widget.video.description != null &&
              widget.video.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.video.description!,
              style: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),

          // Video Player Box
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: _buildPlayerContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerContent() {
    if (_error) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.movie_creation_outlined,
                  color: Colors.white70, size: 36),
              const SizedBox(height: 8),
              const Text(
                'Could not stream video directly in player.',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  final uri = Uri.parse(widget.video.fileUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 16),
                label: const Text('Play Video Externally'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4757),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4757)),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio > 0
              ? _controller.value.aspectRatio
              : 16 / 9,
          child: VideoPlayer(_controller),
        ),

        // Controls Overlay
        GestureDetector(
          onTap: () {
            setState(() {
              if (_controller.value.isPlaying) {
                _controller.pause();
              } else {
                _controller.play();
              }
            });
          },
          child: Container(
            color: Colors.transparent,
            child: AnimatedOpacity(
              opacity: _controller.value.isPlaying ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
            ),
          ),
        ),

        // Bottom Progress Bar Indicator
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            colors: const VideoProgressColors(
              playedColor: Color(0xFFFF4757),
              bufferedColor: Colors.white30,
              backgroundColor: Colors.white10,
            ),
          ),
        ),
      ],
    );
  }
}
