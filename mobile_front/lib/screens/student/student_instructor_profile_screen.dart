import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/instructor_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';

class StudentInstructorProfileScreen extends StatefulWidget {
  final String instructorId;
  const StudentInstructorProfileScreen({super.key, required this.instructorId});

  @override
  State<StudentInstructorProfileScreen> createState() =>
      _StudentInstructorProfileScreenState();
}

class _StudentInstructorProfileScreenState
    extends State<StudentInstructorProfileScreen> {
  final _instructorService = InstructorDashboardService();

  Map<String, dynamic>? _instructor;
  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInstructorProfile();
  }

  Future<void> _loadInstructorProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Get instructor profile and user info
      final instructor = await _instructorService.getProfileByUserId(widget.instructorId);

      // Get courses by this instructor
      final courses = await _instructorService.getAllPublishedCourses();
      final instructorCourses = courses.where((course) {
        if (course.instructor == null) return false;
        final courseInstructorUserId = course.instructor!.userId ?? course.instructor!.id;
        return courseInstructorUserId == widget.instructorId;
      }).map((course) => {
        'courseId': course.courseId,
        'title': course.title,
        'level': course.level,
        'isFree': course.isFree,
        'price': course.price,
        'thumbnailUrl': course.thumbnailUrl,
      }).toList();

      if (mounted) {
        setState(() {
          _instructor = {
            'id': instructor.id,
            'userId': instructor.userId,
            'username': instructor.username,
            'email': instructor.email,
            'specialization': instructor.specialization,
            'studioName': instructor.studioName,
            'bio': instructor.bio,
            'yearsOfExperience': instructor.yearsOfExperience,
            'linkedIn': instructor.linkedIn,
            'website': instructor.website,
            'photo': instructor.photo,
            'featured': instructor.featured,
            'totalCourses': instructor.totalCourses,
          };
          _user = {
            'username': instructor.username,
            'email': instructor.email,
            'photo': instructor.photo,
          };
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
          title: const Text('Instructor Profile'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold),
        ),
      );
    }

    if (_error != null || _instructor == null) {
      return Scaffold(
        backgroundColor: AppTheme.pageBackground,
        appBar: AppBar(
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.white,
          title: const Text('Instructor Profile'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 56,
                  color: AppTheme.errorGold,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Instructor profile not found',
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

    final photoFileId = _instructor!['photo'] ?? _user!['photo'];
    String? photoUrl;
    if (photoFileId != null) {
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
        title: Text(_user!['username'] ?? 'Instructor'),
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
                    _user!['username'] ?? 'Instructor',
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
                      'Instructor',
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

            // Specialization
            if (_instructor!['specialization'] != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.work_outline, color: AppTheme.primaryGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _instructor!['specialization'],
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

            // Bio
            if (_instructor!['bio'] != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryGold),
                          SizedBox(width: 8),
                          Text(
                            'About',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _instructor!['bio'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Experience
            if (_instructor!['yearsOfExperience'] != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.timeline, color: AppTheme.primaryGold),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_instructor!['yearsOfExperience']} years of experience',
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

            const SizedBox(height: 32),

            // Courses Section
            const Text(
              'Courses by this Instructor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 16),

            if (_courses.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No courses available yet.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _courses.length,
                itemBuilder: (context, index) {
                  final course = _courses[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        context.push('/student/course/${course['courseId']}');
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            if (course['thumbnailUrl'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  ApiClient.formatMediaUrl(course['thumbnailUrl']),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: AppTheme.paleGold,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppTheme.paleGold,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.image,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    course['title'] ?? 'Course',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      if (course['level'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryGold.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            course['level'],
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: AppTheme.primaryGold,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      Text(
                                        course['isFree'] ? 'Free' : '\$${course['price']}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: course['isFree'] 
                                              ? Colors.green 
                                              : AppTheme.darkGold,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
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
        gradient: LinearGradient(
          colors: [
            AppTheme.paleGold,
            AppTheme.primaryGold,
          ],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _user!['username']?.toString().substring(0, 1).toUpperCase() ?? 'I',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}