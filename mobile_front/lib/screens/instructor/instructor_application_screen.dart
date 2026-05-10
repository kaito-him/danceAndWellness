import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/category_provider.dart';
import '../../services/auth_service.dart';
import '../../models/instructor_application_request.dart';

// ─── Design Tokens (same as StudentRegistrationScreen) ───────────────────────
class _GoldTheme {
  static const gold      = Color(0xFFB89C4D); // matches AppTheme.primaryGold
  static const goldLight = Color(0xFFCDB96A); // matches AppTheme.lightGold
  static const goldPale  = Color(0xFFF5EDD6); // matches AppTheme.paleGold
  static const goldFaint = Color(0xFFEFE6D5); // matches AppTheme.pageBackground
  static const cream     = Color(0xFFEFE6D5);
  static const white     = Color(0xFFFFFFFF);
  static const ink       = Color(0xFF1C1610);
  static const inkLight  = Color(0xFF5C4A2A);
  static const inkFaint  = Color(0xFF9E8A6A);
  static const divider   = Color(0xFFE8D8A0);
  static const errorRed  = Color(0xFFC0392B);

  static const gradientGold = LinearGradient(
    colors: [Color(0xFF8A7535), Color(0xFFB89C4D), Color(0xFF9E8840)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const shadowGold = BoxShadow(
    color: Color(0x30B89C4D),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}

// ─── Main Screen ──────────────────────────────────────────────────────────────
class InstructorApplicationScreen extends StatefulWidget {
  const InstructorApplicationScreen({super.key});

  @override
  State<InstructorApplicationScreen> createState() =>
      _InstructorApplicationScreenState();
}

class _InstructorApplicationScreenState
    extends State<InstructorApplicationScreen> with TickerProviderStateMixin {

  final _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 3;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // ── Form keys ────────────────────────────────────────────────────────────
  final _step0Key = GlobalKey<FormState>();
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();

  // ── Controllers ──────────────────────────────────────────────────────────
  final _usernameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _studioCtrl   = TextEditingController();
  final _bioCtrl      = TextEditingController();
  final _linkedInCtrl = TextEditingController();
  final _websiteCtrl  = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  String? _certFilePath;
  String? _certFileName;
  String? _selectedExperience;
  String? _selectedSpecialization;
  bool _isCheckingAvailability = false;
  bool _isSubmitting = false;
  String? _usernameError;
  String? _emailError;

  static const _experienceOptions = [
    'Less than 1 year',
    '1–3 years',
    '3–5 years',
    '5–10 years',
    '10+ years',
  ];

  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _studioCtrl.dispose();
    _bioCtrl.dispose();
    _linkedInCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  GlobalKey<FormState> get _currentKey {
    switch (_currentStep) {
      case 0:  return _step0Key;
      case 1:  return _step1Key;
      default: return _step2Key;
    }
  }

  Future<void> _goToStep(int step) async {
    await _fadeController.reverse();
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentStep = step);
    await _fadeController.forward();
  }

  Future<void> _nextStep() async {
    if (!_currentKey.currentState!.validate()) return;

    // After step 0 — check username + email availability
    if (_currentStep == 0) {
      setState(() => _isCheckingAvailability = true);
      bool ok = true;
      try {
        if (!await _authService.checkUsernameAvailable(_usernameCtrl.text.trim())) {
          setState(() => _usernameError = 'Username is already taken');
          ok = false;
        } else {
          setState(() => _usernameError = null);
        }
      } catch (_) {}
      try {
        if (!await _authService.checkEmailAvailable(_emailCtrl.text.trim())) {
          setState(() => _emailError = 'Email is already registered');
          ok = false;
        } else {
          setState(() => _emailError = null);
        }
      } catch (_) {}
      setState(() => _isCheckingAvailability = false);
      if (!ok) return;
    }

    if (_currentStep < _totalSteps - 1) await _goToStep(_currentStep + 1);
  }

  Future<void> _prevStep() async {
    if (_currentStep > 0) await _goToStep(_currentStep - 1);
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        final file = result.files.single;
        if (file.size > 5 * 1024 * 1024) {
          _showSnack('File must be under 5 MB', isError: true);
          return;
        }
        setState(() {
          _certFilePath = file.path;
          _certFileName = file.name;
        });
      }
    } catch (e) {
      _showSnack('Failed to pick file: $e', isError: true);
    }
  }

  Future<void> _submit() async {
    if (!_step2Key.currentState!.validate()) return;
    if (_certFilePath == null) {
      _showSnack('Please upload your certification document', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final request = InstructorApplicationRequest(
        username:          _usernameCtrl.text.trim(),
        email:             _emailCtrl.text.trim(),
        password:          _passwordCtrl.text,
        yearsOfExperience: _selectedExperience!,
        specialization:    _selectedSpecialization!,
        studioName:        _studioCtrl.text.trim(),
        bio:               _bioCtrl.text.trim(),
        linkedIn:          _linkedInCtrl.text.trim(),
        website:           _websiteCtrl.text.trim(),
      );
      await _authService.applyAsInstructor(request, _certFilePath!);
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.check_circle, color: Color(0xFFB8860B)),
            SizedBox(width: 10),
            Flexible(child: Text('Application Submitted')),
          ]),
          content: Text(
            'A confirmation was sent to ${_emailCtrl.text.trim()}.\n'
            'Our team reviews applications within 3–5 business days.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB8860B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Return to Login'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      _showSnack(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isWarning = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: _GoldTheme.cream)),
      backgroundColor: isError
          ? _GoldTheme.errorRed
          : isWarning
              ? const Color(0xFFC8960A)
              : _GoldTheme.gold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _GoldTheme.cream,
      body: Column(
        children: [
          _GoldHeader(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            onBack: () {
              if (_currentStep > 0) {
                _prevStep();
              } else {
                context.pop();
              }
            },
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentStep = p),
                children: [
                  _buildStep0(),
                  _buildStep1(),
                  _buildStep2(),
                ],
              ),
            ),
          ),
          _NavigationFooter(
            currentStep: _currentStep,
            totalSteps: _totalSteps,
            isLoading: _isCheckingAvailability || _isSubmitting,
            isLast: _currentStep == _totalSteps - 1,
            onBack: _prevStep,
            onNext: _currentStep == _totalSteps - 1 ? _submit : _nextStep,
          ),
        ],
      ),
    );
  }

  // ── Step 0 — Account ──────────────────────────────────────────────────────
  Widget _buildStep0() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Form(
        key: _step0Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              'Account Information',
              'Create your instructor account credentials.',
            ),
            const SizedBox(height: 24),

            _GoldField(
              controller: _usernameCtrl,
              label: 'Username *',
              icon: Icons.person_outline_rounded,
              onChanged: (_) => setState(() => _usernameError = null),
              extraError: _usernameError,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Username is required';
                if (v.trim().length < 3) return 'At least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _GoldField(
              controller: _emailCtrl,
              label: 'Email Address *',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => setState(() => _emailError = null),
              extraError: _emailError,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v.trim())) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            _GoldField(
              controller: _passwordCtrl,
              label: 'Password *',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _GoldTheme.inkFaint,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) return 'Minimum 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 16),

            _GoldField(
              controller: _confirmCtrl,
              label: 'Confirm Password *',
              icon: Icons.lock_outline_rounded,
              obscureText: _obscureConfirm,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _GoldTheme.inkFaint,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 1 — Credentials ──────────────────────────────────────────────────
  Widget _buildStep1() {
    final categoryProvider = context.watch<CategoryProvider>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              'Your Expertise',
              'Prove your professional background.',
            ),
            const SizedBox(height: 24),

            // Certification upload
            const _FieldLabel('Certification Document *'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _certFilePath != null
                      ? _GoldTheme.goldFaint
                      : _GoldTheme.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _certFilePath != null
                        ? _GoldTheme.gold
                        : _GoldTheme.divider,
                    width: _certFilePath != null ? 2 : 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _certFilePath != null
                            ? _GoldTheme.gradientGold
                            : const LinearGradient(colors: [
                                _GoldTheme.goldFaint,
                                _GoldTheme.goldFaint
                              ]),
                        border: Border.all(
                          color: _certFilePath != null
                              ? Colors.transparent
                              : _GoldTheme.divider,
                        ),
                      ),
                      child: Icon(
                        _certFilePath != null
                            ? Icons.check_rounded
                            : Icons.upload_file_outlined,
                        color: _certFilePath != null
                            ? Colors.white
                            : _GoldTheme.inkFaint,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _certFilePath != null
                                ? 'File selected'
                                : 'Upload PDF / JPG / PNG',
                            style: TextStyle(
                              color: _certFilePath != null
                                  ? _GoldTheme.gold
                                  : _GoldTheme.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _certFileName ?? 'Max 5 MB',
                            style: const TextStyle(
                              color: _GoldTheme.inkFaint,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: _GoldTheme.inkFaint,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Years of experience
            const _FieldLabel('Years of Experience *'),
            const SizedBox(height: 8),
            _GoldDropdown<String>(
              value: _selectedExperience,
              hint: 'Select your experience',
              icon: Icons.work_outline_rounded,
              items: _experienceOptions
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedExperience = v),
              validator: (v) =>
                  v == null ? 'Please select your experience' : null,
            ),
            const SizedBox(height: 20),

            // Specialization from categories
            const _FieldLabel('Specialization *'),
            const SizedBox(height: 8),
            if (categoryProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_GoldTheme.gold),
                  ),
                ),
              )
            else if (categoryProvider.errorMessage != null)
              _ErrorRetry(
                  onRetry: () => categoryProvider.fetchCategories())
            else
              _GoldDropdown<String>(
                value: _selectedSpecialization,
                hint: 'Select a specialization',
                icon: Icons.star_outline_rounded,
                items: categoryProvider.categories
                    .map((c) => DropdownMenuItem(
                          value: c.name,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedSpecialization = v),
                validator: (v) =>
                    v == null ? 'Please select a specialization' : null,
              ),
            const SizedBox(height: 20),

            // Studio Name — optional
            const _FieldLabel('Studio Name', required: false),
            const SizedBox(height: 8),
            _GoldField(
              controller: _studioCtrl,
              label: 'Studio or gym name (optional)',
              icon: Icons.business_outlined,
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 2 — Profile ──────────────────────────────────────────────────────
  Widget _buildStep2() {
    final bioLen = _bioCtrl.text.trim().length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              'Your Story',
              'Tell students about yourself.',
            ),
            const SizedBox(height: 24),

            // Bio
            const _FieldLabel('Professional Bio *'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 5,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: _GoldTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText:
                    'Share your background, teaching style, achievements…',
                hintStyle: const TextStyle(
                    color: _GoldTheme.inkFaint, fontSize: 14),
                filled: true,
                fillColor: _GoldTheme.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: _GoldTheme.divider, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: _GoldTheme.divider, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: _GoldTheme.gold, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: _GoldTheme.errorRed, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                      color: _GoldTheme.errorRed, width: 2),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Bio is required';
                if (v.trim().length < 10) {
                  return '${10 - v.trim().length} more characters needed';
                }
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '$bioLen chars',
                  style: TextStyle(
                    fontSize: 11,
                    color: bioLen >= 10
                        ? _GoldTheme.gold
                        : _GoldTheme.inkFaint,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // LinkedIn — optional
            const _FieldLabel('LinkedIn URL', required: false),
            const SizedBox(height: 8),
            _GoldField(
              controller: _linkedInCtrl,
              label: 'https://linkedin.com/in/… (optional)',
              icon: Icons.link_rounded,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),

            // Website — optional
            const _FieldLabel('Website URL', required: false),
            const SizedBox(height: 8),
            _GoldField(
              controller: _websiteCtrl,
              label: 'https://yourwebsite.com (optional)',
              icon: Icons.language_rounded,
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Gold Header ──────────────────────────────────────────────────────────────
class _GoldHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;

  const _GoldHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
  });

  static const _stepLabels = ['Account', 'Credentials', 'Profile'];
  static const _stepIcons = [
    Icons.person_outline_rounded,
    Icons.workspace_premium_outlined,
    Icons.auto_awesome_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _GoldTheme.gradientGold),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            children: [
              Row(
                children: [
                  _GoldIconButton(
                      icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                  const Spacer(),
                  const Text(
                    'Instructor Application',
                    style: TextStyle(
                      color: _GoldTheme.cream,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 28),

              // Step indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalSteps * 2 - 1, (i) {
                  if (i.isOdd) {
                    final isCompleted = (i ~/ 2) < currentStep;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                        height: 2,
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? _GoldTheme.cream
                              : _GoldTheme.cream.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }
                  final step = i ~/ 2;
                  final isActive = step == currentStep;
                  final isCompleted = step < currentStep;

                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                        width: isActive ? 52 : 44,
                        height: isActive ? 52 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? _GoldTheme.cream
                              : isActive
                                  ? _GoldTheme.white
                                  : _GoldTheme.cream.withOpacity(0.2),
                          border: Border.all(
                            color: _GoldTheme.cream,
                            width: isActive ? 2.5 : 1.5,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: Icon(
                          isCompleted ? Icons.check_rounded : _stepIcons[step],
                          size: isActive ? 26 : 20,
                          color: isCompleted
                              ? _GoldTheme.gold
                              : isActive
                                  ? _GoldTheme.gold
                                  : _GoldTheme.cream.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          color: isActive || isCompleted
                              ? _GoldTheme.cream
                              : _GoldTheme.cream.withOpacity(0.5),
                          fontSize: isActive ? 12 : 11,
                          fontWeight:
                              isActive ? FontWeight.w700 : FontWeight.w400,
                          letterSpacing: 0.5,
                        ),
                        child: Text(_stepLabels[step]),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoldIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GoldIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.15),
        ),
        child: Icon(icon, color: _GoldTheme.cream, size: 18),
      ),
    );
  }
}

// ─── Navigation Footer ────────────────────────────────────────────────────────
class _NavigationFooter extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isLoading;
  final bool isLast;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _NavigationFooter({
    required this.currentStep,
    required this.totalSteps,
    required this.isLoading,
    required this.isLast,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: _GoldTheme.white,
        border: Border(top: BorderSide(color: _GoldTheme.divider, width: 1)),
        boxShadow: [
          BoxShadow(
            color: _GoldTheme.ink.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: currentStep > 0 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: AnimatedSlide(
              offset: currentStep > 0 ? Offset.zero : const Offset(-0.3, 0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: GestureDetector(
                onTap: currentStep > 0 ? onBack : null,
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _GoldTheme.divider, width: 1.5),
                    color: _GoldTheme.white,
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: _GoldTheme.gold),
                ),
              ),
            ),
          ),
          if (currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: isLoading ? null : onNext,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutCubic,
                height: 56,
                decoration: BoxDecoration(
                  gradient: isLoading
                      ? const LinearGradient(
                          colors: [Color(0xFFCCB466), Color(0xFFCCB466)])
                      : _GoldTheme.gradientGold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isLoading ? [] : [_GoldTheme.shadowGold],
                ),
                child: Center(
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Submit Application' : 'Continue',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isLast
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.arrow_forward_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Title ────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionTitle(this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _GoldTheme.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: _GoldTheme.inkFaint,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            gradient: _GoldTheme.gradientGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

// ─── Field Label ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  final bool required;
  const _FieldLabel(this.text, {this.required = true});

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _GoldTheme.inkLight,
        ),
        children: [
          if (required)
            const TextSpan(
              text: '* ',
              style: TextStyle(color: _GoldTheme.errorRed),
            ),
          TextSpan(text: text),
          if (!required)
            const TextSpan(
              text: '  (optional)',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w400,
                color: _GoldTheme.inkFaint,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Gold Input Field ─────────────────────────────────────────────────────────
class _GoldField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final String? extraError;

  const _GoldField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.extraError,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(
            color: _GoldTheme.ink,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                const TextStyle(color: _GoldTheme.inkFaint, fontSize: 14),
            floatingLabelStyle: const TextStyle(
              color: _GoldTheme.gold,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: _GoldTheme.inkFaint, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _GoldTheme.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _GoldTheme.divider, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _GoldTheme.divider, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _GoldTheme.gold, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _GoldTheme.errorRed, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: _GoldTheme.errorRed, width: 2),
            ),
            errorStyle:
                const TextStyle(color: _GoldTheme.errorRed, fontSize: 12),
          ),
        ),
        if (extraError != null) ...[
          const SizedBox(height: 4),
          Text(
            extraError!,
            style: const TextStyle(
              color: _GoldTheme.errorRed,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Gold Dropdown ────────────────────────────────────────────────────────────
class _GoldDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;

  const _GoldDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      hint: Text(hint, style: const TextStyle(color: _GoldTheme.inkFaint)),
      items: items,
      onChanged: onChanged,
      validator: validator,
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          color: _GoldTheme.inkFaint),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: _GoldTheme.inkFaint, size: 20),
        filled: true,
        fillColor: _GoldTheme.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _GoldTheme.divider, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _GoldTheme.divider, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _GoldTheme.gold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: _GoldTheme.errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _GoldTheme.errorRed, width: 2),
        ),
      ),
      style: const TextStyle(
        color: _GoldTheme.ink,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      dropdownColor: _GoldTheme.white,
    );
  }
}

// ─── Error / Retry ────────────────────────────────────────────────────────────
class _ErrorRetry extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorRetry({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _GoldTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _GoldTheme.divider),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_rounded,
              color: _GoldTheme.inkFaint, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Failed to load categories',
            style: TextStyle(
                color: _GoldTheme.inkLight, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: _GoldTheme.gradientGold,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [_GoldTheme.shadowGold],
              ),
              child: const Text('Retry',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
