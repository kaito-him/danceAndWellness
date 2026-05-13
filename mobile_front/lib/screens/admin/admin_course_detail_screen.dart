import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/course.dart';
import '../../models/quiz.dart';
import '../../models/comment.dart';
import '../../models/app_user.dart';
import '../../services/course_service.dart';
import '../../services/comment_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/admin_user_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import 'admin_user_detail_screen.dart';

String _timeAgo(String? dateStr) {
  if (dateStr == null) return '';
  try {
    final dt = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7}w ago';
    if (diff.inDays < 365) return '${diff.inDays ~/ 30}mo ago';
    return '${diff.inDays ~/ 365}y ago';
  } catch (_) {
    return '';
  }
}

class AdminCourseDetailScreen extends StatefulWidget {
  final String courseId;
  const AdminCourseDetailScreen({super.key, required this.courseId});

  @override
  State<AdminCourseDetailScreen> createState() =>
      _AdminCourseDetailScreenState();
}

class _AdminCourseDetailScreenState extends State<AdminCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  final CourseService _courseService = CourseService();
  final AdminUserService _adminUserService = AdminUserService();

  Course? _course;
  int _enrollmentCount = 0;
  String _categoryName = '';
  bool _loading = true;
  String? _error;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCourse();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCourse() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _courseService.getCourseById(widget.courseId),
        _courseService.getEnrollmentCount(widget.courseId),
      ]);
      final course = results[0] as Course;
      final count = results[1] as int;
      String catName = '';
      if (course.categoryId != null && course.categoryId!.isNotEmpty) {
        catName = await _courseService.getCategoryName(course.categoryId!);
      }
      if (mounted) {
        setState(() {
          _course = course;
          _enrollmentCount = count;
          _categoryName = catName;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _navigateToInstructor() async {
    final instructor = _course?.instructor;
    if (instructor == null) return;
    try {
      final users = await _adminUserService.getAllUsers();
      final AppUser? found = users.cast<AppUser?>().firstWhere(
            (u) => u?.userId == instructor.userId,
            orElse: () => null,
          );
      if (found != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminUserDetailScreen(user: found),
          ),
        );
      }
    } catch (_) {}
  }

  void _openComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CommentsSheet(courseId: widget.courseId),
    );
  }

  void _openEnrollments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _EnrollmentsSheet(courseId: widget.courseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppTheme.pageBackground,
        body: Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }
    if (_error != null || _course == null) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(title: const Text('Course Detail')),
        body: Center(
          child: Text(_error ?? 'Course not found',
              style: const TextStyle(color: AppTheme.errorGold)),
        ),
      );
    }

    final course = _course!;
    final totalDuration =
        course.lessons.fold<int>(0, (sum, l) => sum + l.duration);
    final durationStr = totalDuration >= 60
        ? '${totalDuration ~/ 60}h ${totalDuration % 60}m'
        : '${totalDuration}m';

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _openComments,
        backgroundColor: AppTheme.primaryGold,
        child: const Icon(Icons.chat_bubble_outline_rounded,
            color: AppTheme.pureWhite),
      ),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(course),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderSection(course),
                  const SizedBox(height: 20),
                  _buildStatsRow(course, durationStr),
                  const SizedBox(height: 24),
                  _buildAboutSection(course),
                  const SizedBox(height: 24),
                  _buildCurriculumSection(course),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Course course) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: AppTheme.primaryGold,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppTheme.pureWhite),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: course.thumbnailUrl != null
            ? Image.network(
                ApiClient.formatMediaUrl(course.thumbnailUrl!),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.darkGold,
                  child: const Icon(Icons.play_circle_outline_rounded,
                      size: 64, color: AppTheme.pureWhite),
                ),
              )
            : Container(
                color: AppTheme.darkGold,
                child: const Icon(Icons.play_circle_outline_rounded,
                    size: 64, color: AppTheme.pureWhite),
              ),
      ),
    );
  }

  Widget _buildHeaderSection(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (course.level != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                ),
                child: Text(
                  course.level!.toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.darkGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: course.isFree
                    ? AppTheme.successGold.withValues(alpha: 0.15)
                    : AppTheme.primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                course.isFree
                    ? 'FREE'
                    : '\$${course.price?.toStringAsFixed(2) ?? '0.00'}',
                style: TextStyle(
                  color: course.isFree
                      ? AppTheme.successGold
                      : AppTheme.darkGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          course.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        if (_categoryName.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _categoryName,
            style: const TextStyle(
                color: AppTheme.primaryGold,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 16),
        if (course.instructor != null) _buildInstructorRow(course.instructor!),
      ],
    );
  }

  Widget _buildInstructorRow(CourseInstructor instructor) {
    return GestureDetector(
      onTap: _navigateToInstructor,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.mediumGray),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.paleGold,
              backgroundImage: instructor.photo != null
                  ? NetworkImage(
                      ApiClient.formatMediaUrl('/api/files/${instructor.photo}'))
                  : null,
              child: instructor.photo == null
                  ? Text(
                      (instructor.username ?? 'I')[0].toUpperCase(),
                      style: const TextStyle(
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instructor.username ?? 'Instructor',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 14),
                  ),
                  if (instructor.specialization != null)
                    Text(
                      instructor.specialization!,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppTheme.primaryGold),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(Course course, String durationStr) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.mediumGray),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: _openEnrollments,
            child: _statItem(
              Icons.people_alt_rounded,
              '$_enrollmentCount',
              'Students',
              tappable: true,
            ),
          ),
          _divider(),
          _statItem(Icons.play_lesson_rounded, '${course.lessonCount}',
              'Lessons'),
          _divider(),
          _statItem(Icons.quiz_rounded, '${course.quizCount}', 'Quizzes'),
          _divider(),
          _statItem(Icons.timer_rounded, durationStr, 'Duration'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label,
      {bool tappable = false}) {
    return Column(
      children: [
        Icon(icon,
            color: tappable ? AppTheme.primaryGold : AppTheme.darkGold,
            size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: tappable ? AppTheme.primaryGold : AppTheme.textPrimary,
            decoration: tappable ? TextDecoration.underline : null,
            decorationColor: AppTheme.primaryGold,
          ),
        ),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }

  Widget _divider() {
    return Container(
        height: 40, width: 1, color: AppTheme.mediumGray);
  }

  Widget _buildAboutSection(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this Course',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),
        Text(
          course.description ?? 'No description available.',
          style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.6),
        ),
      ],
    );
  }

  Widget _buildCurriculumSection(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curriculum',
          style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.mediumGray),
          ),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryGold,
                unselectedLabelColor: AppTheme.textSecondary,
                indicatorColor: AppTheme.primaryGold,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: const [
                  Tab(text: 'Lessons'),
                  Tab(text: 'Quizzes'),
                ],
              ),
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _LessonsTab(lessons: course.lessons),
                    _QuizzesTab(quizzes: course.quizzes),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Lessons Tab ─────────────────────────────────────────────────────────────

class _LessonsTab extends StatefulWidget {
  final List<dynamic> lessons;
  const _LessonsTab({required this.lessons});

  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.lessons.isEmpty) {
      return const Center(
        child: Text('No lessons yet.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: widget.lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final lesson = widget.lessons[i];
        final isExpanded = _expandedIndex == i;
        return _LessonRow(
          key: ValueKey('lesson_${lesson.lessonId}'),
          lesson: lesson,
          index: i,
          isExpanded: isExpanded,
          onTap: () {
            setState(() {
              _expandedIndex = isExpanded ? null : i;
            });
          },
        );
      },
    );
  }
}

class _LessonRow extends StatefulWidget {
  final dynamic lesson;
  final int index;
  final bool isExpanded;
  final VoidCallback onTap;

  const _LessonRow({
    super.key,
    required this.lesson,
    required this.index,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  State<_LessonRow> createState() => _LessonRowState();
}

class _LessonRowState extends State<_LessonRow> {
  VideoPlayerController? _vpController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  bool _videoError = false;
  String _errorMessage = '';

  @override
  void didUpdateWidget(_LessonRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) {
      _initVideo();
    } else if (!widget.isExpanded && oldWidget.isExpanded) {
      _disposeVideo();
    }
  }

  Future<void> _initVideo() async {
    // Reset state before each attempt
    if (mounted) setState(() { _videoError = false; _videoInitialized = false; });
    final mediaUrl = widget.lesson.mediaUrl as String?;
    if (mediaUrl == null || mediaUrl.isEmpty) return;
    final url = ApiClient.formatMediaUrl(mediaUrl);
    debugPrint('>>> _initVideo: mediaUrl=$mediaUrl  fullUrl=$url');
    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(url),
        httpHeaders: const {'Accept': '*/*'},
      );
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      _vpController = controller;
      _chewieController = ChewieController(
        videoPlayerController: _vpController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.primaryGold,
          handleColor: AppTheme.darkGold,
          backgroundColor: AppTheme.mediumGray,
          bufferedColor: AppTheme.paleGold,
        ),
      );
      if (mounted) setState(() => _videoInitialized = true);
    } catch (e) {
      debugPrint('>>> _initVideo ERROR: $e');
      if (mounted) setState(() { _videoError = true; _errorMessage = e.toString(); });
    }
  }

  void _disposeVideo() {
    _chewieController?.dispose();
    _vpController?.dispose();
    _chewieController = null;
    _vpController = null;
    if (mounted) setState(() { _videoInitialized = false; _videoError = false; _errorMessage = ''; });
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _vpController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final durationMin = (lesson.duration as int?) ?? 0;
    final durationStr = durationMin >= 60
        ? '${durationMin ~/ 60}h ${durationMin % 60}m'
        : '${durationMin}m';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: widget.isExpanded
              ? AppTheme.primaryGold.withValues(alpha: 0.5)
              : AppTheme.mediumGray,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: const TextStyle(
                          color: AppTheme.darkGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.title as String? ?? 'Lesson',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          durationStr,
                          style: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    widget.isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppTheme.primaryGold,
                  ),
                ],
              ),
            ),
          ),
          if (widget.isExpanded) ...[
            const Divider(height: 1, color: AppTheme.mediumGray),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _buildVideoPlayer(lesson),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoPlayer(dynamic lesson) {
    final mediaUrl = lesson.mediaUrl as String?;
    if (mediaUrl == null || mediaUrl.isEmpty) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.mediumGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('No video available',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }
    if (_videoError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppTheme.mediumGray,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.errorGold, size: 32),
              const SizedBox(height: 8),
              const Text('Failed to load video',
                  style: TextStyle(color: AppTheme.errorGold)),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _errorMessage,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                  textAlign: TextAlign.center,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _initVideo,
                icon: const Icon(Icons.refresh, size: 16, color: AppTheme.primaryGold),
                label: const Text('Retry', style: TextStyle(color: AppTheme.primaryGold)),
              ),
            ],
          ),
        ),
      );
    }
    if (!_videoInitialized) {
      return Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppTheme.mediumGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Chewie(controller: _chewieController!),
      ),
    );
  }
}

// ─── Quizzes Tab ─────────────────────────────────────────────────────────────

class _QuizzesTab extends StatefulWidget {
  final List<Quiz> quizzes;
  const _QuizzesTab({required this.quizzes});

  @override
  State<_QuizzesTab> createState() => _QuizzesTabState();
}

class _QuizzesTabState extends State<_QuizzesTab> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.quizzes.isEmpty) {
      return const Center(
        child: Text('No quizzes yet.',
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: widget.quizzes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final quiz = widget.quizzes[i];
        final isExpanded = _expandedIndex == i;
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isExpanded
                  ? AppTheme.primaryGold.withValues(alpha: 0.5)
                  : AppTheme.mediumGray,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                onTap: () =>
                    setState(() => _expandedIndex = isExpanded ? null : i),
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: AppTheme.darkGold.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.quiz_rounded,
                              color: AppTheme.darkGold, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              quiz.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${quiz.questions.length} question${quiz.questions.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppTheme.primaryGold,
                      ),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 1, color: AppTheme.mediumGray),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: quiz.questions
                        .map((q) => _buildQuestion(q))
                        .toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestion(Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          ...question.options.map((opt) => _buildOption(opt)),
        ],
      ),
    );
  }

  Widget _buildOption(AnswerOption option) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: option.isCorrect
            ? AppTheme.successGold.withValues(alpha: 0.12)
            : AppTheme.lightGray,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: option.isCorrect
              ? AppTheme.successGold.withValues(alpha: 0.5)
              : AppTheme.mediumGray,
        ),
      ),
      child: Row(
        children: [
          Icon(
            option.isCorrect
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: option.isCorrect
                ? AppTheme.successGold
                : AppTheme.textSecondary,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.text,
              style: TextStyle(
                color: option.isCorrect
                    ? AppTheme.successGold
                    : AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: option.isCorrect
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Comments Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

// â”€â”€ Avatar widget â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CommentAvatar extends StatelessWidget {
  final String username;
  final String? photo;
  final double size;
  const _CommentAvatar({required this.username, this.photo, this.size = 36});

  @override
  Widget build(BuildContext context) {
    if (photo != null && photo!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: AppTheme.paleGold,
        backgroundImage: NetworkImage(
          ApiClient.formatMediaUrl('/api/files/$photo'),
        ),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppTheme.paleGold,
      child: Text(
        username.isNotEmpty ? username[0].toUpperCase() : '?',
        style: TextStyle(
          color: AppTheme.primaryGold,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

// â”€â”€ Role badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge(this.role);

  Color get _color {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppTheme.errorGold;
      case 'INSTRUCTOR':
        return AppTheme.primaryGold;
      default:
        return AppTheme.successGold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _color.withValues(alpha: 0.35)),
      ),
      child: Text(
        role.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// â”€â”€ Skeleton loader â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CommentSkeleton extends StatelessWidget {
  const _CommentSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.mediumGray,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 11,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 11,
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Reply item â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ReplyItem extends StatelessWidget {
  final Comment reply;
  final String courseId;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _ReplyItem({
    required this.reply,
    required this.courseId,
    required this.isAdmin,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentAvatar(
            username: reply.authorUsername,
            photo: reply.authorPhoto,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      reply.authorUsername,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                    if (reply.authorRole != null &&
                        reply.authorRole!.toUpperCase() != 'STUDENT') ...[
                      const SizedBox(width: 6),
                      _RoleBadge(reply.authorRole!),
                    ],
                    const Spacer(),
                    Text(
                      _timeAgo(reply.createdAt),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 10),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.errorGold, size: 15),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  reply.content,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Comment item â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CommentItem extends StatefulWidget {
  final Comment comment;
  final String courseId;
  final bool isAdmin;
  final VoidCallback onDelete;
  final void Function(String replyId) onReplyDelete;

  const _CommentItem({
    required this.comment,
    required this.courseId,
    required this.isAdmin,
    required this.onDelete,
    required this.onReplyDelete,
  });

  @override
  State<_CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<_CommentItem> {
  final CommentService _commentService = CommentService();

  bool _showReplies = false;
  bool _repliesFetched = false;
  bool _loadingReplies = false;
  List<Comment> _replies = [];

  bool _showReplyBox = false;
  final TextEditingController _replyCtrl = TextEditingController();
  bool _sendingReply = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReplies() async {
    if (_repliesFetched) return;
    setState(() => _loadingReplies = true);
    try {
      final list = await _commentService.getReplies(
          widget.courseId, widget.comment.commentId);
      if (mounted) {
        setState(() {
          _replies = list;
          _repliesFetched = true;
          _loadingReplies = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingReplies = false);
    }
  }

  Future<void> _toggleReplies() async {
    if (!_showReplies) await _fetchReplies();
    if (mounted) setState(() => _showReplies = !_showReplies);
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty || _sendingReply) return;
    setState(() => _sendingReply = true);
    try {
      final reply = await _commentService.replyToComment(
          widget.courseId, widget.comment.commentId, text);
      _replyCtrl.clear();
      if (mounted) {
        setState(() {
          _replies.add(reply);
          _repliesFetched = true;
          _showReplies = true;
          _showReplyBox = false;
          _sendingReply = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _sendingReply = false);
    }
  }

  bool get _isInstructor =>
      widget.comment.authorRole?.toUpperCase() == 'INSTRUCTOR';

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: _isInstructor
          ? const EdgeInsets.all(14)
          : const EdgeInsets.symmetric(vertical: 14),
      decoration: _isInstructor
          ? BoxDecoration(
              color: const Color(0xFFFFFAF0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF2DEC4)),
            )
          : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentAvatar(
              username: comment.authorUsername, photo: comment.authorPhoto),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.authorUsername,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (comment.authorRole != null &&
                        comment.authorRole!.toUpperCase() != 'STUDENT') ...[
                      const SizedBox(width: 6),
                      _RoleBadge(comment.authorRole!),
                    ],
                    const Spacer(),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                    if (widget.isAdmin) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppTheme.errorGold, size: 16),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                // Content
                Text(
                  comment.content,
                  style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 14, height: 1.55),
                ),
                const SizedBox(height: 10),
                // Action bar
                Row(
                  children: [
                    // Reply button (admin can view replies but not post)
                    if (!widget.isAdmin)
                      _ActionChip(
                        icon: Icons.reply_rounded,
                        label: 'Reply',
                        onTap: () =>
                            setState(() => _showReplyBox = !_showReplyBox),
                        active: _showReplyBox,
                      ),
                    const SizedBox(width: 6),
                    // View replies
                    _ActionChip(
                      icon: _showReplies
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      label: _loadingReplies
                          ? 'Loadingâ€¦'
                          : _showReplies
                              ? 'Hide replies'
                              : 'View replies',
                      onTap: _toggleReplies,
                      active: _showReplies,
                    ),
                  ],
                ),
                // Reply input box
                if (_showReplyBox && !widget.isAdmin) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.mediumGray),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _replyCtrl,
                            maxLines: null,
                            style: const TextStyle(
                                fontSize: 13, color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Write a replyâ€¦',
                              hintStyle: TextStyle(
                                  color: AppTheme.textSecondary
                                      .withValues(alpha: 0.7),
                                  fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _sendReply(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendingReply ? null : _sendReply,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGold,
                              shape: BoxShape.circle,
                            ),
                            child: _sendingReply
                                ? const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: CircularProgressIndicator(
                                        color: AppTheme.pureWhite,
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded,
                                    color: AppTheme.pureWhite, size: 15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Replies list
                if (_showReplies && _replies.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.only(left: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                            color: Color(0xFFF2DEC4), width: 2),
                      ),
                    ),
                    child: Column(
                      children: _replies
                          .map((r) => _ReplyItem(
                                reply: r,
                                courseId: widget.courseId,
                                isAdmin: widget.isAdmin,
                                onDelete: () =>
                                    widget.onReplyDelete(r.commentId),
                              ))
                          .toList(),
                    ),
                  ),
                ],
                if (_showReplies && _replies.isEmpty && !_loadingReplies) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'No replies yet.',
                    style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Small action chip â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryGold.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppTheme.primaryGold.withValues(alpha: 0.4)
                : AppTheme.mediumGray,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: active ? AppTheme.primaryGold : AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: active ? AppTheme.primaryGold : AppTheme.textSecondary,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Delete confirm dialog â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _DeleteConfirmDialog extends StatelessWidget {
  final String title;
  final VoidCallback onConfirm;
  final bool loading;

  const _DeleteConfirmDialog({
    required this.title,
    required this.onConfirm,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.pureWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.delete_outline_rounded,
              color: AppTheme.errorGold, size: 22),
          const SizedBox(width: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
        ],
      ),
      content: const Text(
        'Are you sure you want to delete this? This cannot be undone.',
        style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
        ElevatedButton(
          onPressed: loading ? null : onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.errorGold,
            foregroundColor: AppTheme.pureWhite,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppTheme.pureWhite, strokeWidth: 2),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }
}

// â”€â”€ Main _CommentsSheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CommentsSheet extends StatefulWidget {
  final String courseId;
  const _CommentsSheet({required this.courseId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final CommentService _commentService = CommentService();
  final ScrollController _scrollController = ScrollController();

  List<Comment> _comments = [];
  bool _loading = true;
  String? _error;

  // Delete confirmation state
  String? _pendingDeleteId;
  bool _isReplyDelete = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await _commentService.getComments(widget.courseId);
      if (mounted) setState(() { _comments = list; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Failed to load comments.'; });
    }
  }

  void _askDeleteComment(String commentId) {
    setState(() {
      _pendingDeleteId = commentId;
      _isReplyDelete = false;
    });
  }

  void _askDeleteReply(String replyId) {
    setState(() {
      _pendingDeleteId = replyId;
      _isReplyDelete = true;
    });
  }

  Future<void> _confirmDelete() async {
    final id = _pendingDeleteId;
    if (id == null) return;
    setState(() => _deleting = true);
    try {
      await _commentService.deleteComment(widget.courseId, id);
      if (mounted) {
        if (!_isReplyDelete) {
          setState(() => _comments.removeWhere((c) => c.commentId == id));
        } else {
          // Refresh to update reply counts
          await _loadComments();
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _pendingDeleteId = null;
        _deleting = false;
      });
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (_) => _DeleteConfirmDialog(
        title: _isReplyDelete ? 'Delete Reply' : 'Delete Comment',
        loading: _deleting,
        onConfirm: _confirmDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.mediumGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 14),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded,
                        color: AppTheme.primaryGold, size: 20),
                    const SizedBox(width: 10),
                    const Text(
                      'Discussion',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!_loading)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_comments.length}',
                          style: const TextStyle(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: AppTheme.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEDE9DE)),
              // Error bar
              if (_error != null)
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.errorGold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppTheme.errorGold.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: AppTheme.errorGold, fontSize: 13)),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _error = null),
                        child: const Icon(Icons.close_rounded,
                            color: AppTheme.errorGold, size: 16),
                      ),
                    ],
                  ),
                ),
              // Comments list
              Expanded(
                child: _loading
                    ? ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        children: const [
                          _CommentSkeleton(),
                          _CommentSkeleton(),
                          _CommentSkeleton(),
                        ],
                      )
                    : _comments.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: AppTheme.primaryGold
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: 14),
                                const Text(
                                  'Start the conversation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Be the first to share your thoughts.',
                                  style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            itemCount: _comments.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, color: Color(0xFFF5EEDF)),
                            itemBuilder: (_, i) => _CommentItem(
                              comment: _comments[i],
                              courseId: widget.courseId,
                              isAdmin: true,
                              onDelete: () {
                                _askDeleteComment(_comments[i].commentId);
                                _showDeleteDialog();
                              },
                              onReplyDelete: (replyId) {
                                _askDeleteReply(replyId);
                                _showDeleteDialog();
                              },
                            ),
                          ),
              ),
              // Admin info bar (no compose box â€” admin reads only)
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: const BoxDecoration(
                  color: AppTheme.pureWhite,
                  border: Border(
                      top: BorderSide(color: Color(0xFFEDE9DE))),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.admin_panel_settings_rounded,
                        color: AppTheme.primaryGold, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Viewing as Admin â€” you can delete any comment or reply.',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ),
                    GestureDetector(
                      onTap: _loading ? null : _loadComments,
                      child: const Icon(Icons.refresh_rounded,
                          color: AppTheme.primaryGold, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// â”€â”€â”€ Enrollments Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EnrollmentsSheet extends StatefulWidget {
  final String courseId;
  const _EnrollmentsSheet({required this.courseId});

  @override
  State<_EnrollmentsSheet> createState() => _EnrollmentsSheetState();
}

class _EnrollmentsSheetState extends State<_EnrollmentsSheet> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  List<EnrollmentRow> _enrollments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _loading = true);
    final list =
        await _enrollmentService.getCourseEnrollments(widget.courseId);
    if (mounted) setState(() { _enrollments = list; _loading = false; });
  }

  void _openProgress(EnrollmentRow row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StudentProgressSheet(
        studentId: row.studentId,
        courseId: widget.courseId,
        studentName: row.studentName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryGold))
                    : _enrollments.isEmpty
                        ? const Center(
                            child: Text('No enrollments found.',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)))
                        : ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            itemCount: _enrollments.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) =>
                                _buildEnrollmentItem(_enrollments[i]),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.mediumGray,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Text(
            'Enrolled Students',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_enrollments.length}',
              style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnrollmentItem(EnrollmentRow row) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.paleGold,
            backgroundImage: row.studentPhoto != null
                ? NetworkImage(ApiClient.formatMediaUrl(
                    '/api/files/${row.studentPhoto}'))
                : null,
            child: row.studentPhoto == null
                ? Text(
                    row.studentName[0].toUpperCase(),
                    style: const TextStyle(
                        color: AppTheme.primaryGold,
                        fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.studentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                      fontSize: 13),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: row.enrollmentType == 'PAID'
                            ? AppTheme.primaryGold.withValues(alpha: 0.15)
                            : AppTheme.successGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        row.enrollmentType,
                        style: TextStyle(
                          color: row.enrollmentType == 'PAID'
                              ? AppTheme.darkGold
                              : AppTheme.successGold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (row.enrolledAt != null)
                      Text(
                        _timeAgo(row.enrolledAt),
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11),
                      ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openProgress(row),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primaryGold,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Progress',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ─── Student Progress Bottom Sheet ───────────────────────────────────────────

class _StudentProgressSheet extends StatefulWidget {
  final String studentId;
  final String courseId;
  final String studentName;

  const _StudentProgressSheet({
    required this.studentId,
    required this.courseId,
    required this.studentName,
  });

  @override
  State<_StudentProgressSheet> createState() => _StudentProgressSheetState();
}

class _StudentProgressSheetState extends State<_StudentProgressSheet> {
  final EnrollmentService _enrollmentService = EnrollmentService();
  StudentProgress? _progress;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => _loading = true);
    final progress = await _enrollmentService.getStudentProgress(
        widget.studentId, widget.courseId);
    if (mounted) setState(() { _progress = progress; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              _buildHeader(),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primaryGold))
                    : _progress == null
                        ? const Center(
                            child: Text('No progress data available.',
                                style: TextStyle(
                                    color: AppTheme.textSecondary)))
                        : _buildProgressContent(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.mediumGray,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: AppTheme.primaryGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.studentName}\'s Progress',
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent(ScrollController scrollController) {
    final p = _progress!;
    final percent = p.completionPercent.clamp(0.0, 100.0);

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(20),
      children: [
        // Overall completion card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.paleGold,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: AppTheme.primaryGold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Overall Completion',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        fontSize: 15),
                  ),
                  Text(
                    '${percent.toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGold,
                        fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 10,
                  backgroundColor: AppTheme.mediumGray,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppTheme.primaryGold),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppTheme.successGold, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${p.completedLessons} / ${p.totalLessons} lessons completed',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (p.lessonProgress.isNotEmpty) ...[
          const Text(
            'Lesson Progress',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          ...p.lessonProgress.map((lp) => _buildLessonProgressItem(lp)),
        ],
      ],
    );
  }

  Widget _buildLessonProgressItem(LessonProgress lp) {
    final pct = lp.completionPercent.clamp(0.0, 100.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  lp.lessonTitle ?? 'Lesson',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      fontSize: 13),
                ),
              ),
              Text(
                '${pct.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: pct >= 100
                      ? AppTheme.successGold
                      : AppTheme.primaryGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: AppTheme.mediumGray,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 100 ? AppTheme.successGold : AppTheme.primaryGold,
              ),
            ),
          ),
          if (lp.lastUpdated != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last activity: ${_timeAgo(lp.lastUpdated)}',
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}
