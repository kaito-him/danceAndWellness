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

  List<Course> _courses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final courses = await _courseService.getPublishedCourses();
      if (mounted) {
        setState(() {
          _courses = courses;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Failed to load courses: ${e.toString()}', isError: true);
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Simple title header
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.white,
          child: const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AppTheme.primaryGold, size: 28),
              SizedBox(width: 12),
              Text(
                'Published Courses',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.paleGold.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Thumbnail
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: course.thumbnailUrl != null
                    ? Image.network(
                        ApiClient.formatMediaUrl(course.thumbnailUrl),
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return _buildPulseSkeleton();
                        },
                      )
                    : Container(
                        color: AppTheme.lightGray,
                        child: const Icon(Icons.movie_filter_rounded, size: 48, color: AppTheme.mediumGray),
                      ),
              ),
              // Level Badge
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getLevelColor(course.level).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(course.level ?? 'UNKNOWN', style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold
                  )),
                ),
              ),
              // Price Badge
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(course.isFree ? 'FREE' : '\$${course.price}', style: const TextStyle(
                    color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold
                  )),
                ),
              ),
            ],
          ),
          
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course.title, style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary
                ), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppTheme.paleGold,
                      backgroundImage: (course.instructor?.photo != null)
                        ? NetworkImage(ApiClient.formatMediaUrl('/api/files/${course.instructor!.photo}'))
                        : null,
                      child: (course.instructor?.photo == null)
                        ? const Icon(Icons.person, size: 12, color: AppTheme.darkGold)
                        : null,
                    ),
                    const SizedBox(width: 8),
                    Text(course.instructor?.username ?? 'Unknown', style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminCourseDetailScreen(courseId: course.courseId),
                        ),
                      );
                    },
                    child: const Text('Preview'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String? level) {
    switch (level) {
      case 'BEGINNER': return Colors.green;
      case 'INTERMEDIATE': return Colors.orange;
      case 'ADVANCED': return Colors.red;
      default: return AppTheme.primaryGold;
    }
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (ctx, i) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.paleGold.withValues(alpha: 0.5)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPulseSkeleton(),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPulseSkeleton(height: 20, width: double.infinity),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPulseSkeleton(height: 20, width: 20, isCircle: true),
                      const SizedBox(width: 8),
                      _buildPulseSkeleton(height: 12, width: 80),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPulseSkeleton(height: 40, width: double.infinity),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPulseSkeleton({double? height, double? width, bool isCircle = false}) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.3, end: 0.6),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, _) {
            return Container(
              height: height,
              width: width,
              decoration: BoxDecoration(
                color: AppTheme.mediumGray.withValues(alpha: value),
                shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: isCircle ? null : BorderRadius.circular(height != null ? 8 : 0),
              ),
            );
          },
          onEnd: () => setState(() {}),
        );
      }
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: AppTheme.mediumGray),
          SizedBox(height: 16),
          Text('No published courses found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          SizedBox(height: 8),
          Text('Courses will appear here once published.', 
            style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
