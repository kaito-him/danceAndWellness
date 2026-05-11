import 'package:flutter/material.dart';
import '../../models/category.dart';
import '../../models/course.dart';
import '../../services/api_client.dart';
import '../../services/category_service.dart';
import '../../services/course_service.dart';
import '../../utils/app_theme.dart';
import 'admin_course_detail_screen.dart';

class AdminSearchTab extends StatefulWidget {
  const AdminSearchTab({super.key});

  @override
  State<AdminSearchTab> createState() => _AdminSearchTabState();
}

class _AdminSearchTabState extends State<AdminSearchTab> {
  final _courseService = CourseService();
  final _categoryService = CategoryService();
  final _searchController = TextEditingController();

  List<Course> _publishedCourses = [];
  List<Course> _archivedCourses = [];
  List<Category> _categories = [];

  bool _loading = true;

  String _searchQuery = '';
  String? _selectedLevel;
  String? _selectedStatus; // null = all, 'PUBLISHED', 'ARCHIVED'
  String? _selectedCategoryId;

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
        _categoryService.getCategories(),
        _courseService.getPublishedCourses(),
        _courseService.getAdminArchivedCourses(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _publishedCourses = results[1] as List<Course>;
          _archivedCourses = results[2] as List<Course>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Course> get _allCourses {
    if (_selectedStatus == 'PUBLISHED') return _publishedCourses;
    if (_selectedStatus == 'ARCHIVED') return _archivedCourses;
    return [..._publishedCourses, ..._archivedCourses];
  }

  List<Course> get _filteredCourses {
    final q = _searchQuery.toLowerCase();
    return _allCourses.where((c) {
      final matchesSearch = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          (c.instructor?.username?.toLowerCase().contains(q) ?? false);
      final matchesLevel = _selectedLevel == null || c.level == _selectedLevel;
      final matchesCat = _selectedCategoryId == null || c.categoryId == _selectedCategoryId;
      return matchesSearch && matchesLevel && matchesCat;
    }).toList();
  }

  bool get _hasActiveSearch =>
      _searchQuery.isNotEmpty ||
      _selectedLevel != null ||
      _selectedStatus != null ||
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
      _selectedStatus = null;
      _selectedCategoryId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchHeader(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
              : _hasActiveSearch
                  ? _buildSearchResults()
                  : _buildCategoriesGrid(),
        ),
      ],
    );
  }

  // ── Search Header ─────────────────────────────────────────────────────────

  Widget _buildSearchHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search by title or instructor...',
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
          const SizedBox(height: 12),
          // Dropdowns row
          Row(
            children: [
              Expanded(child: _buildDropdown<String?>(
                value: _selectedLevel,
                hint: 'All Levels',
                icon: Icons.signal_cellular_alt_rounded,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Levels')),
                  DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                  DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                ],
                onChanged: (v) => setState(() => _selectedLevel = v),
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown<String?>(
                value: _selectedStatus,
                hint: 'All Status',
                icon: Icons.toggle_on_rounded,
                items: const [
                  DropdownMenuItem(value: null, child: Text('All Status')),
                  DropdownMenuItem(value: 'PUBLISHED', child: Text('Published')),
                  DropdownMenuItem(value: 'ARCHIVED', child: Text('Archived')),
                ],
                onChanged: (v) => setState(() => _selectedStatus = v),
              )),
            ],
          ),
          // Clear filters chip
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
    required T value,
    required String hint,
    required IconData icon,
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

  // ── Categories Grid ───────────────────────────────────────────────────────

  Widget _buildCategoriesGrid() {
    if (_categories.isEmpty) {
      return const Center(
        child: Text('No categories found.', style: TextStyle(color: AppTheme.textSecondary)),
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

  // ── Search Results ────────────────────────────────────────────────────────

  Widget _buildSearchResults() {
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
                        _buildResultCard(results[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Course course) {
    final isArchived = course.status == 'ADMIN_ARCHIVED';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isArchived
              ? AppTheme.errorGold.withValues(alpha: 0.3)
              : AppTheme.paleGold.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryGold.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminCourseDetailScreen(courseId: course.courseId),
          ),
        ),
        child: Row(
          children: [
            // Thumbnail
            SizedBox(
              width: 90,
              height: 90,
              child: course.thumbnailUrl != null
                  ? Image.network(
                      ApiClient.formatMediaUrl(course.thumbnailUrl),
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: AppTheme.lightGray,
                      child: const Icon(Icons.movie_filter_rounded,
                          size: 32, color: AppTheme.mediumGray),
                    ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _levelBadge(course.level),
                        const SizedBox(width: 6),
                        _statusBadge(isArchived),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          course.instructor?.username ?? 'Unknown',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.chevron_right_rounded,
                  color: AppTheme.primaryGold, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _levelBadge(String? level) {
    Color color;
    switch (level) {
      case 'BEGINNER':
        color = Colors.green;
        break;
      case 'INTERMEDIATE':
        color = Colors.orange;
        break;
      case 'ADVANCED':
        color = Colors.red;
        break;
      default:
        color = AppTheme.primaryGold;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level ?? 'N/A',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _statusBadge(bool isArchived) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isArchived
            ? AppTheme.errorGold.withValues(alpha: 0.12)
            : AppTheme.successGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isArchived ? 'Archived' : 'Published',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isArchived ? AppTheme.errorGold : AppTheme.successGold,
        ),
      ),
    );
  }

  Widget _buildEmptyResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: AppTheme.mediumGray),
          const SizedBox(height: 16),
          const Text('No courses found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Try different keywords or filters.',
              style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: _clearAll,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}
