import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/student_service.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';

class StudentProfileTab extends StatefulWidget {
  const StudentProfileTab({super.key});

  @override
  State<StudentProfileTab> createState() => _StudentProfileTabState();
}

class _StudentProfileTabState extends State<StudentProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _studentService = StudentService();
  final _userService = UserService();

  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _badges = [];

  bool _loading = true;
  bool _saving = false;
  bool _isEditing = false;
  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  String _originalUsername = '';
  String _originalEmail = '';
  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() {
      _loading = true;
      _fieldErrors = {};
    });

    try {
      final results = await Future.wait([
        _studentService.getCurrentUser(),
        _studentService.getStudentStats(userId),
        _studentService.getMyBadgeStatus(),
      ]);

      final profile = results[0] as Map<String, dynamic>;
      _originalUsername = profile['username'] ?? '';
      _originalEmail = profile['email'] ?? '';
      
      _usernameCtrl.text = _originalUsername;
      _emailCtrl.text = _originalEmail;

      setState(() {
        _userProfile = profile;
        _stats = results[1] as Map<String, dynamic>;
        _badges = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showToast('Failed to load profile details.', isError: true);
    }
  }

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final currentPw = _currentPwCtrl.text;
    final newPw = _newPwCtrl.text;
    final confirmPw = _confirmPwCtrl.text;

    if (newPw.isNotEmpty && newPw != confirmPw) {
      setState(() => _fieldErrors['confirmPassword'] = 'Passwords do not match.');
      return;
    }

    setState(() => _saving = true);
    try {
      // 1. Update basic info
      final changedUsername = _usernameCtrl.text.trim() != _originalUsername ? _usernameCtrl.text.trim() : null;
      final changedEmail = _emailCtrl.text.trim() != _originalEmail ? _emailCtrl.text.trim() : null;

      if (changedUsername != null || changedEmail != null) {
        await _userService.updateMe(
          currentPassword: currentPw,
          username: changedUsername,
          email: changedEmail,
        );
      }

      // 2. Change password if filled
      if (newPw.isNotEmpty) {
        await _userService.updateMe(
          currentPassword: currentPw,
          newPassword: newPw,
        );
      }

      final auth = context.read<AuthProvider>();
      final newUsername = changedUsername ?? _originalUsername;
      await auth.updateAuthData(username: newUsername);

      _originalUsername = newUsername;
      _originalEmail = changedEmail ?? _originalEmail;
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();

      setState(() => _isEditing = false);
      _showToast('Profile updated successfully.');
      _loadAll();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final lower = msg.toLowerCase();
      setState(() {
        if (lower.contains('password')) {
          _fieldErrors['currentPassword'] = msg;
        } else if (lower.contains('username')) {
          _fieldErrors['username'] = msg;
        } else if (lower.contains('email')) {
          _fieldErrors['email'] = msg;
        } else {
          _showToast(msg, isError: true);
        }
      });
    } finally {
      setState(() => _saving = false);
    }
  }

  void _reset() {
    _usernameCtrl.text = _originalUsername;
    _emailCtrl.text = _originalEmail;
    _currentPwCtrl.clear();
    _newPwCtrl.clear();
    _confirmPwCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _fieldErrors = {};
      _isEditing = false;
    });
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? AppTheme.errorGold : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    final initials = _originalUsername.isNotEmpty ? _originalUsername.substring(0, 1).toUpperCase() : 'S';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          _buildProfileHeader(initials),
          const SizedBox(height: 28),
          _buildStatsRow(),
          const SizedBox(height: 28),
          _buildSectionHeader('PROFILE INFO'),
          const SizedBox(height: 12),
          _buildProfileInfoCard(),
          const SizedBox(height: 28),
          _buildSectionHeader('MY BADGES'),
          const SizedBox(height: 12),
          _buildBadgesGrid(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String initials) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
            border: Border.all(color: AppTheme.paleGold, width: 2),
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _originalUsername,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          _originalEmail,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final enrollments = _stats?['enrollmentsCount'] ?? 0;
    final streak = _stats?['loginStreak'] ?? 0;
    final categories = _stats?['categoriesWatched'] ?? 0;
    final earned = _badges.where((b) => b['earned'] == true).length;

    return Row(
      children: [
        _statCard('Enrolled', '$enrollments', Icons.play_circle_outline),
        const SizedBox(width: 8),
        _statCard('Streak', '${streak}d', Icons.local_fire_department_outlined),
        const SizedBox(width: 8),
        _statCard('Watched', '$categories', Icons.category_outlined),
        const SizedBox(width: 8),
        _statCard('Badges', '$earned', Icons.military_tech_outlined),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.paleGold),
          boxShadow: [
            BoxShadow(color: AppTheme.primaryGold.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryGold, size: 20),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 1.1)),
        if (!_isEditing)
          GestureDetector(
            onTap: () => setState(() => _isEditing = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: const Row(
                children: [
                  Icon(Icons.edit_outlined, size: 13, color: AppTheme.primaryGold),
                  SizedBox(width: 4),
                  Text('Edit', style: TextStyle(color: AppTheme.primaryGold, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProfileInfoCard() {
    if (_isEditing) {
      return Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.paleGold)),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildField(
                controller: _usernameCtrl,
                label: 'Username',
                icon: Icons.person_outline,
                error: _fieldErrors['username'],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _emailCtrl,
                label: 'Email',
                icon: Icons.mail_outline,
                error: _fieldErrors['email'],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _currentPwCtrl,
                label: 'Current Password',
                icon: Icons.lock_outline,
                obscureText: _hideCurrent,
                error: _fieldErrors['currentPassword'],
                hint: 'Required to confirm changes',
                suffixIcon: IconButton(
                  icon: Icon(_hideCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                  onPressed: () => setState(() => _hideCurrent = !_hideCurrent),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Current password is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        side: const BorderSide(color: AppTheme.paleGold),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white),
                      child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white)) : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.paleGold)),
      child: Column(
        children: [
          _infoRow(Icons.person_outline, 'Username', _originalUsername, isFirst: true),
          _infoRow(Icons.mail_outline, 'Email', _originalEmail),
          _infoRow(Icons.lock_outline, 'Change Password', 'Tap to update', isLast: true, onTap: _showChangePasswordModal),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isFirst = false, bool isLast = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(top: Radius.circular(isFirst ? 16 : 0), bottom: Radius.circular(isLast ? 16 : 0)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppTheme.paleGold, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppTheme.primaryGold, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _StudentPasswordDialog(
        userService: _userService,
        onSuccess: () => _showToast('Password updated successfully!'),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? error,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryGold),
        suffixIcon: suffixIcon,
        errorText: error,
      ),
    );
  }

  // ── Badges Grid ─────────────────────────────────────────────────────────────
  Widget _buildBadgesGrid() {
    if (_badges.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.paleGold)),
        child: const Center(child: Text('No badges available.', style: TextStyle(color: AppTheme.textSecondary))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, i) {
        final b = _badges[i];
        final earned = b['earned'] == true;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: earned ? AppTheme.primaryGold : Colors.grey[200]!, width: earned ? 1.5 : 1),
            boxShadow: [
              if (earned) BoxShadow(color: AppTheme.primaryGold.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: earned ? 1.0 : 0.4,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: earned ? AppTheme.paleGold : Colors.grey[200],
                  child: Icon(
                    earned ? Icons.military_tech_rounded : Icons.lock_outline_rounded,
                    color: earned ? AppTheme.primaryGold : Colors.grey[600],
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                b['name'] ?? 'Badge',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: earned ? AppTheme.textPrimary : Colors.grey[600]),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                b['description'] ?? 'Unlock by learning',
                style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Password Dialog ──────────────────────────────────────────────────────────
class _StudentPasswordDialog extends StatefulWidget {
  final UserService userService;
  final VoidCallback onSuccess;
  const _StudentPasswordDialog({required this.userService, required this.onSuccess});

  @override
  State<_StudentPasswordDialog> createState() => _StudentPasswordDialogState();
}

class _StudentPasswordDialogState extends State<_StudentPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errors = {});
    if (!_formKey.currentState!.validate()) return;
    if (_newCtrl.text != _confirmCtrl.text) {
      setState(() => _errors['confirmPassword'] = 'Passwords do not match.');
      return;
    }

    setState(() => _saving = true);
    try {
      await widget.userService.updateMe(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final lower = msg.toLowerCase();
      setState(() {
        if (lower.contains('password')) {
          _errors['currentPassword'] = msg;
        } else {
          _errors['general'] = msg;
        }
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 24), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Text('Change Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 24),
            TextFormField(
              controller: _currentCtrl,
              obscureText: _hideCurrent,
              decoration: InputDecoration(
                labelText: 'Current Password',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                errorText: _errors['currentPassword'],
                suffixIcon: IconButton(
                  icon: Icon(_hideCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                  onPressed: () => setState(() => _hideCurrent = !_hideCurrent),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Current password is required.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _newCtrl,
              obscureText: _hideNew,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                suffixIcon: IconButton(
                  icon: Icon(_hideNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                  onPressed: () => setState(() => _hideNew = !_hideNew),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'New password is required.' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: _hideConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryGold),
                errorText: _errors['confirmPassword'],
                suffixIcon: IconButton(
                  icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                  onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Confirm password is required.' : null,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.textSecondary, side: const BorderSide(color: AppTheme.paleGold)),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold, foregroundColor: Colors.white),
                    child: _saving ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white)) : const Text('Change Password'),
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
