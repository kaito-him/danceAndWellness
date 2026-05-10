import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../utils/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notifService = NotificationApiService();
  List<NotificationModel> _notifications = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    try {
      final list = await _notifService.getNotifications();
      setState(() {
        _notifications = list;
        _loading = false;
      });
      // Update unread count provider
      if (mounted) {
        context.read<NotificationProvider>().fetchUnreadCount();
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    await _notifService.markAllRead();
    if (mounted) {
      context.read<NotificationProvider>().resetCount();
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.read))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppTheme.errorGold)))
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: AppTheme.primaryGold,
                  child: _notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _notifications.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (_, i) => _buildNotificationTile(_notifications[i]),
                        ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 64, color: AppTheme.primaryGold),
          SizedBox(height: 16),
          Text('No notifications yet', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: n.read ? AppTheme.lightGray : AppTheme.paleGold,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _getNotifIcon(n.type),
          color: n.read ? AppTheme.textSecondary : AppTheme.primaryGold,
          size: 22,
        ),
      ),
      title: Text(
        n.message,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary,
          fontWeight: n.read ? FontWeight.normal : FontWeight.w600,
        ),
      ),
      subtitle: Text(
        _formatDate(n.createdAt),
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
      onTap: () async {
        if (!n.read) {
          await _notifService.markRead(n.id);
          if (mounted) {
            context.read<NotificationProvider>().decrementCount();
            setState(() => n.read = true);
          }
        }
      },
    );
  }

  IconData _getNotifIcon(String? type) {
    switch (type) {
      case 'COURSE_ENROLLMENT': return Icons.school_outlined;
      case 'PURCHASE_SUCCESS': return Icons.check_circle_outline;
      case 'FEATURED': return Icons.star_outline;
      default: return Icons.notifications_outlined;
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
