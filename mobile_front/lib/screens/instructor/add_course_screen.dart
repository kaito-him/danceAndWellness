import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../models/category.dart';
import '../../models/instructor_profile.dart';
import '../../providers/auth_provider.dart';
import '../../services/category_service.dart';
import '../../services/instructor_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_navbar.dart';

const _difficultyLevels = ['BEGINNER', 'INTERMEDIATE', 'ADVANCED'];
const _priceTiers = ['10', '20', '30'];

int _idCounter = 0;
String _uniqueId() => '${DateTime.now().millisecondsSinceEpoch}-${_idCounter++}';

class AddCourseScreen extends StatefulWidget {
  const AddCourseScreen({super.key});

  @override
  State<AddCourseScreen> createState() => _AddCourseScreenState();
}

class _AddCourseScreenState extends State<AddCourseScreen> {
  final _service = InstructorDashboardService();
  final _categoryService = CategoryService();
  final _formKey = GlobalKey<FormState>();

  // ── Form state ──────────────────────────────────────────────────
  String _title = '';
  String _description = '';
  String _level = 'BEGINNER';
  String _categoryId = '';
  bool _isFree = true;
  String _priceType = 'predefined'; // predefined | custom
  String _price = '10';

  // Thumbnail
  File? _thumbnailFile;

  // Lessons
  late List<_LessonEntry> _lessons;

  // Quizzes
  late List<_QuizEntry> _quizzes;

  // ── Remote data ─────────────────────────────────────────────────
  List<Category> _categories = [];
  bool _catsLoading = true;
  Map<String, dynamic>? _stripeStatus;
  bool _stripeLoading = false;
  InstructorProfile? _profile;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _lessons = [_LessonEntry()];
    _quizzes = [];
    _loadRemoteData();
  }

  @override
  void dispose() {
    for (final l in _lessons) {
      l.videoController?.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRemoteData() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    // Load categories
    _categoryService.getCategories().then((cats) {
      if (!mounted) return;
      setState(() {
        _categories = cats;
        _catsLoading = false;
        if (cats.isNotEmpty) {
          final spec = _profile?.specialization;
          final matched = spec != null
              ? cats
                  .where(
                      (c) => c.name.toLowerCase() == spec.toLowerCase())
                  .firstOrNull
              : null;
          _categoryId = matched?.id ?? cats.first.id;
        }
      });
    }).catchError((_) {
      if (mounted) setState(() => _catsLoading = false);
    });

    // Load instructor profile
    _service.getProfileByUserId(userId).then((p) {
      if (!mounted) return;
      setState(() {
        _profile = p;
        // Re-match category after profile loads
        if (_categories.isNotEmpty) {
          final spec = p.specialization;
          final matched = spec != null
              ? _categories
                  .where(
                      (c) => c.name.toLowerCase() == spec.toLowerCase())
                  .firstOrNull
              : null;
          if (matched != null) _categoryId = matched.id;
        }
      });
      // Fetch stripe status with instructor id
      setState(() => _stripeLoading = true);
      _service.getStripeStatus(p.id).then((status) {
        if (mounted) {
          setState(() {
            _stripeStatus = status;
            _stripeLoading = false;
          });
        }
      });
    }).catchError((_) {});
  }

  bool get _stripeBlocked =>
      !_isFree && _stripeStatus != null && _stripeStatus!['chargesEnabled'] != true;

  bool get _stripeConnected =>
      _stripeStatus != null && _stripeStatus!['chargesEnabled'] == true;

  bool get _showCategoryDropdown {
    if (_profile?.specialization == null) return true;
    return !_categories.any(
        (c) => c.name.toLowerCase() == _profile!.specialization!.toLowerCase());
  }

  // ── Thumbnail ───────────────────────────────────────────────────
  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _thumbnailFile = File(picked.path));
    }
  }

  // ── Video ───────────────────────────────────────────────────────
  Future<void> _pickVideo(int idx) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null && mounted) {
      final file = File(result.files.single.path!);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      final durationMin =
          (controller.value.duration.inSeconds / 60).round().clamp(1, 9999);
      setState(() {
        _lessons[idx].videoFile = file;
        _lessons[idx].videoController?.dispose();
        _lessons[idx].videoController = controller;
        _lessons[idx].duration = durationMin.toString();
      });
    }
  }

  // ── Lessons ─────────────────────────────────────────────────────
  void _addLesson() => setState(() => _lessons.add(_LessonEntry()));

  void _removeLesson(int idx) {
    if (_lessons.length <= 1) return;
    setState(() {
      _lessons[idx].videoController?.dispose();
      _lessons.removeAt(idx);
    });
  }

  // ── Quizzes ─────────────────────────────────────────────────────
  void _addQuiz() => setState(() => _quizzes.add(_QuizEntry()));

  void _removeQuiz(int idx) => setState(() => _quizzes.removeAt(idx));

  void _addQuestion(int qIdx) =>
      setState(() => _quizzes[qIdx].questions.add(_QuestionEntry()));

  void _removeQuestion(int qIdx, int qstIdx) {
    if (_quizzes[qIdx].questions.length <= 1) return;
    setState(() => _quizzes[qIdx].questions.removeAt(qstIdx));
  }

  void _addOption(int qIdx, int qstIdx) =>
      setState(() => _quizzes[qIdx].questions[qstIdx].options
          .add(_OptionEntry()));

  void _removeOption(int qIdx, int qstIdx, int optIdx) {
    if (_quizzes[qIdx].questions[qstIdx].options.length <= 2) return;
    setState(
        () => _quizzes[qIdx].questions[qstIdx].options.removeAt(optIdx));
  }

  // ── Submit ──────────────────────────────────────────────────────
  Future<void> _handleSubmit(String mode) async {
    final isDraft = mode == 'draft';

    if (isDraft) {
      if (_title.trim().isEmpty) {
        _showMsg('Please provide at least a course title to save a draft.');
        return;
      }
    }

    if (!isDraft) {
      if (_title.trim().isEmpty) {
        _showMsg('Course title is required to publish.');
        return;
      }
      if (_lessons.isEmpty) {
        _showMsg('Add at least one lesson before submitting.');
        return;
      }
      final missingVideo =
          _lessons.indexWhere((l) => l.videoFile == null);
      if (missingVideo != -1) {
        _showMsg(
            'Please upload a video for Lesson ${missingVideo + 1}.');
        return;
      }
      if (_stripeBlocked) {
        _showMsg(
            'Connect your Stripe account before publishing a paid course.');
        return;
      }
      if (!_isFree && _priceType == 'custom') {
        final p = double.tryParse(_price);
        if (p == null || p < 10 || p > 100) {
          _showMsg('Custom price must be between \$10 and \$100.');
          return;
        }
      }
      // Quiz validation
      for (int i = 0; i < _quizzes.length; i++) {
        final q = _quizzes[i];
        for (int j = 0; j < q.questions.length; j++) {
          final qst = q.questions[j];
          if (qst.options.length < 2) {
            _showMsg(
                'Quiz ${i + 1}, Question ${j + 1} must have at least 2 options.');
            return;
          }
          if (!qst.options.any((o) => o.isCorrect)) {
            _showMsg(
                'Quiz ${i + 1}, Question ${j + 1} must have at least one correct option.');
            return;
          }
        }
      }
    }

    setState(() => _loading = true);
    try {
      // Upload thumbnail
      String thumbnailUrl = '';
      if (_thumbnailFile != null) {
        thumbnailUrl = await _service.uploadFile(
          _thumbnailFile!.path,
          _thumbnailFile!.path.split('/').last,
        );
      }

      // Upload lesson videos sequentially
      final lessonPayloads = <Map<String, dynamic>>[];
      for (int i = 0; i < _lessons.length; i++) {
        final l = _lessons[i];
        String? mediaUrl;
        if (l.videoFile != null) {
          mediaUrl = await _service.uploadFile(
            l.videoFile!.path,
            l.videoFile!.path.split('/').last,
          );
        }
        lessonPayloads.add({
          'lessonId': l.id,
          'title': l.title,
          'duration': int.tryParse(l.duration) ?? 0,
          'mediaUrl': mediaUrl,
          'order': i,
        });
      }

      final payload = {
        'title': _title,
        'description': _description,
        'isFree': _isFree,
        'price': _isFree ? 0 : (double.tryParse(_price) ?? 0),
        'level': _level,
        'categoryId': _categoryId,
        'thumbnailUrl': thumbnailUrl,
        'lessons': lessonPayloads,
        'quizzes': _quizzes
            .map((q) => {
                  'title': q.title,
                  'questions': q.questions
                      .map((qst) => {
                            'text': qst.text,
                            'options': qst.options
                                .map((o) => {
                                      'text': o.text,
                                      'isCorrect': o.isCorrect,
                                    })
                                .toList(),
                          })
                      .toList(),
                })
            .toList(),
      };

      if (isDraft) {
        await _service.saveDraft(payload);
        if (mounted) {
          _showMsg('Draft saved.', isError: false);
          Navigator.of(context).pop(true);
        }
      } else {
        await _service.publishCourse(payload);
        if (mounted) {
          _showMsg('Course published successfully!', isError: false);
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _showMsg(isDraft ? 'Failed to save draft: $msg' : 'Failed to submit course: $msg');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMsg(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.errorGold : AppTheme.successGold,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: const AppNavbar(title: 'Create New Course'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Fill in the details below — your course will be published immediately.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            _buildSection(1, 'Course Details', _buildCourseDetailsSection()),
            const SizedBox(height: 16),
            _buildSection(2, 'Thumbnail', _buildThumbnailSection()),
            const SizedBox(height: 16),
            _buildSection(3, 'Pricing', _buildPricingSection()),
            const SizedBox(height: 16),
            _buildSection(4, 'Lessons', _buildLessonsSection()),
            const SizedBox(height: 16),
            _buildSection(5, 'Quizzes (Optional)', _buildQuizzesSection()),
            const SizedBox(height: 24),
            _buildFooter(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(int step, String title, Widget child) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.paleGold),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGold.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text('$step',
                      style: const TextStyle(
                          color: AppTheme.pureWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ],
      ),
    );
  }

  // ── Section 1: Course Details ──────────────────────────────────
  Widget _buildCourseDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Course Title', required: true),
        const SizedBox(height: 6),
        TextFormField(
          decoration: const InputDecoration(
            hintText: 'e.g. Beginner Contemporary Dance',
          ),
          onChanged: (v) => _title = v,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Description', optional: true),
        const SizedBox(height: 6),
        TextFormField(
          decoration: const InputDecoration(
            hintText:
                'Describe what students will learn, who this course is for, and what makes it special...',
          ),
          maxLines: 4,
          onChanged: (v) => _description = v,
        ),
        const SizedBox(height: 16),
        _fieldLabel('Difficulty Level', required: true),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _level,
          decoration: const InputDecoration(),
          items: _difficultyLevels
              .map((l) => DropdownMenuItem(
                    value: l,
                    child: Text(
                        l[0] + l.substring(1).toLowerCase()),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _level = v);
          },
        ),
        if (_showCategoryDropdown) ...[
          const SizedBox(height: 16),
          _fieldLabel('Category', required: true),
          const SizedBox(height: 6),
          if (_catsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Loading categories...',
                  style: TextStyle(color: AppTheme.textSecondary)),
            )
          else
            DropdownButtonFormField<String>(
              value: _categoryId.isNotEmpty ? _categoryId : null,
              decoration: const InputDecoration(),
              items: _categories.isEmpty
                  ? [
                      const DropdownMenuItem(
                          value: '', child: Text('No categories found'))
                    ]
                  : _categories
                      .map((c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ))
                      .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _categoryId = v);
              },
            ),
        ],
      ],
    );
  }

  // ── Section 2: Thumbnail ───────────────────────────────────────
  Widget _buildThumbnailSection() {
    if (_thumbnailFile != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(_thumbnailFile!,
                height: 180, width: double.infinity, fit: BoxFit.cover),
          ),
          const SizedBox(height: 8),
          Text(_thumbnailFile!.path.split('/').last,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickThumbnail,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Change'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _thumbnailFile = null),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: const Text('Remove'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.errorGold,
                    side: const BorderSide(color: AppTheme.errorGold),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }
    return InkWell(
      onTap: _pickThumbnail,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppTheme.mediumGray, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(10),
          color: AppTheme.lightGray,
        ),
        child: Column(
          children: [
            Icon(Icons.image_outlined,
                size: 36, color: AppTheme.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                      text: 'Tap to upload',
                      style: TextStyle(
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('PNG, JPG, WEBP — recommended 1280x720',
                style: TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Section 3: Pricing ─────────────────────────────────────────
  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Free / Paid toggle
        Row(
          children: [
            Expanded(
              child: _pricingTab(
                icon: Icons.star_outline,
                label: 'Free',
                active: _isFree,
                onTap: () => setState(() => _isFree = true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _pricingTab(
                icon: Icons.attach_money,
                label: 'Paid',
                active: !_isFree,
                enabled: _stripeConnected,
                onTap: _stripeConnected
                    ? () => setState(() => _isFree = false)
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Stripe info banner
        _buildStripeInfoBanner(),
        // Price details (only when Paid)
        if (!_isFree) ...[
          const SizedBox(height: 14),
          // Price type selector
          Row(
            children: [
              Expanded(
                child: _priceTypeBtn('Tiers', 'predefined'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _priceTypeBtn('Custom', 'custom'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_priceType == 'predefined') ...[
            _fieldLabel('Select Price Tier', required: true),
            const SizedBox(height: 8),
            Row(
              children: _priceTiers.map((tier) {
                final selected = _price == tier;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                        right: tier != _priceTiers.last ? 10 : 0),
                    child: InkWell(
                      onTap: () => setState(() => _price = tier),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppTheme.primaryGold
                              : AppTheme.lightGray,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: selected
                                  ? AppTheme.primaryGold
                                  : AppTheme.mediumGray),
                        ),
                        alignment: Alignment.center,
                        child: Text('\$$tier',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: selected
                                    ? AppTheme.pureWhite
                                    : AppTheme.textPrimary)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            _fieldLabel('Custom Price (\$)', required: true),
            const SizedBox(height: 6),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'e.g. 45',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.number,
              initialValue: _price,
              onChanged: (v) => _price = v,
            ),
            const SizedBox(height: 4),
            const Text('Range: \$10 – \$100',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ],
          const SizedBox(height: 10),
          const Text('You keep 80% · Platform retains 20%',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        ],
      ],
    );
  }

  Widget _pricingTab({
    required IconData icon,
    required String label,
    required bool active,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? AppTheme.primaryGold : AppTheme.lightGray,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppTheme.primaryGold : AppTheme.mediumGray),
        ),
        child: Opacity(
          opacity: enabled ? 1.0 : 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color:
                      active ? AppTheme.pureWhite : AppTheme.textPrimary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: active
                          ? AppTheme.pureWhite
                          : AppTheme.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceTypeBtn(String label, String type) {
    final active = _priceType == type;
    return InkWell(
      onTap: () {
        setState(() {
          _priceType = type;
          if (type == 'predefined' && !_priceTiers.contains(_price)) {
            _price = _priceTiers.first;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryGold.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active ? AppTheme.primaryGold : AppTheme.mediumGray),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: active ? AppTheme.primaryGold : AppTheme.textSecondary)),
      ),
    );
  }

  Widget _buildStripeInfoBanner() {
    if (_stripeLoading) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primaryGold)),
            SizedBox(width: 10),
            Text('Checking account status...',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ],
        ),
      );
    }

    if (_isFree) return const SizedBox.shrink();

    if (_stripeStatus == null || _stripeStatus!['hasAccount'] != true) {
      return _infoBanner(
        'Connect Stripe to create paid courses. Go to Payments > Connect Stripe.',
        isWarning: true,
      );
    }

    if (_stripeStatus!['chargesEnabled'] != true) {
      return _infoBanner(
        'Finish your Stripe onboarding to enable paid courses.',
        isWarning: true,
      );
    }

    return _infoBanner(
      'Stripe is active — ready to publish paid courses.',
      isWarning: false,
    );
  }

  Widget _infoBanner(String text, {required bool isWarning}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning
            ? AppTheme.errorGold.withValues(alpha: 0.1)
            : AppTheme.successGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWarning
              ? AppTheme.errorGold.withValues(alpha: 0.3)
              : AppTheme.successGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            size: 18,
            color: isWarning ? AppTheme.errorGold : AppTheme.successGold,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13,
                    color: isWarning
                        ? AppTheme.errorGold
                        : AppTheme.successGold)),
          ),
        ],
      ),
    );
  }

  // ── Section 4: Lessons ─────────────────────────────────────────
  Widget _buildLessonsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.paleGold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${_lessons.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_lessons.length, (idx) => _buildLessonCard(idx)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addLesson,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add another lesson'),
          ),
        ),
      ],
    );
  }

  Widget _buildLessonCard(int idx) {
    final lesson = _lessons[idx];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text('#${idx + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.primaryGold)),
              ),
              const SizedBox(width: 8),
              Text('Lesson ${idx + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
              const Spacer(),
              if (_lessons.length > 1)
                IconButton(
                  onPressed: () => _removeLesson(idx),
                  icon: const Icon(Icons.delete_outline,
                      size: 20, color: AppTheme.errorGold),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _fieldLabel('Lesson Title', required: true),
          const SizedBox(height: 6),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'e.g. Warm-up & Posture Basics',
            ),
            initialValue: lesson.title,
            onChanged: (v) => lesson.title = v,
          ),
          const SizedBox(height: 14),
          _fieldLabel('Lesson Video', required: true),
          const SizedBox(height: 6),
          if (lesson.videoFile != null) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.mediumGray),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(9)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: lesson.videoController != null &&
                              lesson.videoController!.value.isInitialized
                          ? VideoPlayer(lesson.videoController!)
                          : Container(
                              color: AppTheme.lightGray,
                              child: const Center(
                                  child: Icon(Icons.videocam,
                                      size: 40,
                                      color: AppTheme.textSecondary)),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                              lesson.videoFile!.path.split('/').last,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _pickVideo(idx),
                          child: const Text('Change',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.primaryGold,
                                  fontWeight: FontWeight.w600)),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            setState(() {
                              lesson.videoController?.dispose();
                              lesson.videoController = null;
                              lesson.videoFile = null;
                              lesson.duration = '';
                            });
                          },
                          child: const Text('Remove',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.errorGold,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            InkWell(
              onTap: () => _pickVideo(idx),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppTheme.mediumGray,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.pureWhite,
                ),
                child: Column(
                  children: [
                    Icon(Icons.videocam_outlined,
                        size: 32,
                        color: AppTheme.textSecondary
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('Tap to upload',
                        style: TextStyle(
                            color: AppTheme.primaryGold,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('MP4, MOV, WEBM',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondary)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Section 5: Quizzes ─────────────────────────────────────────
  Widget _buildQuizzesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.paleGold,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('${_quizzes.length}',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.darkGold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(_quizzes.length, (qIdx) => _buildQuizCard(qIdx)),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _addQuiz,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add a quiz (optional)'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(int qIdx) {
    final quiz = _quizzes[qIdx];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.mediumGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text('#${qIdx + 1}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.primaryGold)),
              ),
              const SizedBox(width: 8),
              Text('Quiz ${qIdx + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textPrimary)),
              const Spacer(),
              IconButton(
                onPressed: () => _removeQuiz(qIdx),
                icon: const Icon(Icons.delete_outline,
                    size: 20, color: AppTheme.errorGold),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fieldLabel('Quiz Title', required: true),
          const SizedBox(height: 6),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'e.g. Mid-term Assessment',
            ),
            initialValue: quiz.title,
            onChanged: (v) => quiz.title = v,
          ),
          const SizedBox(height: 16),
          // Questions
          Container(
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(
              border: Border(
                  left: BorderSide(color: AppTheme.mediumGray, width: 2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('QUESTIONS & ANSWERS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(height: 10),
                ...List.generate(quiz.questions.length,
                    (qstIdx) => _buildQuestionCard(qIdx, qstIdx)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _addQuestion(qIdx),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Question',
                        style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(int qIdx, int qstIdx) {
    final qst = _quizzes[qIdx].questions[qstIdx];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.mediumGray.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Q${qstIdx + 1}:',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. What is the main characteristic of ballet?',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                  initialValue: qst.text,
                  onChanged: (v) => qst.text = v,
                ),
              ),
              if (_quizzes[qIdx].questions.length > 1) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: () => _removeQuestion(qIdx, qstIdx),
                  child: const Icon(Icons.close,
                      size: 18, color: AppTheme.textSecondary),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text('OPTIONS',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(height: 6),
          ...List.generate(
              qst.options.length,
              (optIdx) =>
                  _buildOptionRow(qIdx, qstIdx, optIdx)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _addOption(qIdx, qstIdx),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppTheme.mediumGray, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('+ Add Option',
                  style: TextStyle(fontSize: 12, color: AppTheme.primaryGold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionRow(int qIdx, int qstIdx, int optIdx) {
    final opt = _quizzes[qIdx].questions[qstIdx].options[optIdx];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: opt.isCorrect,
              onChanged: (v) =>
                  setState(() => opt.isCorrect = v ?? false),
              activeColor: AppTheme.primaryGold,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                hintText: 'Option ${optIdx + 1}',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              initialValue: opt.text,
              onChanged: (v) => opt.text = v,
            ),
          ),
          if (_quizzes[qIdx].questions[qstIdx].options.length > 2) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: () => _removeOption(qIdx, qstIdx, optIdx),
              child: const Icon(Icons.close,
                  size: 16, color: AppTheme.textSecondary),
            ),
          ],
        ],
      ),
    );
  }

  // ── Footer ─────────────────────────────────────────────────────
  Widget _buildFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('All courses publish immediately',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _loading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed:
                    (_loading || _stripeBlocked || _stripeLoading)
                        ? null
                        : () => _handleSubmit('publish'),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppTheme.pureWhite))
                    : const Text('Publish Course'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _loading ? null : () => _handleSubmit('draft'),
            child: const Text('Save Draft'),
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────
  Widget _fieldLabel(String text, {bool required = false, bool optional = false}) {
    return Row(
      children: [
        Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary)),
        if (required)
          const Text(' *',
              style: TextStyle(
                  color: AppTheme.errorGold, fontWeight: FontWeight.bold)),
        if (optional)
          const Text(' (optional)',
              style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppTheme.textSecondary)),
      ],
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────
class _LessonEntry {
  final String id;
  String title;
  String duration;
  File? videoFile;
  VideoPlayerController? videoController;

  _LessonEntry()
      : id = _uniqueId(),
        title = '',
        duration = '';
}

class _QuizEntry {
  final String id;
  String title;
  List<_QuestionEntry> questions;

  _QuizEntry()
      : id = _uniqueId(),
        title = '',
        questions = [_QuestionEntry()];
}

class _QuestionEntry {
  final String id;
  String text;
  List<_OptionEntry> options;

  _QuestionEntry()
      : id = _uniqueId(),
        text = '',
        options = [
          _OptionEntry(isCorrect: true),
          _OptionEntry(),
        ];
}

class _OptionEntry {
  final String id;
  String text;
  bool isCorrect;

  _OptionEntry({this.isCorrect = false})
      : id = _uniqueId(),
        text = '';
}
