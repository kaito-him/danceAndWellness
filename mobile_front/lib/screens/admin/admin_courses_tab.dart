import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_course_detail_screen.dart';
import '../../models/course.dart';
import '../../models/category.dart';
import '../../services/api_client.dart';
import '../../services/course_service.dart';
import '../../services/category_service.dart';
import '../../utils/app_theme.dart';
import 'package:go_router/go_router.dart'; // optional if using Navigator

enum AdminCourseSection { published, archived }

class AdminCoursesTab extends StatefulWidget {
  final AdminCourseSection? initialSection;
  const AdminCoursesTab({super.key, this.initialSection});

  @override
  State<AdminCoursesTab> createState() => _AdminCoursesTabState();
}

class _AdminCoursesTabState extends State<AdminCoursesTab> {
  final _courseService = CourseService();
  final _categoryService = CategoryService();
  
  AdminCourseSection _activeSection = AdminCourseSection.published;
  
  List<Course> _courses = [];
  List<Category> _categories = [];
  bool _loading = true;
  
  // Search & Filter
  String _searchQuery = '';
  String? _selectedCategoryId;
  String? _selectedLevel;
  
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialSection != null) {
      _activeSection = widget.initialSection!;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final cats = await _categoryService.getCategories();
      List<Course> courses;
      if (_activeSection == AdminCourseSection.published) {
        courses = await _courseService.getPublishedCourses();
      } else {
        courses = await _courseService.getAdminArchivedCourses();
      }
      
      if (mounted) {
        setState(() {
          _categories = cats;
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

  List<Course> get _filteredCourses {
    return _courses.where((c) {
      final matchesSearch = c.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (c.instructor?.username?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      final matchesCat = _selectedCategoryId == null || c.categoryId == _selectedCategoryId;
      final matchesLevel = _selectedLevel == null || c.level == _selectedLevel;
      return matchesSearch && matchesCat && matchesLevel;
    }).toList();
  }

  // ── Actions ──────────────────────────────────────────────────────────────

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
            Text('Are you sure you want to archive "${course.title}"?'),
            const SizedBox(height: 8),
            const Text('It will be removed from the public catalog.', 
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            const Text('Archiving Reason *', 
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain to the instructor why...',
                fillColor: AppTheme.lightGray,
                filled: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                _showToast('Please provide a reason.', isError: true);
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
            child: const Text('Archive'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _courseService.archiveCourse(course.courseId, reasonController.text.trim());
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
        content: Text('Restore "${course.title}" to the published catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGold),
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

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSectionToggle(),
        _buildFilterBar(),
        Expanded(
          child: _loading 
            ? _buildSkeletons() 
            : _filteredCourses.isEmpty 
              ? _buildEmptyState()
              : _buildCourseList(),
        ),
      ],
    );
  }

  Widget _buildSectionToggle() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          _toggleItem('Published', AdminCourseSection.published),
          const SizedBox(width: 12),
          _toggleItem('Archived', AdminCourseSection.archived),
        ],
      ),
    );
  }

  Widget _toggleItem(String label, AdminCourseSection section) {
    final active = _activeSection == section;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!active) {
            setState(() {
              _activeSection = section;
              _searchQuery = '';
              _searchController.clear();
              _selectedCategoryId = null;
              _selectedLevel = null;
            });
            _fetchData();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryGold : AppTheme.lightGray,
            borderRadius: BorderRadius.circular(12),
            boxShadow: active ? [
              BoxShadow(color: AppTheme.primaryGold.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
            ] : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: TextStyle(
                  color: active ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                )),
                if (active) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${_courses.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          // Search
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search courses...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold),
              filled: true,
              fillColor: AppTheme.lightGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),
          // Dropdowns
          Row(
            children: [
              Expanded(
                child: _buildDropdown<String?>(
                  value: _selectedCategoryId,
                  hint: 'Category',
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Categories')),
                    ..._categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown<String?>(
                  value: _selectedLevel,
                  hint: 'Level',
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Levels')),
                    DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner')),
                    DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                    DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced')),
                  ],
                  onChanged: (v) => setState(() => _selectedLevel = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: (v) => v != null ? onChanged(v) : null,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGold),
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
        itemCount: _filteredCourses.length,
        itemBuilder: (context, index) => _buildCourseCard(_filteredCourses[index]),
      ),
    );
  }

  Widget _buildCourseCard(Course course) {
    final isArchived = _activeSection == AdminCourseSection.archived;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.paleGold.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGold.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
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
                    color: _getLevelColor(course.level).withOpacity(0.9),
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
                    color: AppTheme.primaryGold.withOpacity(0.9),
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
                
                if (isArchived) ...[
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('Archived on: ${course.archivedAt != null ? _formatDate(course.archivedAt!) : "Unknown"}', 
                        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorGold.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.errorGold.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 12, color: AppTheme.errorGold),
                            SizedBox(width: 4),
                            Text('Reason', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.errorGold)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(course.archiveReason ?? 'No reason provided.', 
                          style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: isArchived
                        ? ElevatedButton(
                            onPressed: () => _initiateUnarchive(course),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successGold),
                            child: const Text('Restore'),
                          )
                        : ElevatedButton(
                            onPressed: () => _initiateArchive(course),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
                            child: const Text('Archive'),
                          ),
                    ),
                  ],
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

  String _formatDate(String raw) {
    try {
      final date = DateTime.parse(raw);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (_) {
      return raw;
    }
  }

  Widget _buildSkeletons() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (ctx, i) => Container(
        height: 250,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppTheme.paleGold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_activeSection == AdminCourseSection.published ? Icons.search_off : Icons.archive_outlined, 
            size: 64, color: AppTheme.mediumGray),
          const SizedBox(height: 16),
          Text(_activeSection == AdminCourseSection.published ? 'No published courses found' : 'No archived courses found',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters or search query.', 
            style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
