import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/instructor_payment.dart';
import '../../services/instructor_payment_service.dart';
import '../../services/instructor_service.dart';
import '../../utils/app_theme.dart';
import '../../providers/auth_provider.dart';

class InstructorPaymentScreen extends StatefulWidget {
  const InstructorPaymentScreen({super.key});

  @override
  State<InstructorPaymentScreen> createState() => _InstructorPaymentScreenState();
}

class _InstructorPaymentScreenState extends State<InstructorPaymentScreen> {
  final InstructorPaymentService _paymentService = InstructorPaymentService();
  final InstructorDashboardService _instructorService = InstructorDashboardService();
  
  String? _instructorId;
  StripeStatus? _status;
  List<InstructorEnrollmentRow> _enrollments = [];
  bool _loading = true;
  bool _onboarding = false;
  bool _managing = false;
  String _selectedMonth = 'All Time';
  List<String> _availableMonths = ['All Time'];
  
  String? _topStudentName;
  double _topStudentAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;

    setState(() => _loading = true);
    try {
      // 1. Resolve userId -> instructorId
      final profile = await _instructorService.getProfileByUserId(userId);
      _instructorId = profile.id;

      if (_instructorId == null || _instructorId!.isEmpty) {
        throw Exception('Could not resolve instructor profile.');
      }

      // 2. Fetch data using instructorId
      final status = await _paymentService.getStatus(_instructorId!);
      final enrollments = await _paymentService.getEnrollments(_instructorId!);
      
      if (mounted) {
        setState(() {
          _status = status;
          _enrollments = enrollments;
          _generateMonthList();
          _computeStats();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading payment data: $e')),
        );
      }
    }
  }

  Future<void> _startOnboarding() async {
    if (_instructorId == null) return;

    setState(() => _onboarding = true);
    try {
      final url = await _paymentService.getOnboardingLink(_instructorId!);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting onboarding: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _onboarding = false);
    }
  }

  Future<void> _manageStripeAccount() async {
    if (_instructorId == null) return;

    setState(() => _managing = true);
    try {
      final url = await _paymentService.getDashboardLink(_instructorId!);
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening Stripe dashboard: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _managing = false);
    }
  }

  void _generateMonthList() {
    final months = <String>{'All Time'};
    final formatter = DateFormat('MMMM yyyy');
    for (var e in _enrollments) {
      months.add(formatter.format(e.enrolledAt));
    }
    _availableMonths = months.toList();
    _availableMonths.sort((a, b) {
      if (a == 'All Time') return -1;
      if (b == 'All Time') return 1;
      return DateFormat('MMMM yyyy').parse(b).compareTo(DateFormat('MMMM yyyy').parse(a));
    });
  }

  void _computeStats() {
    _topStudentName = null;
    _topStudentAmount = 0;

    final monthFormatter = DateFormat('MMMM yyyy');
    final Map<String, double> studentSpending = {};

    for (var e in _enrollments) {
      final eMonth = monthFormatter.format(e.enrolledAt);
      if (_selectedMonth != 'All Time' && eMonth != _selectedMonth) continue;

      studentSpending[e.studentName] = (studentSpending[e.studentName] ?? 0) + (e.instructorShareCents / 100.0);
    }

    if (studentSpending.isNotEmpty) {
      final top = studentSpending.entries.reduce((a, b) => a.value > b.value ? a : b);
      _topStudentName = top.key;
      _topStudentAmount = top.value;
    }
  }

  double get _totalEarnings {
    final monthFormatter = DateFormat('MMMM yyyy');
    final filtered = _selectedMonth == 'All Time'
        ? _enrollments
        : _enrollments.where((e) => monthFormatter.format(e.enrolledAt) == _selectedMonth).toList();
    return filtered.fold(0, (sum, item) => sum + (item.instructorShareCents / 100.0));
  }

  int get _salesCount {
    final monthFormatter = DateFormat('MMMM yyyy');
    return _selectedMonth == 'All Time'
        ? _enrollments.length
        : _enrollments.where((e) => monthFormatter.format(e.enrolledAt) == _selectedMonth).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStripeStatusCard(),
          const SizedBox(height: 24),
          _buildEarningsSummary(),
          const SizedBox(height: 32),
          const Text(
            'ENROLLMENT HISTORY',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _enrollments.isEmpty ? _buildEmptyState() : _buildEnrollmentList(),
        ],
      ),
    );
  }

  Widget _buildStripeStatusCard() {
    final isConnected = _status?.chargesEnabled ?? false;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isConnected ? const Color(0xFFF0F9F4) : const Color(0xFFFFF9F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isConnected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                  color: isConnected ? Colors.green : Colors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Stripe Connected' : 'Stripe Not Ready',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.green.shade800 : Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    isConnected ? 'You are ready to receive payments.' : 'Complete setup to start earning.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isConnected ? Colors.green.shade600 : Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!isConnected)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onboarding ? null : _startOnboarding,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _onboarding
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Connect Stripe Account', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _managing ? null : _manageStripeAccount,
                    icon: _managing
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryGold))
                        : const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Manage Stripe Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGold,
                      side: const BorderSide(color: AppTheme.primaryGold),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEarningsSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'EARNINGS OVERVIEW',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGold,
                letterSpacing: 1.2,
              ),
            ),
            _buildFilterToggle(),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.darkGold, AppTheme.primaryGold],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedMonth == 'All Time' ? 'Total Lifetime Earnings' : 'Earnings in $_selectedMonth',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  if (_topStudentName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text('Top: $_topStudentName', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormat.currency(symbol: '\$').format(_totalEarnings),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'USD',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Sales', '$_salesCount'),
                    _buildDivider(),
                    _buildStatItem('Share', '80%'),
                    _buildDivider(),
                    _buildStatItem('Top Payout', NumberFormat.currency(symbol: '\$').format(_topStudentAmount)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 36,
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.paleGold.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primaryGold, size: 18),
          dropdownColor: AppTheme.pureWhite,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
          borderRadius: BorderRadius.circular(12),
          items: _availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedMonth = val;
                _computeStats();
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDivider() => Container(height: 24, width: 1, color: Colors.white24);

  Widget _buildEnrollmentList() {
    return Column(
      children: _enrollments.map((e) => _buildEnrollmentCard(e)).toList(),
    );
  }

  Widget _buildEnrollmentCard(InstructorEnrollmentRow enrollment) {
    final earnings = enrollment.instructorShareCents / 100.0;
    final date = DateFormat('MMM dd, yyyy').format(enrollment.enrolledAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6D5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.paleGold.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryGold),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    enrollment.courseTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Student: ${enrollment.studentName}',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '+\$${earnings.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                ),
                Text(
                  enrollment.enrollmentType,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFE6D5)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, size: 48, color: AppTheme.mediumGray.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text(
            'No earnings recorded yet.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
