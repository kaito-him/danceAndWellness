import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../models/category.dart';
import '../../services/student_service.dart';
import '../../services/course_service.dart';
import '../../services/category_service.dart';
import '../../utils/app_theme.dart';
import 'student_course_detail_screen.dart';

class StudentHomeTab extends StatefulWidget {
  const StudentHomeTab({super.key});

  @override
  State<StudentHomeTab> createState() => _StudentHomeTabState();
}

class _StudentHomeTabState extends State<StudentHomeTab> {
  final _studentService = StudentService();
  final _courseService = CourseService();
  final _categoryService = CategoryService();

  List<Course> _recommendedCourses = [];
  List<Course> _publishedCourses = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;

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
      final results = await Future.wait([
        _studentService.getRecommendations(userId),
        _courseService.getPublishedCourses(),
        _categoryService.getCategories(),
      ]);

      setState(() {
        _recommendedCourses = results[0] as List<Course>;
        _publishedCourses = results[1] as List<Course>;
        _categories = results[2] as List<Category>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Course> get _filteredPublishedCourses {
    if (_selectedCategoryId == null) return _publishedCourses;
    return _publishedCourses.where((c) => c.categoryId == _selectedCategoryId).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppTheme.errorGold),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
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

    final username = context.watch<AuthProvider>().username ?? 'Student';

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.primaryGold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(username),
            const SizedBox(height: 24),

            // Categories horizontal list
            if (_categories.isNotEmpty) ...[
              const Text('Browse Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 10),
              _buildCategoryChips(),
              const SizedBox(height: 24),
            ],

            // Recommended Courses Section
            if (_recommendedCourses.isNotEmpty) ...[
              const Text('Recommended For You', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 12),
              _buildHorizontalCoursesList(_recommendedCourses),
              const SizedBox(height: 28),
            ],

            // All Published Courses Section
            const Text('Explore Courses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 12),
            _filteredPublishedCourses.isEmpty
                ? _buildEmptyPublishedCourses()
                : _buildVerticalCoursesList(_filteredPublishedCourses),
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
            color: AppTheme.primaryGold.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: const Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Welcome Back,',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  username,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Start learning your favorite courses today!',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final cat = isAll ? null : _categories[index - 1];
          final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == cat!.id;

          return ChoiceChip(
            label: Text(isAll ? 'All' : cat!.name),
            selected: isSelected,
            selectedColor: AppTheme.primaryGold,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? Colors.transparent : AppTheme.paleGold),
            ),
            onSelected: (selected) {
              setState(() {
                _selectedCategoryId = isAll ? null : cat!.id;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildHorizontalCoursesList(List<Course> courses) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) {
          final c = courses[i];
          return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCourseDetailScreen(courseId: c.courseId))),
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.paleGold),
                boxShadow: [
                  BoxShadow(color: AppTheme.primaryGold.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppTheme.paleGold,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(child: Icon(Icons.school_outlined, color: AppTheme.primaryGold, size: 36)),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const Spacer(),
                          Row(
                            children: [
                              Text(
                                c.isFree ? 'Free' : '\$${c.price?.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                              ),
                              const Spacer(),
                              const Icon(Icons.play_circle_outline, size: 12, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text('${c.lessonCount} lessons', style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
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
        },
      ),
    );
  }

  Widget _buildVerticalCoursesList(List<Course> courses) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final c = courses[i];
        return Card(
          margin: EdgeInsets.zero,
          child: InkWell(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCourseDetailScreen(courseId: c.courseId))),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.paleGold,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_circle_outline, color: AppTheme.primaryGold, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              c.isFree ? 'Free' : '\$${c.price?.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: c.isFree ? Colors.green : AppTheme.primaryGold, fontSize: 12),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.video_library_outlined, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('${c.lessonCount} lessons', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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
      },
    );
  }

  Widget _buildEmptyPublishedCourses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.paleGold)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppTheme.primaryGold.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text('No courses found in this category.', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
