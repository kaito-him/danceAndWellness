import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:provider/provider.dart';

import '../../models/course.dart';
import '../../services/instructor_service.dart';
import '../../services/course_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/api_client.dart';
import '../../services/comment_service.dart';
import '../../utils/app_theme.dart';
import '../../models/comment.dart';
import '../../models/lesson.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/course_details_bottom_sheet.dart';
import 'instructor_student_profile_screen.dart';

class InstructorCourseDetailScreen extends StatefulWidget {
  final String courseId;
  const InstructorCourseDetailScreen({super.key, required this.courseId});

  @override
  State<InstructorCourseDetailScreen> createState() =>
      _InstructorCourseDetailScreenState();
}

class _InstructorCourseDetailScreenState
    extends State<InstructorCourseDetailScreen>
    with SingleTickerProviderStateMixin {
  final _instructorService = InstructorDashboardService();
  final _courseService = CourseService();
  final _enrollmentService = EnrollmentService();
  final _commentService = CommentService();

  late TabController _tabController;

  Course? _course;
  int _enrollmentCount = 0;
  String _categoryName = '';
  List<EnrollmentRow> _enrollments = [];
  List<Comment> _comments = [];
  List<Map<String, dynamic>> _categories = [];
  
  // Comment functionality state
  Map<String, List<Comment>> _replies = {}; // commentId -> list of replies
  Map<String, bool> _showReplies = {}; // commentId -> bool
  Map<String, bool> _repliesFetched = {}; // commentId -> bool
  Map<String, bool> _loadingReplies = {}; // commentId -> bool
  final TextEditingController _commentController = TextEditingController();
  Map<String, TextEditingController> _replyControllers = {}; // commentId -> controller
  bool _postingComment = false;
  Map<String, bool> _postingReply = {}; // commentId -> bool
  Map<String, bool> _liking = {}; // commentId -> bool

  // Lesson video player state
  Lesson? _activeLesson;
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Student progress state
  EnrollmentRow? _selectedEnrollment;
  StudentProgress? _studentProgress;
  bool _loadingProgress = false;

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCourse();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    _commentController.dispose();
    _replyControllers.forEach((_, controller) => controller.dispose());
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
        _instructorService.getComments(widget.courseId),
        _enrollmentService.getCourseEnrollments(widget.courseId),
        _instructorService.getCategories(),
      ]);

      final course = results[0] as Course;
      final count = results[1] as int;
      final comments = results[2] as List<Map<String, dynamic>>;
      final enrollments = results[3] as List<EnrollmentRow>;
      final categories = results[4] as List<Map<String, dynamic>>;

      String catName = '';
      if (course.categoryId != null && course.categoryId!.isNotEmpty) {
        catName = await _courseService.getCategoryName(course.categoryId!);
      }

      if (mounted) {
        setState(() {
          _course = course;
          _enrollmentCount = count;
          _categoryName = catName;
          _comments = comments.map((c) => Comment.fromJson(c)).toList();
          _enrollments = enrollments;
          _categories = categories;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _openEditSheet() {
    if (_course == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CourseDetailsBottomSheet(
        editCourse: _course,
        categories: _categories,
        onSaved: _loadCourse,
      ),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.white,
          title: const Text('Course Details'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.white,
          title: const Text('Course Details'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 56, color: AppTheme.errorGold),
                const SizedBox(height: 16),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadCourse,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        title: Text(_course?.title ?? 'Course Details'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit') _openEditSheet();
            },
            itemBuilder: (_) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18, color: AppTheme.textPrimary),
                    SizedBox(width: 10),
                    Text('Edit Course'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.info_outline)),
            Tab(text: 'Analytics', icon: Icon(Icons.bar_chart)),
            Tab(text: 'Comments', icon: Icon(Icons.comment_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildAnalyticsTab(),
          _buildCommentsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (_course == null) return const SizedBox();

    final thumbUrl = _course!.thumbnailUrl != null &&
            _course!.thumbnailUrl!.isNotEmpty
        ? ApiClient.formatMediaUrl(_course!.thumbnailUrl)
        : null;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          if (thumbUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                thumbUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildThumbnailPlaceholder(),
              ),
            )
          else
            _buildThumbnailPlaceholder(),

          const SizedBox(height: 20),

          // Title
          Text(
            _course!.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 12),

          // Tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(_categoryName.isEmpty ? 'Category' : _categoryName,
                  AppTheme.primaryGold.withValues(alpha: 0.12), AppTheme.primaryGold),
              _chip(_course!.level ?? 'N/A',
                  AppTheme.paleGold, AppTheme.darkGold),
              _chip(_course!.isFree ? 'Free' : '\$${_course!.price}',
                  AppTheme.paleGold, AppTheme.darkGold),
            ],
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              _statItem(Icons.people_outline, '$_enrollmentCount', 'Enrolled'),
              const SizedBox(width: 24),
              _statItem(Icons.play_circle_outline, '${_course!.lessonCount}', 'Lessons'),
            ],
          ),

          const SizedBox(height: 20),

          // Description
          const Text(
            'Description',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _course!.description ?? 'No description',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 20),

          // Lessons
          _buildLessonsSection(),
        ],
      ),
    );
  }

  Widget _buildLessonsSection() {
    final lessons = _course!.lessons;
    if (lessons == null || lessons.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lessons',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...lessons.asMap().entries.map((entry) {
          final idx = entry.key;
          final lesson = entry.value;
          final isActive = _activeLesson?.lessonId == lesson.lessonId;

          return Column(
            children: [
              GestureDetector(
                onTap: () {
                  if (isActive) {
                    _closeLessonVideo();
                  } else {
                    _playLessonVideo(lesson);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryGold.withValues(alpha: 0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive ? AppTheme.primaryGold : AppTheme.paleGold,
                      width: isActive ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.paleGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
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
                              lesson.title ?? 'Untitled Lesson',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (lesson.duration != null)
                              Row(
                                children: [
                                  const Icon(Icons.play_circle_outline,
                                      size: 12, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${lesson.duration} min',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.primaryGold : AppTheme.paleGold,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              isActive ? 'Watching' : 'Watch',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isActive ? Colors.white : AppTheme.darkGold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isActive ? Icons.expand_less : Icons.expand_more,
                              size: 16,
                              color: isActive ? Colors.white : AppTheme.darkGold,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isActive && _chewieController != null) ...[
                const SizedBox(height: 12),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Chewie(controller: _chewieController!),
                ),
              ],
              if (isActive && _chewieController == null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.paleGold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.video_library_outlined,
                            size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 8),
                        Text(
                          'No video available',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    // If showing student progress
    if (_selectedEnrollment != null) {
      return _buildStudentProgressView();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enrollment Stats
          const Text(
            'Enrollment Analytics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Summary Cards
          Row(
            children: [
              _analyticsCard('Total Enrolled', '$_enrollmentCount',
                  Icons.people, AppTheme.primaryGold),
              const SizedBox(width: 12),
              _analyticsCard('Active Students', '${_enrollments.length}',
                  Icons.trending_up, Colors.green),
            ],
          ),

          const SizedBox(height: 24),

          // Enrolled Students List
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enrolled Students',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.paleGold,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_enrollments.length}',
                  style: const TextStyle(
                    color: AppTheme.darkGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_enrollments.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'No enrollments yet',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ),
            )
          else
            ..._enrollments.map((enrollment) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => _loadStudentProgress(enrollment),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildAvatar(enrollment.studentName, enrollment.studentPhoto, 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => InstructorStudentProfileScreen(
                                      studentUserId: enrollment.studentId,
                                      studentName: enrollment.studentName,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                enrollment.studentName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.primaryGold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enrolled: ${_formatDate(enrollment.enrolledAt)}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: enrollment.enrollmentType == 'PAID'
                              ? AppTheme.primaryGold.withValues(alpha: 0.15)
                              : AppTheme.successGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          enrollment.enrollmentType,
                          style: TextStyle(
                            color: enrollment.enrollmentType == 'PAID'
                                ? AppTheme.darkGold
                                : AppTheme.successGold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.bar_chart, size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Progress',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildStudentProgressView() {
    if (_loadingProgress) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            children: [
              CircularProgressIndicator(color: AppTheme.primaryGold),
              SizedBox(height: 16),
              Text('Loading progress...'),
            ],
          ),
        ),
      );
    }

    if (_studentProgress == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 48, color: AppTheme.errorGold),
                    SizedBox(height: 16),
                    Text('Unable to load progress'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _closeStudentProgress,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Enrollments'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final progress = _studentProgress!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _closeStudentProgress,
              ),
              Expanded(
                child: Text(
                  '${_selectedEnrollment!.studentName}\'s Progress',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats Cards
          Row(
            children: [
              _analyticsCard(
                'Global Progress',
                '${progress.completionPercent.toStringAsFixed(0)}%',
                Icons.pie_chart,
                AppTheme.primaryGold,
              ),
              const SizedBox(width: 12),
              _analyticsCard(
                'Completed',
                '${progress.completedLessons}/${progress.totalLessons}',
                Icons.check_circle,
                Colors.green,
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (progress.lastUpdated != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.update, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'Last Updated: ${_formatDate(progress.lastUpdated)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Lesson Progress Table
          const Text(
            'Lesson Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          ...progress.lessonProgress.map((lp) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      lp.lessonTitle ?? 'Lesson',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getProgressColor(lp.completionPercent).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${lp.completionPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: _getProgressColor(lp.completionPercent),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent >= 80) return Colors.green;
    if (percent >= 50) return Colors.orange;
    return Colors.red;
  }

  Widget _buildCommentsTab() {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userId;
    final currentUsername = authProvider.username;

    return Column(
      children: [
        // Compose new comment section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppTheme.paleGold, width: 1),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatar(currentUsername, null, 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        hintStyle: TextStyle(color: AppTheme.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppTheme.paleGold),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide(color: AppTheme.primaryGold),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _postingComment
                              ? null
                              : () => _postComment(currentUserId ?? ''),
                          icon: _postingComment
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, size: 16),
                          label: Text(_postingComment ? 'Posting...' : 'Post'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Comments list
        Expanded(
          child: _comments.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.comment_outlined,
                            size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _comments.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final comment = _comments[index];
                    return _buildCommentItem(
                      comment,
                      currentUserId ?? '',
                      currentUsername ?? '',
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCommentItem(
    Comment comment,
    String currentUserId,
    String currentUsername,
  ) {
    final authProvider = context.read<AuthProvider>();
    final currentUserRole = authProvider.role?.value;
    final isInstructorAuthor = comment.authorId == currentUserId;
    final isOwn = comment.authorId == currentUserId;
    final isLiked = comment.likedByUserIds.contains(currentUserId);
    final likeCount = comment.likedByUserIds.length;
    final showInstructorHighlight = isInstructorAuthor && comment.authorRole == 'INSTRUCTOR';
    final canDelete = currentUserRole == 'INSTRUCTOR' || currentUserRole == 'ADMIN' || isOwn;

    // Separate instructor comments (highlighted at top) from regular comments
    // This is already handled by the API returning instructor comments first

    return Container(
      decoration: BoxDecoration(
        color: showInstructorHighlight ? const Color(0xFFFFFAF0) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: showInstructorHighlight
            ? Border.all(color: const Color(0xFFF2DEC4))
            : null,
      ),
      padding: EdgeInsets.all(showInstructorHighlight ? 16 : 0),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Comment header
              Row(
                children: [
                  _buildAvatar(comment.authorUsername, comment.authorPhoto, 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              comment.authorUsername,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (comment.authorRole != null &&
                                comment.authorRole != 'STUDENT') ...[
                              const SizedBox(width: 8),
                              _buildRoleBadge(comment.authorRole!),
                            ],
                          ],
                        ),
                        Text(
                          _timeAgo(comment.createdAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Three-dot menu for delete
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(comment.commentId);
                      }
                    },
                    itemBuilder: (context) => [
                      if (canDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 16),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Comment content
              Text(
                comment.content,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 12),
              // Comment actions
              Row(
                children: [
                  // Like button
                  InkWell(
                    onTap: () => _toggleLike(comment.commentId),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLiked
                            ? const Color(0xFFFFFCF8)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isLiked
                              ? const Color(0xFFEADDC0)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 12,
                            color: isLiked
                                ? AppTheme.primaryGold
                                : AppTheme.textSecondary,
                          ),
                          if (likeCount > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '$likeCount',
                              style: TextStyle(
                                fontSize: 12,
                                color: isLiked
                                    ? AppTheme.primaryGold
                                    : AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reply button
                  InkWell(
                    onTap: () => _toggleReplyBox(comment.commentId),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.reply, size: 12),
                          SizedBox(width: 4),
                          Text('Reply', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Show/hide replies button
                  if (_replies[comment.commentId]?.isNotEmpty ?? false)
                    InkWell(
                      onTap: () => _toggleShowReplies(comment.commentId),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _showReplies[comment.commentId] ?? false
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${_replies[comment.commentId]!.length} replies',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              // Reply box
              if (_replyControllers.containsKey(comment.commentId))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAvatar(currentUsername, null, 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _replyControllers[comment.commentId],
                              decoration: InputDecoration(
                                hintText: 'Write a reply...',
                                hintStyle:
                                    TextStyle(color: AppTheme.textSecondary),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: AppTheme.paleGold),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      BorderSide(color: AppTheme.primaryGold),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              maxLines: 2,
                              minLines: 1,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () =>
                                      _toggleReplyBox(comment.commentId),
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _postingReply[comment.commentId] ==
                                          true
                                      ? null
                                      : () =>
                                          _postReply(comment.commentId, currentUserId),
                                  icon: _postingReply[comment.commentId] ==
                                          true
                                      ? const SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.send, size: 14),
                                  label: Text(_postingReply[comment.commentId] ==
                                          true
                                      ? 'Sending...'
                                      : 'Reply'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Replies section
              if (_showReplies[comment.commentId] ?? false)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 44),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_loadingReplies[comment.commentId] ?? false)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGold,
                            ),
                          ),
                        )
                      else
                        ...(_replies[comment.commentId] ?? []).map((reply) =>
                            _buildReplyItem(reply, currentUserId, currentUsername)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReplyItem(
    Comment reply,
    String currentUserId,
    String currentUsername,
  ) {
    final authProvider = context.read<AuthProvider>();
    final currentUserRole = authProvider.role?.value;
    final isOwn = reply.authorId == currentUserId;
    final isLiked = reply.likedByUserIds.contains(currentUserId);
    final likeCount = reply.likedByUserIds.length;
    final canDelete = currentUserRole == 'INSTRUCTOR' || currentUserRole == 'ADMIN' || isOwn;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(reply.authorUsername, reply.authorPhoto, 28),
          const SizedBox(width: 8),
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
                        fontSize: 13,
                      ),
                    ),
                    if (reply.authorRole != null &&
                        reply.authorRole != 'STUDENT') ...[
                      const SizedBox(width: 6),
                      _buildRoleBadge(reply.authorRole!),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(reply.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.content,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Like button
                    InkWell(
                      onTap: () => _toggleLike(reply.commentId),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isLiked
                              ? const Color(0xFFFFFCF8)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLiked
                                ? const Color(0xFFEADDC0)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 11,
                              color: isLiked
                                  ? AppTheme.primaryGold
                                  : AppTheme.textSecondary,
                            ),
                            if (likeCount > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '$likeCount',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isLiked
                                      ? AppTheme.primaryGold
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Delete button
                    if (canDelete)
                      InkWell(
                        onTap: () => _showDeleteDialog(reply.commentId),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.delete,
                            size: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
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

  Widget _buildAvatar(String? username, String? photo, double size) {
    final initial = (username != null && username.isNotEmpty) ? username[0].toUpperCase() : '?';
    
    if (photo != null && photo.isNotEmpty) {
      // Format the URL to match the backend's expected format
      String photoUrl = photo;
      if (!photo.startsWith('http')) {
        // If it's just a file ID, prepend the base URL
        final baseUrl = ApiClient.baseUrl.replaceFirst('/api', '');
        photoUrl = '$baseUrl/api/files/$photo';
      } else {
        photoUrl = ApiClient.formatMediaUrl(photo);
      }
      
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildAvatarFallback(initial, size),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildAvatarFallback(initial, size);
          },
        ),
      );
    }
    
    return _buildAvatarFallback(initial, size);
  }

  Widget _buildAvatarFallback(String initial, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppTheme.paleGold,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: AppTheme.primaryGold,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bgColor;
    Color textColor;
    
    switch (role.toUpperCase()) {
      case 'INSTRUCTOR':
        bgColor = const Color(0xFFFFFCF8);
        textColor = const Color(0xFFBFA36C);
        break;
      case 'ADMIN':
        bgColor = Colors.white;
        textColor = const Color(0xFFCDA85C);
        break;
      default:
        bgColor = AppTheme.paleGold;
        textColor = AppTheme.primaryGold;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppTheme.paleGold,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.menu_book_outlined,
        size: 64,
        color: AppTheme.primaryGold,
      ),
    );
  }

  Widget _chip(String label, Color backgroundColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGold),
        const SizedBox(width: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _analyticsCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.paleGold),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    try {
      final dt = date is String ? DateTime.parse(date) : date as DateTime;
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return 'Unknown';
    }
  }

  Future<void> _loadStudentProgress(EnrollmentRow enrollment) async {
    setState(() {
      _selectedEnrollment = enrollment;
      _loadingProgress = true;
    });

    try {
      final progress = await _enrollmentService.getStudentProgress(
        enrollment.studentId,
        widget.courseId,
      );
      if (mounted) {
        setState(() {
          _studentProgress = progress;
          _loadingProgress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _studentProgress = null;
          _loadingProgress = false;
        });
      }
    }
  }

  Future<void> _playLessonVideo(Lesson lesson) async {
    // Dispose previous controller
    _videoController?.dispose();
    _chewieController?.dispose();

    if (lesson.mediaUrl == null || lesson.mediaUrl!.isEmpty) {
      setState(() {
        _activeLesson = lesson;
        _videoController = null;
        _chewieController = null;
      });
      return;
    }

    try {
      final videoUrl = ApiClient.formatMediaUrl(lesson.mediaUrl!);
      final controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await controller.initialize();

      if (mounted) {
        final chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
        );

        setState(() {
          _activeLesson = lesson;
          _videoController = controller;
          _chewieController = chewieController;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _activeLesson = lesson;
          _videoController = null;
          _chewieController = null;
        });
      }
    }
  }

  void _closeLessonVideo() {
    _videoController?.dispose();
    _chewieController?.dispose();
    setState(() {
      _activeLesson = null;
      _videoController = null;
      _chewieController = null;
    });
  }

  void _closeStudentProgress() {
    setState(() {
      _selectedEnrollment = null;
      _studentProgress = null;
    });
  }

  // Comment-related helper methods
  Future<void> _postComment(String userId) async {
    final content = _commentController.text.trim();
    if (content.isEmpty || userId.isEmpty) return;

    setState(() {
      _postingComment = true;
    });

    try {
      final newComment = await _instructorService.addComment(widget.courseId, content);
      
      if (mounted) {
        setState(() {
          _comments.insert(0, Comment.fromJson(newComment));
          _commentController.clear();
          _postingComment = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postingComment = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post comment: $e')),
        );
      }
    }
  }

  Future<void> _toggleLike(String commentId) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.userId;
    if (currentUserId == null) return;

    // Find the comment in the list
    final commentIndex = _comments.indexWhere((c) => c.commentId == commentId);
    if (commentIndex == -1) {
      // Check if it's a reply
      for (final replies in _replies.values) {
        final replyIndex = replies.indexWhere((r) => r.commentId == commentId);
        if (replyIndex != -1) {
          final isLiked = replies[replyIndex].likedByUserIds.contains(currentUserId);
          setState(() {
            _liking[commentId] = true;
          });

          try {
            if (isLiked) {
              await _commentService.unlikeComment(widget.courseId, commentId);
              replies[replyIndex] = Comment.fromJson({
                ...replies[replyIndex].toJson(),
                'likedByUserIds': List.from(replies[replyIndex].likedByUserIds)..remove(currentUserId),
              });
            } else {
              await _commentService.likeComment(widget.courseId, commentId);
              replies[replyIndex] = Comment.fromJson({
                ...replies[replyIndex].toJson(),
                'likedByUserIds': List.from(replies[replyIndex].likedByUserIds)..add(currentUserId),
              });
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to toggle like: $e')),
            );
          } finally {
            if (mounted) {
              setState(() {
                _liking[commentId] = false;
              });
            }
          }
          return;
        }
      }
      return;
    }

    final isLiked = _comments[commentIndex].likedByUserIds.contains(currentUserId);
    setState(() {
      _liking[commentId] = true;
    });

    try {
      if (isLiked) {
        await _commentService.unlikeComment(widget.courseId, commentId);
        setState(() {
          _comments[commentIndex] = Comment.fromJson({
            ..._comments[commentIndex].toJson(),
            'likedByUserIds': List.from(_comments[commentIndex].likedByUserIds)..remove(currentUserId),
          });
          _liking[commentId] = false;
        });
      } else {
        await _commentService.likeComment(widget.courseId, commentId);
        setState(() {
          _comments[commentIndex] = Comment.fromJson({
            ..._comments[commentIndex].toJson(),
            'likedByUserIds': List.from(_comments[commentIndex].likedByUserIds)..add(currentUserId),
          });
          _liking[commentId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _liking[commentId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to toggle like: $e')),
        );
      }
    }
  }

  void _toggleReplyBox(String commentId) {
    setState(() {
      if (_replyControllers.containsKey(commentId)) {
        _replyControllers.remove(commentId);
        _replyControllers[commentId]?.dispose();
      } else {
        _replyControllers[commentId] = TextEditingController();
      }
    });
  }

  Future<void> _postReply(String commentId, String userId) async {
    final controller = _replyControllers[commentId];
    if (controller == null) return;

    final content = controller.text.trim();
    if (content.isEmpty || userId.isEmpty) return;

    setState(() {
      _postingReply[commentId] = true;
    });

    try {
      final newReply = await _instructorService.addReply(widget.courseId, commentId, content);
      
      if (mounted) {
        setState(() {
          if (!_replies.containsKey(commentId)) {
            _replies[commentId] = [];
          }
          _replies[commentId]!.add(Comment.fromJson(newReply));
          _showReplies[commentId] = true;
          _replyControllers.remove(commentId);
          controller.dispose();
          _postingReply[commentId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _postingReply[commentId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post reply: $e')),
        );
      }
    }
  }

  Future<void> _toggleShowReplies(String commentId) async {
    if (_showReplies[commentId] == true) {
      setState(() {
        _showReplies[commentId] = false;
      });
      return;
    }

    if (_repliesFetched[commentId] != true) {
      setState(() {
        _loadingReplies[commentId] = true;
      });

      try {
        final repliesData = await _instructorService.getReplies(widget.courseId, commentId);
        
        if (mounted) {
          setState(() {
            _replies[commentId] = repliesData.map((r) => Comment.fromJson(r)).toList();
            _repliesFetched[commentId] = true;
            _loadingReplies[commentId] = false;
            _showReplies[commentId] = true;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadingReplies[commentId] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load replies: $e')),
          );
        }
      }
    } else {
      setState(() {
        _showReplies[commentId] = true;
      });
    }
  }

  void _showDeleteDialog(String commentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteComment(commentId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await _commentService.deleteComment(widget.courseId, commentId);
      
      if (mounted) {
        setState(() {
          _comments.removeWhere((c) => c.commentId == commentId);
          // Also remove from replies if it's a reply
          for (final key in _replies.keys) {
            _replies[key]!.removeWhere((r) => r.commentId == commentId);
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete comment: $e')),
        );
      }
    }
  }
}
