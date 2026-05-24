import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../models/notification_model.dart';
import '../../services/student_service.dart';
import '../../services/notification_service.dart';
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

  late TabController _tabController;

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _stats;
  List<Course> _courses = [];
  List<Map<String, dynamic>> _badges = [];
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

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
      final results = await Future.wait([
        _studentService.getCurrentUser(),
        _studentService.getStudentStats(userId),
        _studentService.getStudentCourses(userId),
        _studentService.getMyBadgeStatus(),
        _notifService.getNotifications(),
        _notifService.getUnreadCount(),
      ]);

      if (!mounted) return;

      // Update global notification provider
      context.read<NotificationProvider>().fetchUnreadCount();

      setState(() {
        _userProfile = results[0] as Map<String, dynamic>;
        _stats = results[1] as Map<String, dynamic>;
        _courses = results[2] as List<Course>;
        _badges = results[3] as List<Map<String, dynamic>>;
        _notifications = results[4] as List<NotificationModel>;
        _unreadCount = results[5] as int;
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

            // Recent courses
            if (_courses.isNotEmpty) ...[
              _sectionTitle('Continue Learning'),
              const SizedBox(height: 12),
              ..._courses
                  .take(3)
                  .map((c) => _buildCourseCard(c))
                  .toList(),
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
    if (_courses.isEmpty) {
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
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _buildCourseCard(_courses[i]),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/student/course/${course.courseId}'),
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
                          course.isFree ? 'Free' : '\$${course.price?.toStringAsFixed(0)}',
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
}
