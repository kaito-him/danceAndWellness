import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../models/instructor_profile.dart';
import '../../models/notification_model.dart';
import '../../services/instructor_service.dart';
import '../../services/notification_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/course_editor_bottom_sheet.dart';
import '../../widgets/course_details_bottom_sheet.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart' as dio_pkg;

class InstructorHomeScreen extends StatefulWidget {
  final TabController? tabController;
  const InstructorHomeScreen({super.key, this.tabController});

  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _instructorService = InstructorDashboardService();
  final _notifService = NotificationApiService();


  InstructorProfile? _profile;
  List<Course> _publishedCourses = [];
  List<Course> _draftCourses = [];
  Map<String, int> _enrollmentCounts = {};
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  List<Map<String, dynamic>> _categories = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
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
      final results = await Future.wait([
        _instructorService.getProfileByUserId(userId),
        _instructorService.getPublishedCourses(),
        _instructorService.getDraftCourses(),
        _notifService.getNotifications(),
        _notifService.getUnreadCount(),
        _instructorService.getCategories(),
      ]);

      if (!mounted) return;

      // Update global notification provider
      context.read<NotificationProvider>().fetchUnreadCount();

      final published = results[1] as List<Course>;

      // Fetch enrollment counts for published courses
      final counts = <String, int>{};
      await Future.wait(published.map((c) async {
        counts[c.courseId] =
            await _instructorService.getEnrollmentCount(c.courseId);
      }));

      if (!mounted) return;
      setState(() {
        _profile = results[0] as InstructorProfile;
        _publishedCourses = published;
        _draftCourses = results[2] as List<Course>;
        _enrollmentCounts = counts;
        _notifications = results[3] as List<NotificationModel>;
        _unreadCount = results[4] as int;
        _categories = results[5] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  int get _totalStudents =>
      _enrollmentCounts.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    if (_error != null) {
      return _buildError();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: _buildCoursesTab(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCourseDialog(),
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Course', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
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
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Overview Tab ───────────────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      color: AppTheme.primaryGold,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Dashboard'),
                ElevatedButton.icon(
                  onPressed: _showAddCourseDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'Add Course',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProfileCard(),
            const SizedBox(height: 20),
            _buildStatsRow(),
            const SizedBox(height: 20),
            _sectionTitle('Published Courses'),
            const SizedBox(height: 12),
            if (_publishedCourses.isEmpty)
              _emptyState('No published courses yet', Icons.menu_book_outlined)
            else
              ..._publishedCourses
                  .take(3)
                  .map((c) => _buildCourseCard(c, showEnrollments: true))
                  .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final p = _profile;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGold, AppTheme.primaryGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppTheme.pureWhite.withValues(alpha: 0.3),
            child: const Icon(Icons.person, size: 34, color: AppTheme.pureWhite),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p?.username ?? 'Instructor',
                  style: const TextStyle(
                      color: AppTheme.pureWhite,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
                if (p?.specialization != null) ...[
                  const SizedBox(height: 2),
                  Text(p!.specialization!,
                      style: TextStyle(
                          color: AppTheme.pureWhite.withValues(alpha: 0.85),
                          fontSize: 13)),
                ],
                if (p?.studioName != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.business_outlined,
                          size: 13,
                          color: AppTheme.pureWhite.withValues(alpha: 0.7)),
                      const SizedBox(width: 4),
                      Text(p!.studioName!,
                          style: TextStyle(
                              color: AppTheme.pureWhite.withValues(alpha: 0.7),
                              fontSize: 12)),
                    ],
                  ),
                ],
                if (p?.featured == true) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.pureWhite.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, size: 12, color: AppTheme.pureWhite),
                        SizedBox(width: 4),
                        Text('Featured Instructor',
                            style: TextStyle(
                                color: AppTheme.pureWhite,
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _statCard('Published', '${_publishedCourses.length}',
            Icons.check_circle_outline),
        const SizedBox(width: 10),
        _statCard('Drafts', '${_draftCourses.length}',
            Icons.edit_note_outlined),
        const SizedBox(width: 10),
        _statCard('Students', '$_totalStudents',
            Icons.people_outline),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppTheme.pureWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.paleGold),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGold, size: 24),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.textPrimary)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Courses Tab ────────────────────────────────────────────────────────────
  Widget _buildCoursesTab() {
    final paidCourses = _publishedCourses.where((c) => !c.isFree).toList();
    final freeCourses = _publishedCourses.where((c) => c.isFree).toList();

    return RefreshIndicator(
      color: AppTheme.primaryGold,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Paid Courses ───────────────────────────────────────────────
            _buildCourseSection(
              title: 'Paid Courses',
              icon: Icons.attach_money_rounded,
              courses: paidCourses,
              emptyMessage: 'No paid courses yet',
            ),
            const SizedBox(height: 28),

            // ── Free Courses ───────────────────────────────────────────────
            _buildCourseSection(
              title: 'Free Courses',
              icon: Icons.card_giftcard_rounded,
              courses: freeCourses,
              emptyMessage: 'No free courses yet',
            ),

            // ── Drafts ─────────────────────────────────────────────────────
            if (_draftCourses.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildCourseSection(
                title: 'Drafts',
                icon: Icons.edit_note_outlined,
                courses: _draftCourses,
                emptyMessage: 'No drafts',
                isDraft: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourseSection({
    required String title,
    required IconData icon,
    required List<Course> courses,
    required String emptyMessage,
    bool isDraft = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppTheme.paleGold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: AppTheme.primaryGold),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.paleGold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${courses.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkGold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Horizontal scroll list
        if (courses.isEmpty)
          Container(
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.paleGold,
                style: BorderStyle.solid,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    emptyMessage,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) {
                final course = courses[i];
                return _buildCourseCard(
                  course,
                  showEnrollments: !isDraft,
                  onTap: () {
                    if (isDraft) {
                      _showAddCourseDialog(editCourse: course);
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(Course course, {required bool showEnrollments, VoidCallback? onTap}) {
    final enrollments = _enrollmentCounts[course.courseId] ?? 0;
    final thumbUrl = course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
        ? ApiClient.formatMediaUrl(course.thumbnailUrl)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.paleGold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: thumbUrl != null
                    ? Image.network(
                        thumbUrl,
                        height: 100,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _courseThumbnailPlaceholder(),
                      )
                    : _courseThumbnailPlaceholder(),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    shape: BoxShape.circle,
                  ),
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showAddCourseDialog(editCourse: course);
                      } else if (value == 'archive') {
                        _confirmArchiveCourse(course);
                      } else if (value == 'delete') {
                        _confirmDeleteDraft(course);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 18, color: AppTheme.textPrimary),
                            SizedBox(width: 8),
                            Text('Edit / View'),
                          ],
                        ),
                      ),
                      if (course.status == 'DRAFT')
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Delete Draft', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        )
                      else
                        const PopupMenuItem<String>(
                          value: 'archive',
                          child: Row(
                            children: [
                              Icon(Icons.archive_outlined, size: 18, color: Colors.redAccent),
                              SizedBox(width: 8),
                              Text('Archive', style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      _chip(
                        course.level ?? 'N/A',
                        AppTheme.primaryGold.withValues(alpha: 0.12),
                        AppTheme.primaryGold,
                      ),
                      const SizedBox(width: 5),
                      _chip(
                        course.isFree
                            ? 'Free'
                            : '\$${course.price?.toStringAsFixed(0)}',
                        AppTheme.paleGold,
                        AppTheme.darkGold,
                      ),
                    ],
                  ),
                  if (showEnrollments) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.people_outline,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '$enrollments enrolled',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.play_circle_outline,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Text(
                          '${course.lessonCount}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
            ],
          ),
        ),
      ),
      ],
      ),
      ),
    );
  }

  Future<void> _confirmArchiveCourse(Course course) async {
    final enrollments = _enrollmentCounts[course.courseId] ?? 0;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.archive_outlined, color: AppTheme.primaryGold, size: 24),
            SizedBox(width: 8),
            Text('Archive Course'),
          ],
        ),
        content: Text(
          'Are you sure you want to archive "${course.title}"?\n\n'
          'This will remove it from the public catalog. '
          '${!course.isFree && enrollments > 0 ? "\n\nWarning: Paid courses with active enrollments cannot be archived." : ""}'
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _instructorService.archiveCourseByInstructor(course.courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course archived successfully!'), backgroundColor: Colors.green),
        );
        _loadAll();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to archive course: ${e.toString().replaceFirst('Exception: ', '')}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _confirmDeleteDraft(Course course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Draft'),
          ],
        ),
        content: const Text('Are you sure you want to permanently delete this draft course? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _instructorService.deleteCourse(course.courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft deleted successfully!'), backgroundColor: Colors.green),
        );
        _loadAll();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete draft: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _courseThumbnailPlaceholder() {
    return Container(
      height: 100,
      width: double.infinity,
      color: AppTheme.paleGold,
      child: const Icon(
        Icons.menu_book_outlined,
        color: AppTheme.primaryGold,
        size: 36,
      ),
    );
  }

  void _showAddCourseDialog({Course? editCourse}) {
    if (editCourse != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CourseDetailsBottomSheet(
          editCourse: editCourse,
          categories: _categories,
          onSaved: _loadAll,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => CourseEditorBottomSheet(
          categories: _categories,
          onSaved: _loadAll,
        ),
      );
    }
  }

  void _showSnackBar(BuildContext context, String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryGold, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _dialogSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
    );
  }

  Future<String> _uploadFile(File file) async {
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    
    String type = 'image';
    if (['mp4', 'mov', 'webm', 'avi'].contains(ext)) type = 'video';

    final formData = dio_pkg.FormData.fromMap({
      'file': await dio_pkg.MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType(type, ext == 'jpg' ? 'jpeg' : ext),
      ),
    });

    final apiClient = ApiClient();
    final response = await apiClient.dio.post('/api/files/upload', data: formData);
    return response.data['url'] as String;
  }

  Future<void> _createFullCourse({
    required String title,
    required String description,
    required String level,
    required String? categoryId,
    required bool isFree,
    required double price,
    required String thumbnailUrl,
    required List<dynamic> lessons,
    required List<dynamic> quizzes,
    bool isDraft = false,
  }) async {
    final apiClient = ApiClient();
    final path = isDraft ? '/courses/draft' : '/courses';
    await apiClient.dio.post(path, data: {
      'title': title,
      'description': description,
      'level': level,
      'categoryId': categoryId,
      'isFree': isFree,
      'price': price,
      'thumbnailUrl': thumbnailUrl,
      'lessons': lessons,
      'quizzes': quizzes,
    });
  }

  Future<void> _createCourse({
    required String title,
    required String description,
    required String level,
    required bool isFree,
    double? price,
  }) async {
    final apiClient = ApiClient();
    await apiClient.dio.post('/courses', data: {
      'title': title,
      if (description.isNotEmpty) 'description': description,
      'level': level,
      'isFree': isFree,
      if (!isFree && price != null) 'price': price,
    });
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ── Notifications Tab ──────────────────────────────────────────────────────
  Widget _buildNotificationsTab() {
    return Column(
      children: [
        if (_unreadCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$_unreadCount unread',
                    style: const TextStyle(
                        color: AppTheme.textSecondary, fontSize: 13)),
                TextButton(
                  onPressed: () async {
                    await _notifService.markAllRead();
                    _loadAll();
                  },
                  child: const Text('Mark all read'),
                ),
              ],
            ),
          ),
        Expanded(
          child: _notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none,
                          size: 56, color: AppTheme.primaryGold),
                      SizedBox(height: 12),
                      Text('No notifications yet',
                          style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryGold,
                  onRefresh: _loadAll,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) =>
                        _buildNotifTile(_notifications[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNotifTile(NotificationModel n) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: n.read ? AppTheme.lightGray : AppTheme.paleGold,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _notifIcon(n.type),
          color: n.read ? AppTheme.textSecondary : AppTheme.primaryGold,
          size: 20,
        ),
      ),
      title: Text(n.message,
          style: TextStyle(
              fontSize: 13,
              color: AppTheme.textPrimary,
              fontWeight: n.read ? FontWeight.normal : FontWeight.w600),
          maxLines: 3,
          overflow: TextOverflow.ellipsis),
      subtitle: n.createdAt != null
          ? Text(_formatDate(n.createdAt!),
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary))
          : null,
      onTap: () async {
        if (!n.read) {
          await _notifService.markRead(n.id);
          setState(() => _unreadCount = (_unreadCount - 1).clamp(0, 999));
        }
      },
    );
  }

  IconData _notifIcon(String? type) {
    switch (type) {
      case 'COURSE_ENROLLMENT':
        return Icons.person_add_outlined;
      case 'FEATURED':
        return Icons.star_outline;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppTheme.textPrimary));

  Widget _emptyState(String msg, IconData icon) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: AppTheme.primaryGold),
              const SizedBox(height: 12),
              Text(msg,
                  style: const TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        ),
      );
}

