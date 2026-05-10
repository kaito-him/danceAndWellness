import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/admin_user_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import 'admin_user_detail_screen.dart';

class AdminAccountsTab extends StatefulWidget {
  final String? initialRoleFilter;
  final String? initialStatusFilter;
  const AdminAccountsTab({super.key, this.initialRoleFilter, this.initialStatusFilter});

  @override
  State<AdminAccountsTab> createState() => _AdminAccountsTabState();
}

class _AdminAccountsTabState extends State<AdminAccountsTab> {
  final AdminUserService _userService = AdminUserService();
  List<AppUser> _allUsers = [];
  List<AppUser> _filteredUsers = [];
  bool _loading = true;

  String _searchQuery = '';
  String _roleFilter = 'ALL';
  String _statusFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    if (widget.initialRoleFilter != null) _roleFilter = widget.initialRoleFilter!;
    if (widget.initialStatusFilter != null) _statusFilter = widget.initialStatusFilter!;
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final users = await _userService.getAllUsers();
      if (mounted) {
        setState(() {
          _allUsers = users;
          _applyFilters();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Failed to load users', isError: true);
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _allUsers.where((u) {
        final matchesSearch = u.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            u.email.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesRole = _roleFilter == 'ALL' || u.role.toUpperCase() == _roleFilter;
        final matchesStatus = _statusFilter == 'ALL' || u.accountStatus.toUpperCase() == _statusFilter;
        return matchesSearch && matchesRole && matchesStatus;
      }).toList();
    });
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorGold : AppTheme.successGold,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _handleBanAction(AppUser user) async {
    final isBanned = user.accountStatus == 'INACTIVE';
    try {
      if (isBanned) {
        await _userService.unbanUser(user.userId);
        _showToast('Account reinstated for ${user.username}');
      } else {
        await _userService.banUser(user.userId);
        _showToast('Account suspended for ${user.username}');
      }
      _fetchUsers();
    } catch (e) {
      _showToast('Failed to update account status', isError: true);
    }
  }

  Future<void> _handleHighlightAction(AppUser user) async {
    if (user.role != 'INSTRUCTOR') return;
    try {
      if (user.featured) {
        await _userService.unhighlightInstructor(user.id!);
        _showToast('Instructor unhighlighted');
      } else {
        await _userService.highlightInstructor(user.id!);
        _showToast('Instructor highlighted');
      }
      _fetchUsers();
    } catch (e) {
      _showToast('Failed to update highlight status', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildFilters(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
              : _filteredUsers.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchUsers,
                      color: AppTheme.primaryGold,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) => _buildUserCard(_filteredUsers[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _applyFilters();
            },
            decoration: InputDecoration(
              hintText: 'Search by username or email...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.mediumGray),
              filled: true,
              fillColor: AppTheme.lightGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDropdown('Role', _roleFilter, ['ALL', 'STUDENT', 'INSTRUCTOR'], (val) {
                setState(() { _roleFilter = val!; _applyFilters(); });
              })),
              const SizedBox(width: 12),
              Expanded(child: _buildDropdown('Status', _statusFilter, ['ALL', 'ACTIVE', 'INACTIVE', 'PENDING'], (val) {
                setState(() { _statusFilter = val!; _applyFilters(); });
              })),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s == 'ALL' ? 'All $label' : s.substring(0, 1) + s.substring(1).toLowerCase()),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.paleGold.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGold.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUserDetailScreen(user: user))),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildAvatar(user),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                        if (user.featured) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, color: Colors.orange, size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildBadge(user.role, isRole: true),
                        const SizedBox(width: 8),
                        _buildBadge(user.accountStatus),
                      ],
                    ),
                  ],
                ),
              ),
              _buildPopupMenu(user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(AppUser user) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.paleGold,
        image: user.photo != null
            ? DecorationImage(image: NetworkImage(ApiClient.formatMediaUrl('/api/files/${user.photo}')), fit: BoxFit.cover)
            : null,
      ),
      child: user.photo == null
          ? Center(child: Text(user.username[0].toUpperCase(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)))
          : null,
    );
  }

  Widget _buildBadge(String label, {bool isRole = false}) {
    Color color;
    if (isRole) {
      color = label == 'INSTRUCTOR' ? AppTheme.primaryGold : Colors.blueGrey;
    } else {
      color = label == 'ACTIVE' ? Colors.green : (label == 'INACTIVE' ? Colors.red : Colors.orange);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPopupMenu(AppUser user) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppTheme.mediumGray),
      onSelected: (val) {
        if (val == 'ban') _handleBanAction(user);
        if (val == 'highlight') _handleHighlightAction(user);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'ban',
          child: Row(
            children: [
              Icon(user.accountStatus == 'INACTIVE' ? Icons.check_circle_outline : Icons.block_flipped, size: 18, color: user.accountStatus == 'INACTIVE' ? Colors.green : Colors.red),
              const SizedBox(width: 12),
              Text(user.accountStatus == 'INACTIVE' ? 'Unban Account' : 'Ban Account'),
            ],
          ),
        ),
        if (user.role == 'INSTRUCTOR' && user.accountStatus == 'ACTIVE')
          PopupMenuItem(
            value: 'highlight',
            child: Row(
              children: [
                Icon(user.featured ? Icons.star_border_rounded : Icons.star_rounded, size: 18, color: Colors.orange),
                const SizedBox(width: 12),
                Text(user.featured ? 'Remove Highlight' : 'Highlight Instructor'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_rounded, size: 64, color: AppTheme.mediumGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text('No users found', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        ],
      ),
    );
  }
}
