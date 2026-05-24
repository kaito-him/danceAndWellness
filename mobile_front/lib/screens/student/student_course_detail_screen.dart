import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../models/quiz.dart';
import '../../services/api_client.dart';
import '../../services/course_service.dart';
import '../../utils/app_theme.dart';

class StudentCourseDetailScreen extends StatefulWidget {
  final String courseId;

  const StudentCourseDetailScreen({super.key, required this.courseId});

  @override
  State<StudentCourseDetailScreen> createState() =>
      _StudentCourseDetailScreenState();
}

class _StudentCourseDetailScreenState extends State<StudentCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  final _courseService = CourseService();
  Course? _course;
  bool _loading = true;
  String? _expandedLessonId;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCourse();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourse() async {
    setState(() => _loading = true);
    try {
      final course = await _courseService.getCourseById(widget.courseId);
      if (mounted) {
        setState(() {
          _course = course;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Failed to load course details.', isError: true);
      }
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorGold : AppTheme.successGold,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _startQuiz(Quiz quiz) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuizSheet(quiz: quiz),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Detail')),
        body: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Detail')),
        body: const Center(child: Text('Course not found.')),
      );
    }

    final course = _course!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(course),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(course),
                  const SizedBox(height: 24),
                  _buildStats(course),
                  const SizedBox(height: 24),
                  _buildSectionTitle('About This Course'),
                  const SizedBox(height: 12),
                  Text(
                    course.description ?? 'No description provided.',
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  _buildContentTabs(course),
                  const SizedBox(height: 100),
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
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryGold,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (course.thumbnailUrl != null)
              Image.network(
                ApiClient.formatMediaUrl(course.thumbnailUrl),
                fit: BoxFit.cover,
              )
            else
              Container(
                  color: AppTheme.paleGold,
                  child: const Icon(Icons.movie_filter_rounded,
                      size: 64, color: AppTheme.primaryGold)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    Colors.transparent,
                    Colors.black.withOpacity(0.6),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(course.level ?? 'UNKNOWN',
                  style: const TextStyle(
                      color: AppTheme.darkGold,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.circle, size: 4, color: AppTheme.mediumGray),
            const SizedBox(width: 8),
            Text(course.isFree ? 'FREE' : '\$${course.price}',
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text(course.title,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.paleGold,
              backgroundImage: (course.instructor?.photo != null)
                  ? NetworkImage(ApiClient.formatMediaUrl(
                      '/api/files/${course.instructor!.photo}'))
                  : null,
              child: (course.instructor?.photo == null)
                  ? const Icon(Icons.person,
                      size: 16, color: AppTheme.darkGold)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Instructor',
                    style: TextStyle(
                        fontSize: 10, color: AppTheme.textSecondary)),
                Text(course.instructor?.username ?? 'Unknown',
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(Course course) {
    final totalMin =
        course.lessons.fold<int>(0, (prev, l) => prev + l.duration);
    return Row(
      children: [
        _statCard(Icons.play_circle_outline_rounded,
            '${course.lessonCount}', 'Lessons'),
        const SizedBox(width: 12),
        _statCard(
            Icons.timer_outlined, _formatMinutes(totalMin), 'Duration'),
        const SizedBox(width: 12),
        _statCard(Icons.quiz_outlined, '${course.quizzes.length}',
            'Quizzes'),
      ],
    );
  }

  String _formatMinutes(int min) {
    if (min == 0) return '0m';
    final h = min ~/ 60;
    final m = min % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  Widget _buildContentTabs(Course course) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
              color: AppTheme.primaryGold,
              borderRadius: BorderRadius.circular(12),
            ),
            labelColor: AppTheme.pureWhite,
            unselectedLabelColor: AppTheme.textSecondary,
            dividerColor: Colors.transparent,
            tabs: [
              Tab(text: 'Lessons (${course.lessons.length})'),
              Tab(text: 'Quizzes (${course.quizzes.length})'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: _computeTabHeight(course),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildLessonsContent(course),
              _buildQuizzesContent(course),
            ],
          ),
        ),
      ],
    );
  }

  double _computeTabHeight(Course course) {
    final lessonHeight = course.lessons.isEmpty ? 120.0 : course.lessons.length * 88.0;
    final quizHeight = course.quizzes.isEmpty ? 120.0 : course.quizzes.length * 88.0;
    return lessonHeight > quizHeight ? lessonHeight : quizHeight;
  }

  Widget _buildLessonsContent(Course course) {
    if (course.lessons.isEmpty) {
      return const Center(
        child: Text('No lessons available.',
            style:
                TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: course.lessons.length,
      itemBuilder: (_, i) => _LessonTile(
        index: i,
        lesson: course.lessons[i],
        isExpanded: _expandedLessonId == course.lessons[i].lessonId,
        onTap: () {
          setState(() {
            _expandedLessonId =
                _expandedLessonId == course.lessons[i].lessonId
                    ? null
                    : course.lessons[i].lessonId;
          });
        },
      ),
    );
  }

  Widget _buildQuizzesContent(Course course) {
    if (course.quizzes.isEmpty) {
      return const Center(
        child: Text('No quizzes available.',
            style:
                TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondary)),
      );
    }
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: course.quizzes.length,
      itemBuilder: (_, i) => _QuizTile(
        quiz: course.quizzes[i],
        index: i,
        onTap: () => _startQuiz(course.quizzes[i]),
      ),
    );
  }

  Widget _statCard(IconData icon, String val, String lbl) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryGold),
            const SizedBox(height: 8),
            Text(val,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            Text(lbl,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary));
  }
}

// ── Lesson Tile ──────────────────────────────────────────────────────────────

class _LessonTile extends StatelessWidget {
  final int index;
  final Lesson lesson;
  final bool isExpanded;
  final VoidCallback onTap;

  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: isExpanded
            ? Border.all(color: AppTheme.primaryGold.withOpacity(0.5))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isExpanded
                          ? AppTheme.primaryGold
                          : AppTheme.paleGold,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                        child: Text('${index + 1}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isExpanded
                                    ? Colors.white
                                    : AppTheme.darkGold))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lesson.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                        Row(
                          children: [
                            const Icon(Icons.videocam_outlined,
                                size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('${lesson.duration}m',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: AppTheme.mediumGray,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              color: Colors.black,
              child: lesson.mediaUrl != null
                  ? _InlineVideoPlayer(
                      url: ApiClient.formatMediaUrl(lesson.mediaUrl))
                  : const AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Center(
                          child: Text('No video source',
                              style: TextStyle(color: Colors.white))),
                    ),
            ),
        ],
      ),
    );
  }
}

// ── Quiz Tile ────────────────────────────────────────────────────────────────

class _QuizTile extends StatelessWidget {
  final Quiz quiz;
  final int index;
  final VoidCallback onTap;

  const _QuizTile({
    required this.quiz,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.paleGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.quiz_outlined,
                    color: AppTheme.primaryGold, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('${quiz.questions.length} questions',
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.mediumGray),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quiz Bottom Sheet ────────────────────────────────────────────────────────

class _QuizSheet extends StatefulWidget {
  final Quiz quiz;

  const _QuizSheet({required this.quiz});

  @override
  State<_QuizSheet> createState() => _QuizSheetState();
}

class _QuizSheetState extends State<_QuizSheet> {
  final Map<String, Set<int>> _selected = {};
  bool _submitted = false;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    for (final q in widget.quiz.questions) {
      _selected[q.questionId] = {};
    }
  }

  void _toggleOption(String questionId, int optionIndex) {
    if (_submitted) return;
    setState(() {
      final set = _selected[questionId]!;
      if (set.contains(optionIndex)) {
        set.remove(optionIndex);
      } else {
        set.add(optionIndex);
      }
    });
  }

  void _submit() {
    int correct = 0;
    for (final q in widget.quiz.questions) {
      final chosen = _selected[q.questionId] ?? {};
      final correctIndices = <int>{};
      for (int i = 0; i < q.options.length; i++) {
        if (q.options[i].isCorrect) correctIndices.add(i);
      }
      if (chosen.length == correctIndices.length &&
          chosen.every((i) => correctIndices.contains(i))) {
        correct++;
      }
    }
    setState(() {
      _submitted = true;
      _score = widget.quiz.questions.isEmpty
          ? 0
          : ((correct / widget.quiz.questions.length) * 100).round();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                    bottom:
                        BorderSide(color: AppTheme.paleGold, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('KNOWLEDGE CHECK',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                color: AppTheme.primaryGold)),
                        const SizedBox(height: 4),
                        Text(widget.quiz.title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            if (_submitted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: _score >= 80
                    ? AppTheme.successGold.withOpacity(0.1)
                    : _score >= 50
                        ? AppTheme.warningGold.withOpacity(0.1)
                        : AppTheme.errorGold.withOpacity(0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _score >= 80 ? Icons.emoji_events : Icons.info_outline,
                      color: _score >= 80
                          ? AppTheme.successGold
                          : _score >= 50
                              ? AppTheme.warningGold
                              : AppTheme.errorGold,
                    ),
                    const SizedBox(width: 12),
                    Text('Score: $_score%',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _score >= 80
                                ? AppTheme.successGold
                                : _score >= 50
                                    ? AppTheme.warningGold
                                    : AppTheme.errorGold)),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.all(20),
                itemCount: widget.quiz.questions.length,
                itemBuilder: (_, qi) {
                  final question = widget.quiz.questions[qi];
                  return _buildQuestionCard(qi, question);
                },
              ),
            ),
            if (!_submitted)
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit Quiz'),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(int index, Question question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.paleGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Question ${index + 1}',
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold)),
          const SizedBox(height: 6),
          Text(question.text,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 14),
          ...question.options.asMap().entries.map((entry) {
            final oi = entry.key;
            final option = entry.value;
            final isChosen =
                _selected[question.questionId]?.contains(oi) ?? false;

            Color bgColor = AppTheme.pureWhite;
            Color borderColor = AppTheme.mediumGray;

            if (_submitted) {
              if (option.isCorrect && isChosen) {
                bgColor = AppTheme.successGold.withOpacity(0.1);
                borderColor = AppTheme.successGold;
              } else if (!option.isCorrect && isChosen) {
                bgColor = AppTheme.errorGold.withOpacity(0.1);
                borderColor = AppTheme.errorGold;
              } else if (option.isCorrect) {
                borderColor = AppTheme.successGold;
              }
            } else if (isChosen) {
              bgColor = AppTheme.primaryGold.withOpacity(0.1);
              borderColor = AppTheme.primaryGold;
            }

            return GestureDetector(
              onTap: () => _toggleOption(question.questionId, oi),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: borderColor, width: 2),
                        color: isChosen ? borderColor : Colors.transparent,
                      ),
                      child: isChosen
                          ? const Icon(Icons.check,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(option.text,
                          style: const TextStyle(
                              fontSize: 14, color: AppTheme.textPrimary)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Inline Video Player ──────────────────────────────────────────────────────

class _InlineVideoPlayer extends StatefulWidget {
  final String url;
  const _InlineVideoPlayer({required this.url});

  @override
  State<_InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<_InlineVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
      );
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null ||
        !_videoController.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
            child:
                CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}
