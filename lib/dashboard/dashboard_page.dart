import 'package:flutter/material.dart';
import '../models/exam_model.dart';
import '../services/exam_service.dart';
import '../services/auth_provider.dart';
import '../footer_header/app_footer.dart';
import 'attempt_detail_dialog.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _surface = Color(0xFFF4F5F9);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _cardBg = Colors.white;

  bool _loading = true;
  String? _error;

  PerformanceAnalyticsModel? _analytics;
  List<ExamAttemptModel> _attempts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = AuthProvider.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please log in to view performance analytics & attempt history.';
      });
      return;
    }

    try {
      final results = await Future.wait([
        ExamService.fetchAnalytics(token: token),
        ExamService.fetchHistory(token: token),
      ]);

      setState(() {
        _analytics = results[0] as PerformanceAnalyticsModel;
        _attempts = results[1] as List<ExamAttemptModel>;
        _loading = false;
      });
    } catch (e) {
      // Fallback with mock or partial data if backend is still populating
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text(
          'Performance Dashboard',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded, color: _primary),
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: _loadData,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    // Section Header: Performance Ratios
                    const Text(
                      'Performance Ratios',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Performance Ratio Cards
                    _buildRatioCards(),
                    const SizedBox(height: 24),

                    // Section Header: Exam Attempt History
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Exam Attempt History',
                          style: TextStyle(
                            color: _textDark,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_attempts.length} Papers Attended',
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Attempt History List
                    _buildHistoryList(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: 2,
        onTap: (i) {
          if (i == 2) return;
          Navigator.of(context).pop(i);
        },
      ),
    );
  }

  // ── Performance Ratios Widgets ──────────────────────────────────────────────
  Widget _buildRatioCards() {
    double mockRatio = _analytics?.mockTestRatio ?? 0.0;
    double combinedRatio = _analytics?.combinedPaperRatio ?? 0.0;
    double overallRatio = _analytics?.overallCombinedRatio ?? 0.0;

    // Smart Fallback: Compute ratios directly from completed attempts if analytics returns 0
    if (mockRatio == 0.0 && combinedRatio == 0.0 && overallRatio == 0.0 && _attempts.isNotEmpty) {
      final completed = _attempts.where((a) => a.status.toLowerCase() == 'completed' || a.status.isEmpty).toList();

      if (completed.isNotEmpty) {
        final mockAttempts = completed.where((a) {
          final type = a.paperType.toLowerCase();
          return type.contains('mock') || type.contains('chapter') || type.contains('subject') || !type.contains('combined');
        }).toList();

        final combinedAttempts = completed.where((a) {
          final type = a.paperType.toLowerCase();
          return type.contains('combined');
        }).toList();

        if (mockAttempts.isNotEmpty) {
          final sumPct = mockAttempts.fold<double>(0.0, (sum, a) => sum + a.percentage);
          mockRatio = sumPct / mockAttempts.length;
        }

        if (combinedAttempts.isNotEmpty) {
          final sumPct = combinedAttempts.fold<double>(0.0, (sum, a) => sum + a.percentage);
          combinedRatio = sumPct / combinedAttempts.length;
        }

        final sumAllPct = completed.fold<double>(0.0, (sum, a) => sum + a.percentage);
        overallRatio = sumAllPct / completed.length;
      }
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Mock Test Ratio',
                subtitle: 'Average Mock Performance',
                value: '${mockRatio.toStringAsFixed(1)}%',
                icon: Icons.track_changes_rounded,
                color: const Color(0xFF6C63FF),
                bgColor: const Color(0xFFEDE7FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Combined Paper Ratio',
                subtitle: 'Subject Combination Score',
                value: '${combinedRatio.toStringAsFixed(1)}%',
                icon: Icons.layers_rounded,
                color: const Color(0xFF00BCD4),
                bgColor: const Color(0xFFE0F7FA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricTile(
          title: 'Overall Both Ratio',
          subtitle: 'Combined Overall Score Across All Question Papers',
          value: '${overallRatio.toStringAsFixed(1)}%',
          icon: Icons.insights_rounded,
          color: const Color(0xFF4CAF50),
          bgColor: const Color(0xFFE8F5E9),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String subtitle,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: isFullWidth ? 22 : 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: _textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── History List Widgets ───────────────────────────────────────────────────
  Widget _buildHistoryList() {
    if (_attempts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          children: [
            Icon(Icons.assignment_outlined, color: _textMuted, size: 40),
            SizedBox(height: 8),
            Text(
              'No exam attempts recorded yet',
              style: TextStyle(
                color: _textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Take a question paper test to track your performance and answer history here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _attempts.map((att) {
        final percentage = att.percentage;
        final Color statusColor = percentage >= 60
            ? const Color(0xFF4CAF50)
            : percentage >= 40
                ? const Color(0xFFFF9800)
                : const Color(0xFFF44336);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => AttemptDetailDialog(attempt: att),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${att.paperType.toUpperCase()} • ${att.completedAt ?? att.startedAt ?? 'Recent'}',
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20, color: Color(0xFFF0F0F0)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatChip(
                          label: 'Score',
                          value: '${att.score} / ${att.totalMarks}',
                          color: _primary,
                        ),
                        _buildStatChip(
                          label: 'Correct',
                          value: '${att.correctAnswers}',
                          color: const Color(0xFF4CAF50),
                        ),
                        _buildStatChip(
                          label: 'Wrong',
                          value: '${att.wrongAnswers}',
                          color: const Color(0xFFF44336),
                        ),
                        _buildStatChip(
                          label: 'Answered',
                          value: '${att.totalAnswered} / ${att.totalQuestions}',
                          color: _textDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: _textMuted, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
