import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'admin_user_detail_screen.dart';
import '../../models/badge.dart' as badge_model;
import '../../models/category.dart';
import '../../services/badge_service.dart';
import '../../services/category_service.dart';
import '../../services/admin_user_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';

// ── Badges Tab ───────────────────────────────────────────────────────────────

class AdminBadgesTab extends StatefulWidget {
  const AdminBadgesTab({super.key});

  @override
  State<AdminBadgesTab> createState() => _AdminBadgesTabState();
}

class _AdminBadgesTabState extends State<AdminBadgesTab> {
  final _badgeService = BadgeService();
  final _adminUserService = AdminUserService();
  List<badge_model.Badge> _badges = [];
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
    );
  }

  Widget _buildBadgeCard(badge_model.Badge b, int earners) {
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.paleGold.withOpacity(0.3), shape: BoxShape.circle),
            child: b.iconUrl != null
                ? Image.network(
                    ApiClient.formatMediaUrl(b.iconUrl!.startsWith('/api/files/') ? b.iconUrl : '/api/files/${b.iconUrl}'),
                    width: 32,
                    height: 32,
                    errorBuilder: (ctx, _, __) => const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryGold, size: 28),
                  )
                : const Icon(Icons.emoji_events_rounded, color: AppTheme.primaryGold, size: 28),
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
                GestureDetector(
                  onTap: () => _showEarnersDialog(b),
                  child: Text('$earners earners', style: const TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: AppTheme.primaryGold,
                    decoration: TextDecoration.underline,
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEarnersDialog(badge_model.Badge badge) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Earners of ${badge.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: FutureBuilder(
            future: _adminUserService.getAllUsers(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)));
              }
              if (!snapshot.hasData) return const Text('No data');
              
              final students = snapshot.data!.where((u) => u.badgeIds.contains(badge.id)).toList();
              
              if (students.isEmpty) return const Text('No students have earned this badge yet.');
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: students.length,
                itemBuilder: (ctx, i) {
                  final s = students[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.paleGold,
                      backgroundImage: s.photo != null ? NetworkImage(ApiClient.formatMediaUrl('/api/files/${s.photo}')) : null,
                      child: s.photo == null ? const Icon(Icons.person, color: AppTheme.darkGold) : null,
                    ),
                    title: Text(s.username, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(s.email, style: const TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdminUserDetailScreen(user: s),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
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
  final _apiClient = ApiClient();
  final _picker = ImagePicker();
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
    File? selectedImage;
    bool uploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await _picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      setDialogState(() => selectedImage = File(picked.path));
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                      image: selectedImage != null 
                        ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                        : null,
                    ),
                    child: selectedImage == null 
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, color: AppTheme.mediumGray, size: 40),
                            SizedBox(height: 8),
                            Text('Pick Category Photo', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        )
                      : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Category Name', hintText: 'e.g. Contemporary Dance'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: uploading ? null : () async {
                if (controller.text.trim().isEmpty) return;
                setDialogState(() => uploading = true);
                try {
                  String? iconPath;
                  if (selectedImage != null) {
                    iconPath = await _apiClient.uploadFile(selectedImage!.path);
                  }
                  await _categoryService.addCategory(Category(
                    id: '', 
                    name: controller.text.trim(),
                    icon: iconPath,
                  ));
                  Navigator.pop(ctx);
                  _fetchData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add category')));
                  setDialogState(() => uploading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              child: uploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Add'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // ── Add Button at Top ──────────────────────────────────────────
              GestureDetector(
                onTap: _showAddCategoryDialog,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryGold, width: 2),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded, color: AppTheme.primaryGold),
                      SizedBox(width: 8),
                      Text('Add New Category', style: TextStyle(
                        color: AppTheme.primaryGold, 
                        fontWeight: FontWeight.bold,
                        fontSize: 16
                      )),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // ── Categories Grid ────────────────────────────────────────────
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
      ),
    );
  }

  Widget _buildCategoryCard(Category cat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: cat.icon != null
              ? Image.network(
                  ApiClient.formatMediaUrl(cat.icon!.startsWith('/api/files/') ? cat.icon : '/api/files/${cat.icon}'),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildSkeleton();
                  },
                  errorBuilder: (ctx, _, __) => Container(
                    color: AppTheme.paleGold.withOpacity(0.3),
                    child: const Icon(Icons.category_rounded, color: AppTheme.primaryGold, size: 32),
                  ),
                )
              : _buildSkeleton(child: const Icon(Icons.category_rounded, color: AppTheme.primaryGold, size: 32)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(cat.name, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton({Widget? child}) {
    return StatefulBuilder(
      builder: (context, setState) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.3, end: 0.7),
          duration: const Duration(milliseconds: 1000),
          builder: (context, value, _) {
            return Container(
              color: AppTheme.mediumGray.withOpacity(value),
              child: child,
            );
          },
          onEnd: () => setState(() {}),
        );
      }
    );
  }
}
