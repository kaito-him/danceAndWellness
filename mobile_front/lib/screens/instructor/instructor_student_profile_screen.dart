import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../services/instructor_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import 'chat_thread_screen.dart';

class InstructorStudentProfileScreen extends StatefulWidget {
  final String studentUserId;
  final String studentName;
  const InstructorStudentProfileScreen({
    super.key,
    required this.studentUserId,
    required this.studentName,
  });

  @override
  State<InstructorStudentProfileScreen> createState() =>
      _InstructorStudentProfileScreenState();
}

class _InstructorStudentProfileScreenState
    extends State<InstructorStudentProfileScreen> {
  final _instructorService = InstructorDashboardService();

  Map<String, dynamic>? _student;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    final instructorId = context.read<AuthProvider>().userId;
    if (instructorId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get student profile and user info
      final student = await _instructorService.getStudentByUserId(widget.studentUserId);
      
      // Get user info
      final user = await _instructorService.getUserInfo(widget.studentUserId);

      // Get courses this student is enrolled in
      List<Map<String, dynamic>> allCourses = [];
      try {
        allCourses = await _instructorService.getStudentCourses(student['userId'] ?? widget.studentUserId);
      } catch (_) {
        allCourses = [];
      }

      // Filter courses to only show those taught by this instructor
      final instructorCourses = allCourses.where((course) {
        if (course['instructor'] == null) return false;
        final courseInstructor = course['instructor'];
        final courseInstructorUserId = courseInstructor['userId'] ?? courseInstructor['id'];
        return courseInstructorUserId == instructorId;
      }).toList();
      
      if (mounted) {
        setState(() {
          _student = student;
          _user = user;
          _courses = instructorCourses;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.white,
          title: Text(widget.studentName),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
      );
    }

    if (_error != null || _student == null) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.white,
          title: Text(widget.studentName),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 56, color: AppTheme.errorGold),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Student profile not found',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final photoFileId = _student!['photo'] ?? _user!['photo'];
    String? photoUrl;
    if (photoFileId != null) {
      // Check if it's already a full URL or just a file ID
      if (photoFileId.toString().startsWith('http')) {
        photoUrl = photoFileId.toString();
      } else {
        photoUrl = ApiClient.formatMediaUrl('/api/files/$photoFileId');
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: Colors.white,
        title: Text(_user!['username'] ?? widget.studentName),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined),
            onPressed: () => _openChat(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  ClipOval(
                    child: photoUrl != null
                        ? Image.network(
                            photoUrl,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatar(),
                            loadingBuilder: (_, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return _buildAvatar();
                            },
                          )
                        : _buildAvatar(),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _user!['username'] ?? widget.studentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.paleGold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Student',
                      style: TextStyle(
                        color: AppTheme.darkGold,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Email
            if (_user!['email'] != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AppTheme.primaryGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _user!['email'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Message Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openChat(),
                icon: const Icon(Icons.message_outlined),
                label: const Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Enrolled Courses Section
            const Text(
              'Enrolled In Your Courses',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (_courses.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Not enrolled in any courses yet',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ..._courses.map((course) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: course['thumbnailUrl'] != null
                        ? Image.network(
                            ApiClient.formatMediaUrl(course['thumbnailUrl']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildCourseThumbnail(),
                          )
                        : _buildCourseThumbnail(),
                  ),
                  title: Text(
                    course['title'] ?? 'Untitled Course',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    course['level'] ?? 'N/A',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.paleGold,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          (_user!['username'] ?? widget.studentName)
                  .toString()
                  .substring(0, 1)
                  .toUpperCase() ??
              'S',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGold,
          ),
        ),
      ),
    );
  }

  Widget _buildCourseThumbnail() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppTheme.paleGold,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.play_circle_outline,
        color: AppTheme.primaryGold,
      ),
    );
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatThreadScreen(
          otherUserId: widget.studentUserId,
          otherUsername: _user!['username'] ?? widget.studentName,
          otherUserPhoto: _student!['photo'] ?? _user!['photo'],
        ),
      ),
    );
  }
}
