import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/category_provider.dart';
import '../../models/student_registration_request.dart';
import '../../models/skill_level.dart';
import '../../services/auth_service.dart';

// ─── Design Tokens (shared with InstructorApplicationScreen) ──────────────────
class _GoldTheme {
  static const gold      = Color(0xFFB89C4D); // matches AppTheme.primaryGold
  static const goldLight = Color(0xFFCDB96A); // matches AppTheme.lightGold
  static const goldPale  = Color(0xFFF5EDD6); // matches AppTheme.paleGold
  static const goldFaint = Color(0xFFEFE6D5); // matches AppTheme.pageBackground
  static const cream = Color(0xFFEFE6D5);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1C1610);
  static const inkLight = Color(0xFF5C4A2A);
  static const inkFaint = Color(0xFF9E8A6A);
  static const divider = Color(0xFFE8D8A0);
  static const errorRed = Color(0xFFC0392B);

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
class StudentRegistrationScreen extends StatefulWidget {
  const StudentRegistrationScreen({super.key});

  @override
  State<StudentRegistrationScreen> createState() =>
      _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 2;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  // Step 1
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 2
  final Set<String> _selectedCategoryIds = {};
  SkillLevel _selectedSkillLevel = SkillLevel.beginner;

  // Availability check state
  bool _isCheckingAvailability = false;
  String? _usernameError;
  String? _emailError;

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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    await _fadeController.reverse();
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
    setState(() => _currentPage = page);
    await _fadeController.forward();
  }

  Future<void> _nextPage() async {
    if (_currentPage == 0) {
      if (!_formKey.currentState!.validate()) return;

      // Check username + email availability before moving to step 2
      setState(() => _isCheckingAvailability = true);
      bool ok = true;

      try {
        if (!await _authService.checkUsernameAvailable(
            _usernameController.text.trim())) {
          setState(() => _usernameError = 'Username is already taken');
          ok = false;
        } else {
          setState(() => _usernameError = null);
        }
      } catch (_) {}

      try {
        if (!await _authService
            .checkEmailAvailable(_emailController.text.trim())) {
          setState(() => _emailError = 'Email is already registered');
          ok = false;
        } else {
          setState(() => _emailError = null);
        }
      } catch (_) {}

      setState(() => _isCheckingAvailability = false);
      if (!ok) return;
    }
    if (_currentPage < _totalPages - 1) await _goToPage(_currentPage + 1);
  }

  Future<void> _prevPage() async {
    if (_currentPage > 0) await _goToPage(_currentPage - 1);
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

  Future<void> _handleRegistration() async {
    if (_selectedCategoryIds.length < 3) {
      _showSnack('Please select at least 3 categories', isWarning: true);
      return;
    }

    final authProvider = context.read<AuthProvider>();
    try {
      final request = StudentRegistrationRequest(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        categoryIds: _selectedCategoryIds.toList(),
        skillLevel: _selectedSkillLevel.value,
      );
      await authProvider.registerStudent(request);
      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Row(children: [
            Icon(Icons.check_circle, color: _GoldTheme.gold),
            SizedBox(width: 10),
            Flexible(child: Text('Account Created!')),
          ]),
          content: Text(
            'Welcome, ${_usernameController.text.trim()}!\n\n'
            'Your student account has been created successfully. '
            'You can now sign in and start exploring.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _GoldTheme.gold,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );

      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      _showSnack('Registration failed: ${e.toString()}', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _GoldTheme.cream,
      body: Column(
        children: [
          _GoldHeader(
            currentStep: _currentPage,
            totalSteps: _totalPages,
            onBack: () {
              if (_currentPage > 0) {
                _prevPage();
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
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _BasicInfoPage(
                    formKey: _formKey,
                    usernameController: _usernameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    obscurePassword: _obscurePassword,
                    obscureConfirmPassword: _obscureConfirmPassword,
                    onTogglePassword: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    onToggleConfirm: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                    usernameError: _usernameError,
                    emailError: _emailError,
                    onUsernameChanged: () =>
                        setState(() => _usernameError = null),
                    onEmailChanged: () => setState(() => _emailError = null),
                  ),
                  _OnboardingPage(
                    selectedCategoryIds: _selectedCategoryIds,
                    selectedSkillLevel: _selectedSkillLevel,
                    onCategoryToggle: (id, selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategoryIds.add(id);
                        } else {
                          _selectedCategoryIds.remove(id);
                        }
                      });
                    },
                    onSkillLevelChanged: (level) {
                      if (level != null) {
                        setState(() => _selectedSkillLevel = level);
                      }
                    },
                    onRetry: () =>
                        context.read<CategoryProvider>().fetchCategories(),
                  ),
                ],
              ),
            ),
          ),
          _NavigationFooter(
            currentStep: _currentPage,
            totalSteps: _totalPages,
            isLoading: authProvider.isLoading || _isCheckingAvailability,
            isLast: _currentPage == _totalPages - 1,
            onBack: _prevPage,
            onNext:
                _currentPage == _totalPages - 1 ? _handleRegistration : _nextPage,
          ),
        ],
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

  static const _stepLabels = ['Account', 'Interests'];
  static const _stepIcons = [
    Icons.person_outline_rounded,
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
              // AppBar row
              Row(
                children: [
                  _GoldIconButton(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                  const Spacer(),
                  const Text(
                    'Student Registration',
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

// ─── Step 1: Basic Info ───────────────────────────────────────────────────────
class _BasicInfoPage extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final String? usernameError;
  final String? emailError;
  final VoidCallback? onUsernameChanged;
  final VoidCallback? onEmailChanged;

  const _BasicInfoPage({
    required this.formKey,
    required this.usernameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    this.usernameError,
    this.emailError,
    this.onUsernameChanged,
    this.onEmailChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              'Basic Information',
              'Create your student account to get started.',
            ),
            const SizedBox(height: 24),
            _GoldField(
              controller: usernameController,
              label: 'Username',
              icon: Icons.person_outline_rounded,
              onChanged: (_) => onUsernameChanged?.call(),
              extraError: usernameError,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a username';
                if (v.length < 3) return 'At least 3 characters required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _GoldField(
              controller: emailController,
              label: 'Email Address',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              onChanged: (_) => onEmailChanged?.call(),
              extraError: emailError,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter your email';
                if (!v.contains('@')) return 'Enter a valid email address';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _GoldField(
              controller: passwordController,
              label: 'Password',
              icon: Icons.lock_outline_rounded,
              obscureText: obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _GoldTheme.inkFaint,
                ),
                onPressed: onTogglePassword,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please enter a password';
                if (v.length < 6) return 'At least 6 characters required';
                return null;
              },
            ),
            const SizedBox(height: 16),
            _GoldField(
              controller: confirmPasswordController,
              label: 'Confirm Password',
              icon: Icons.lock_outline_rounded,
              obscureText: obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: _GoldTheme.inkFaint,
                ),
                onPressed: onToggleConfirm,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != passwordController.text) return 'Passwords do not match';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Onboarding ───────────────────────────────────────────────────────
class _OnboardingPage extends StatelessWidget {
  final Set<String> selectedCategoryIds;
  final SkillLevel selectedSkillLevel;
  final void Function(String id, bool selected) onCategoryToggle;
  final ValueChanged<SkillLevel?> onSkillLevelChanged;
  final VoidCallback onRetry;

  const _OnboardingPage({
    required this.selectedCategoryIds,
    required this.selectedSkillLevel,
    required this.onCategoryToggle,
    required this.onSkillLevelChanged,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final categoryProvider = context.watch<CategoryProvider>();
    final selectionCount = selectedCategoryIds.length;
    final progress = (selectionCount / 3).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            'Choose Your Interests',
            'Select at least 3 categories you\'d like to explore.',
          ),
          const SizedBox(height: 20),

          // Selection progress bar
          _SelectionProgress(
            count: selectionCount,
            required: 3,
            progress: progress,
          ),
          const SizedBox(height: 24),

          // Categories
          if (categoryProvider.isLoading)
            _LoadingCategories()
          else if (categoryProvider.errorMessage != null)
            _ErrorRetry(onRetry: onRetry)
          else
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: categoryProvider.categories.map((category) {
                final isSelected = selectedCategoryIds.contains(category.id);
                return _GoldChip(
                  label: category.name,
                  isSelected: isSelected,
                  onTap: () => onCategoryToggle(category.id, !isSelected),
                );
              }).toList(),
            ),

          const SizedBox(height: 32),

          // Skill Level
          const _SectionTitle(
            'Skill Level',
            'How would you describe your current experience?',
          ),
          const SizedBox(height: 16),
          _SkillLevelSelector(
            selected: selectedSkillLevel,
            onChanged: onSkillLevelChanged,
          ),
        ],
      ),
    );
  }
}

// ─── Selection progress bar ───────────────────────────────────────────────────
class _SelectionProgress extends StatelessWidget {
  final int count;
  final int required;
  final double progress;

  const _SelectionProgress({
    required this.count,
    required this.required,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = count >= required;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? _GoldTheme.goldFaint : _GoldTheme.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone ? _GoldTheme.gold : _GoldTheme.divider,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isDone ? 'Great selection!' : '$count of $required selected',
                style: TextStyle(
                  color: isDone ? _GoldTheme.gold : _GoldTheme.inkLight,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isDone
                    ? const Icon(Icons.check_circle_rounded,
                        color: _GoldTheme.gold, size: 18, key: ValueKey('done'))
                    : Text(
                        '${required - count} more to go',
                        key: const ValueKey('more'),
                        style: const TextStyle(
                          color: _GoldTheme.inkFaint,
                          fontSize: 12,
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: _GoldTheme.divider,
                valueColor: const AlwaysStoppedAnimation(_GoldTheme.gold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Gold Chip ────────────────────────────────────────────────────────────────
class _GoldChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoldChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _GoldTheme.gold : _GoldTheme.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? _GoldTheme.gold : _GoldTheme.divider,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected ? [_GoldTheme.shadowGold] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : _GoldTheme.inkLight,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skill Level Selector ─────────────────────────────────────────────────────
class _SkillLevelSelector extends StatelessWidget {
  final SkillLevel selected;
  final ValueChanged<SkillLevel?> onChanged;

  const _SkillLevelSelector({required this.selected, required this.onChanged});

  static const _levels = [
    (SkillLevel.beginner, Icons.emoji_nature_outlined, 'Beginner',
        'Just starting out'),
    (SkillLevel.intermediate, Icons.trending_up_rounded, 'Intermediate',
        'Some experience'),
    (SkillLevel.advanced, Icons.workspace_premium_outlined, 'Advanced',
        'Highly experienced'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _levels.map((entry) {
        final (level, icon, title, subtitle) = entry;
        final isSelected = selected == level;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: () => onChanged(level),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOutCubic,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? _GoldTheme.goldFaint : _GoldTheme.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? _GoldTheme.gold : _GoldTheme.divider,
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: isSelected ? [_GoldTheme.shadowGold] : [],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isSelected
                          ? _GoldTheme.gradientGold
                          : const LinearGradient(
                              colors: [_GoldTheme.goldFaint, _GoldTheme.goldFaint]),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : _GoldTheme.divider,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color:
                          isSelected ? Colors.white : _GoldTheme.inkFaint,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: isSelected
                                ? _GoldTheme.gold
                                : _GoldTheme.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: _GoldTheme.inkFaint,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: isSelected ? 1 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.radio_button_checked_rounded,
                        color: _GoldTheme.gold, size: 22),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Loading Placeholder ──────────────────────────────────────────────────────
class _LoadingCategories extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 10,
      children: List.generate(
        8,
        (i) => _ShimmerChip(width: 60.0 + (i % 3) * 30),
      ),
    );
  }
}

class _ShimmerChip extends StatefulWidget {
  final double width;
  const _ShimmerChip({required this.width});

  @override
  State<_ShimmerChip> createState() => _ShimmerChipState();
}

class _ShimmerChipState extends State<_ShimmerChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: 38,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          color: Color.lerp(
            _GoldTheme.goldFaint,
            _GoldTheme.goldPale,
            _anim.value,
          ),
        ),
      ),
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
          const Icon(Icons.cloud_off_rounded, color: _GoldTheme.inkFaint, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Failed to load categories',
            style: TextStyle(color: _GoldTheme.inkLight, fontWeight: FontWeight.w600),
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
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isLast ? 'Create Account' : 'Continue',
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

// ─── Reusable: Section Title ──────────────────────────────────────────────────
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

// ─── Reusable: Gold Input Field ───────────────────────────────────────────────
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
        labelStyle: const TextStyle(color: _GoldTheme.inkFaint, fontSize: 14),
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
          borderSide: const BorderSide(color: _GoldTheme.errorRed, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _GoldTheme.errorRed, width: 2),
        ),
        errorStyle: const TextStyle(color: _GoldTheme.errorRed, fontSize: 12),
      ),
    ),
    if (extraError != null) ...[
      const SizedBox(height: 4),
      Text(
        extraError!,
        style: const TextStyle(color: _GoldTheme.errorRed, fontSize: 12),
      ),
    ],
  ],
 );
  }
}