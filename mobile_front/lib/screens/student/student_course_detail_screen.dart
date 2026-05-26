import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../services/course_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/instructor_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import '../../models/lesson.dart';
import '../../models/quiz.dart';
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
  final _enrollService = EnrollmentService();
  final _instructorService = InstructorDashboardService();

  late TabController _tabController;

  Course? _course;
  bool _enrolled = false;
  StudentProgress? _progress;
  List<Map<String, dynamic>> _comments = [];
  int _enrolledCount = 0;
  String _categoryName = '';

  bool _loading = true;
  bool _enrolling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final course = await _courseService.getCourseById(widget.courseId);
      final enrolled = await _enrollService.isEnrolled(userId, widget.courseId);

      StudentProgress? progress;
      if (enrolled) {
        progress = await _enrollService.getStudentOwnProgress(
          userId,
          widget.courseId,
        );
      }

      final comments = await _instructorService.getComments(widget.courseId);

      // Fetch enrollment count and category name in parallel
      final int enrolledCount =
          await _courseService.getEnrollmentCount(course.courseId);
      String categoryName = '';
      if (course.categoryId != null && course.categoryId!.isNotEmpty) {
        categoryName =
            await _courseService.getCategoryName(course.categoryId!);
      }

      setState(() {
        _course = course;
        _enrolled = enrolled;
        _progress = progress;
        _comments = comments;
        _enrolledCount = enrolledCount;
        _categoryName = categoryName;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  
  Widget _buildInstructorAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.paleGold,
            AppTheme.primaryGold,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _course!.instructor?.username?.toString().substring(0, 1).toUpperCase() ?? 'I',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

Future<void> _enroll() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null || _course == null) return;

    if (!_course!.isFree) {
      // Mock Paid checkout
      final paid = await _showCheckoutDialog();
      if (!paid) return;
    }

    setState(() => _enrolling = true);
    try {
      await _enrollService.enrollFree(userId, widget.courseId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Successfully enrolled! Welcome to the course. 🎓'),
          backgroundColor: Colors.green,
        ),
      );
      _loadAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enrollment failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _enrolling = false);
    }
  }

  Future<bool> _showCheckoutDialog() async {
    final cardCtrl = TextEditingController(text: '4242 4242 4242 4242');
    final expiryCtrl = TextEditingController(text: '12/28');
    final cvcCtrl = TextEditingController(text: '123');

    final pay = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment_rounded, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text('Checkout'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Course: ${_course!.title}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Amount to pay: \$${_course!.price?.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cardCtrl,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                prefixIcon: Icon(Icons.credit_card),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: expiryCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Expiry (MM/YY)',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: cvcCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'CVC'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Pay & Enroll'),
          ),
        ],
      ),
    );
    return pay ?? false;
  }

  

 @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
      );
    }

    if (_error != null || _course == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 56,
                color: AppTheme.errorGold,
              ),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Course not found',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final thumbUrl =
        _course!.thumbnailUrl != null && _course!.thumbnailUrl!.isNotEmpty
        ? ApiClient.formatMediaUrl(_course!.thumbnailUrl)
        : null;

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryGold,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: thumbUrl != null
                    ? Image.network(thumbUrl, fit: BoxFit.cover)
                    : Container(
                        color: AppTheme.paleGold,
                        child: const Icon(
                          Icons.menu_book_outlined,
                          size: 64,
                          color: AppTheme.primaryGold,
                        ),
                      ),
              ),
            ),
          ];
        },
        body: Column(
          children: [
            // Overview Header Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _course!.isFree
                              ? Colors.green.withOpacity(0.12)
                              : AppTheme.paleGold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _course!.isFree
                              ? 'FREE'
                              : '\$${_course!.price?.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _course!.isFree
                                ? Colors.green
                                : AppTheme.darkGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _course!.level ?? 'ALL LEVELS',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category + enrolled count row
                  Row(
                    children: [
                      if (_categoryName.isNotEmpty) ...[
                        const Icon(Icons.category_outlined,
                            size: 14, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          _categoryName,
                          style: const TextStyle(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 14),
                      ],
                      const Icon(Icons.people_outline,
                          size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '$_enrolledCount student${_enrolledCount == 1 ? '' : 's'} enrolled',
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _course!.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Instructor section with clickable photo
                  InkWell(
                    onTap: () {
                      if (_course!.instructor?.userId != null || _course!.instructor?.id != null) {
                        final instructorId = _course!.instructor?.userId ?? _course!.instructor?.id;
                        if (instructorId != null) {
                          context.push('/student/instructor/$instructorId');
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.paleGold.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Instructor photo
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryGold.withOpacity(0.2),
                            ),
                            child: ClipOval(
                              child: _course!.instructor?.photo != null
                                  ? Image.network(
                                      ApiClient.formatMediaUrl('/api/files/${_course!.instructor!.photo}'),
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _buildInstructorAvatar(),
                                      loadingBuilder: (_, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return _buildInstructorAvatar();
                                      },
                                    )
                                  : _buildInstructorAvatar(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Instructor name and label
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Instructor',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _course!.instructor?.username ?? 'Instructor',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Chevron icon to indicate clickability
                          const Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryGold,
                labelColor: AppTheme.primaryGold,
                unselectedLabelColor: AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: 'About'),
                  Tab(text: 'Lessons'),
                  Tab(text: 'Quizzes'),
                  Tab(text: 'Comments'),
                ],
              ),
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(),
                  _buildLessonsTab(),
                  _buildQuizzesTab(),
                  _buildCommentsTab(),
                ],
              ),
            ),

            // Enrollment panel
            if (!_enrolled)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: AppTheme.mediumGray, width: 0.5),
                  ),
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _enrolling ? null : _enroll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _enrolling
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _course!.isFree
                                ? 'Enroll for Free'
                                : 'Buy Now - \$${_course!.price?.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── About Tab ──────────────────────────────────────────────────────────────
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _course!.description ?? 'No description provided.',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Instructor Spec',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.paleGold),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.paleGold,
                  child: const Icon(Icons.person, color: AppTheme.primaryGold),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _course!.instructor?.username ?? 'Instructor',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (_course!.instructor?.specialization != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          _course!.instructor!.specialization!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Lessons Tab ────────────────────────────────────────────────────────────
  Widget _buildLessonsTab() {
    if (_course!.lessons.isEmpty) {
      return const Center(
        child: Text(
          'No lessons in this course.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _course!.lessons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final lesson = _course!.lessons[i];

        // Find if lesson is completed in progress
        bool completed = false;
        if (_progress != null) {
          final lp = _progress!.lessonProgress.firstWhere(
            (p) => p.lessonId == lesson.lessonId,
            orElse: () => LessonProgress(lessonId: '', completionPercent: 0),
          );
          completed = lp.completionPercent >= 100;
        }

        return _LessonRow(
          lesson: lesson,
          index: i + 1,
          enrolled: _enrolled,
          completed: completed,
          onCompleteToggle: () async {
            final userId = context.read<AuthProvider>().userId;
            if (userId == null) return;
            await _enrollService.updateProgress(
              studentId: userId,
              courseId: widget.courseId,
              lessonId: lesson.lessonId,
              watchedSeconds: 100,
              totalSeconds: 100, // force complete
            );
            _loadAll();
          },
        );
      },
    );
  }

  // ── Quizzes Tab ────────────────────────────────────────────────────────────
  Widget _buildQuizzesTab() {
    if (!_enrolled) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 48,
                color: AppTheme.primaryGold,
              ),
              SizedBox(height: 12),
              Text(
                'Enroll to unlock quizzes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_course!.quizzes.isEmpty) {
      return const Center(
        child: Text(
          'No quizzes in this course.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _course!.quizzes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final quiz = _course!.quizzes[i];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.paleGold,
              child: const Icon(
                Icons.quiz_outlined,
                color: AppTheme.primaryGold,
              ),
            ),
            title: Text(
              quiz.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${quiz.questions.length} questions'),
            trailing: ElevatedButton(
              onPressed: () => _startQuiz(quiz),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start'),
            ),
          ),
        );
      },
    );
  }

  void _startQuiz(Quiz quiz) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _QuizPlayDialog(quiz: quiz),
    );
  }

  // ── Comments Tab ───────────────────────────────────────────────────────────
  Widget _buildCommentsTab() {
    final commentCtrl = TextEditingController();

    return Column(
      children: [
        if (_enrolled)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppTheme.primaryGold),
                  onPressed: () async {
                    final text = commentCtrl.text.trim();
                    if (text.isEmpty) return;
                    try {
                      await _instructorService.addComment(
                        widget.courseId,
                        text,
                      );
                      commentCtrl.clear();
                      _loadAll();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add comment: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        Expanded(
          child: _comments.isEmpty
              ? const Center(child: Text('No comments yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    final c = _comments[i];
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(
                        c['username'] ?? 'User',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(c['content'] ?? ''),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Lesson Row & Inline Player ───────────────────────────────────────────────
class _LessonRow extends StatefulWidget {
  final Lesson lesson;
  final int index;
  final bool enrolled;
  final bool completed;
  final VoidCallback onCompleteToggle;

  const _LessonRow({
    required this.lesson,
    required this.index,
    required this.enrolled,
    required this.completed,
    required this.onCompleteToggle,
  });

  @override
  State<_LessonRow> createState() => _LessonRowState();
}

class _LessonRowState extends State<_LessonRow> {
  VideoPlayerController? _vpController;
  bool _isPlaying = false;
  bool _loadingVideo = false;

  void _playVideo() {
    if (!widget.enrolled ||
        widget.lesson.mediaUrl == null ||
        widget.lesson.mediaUrl!.isEmpty)
      return;

    if (_vpController != null) {
      setState(() {
        if (_vpController!.value.isPlaying) {
          _vpController!.pause();
          _isPlaying = false;
        } else {
          _vpController!.play();
          _isPlaying = true;
        }
      });
      return;
    }

    setState(() => _loadingVideo = true);
    final videoUrl = ApiClient.formatMediaUrl(widget.lesson.mediaUrl);
    _vpController = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
      ..initialize()
          .then((_) {
            setState(() {
              _loadingVideo = false;
              _vpController!.play();
              _isPlaying = true;
            });
          })
          .catchError((err) {
            setState(() => _loadingVideo = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load video: $err'),
                backgroundColor: Colors.red,
              ),
            );
          });
  }

  @override
  void dispose() {
    _vpController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: widget.enrolled ? _playVideo : null,
            leading: CircleAvatar(
              backgroundColor: AppTheme.paleGold,
              child: Text(
                '${widget.index}',
                style: const TextStyle(
                  color: AppTheme.darkGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              widget.lesson.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(widget.enrolled ? 'Tap to play video' : 'Locked'),
            trailing: widget.enrolled
                ? IconButton(
                    icon: Icon(
                      widget.completed
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: widget.completed ? Colors.green : Colors.grey,
                    ),
                    onPressed: widget.onCompleteToggle,
                  )
                : const Icon(Icons.lock_outline, color: Colors.grey),
          ),
        ),
        if (_loadingVideo)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(color: AppTheme.primaryGold),
          ),
        if (_vpController != null && _vpController!.value.isInitialized)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.black,
            ),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: _vpController!.value.aspectRatio,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  VideoPlayer(_vpController!),
                  VideoProgressIndicator(_vpController!, allowScrubbing: true),
                  Center(
                    child: IconButton(
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        color: Colors.white,
                        size: 50,
                      ),
                      onPressed: _playVideo,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

// ── Interactive Quiz Dialog ──────────────────────────────────────────────────
class _QuizPlayDialog extends StatefulWidget {
  final Quiz quiz;
  const _QuizPlayDialog({required this.quiz});

  @override
  State<_QuizPlayDialog> createState() => _QuizPlayDialogState();
}

class _QuizPlayDialogState extends State<_QuizPlayDialog> {
  int _currentQuestionIdx = 0;
  int _score = 0;
  int? _selectedOptionIdx;
  bool _submitted = false;

  void _submitAnswer() {
    if (_selectedOptionIdx == null) return;
    final qst = widget.quiz.questions[_currentQuestionIdx];
    final isCorrect = qst.options[_selectedOptionIdx!].isCorrect;

    setState(() {
      _submitted = true;
      if (isCorrect) _score++;
    });
  }

  void _next() {
    if (_currentQuestionIdx < widget.quiz.questions.length - 1) {
      setState(() {
        _currentQuestionIdx++;
        _selectedOptionIdx = null;
        _submitted = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Quiz Complete! 🎉'),
        content: Text('Your score: $_score / ${widget.quiz.questions.length}'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx); // pop result
              Navigator.pop(context); // pop quiz play
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qst = widget.quiz.questions[_currentQuestionIdx];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_currentQuestionIdx + 1) / widget.quiz.questions.length,
              color: AppTheme.primaryGold,
              backgroundColor: AppTheme.paleGold,
            ),
            const SizedBox(height: 16),
            Text(
              'Question ${_currentQuestionIdx + 1} of ${widget.quiz.questions.length}',
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Text(
              qst.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: qst.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, idx) {
                  final opt = qst.options[idx];
                  final isSelected = _selectedOptionIdx == idx;

                  Color cardColor = Colors.white;
                  Color textColor = AppTheme.textPrimary;
                  if (isSelected) {
                    cardColor = AppTheme.primaryGold.withOpacity(0.12);
                    textColor = AppTheme.primaryGold;
                  }
                  if (_submitted) {
                    if (opt.isCorrect) {
                      cardColor = Colors.green.withOpacity(0.12);
                      textColor = Colors.green;
                    } else if (isSelected) {
                      cardColor = Colors.red.withOpacity(0.12);
                      textColor = Colors.red;
                    }
                  }

                  return GestureDetector(
                    onTap: _submitted
                        ? null
                        : () => setState(() => _selectedOptionIdx = idx),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryGold
                              : Colors.grey[200]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              opt.text,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (_submitted && opt.isCorrect)
                            const Icon(Icons.check_circle, color: Colors.green)
                          else if (_submitted && isSelected && !opt.isCorrect)
                            const Icon(Icons.cancel, color: Colors.red),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: ElevatedButton(
                onPressed: _selectedOptionIdx == null
                    ? null
                    : (_submitted ? _next : _submitAnswer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(_submitted ? 'Next' : 'Submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
