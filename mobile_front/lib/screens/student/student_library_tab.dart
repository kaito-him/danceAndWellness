import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../models/course.dart';
import '../../services/student_service.dart';
import '../../services/enrollment_service.dart';
import '../../utils/app_theme.dart';
import 'student_course_detail_screen.dart';

class StudentLibraryTab extends StatefulWidget {
  const StudentLibraryTab({super.key});

  @override
  State<StudentLibraryTab> createState() => _StudentLibraryTabState();
}

class _StudentLibraryTabState extends State<StudentLibraryTab> {
  final _studentService = StudentService();
  final _enrollService = EnrollmentService();

  List<Course> _courses = [];
  Map<String, StudentProgress?> _progressMap = {};

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final courses = await _studentService.getStudentCourses(userId);
      
      final progMap = <String, StudentProgress?>{};
      await Future.wait(courses.map((c) async {
        try {
          final prog = await _enrollService.getStudentProgress(userId, c.courseId);
          progMap[c.courseId] = prog;
        } catch (_) {
          progMap[c.courseId] = null;
        }
      }));

      setState(() {
        _courses = courses;
        _progressMap = progMap;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppTheme.errorGold),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppTheme.textSecondary)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _loadAll, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school_outlined, size: 64, color: AppTheme.primaryGold),
            const SizedBox(height: 16),
            const Text(
              'No enrolled courses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse and enroll in courses to start learning!',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppTheme.primaryGold,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _courses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final c = _courses[i];
          final progress = _progressMap[c.courseId];
          final percent = progress?.completionPercent ?? 0.0;
          final completed = progress?.completedLessons ?? 0;
          final total = progress?.totalLessons ?? c.lessonCount;

          return Card(
            margin: EdgeInsets.zero,
            child: InkWell(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => StudentCourseDetailScreen(courseId: c.courseId)),
                );
                _loadAll();
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(color: AppTheme.paleGold, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.play_circle_outline, color: AppTheme.primaryGold, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'By ${c.instructor?.username ?? "Instructor"}',
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          // Progress Bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: percent / 100.0,
                                    color: AppTheme.primaryGold,
                                    backgroundColor: AppTheme.paleGold,
                                    minHeight: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${percent.toStringAsFixed(0)}%',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryGold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$completed of $total lessons completed',
                            style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: AppTheme.primaryGold),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
