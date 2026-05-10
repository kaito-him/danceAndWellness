import 'package:flutter/material.dart';
import '../../models/badge.dart';
import '../../models/category.dart';
import '../../services/badge_service.dart';
import '../../services/category_service.dart';
import '../../utils/app_theme.dart';

// ── Badges Tab ───────────────────────────────────────────────────────────────

class AdminBadgesTab extends StatefulWidget {
  const AdminBadgesTab({super.key});

  @override
  State<AdminBadgesTab> createState() => _AdminBadgesTabState();
}

class _AdminBadgesTabState extends State<AdminBadgesTab> {
  final _badgeService = BadgeService();
  List<Badge> _badges = [];
  Map<String, int> _counts = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final badges = await _badgeService.getAllBadges();
      final counts = await _badgeService.getEarnerCounts();
      if (mounted) {
        setState(() {
          _badges = badges;
          _counts = counts;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load badges')));
      }
    }
  }

  void _showBadgeDialog([Badge? badge]) {
    final nameController = TextEditingController(text: badge?.name);
    final achController = TextEditingController(text: badge?.achievement);
    String type = badge?.type ?? 'LEVEL';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(badge == null ? 'Create Badge' : 'Edit Badge'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Badge Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: achController,
                  decoration: const InputDecoration(labelText: 'Achievement Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'LEVEL', child: Text('Level Based')),
                    DropdownMenuItem(value: 'COURSES_COUNT', child: Text('Courses Count')),
                    DropdownMenuItem(value: 'SPECIAL', child: Text('Special Recognition')),
                  ],
                  onChanged: (val) => setDialogState(() => type = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final newBadge = Badge(
                  id: badge?.id ?? '',
                  name: nameController.text,
                  achievement: achController.text,
                  type: type,
                  iconUrl: badge?.iconUrl,
                );
                try {
                  if (badge == null) {
                    await _badgeService.createBadge(newBadge);
                  } else {
                    await _badgeService.updateBadge(badge.id, newBadge);
                  }
                  Navigator.pop(ctx);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Operation failed')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppTheme.primaryGold,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _badges.length,
          itemBuilder: (context, index) {
            final b = _badges[index];
            final earners = _counts[b.id] ?? 0;
            return _buildBadgeCard(b, earners);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBadgeDialog(),
        backgroundColor: AppTheme.primaryGold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBadgeCard(Badge b, int earners) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.paleGold.withOpacity(0.5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppTheme.paleGold.withOpacity(0.3), shape: BoxShape.circle),
            child: const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryGold, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(b.achievement, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _typeBadge(b.type),
                    const SizedBox(width: 8),
                    Text('$earners earners', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showBadgeDialog(b)),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Badge'),
                      content: Text('Delete "${b.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await _badgeService.deleteBadge(b.id);
                    _fetchData();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: AppTheme.lightGray, borderRadius: BorderRadius.circular(6)),
      child: Text(type, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
    );
  }
}

// ── Categories Tab ──────────────────────────────────────────────────────────

class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab> {
  final _categoryService = CategoryService();
  List<Category> _categories = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final cats = await _categoryService.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to load categories')));
      }
    }
  }

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Contemporary Dance'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              try {
                await _categoryService.addCategory(Category(id: '', name: controller.text.trim()));
                Navigator.pop(ctx);
                _fetchData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add category')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppTheme.primaryGold,
        child: ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5)],
              ),
              child: ListTile(
                title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Delete Category'),
                        content: Text('Delete "${cat.name}"?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await _categoryService.deleteCategory(cat.id);
                      _fetchData();
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppTheme.primaryGold,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
