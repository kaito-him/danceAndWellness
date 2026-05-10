import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/course.dart';
import '../../models/lesson.dart';
import '../../services/api_client.dart';
import '../../services/course_service.dart';
import '../../utils/app_theme.dart';

class AdminCourseDetailScreen extends StatefulWidget {
  final String courseId;

  const AdminCourseDetailScreen({super.key, required this.courseId});

  @override
  State<AdminCourseDetailScreen> createState() => _AdminCourseDetailScreenState();
}

class _AdminCourseDetailScreenState extends State<AdminCourseDetailScreen> {
  final _courseService = CourseService();
  Course? _course;
  bool _loading = true;
  String? _expandedLessonId;

  @override
  void initState() {
    super.initState();
    _fetchCourse();
  }

  Future<void> _fetchCourse() async {
    setState(() => _loading = true);
    try {
      final course = await _courseService.getCourseById(widget.courseId);
      if (mounted) {
        setState(() {
          _course = course;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Failed to load course details.', isError: true);
      }
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorGold : AppTheme.successGold,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Detail')),
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Course Detail')),
        body: const Center(child: Text('Course not found.')),
      );
    }

    final course = _course!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(course),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(course),
                  const SizedBox(height: 24),
                  _buildStats(course),
                  const SizedBox(height: 24),
                  _buildSectionTitle('About This Course'),
                  const SizedBox(height: 12),
                  Text(
                    course.description ?? 'No description provided.',
                    style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Curriculum'),
                  const SizedBox(height: 12),
                  if (course.lessons.isEmpty)
                    const Text('No lessons found for this course.', 
                      style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondary))
                  else
                    Column(
                      children: course.lessons.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final lesson = entry.value;
                        return _buildLessonRow(idx, lesson);
                      }).toList(),
                    ),
                  const SizedBox(height: 100), // Padding for bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Course course) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: AppTheme.primaryGold,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (course.thumbnailUrl != null)
              Image.network(
                ApiClient.formatMediaUrl(course.thumbnailUrl),
                fit: BoxFit.cover,
              )
            else
              Container(color: AppTheme.paleGold, child: const Icon(Icons.movie_filter_rounded, size: 64, color: AppTheme.primaryGold)),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.black.withOpacity(0.6)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Course course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(course.level ?? 'UNKNOWN', style: const TextStyle(
                color: AppTheme.darkGold, fontSize: 10, fontWeight: FontWeight.bold
              )),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.circle, size: 4, color: AppTheme.mediumGray),
            const SizedBox(width: 8),
            Text(course.isFree ? 'FREE' : '\$${course.price}', style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold
            )),
          ],
        ),
        const SizedBox(height: 12),
        Text(course.title, style: const TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary
        )),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppTheme.paleGold,
              backgroundImage: (course.instructor?.photo != null)
                ? NetworkImage(ApiClient.formatMediaUrl('/api/files/${course.instructor!.photo}'))
                : null,
              child: (course.instructor?.photo == null)
                ? const Icon(Icons.person, size: 16, color: AppTheme.darkGold)
                : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Instructor', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                Text(course.instructor?.username ?? 'Unknown', style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary
                )),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(Course course) {
    final totalMin = course.lessons.fold<int>(0, (prev, l) => prev + l.duration);
    return Row(
      children: [
        _statCard(Icons.play_circle_outline_rounded, '${course.lessonCount}', 'Lessons'),
        const SizedBox(width: 12),
        _statCard(Icons.timer_outlined, _formatMinutes(totalMin), 'Duration'),
        const SizedBox(width: 12),
        _statCard(Icons.people_outline_rounded, '—', 'Students'), // Count not in course object
      ],
    );
  }

  String _formatMinutes(int min) {
    if (min == 0) return '0m';
    final h = min ~/ 60;
    final m = min % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  Widget _buildLessonRow(int index, Lesson lesson) {
    final isExpanded = _expandedLessonId == lesson.lessonId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: isExpanded ? Border.all(color: AppTheme.primaryGold.withOpacity(0.5)) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expandedLessonId = isExpanded ? null : lesson.lessonId),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: isExpanded ? AppTheme.primaryGold : AppTheme.paleGold, 
                      shape: BoxShape.circle
                    ),
                    child: Center(
                      child: Text('${index + 1}', style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: isExpanded ? Colors.white : AppTheme.darkGold
                      ))
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(lesson.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Row(
                          children: [
                            const Icon(Icons.videocam_outlined, size: 12, color: AppTheme.textSecondary),
                            const SizedBox(width: 4),
                            Text('${lesson.duration}m', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, 
                    size: 20, 
                    color: AppTheme.mediumGray
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              color: Colors.black,
              child: lesson.mediaUrl != null
                ? InlineVideoPlayer(url: ApiClient.formatMediaUrl(lesson.mediaUrl))
                : const AspectRatio(
                    aspectRatio: 16/9,
                    child: Center(child: Text('No video source', style: TextStyle(color: Colors.white))),
                  ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String val, String lbl) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.lightGray,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryGold),
            const SizedBox(height: 8),
            Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text(lbl, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(
      fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary
    ));
  }
}

class InlineVideoPlayer extends StatefulWidget {
  final String url;
  const InlineVideoPlayer({super.key, required this.url});

  @override
  State<InlineVideoPlayer> createState() => _InlineVideoPlayerState();
}

class _InlineVideoPlayerState extends State<InlineVideoPlayer> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: 16 / 9,
        allowFullScreen: true,
        allowPlaybackSpeedChanging: true,
      );
    } catch (e) {
      debugPrint('Error initializing video: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController == null || !_videoController.value.isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewieController!),
    );
  }
}
