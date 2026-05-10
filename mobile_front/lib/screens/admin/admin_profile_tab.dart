import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../utils/app_theme.dart';

class AdminProfileTab extends StatefulWidget {
  const AdminProfileTab({super.key});

  @override
  State<AdminProfileTab> createState() => _AdminProfileTabState();
}

class _AdminProfileTabState extends State<AdminProfileTab> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

  // controllers
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _currentPwCtrl = TextEditingController();
  final _newPwCtrl     = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  // state
  bool _isEditing   = false;
  bool _hideCurrent = true;
  bool _hideNew     = true;
  bool _hideConfirm = true;

  String _originalUsername = '';
  String _originalEmail    = '';
  Uint8List? _photoBytes;
  bool _loading   = true;
  bool _saving    = false;
  bool _uploading = false;

  Map<String, String> _fieldErrors = {};

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

  // ── Data Loading ──────────────────────────────────────────────────────────
  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final data = await _userService.getMe();
      _originalUsername = data['username'] ?? '';
      _originalEmail    = data['email'] ?? '';
      _usernameCtrl.text = _originalUsername;
      _emailCtrl.text    = _originalEmail;

      final photoId = data['photo'];
      if (photoId != null && photoId.toString().isNotEmpty) {
        final bytes = await _userService.getPhotoBytes(photoId.toString());
        if (mounted && bytes != null) {
          setState(() => _photoBytes = Uint8List.fromList(bytes));
        }
      }
    } catch (e) {
      if (mounted) _showToast('Failed to load profile.', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Photo Actions ─────────────────────────────────────────────────────────
  void _showPhotoOptions() {
    if (!_isEditing) return; // Prevent photo change if not editing
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.pureWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.mediumGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _photoSheetButton(Icons.upload_rounded, 'Upload New Photo', () {
              Navigator.pop(context);
              _pickAndUploadPhoto();
            }),
            if (_photoBytes != null) ...[
              const SizedBox(height: 10),
              _photoSheetButton(Icons.delete_outline_rounded, 'Remove Photo', () {
                Navigator.pop(context);
                _removePhoto();
              }, isDestructive: true),
            ],
            const SizedBox(height: 10),
            _photoSheetButton(Icons.close_rounded, 'Cancel', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _photoSheetButton(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: isDestructive ? AppTheme.errorGold.withOpacity(0.1) : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDestructive ? AppTheme.errorGold : AppTheme.primaryGold, size: 20),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(
              color: isDestructive ? AppTheme.errorGold : AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final fileId = await _userService.uploadPhoto(picked.path);
      if (fileId == null) throw Exception('Upload returned no ID');
      await _userService.updatePhoto(fileId);
      final bytes = await _userService.getPhotoBytes(fileId);
      if (mounted && bytes != null) {
        setState(() => _photoBytes = Uint8List.fromList(bytes));
        _showToast('Photo updated!');
      }
    } catch (e) {
      if (mounted) _showToast('Failed to upload photo.', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _uploading = true);
    try {
      await _userService.removePhoto();
      if (mounted) setState(() => _photoBytes = null);
      _showToast('Photo removed.');
    } catch (e) {
      if (mounted) _showToast('Failed to remove photo.', isError: true);
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ── Form Submit ───────────────────────────────────────────────────────────
  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;

    final currentPw  = _currentPwCtrl.text;
    final newPw      = _newPwCtrl.text;
    final confirmPw  = _confirmPwCtrl.text;

    if (newPw.isNotEmpty && newPw != confirmPw) {
      setState(() => _fieldErrors['confirmPassword'] = 'Passwords do not match.');
      return;
    }

    final changedUsername = _usernameCtrl.text.trim() != _originalUsername
        ? _usernameCtrl.text.trim()
        : null;
    final changedEmail = _emailCtrl.text.trim() != _originalEmail
        ? _emailCtrl.text.trim()
        : null;

    setState(() => _saving = true);
    try {
      final result = await _userService.updateMe(
        currentPassword: currentPw,
        username:    changedUsername,
        email:       changedEmail,
        newPassword: newPw.isNotEmpty ? newPw : null,
      );

      final newUsername = result['username'] ?? _originalUsername;
      final newEmail    = result['email']    ?? _originalEmail;
      final newToken    = result['token'];

      // CRITICAL: Update AuthProvider with new token and username
      // This prevents the "User not found" error on subsequent requests
      if (mounted) {
        final auth = context.read<AuthProvider>();
        await auth.updateAuthData(
          token: (newToken != null && newToken.toString().isNotEmpty) ? newToken.toString() : null,
          username: newUsername,
        );
      }

      _originalUsername = newUsername;
      _originalEmail    = newEmail;
      _usernameCtrl.text = newUsername;
      _emailCtrl.text    = newEmail;
      _currentPwCtrl.clear();
      _newPwCtrl.clear();
      _confirmPwCtrl.clear();

      if (mounted) {
        setState(() => _isEditing = false);
        _showToast('Profile updated successfully!');
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      final lower = msg.toLowerCase();
      if (mounted) {
        if (lower.contains('password')) {
          setState(() => _fieldErrors['currentPassword'] = msg);
        } else if (lower.contains('username')) {
          setState(() => _fieldErrors['username'] = msg);
        } else if (lower.contains('email')) {
          setState(() => _fieldErrors['email'] = msg);
        } else {
          _showToast(msg, isError: true);
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() {
    _usernameCtrl.text = _originalUsername;
    _emailCtrl.text    = _originalEmail;
    _currentPwCtrl.clear();
    _newPwCtrl.clear();
    _confirmPwCtrl.clear();
    setState(() {
      _fieldErrors = {};
      _isEditing = false;
    });
  }

  void _showLogoutConfirmation() {
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
          'Are you sure you want to sign out of your admin account?',
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
              await context.read<AuthProvider>().logout();
              if (mounted) context.go('/login');
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

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
      ]),
      backgroundColor: isError ? AppTheme.errorGold : AppTheme.successGold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    final initials = _originalUsername.isNotEmpty
        ? _originalUsername.substring(0, _originalUsername.length >= 2 ? 2 : 1).toUpperCase()
        : 'AD';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Profile Header ──────────────────────────────────────────────
          _buildProfileHeader(initials),
          const SizedBox(height: 28),

          // ── Account Information ─────────────────────────────────────────
          _buildSectionCard(
            title: 'Account Information',
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildField(
                    controller: _usernameCtrl,
                    label: 'Username',
                    icon: Icons.person_outline_rounded,
                    enabled: _isEditing,
                    error: _fieldErrors['username'],
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required.' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    controller: _emailCtrl,
                    label: 'Email Address',
                    icon: Icons.alternate_email_rounded,
                    enabled: _isEditing,
                    keyboardType: TextInputType.emailAddress,
                    error: _fieldErrors['email'],
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email is required.';
                      if (!v.contains('@') || !v.contains('.')) return 'Invalid email address.';
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Change Password ─────────────────────────────────────────────
          if (_isEditing) ...[
            _buildSectionCard(
              title: 'Change Password',
              subtitle: 'Your current password is required to save any changes.',
              child: Column(
                children: [
                  _buildField(
                    controller: _currentPwCtrl,
                    label: 'Current Password *',
                    icon: Icons.lock_outline_rounded,
                    enabled: true,
                    obscureText: _hideCurrent,
                    error: _fieldErrors['currentPassword'],
                    suffixIcon: IconButton(
                      icon: Icon(_hideCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.textSecondary, size: 20),
                      onPressed: () => setState(() => _hideCurrent = !_hideCurrent),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Current password is required.' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildField(
                          controller: _newPwCtrl,
                          label: 'New Password',
                          icon: Icons.lock_reset_rounded,
                          enabled: true,
                          obscureText: _hideNew,
                          error: _fieldErrors['newPassword'],
                          hint: 'Leave blank',
                          suffixIcon: IconButton(
                            icon: Icon(_hideNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.textSecondary, size: 20),
                            onPressed: () => setState(() => _hideNew = !_hideNew),
                          ),
                          validator: (v) {
                            if (v != null && v.isNotEmpty && v.length < 6) {
                              return 'At least 6 characters.';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildField(
                          controller: _confirmPwCtrl,
                          label: 'Confirm Password',
                          icon: Icons.lock_outline_rounded,
                          enabled: true,
                          obscureText: _hideConfirm,
                          error: _fieldErrors['confirmPassword'],
                          hint: 'Repeat',
                          suffixIcon: IconButton(
                            icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                color: AppTheme.textSecondary, size: 20),
                            onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Actions ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ] else ...[
             // ── Logout ──────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showLogoutConfirmation,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.errorGold,
                  side: const BorderSide(color: AppTheme.errorGold, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Widget Builders ───────────────────────────────────────────────────────
  Widget _buildProfileHeader(String initials) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGold, AppTheme.primaryGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar / Photo
          GestureDetector(
            onTap: _showPhotoOptions,
            child: Stack(
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white24,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: _uploading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : _photoBytes != null
                          ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                          : Center(
                              child: Text(initials,
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                ),
                if (_isEditing)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 22, height: 22,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppTheme.darkGold),
                      child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Name and subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Profile',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isEditing ? 'Editing your credentials' : 'View your account details',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Edit Toggle Icon
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_rounded, color: Colors.white),
            onPressed: () => setState(() {
              if (_isEditing) {
                _reset();
              } else {
                _isEditing = true;
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.paleGold),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary,
          )),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? error,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          enabled: enabled,
          validator: validator,
          onChanged: (_) => setState(() => _fieldErrors = {}),
          style: TextStyle(color: enabled ? AppTheme.textPrimary : AppTheme.textSecondary),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: enabled ? AppTheme.primaryGold : AppTheme.textSecondary),
            suffixIcon: suffixIcon,
            errorText: error,
            isDense: true,
            filled: !enabled,
            fillColor: enabled ? Colors.white : AppTheme.lightGray,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}
