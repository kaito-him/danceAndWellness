import 'package:flutter/material.dart';
import '../../models/course.dart';
import '../../services/instructor_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/course_details_bottom_sheet.dart';

class InstructorDraftsScreen extends StatefulWidget {
  const InstructorDraftsScreen({super.key});

  @override
  State<InstructorDraftsScreen> createState() => _InstructorDraftsScreenState();
}

class _InstructorDraftsScreenState extends State<InstructorDraftsScreen> {
  final _instructorService = InstructorDashboardService();
  
  List<Course> _drafts = [];
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
        _instructorService.getDraftCourses(),
        _instructorService.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _drafts = results[0] as List<Course>;
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

  Future<void> _deleteDraft(String courseId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red, size: 24),
            SizedBox(width: 8),
            Text('Delete Draft'),
          ],
        ),
        content: const Text('Are you sure you want to permanently delete this draft course? This action cannot be undone.'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _instructorService.deleteCourse(courseId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft deleted successfully!'), backgroundColor: Colors.green),
        );
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete draft: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openEditDraftDialog(Course course) {
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
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: const AppNavbar(
        title: 'My Drafts',
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
                  child: _drafts.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.edit_note_rounded,
                                    size: 72,
                                    color: AppTheme.primaryGold,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No draft courses found',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Save a new course as draft to see it here.',
                                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                          itemCount: _drafts.length,
                          itemBuilder: (context, index) {
                            final draft = _drafts[index];
                            final thumbUrl = draft.thumbnailUrl != null && draft.thumbnailUrl!.isNotEmpty
                                ? ApiClient.formatMediaUrl(draft.thumbnailUrl)
                                : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppTheme.paleGold.withOpacity(0.8), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryGold.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Course Card Upper Part
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
                                          color: AppTheme.paleGold.withOpacity(0.4),
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
                                                draft.title.isEmpty ? 'Untitled Course' : draft.title,
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
                                                draft.description == null || draft.description!.isEmpty
                                                    ? 'No description provided yet.'
                                                    : draft.description!,
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
                                                    draft.level ?? 'BEGINNER',
                                                    AppTheme.primaryGold.withOpacity(0.12),
                                                    AppTheme.darkGold,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  _chip(
                                                    draft.isFree ? 'Free' : '\$${draft.price?.toStringAsFixed(0) ?? "0"}',
                                                    AppTheme.paleGold.withOpacity(0.5),
                                                    AppTheme.darkGold,
                                                  ),
                                                  const Spacer(),
                                                  const Icon(Icons.play_circle_outline, size: 12, color: AppTheme.textSecondary),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '${draft.lessonCount} lessons',
                                                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  
                                  // Divider
                                  const Divider(height: 1),

                                  // Quick Action Row
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _deleteDraft(draft.courseId),
                                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
                                          label: const Text(
                                            'Delete Draft',
                                            style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _openEditDraftDialog(draft),
                                          icon: const Icon(Icons.edit_note_outlined, size: 18),
                                          label: const Text('Finish Course'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryGold,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
