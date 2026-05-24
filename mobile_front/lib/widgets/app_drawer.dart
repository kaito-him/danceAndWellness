import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../services/user_service.dart';
import '../models/user_role.dart';
import '../utils/app_theme.dart';

class AppDrawer extends StatefulWidget {
  /// Optional callback for navigating to a specific section within the home screen.
  /// Used by Admin to jump directly to the Profile tab.
  final Function(String)? onSectionTap;
  final VoidCallback? onProfileTap;

  const AppDrawer({super.key, this.onProfileTap, this.onSectionTap});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final _userService = UserService();
  Uint8List? _photoBytes;
  bool _loadingPhoto = false;
  String? _loadedPhotoId;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  Future<void> _loadPhoto() async {
    try {
      final data = await _userService.getMe();
      final photoId = data['photo'];
      if (photoId == null || photoId.toString().isEmpty) return;
      if (_loadedPhotoId == photoId) return;
      setState(() => _loadingPhoto = true);
      final bytes = await _userService.getPhotoBytes(photoId.toString());
      if (mounted && bytes != null) {
        setState(() {
          _photoBytes = Uint8List.fromList(bytes);
          _loadedPhotoId = photoId.toString();
        });
      }
    } catch (_) {
      // silently ignore — avatar initials will show
    } finally {
      if (mounted) setState(() => _loadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.role ?? UserRole.student;
    final username = auth.username ?? 'User';
    final roleLabel = role.value;

    final initials = username.isNotEmpty
        ? username.substring(0, username.length >= 2 ? 2 : 1).toUpperCase()
        : '??';

    return Drawer(
      backgroundColor: AppTheme.pageBackground,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          _buildHeader(context, auth, username, roleLabel, initials),

          // ── Navigation Items ─────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildNavItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    trailing: _buildUnreadBadge(context),
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/notifications');
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Divider(color: AppTheme.mediumGray),
                  ),

                  if (role == UserRole.admin) ...[
                    _buildAdminSection(context),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Divider(color: AppTheme.mediumGray),
                    ),
                  ],

                  if (role == UserRole.instructor) ...[
                    _buildInstructorSection(context),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Divider(color: AppTheme.mediumGray),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(color: AppTheme.mediumGray),
          ),

          // ── Sign Out ─────────────────────────────────────────────────────
          _buildNavItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            color: AppTheme.errorGold,
            onTap: () => _confirmLogout(context, auth),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    AuthProvider auth,
    String username,
    String roleLabel,
    String initials,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        if (widget.onProfileTap != null) {
          widget.onProfileTap!();
        }
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 28,
          bottom: 28,
          left: 20,
          right: 20,
        ),
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
            // Avatar — no border, exact fit, matches profile screen
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _loadingPhoto
                    ? Container(
                        color: Colors.white24,
                        child: const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                      )
                    : _photoBytes != null
                        ? Image.memory(
                            _photoBytes!,
                            fit: BoxFit.cover,
                            width: 72,
                            height: 72,
                          )
                        : Container(
                            color: Colors.white24,
                            child: Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
              ),
            ),

            const SizedBox(height: 14),

            // Username · Role on one line
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    username,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white60,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Admin Section ──────────────────────────────────────────────────────────
  Widget _buildAdminSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'MANAGEMENT',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildNavItem(
          icon: Icons.bar_chart_rounded,
          label: 'Platform Statistics',
          onTap: () {
            Navigator.pop(context);
            widget.onSectionTap?.call('stats');
          },
        ),
        _buildNavItem(
          icon: Icons.assignment_ind_outlined,
          label: 'Instructor Applications',
          onTap: () {
            Navigator.pop(context);
            widget.onSectionTap?.call('applications');
          },
        ),
        _buildNavItem(
          icon: Icons.block_flipped,
          label: 'Banned Accounts',
          onTap: () {
            Navigator.pop(context);
            widget.onSectionTap?.call('banned');
          },
        ),
        _buildNavItem(
          icon: Icons.star_rounded,
          label: 'Highlight Instructors',
          onTap: () {
            Navigator.pop(context);
            widget.onSectionTap?.call('highlight');
          },
        ),
        _buildNavItem(
          icon: Icons.archive_outlined,
          label: 'Archived Courses',
          onTap: () {
            Navigator.pop(context);
            widget.onSectionTap?.call('archived');
          },
        ),
        _buildNavItem(
          icon: Icons.emoji_events_outlined,
          label: 'Badges',
          onTap: () {
            Navigator.pop(context);
            widget.onSectionTap?.call('badges');
          },
        ),
        _buildNavItem(
          icon: Icons.category_outlined,
          label: 'Categories',
          onTap: () {
            Navigator.pop(context);
            widget.onSectionTap?.call('categories');
          },
        ),
      ],
    );
  }

  Widget _buildInstructorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Text(
            'INSTRUCTOR',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        _buildNavItem(
          icon: Icons.edit_note_outlined,
          label: 'My Drafts',
          onTap: () {
            Navigator.pop(context);
            context.push('/instructor/drafts');
          },
        ),
        _buildNavItem(
          icon: Icons.archive_outlined,
          label: 'Archived Courses',
          onTap: () {
            Navigator.pop(context);
            context.push('/instructor/archived');
          },
        ),
      ],
    );
  }

  // ── Nav Item ───────────────────────────────────────────────────────────────
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Widget? trailing,
  }) {
    final itemColor = color ?? AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (color ?? AppTheme.primaryGold).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color ?? AppTheme.primaryGold, size: 20),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: itemColor,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          trailing: trailing ??
              const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textSecondary, size: 18),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    );
  }

  // ── Unread badge ───────────────────────────────────────────────────────────
  Widget _buildUnreadBadge(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;
    if (count == 0) {
      return const Icon(Icons.chevron_right_rounded,
          color: AppTheme.textSecondary, size: 18);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.errorGold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ── Logout Confirmation ────────────────────────────────────────────────────
  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.logout_rounded, color: AppTheme.errorGold, size: 24),
          SizedBox(width: 10),
          Text('Sign Out'),
        ]),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              Navigator.pop(context);
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
