import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../models/course.dart';
import '../services/api_client.dart';
import '../utils/app_theme.dart';

class CourseDetailsBottomSheet extends StatefulWidget {
  final Course? editCourse;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onSaved;

  const CourseDetailsBottomSheet({
    super.key,
    this.editCourse,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<CourseDetailsBottomSheet> createState() => _CourseDetailsBottomSheetState();
}

class _CourseDetailsBottomSheetState extends State<CourseDetailsBottomSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  
  late String _selectedLevel;
  String? _selectedCategoryId;
  late bool _isFree;
  bool _saving = false;
  late bool _isEditing;

  File? _thumbnailFile;
  String? _existingThumbnailUrl;

  List<_NewLesson> _lessons = [];
  List<_NewQuiz> _quizzes = [];

  String? _titleError;
  String? _lessonsError;
  String? _thumbnailError;

  @override
  void initState() {
    super.initState();
    final c = widget.editCourse;
    _titleCtrl = TextEditingController(text: c?.title ?? '');
    _descCtrl = TextEditingController(text: c?.description ?? '');
    _priceCtrl = TextEditingController(text: c?.price != null ? c!.price!.toStringAsFixed(0) : '10');
    _selectedLevel = c?.level ?? 'BEGINNER';
    _selectedCategoryId = c?.categoryId ?? (widget.categories.isNotEmpty ? widget.categories[0]['id'] : null);
    _isFree = c?.isFree ?? true;
    _existingThumbnailUrl = c?.thumbnailUrl;
    _isEditing = c != null;

    if (c != null) {
      _lessons = c.lessons.map((l) {
        final nl = _NewLesson();
        nl.titleCtrl.text = l.title;
        nl.mediaUrl = l.mediaUrl;
        nl.videoName = l.mediaUrl != null && l.mediaUrl!.isNotEmpty ? l.mediaUrl!.split('/').last : null;
        return nl;
      }).toList();
    }
    if (_lessons.isEmpty) {
      _lessons.add(_NewLesson());
    }

    if (c != null) {
      _quizzes = c.quizzes.map((q) {
        final nq = _NewQuiz();
        nq.titleCtrl.text = q.title;
        nq.questions.clear(); // remove default empty question
        nq.questions.addAll(q.questions.map((qst) {
          final nqst = _NewQuestion();
          nqst.textCtrl.text = qst.text;
          nqst.options.clear(); // remove default options
          nqst.options.addAll(qst.options.map((o) {
            final nopt = _NewOption();
            nopt.textCtrl.text = o.text;
            nopt.isCorrect = o.isCorrect;
            return nopt;
          }));
          return nqst;
        }));
        return nq;
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<String> _uploadFile(File file) async {
    final fileName = file.path.split('/').last;
    final ext = fileName.split('.').last.toLowerCase();
    
    String type = 'image';
    if (['mp4', 'mov', 'webm', 'avi'].contains(ext)) type = 'video';

    final formData = dio_pkg.FormData.fromMap({
      'file': await dio_pkg.MultipartFile.fromFile(
        file.path,
        filename: fileName,
        contentType: MediaType(type, ext == 'jpg' ? 'jpeg' : ext),
      ),
    });

    final apiClient = ApiClient();
    final response = await apiClient.dio.post('/files/upload', data: formData);
    return response.data['url'] as String;
  }

  // ── Validate publish requirements ────────────────────────────────────────
  bool _validateForPublish() {
    setState(() {
      _titleError = null;
      _lessonsError = null;
      _thumbnailError = null;
    });

    bool valid = true;

    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Please enter a course title');
      valid = false;
    }

    if (_thumbnailFile == null &&
        (_existingThumbnailUrl == null || _existingThumbnailUrl!.isEmpty)) {
      setState(() => _thumbnailError = 'Please upload a course thumbnail');
      valid = false;
    }

    final nonEmptyLessons = _lessons.where((l) {
      final hasTitle = l.titleCtrl.text.trim().isNotEmpty;
      final hasVideo =
          l.videoFile != null || (l.mediaUrl != null && l.mediaUrl!.isNotEmpty);
      return hasTitle || hasVideo;
    }).toList();

    if (nonEmptyLessons.isEmpty) {
      setState(() => _lessonsError = 'Please add at least one lesson');
      valid = false;
    } else {
      for (int i = 0; i < nonEmptyLessons.length; i++) {
        final l = nonEmptyLessons[i];
        if (l.titleCtrl.text.trim().isEmpty) {
          setState(() => _lessonsError = 'Lesson ${i + 1} must have a title');
          valid = false;
          break;
        }
        if (l.videoFile == null &&
            (l.mediaUrl == null || l.mediaUrl!.isEmpty)) {
          setState(
              () => _lessonsError = 'Lesson ${i + 1} must have a video');
          valid = false;
          break;
        }
      }
    }

    // Quiz validation
    for (int i = 0; i < _quizzes.length; i++) {
      final q = _quizzes[i];
      if (q.titleCtrl.text.trim().isEmpty) {
        setState(() => _lessonsError = 'Quiz ${i + 1} must have a title');
        valid = false;
        break;
      }
      for (int j = 0; j < q.questions.length; j++) {
        final qst = q.questions[j];
        if (qst.textCtrl.text.trim().isEmpty) {
          setState(() =>
              _lessonsError = 'Quiz ${i + 1}, Question ${j + 1} must have text');
          valid = false;
          break;
        }
        if (qst.options.length < 2) {
          setState(() => _lessonsError =
              'Quiz ${i + 1}, Question ${j + 1} needs at least 2 options');
          valid = false;
          break;
        }
        if (qst.options.any((o) => o.textCtrl.text.trim().isEmpty)) {
          setState(() => _lessonsError =
              'All options in Quiz ${i + 1}, Question ${j + 1} must have text');
          valid = false;
          break;
        }
        if (!qst.options.any((o) => o.isCorrect)) {
          setState(() => _lessonsError =
              'Quiz ${i + 1}, Question ${j + 1} must have at least one correct option');
          valid = false;
          break;
        }
      }
      if (!valid) break;
    }

    return valid;
  }

  // ── Build the course payload and upload any new files ────────────────────
  Future<Map<String, dynamic>> _buildPayload({required bool isDraft}) async {
    // Upload thumbnail if new
    String thumbUrl = _existingThumbnailUrl ?? '';
    if (_thumbnailFile != null) {
      thumbUrl = await _uploadFile(_thumbnailFile!);
    }

    // Upload lesson videos
    final lessonData = [];
    for (int i = 0; i < _lessons.length; i++) {
      final l = _lessons[i];
      final lTitle = l.titleCtrl.text.trim();
      // Skip completely empty lessons when saving a draft
      if (isDraft &&
          lTitle.isEmpty &&
          l.videoFile == null &&
          (l.mediaUrl == null || l.mediaUrl!.isEmpty)) {
        continue;
      }
      String? videoUrl = l.mediaUrl;
      if (l.videoFile != null) {
        videoUrl = await _uploadFile(l.videoFile!);
      }
      lessonData.add({
        'lessonId': 'lesson_${DateTime.now().millisecondsSinceEpoch}_$i',
        'title': lTitle.isEmpty ? 'Untitled Lesson' : lTitle,
        'mediaUrl': videoUrl,
        'order': i,
        'duration': 0,
      });
    }

    // Map quizzes
    final quizData = _quizzes.asMap().entries.map((quizEntry) {
      final qIdx = quizEntry.key;
      final q = quizEntry.value;
      return {
        'quizId': 'quiz_${DateTime.now().millisecondsSinceEpoch}_$qIdx',
        'title':
            q.titleCtrl.text.trim().isEmpty ? 'Untitled Quiz' : q.titleCtrl.text.trim(),
        'questions': q.questions.asMap().entries.map((qstEntry) {
          final qstIdx = qstEntry.key;
          final qst = qstEntry.value;
          return {
            'questionId':
                'question_${DateTime.now().millisecondsSinceEpoch}_$qstIdx',
            'text': qst.textCtrl.text.trim().isEmpty
                ? 'Untitled Question'
                : qst.textCtrl.text.trim(),
            'options': qst.options
                .map((opt) => {
                      'text': opt.textCtrl.text.trim().isEmpty
                          ? 'Option'
                          : opt.textCtrl.text.trim(),
                      'isCorrect': opt.isCorrect,
                    })
                .toList()
          };
        }).toList()
      };
    }).toList();

    return {
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'level': _selectedLevel,
      'categoryId': _selectedCategoryId,
      'isFree': _isFree,
      'price': _isFree ? 0 : double.tryParse(_priceCtrl.text) ?? 0,
      'thumbnailUrl': thumbUrl,
      'lessons': lessonData,
      'quizzes': quizData,
    };
  }

  Future<void> _saveChanges() async {
    if (!_isEditing) return;

    setState(() {
      _titleError = null;
      _lessonsError = null;
      _thumbnailError = null;
    });

    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _titleError = 'Please enter a course title');
      return;
    }

    setState(() => _saving = true);
    try {
      final courseId = widget.editCourse?.courseId;
      if (courseId == null) return;

      final data = await _buildPayload(isDraft: true);
      final apiClient = ApiClient();

      try {
        await apiClient.dio.put('/courses/$courseId', data: data);
      } on dio_pkg.DioException catch (e) {
        if (e.response?.statusCode == 403) {
          throw Exception('Access denied. Please log out and log in again.');
        }
        rethrow;
      }

      if (mounted) Navigator.pop(context);
      widget.onSaved();
      _show('Changes saved successfully!', Colors.green);
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _publishCourse() async {
    if (!_isEditing) return;
    if (!_validateForPublish()) return;

    // Confirm before publishing
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.rocket_launch_outlined, color: AppTheme.primaryGold),
            SizedBox(width: 8),
            Text('Publish Course'),
          ],
        ),
        content: const Text(
          'Once published, the course will be visible to all students. '
          'Title and pricing cannot be changed after publishing.\n\n'
          'Are you ready to publish?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      final courseId = widget.editCourse?.courseId;
      if (courseId == null) return;

      final apiClient = ApiClient();

      // Step 1: Save all changes first
      final data = await _buildPayload(isDraft: false);
      try {
        await apiClient.dio.put('/courses/$courseId', data: data);
      } on dio_pkg.DioException catch (e) {
        if (e.response?.statusCode == 403) {
          throw Exception('Access denied. Please log out and log in again.');
        }
        final msg = e.response?.data;
        throw Exception(msg?.toString() ?? 'Failed to save course before publishing.');
      }

      // Step 2: Publish
      try {
        await apiClient.dio.patch('/courses/$courseId/publish');
      } on dio_pkg.DioException catch (e) {
        if (e.response?.statusCode == 403) {
          throw Exception('Access denied. Please log out and log in again.');
        }
        final msg = e.response?.data;
        throw Exception(msg?.toString() ?? 'Failed to publish course.');
      }

      if (mounted) Navigator.pop(context);
      widget.onSaved();
      _show('Course published successfully!', Colors.green);
    } catch (e) {
      _show(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _show(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.primaryGold, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _dialogSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.editCourse;
    final isDraft = c == null || c.status == 'DRAFT';

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Course Preview',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          _isEditing ? 'Editing enabled.' : 'Preview mode.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _isEditing = !_isEditing),
                          icon: Icon(
                            _isEditing ? Icons.edit : Icons.edit_outlined,
                            color: _isEditing ? AppTheme.primaryGold : AppTheme.textSecondary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Section 1: Basic Info ──
                  _dialogSectionTitle('1. Basic Info'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _titleCtrl,
                    enabled: _isEditing && isDraft,
                    decoration: _inputDeco('Course Title', Icons.title_rounded).copyWith(
                      helperText: _titleError ?? (isDraft ? null : 'Title cannot be changed after publishing'),
                      helperStyle: TextStyle(
                        fontSize: 11,
                        color: _titleError != null ? Colors.red : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descCtrl,
                    enabled: _isEditing,
                    maxLines: 3,
                    decoration: _inputDeco('Description', Icons.description_outlined),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedLevel,
                    isExpanded: true,
                    decoration: _inputDeco('Level', Icons.bar_chart_rounded),
                    items: const [
                      DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate', overflow: TextOverflow.ellipsis, maxLines: 1)),
                      DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced', overflow: TextOverflow.ellipsis, maxLines: 1)),
                    ],
                    onChanged: _isEditing ? (v) => setState(() => _selectedLevel = v ?? 'BEGINNER') : null,
                  ),

                  const SizedBox(height: 28),
                  
                  // ── Section 2: Thumbnail ──
                  _dialogSectionTitle('2. Course Thumbnail'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: !_isEditing ? null : () async {
                      final picker = ImagePicker();
                      final img = await picker.pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        setState(() {
                          _thumbnailFile = File(img.path);
                        });
                      }
                    },
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.paleGold.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.paleGold, style: BorderStyle.solid),
                      ),
                      child: _thumbnailFile != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(_thumbnailFile!, height: 140, width: double.infinity, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  right: 8, top: 8,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.black54,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                      onPressed: () => setState(() { _thumbnailFile = null; }),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : (_existingThumbnailUrl != null && _existingThumbnailUrl!.isNotEmpty)
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        ApiClient.formatMediaUrl(_existingThumbnailUrl),
                                        height: 140,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Center(
                                          child: Icon(Icons.broken_image_outlined, size: 40, color: AppTheme.primaryGold),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8, top: 8,
                                      child: CircleAvatar(
                                        backgroundColor: Colors.black54,
                                        child: IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                          onPressed: () => setState(() {
                                            _thumbnailFile = null;
                                            _existingThumbnailUrl = null;
                                          }),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.add_photo_alternate_outlined, size: 40, color: AppTheme.primaryGold),
                                    const SizedBox(height: 8),
                                    const Text('Pick Thumbnail', style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                                    Text('JPG, PNG or WebP', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                  ],
                                ),
                    ),
                  ),
                  if (_thumbnailError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _thumbnailError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  
                  const SizedBox(height: 28),
 
                  // ── Section 3: Pricing ──
                  _dialogSectionTitle('3. Pricing'),
                  const SizedBox(height: 12),
                  if (isDraft)
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.paleGold.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            title: const Text('Free Course', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Students can enroll without paying'),
                            value: _isFree,
                            activeColor: AppTheme.primaryGold,
                            onChanged: _isEditing ? (v) => setState(() => _isFree = v) : null,
                          ),
                          if (!_isFree)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: TextField(
                                controller: _priceCtrl,
                                enabled: _isEditing,
                                keyboardType: TextInputType.number,
                                decoration: _inputDeco('Price (USD)', Icons.monetization_on_outlined),
                              ),
                            ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isFree ? 'Pricing: Free Course' : 'Pricing: Paid Course - \$${_priceCtrl.text}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Pricing cannot be changed after publishing',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 28),
 
                  // ── Section 4: Lessons ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _dialogSectionTitle('4. Lessons'),
                      TextButton.icon(
                        onPressed: _isEditing ? () => setState(() => _lessons.add(_NewLesson())) : null,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add Lesson'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._lessons.asMap().entries.map((entry) {
                    int i = entry.key;
                    _NewLesson lesson = entry.value;
                    final hasExistingVideo = lesson.mediaUrl != null && lesson.mediaUrl!.isNotEmpty;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Lesson ${i + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                              if (_lessons.length > 1 && (isDraft || !hasExistingVideo))
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: _isEditing ? () => setState(() => _lessons.removeAt(i)) : null,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: lesson.titleCtrl,
                            enabled: _isEditing,
                            decoration: _inputDeco('Lesson Title', Icons.play_circle_outline),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: (_isEditing && (isDraft || !hasExistingVideo)) ? () async {
                              final result = await FilePicker.platform.pickFiles(type: FileType.video);
                              if (result != null && result.files.single.path != null) {
                                setState(() {
                                  lesson.videoFile = File(result.files.single.path!);
                                  lesson.videoName = result.files.single.name;
                                });
                              }
                            } : null,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: (isDraft || !hasExistingVideo) ? Colors.grey[50] : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.video_collection_outlined, 
                                    color: (lesson.videoFile != null || hasExistingVideo) ? AppTheme.primaryGold : Colors.grey,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      lesson.videoName ?? (hasExistingVideo ? 'Existing Video' : 'Upload Video'),
                                      style: TextStyle(
                                        color: (lesson.videoFile != null || hasExistingVideo) ? AppTheme.textPrimary : Colors.grey,
                                        fontSize: 13,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (lesson.videoFile != null || hasExistingVideo)
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                ],
                              ),
                            ),
                          ),
                          if (!isDraft && hasExistingVideo)
                            const Padding(
                              padding: EdgeInsets.only(top: 6, left: 4),
                              child: Text(
                                'Videos cannot be changed after publishing',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  if (_lessonsError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _lessonsError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                  
                  const SizedBox(height: 28),

                  // ── Section 5: Quizzes ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _dialogSectionTitle('5. Quizzes (Optional)'),
                          const SizedBox(width: 8),
                          if (_quizzes.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.paleGold,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${_quizzes.length}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkGold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: _isEditing ? () => setState(() => _quizzes.add(_NewQuiz())) : null,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        label: const Text('Add Quiz'),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ..._quizzes.asMap().entries.map((quizEntry) {
                    int qIdx = quizEntry.key;
                    _NewQuiz quiz = quizEntry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.paleGold),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryGold.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Quiz ${qIdx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.darkGold, fontSize: 14)),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: _isEditing ? () => setState(() => _quizzes.removeAt(qIdx)) : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: quiz.titleCtrl,
                            decoration: _inputDeco('Quiz Title', Icons.quiz_outlined),
                          ),
                          const SizedBox(height: 16),
                          
                          // Questions header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Questions (${quiz.questions.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary)),
                              TextButton.icon(
                                onPressed: _isEditing ? () => setState(() => quiz.questions.add(_NewQuestion())) : null,
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Add Question', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.primaryGold,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 8),
                          const SizedBox(height: 8),
                          
                          // Questions list
                          ...quiz.questions.asMap().entries.map((qstEntry) {
                            int qstIdx = qstEntry.key;
                            _NewQuestion qst = qstEntry.value;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Question ${qstIdx + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textSecondary, fontSize: 12)),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                        onPressed: _isEditing ? () => setState(() => quiz.questions.removeAt(qstIdx)) : null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: qst.textCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Enter question text',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Options list
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Options', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: AppTheme.textSecondary)),
                                      Text('Mark Correct option', style: TextStyle(fontSize: 10, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ...qst.options.asMap().entries.map((optEntry) {
                                    int optIdx = optEntry.key;
                                    _NewOption opt = optEntry.value;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Checkbox(
                                            value: opt.isCorrect,
                                            activeColor: AppTheme.primaryGold,
                                            onChanged: (v) => setState(() {
                                              opt.isCorrect = v ?? false;
                                            }),
                                          ),
                                          Expanded(
                                            child: TextField(
                                              controller: opt.textCtrl,
                                              decoration: InputDecoration(
                                                hintText: 'Option ${optIdx + 1}',
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (qst.options.length > 2)
                                            IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                              onPressed: _isEditing ? () => setState(() => qst.options.removeAt(optIdx)) : null,
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                  TextButton.icon(
                                    onPressed: _isEditing ? () => setState(() => qst.options.add(_NewOption())) : null,
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Option'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryGold,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          OutlinedButton.icon(
                            onPressed: _isEditing ? () => setState(() => quiz.questions.add(_NewQuestion())) : null,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Question'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryGold,
                              side: const BorderSide(color: AppTheme.paleGold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          
          // Bottom Buttons
          if (_isEditing)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Builder(builder: (context) {
                final c = widget.editCourse;
                final isDraft = c == null || c.status == 'DRAFT';

                if (isDraft) {
                  // Two-button layout for drafts
                  return Row(
                    children: [
                      // Save Changes
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _saving ? null : _saveChanges,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryGold,
                            side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _saving
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      color: AppTheme.primaryGold, strokeWidth: 2))
                              : const Text('Save Draft',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Publish Course
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saving ? null : _publishCourse,
                          icon: const Icon(Icons.rocket_launch_outlined, size: 18),
                          label: const Text('Publish',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Published course — only save changes
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Save Changes',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}

// ── State Helper Classes ─────────────────────────────────────────────────────

class _NewLesson {
  final titleCtrl = TextEditingController();
  File? videoFile;
  String? videoName;
  String? mediaUrl;
}

class _NewQuiz {
  final titleCtrl = TextEditingController();
  final List<_NewQuestion> questions = [];
}

class _NewQuestion {
  final textCtrl = TextEditingController();
  final List<_NewOption> options = [_NewOption(), _NewOption()];
}

class _NewOption {
  final textCtrl = TextEditingController();
  bool isCorrect = false;
}
