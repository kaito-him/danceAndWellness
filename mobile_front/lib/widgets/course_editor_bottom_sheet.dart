import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dio/dio.dart' as dio_pkg;
import '../models/course.dart';
import '../services/api_client.dart';
import '../utils/app_theme.dart';

class CourseEditorBottomSheet extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final VoidCallback onSaved;

  const CourseEditorBottomSheet({
    super.key,
    required this.categories,
    required this.onSaved,
  });

  @override
  State<CourseEditorBottomSheet> createState() => _CourseEditorBottomSheetState();
}

class _CourseEditorBottomSheetState extends State<CourseEditorBottomSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  
  late String _selectedLevel;
  String? _selectedCategoryId;
  late bool _isFree;
  bool _saving = false;

  File? _thumbnailFile;
  String? _existingThumbnailUrl;

  List<_NewLesson> _lessons = [];
  List<_NewQuiz> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _priceCtrl = TextEditingController(text: '10');
    _selectedLevel = 'BEGINNER';
    _selectedCategoryId = widget.categories.isNotEmpty ? widget.categories[0]['id'] : null;
    _isFree = true;

    _lessons.add(_NewLesson());
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
    final response = await apiClient.dio.post('/api/files/upload', data: formData);
    return response.data['url'] as String;
  }

  Future<void> _saveOrPublish({required bool isDraft}) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      _showSnackBar('Please enter a course title', Colors.red);
      return;
    }

    if (!isDraft) {
      if (_thumbnailFile == null && (_existingThumbnailUrl == null || _existingThumbnailUrl!.isEmpty)) {
        _showSnackBar('Please upload a course thumbnail', Colors.red);
        return;
      }
      if (_lessons.isEmpty) {
        _showSnackBar('Please add at least one lesson', Colors.red);
        return;
      }
      if (_lessons.any((l) => l.titleCtrl.text.trim().isEmpty || (l.videoFile == null && (l.mediaUrl == null || l.mediaUrl!.isEmpty)))) {
        _showSnackBar('All lessons must have a title and a video', Colors.red);
        return;
      }

      // Quiz validation
      for (int i = 0; i < _quizzes.length; i++) {
        final q = _quizzes[i];
        if (q.titleCtrl.text.trim().isEmpty) {
          _showSnackBar('Quiz ${i + 1} must have a title', Colors.red);
          return;
        }
        for (int j = 0; j < q.questions.length; j++) {
          final qst = q.questions[j];
          if (qst.textCtrl.text.trim().isEmpty) {
            _showSnackBar('Quiz ${i + 1}, Question ${j + 1} must have text', Colors.red);
            return;
          }
          if (qst.options.length < 2) {
            _showSnackBar('Quiz ${i + 1}, Question ${j + 1} needs at least 2 options', Colors.red);
            return;
          }
          if (qst.options.any((o) => o.textCtrl.text.trim().isEmpty)) {
            _showSnackBar('All options in Quiz ${i + 1}, Question ${j + 1} must have text', Colors.red);
            return;
          }
          if (!qst.options.any((o) => o.isCorrect)) {
            _showSnackBar('Quiz ${i + 1}, Question ${j + 1} must have at least one correct option', Colors.red);
            return;
          }
        }
      }
    }

    setState(() => _saving = true);
    try {
      // 1. Upload Thumbnail
      String thumbUrl = _existingThumbnailUrl ?? '';
      if (_thumbnailFile != null) {
        thumbUrl = await _uploadFile(_thumbnailFile!);
      }

      // 2. Upload Lesson Videos
      final lessonData = [];
      for (int i = 0; i < _lessons.length; i++) {
        final l = _lessons[i];
        final lTitle = l.titleCtrl.text.trim();
        if (isDraft && lTitle.isEmpty && l.videoFile == null && (l.mediaUrl == null || l.mediaUrl!.isEmpty)) {
          continue; // Skip empty draft lessons
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

      // 3. Map Quizzes
      final quizData = _quizzes.asMap().entries.map((quizEntry) {
        final qIdx = quizEntry.key;
        final q = quizEntry.value;
        return {
          'quizId': 'quiz_${DateTime.now().millisecondsSinceEpoch}_$qIdx',
          'title': q.titleCtrl.text.trim().isEmpty ? 'Untitled Quiz' : q.titleCtrl.text.trim(),
          'questions': q.questions.asMap().entries.map((qstEntry) {
            final qstIdx = qstEntry.key;
            final qst = qstEntry.value;
            return {
              'questionId': 'question_${DateTime.now().millisecondsSinceEpoch}_$qstIdx',
              'text': qst.textCtrl.text.trim().isEmpty ? 'Untitled Question' : qst.textCtrl.text.trim(),
              'options': qst.options.map((opt) => {
                'text': opt.textCtrl.text.trim().isEmpty ? 'Option' : opt.textCtrl.text.trim(),
                'isCorrect': opt.isCorrect,
              }).toList()
            };
          }).toList()
        };
      }).toList();

      final data = {
        'title': title,
        'description': _descCtrl.text.trim(),
        'level': _selectedLevel,
        'categoryId': _selectedCategoryId,
        'isFree': _isFree,
        'price': _isFree ? 0 : double.tryParse(_priceCtrl.text) ?? 0,
        'thumbnailUrl': thumbUrl,
        'lessons': lessonData,
        'quizzes': quizData,
      };
      final apiClient = ApiClient();
      
      // Create new course/draft
      final path = isDraft ? '/api/courses/draft' : '/api/courses';
      await apiClient.dio.post(path, data: data);

      if (mounted) Navigator.pop(context);
      widget.onSaved();
      _showSnackBar(
        isDraft ? 'Draft saved successfully! 📝' : 'Course published successfully! 🎉',
        Colors.green,
      );
    } catch (e) {
      _showSnackBar(e.toString().replaceFirst('Exception: ', ''), Colors.red);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnackBar(String msg, Color bg) {
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
    final isDraft = true;

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
                    Text(
                      'Create New Course',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
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
                    enabled: isDraft,
                    decoration: _inputDeco('Course Title', Icons.title_rounded).copyWith(
                      helperText: isDraft ? null : 'Title cannot be changed after publishing',
                      helperStyle: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: _inputDeco('Description', Icons.description_outlined),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedLevel,
                          isExpanded: true,
                          decoration: _inputDeco('Level', Icons.bar_chart_rounded),
                          items: const [
                            DropdownMenuItem(value: 'BEGINNER', child: Text('Beginner', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            DropdownMenuItem(value: 'INTERMEDIATE', child: Text('Intermediate', overflow: TextOverflow.ellipsis, maxLines: 1)),
                            DropdownMenuItem(value: 'ADVANCED', child: Text('Advanced', overflow: TextOverflow.ellipsis, maxLines: 1)),
                          ],
                          onChanged: (v) => setState(() => _selectedLevel = v ?? 'BEGINNER'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          isExpanded: true,
                          decoration: _inputDeco('Category', Icons.category_outlined),
                          items: widget.categories.map((cat) => DropdownMenuItem<String>(
                            value: cat['id'],
                            child: Text(cat['name'] ?? 'Misc', overflow: TextOverflow.ellipsis, maxLines: 1),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedCategoryId = v),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // ── Section 2: Thumbnail ──
                  _dialogSectionTitle('2. Course Thumbnail'),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
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
                            onChanged: (v) => setState(() => _isFree = v),
                          ),
                          if (!_isFree)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              child: TextField(
                                controller: _priceCtrl,
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
                        onPressed: () => setState(() => _lessons.add(_NewLesson())),
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
                                  onPressed: () => setState(() => _lessons.removeAt(i)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: lesson.titleCtrl,
                            decoration: _inputDeco('Lesson Title', Icons.play_circle_outline),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: (isDraft || !hasExistingVideo) ? () async {
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
                        onPressed: () => setState(() => _quizzes.add(_NewQuiz())),
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
                                onPressed: () => setState(() => _quizzes.removeAt(qIdx)),
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
                                onPressed: () => setState(() => quiz.questions.add(_NewQuestion())),
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
                                        onPressed: () => setState(() => quiz.questions.removeAt(qstIdx)),
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
                                              onPressed: () => setState(() => qst.options.removeAt(optIdx)),
                                            ),
                                        ],
                                      ),
                                    );
                                  }),
                                  TextButton.icon(
                                    onPressed: () => setState(() => qst.options.add(_NewOption())),
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
                            onPressed: () => setState(() => quiz.questions.add(_NewQuestion())),
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saving ? null : () => _saveOrPublish(isDraft: true),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: AppTheme.primaryGold),
                      foregroundColor: AppTheme.primaryGold,
                    ),
                    child: _saving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: AppTheme.primaryGold, strokeWidth: 2))
                      : const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saving ? null : () => _saveOrPublish(isDraft: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publish Course', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
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
