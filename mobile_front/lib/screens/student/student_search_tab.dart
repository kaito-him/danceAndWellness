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
                  ? _buildCourseResults()
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
                  color: AppTheme.errorGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.errorGold.withOpacity(0.3)),
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
    required T value,
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
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGold, size: 18),
        ),
      ),
    );
  }

  // ── Course Results ──────────────────────────────────────────────────────────
  Widget _buildCourseResults() {
    final results = _filteredCourses;
    if (results.isEmpty) return _buildEmptyState('No courses found.');

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primaryGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, idx) {
          final c = results[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentCourseDetailScreen(courseId: c.courseId))),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(color: AppTheme.paleGold, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.play_circle_outline, color: AppTheme.primaryGold, size: 36),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(c.isFree ? 'Free' : '\$${c.price?.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: c.isFree ? Colors.green : AppTheme.primaryGold)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.paleGold, borderRadius: BorderRadius.circular(4)),
                                child: Text(c.level ?? 'ALL', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.darkGold)),
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
        },
      ),
    );
  }

  // ── Instructor Results ──────────────────────────────────────────────────────
  Widget _buildInstructorResults() {
    final results = _filteredInstructors;
    if (results.isEmpty) return _buildEmptyState('No instructors found.');

    return RefreshIndicator(
      onRefresh: _fetchData,
      color: AppTheme.primaryGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, idx) {
          final inst = results[idx];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.paleGold,
                    child: const Icon(Icons.person, color: AppTheme.primaryGold, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(inst.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            if (inst.featured) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.star, color: AppTheme.primaryGold, size: 16),
                            ],
                          ],
                        ),
                        if (inst.specialization != null) ...[
                          const SizedBox(height: 4),
                          Text(inst.specialization!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                        if (inst.studioName != null) ...[
                          const SizedBox(height: 2),
                          Text(inst.studioName!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ],
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 56, color: AppTheme.primaryGold.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }
}
