import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../services/student_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/course_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import 'student_course_detail_screen.dart';

class StudentLibraryTab extends StatefulWidget {
  const StudentLibraryTab({super.key});

  @override
  State<StudentLibraryTab> createState() => _StudentLibraryTabState();
}

class _StudentLibraryTabState extends State<StudentLibraryTab> {
  final _studentService = StudentService();
  final _enrollService = EnrollmentService();
  final _courseService = CourseService();

  List<Course> _paidCourses = [];
  List<Course> _freeCourses = [];
  Map<String, StudentProgress?> _progressMap = {};
  Map<String, int> _enrolledCountMap = {};
  Map<String, String> _categoryNameMap = {};

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Fetch paid + free courses in parallel
      final results = await Future.wait([
        _studentService.getStudentPaidCourses(userId),
        _studentService.getStudentFreeCourses(userId),
      ]);

      final paid = results[0] as List<Course>;
      final free = results[1] as List<Course>;
      final all = [...paid, ...free];

      // Fetch progress, enrollment counts, and category names in parallel
      final progMap = <String, StudentProgress?>{};
      final enrolledCountMap = <String, int>{};
      final categoryNameMap = <String, String>{};

      await Future.wait(all.map((c) async {
        try {
          progMap[c.courseId] =
              await _enrollService.getStudentOwnProgress(userId, c.courseId);
        } catch (_) {
          progMap[c.courseId] = null;
        }
      }));

      await Future.wait(all.map((c) async {
        try {
          enrolledCountMap[c.courseId] =
              await _courseService.getEnrollmentCount(c.courseId);
        } catch (_) {
          enrolledCountMap[c.courseId] = 0;
        }
        if (c.categoryId != null && c.categoryId!.isNotEmpty) {
          try {
            categoryNameMap[c.courseId] =
                await _courseService.getCategoryName(c.categoryId!);
          } catch (_) {
            categoryNameMap[c.courseId] = '';
          }
        }
      }));

      if (!mounted) return;
      setState(() {
        _paidCourses = paid;
        _freeCourses = free;
        _progressMap = progMap;
        _enrolledCountMap = enrolledCountMap;
        _categoryNameMap = categoryNameMap;
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    if (_error != null) {
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
              ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_paidCourses.isEmpty && _freeCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined,
                size: 64, color: AppTheme.primaryGold),
            const SizedBox(height: 16),
            const Text(
              'No enrolled courses',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse and enroll in courses to start learning!',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.primaryGold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Paid Courses ───────────────────────────────────────────────
            _buildSection(
              title: 'Paid Courses',
              icon: Icons.attach_money_rounded,
              courses: _paidCourses,
              emptyMessage: 'No paid courses enrolled yet',
            ),
            const SizedBox(height: 28),

            // ── Free Courses ───────────────────────────────────────────────
            _buildSection(
              title: 'Free Courses',
              icon: Icons.card_giftcard_rounded,
              courses: _freeCourses,
              emptyMessage: 'No free courses enrolled yet',
            ),
          ],
        ),
      ),
    );
  }

  // ── Section with header + horizontal scroll row ────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Course> courses,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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

        // Horizontal scroll or empty placeholder
        if (courses.isEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.paleGold),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 28,
                      color: AppTheme.primaryGold.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(emptyMessage,
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              itemCount: courses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => _buildCourseCard(courses[i]),
            ),
          ),
      ],
    );
  }

  // ── Course card — instructor style, no three-dot menu ─────────────────────
  Widget _buildCourseCard(Course course) {
    final progress = _progressMap[course.courseId];
    final percent = progress?.completionPercent ?? 0.0;
    final completed = progress?.completedLessons ?? 0;
    final total = progress?.totalLessons ?? course.lessonCount;
    final enrolledCount = _enrolledCountMap[course.courseId] ?? 0;
    final categoryName = _categoryNameMap[course.courseId] ?? '';

    final thumbUrl =
        course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
            ? ApiClient.formatMediaUrl(course.thumbnailUrl)
            : null;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  StudentCourseDetailScreen(courseId: course.courseId)),
        );
        _loadAll();
      },
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
            // ── Thumbnail ──────────────────────────────────────────
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: thumbUrl != null
                  ? Image.network(
                      thumbUrl,
                      height: 95,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                    )
                  : _thumbPlaceholder(),
            ),

            // ── Card body ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),

                  // Level + price chips
                  Row(
                    children: [
                      if (course.level != null) ...[
                        _chip(
                          course.level!,
                          AppTheme.primaryGold.withValues(alpha: 0.12),
                          AppTheme.primaryGold,
                        ),
                        const SizedBox(width: 4),
                      ],
                      _chip(
                        course.isFree
                            ? 'Free'
                            : '\$${course.price?.toStringAsFixed(0)}',
                        AppTheme.paleGold,
                        AppTheme.darkGold,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Category + instructor
                  Row(
                    children: [
                      if (categoryName.isNotEmpty) ...[
                        const Icon(Icons.category_outlined,
                            size: 11, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            categoryName,
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      if (course.instructor?.username != null) ...[
                        const Icon(Icons.person_outline,
                            size: 11, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            course.instructor!.username!,
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent / 100.0,
                            color: AppTheme.primaryGold,
                            backgroundColor: AppTheme.paleGold,
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Lessons completed + enrolled count
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline,
                          size: 11, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '$completed / $total lessons',
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.textSecondary),
                      ),
                      const Spacer(),
                      const Icon(Icons.people_outline,
                          size: 11, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '$enrolledCount enrolled',
                        style: const TextStyle(
                            fontSize: 9, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      height: 95,
      width: double.infinity,
      color: AppTheme.paleGold,
      child: const Icon(Icons.menu_book_outlined,
          color: AppTheme.primaryGold, size: 32),
    );
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}
