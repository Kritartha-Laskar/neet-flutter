import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../config/api_config.dart';
import '../models/resource_model.dart';
import '../models/study_class_model.dart';
import '../models/question_paper_model.dart';
import '../services/auth_provider.dart';
import '../services/class_service.dart';
import '../footer_header/app_footer.dart';

class ClassPage extends StatefulWidget {
  final int? classId;
  final String? initialClassName;

  const ClassPage({
    super.key,
    this.classId,
    this.initialClassName,
  });

  @override
  State<ClassPage> createState() => _ClassPageState();
}

class _ClassPageState extends State<ClassPage> {
  int _navIndex = 0;
  bool _isLoadingClasses = true;
  bool _isLoadingDetail = false;
  String? _errorMessage;

  List<StudyClassModel> _allClasses = [];
  StudyClassModel? _selectedClass;
  ResourceModel? _activeVideoResource;

  // For interactive inline questions
  final Map<int, int> _playlistSelectedAnswers = {};

  // Video Controller State
  VideoPlayerController? _videoPlayerController;
  bool _isVideoInitialized = false;
  bool _isVideoError = false;
  bool _isPlaying = false;

  // Zoom, Gestures & Slider Scrubbing State
  bool _isFitCover = false;
  bool _showLeftSeekOverlay = false;
  bool _showRightSeekOverlay = false;
  bool _isDraggingSlider = false;
  double _dragProgress = 0.0;
  double _currentSpeed = 1.0;

  // Filter by subject
  String _selectedSubjectFilter = 'All';

  // ── Brand colours ──────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF6C63FF);
  static const Color _surface = Color(0xFFF4F6F9);
  static const Color _textDark = Color(0xFF1A1A2E);
  static const Color _textMuted = Color(0xFF8E8E93);
  static const Color _cardBg = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadClassesData();
  }

  @override
  void dispose() {
    _disposeVideoController();
    super.dispose();
  }

  void _disposeVideoController() {
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _isVideoInitialized = false;
    _isPlaying = false;
  }

  Future<void> _loadClassesData() async {
    setState(() {
      _isLoadingClasses = true;
      _errorMessage = null;
    });

    final token = AuthProvider.instance.token;
    if (token == null || token.isEmpty) {
      setState(() {
        _isLoadingClasses = false;
        _errorMessage = 'Authentication required. Please log in.';
      });
      return;
    }

    try {
      final classes = await ClassService.fetchClasses(token: token);
      setState(() {
        _allClasses = classes;
        _isLoadingClasses = false;
      });

      if (classes.isNotEmpty) {
        int targetId = widget.classId ?? classes.first.id;
        final found = classes.firstWhere(
          (c) => c.id == targetId,
          orElse: () => classes.first,
        );
        _selectClass(found);
      }
    } catch (e) {
      setState(() {
        _isLoadingClasses = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _selectClass(StudyClassModel studyClass) async {
    setState(() {
      _selectedClass = studyClass;
      _isLoadingDetail = true;
      _errorMessage = null;
      _selectedSubjectFilter = 'All';
    });

    _disposeVideoController();

    final token = AuthProvider.instance.token;
    if (token == null) return;

    try {
      final detail = await ClassService.fetchClassDetail(
        token: token,
        id: studyClass.id,
      );
      setState(() {
        _selectedClass = detail;
        _isLoadingDetail = false;
      });

      // Automatically play the first video material if available
      final videoMaterials = detail.materials.where((m) => m.isVideo).toList();
      if (videoMaterials.isNotEmpty) {
        _playVideo(videoMaterials.first);
      }
    } catch (e) {
      setState(() {
        _isLoadingDetail = false;
        _errorMessage = 'Failed to load class materials: $e';
      });
    }
  }

  Future<void> _playVideo(ResourceModel resource) async {
    if (!resource.isVideo) return;

    _disposeVideoController();

    debugPrint('🎥 [ClassPage] Attempting to play video URL: ${resource.fileUrl}');

    setState(() {
      _activeVideoResource = resource;
      _isVideoInitialized = false;
      _isVideoError = false;
      _isPlaying = false;
      _currentSpeed = 1.0;
    });

    try {
      final Uri videoUri = Uri.parse(resource.fileUrl);
      final controller = VideoPlayerController.networkUrl(videoUri);
      _videoPlayerController = controller;

      await controller.initialize();
      controller.addListener(_videoListener);

      setState(() {
        _isVideoInitialized = true;
      });

      controller.play();
      debugPrint('✅ [ClassPage] Video initialized and playing successfully!');
    } catch (e, stack) {
      debugPrint('❌ [ClassPage] Error initializing video player for ${resource.fileUrl}: $e');
      debugPrint(stack.toString());
      setState(() {
        _isVideoError = true;
        _isVideoInitialized = false;
      });
    }
  }

  void _videoListener() {
    if (_videoPlayerController != null && mounted && !_isDraggingSlider) {
      setState(() {
        _isPlaying = _videoPlayerController!.value.isPlaying;
      });
    }
  }

  void _seekRelative(int seconds) {
    if (_videoPlayerController == null || !_isVideoInitialized) return;
    final current = _videoPlayerController!.value.position;
    final duration = _videoPlayerController!.value.duration;
    var target = current + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > duration) target = duration;

    _videoPlayerController!.seekTo(target);

    if (seconds < 0) {
      setState(() {
        _showLeftSeekOverlay = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showLeftSeekOverlay = false);
      });
    } else {
      setState(() {
        _showRightSeekOverlay = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showRightSeekOverlay = false);
      });
    }
  }

  void _changePlaybackSpeed(double speed) {
    if (_videoPlayerController == null || !_isVideoInitialized) return;
    setState(() {
      _currentSpeed = speed;
    });
    _videoPlayerController!.setPlaybackSpeed(speed);
  }

  Future<void> _openFullscreenPlayer() async {
    if (_videoPlayerController == null || !_isVideoInitialized) return;

    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FullscreenVideoPage(
          controller: _videoPlayerController!,
          resource: _activeVideoResource,
          isFitCover: _isFitCover,
          onToggleFitCover: () {
            setState(() {
              _isFitCover = !_isFitCover;
            });
          },
          onSeekRelative: _seekRelative,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );

    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) setState(() {});
  }

  List<String> get _availableSubjects {
    if (_selectedClass == null) return ['All'];
    final set = <String>{'All'};
    for (var item in _selectedClass!.playlist) {
      if (item.subject != null && item.subject!.trim().isNotEmpty) {
        set.add(item.subject!.trim());
      }
    }
    return set.toList();
  }

  List<PlaylistItemModel> get _filteredPlaylist {
    if (_selectedClass == null) return [];
    var list = _selectedClass!.playlist;
    if (_selectedSubjectFilter != 'All') {
      list = list
          .where((item) =>
              item.subject?.toLowerCase() == _selectedSubjectFilter.toLowerCase())
          .toList();
    }
    // ensure order by sort_order
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _isLoadingClasses
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary))
                  : _errorMessage != null
                      ? _buildErrorView()
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildClassSelectorDropdown(),
                              if (_activeVideoResource != null ||
                                  _isVideoInitialized ||
                                  _isVideoError)
                                _buildVideoPlayerSection(),
                              _buildSubjectTabs(),
                              _buildMaterialsHeader(),
                              _buildMaterialsList(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: _navIndex,
        onTap: (i) {
          if (i == 0) {
            Navigator.of(context).pop();
          } else {
            setState(() => _navIndex = i);
          }
        },
      ),
    );
  }

  // ── Header Bar ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 20, color: _textDark),
            splashRadius: 24,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedClass?.name ?? widget.initialClassName ?? 'Study Class Materials',
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _selectedClass != null
                      ? '${_selectedClass!.materials.length} Materials Available'
                      : 'Load study resources & video lectures',
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE7FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.video_library_rounded, color: _primary, size: 16),
                SizedBox(width: 4),
                Text(
                  'Live API',
                  style: TextStyle(
                    color: _primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Class Selector Dropdown / Horizontal Bar ────────────────────────────────
  Widget _buildClassSelectorDropdown() {
    if (_allClasses.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
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
            const Text(
              'SELECT STUDY CLASS',
              style: TextStyle(
                color: _textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _allClasses.length,
                itemBuilder: (context, index) {
                  final c = _allClasses[index];
                  final isSelected = c.id == _selectedClass?.id;
                  return GestureDetector(
                    onTap: () => _selectClass(c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary : const Color(0xFFF0F2F6),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          c.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : _textDark,
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
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

  // ── Video Player Component ──────────────────────────────────────────────────
  Widget _buildVideoPlayerSection() {
    final resource = _activeVideoResource;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Aspect ratio video view with Zoom Cover and Double Tap
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isVideoInitialized && _videoPlayerController != null)
                    ClipRect(
                      child: SizedBox.expand(
                        child: FittedBox(
                          fit: _isFitCover ? BoxFit.cover : BoxFit.contain,
                          child: SizedBox(
                            width: _videoPlayerController!.value.size.width > 0
                                ? _videoPlayerController!.value.size.width
                                : 16,
                            height: _videoPlayerController!.value.size.height > 0
                                ? _videoPlayerController!.value.size.height
                                : 9,
                            child: VideoPlayer(_videoPlayerController!),
                          ),
                        ),
                      ),
                    )
                  else if (_isVideoError)
                    Container(
                      color: const Color(0xFF1E1E2C),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.video_file_rounded,
                              color: Colors.amberAccent, size: 40),
                          const SizedBox(height: 8),
                          const Text(
                            'Unable to play video in browser',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            resource?.rawFileUrl.endsWith('.mkv') == true || resource?.rawFileUrl.endsWith('.avi') == true
                                ? 'The uploaded file is in MKV/AVI format. Web browsers require MP4 (H.264) format to stream videos.'
                                : 'Please verify the file path on the server or ensure it is a valid MP4 video.',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 11),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          if (resource != null)
                            ElevatedButton.icon(
                              onPressed: () => _playVideo(resource),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Retry'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF1A1A2E),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading ${resource?.title ?? "Video"}...',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Left & Right double-tap gesture zones (Left: -10s, Right: +10s)
                  if (_isVideoInitialized && _videoPlayerController != null)
                    Positioned.fill(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                setState(() {
                                  if (_isPlaying) {
                                    _videoPlayerController!.pause();
                                  } else {
                                    _videoPlayerController!.play();
                                  }
                                });
                              },
                              onDoubleTap: () => _seekRelative(-10),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () {
                                setState(() {
                                  if (_isPlaying) {
                                    _videoPlayerController!.pause();
                                  } else {
                                    _videoPlayerController!.play();
                                  }
                                });
                              },
                              onDoubleTap: () => _seekRelative(10),
                              child: Container(color: Colors.transparent),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Left Double Tap Overlay Indicator (-10s)
                  if (_showLeftSeekOverlay)
                    Positioned(
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 24),
                            SizedBox(width: 4),
                            Text(
                              '-10s',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Right Double Tap Overlay Indicator (+10s)
                  if (_showRightSeekOverlay)
                    Positioned(
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+10s',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.fast_forward_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                      ),
                    ),

                  // Center Play/Pause button when paused
                  if (_isVideoInitialized && _videoPlayerController != null && !_isPlaying)
                    IgnorePointer(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: _primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Video Controls Bar & Metadata
            if (resource != null)
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFF1E1E2C),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PLAYING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            resource.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (resource.subject != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              resource.subject!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),

                    if (_isVideoInitialized && _videoPlayerController != null) ...[
                      const SizedBox(height: 8),

                      // Interactive Progress Slider with Smooth Dragging
                      ValueListenableBuilder(
                        valueListenable: _videoPlayerController!,
                        builder: (context, VideoPlayerValue value, child) {
                          final duration = value.duration.inMilliseconds;
                          final position = value.position.inMilliseconds;
                          double progress = (duration > 0)
                              ? (position / duration).clamp(0.0, 1.0)
                              : 0.0;

                          final displayValue = _isDraggingSlider
                              ? _dragProgress.clamp(0.0, 1.0)
                              : progress;

                          return Column(
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7),
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14),
                                  activeTrackColor: _primary,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: _primary,
                                ),
                                child: Slider(
                                  value: displayValue,
                                  onChangeStart: (val) {
                                    setState(() {
                                      _isDraggingSlider = true;
                                      _dragProgress = val;
                                    });
                                  },
                                  onChanged: (val) {
                                    setState(() {
                                      _dragProgress = val;
                                    });
                                  },
                                  onChangeEnd: (val) {
                                    final targetMs = (val * duration).toInt();
                                    _videoPlayerController!.seekTo(
                                        Duration(milliseconds: targetMs));
                                    setState(() {
                                      _isDraggingSlider = false;
                                    });
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                        style: const TextStyle(
                                            color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),

                                  Row(
                                    children: [
                                      // Rewind 10s Button
                                      IconButton(
                                        icon: const Icon(Icons.replay_10_rounded,
                                            color: Colors.white70, size: 20),
                                        tooltip: 'Rewind 10s',
                                        onPressed: () => _seekRelative(-10),
                                      ),

                                      // Fast Forward 10s Button
                                      IconButton(
                                        icon: const Icon(Icons.forward_10_rounded,
                                            color: Colors.white70, size: 20),
                                        tooltip: 'Fast Forward 10s',
                                        onPressed: () => _seekRelative(10),
                                      ),

                                      // Speed Selector (1x, 1.25x, 1.5x, 2x)
                                      PopupMenuButton<double>(
                                        tooltip: 'Playback Speed',
                                        initialValue: _currentSpeed,
                                        onSelected: _changePlaybackSpeed,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '${_currentSpeed == 1.0 ? "1x" : "${_currentSpeed}x"}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                              value: 1.0, child: Text('1.0x (Normal)')),
                                          const PopupMenuItem(
                                              value: 1.25, child: Text('1.25x Speed')),
                                          const PopupMenuItem(
                                              value: 1.5, child: Text('1.5x Speed')),
                                          const PopupMenuItem(
                                              value: 2.0, child: Text('2.0x Speed')),
                                        ],
                                      ),

                                      const SizedBox(width: 4),

                                      // Zoom to fill button
                                      IconButton(
                                        icon: Icon(
                                          _isFitCover
                                              ? Icons.zoom_in_map_rounded
                                              : Icons.zoom_out_map_rounded,
                                          color: Colors.white70,
                                          size: 20,
                                        ),
                                        tooltip: _isFitCover
                                            ? 'Fit to Screen'
                                            : 'Zoom Whole Screen',
                                        onPressed: () {
                                          setState(() {
                                            _isFitCover = !_isFitCover;
                                          });
                                        },
                                      ),

                                      // Landscape / Fullscreen button
                                      IconButton(
                                        icon: const Icon(
                                          Icons.fullscreen_rounded,
                                          color: Colors.white70,
                                          size: 22,
                                        ),
                                        tooltip: 'Landscape Fullscreen',
                                        onPressed: _openFullscreenPlayer,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // ── Subject Tabs Filter ────────────────────────────────────────────────────
  Widget _buildSubjectTabs() {
    final subjects = _availableSubjects;
    if (subjects.length <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SizedBox(
        height: 34,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: subjects.length,
          itemBuilder: (context, index) {
            final sub = subjects[index];
            final isSelected = sub == _selectedSubjectFilter;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedSubjectFilter = sub;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? _textDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _textDark : const Color(0xFFE0E0E0),
                  ),
                ),
                child: Text(
                  sub,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textDark,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Materials Header ───────────────────────────────────────────────────────
  Widget _buildMaterialsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Course Materials & Lectures',
            style: TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEAEA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'In Order',
              style: TextStyle(
                color: _textDark,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Materials Serial List ─────────────────────────────────────────────────
  Widget _buildMaterialsList() {
    if (_isLoadingDetail) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    final list = _filteredPlaylist;
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            children: [
              Icon(Icons.folder_open_rounded, size: 48, color: _textMuted),
              SizedBox(height: 12),
              Text(
                'No study materials found for this class.',
                style: TextStyle(
                    color: _textDark,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        if (item.isResource && item.resource != null) {
          final material = item.resource!;
          final isCurrentlyPlaying = _activeVideoResource?.id == material.id;
          return _buildMaterialCard(
            material: material,
            orderIndex: index + 1,
            isPlaying: isCurrentlyPlaying,
          );
        } else if (item.isQuestion && item.question != null) {
          return _buildQuestionCard(item, index + 1);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildQuestionCard(PlaylistItemModel item, int orderIndex) {
    final q = item.question;
    if (q == null) return const SizedBox.shrink();

    final selectedAnswerId = _playlistSelectedAnswers[q.id];
    final isAnswered = selectedAnswerId != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          // Header of MCQ card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDE7FF),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#$orderIndex',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.quiz_rounded, color: _primary, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'MCQ QUIZ',
                          style: TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.subject != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.subject!,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Question text
          Text(
            q.question,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          // Option rows
          ...q.options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final letters = ['A', 'B', 'C', 'D', 'E'];
            final letter = idx < letters.length ? letters[idx] : '${idx + 1}';

            final isSelected = selectedAnswerId == opt.id;
            final isCorrect = opt.isCorrect;

            // Determine option styles
            Color optionBg = Colors.white;
            Color borderColor = const Color(0xFFE2E4E8);
            Color textColor = _textDark;
            Widget checkIcon = const SizedBox.shrink();

            if (isAnswered) {
              if (isCorrect) {
                optionBg = const Color(0xFFE8F5E9);
                borderColor = const Color(0xFF4CAF50);
                textColor = const Color(0xFF2E7D32);
                checkIcon = const Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 18);
              } else if (isSelected) {
                optionBg = const Color(0xFFFFEBEE);
                borderColor = const Color(0xFFEF5350);
                textColor = const Color(0xFFC62828);
                checkIcon = const Icon(Icons.cancel_rounded, color: Color(0xFFEF5350), size: 18);
              }
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: isAnswered
                    ? null
                    : () {
                        setState(() {
                          _playlistSelectedAnswers[q.id] = opt.id;
                        });
                      },
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: optionBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAnswered && isCorrect
                              ? const Color(0xFF4CAF50)
                              : isAnswered && isSelected
                                  ? const Color(0xFFEF5350)
                                  : const Color(0xFFF0F2F6),
                          border: isAnswered && (isCorrect || isSelected)
                              ? null
                              : Border.all(color: const Color(0xFFD2D4D8)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          letter,
                          style: TextStyle(
                            color: isAnswered && (isCorrect || isSelected)
                                ? Colors.white
                                : _textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt.answer,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 12.5,
                            fontWeight: isSelected || (isAnswered && isCorrect)
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      checkIcon,
                    ],
                  ),
                ),
              ),
            );
          }),
          if (isAnswered) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _playlistSelectedAnswers.remove(q.id);
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: _primary),
                  label: const Text(
                    'Reset Question',
                    style: TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMaterialCard({
    required ResourceModel material,
    required int orderIndex,
    required bool isPlaying,
  }) {
    IconData icon;
    Color iconColor;
    Color iconBg;

    if (material.isVideo) {
      icon = Icons.play_circle_fill_rounded;
      iconColor = const Color(0xFF6C63FF);
      iconBg = const Color(0xFFEDE7FF);
    } else if (material.isPdf) {
      icon = Icons.picture_as_pdf_rounded;
      iconColor = const Color(0xFFE91E63);
      iconBg = const Color(0xFFFCE4EC);
    } else {
      icon = Icons.image_rounded;
      iconColor = const Color(0xFF4CAF50);
      iconBg = const Color(0xFFE8F5E9);
    }

    return GestureDetector(
      onTap: () {
        if (material.isVideo) {
          _playVideo(material);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opening ${material.type.toUpperCase()}: ${material.title}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPlaying ? const Color(0xFFF4F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isPlaying ? _primary : Colors.transparent,
            width: isPlaying ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Order index badge #1, #2...
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isPlaying ? _primary : const Color(0xFFF0F2F6),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '#$orderIndex',
                  style: TextStyle(
                    color: isPlaying ? Colors.white : _textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Material type icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),

            // Content Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          material.title,
                          style: TextStyle(
                            color: _textDark,
                            fontSize: 14,
                            fontWeight: isPlaying
                                ? FontWeight.w800
                                : FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPlaying)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PLAYING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (material.subject != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEEEEE),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            material.subject!,
                            style: const TextStyle(
                              color: _textDark,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        material.fileSizeHuman ?? material.type.toUpperCase(),
                        style: const TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Play / View Arrow Action
            Icon(
              material.isVideo
                  ? (isPlaying
                      ? Icons.equalizer_rounded
                      : Icons.play_arrow_rounded)
                  : Icons.arrow_forward_ios_rounded,
              color: isPlaying ? _primary : _textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ── Error View ────────────────────────────────────────────────────────────
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 54, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'An error occurred while loading classes',
              style: const TextStyle(
                  color: _textDark, fontWeight: FontWeight.w700, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadClassesData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen Landscape Video Player Page
// ─────────────────────────────────────────────────────────────────────────────
class FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;
  final ResourceModel? resource;
  final bool isFitCover;
  final VoidCallback onToggleFitCover;
  final Function(int seconds) onSeekRelative;

  const FullscreenVideoPage({
    super.key,
    required this.controller,
    this.resource,
    required this.isFitCover,
    required this.onToggleFitCover,
    required this.onSeekRelative,
  });

  @override
  State<FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<FullscreenVideoPage> {
  late bool _isFitCover;
  bool _showLeftSeekOverlay = false;
  bool _showRightSeekOverlay = false;
  bool _showControls = true;
  bool _isDraggingSlider = false;
  double _dragProgress = 0.0;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _isFitCover = widget.isFitCover;
    widget.controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted && !_isDraggingSlider) {
      setState(() {});
    }
  }

  void _seekRelative(int seconds) {
    widget.onSeekRelative(seconds);
    if (seconds < 0) {
      setState(() => _showLeftSeekOverlay = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showLeftSeekOverlay = false);
      });
    } else {
      setState(() => _showRightSeekOverlay = true);
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showRightSeekOverlay = false);
      });
    }
  }

  void _changePlaybackSpeed(double speed) {
    setState(() {
      _currentSpeed = speed;
    });
    widget.controller.setPlaybackSpeed(speed);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final isPlaying = controller.value.isPlaying;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video View with Zoom Cover option
            Positioned.fill(
              child: ClipRect(
                child: FittedBox(
                  fit: _isFitCover ? BoxFit.cover : BoxFit.contain,
                  child: SizedBox(
                    width: controller.value.size.width > 0 ? controller.value.size.width : 16,
                    height: controller.value.size.height > 0 ? controller.value.size.height : 9,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
            ),

            // Left & Right double-tap gesture areas
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() => _showControls = !_showControls);
                      },
                      onDoubleTap: () => _seekRelative(-10),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() => _showControls = !_showControls);
                      },
                      onDoubleTap: () => _seekRelative(10),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),

            // Seek Overlays
            if (_showLeftSeekOverlay)
              Positioned(
                left: 40,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fast_rewind_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 6),
                      Text('-10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                ),
              ),

            if (_showRightSeekOverlay)
              Positioned(
                right: 40,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    children: [
                      Text('+10s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      SizedBox(width: 6),
                      Icon(Icons.fast_forward_rounded, color: Colors.white, size: 28),
                    ],
                  ),
                ),
              ),

            // Center Play/Pause button
            if (_showControls)
              Center(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isPlaying) {
                        controller.pause();
                      } else {
                        controller.play();
                      }
                    });
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withOpacity(0.85),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),

            // Top Header Bar
            if (_showControls)
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.resource?.title ?? 'Landscape Fullscreen Video',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

            // Bottom Controls Bar
            if (_showControls)
              Positioned(
                bottom: 10,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Smooth Interactive Slider
                      ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, VideoPlayerValue value, child) {
                          final duration = value.duration.inMilliseconds;
                          final position = value.position.inMilliseconds;
                          double progress = (duration > 0)
                              ? (position / duration).clamp(0.0, 1.0)
                              : 0.0;
                          final displayValue = _isDraggingSlider
                              ? _dragProgress.clamp(0.0, 1.0)
                              : progress;

                          return SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                              activeTrackColor: const Color(0xFF6C63FF),
                              inactiveTrackColor: Colors.white24,
                              thumbColor: const Color(0xFF6C63FF),
                            ),
                            child: Slider(
                              value: displayValue,
                              onChangeStart: (val) {
                                setState(() {
                                  _isDraggingSlider = true;
                                  _dragProgress = val;
                                });
                              },
                              onChanged: (val) {
                                setState(() {
                                  _dragProgress = val;
                                });
                              },
                              onChangeEnd: (val) {
                                final targetMs = (val * duration).toInt();
                                controller.seekTo(Duration(milliseconds: targetMs));
                                setState(() {
                                  _isDraggingSlider = false;
                                });
                              },
                            ),
                          );
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_formatDuration(controller.value.position)} / ${_formatDuration(controller.value.duration)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          Row(
                            children: [
                              // Rewind 10s
                              IconButton(
                                icon: const Icon(Icons.replay_10_rounded, color: Colors.white),
                                tooltip: 'Rewind 10s',
                                onPressed: () => _seekRelative(-10),
                              ),
                              // Fast Forward 10s
                              IconButton(
                                icon: const Icon(Icons.forward_10_rounded, color: Colors.white),
                                tooltip: 'Fast Forward 10s',
                                onPressed: () => _seekRelative(10),
                              ),
                              // Speed Selector
                              PopupMenuButton<double>(
                                tooltip: 'Playback Speed',
                                initialValue: _currentSpeed,
                                onSelected: _changePlaybackSpeed,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _currentSpeed == 1.0 ? '1x' : '${_currentSpeed}x',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 1.0, child: Text('1.0x (Normal)')),
                                  const PopupMenuItem(value: 1.25, child: Text('1.25x Speed')),
                                  const PopupMenuItem(value: 1.5, child: Text('1.5x Speed')),
                                  const PopupMenuItem(value: 2.0, child: Text('2.0x Speed')),
                                ],
                              ),
                              const SizedBox(width: 4),
                              // Zoom (Fit vs Cover) Button
                              IconButton(
                                icon: Icon(
                                  _isFitCover ? Icons.zoom_in_map_rounded : Icons.zoom_out_map_rounded,
                                  color: Colors.white,
                                ),
                                tooltip: _isFitCover ? 'Fit to Screen' : 'Zoom Whole Screen',
                                onPressed: () {
                                  setState(() {
                                    _isFitCover = !_isFitCover;
                                  });
                                  widget.onToggleFitCover();
                                },
                              ),
                              // Exit Fullscreen Button
                              IconButton(
                                icon: const Icon(Icons.fullscreen_exit_rounded, color: Colors.white),
                                tooltip: 'Exit Fullscreen',
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
