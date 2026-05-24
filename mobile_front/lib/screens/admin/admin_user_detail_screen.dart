import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/admin_user_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import 'admin_course_detail_screen.dart';

class AdminUserDetailScreen extends StatefulWidget {
  final AppUser user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  late AppUser _user;
  final AdminUserService _userService = AdminUserService();
  bool _processing = false;
  List<dynamic> _instructorCourses = [];
  bool _loadingCourses = false;
  List<dynamic> _studentCourses = [];
  bool _loadingStudentCourses = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    if (_user.role == 'INSTRUCTOR' && _user.id != null) {
      _fetchInstructorCourses();
    }
    if (_user.role == 'STUDENT' && _user.id != null) {
      _fetchStudentCourses();
    }
  }

  Future<void> _fetchInstructorCourses() async {
    setState(() => _loadingCourses = true);
    try {
      final courses = await _userService.getInstructorCourses(_user.id!);
      if (mounted) {
        setState(() {
          _instructorCourses = courses;
          _loadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _fetchStudentCourses() async {
    setState(() => _loadingStudentCourses = true);
    try {
      final courses = await _userService.getStudentCourses(_user.id!);
      if (mounted) {
        setState(() {
          _studentCourses = courses;
          _loadingStudentCourses = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingStudentCourses = false);
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorGold : AppTheme.successGold,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _handleBanAction() async {
    final isBanned = _user.accountStatus == 'INACTIVE';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isBanned ? 'Reinstate User' : 'Suspend Account',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
        content: Text(
            'Are you sure you want to ${isBanned ? 'reinstate' : 'suspend'} ${_user.username}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isBanned ? 'Reinstate' : 'Suspend',
                style: TextStyle(
                    color: isBanned ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      if (isBanned) {
        await _userService.unbanUser(_user.userId);
        _showToast('Account reinstated');
      } else {
        await _userService.banUser(_user.userId);
        _showToast('Account suspended');
      }
      setState(() {
        _user = AppUser(
          userId: _user.userId,
          id: _user.id,
          username: _user.username,
          email: _user.email,
          role: _user.role,
          photo: _user.photo,
          accountStatus: isBanned ? 'ACTIVE' : 'INACTIVE',
          featured: _user.featured,
          specialization: _user.specialization,
          totalCourses: _user.totalCourses,
          yearsOfExperience: _user.yearsOfExperience,
          linkedIn: _user.linkedIn,
          website: _user.website,
          studioName: _user.studioName,
          lastLoginDate: _user.lastLoginDate,
          createdAt: _user.createdAt,
        );
      });
    } catch (e) {
      _showToast('Failed to update status', isError: true);
    } finally {
      setState(() => _processing = false);
    }
  }

  Future<void> _handleHighlightAction() async {
    final willHighlight = !_user.featured;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
            willHighlight ? 'Highlight Instructor' : 'Remove Highlight',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Georgia')),
        content: Text(
            'Are you sure you want to ${willHighlight ? 'highlight' : 'unhighlight'} ${_user.username}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willHighlight ? 'Highlight' : 'Remove',
                style: const TextStyle(
                    color: Colors.orange, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _processing = true);
    try {
      if (_user.featured) {
        await _userService.unhighlightInstructor(_user.id!);
        _showToast('Instructor unhighlighted');
      } else {
        await _userService.highlightInstructor(_user.id!);
        _showToast('Instructor highlighted');
      }
      setState(() {
        _user = AppUser(
          userId: _user.userId,
          id: _user.id,
          username: _user.username,
          email: _user.email,
          role: _user.role,
          photo: _user.photo,
          accountStatus: _user.accountStatus,
          featured: !_user.featured,
          specialization: _user.specialization,
          totalCourses: _user.totalCourses,
          yearsOfExperience: _user.yearsOfExperience,
          linkedIn: _user.linkedIn,
          website: _user.website,
          studioName: _user.studioName,
          lastLoginDate: _user.lastLoginDate,
          createdAt: _user.createdAt,
        );
      });
    } catch (e) {
      _showToast('Failed to update highlight', isError: true);
    } finally {
      setState(() => _processing = false);
    }
  }

  void _showActionsMenu(BuildContext buttonContext) async {
    final isBanned = _user.accountStatus == 'INACTIVE';
    final isActiveInstructor =
        _user.role == 'INSTRUCTOR' && _user.accountStatus == 'ACTIVE';

    final RenderBox button =
        buttonContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final items = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'suspend',
        child: Row(
          children: [
            Icon(
              isBanned ? Icons.check_circle_outline_rounded : Icons.block_rounded,
              size: 18,
              color: isBanned ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 10),
            Text(
              isBanned ? 'Reinstate Account' : 'Suspend Account',
              style: TextStyle(
                color: isBanned ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
      if (isActiveInstructor)
        PopupMenuItem<String>(
          value: 'highlight',
          child: Row(
            children: [
              Icon(
                _user.featured ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 10),
              Text(
                _user.featured ? 'Remove Highlight' : 'Highlight Instructor',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
    ];

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      items: items,
    );

    if (result == 'suspend') {
      _handleBanAction();
    } else if (result == 'highlight') {
      _handleHighlightAction();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Account Information'),
                      const SizedBox(height: 16),
                      _buildInfoCard([
                        _buildDetailRow('Email Address', _user.email,
                            Icons.email_outlined),
                        _buildDivider(),
                        _buildDetailRow(
                            'Last Login',
                            _user.lastLoginDate?.substring(0, 10) ?? '—',
                            Icons.access_time_rounded),
                        _buildDivider(),
                        _buildDetailRow(
                            'Member Since',
                            _user.createdAt?.substring(0, 10) ?? '—',
                            Icons.calendar_today_rounded),
                      ]),

                      if (_user.role == 'INSTRUCTOR') ...[
                        const SizedBox(height: 32),
                        _buildSectionTitle('Instructor Profile'),
                        const SizedBox(height: 16),
                        _buildInfoCard([
                          _buildDetailRow('Specialization',
                              _user.specialization ?? 'Not set',
                              Icons.psychology_outlined),
                          _buildDivider(),
                          _buildDetailRow('Experience',
                              _user.yearsOfExperience ?? 'Not set',
                              Icons.history_edu_rounded),
                          _buildDivider(),
                          _buildDetailRow('Studio Name',
                              _user.studioName ?? 'Not set',
                              Icons.apartment_rounded),
                        ]),

                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Published Courses'),
                            if (!_loadingCourses)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_instructorCourses.length} Total',
                                  style: const TextStyle(
                                      color: AppTheme.primaryGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCoursesList(),
                      ] else if (_user.role == 'STUDENT') ...[
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle('Enrolled Courses'),
                            if (!_loadingStudentCourses)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGold.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_studentCourses.length} Total',
                                  style: const TextStyle(
                                      color: AppTheme.primaryGold,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildStudentCoursesList(),
                      ],

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      pinned: true,
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: AppTheme.textPrimary, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'User Overview',
        style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18),
      ),
      actions: [
        _processing
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: AppTheme.primaryGold, strokeWidth: 2)),
              )
            : Builder(
                builder: (btnCtx) => IconButton(
                  icon: const Icon(Icons.more_vert_rounded,
                      color: AppTheme.textPrimary),
                  onPressed: () => _showActionsMenu(btnCtx),
                ),
              ),
      ],
    );
  }

  /// Centered hero header with beige background — matches the design image
  Widget _buildHeroHeader() {
    final isBanned = _user.accountStatus == 'INACTIVE';
    final statusColor = _getStatusColor(_user.accountStatus);

    return Container(
      width: double.infinity,
      color: const Color(0xFFF0EAE0),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
      child: Column(
        children: [
          // Avatar
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  image: _user.photo != null
                      ? DecorationImage(
                          image: NetworkImage(ApiClient.formatMediaUrl(
                              '/api/files/${_user.photo}')),
                          fit: BoxFit.cover)
                      : null,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 6))
                  ],
                ),
                child: _user.photo == null
                    ? Center(
                        child: Text(
                          _user.username[0].toUpperCase(),
                          style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB89B4D)),
                        ),
                      )
                    : null,
              ),
              if (_user.featured)
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                      color: Colors.orange, shape: BoxShape.circle),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.white, size: 14),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Email
          Text(
            _user.email,
            style: const TextStyle(
                fontSize: 15,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 12),

          // Role + Status badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBadge(
                label: _user.role,
                textColor: const Color(0xFFB89B4D),
                borderColor: const Color(0xFFB89B4D),
                bgColor: Colors.transparent,
              ),
              const SizedBox(width: 10),
              _buildBadge(
                label: _user.accountStatus,
                textColor: statusColor,
                borderColor: statusColor,
                bgColor: statusColor.withOpacity(0.08),
              ),
              if (_user.featured && _user.role == 'INSTRUCTOR') ...[
                const SizedBox(width: 10),
                _buildBadge(
                  label: 'FEATURED',
                  textColor: Colors.orange,
                  borderColor: Colors.orange,
                  bgColor: Colors.orange.withOpacity(0.08),
                ),
              ],
            ],
          ),

          if (isBanned) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.block_rounded, color: Colors.red, size: 14),
                  SizedBox(width: 6),
                  Text('Account Suspended',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color textColor,
    required Color borderColor,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 0.5),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.green;
      case 'INACTIVE':
        return Colors.red;
      case 'PENDING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGold,
          letterSpacing: 1.2),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6D5)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFB89B4D).withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return const Divider(
        height: 1, thickness: 1, color: Color(0xFFF5F0E8), indent: 56);
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFFF5F0E8),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppTheme.primaryGold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoursesList() {
    if (_loadingCourses) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }
    if (_instructorCourses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(20)),
        child: const Text('No courses published yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return Column(
      children: _instructorCourses.map((c) => _buildCourseItem(c)).toList(),
    );
  }

  Widget _buildStudentCoursesList() {
    if (_loadingStudentCourses) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }
    if (_studentCourses.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            color: const Color(0xFFF5F0E8),
            borderRadius: BorderRadius.circular(20)),
        child: const Text('No enrolled courses yet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    return Column(
      children: _studentCourses.map((c) => _buildCourseItem(c)).toList(),
    );
  }

  Widget _buildCourseItem(Map<String, dynamic> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6D5)),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFFB89B4D).withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: () {
          final id = course['courseId'] ?? course['id'];
          if (id != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => AdminCourseDetailScreen(courseId: id)),
            );
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: course['thumbnailUrl'] != null
                    ? Image.network(
                        ApiClient.formatMediaUrl(course['thumbnailUrl']),
                        width: 65,
                        height: 65,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 65,
                        height: 65,
                        color: const Color(0xFFF5F0E8),
                        child: const Icon(Icons.movie_rounded,
                            color: Color(0xFFB89B4D))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course['title'] ?? 'Untitled',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: const Color(0xFFB89B4D).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                          child: Text(
                              course['categoryName'] ?? 'No Category',
                              style: const TextStyle(
                                  color: Color(0xFFB89B4D),
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          course['status'] ?? 'DRAFT',
                          style: TextStyle(
                            color: course['status'] == 'PUBLISHED'
                                ? Colors.green
                                : Colors.orange,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: Color(0xFFB89B4D)),
            ],
          ),
        ),
      ),
    );
  }
}
