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

class _AdminProfileTabState extends State<AdminProfileTab> with SingleTickerProviderStateMixin {
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

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // ── Theme Colors ───────────────────────────────────────────────────────────
  static const Color _background = Color(0xFFEDE8DE);
  static const Color _cardBg     = Color(0xFFF9F7F2);
  static const Color _gold       = Color(0xFFB89C4D);
  static const Color _goldLight  = Color(0xFFFAF3E6);
  static const Color _textDark   = Color(0xFF1C2126);
  static const Color _textMid    = Color(0xFF5E6266);
  static const Color _textGold   = Color(0xFFB4975A);
  static const Color _errorRed   = Color(0xFFD92D20);

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _loadProfile();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPwCtrl.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

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
      if (mounted) {
        setState(() => _loading = false);
        _animController.forward();
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text('Profile Photo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark)),
            const SizedBox(height: 24),
            _sheetTile(Icons.cloud_upload_outlined, 'Upload New Photo', () {
              Navigator.pop(context);
              _pickAndUploadPhoto();
            }),
            if (_photoBytes != null) ...[
              const SizedBox(height: 10),
              _sheetTile(Icons.delete_sweep_outlined, 'Remove Photo', () {
                Navigator.pop(context);
                _removePhoto();
              }, danger: true),
            ],
            const SizedBox(height: 10),
            _sheetTile(Icons.close_rounded, 'Cancel', () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _sheetTile(IconData icon, String label, VoidCallback onTap, {bool danger = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: danger ? _errorRed.withOpacity(0.06) : Colors.grey[100],
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: danger ? _errorRed : _textDark),
              const SizedBox(width: 14),
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: danger ? _errorRed : _textDark)),
            ],
          ),
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
        _showToast('Photo updated successfully.');
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

  Future<void> _submit() async {
    setState(() => _fieldErrors = {});
    if (!_formKey.currentState!.validate()) return;
    final currentPw = _currentPwCtrl.text;
    final newPw     = _newPwCtrl.text;
    final confirmPw = _confirmPwCtrl.text;
    if (newPw.isNotEmpty && newPw != confirmPw) {
      setState(() => _fieldErrors['confirmPassword'] = 'Passwords do not match.');
      return;
    }
    final changedUsername = _usernameCtrl.text.trim() != _originalUsername ? _usernameCtrl.text.trim() : null;
    final changedEmail = _emailCtrl.text.trim() != _originalEmail ? _emailCtrl.text.trim() : null;
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
        _showToast('Profile updated successfully.');
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
    FocusScope.of(context).unfocus();
    setState(() { _fieldErrors = {}; _isEditing = false; });
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: _errorRed.withOpacity(0.08), shape: BoxShape.circle),
                child: const Icon(Icons.logout_rounded, color: _errorRed, size: 26),
              ),
              const SizedBox(height: 16),
              const Text('Sign Out', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textDark)),
              const SizedBox(height: 10),
              const Text('Are you sure you want to sign out?', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _textMid, height: 1.5)),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(foregroundColor: _textMid, side: const BorderSide(color: Color(0xFFD5C9B8)), padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await context.read<AuthProvider>().logout();
                        if (mounted) context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: _errorRed, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: isError ? _errorRed : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _gold));

    final initials = _originalUsername.isNotEmpty ? _originalUsername.substring(0, 1).toUpperCase() : 'A';

    return Scaffold(
      backgroundColor: _background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildProfileHeader(initials),
                const SizedBox(height: 40),
                _buildSectionHeader('ACCOUNT INFO'),
                const SizedBox(height: 12),
                _buildAccountInfoCard(),
                const SizedBox(height: 32),
                _buildSignOutButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String initials) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: 140, height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: ClipOval(
                child: _photoBytes != null
                    ? Image.memory(_photoBytes!, fit: BoxFit.cover)
                    : Center(child: Text(initials, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _gold))),
              ),
            ),
            Positioned(
              bottom: 4, right: 4,
              child: GestureDetector(
                onTap: _showPhotoOptions,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(_originalUsername, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: -0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 14, color: _gold),
              SizedBox(width: 6),
              Text('Admin', style: TextStyle(color: _gold, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textGold, letterSpacing: 1.2)),
        GestureDetector(
          onTap: () => setState(() => _isEditing = !_isEditing),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: _gold.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(_isEditing ? Icons.close : Icons.edit_outlined, color: _gold, size: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountInfoCard() {
    if (_isEditing) {
      return Form(
        key: _formKey,
        child: Container(
          decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildField(
                controller: _usernameCtrl,
                label: 'Username',
                icon: Icons.person_outline,
                error: _fieldErrors['username'],
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required.' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _emailCtrl,
                label: 'Email Address',
                icon: Icons.mail_outline,
                keyboardType: TextInputType.emailAddress,
                error: _fieldErrors['email'],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required.';
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v)) return 'Invalid email address.';
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
                  icon: Icon(_hideCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18, color: _textMid),
                  onPressed: () => setState(() => _hideCurrent = !_hideCurrent),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Current password is required.' : null,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textMid,
                        side: const BorderSide(color: Color(0xFFD5C9B8)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
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
      decoration: BoxDecoration(color: _cardBg, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _buildInfoRow(Icons.person_outline, 'Username', _originalUsername, isFirst: true),
          _buildInfoRow(Icons.mail_outline, 'Email', _originalEmail),
          _buildInfoRow(Icons.lock_outline, 'Change Password', null, isLast: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value, {bool isFirst = false, bool isLast = false}) {
    return InkWell(
      onTap: value == null ? _showChangePasswordDialog : null,
      borderRadius: BorderRadius.vertical(top: isFirst ? const Radius.circular(24) : Radius.zero, bottom: isLast ? const Radius.circular(24) : Radius.zero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _goldLight, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: _gold, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _textDark)),
                  if (value != null) ...[
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 13, color: _textMid)),
                  ],
                ],
              ),
            ),
            if (value == null) const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PasswordDialog(
        userService: _userService,
        onSuccess: (newToken) async {
          if (!mounted) return;
          if (newToken != null && newToken.isNotEmpty) {
            await context.read<AuthProvider>().updateAuthData(
              token: newToken,
              username: _originalUsername,
            );
          }
          _showToast('Password changed successfully.');
        },
      ),
    );
  }

  Widget _buildSignOutButton() {
    return GestureDetector(
      onTap: _showLogoutConfirmation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: _errorRed, size: 20),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(color: _errorRed, fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required IconData icon, bool enabled = true, TextInputType keyboardType = TextInputType.text, bool obscureText = false, Widget? suffixIcon, String? error, String? hint, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      onChanged: (_) => setState(() => _fieldErrors = {}),
      style: const TextStyle(color: _textDark, fontSize: 14.5, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: TextStyle(color: enabled ? _gold : _textMid, fontSize: 13.5, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, size: 19, color: enabled ? _gold : _textMid),
        suffixIcon: suffixIcon, errorText: error,
        filled: true, fillColor: enabled ? Colors.white : Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFE2D9C8))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _gold, width: 1.8)),
      ),
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  final UserService userService;
  final Future<void> Function(String? newToken) onSuccess;

  const _PasswordDialog({required this.userService, required this.onSuccess});

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _formKey      = GlobalKey<FormState>();
  final _currentCtrl  = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _hideCurrent = true;
  bool _hideNew     = true;
  bool _hideConfirm = true;
  bool _saving      = false;

  Map<String, String> _errors = {};

  static const Color _gold     = Color(0xFFB89C4D);
  static const Color _textDark = Color(0xFF1C2126);
  static const Color _errorRed = Color(0xFFD92D20);

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

    final currentPw = _currentCtrl.text;
    final newPw     = _newCtrl.text;
    final confirmPw = _confirmCtrl.text;

    if (newPw != confirmPw) {
      setState(() => _errors['confirmPassword'] = 'Passwords do not match.');
      return;
    }

    setState(() => _saving = true);
    try {
      final result = await widget.userService.updateMe(
        currentPassword: currentPw,
        newPassword: newPw,
      );
      final newToken = result['token'] as String?;
      if (mounted) {
        Navigator.pop(context);
        await widget.onSuccess(newToken);
      }
    } catch (e) {
      final msg   = e.toString().replaceFirst('Exception: ', '');
      final lower = msg.toLowerCase();
      if (mounted) {
        setState(() {
          if (lower.contains('password')) {
            _errors['currentPassword'] = msg;
          } else {
            _errors['general'] = msg;
          }
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const Text(
              'Change Password',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textDark),
            ),
            const SizedBox(height: 24),

            // Current password
            _buildField(
              controller: _currentCtrl,
              label: 'Current Password',
              icon: Icons.lock_outline,
              obscureText: _hideCurrent,
              error: _errors['currentPassword'],
              suffixIcon: IconButton(
                icon: Icon(_hideCurrent ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                onPressed: () => setState(() => _hideCurrent = !_hideCurrent),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Current password is required.' : null,
            ),
            const SizedBox(height: 16),

            // New password
            _buildField(
              controller: _newCtrl,
              label: 'New Password',
              icon: Icons.lock_reset,
              obscureText: _hideNew,
              error: _errors['newPassword'],
              suffixIcon: IconButton(
                icon: Icon(_hideNew ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                onPressed: () => setState(() => _hideNew = !_hideNew),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'New password is required.';
                if (v.length < 6) return 'Password must be at least 6 characters.';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirm password
            _buildField(
              controller: _confirmCtrl,
              label: 'Confirm New Password',
              icon: Icons.lock_outline,
              obscureText: _hideConfirm,
              error: _errors['confirmPassword'],
              suffixIcon: IconButton(
                icon: Icon(_hideConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              ),
              validator: (v) => (v == null || v.isEmpty) ? 'Please confirm your new password.' : null,
            ),

            // General error (e.g. server error not related to a specific field)
            if (_errors['general'] != null) ...[
              const SizedBox(height: 10),
              Text(_errors['general']!, style: const TextStyle(color: _errorRed, fontSize: 13)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Password', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
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
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      onChanged: (_) => setState(() => _errors = {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 19, color: _gold),
        suffixIcon: suffixIcon,
        errorText: error,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFE2D9C8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: _gold, width: 1.8),
        ),
      ),
    );
  }
}