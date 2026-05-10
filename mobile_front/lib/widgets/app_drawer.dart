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
  final VoidCallback? onProfileTap;

  const AppDrawer({super.key, this.onProfileTap});

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
      if (_loadedPhotoId == photoId) return; // already loaded
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
    final roleLabel = role.value; // e.g. "STUDENT", "INSTRUCTOR", "ADMIN"

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
          const SizedBox(height: 8),

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

          // ── Spacer ───────────────────────────────────────────────────────
          const Spacer(),

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
        Navigator.pop(context); // close drawer
        if (widget.onProfileTap != null) {
          widget.onProfileTap!();
        } else {
          // For student/instructor, push to a profile route (future)
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
            // Avatar
            Stack(
              children: [
                Container(
                  width: 66, height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _loadingPhoto
                      ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : _photoBytes != null
                          ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                          : Center(
                              child: Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                ),
                // Small edit hint icon
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.darkGold),
                    child: const Icon(Icons.edit_rounded, size: 11, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Username
            Text(
              username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),

            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                roleLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tap-to-edit hint
            Row(
              children: [
                const Icon(Icons.touch_app_outlined, size: 12, color: Colors.white60),
                const SizedBox(width: 4),
                Text(
                  'Tap to manage profile',
                  style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
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
            width: 38, height: 38,
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
          trailing: trailing ?? const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 18),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
      ),
    );
  }

  // ── Unread badge ───────────────────────────────────────────────────────────
  Widget _buildUnreadBadge(BuildContext context) {
    final count = context.watch<NotificationProvider>().unreadCount;
    if (count == 0) return const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary, size: 18);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.errorGold,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
              Navigator.pop(context); // close drawer
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
