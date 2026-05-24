import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/instructor_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/course_details_bottom_sheet.dart';

class InstructorArchivedScreen extends StatefulWidget {
  const InstructorArchivedScreen({super.key});

  @override
  State<InstructorArchivedScreen> createState() => _InstructorArchivedScreenState();
}

class _InstructorArchivedScreenState extends State<InstructorArchivedScreen> {
  final _instructorService = InstructorDashboardService();
  
  List<Course> _archivedCourses = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _instructorService.getArchivedCourses(),
        _instructorService.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _archivedCourses = results[0] as List<Course>;
          _categories = results[1] as List<Map<String, dynamic>>;
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

  Future<void> _unarchiveCourse(String courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.unarchive_outlined, color: AppTheme.primaryGold, size: 24),
            SizedBox(width: 8),
            Text('Unarchive Course'),
          ],
        ),
        content: const Text('Do you want to restore this course to published status? It will be visible to students again.'),
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
            child: const Text('Unarchive'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _instructorService.unarchiveCourseByInstructor(courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course restored successfully!'), backgroundColor: Colors.green),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unarchive course: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCoursePermanently(String courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_outlined, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Permanently'),
          ],
        ),
        content: const Text('Are you sure you want to permanently delete this archived course? This action cannot be undone and all data will be lost.'),
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
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _instructorService.deleteCourse(courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Course deleted permanently!'), backgroundColor: Colors.green),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete course: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openEditCourseDialog(Course course) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CourseDetailsBottomSheet(
        editCourse: course,
        categories: _categories,
        onSaved: _loadData,
      ),
    );
  }

  String _formatArchivedDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at $hour:$minute $period';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _chip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selfArchived = _archivedCourses.where((c) => !c.archivedByAdmin).toList();
    final adminArchived = _archivedCourses.where((c) => c.archivedByAdmin).toList();

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: const AppNavbar(
        title: 'Archived Courses',
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGold,
              ),
            )
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.primaryGold,
                  onRefresh: _loadData,
                  child: _archivedCourses.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.archive_outlined,
                                    size: 72,
                                    color: AppTheme.primaryGold,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No archived courses',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Courses you archive will appear here.',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            // ── Self Archived Section ──
                            if (selfArchived.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Archived by you',
                                count: selfArchived.length,
                                icon: Icons.archive_outlined,
                                iconColor: AppTheme.primaryGold,
                              ),
                              const SizedBox(height: 12),
                              ...selfArchived.map((course) => _buildArchivedCourseCard(course, isAdminArchived: false)),
                              const SizedBox(height: 24),
                            ],

                            // ── Admin Archived Section ──
                            if (adminArchived.isNotEmpty) ...[
                              _buildSectionHeader(
                                title: 'Archived by admin',
                                count: adminArchived.length,
                                icon: Icons.lock_outline_rounded,
                                iconColor: Colors.redAccent,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  border: Border.all(color: Colors.red[200]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline_rounded, color: Colors.red[800], size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'These courses were removed from the catalog by an administrator. Contact support if you believe this was a mistake.',
                                        style: TextStyle(color: Colors.red[800], fontSize: 12, height: 1.4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...adminArchived.map((course) => _buildArchivedCourseCard(course, isAdminArchived: true)),
                            ],
                          ],
                        ),
                ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required int count,
    required IconData icon,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArchivedCourseCard(Course course, {required bool isAdminArchived}) {
    final thumbUrl = course.thumbnailUrl != null && course.thumbnailUrl!.isNotEmpty
        ? ApiClient.formatMediaUrl(course.thumbnailUrl)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAdminArchived 
              ? Colors.red[100]! 
              : AppTheme.paleGold.withOpacity(0.8), 
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAdminArchived ? Colors.redAccent : AppTheme.primaryGold).withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Preview
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  color: (isAdminArchived ? Colors.red[50]! : AppTheme.paleGold).withOpacity(0.4),
                  child: thumbUrl != null
                      ? Image.network(
                          thumbUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported_outlined, color: AppTheme.primaryGold),
                          ),
                        )
                      : const Center(
                          child: Icon(Icons.menu_book_outlined, color: AppTheme.primaryGold, size: 28),
                        ),
                ),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course.description ?? 'No description provided.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _chip(
                            course.level ?? 'BEGINNER',
                            isAdminArchived 
                                ? Colors.red[50]! 
                                : AppTheme.primaryGold.withOpacity(0.12),
                            isAdminArchived ? Colors.red[800]! : AppTheme.darkGold,
                          ),
                          const SizedBox(width: 6),
                          _chip(
                            course.isFree ? 'Free' : '\$${course.price?.toStringAsFixed(0) ?? "0"}',
                            AppTheme.paleGold.withOpacity(0.5),
                            AppTheme.darkGold,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Show reason and date for admin archived
          if (isAdminArchived) ...[
            const Divider(height: 1),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.red[50]!.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(
                        'Reason: ${course.archiveReason ?? "No reason specified"}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Archived on: ${_formatArchivedDate(course.archivedAt)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 1),

          // Action Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!isAdminArchived) ...[
                  TextButton.icon(
                    onPressed: () => _deleteCoursePermanently(course.courseId),
                    icon: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 16),
                    label: const Text(
                      'Delete Permanently',
                      style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _unarchiveCourse(course.courseId),
                    icon: const Icon(Icons.unarchive_outlined, size: 16),
                    label: const Text('Unarchive'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.lock_clock_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Locked by administrator',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openEditCourseDialog(course),
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                    label: const Text('View details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: AppTheme.textPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
