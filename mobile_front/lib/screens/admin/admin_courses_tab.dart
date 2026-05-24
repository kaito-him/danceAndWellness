import 'package:flutter/material.dart';
import 'admin_course_detail_screen.dart';
import '../../models/course.dart';
import '../../services/api_client.dart';
import '../../services/course_service.dart';
import '../../utils/app_theme.dart';

class AdminCoursesTab extends StatefulWidget {
  final AdminCourseSection? initialSection;
  const AdminCoursesTab({super.key, this.initialSection});

  @override
  State<AdminCoursesTab> createState() => _AdminCoursesTabState();
}

enum AdminCourseSection { published, archived }

class _AdminCoursesTabState extends State<AdminCoursesTab> {
  final _courseService = CourseService();

  late AdminCourseSection _activeSection;
  List<Course> _courses = [];
  bool _loading = true;

  // Cache: courseId → {enrollmentCount, categoryName}
  final Map<String, int> _enrollmentCache = {};
  final Map<String, String> _categoryCache = {};

  @override
  void initState() {
    super.initState();
    _activeSection = widget.initialSection ?? AdminCourseSection.published;
    _fetchData();
  }

  @override
  void didUpdateWidget(AdminCoursesTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialSection != null && widget.initialSection != _activeSection) {
      setState(() {
        _activeSection = widget.initialSection!;
      });
      _fetchData();
    }
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final courses = _activeSection == AdminCourseSection.published
          ? await _courseService.getPublishedCourses()
          : await _courseService.getAdminArchivedCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _loading = false;
        });
        _loadExtras(courses);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Failed to load courses: ${e.toString()}', isError: true);
      }
    }
  }

  Future<void> _loadExtras(List<Course> courses) async {
    for (final course in courses) {
      if (!_enrollmentCache.containsKey(course.courseId)) {
        final count = await _courseService.getEnrollmentCount(course.courseId);
        if (mounted) setState(() => _enrollmentCache[course.courseId] = count);
      }
      if (course.categoryId != null &&
          !_categoryCache.containsKey(course.categoryId)) {
        final name = await _courseService.getCategoryName(course.categoryId!);
        if (mounted) setState(() => _categoryCache[course.categoryId!] = name);
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

  Future<void> _initiateArchive(Course course) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive Course'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Archive "${course.title}"?'),
            const SizedBox(height: 6),
            const Text(
              'It will be removed from the public catalog.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            const Text('Reason *',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Explain to the instructor why...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                _showToast('Please provide a reason.', isError: true);
                return;
              }
              Navigator.pop(ctx, true);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _courseService.archiveCourse(
            course.courseId, reasonController.text.trim());
        _showToast('Course archived successfully.');
        _fetchData();
      } catch (e) {
        _showToast('Failed to archive course.', isError: true);
      }
    }
  }

  Future<void> _initiateUnarchive(Course course) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unarchive Course'),
        content: Text('Restore "${course.title}" to the published catalog? The instructor will be notified.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _courseService.unarchiveCourse(course.courseId);
        _showToast('Course restored successfully.');
        _fetchData();
      } catch (e) {
        _showToast('Failed to unarchive course.', isError: true);
      }
    }
  }

  String _formatArchivedDate(dynamic raw) {
    if (raw == null) return 'Unknown date';
    if (raw is List) {
      if (raw.length >= 3) {
        return '${raw[2]}/${raw[1]}/${raw[0]}';
      }
    }
    try {
      final date = DateTime.parse(raw.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(
                _activeSection == AdminCourseSection.published 
                  ? Icons.menu_book_rounded 
                  : Icons.archive_rounded,
                color: AppTheme.primaryGold, 
                size: 26
              ),
              const SizedBox(width: 10),
              Text(
                _activeSection == AdminCourseSection.published 
                  ? 'Published Courses' 
                  : 'Archived Courses',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.paleGold,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_courses.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.initialSection == null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton('Published', AdminCourseSection.published),
                const SizedBox(width: 16),
                _buildTabButton('Archived', AdminCourseSection.archived),
              ],
            ),
          ),
        Expanded(
          child: _loading
              ? _buildSkeletons()
              : _courses.isEmpty
                  ? _buildEmptyState()
                  : _buildCourseList(),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, AdminCourseSection section) {
    final isActive = _activeSection == section;
    return GestureDetector(
      onTap: () {
        if (isActive) return;
        setState(() => _activeSection = section);
        _fetchData();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.primaryGold : AppTheme.mediumGray),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseList() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primaryGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _courses.length,
        itemBuilder: (context, index) => _buildCourseCard(_courses[index]),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final enrollments = _enrollmentCache[course.courseId];
    final categoryName = course.categoryId != null
        ? _categoryCache[course.categoryId]
        : null;
    final isArchived = _activeSection == AdminCourseSection.archived;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminCourseDetailScreen(courseId: course.courseId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.paleGold.withOpacity(0.6)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: course.thumbnailUrl != null
                      ? Image.network(
                          ApiClient.formatMediaUrl(course.thumbnailUrl),
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _pulseSkeleton(),
                          errorBuilder: (_, __, ___) => _thumbnailPlaceholder(),
                        )
                      : _thumbnailPlaceholder(),
                ),
                Positioned(top: 10, left: 10, child: _levelBadge(course.level)),
                Positioned(
                  top: 10,
                  right: 44,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      course.isFree ? 'FREE' : '\$${course.price?.toStringAsFixed(0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(top: 4, right: 4, child: _buildThreeDots(course)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: AppTheme.paleGold,
                        backgroundImage: course.instructor?.photo != null
                            ? NetworkImage(ApiClient.formatMediaUrl('/api/files/${course.instructor!.photo}'))
                            : null,
                        child: course.instructor?.photo == null ? const Icon(Icons.person, size: 13, color: AppTheme.darkGold) : null,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          course.instructor?.username ?? 'Unknown',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (categoryName != null && categoryName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Text('·', style: TextStyle(color: AppTheme.mediumGray)),
                        const SizedBox(width: 8),
                        const Icon(Icons.category_outlined, size: 12, color: AppTheme.primaryGold),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            categoryName,
                            style: const TextStyle(fontSize: 12, color: AppTheme.primaryGold, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            if (isArchived) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 14, color: Colors.red),
                          const SizedBox(width: 6),
                          Text(
                            'Archived on ${_formatArchivedDate(course.archivedAt)}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        course.archiveReason ?? 'No reason provided.',
                        style: TextStyle(fontSize: 12, color: Colors.red.shade800, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    _statCell(icon: Icons.play_lesson_outlined, value: '${course.lessonCount}', label: 'Lessons'),
                    _verticalDivider(),
                    _statCell(icon: Icons.quiz_outlined, value: '${course.quizCount}', label: 'Quizzes'),
                    _verticalDivider(),
                    _statCell(
                      icon: Icons.people_outline_rounded,
                      value: enrollments != null ? '$enrollments' : '—',
                      label: 'Students',
                      loading: enrollments == null,
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

  Widget _buildThreeDots(Course course) {
    final isArchived = _activeSection == AdminCourseSection.archived;
    return Material(
      color: Colors.black38,
      borderRadius: BorderRadius.circular(20),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onSelected: (val) {
          if (val == 'preview') {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdminCourseDetailScreen(courseId: course.courseId)));
          } else if (val == 'archive') {
            _initiateArchive(course);
          } else if (val == 'unarchive') {
            _initiateUnarchive(course);
          }
        },
        itemBuilder: (_) => [
          const PopupMenuItem(
            value: 'preview',
            child: Row(
              children: [
                Icon(Icons.visibility_outlined, size: 18, color: AppTheme.primaryGold),
                SizedBox(width: 10),
                Text('Preview'),
              ],
            ),
          ),
          if (!isArchived)
            const PopupMenuItem(
              value: 'archive',
              child: Row(
                children: [
                  Icon(Icons.archive_outlined, size: 18, color: AppTheme.errorGold),
                  SizedBox(width: 10),
                  Text('Archive', style: TextStyle(color: AppTheme.errorGold)),
                ],
              ),
            ),
          if (isArchived)
            const PopupMenuItem(
              value: 'unarchive',
              child: Row(
                children: [
                  Icon(Icons.unarchive_outlined, size: 18, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Unarchive', style: TextStyle(color: Colors.green)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCell({required IconData icon, required String value, required String label, bool loading = false}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGold),
          const SizedBox(height: 4),
          loading
              ? const SizedBox(width: 24, height: 12, child: _InlineSkeleton())
              : Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _verticalDivider() => Container(width: 1, height: 36, color: AppTheme.mediumGray);

  Widget _levelBadge(String? level) {
    Color color;
    switch (level) {
      case 'BEGINNER': color = Colors.green; break;
      case 'INTERMEDIATE': color = Colors.orange; break;
      case 'ADVANCED': color = Colors.red; break;
      default: color = AppTheme.primaryGold;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.85), borderRadius: BorderRadius.circular(8)),
      child: Text(level ?? 'UNKNOWN', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _thumbnailPlaceholder() => Container(color: AppTheme.lightGray, child: const Center(child: Icon(Icons.movie_filter_rounded, size: 48, color: AppTheme.mediumGray)));

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.paleGold.withOpacity(0.5))),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: _pulseSkeleton()),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _pulseSkeleton(height: 16, width: double.infinity),
                  const SizedBox(height: 8),
                  _pulseSkeleton(height: 12, width: 160),
                  const SizedBox(height: 12),
                  _pulseSkeleton(height: 52, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pulseSkeleton({double? height, double? width}) {
    return StatefulBuilder(builder: (context, ss) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.3, end: 0.6),
        duration: const Duration(milliseconds: 900),
        builder: (_, v, __) => Container(
          height: height,
          width: width,
          decoration: BoxDecoration(color: AppTheme.mediumGray.withOpacity(v), borderRadius: BorderRadius.circular(height != null ? 6 : 0)),
        ),
        onEnd: () => ss(() {}),
      );
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppTheme.mediumGray),
          const SizedBox(height: 16),
          Text(
            _activeSection == AdminCourseSection.published ? 'No published courses found' : 'No archived courses found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)
          ),
          const SizedBox(height: 8),
          Text(
            _activeSection == AdminCourseSection.published ? 'Courses will appear here once published.' : 'Archived courses will appear here.',
            style: const TextStyle(color: AppTheme.textSecondary)
          ),
        ],
      ),
    );
  }
}

// Small inline skeleton widget (const-compatible)
class _InlineSkeleton extends StatefulWidget {
  const _InlineSkeleton();

  @override
  State<_InlineSkeleton> createState() => _InlineSkeletonState();
}

class _InlineSkeletonState extends State<_InlineSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.6).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: AppTheme.mediumGray.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
