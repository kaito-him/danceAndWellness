import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../models/instructor_profile.dart';
import '../../models/notification_model.dart';
import '../../services/instructor_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/notification_provider.dart';

class InstructorHomeScreen extends StatefulWidget {
  const InstructorHomeScreen({super.key});

  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen>
    with SingleTickerProviderStateMixin {
  final _instructorService = InstructorDashboardService();
  final _notifService = NotificationApiService();

  late TabController _tabController;

  InstructorProfile? _profile;
  List<Course> _publishedCourses = [];
  List<Course> _draftCourses = [];
  Map<String, int> _enrollmentCounts = {};
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
        _instructorService.getProfileByUserId(userId),
        _instructorService.getPublishedCourses(),
        _instructorService.getDraftCourses(),
        _notifService.getNotifications(),
        _notifService.getUnreadCount(),
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

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: const AppNavbar(title: 'Instructor Dashboard'),
      drawer: const AppDrawer(),
      bottomNavigationBar: Container(
        color: AppTheme.primaryGold,
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.pureWhite,
          labelColor: AppTheme.pureWhite,
          unselectedLabelColor: AppTheme.pureWhite.withValues(alpha: 0.6),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.menu_book_outlined), text: 'Courses'),
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
                    _buildOverviewTab(),
                    _buildCoursesTab(),
                    _buildNotificationsTab(),
                  ],
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
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: AppTheme.primaryGold,
            labelColor: AppTheme.primaryGold,
            unselectedLabelColor: AppTheme.textSecondary,
            tabs: [
              Tab(text: 'Published'),
              Tab(text: 'Drafts'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _courseList(_publishedCourses, showEnrollments: true),
                _courseList(_draftCourses, showEnrollments: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseList(List<Course> courses, {required bool showEnrollments}) {
    if (courses.isEmpty) {
      return _emptyState(
        showEnrollments ? 'No published courses' : 'No drafts',
        Icons.menu_book_outlined,
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryGold,
      onRefresh: _loadAll,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _buildCourseCard(courses[i], showEnrollments: showEnrollments),
      ),
    );
  }

  Widget _buildCourseCard(Course course,
      {required bool showEnrollments}) {
    final enrollments = _enrollmentCounts[course.courseId] ?? 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.paleGold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.menu_book_outlined,
                      color: AppTheme.primaryGold, size: 26),
                ),
                const SizedBox(width: 12),
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
                          _chip(course.level ?? 'N/A',
                              AppTheme.primaryGold.withValues(alpha: 0.15),
                              AppTheme.primaryGold),
                          const SizedBox(width: 6),
                          _chip(
                              course.isFree
                                  ? 'Free'
                                  : '\$${course.price?.toStringAsFixed(0)}',
                              AppTheme.paleGold,
                              AppTheme.darkGold),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showEnrollments) ...[
              const SizedBox(height: 10),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.people_outline,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 6),
                  Text('$enrollments student${enrollments == 1 ? '' : 's'} enrolled',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  const Spacer(),
                  const Icon(Icons.video_library_outlined,
                      size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text('${course.lessonCount} lessons',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
