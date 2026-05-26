import 'package:flutter/material.dart';

import '../../models/course.dart';
import '../../models/category.dart';
import '../../models/app_user.dart';
import '../../services/api_client.dart';
import '../../services/category_service.dart';
import '../../services/course_service.dart';
import '../../utils/app_theme.dart';
import 'student_course_detail_screen.dart';

class StudentSearchTab extends StatefulWidget {
  const StudentSearchTab({super.key});

  @override
  State<StudentSearchTab> createState() => _StudentSearchTabState();
}

class _StudentSearchTabState extends State<StudentSearchTab> {
  final _courseService = CourseService();
  final _categoryService = CategoryService();
  final _apiClient = ApiClient();
  final _searchController = TextEditingController();

  List<Course> _courses = [];
  List<Category> _categories = [];
  List<AppUser> _instructors = [];

  bool _loading = true;
  String _searchQuery = '';
  String? _selectedLevel;
  String? _selectedCategoryId;

  // Toggle: true = Courses, false = Instructors
  bool _searchCoursesMode = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _courseService.getPublishedCourses(),
        _categoryService.getCategories(),
        _apiClient.dio.get('/instructors'),
      ]);

      final instructorList = (results[2] as dynamic).data as List<dynamic>;

      if (mounted) {
        setState(() {
          _courses = results[0] as List<Course>;
          _categories = results[1] as List<Category>;
          _instructors = instructorList.map((e) => AppUser.fromJson(e, 'INSTRUCTOR')).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Course> get _filteredCourses {
    final q = _searchQuery.toLowerCase();
    return _courses.where((c) {
      final matchesSearch = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          (c.instructor?.username?.toLowerCase().contains(q) ?? false);
      final matchesLevel = _selectedLevel == null || c.level == _selectedLevel;
      final matchesCat = _selectedCategoryId == null || c.categoryId == _selectedCategoryId;
      return matchesSearch && matchesLevel && matchesCat;
    }).toList();
  }

  List<AppUser> get _filteredInstructors {
    final q = _searchQuery.toLowerCase();
    return _instructors.where((inst) {
      final matchesSearch = q.isEmpty ||
          inst.username.toLowerCase().contains(q) ||
          (inst.specialization?.toLowerCase().contains(q) ?? false) ||
          (inst.studioName?.toLowerCase().contains(q) ?? false);
      return matchesSearch;
    }).toList();
  }

  bool get _hasActiveSearch =>
      _searchQuery.isNotEmpty ||
      _selectedLevel != null ||
      _selectedCategoryId != null;

  void _onCategoryTap(Category cat) {
    setState(() {
      if (_selectedCategoryId == cat.id) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = cat.id;
      }
    });
  }

  void _clearAll() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _selectedLevel = null;
      _selectedCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildModeToggle(),
        _buildSearchHeader(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
              : _searchCoursesMode
                  ? (_hasActiveSearch ? _buildCourseResults() : _buildCategoriesGrid())
                  : _buildInstructorResults(),
        ),
      ],
    );
  }

  // ── Mode Toggle ─────────────────────────────────────────────────────────────
  Widget _buildModeToggle() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _toggleButton('Courses', _searchCoursesMode, () => setState(() => _searchCoursesMode = true)),
          const SizedBox(width: 16),
          _toggleButton('Instructors', !_searchCoursesMode, () => setState(() => _searchCoursesMode = false)),
        ],
      ),
    );
  }

  Widget _toggleButton(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryGold : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryGold, width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : AppTheme.primaryGold,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ── Search Header ─────────────────────────────────────────────────────────
  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: _searchCoursesMode ? 'Search courses by title or instructor...' : 'Search instructors...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.lightGray,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          if (_searchCoursesMode) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown<String?>(
                    value: _selectedLevel,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Levels')),
                      DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                      DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                      DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                    ],
                    onChanged: (v) => setState(() => _selectedLevel = v),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildDropdown<String?>(
                    value: _selectedCategoryId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Categories')),
                      ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedCategoryId = v),
                  ),
                ),
              ],
            ),
          ],
          if (_hasActiveSearch) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _clearAll,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.errorGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.errorGold.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.filter_alt_off_rounded, size: 14, color: AppTheme.errorGold),
                    SizedBox(width: 6),
                    Text('Clear filters', style: TextStyle(fontSize: 12, color: AppTheme.errorGold, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary, size: 20),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          underline: const SizedBox.shrink(),
        ),
      ),
    );
  }

  // ── Categories Grid ────────────────────────────────────────────────────────
  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text(
          'No categories available',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primaryGold,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Browse by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Tap a category to see its courses',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _buildCategoryCard(cat);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category cat) {
    final isSelected = _selectedCategoryId == cat.id;
    return GestureDetector(
      onTap: () => _onCategoryTap(cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGold : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? AppTheme.primaryGold.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: cat.icon != null
                  ? Image.network(
                      ApiClient.formatMediaUrl(
                        cat.icon!.startsWith('/api/files/')
                            ? cat.icon!
                            : '/api/files/${cat.icon}',
                      ),
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return _buildSkeleton();
                      },
                      errorBuilder: (ctx, _, __) => Container(
                        color: AppTheme.paleGold.withValues(alpha: 0.3),
                        child: const Icon(Icons.category_rounded,
                            color: AppTheme.primaryGold, size: 32),
                      ),
                    )
                  : _buildSkeleton(
                      child: const Icon(Icons.category_rounded,
                          color: AppTheme.primaryGold, size: 32)),
            ),
            Container(
              padding: const EdgeInsets.all(10),
              color: isSelected ? AppTheme.primaryGold.withValues(alpha: 0.08) : null,
              child: Text(
                cat.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? AppTheme.darkGold : AppTheme.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton({Widget? child}) {
    return StatefulBuilder(builder: (context, setState) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.3, end: 0.7),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, _) {
          return Container(
            color: AppTheme.mediumGray.withValues(alpha: value),
            child: child,
          );
        },
        onEnd: () => setState(() {}),
      );
    });
  }

  // ── Course Results ───────────────────────────────────────────────────────
  Widget _buildCourseResults() {
    final results = _filteredCourses;

    return Column(
      children: [
        // Results count + active category chip
        if (_selectedCategoryId != null) ...[
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.category_rounded, size: 14, color: AppTheme.primaryGold),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _categories.firstWhere((c) => c.id == _selectedCategoryId,
                        orElse: () => Category(id: '', name: 'Unknown')).name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGold),
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _selectedCategoryId = null),
                  child: const Icon(Icons.close_rounded, size: 16, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${results.length} result${results.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? _buildEmptyResults()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppTheme.primaryGold,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: results.length,
                    itemBuilder: (context, index) =>
                        _buildCourseCard(results[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildCourseCard(Course course) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => StudentCourseDetailScreen(courseId: course.courseId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (course.thumbnailUrl != null)
              Image.network(
                ApiClient.formatMediaUrl(course.thumbnailUrl!),
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (ctx, _, __) => Container(
                  height: 140,
                  color: AppTheme.paleGold.withValues(alpha: 0.3),
                  child: const Icon(Icons.play_circle_rounded,
                      color: AppTheme.primaryGold, size: 48),
                ),
              )
            else
              Container(
                height: 140,
                color: AppTheme.paleGold.withValues(alpha: 0.3),
                child: const Icon(Icons.play_circle_rounded,
                    color: AppTheme.primaryGold, size: 48),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (course.instructor?.username != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.person_rounded,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            course.instructor!.username!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          course.level ?? "All Levels",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (course.price != null) ...[
                        Text(
                          '\$${course.price}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGold,
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

  // ── Instructor Results ────────────────────────────────────────────────────
  Widget _buildInstructorResults() {
    final results = _filteredInstructors;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${results.length} result${results.length == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? _buildEmptyResults()
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  color: AppTheme.primaryGold,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: results.length,
                    itemBuilder: (context, index) =>
                        _buildInstructorCard(results[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildInstructorCard(AppUser instructor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.paleGold.withValues(alpha: 0.3),
            child: instructor.photo != null
                ? ClipOval(
                    child: Image.network(
                      ApiClient.formatMediaUrl(instructor.photo!),
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, _, __) => const Icon(Icons.person_rounded,
                          color: AppTheme.primaryGold, size: 28),
                    ),
                  )
                : const Icon(Icons.person_rounded,
                    color: AppTheme.primaryGold, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  instructor.username,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (instructor.specialization != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    instructor.specialization!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                if (instructor.studioName != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    instructor.studioName!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your filters or search query',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
