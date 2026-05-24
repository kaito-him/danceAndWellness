import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/course.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/instructor_service.dart';
import '../../utils/app_theme.dart';

class InstructorFeedScreen extends StatefulWidget {
  const InstructorFeedScreen({super.key});

  @override
  State<InstructorFeedScreen> createState() => _InstructorFeedScreenState();
}

class _InstructorFeedScreenState extends State<InstructorFeedScreen> {
  final _service = InstructorDashboardService();
  final _searchCtrl = TextEditingController();

  List<Course> _courses = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String? _error;

  String _search    = '';
  String _filterCat = 'ALL';
  String _filterLvl = 'ALL';

  static const _gold     = AppTheme.primaryGold;
  static const _bg       = AppTheme.pageBackground;
  static const _textDark = AppTheme.textPrimary;
  static const _textMid  = AppTheme.textSecondary;
  static const _paleGold = AppTheme.paleGold;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _service.getAllPublishedCourses(),
        _service.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _courses    = results[0] as List<Course>;
          _categories = results[1] as List<Map<String, dynamic>>;
          _loading    = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load feed data.'; _loading = false; });
    }
  }

  List<Course> get _filtered {
    final q = _search.toLowerCase();
    return _courses.where((c) {
      final matchSearch = q.isEmpty ||
          c.title.toLowerCase().contains(q) ||
          (c.instructor?.username ?? '').toLowerCase().contains(q);
      final matchCat = _filterCat == 'ALL' || c.categoryId == _filterCat;
      final matchLvl = _filterLvl == 'ALL' || c.level == _filterLvl;
      return matchSearch && matchCat && matchLvl;
    }).toList();
  }

  String _catName(String? id) {
    if (id == null) return '';
    final cat = _categories.firstWhere((c) => c['id'] == id, orElse: () => {});
    return cat['name'] as String? ?? '';
  }

  Color _levelColor(String? level) {
    switch (level) {
      case 'BEGINNER':     return const Color(0xFF27AE60);
      case 'INTERMEDIATE': return const Color(0xFFB89C4D);
      case 'ADVANCED':     return const Color(0xFFC0392B);
      default:             return const Color(0xFFB89C4D);
    }
  }

  String _levelLabel(String? level) {
    switch (level) {
      case 'BEGINNER':     return 'Beginner';
      case 'INTERMEDIATE': return 'Intermediate';
      case 'ADVANCED':     return 'Advanced';
      default:             return level ?? '';
    }
  }

  void _onCardTap() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (ctx) => _SwitchToStudentDialog(
        onSwitch: () async {
          Navigator.pop(ctx);
          await context.read<AuthProvider>().logout();
          if (mounted) context.go('/login');
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorGold),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: _textMid)),
            const SizedBox(height: 16),
            ElevatedButton.icon(onPressed: _load, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      );
    }

    final rows = _filtered;

    return RefreshIndicator(
      color: _gold,
      onRefresh: _load,
      child: CustomScrollView(
        slivers: [
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHeader()),

          // ── Filter bar ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildFilterBar()),

          // ── Results count ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                '${rows.length} matching course${rows.length != 1 ? 's' : ''}',
                style: const TextStyle(fontSize: 12, color: _textMid),
              ),
            ),
          ),

          // ── Course grid ──────────────────────────────────────────────────
          rows.isEmpty
              ? SliverFillRemaining(child: _buildEmpty())
              : SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => _buildCourseCard(rows[i]),
                      childCount: rows.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.darkGold, AppTheme.primaryGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Community Feed',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Georgia')),
          const SizedBox(height: 4),
          Text('See what other instructors are publishing',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
        ],
      ),
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        children: [
          // Search
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F0E8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              style: const TextStyle(fontSize: 14, color: _textDark),
              decoration: InputDecoration(
                hintText: 'Search courses or instructors…',
                hintStyle: const TextStyle(color: _textMid, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: _textMid, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18, color: _textMid),
                        onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Category + Level dropdowns
          Row(
            children: [
              Expanded(child: _buildDropdown(
                value: _filterCat,
                items: [
                  const DropdownMenuItem(value: 'ALL', child: Text('All Categories')),
                  ..._categories.map((c) => DropdownMenuItem(
                    value: c['id'] as String,
                    child: Text(c['name'] as String? ?? '', overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: (v) => setState(() => _filterCat = v ?? 'ALL'),
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildDropdown(
                value: _filterLvl,
                items: const [
                  DropdownMenuItem(value: 'ALL',          child: Text('All Levels')),
                  DropdownMenuItem(value: 'BEGINNER',     child: Text('Beginner')),
                  DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate')),
                  DropdownMenuItem(value: 'ADVANCED',     child: Text('Advanced')),
                ],
                onChanged: (v) => setState(() => _filterLvl = v ?? 'ALL'),
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0E8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: _textMid),
          style: const TextStyle(fontSize: 12, color: _textDark),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off_rounded, size: 56, color: _textMid),
          const SizedBox(height: 14),
          const Text('No results found',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: _textDark)),
          const SizedBox(height: 6),
          const Text('Try adjusting your search or filters.',
              style: TextStyle(fontSize: 13, color: _textMid)),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() { _search = ''; _filterCat = 'ALL'; _filterLvl = 'ALL'; });
            },
            child: const Text('Clear all filters', style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );
  }

  // ── Course card ────────────────────────────────────────────────────────────
  Widget _buildCourseCard(Course course) {
    final levelColor = _levelColor(course.level);
    final catName    = _catName(course.categoryId);
    final instrName  = course.instructor?.username ?? 'Unknown Instructor';
    final instrPhoto = course.instructor?.photo;

    return GestureDetector(
      onTap: _onCardTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEFE6D5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: Stack(
                children: [
                  // Image or placeholder
                  course.thumbnailUrl != null
                      ? Image.network(
                          ApiClient.formatMediaUrl(course.thumbnailUrl!),
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                        )
                      : _thumbPlaceholder(),
                  // Level badge
                  Positioned(
                    top: 10, left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: levelColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(_levelLabel(course.level),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  // Price badge
                  Positioned(
                    top: 10, right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: course.isFree ? const Color(0xFF27AE60) : const Color(0xFF1C2126).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.isFree ? 'Free' : '\$${course.price?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  if (catName.isNotEmpty)
                    Text(catName.toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: _gold, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
                  const SizedBox(height: 4),
                  // Title
                  Text(course.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _textDark),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  // Instructor
                  Row(
                    children: [
                      Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _paleGold,
                          image: instrPhoto != null
                              ? DecorationImage(
                                  image: NetworkImage(ApiClient.formatMediaUrl('/api/files/$instrPhoto')),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: instrPhoto == null
                            ? Center(child: Text(instrName[0].toUpperCase(),
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _gold)))
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(instrName,
                            style: const TextStyle(fontSize: 12, color: _textMid),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Stats row
                  Row(
                    children: [
                      _statChip(Icons.video_library_outlined, '${course.lessonCount} Lessons'),
                      const SizedBox(width: 10),
                      _statChip(Icons.quiz_outlined, '${course.quizCount} Quizzes'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // CTA
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _onCardTap,
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('View Course', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _gold,
                        side: const BorderSide(color: _gold),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: _paleGold,
      child: const Center(child: Icon(Icons.movie_outlined, size: 48, color: _gold)),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: _textMid),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: _textMid)),
      ],
    );
  }
}

// ── Switch to Student Dialog ───────────────────────────────────────────────────
class _SwitchToStudentDialog extends StatelessWidget {
  final VoidCallback onSwitch;
  final VoidCallback onCancel;

  const _SwitchToStudentDialog({required this.onSwitch, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 32, color: AppTheme.primaryGold),
            ),
            const SizedBox(height: 20),
            const Text('Switch to Student View',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary, fontFamily: 'Georgia'),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            const Text(
              'To view, enroll, or interact with courses as a student, you must use a student account.\n\nWould you like to log out and sign in as a student?',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textSecondary,
                      side: const BorderSide(color: Color(0xFFD5C9B8)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onSwitch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Switch', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
