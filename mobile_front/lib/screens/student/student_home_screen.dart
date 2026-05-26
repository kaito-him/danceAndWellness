import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../models/notification_model.dart';
import '../../services/student_service.dart';
import '../../services/notification_service.dart';
import '../../services/course_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/notification_provider.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen>
    with SingleTickerProviderStateMixin {
  final _studentService = StudentService();
  final _notifService = NotificationApiService();
  final _courseService = CourseService();
  final _enrollService = EnrollmentService();

  late TabController _tabController;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _stats;
  List<Course> _courses = [];
  List<Course> _paidCourses = [];
  List<Course> _freeCourses = [];
  List<Map<String, dynamic>> _badges = [];
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  
  // New: Recommended and Most Popular courses
  List<Course> _recommendedCourses = [];
  List<Course> _mostPopularCourses = [];
  Set<String> _enrolledCourseIds = {};

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      // Load core data first
      final coreResults = await Future.wait([
        _studentService.getCurrentUser(),
        _studentService.getStudentStats(userId),
        _studentService.getStudentCourses(userId),
        _studentService.getStudentFreeCourses(userId),
        _studentService.getStudentPaidCourses(userId),
        _studentService.getMyBadgeStatus(),
        _notifService.getNotifications(),
        _notifService.getUnreadCount(),
      ]);

      if (!mounted) return;

      // Update global notification provider
      context.read<NotificationProvider>().fetchUnreadCount();

      final allCourses = coreResults[2] as List<Course>;
      final enrolledIds = allCourses.map((c) => c.courseId).toSet();

      // Load recommended and popular courses separately (non-blocking)
      List<Course> recommended = [];
      List<Course> popular = [];
      
      try {
        recommended = await _studentService.getRecommendations(userId, topN: 10);
      } catch (e) {
        print('Failed to load recommendations: $e');
      }
      
      try {
        popular = await _courseService.getMostPopularCourses(limit: 10);
      } catch (e) {
        print('Failed to load popular courses: $e');
      }

      if (!mounted) return;

      setState(() {
        _userProfile = coreResults[0] as Map<String, dynamic>;
        _stats = coreResults[1] as Map<String, dynamic>;
        _courses = allCourses;
        _freeCourses = coreResults[3] as List<Course>;
        _paidCourses = coreResults[4] as List<Course>;
        _badges = coreResults[5] as List<Map<String, dynamic>>;
        _notifications = coreResults[6] as List<NotificationModel>;
        _unreadCount = coreResults[7] as int;
        _recommendedCourses = recommended;
        _mostPopularCourses = popular;
        _enrolledCourseIds = enrolledIds;
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

  Future<void> _markAllRead() async {
    await _notifService.markAllRead();
    setState(() {
      _unreadCount = 0;
    });
    await _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    final username = _userProfile?['username'] ?? 'Student';

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: const AppNavbar(title: 'Student Dashboard'),
      drawer: const AppDrawer(),
      bottomNavigationBar: Container(
        color: AppTheme.primaryGold,
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.pureWhite,
          labelColor: AppTheme.pureWhite,
          unselectedLabelColor: AppTheme.pureWhite.withValues(alpha: 0.6),
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: 'Home'),
            Tab(icon: Icon(Icons.play_circle_outline), text: 'My Courses'),
            Tab(icon: Icon(Icons.notifications_outlined), text: 'Alerts'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHomeTab(username),
                    _buildCoursesTab(),
                    _buildNotificationsTab(),
                  ],
                ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
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

  // ── Home Tab ───────────────────────────────────────────────────────────────
  Widget _buildHomeTab(String username) {
    return RefreshIndicator(
      color: AppTheme.primaryGold,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting card
            _buildGreetingCard(username),
            const SizedBox(height: 20),

            // Stats row
            _buildStatsRow(),
            const SizedBox(height: 20),

            // Badges section
            if (_badges.isNotEmpty) ...[
              _sectionTitle('My Badges'),
              const SizedBox(height: 12),
              _buildBadgesRow(),
              const SizedBox(height: 20),
            ],

            // Recommended courses section
            if (_recommendedCourses.isNotEmpty) ...[
              _sectionTitle('Recommended for You'),
              const SizedBox(height: 12),
              SizedBox(
                height: 248,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _recommendedCourses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => _buildDiscoveryCourseCard(_recommendedCourses[i]),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Most Popular courses section
            if (_mostPopularCourses.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle('Most Popular'),
                  TextButton(
                    onPressed: () {
                      // Navigate to all courses view
                      _showAllPopularCourses();
                    },
                    child: const Text(
                      'Show All',
                      style: TextStyle(
                        color: AppTheme.primaryGold,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 248,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  itemCount: _mostPopularCourses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => _buildDiscoveryCourseCard(_mostPopularCourses[i]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard(String username) {
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
            radius: 30,
            backgroundColor: AppTheme.pureWhite.withValues(alpha: 0.3),
            child: const Icon(Icons.person, size: 32, color: AppTheme.pureWhite),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: AppTheme.pureWhite.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                Text(
                  username,
                  style: const TextStyle(
                    color: AppTheme.pureWhite,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_courses.length} course${_courses.length == 1 ? '' : 's'} enrolled',
                  style: TextStyle(
                    color: AppTheme.pureWhite.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final enrollments = _stats?['enrollmentsCount'] ?? 0;
    final streak = _stats?['loginStreak'] ?? 0;
    final categories = _stats?['categoriesWatched'] ?? 0;
    final earned = _badges.where((b) => b['earned'] == true).length;

    return Row(
      children: [
        _statCard('Courses', '$enrollments', Icons.play_circle_outline),
        const SizedBox(width: 10),
        _statCard('Streak', '${streak}d', Icons.local_fire_department_outlined),
        const SizedBox(width: 10),
        _statCard('Categories', '$categories', Icons.category_outlined),
        const SizedBox(width: 10),
        _statCard('Badges', '$earned', Icons.military_tech_outlined),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
            Icon(icon, color: AppTheme.primaryGold, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textPrimary)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesRow() {
    final earned = _badges.where((b) => b['earned'] == true).toList();
    if (earned.isEmpty) {
      return const Text('No badges earned yet. Keep learning!',
          style: TextStyle(color: AppTheme.textSecondary));
    }
    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: earned.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final badge = earned[i];
          return Tooltip(
            message: badge['name'] ?? '',
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.paleGold,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGold, width: 2),
              ),
              child: const Icon(Icons.military_tech,
                  color: AppTheme.primaryGold, size: 32),
            ),
          );
        },
      ),
    );
  }

  // ── Courses Tab ────────────────────────────────────────────────────────────
  Widget _buildCoursesTab() {
    if (_paidCourses.isEmpty && _freeCourses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined,
                size: 64, color: AppTheme.primaryGold),
            const SizedBox(height: 16),
            const Text('No courses yet',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text('Enroll in a course to get started',
                style: TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGold,
      onRefresh: _loadAll,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Paid Courses Row ──────────────────────────────────────────
            _buildLibraryCourseSection(
              title: 'Paid Courses',
              icon: Icons.attach_money_rounded,
              courses: _paidCourses,
              emptyMessage: 'No paid courses enrolled yet',
            ),
            const SizedBox(height: 28),

            // ── Free Courses Row ──────────────────────────────────────────
            _buildLibraryCourseSection(
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

  Widget _buildLibraryCourseSection({
    required String title,
    required IconData icon,
    required List<Course> courses,
    required String emptyMessage,
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
                  Text(
                    emptyMessage,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
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
              itemBuilder: (_, i) => _buildLibraryCourseCard(courses[i]),
            ),
          ),
      ],
    );
  }

  Widget _buildLibraryCourseCard(Course course) {
    final thumbUrl = course.thumbnailUrl != null &&
            course.thumbnailUrl!.isNotEmpty
        ? ApiClient.formatMediaUrl(course.thumbnailUrl)
        : null;

    return GestureDetector(
      onTap: () {
        // Navigate to course detail / lesson player
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
            // Thumbnail — no three-dot menu
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: thumbUrl != null
                  ? Image.network(
                      thumbUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _libraryThumbnailPlaceholder(),
                    )
                  : _libraryThumbnailPlaceholder(),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                        if (course.level != null)
                          _chip(
                            course.level!,
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${course.lessonCount} lesson${course.lessonCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                        if (course.instructor?.username != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.person_outline,
                              size: 13, color: AppTheme.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              course.instructor!.username!,
                              style: const TextStyle(
                                  fontSize: 11, color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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

  Widget _libraryThumbnailPlaceholder() {
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
                  onPressed: _markAllRead,
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
                        _buildNotificationTile(_notifications[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
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
      title: Text(
        n.message,
        style: TextStyle(
          fontSize: 13,
          color: AppTheme.textPrimary,
          fontWeight: n.read ? FontWeight.normal : FontWeight.w600,
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: n.createdAt != null
          ? Text(
              _formatDate(n.createdAt!),
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            )
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
        return Icons.school_outlined;
      case 'PURCHASE_SUCCESS':
        return Icons.check_circle_outline;
      case 'FEATURED':
        return Icons.star_outline;
      case 'NEW_INSTRUCTOR_APPLICATION':
        return Icons.person_add_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimary,
      ),
    );
  }

  // ── Home tab: "Continue Learning" card (simple list style) ────────────────
  Widget _buildCourseCard(Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.paleGold,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_outline,
                  color: AppTheme.primaryGold, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.video_library_outlined,
                          size: 13, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${course.lessonCount} lessons',
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textSecondary)),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: course.isFree
                              ? AppTheme.paleGold
                              : AppTheme.primaryGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.isFree
                              ? 'Free'
                              : '\$${course.price?.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: course.isFree
                                ? AppTheme.darkGold
                                : AppTheme.primaryGold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.primaryGold),
          ],
        ),
      ),
    );
  }

  // ── Shared chip widget (matches instructor card style) ────────────────────
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
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  // ── Discovery course card (for recommended & popular) ──────────────────────
  Widget _buildDiscoveryCourseCard(Course course) {
    final isEnrolled = _enrolledCourseIds.contains(course.courseId);
    final thumbUrl = course.thumbnailUrl != null &&
            course.thumbnailUrl!.isNotEmpty
        ? ApiClient.formatMediaUrl(course.thumbnailUrl)
        : null;

    return GestureDetector(
      onTap: () {
        // Navigate to course detail
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
            // Thumbnail with check icon if enrolled
            Stack(
              children: [
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
                if (isEnrolled)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: AppTheme.pureWhite,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),

            // Card body
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
                  const SizedBox(height: 6),

                  // Lessons + instructor
                  Row(
                    children: [
                      const Icon(Icons.play_circle_outline,
                          size: 11, color: AppTheme.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        '${course.lessonCount} lesson${course.lessonCount == 1 ? '' : 's'}',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textSecondary),
                      ),
                      if (course.instructor?.username != null) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.person_outline,
                            size: 11, color: AppTheme.textSecondary),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            course.instructor!.username!,
                            style: const TextStyle(
                                fontSize: 10, color: AppTheme.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  void _showAllPopularCourses() {
    // Navigate to a full screen showing all popular courses
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Most Popular Courses'),
        content: const Text('Full course list view coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
