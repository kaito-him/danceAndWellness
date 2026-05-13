import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../../models/instructor_profile.dart';

import '../../models/category.dart';
import '../../services/admin_application_service.dart';
import '../../services/category_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';

class AdminInstructorApplicationsTab extends StatefulWidget {
  const AdminInstructorApplicationsTab({super.key});

  @override
  State<AdminInstructorApplicationsTab> createState() => _AdminInstructorApplicationsTabState();
}

class _AdminInstructorApplicationsTabState extends State<AdminInstructorApplicationsTab> {
  final AdminApplicationService _applicationService = AdminApplicationService();
  final CategoryService _categoryService = CategoryService();

  List<InstructorProfile> _applications = [];
  List<Category> _categories = [];
  bool _loading = true;

  String _searchUsername = '';
  String _selectedCategory = '';
  String _selectedExperience = '';

  final List<String> _experienceOptions = [
    "Less than 1 year",
    "1–3 years",
    "3–5 years",
    "5–10 years",
    "10+ years",
  ];

  final Set<String> _processingUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _applicationService.getPendingApplications(),
        _categoryService.getCategories(),
      ]);
      if (mounted) {
        setState(() {
          _applications = results[0] as List<InstructorProfile>;
          _categories = results[1] as List<Category>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Failed to load applications', isError: true);
      }
    }
  }

  Future<void> _fetchApplications() async {
    setState(() => _loading = true);
    try {
      final apps = await _applicationService.searchApplications(
        username: _searchUsername,
        specialization: _selectedCategory,
        experience: _selectedExperience,
      );
      if (mounted) {
        setState(() {
          _applications = apps;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showToast('Search failed', isError: true);
      }
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.errorGold : AppTheme.successGold,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  Future<void> _handleApprove(InstructorProfile app) async {
    final confirm = await _showConfirmDialog(
      title: 'Approve Application',
      content: 'Are you sure you want to approve ${app.username} as an instructor?',
      confirmText: 'Approve',
      confirmColor: AppTheme.successGold,
    );

    if (confirm != true) return;

    setState(() => _processingUserIds.add(app.userId));
    try {
      await _applicationService.approveApplication(app.userId);
      _showToast('Instructor ${app.username} approved!');
      _loadData();
    } catch (e) {
      _showToast('Failed to approve application', isError: true);
    } finally {
      if (mounted) setState(() => _processingUserIds.remove(app.userId));
    }
  }

  Future<void> _handleDecline(InstructorProfile app) async {
    final confirm = await _showConfirmDialog(
      title: 'Decline Application',
      content: 'Are you sure you want to decline ${app.username}\'s application?',
      confirmText: 'Decline',
      confirmColor: AppTheme.errorGold,
    );

    if (confirm != true) return;

    setState(() => _processingUserIds.add(app.userId));
    try {
      await _applicationService.declineApplication(app.userId);
      _showToast('Application declined.');
      _loadData();
    } catch (e) {
      _showToast('Failed to decline application', isError: true);
    } finally {
      if (mounted) setState(() => _processingUserIds.remove(app.userId));
    }
  }

  Future<bool?> _showConfirmDialog({
    required String title,
    required String content,
    required String confirmText,
    required Color confirmColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        _buildFilters(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
              : _applications.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primaryGold,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) => _buildApplicationCard(_applications[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Instructor Applications',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_applications.length} Pending',
                  style: const TextStyle(
                    color: AppTheme.primaryGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Review and manage pending applications',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          TextField(
            onChanged: (val) {
              _searchUsername = val;
              _fetchApplications();
            },
            decoration: InputDecoration(
              hintText: 'Search by username...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.mediumGray),
              filled: true,
              fillColor: AppTheme.lightGray,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Category',
                  _selectedCategory,
                  ['', ..._categories.map((c) => c.name), 'Other'],
                  (val) {
                    setState(() {
                      _selectedCategory = val!;
                      _fetchApplications();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDropdown(
                  'Experience',
                  _selectedExperience,
                  ['', ..._experienceOptions],
                  (val) {
                    setState(() {
                      _selectedExperience = val!;
                      _fetchApplications();
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchUsername = '';
                    _selectedCategory = '';
                    _selectedExperience = '';
                  });
                  _loadData();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.filter_list_off_rounded, color: AppTheme.primaryGold, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          isExpanded: true,
          hint: Text('All $label', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
          items: items.map((s) => DropdownMenuItem(
            value: s,
            child: Text(s.isEmpty ? 'All $label' : s),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildApplicationCard(InstructorProfile app) {
    final dateFormat = DateFormat('MMM d, yyyy');
    String appliedDateStr = '—';
    if (app.appliedAt != null) {
      if (app.appliedAt is List && app.appliedAt.length >= 3) {
        appliedDateStr = dateFormat.format(DateTime(app.appliedAt[0], app.appliedAt[1], app.appliedAt[2]));
      } else {
        try {
          appliedDateStr = dateFormat.format(DateTime.parse(app.appliedAt.toString()));
        } catch (_) {}
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.paleGold.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGold.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                _buildAvatar(app),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(app.username,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary, fontFamily: 'Georgia')),
                      Text(app.email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('APPLIED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                    Text(appliedDateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0EAE0)),

          // ── Info Grid ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildInfoBlock('Specialization', app.specialization ?? '—')),
                    Expanded(child: _buildInfoBlock('Experience', app.yearsOfExperience ?? '—')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoBlock('Studio Name', app.studioName ?? '—'),

                if (app.bio != null && app.bio!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text('BIO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1)),
                  const SizedBox(height: 6),
                  Text(app.bio!, style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, height: 1.5)),
                ],

                const SizedBox(height: 20),
                const Text('RESOURCES & LINKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 1)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (app.linkedIn != null && app.linkedIn!.isNotEmpty)
                      _buildExternalLink(Icons.link_rounded, 'LinkedIn', app.linkedIn!),
                    if (app.website != null && app.website!.isNotEmpty)
                      _buildExternalLink(Icons.language_rounded, 'Website', app.website!),
                    if (app.certificationFileId != null)
                      _buildFileLink(app),
                  ],
                ),
              ],
            ),
          ),

          // ── Actions ──
          Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _processingUserIds.contains(app.userId) ? null : () => _handleDecline(app),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorGold,
                      side: const BorderSide(color: AppTheme.errorGold, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _processingUserIds.contains(app.userId) ? null : () => _handleApprove(app),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successGold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _processingUserIds.contains(app.userId)
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Approve Application', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.textSecondary, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
      ],
    );
  }

  Widget _buildExternalLink(IconData icon, String label, String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGold.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryGold.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryGold),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFileLink(InstructorProfile app) {
    return InkWell(
      onTap: () => _downloadAndOpenFile(app.certificationFileId!, app.certificationFileName ?? 'certification.pdf'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFC8E6C9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.description_outlined, size: 14, color: Color(0xFF2E7D32)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                app.certificationFileName ?? 'Certification',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAndOpenFile(String fileId, String fileName) async {
    _showToast('Downloading certification...');
    try {
      final dio = Dio();
      final url = ApiClient.formatMediaUrl('/api/files/$fileId');
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/$fileName';

      await dio.download(url, savePath);
      await OpenFile.open(savePath);
    } catch (e) {
      _showToast('Failed to open file', isError: true);
    }
  }

  Widget _buildAvatar(InstructorProfile app) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.paleGold,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
        image: app.photo != null
            ? DecorationImage(image: NetworkImage(ApiClient.formatMediaUrl('/api/files/${app.photo}')), fit: BoxFit.cover)
            : null,
      ),
      child: app.photo == null
          ? Center(child: Text(app.username[0].toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)))
          : null,
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.primaryGold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.successGold.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_outline_rounded, size: 64, color: AppTheme.successGold),
          ),
          const SizedBox(height: 20),
          const Text(
            'All caught up!',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Georgia'),
          ),
          const SizedBox(height: 8),
          const Text(
            'No pending instructor applications found.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
