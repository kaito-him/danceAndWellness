import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/admin_user_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final AppUser user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late AppUser _user;
  final AdminUserService _userService = AdminUserService();
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorGold : AppTheme.successGold,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _handleBanAction() async {
    setState(() => _processing = true);
    final isBanned = _user.accountStatus == 'INACTIVE';
    try {
      if (isBanned) {
        await _userService.unbanUser(_user.userId);
        _showToast('Account reinstated');
      } else {
        await _userService.banUser(_user.userId);
        _showToast('Account suspended');
      }
      // Refresh local state if possible, but for simplicity we'll just pop back or stay
      // Actually, we should ideally fetch the updated user object.
      // For now, I'll just update the local status.
      setState(() {
        _user = AppUser(
          userId: _user.userId,
          id: _user.id,
          username: _user.username,
          email: _user.email,
          role: _user.role,
          photo: _user.photo,
          accountStatus: isBanned ? 'ACTIVE' : 'INACTIVE',
          featured: _user.featured,
          specialization: _user.specialization,
          totalCourses: _user.totalCourses,
          yearsOfExperience: _user.yearsOfExperience,
          lastLoginDate: _user.lastLoginDate,
          createdAt: _user.createdAt,
        );
      });
    } catch (e) {
      _showToast('Failed to update status', isError: true);
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _handleHighlightAction() async {
    setState(() => _processing = true);
    try {
      if (_user.featured) {
        await _userService.unhighlightInstructor(_user.id!);
        _showToast('Instructor unhighlighted');
      } else {
        await _userService.highlightInstructor(_user.id!);
        _showToast('Instructor highlighted');
      }
      setState(() {
        _user = AppUser(
          userId: _user.userId,
          id: _user.id,
          username: _user.username,
          email: _user.email,
          role: _user.role,
          photo: _user.photo,
          accountStatus: _user.accountStatus,
          featured: !_user.featured,
          specialization: _user.specialization,
          totalCourses: _user.totalCourses,
          yearsOfExperience: _user.yearsOfExperience,
          lastLoginDate: _user.lastLoginDate,
          createdAt: _user.createdAt,
        );
      });
    } catch (e) {
      _showToast('Failed to update highlight', isError: true);
    } finally {
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('User Details'),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildActionButtons(),
            const SizedBox(height: 32),
            _buildDetailsSection(),
            if (_user.role == 'INSTRUCTOR') ...[
              const SizedBox(height: 24),
              _buildInstructorSection(),
            ] else if (_user.role == 'STUDENT') ...[
              const SizedBox(height: 24),
              _buildStudentSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.paleGold,
                image: _user.photo != null
                    ? DecorationImage(image: NetworkImage(ApiClient.formatMediaUrl('/api/files/${_user.photo}')), fit: BoxFit.cover)
                    : null,
                boxShadow: [BoxShadow(color: AppTheme.primaryGold.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: _user.photo == null
                  ? Center(child: Text(_user.username[0].toUpperCase(), style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)))
                  : null,
            ),
            if (_user.featured)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Text(_user.username, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        Text(_user.email, style: const TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildStatusChip(),
            const SizedBox(width: 12),
            _buildRoleChip(),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip() {
    final isBanned = _user.accountStatus == 'INACTIVE';
    final isPending = _user.accountStatus == 'PENDING';
    final color = isBanned ? Colors.red : (isPending ? Colors.orange : Colors.green);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(_user.accountStatus, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildRoleChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(_user.role, style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildActionButtons() {
    final isBanned = _user.accountStatus == 'INACTIVE';
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _processing ? null : _handleBanAction,
            icon: Icon(isBanned ? Icons.check_circle_outline : Icons.block_flipped),
            label: Text(isBanned ? 'Unban User' : 'Ban User'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isBanned ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        if (_user.role == 'INSTRUCTOR' && _user.accountStatus == 'ACTIVE') ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _processing ? null : _handleHighlightAction,
              icon: Icon(_user.featured ? Icons.star_border_rounded : Icons.star_rounded),
              label: Text(_user.featured ? 'Unhighlight' : 'Highlight'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        _buildDetailRow('User ID', _user.userId),
        if (_user.id != null) _buildDetailRow('Internal ID', _user.id!),
        _buildDetailRow('Email Address', _user.email),
      ],
    );
  }

  Widget _buildInstructorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Instructor Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        _buildDetailRow('Specialization', _user.specialization ?? 'Not set'),
        _buildDetailRow('Experience', _user.yearsOfExperience ?? 'Not set'),
        _buildDetailRow('Published Courses', '${_user.totalCourses}'),
      ],
    );
  }

  Widget _buildStudentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Student Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        _buildDetailRow('Joined Platform', _user.createdAt?.substring(0, 10) ?? '—'),
        _buildDetailRow('Last Activity', _user.lastLoginDate?.substring(0, 10) ?? '—'),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
