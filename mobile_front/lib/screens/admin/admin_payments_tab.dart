import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/admin_payment.dart';
import '../../services/admin_payment_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';
import 'admin_user_detail_screen.dart';
import '../../models/app_user.dart';

class AdminPaymentsTab extends StatefulWidget {
  const AdminPaymentsTab({super.key});

  @override
  State<AdminPaymentsTab> createState() => _AdminPaymentsTabState();
}

class _AdminPaymentsTabState extends State<AdminPaymentsTab> {
  final AdminPaymentService _paymentService = AdminPaymentService();
  bool _loading = true;
  AdminRevenueSummary? _summary;
  List<AdminTransaction> _allTransactions = [];
  
  // Analytics State
  String _selectedMonth = 'All Time';
  List<String> _availableMonths = ['All Time'];
  
  // Computed Stats
  double _filteredRevenue = 0;
  List<AdminTransaction> _filteredTransactions = [];
  Map<String, double> _instructorEarnings = {};
  Map<String, double> _studentSpending = {};
  
  String? _topInstructorName;
  String? _topInstructorId;
  double _topInstructorAmount = 0;
  
  String? _topStudentName;
  String? _topStudentId;
  double _topStudentAmount = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _loading = true);
    try {
      final summary = await _paymentService.getSummary();
      final transactions = await _paymentService.getTransactions();
      
      if (mounted) {
        _summary = summary;
        _allTransactions = transactions;
        _generateMonthList();
        _computeStats();
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load financial data')),
        );
      }
    }
  }

  void _generateMonthList() {
    final months = <String>{'All Time'};
    final formatter = DateFormat('MMMM yyyy');
    for (var t in _allTransactions) {
      months.add(formatter.format(t.date));
    }
    _availableMonths = months.toList();
    _availableMonths.sort((a, b) {
      if (a == 'All Time') return -1;
      if (b == 'All Time') return 1;
      return DateFormat('MMMM yyyy').parse(b).compareTo(DateFormat('MMMM yyyy').parse(a));
    });
  }

  void _computeStats() {
    _instructorEarnings.clear();
    _studentSpending.clear();
    _filteredRevenue = 0;
    _filteredTransactions = [];

    final monthFormatter = DateFormat('MMMM yyyy');

    for (var t in _allTransactions) {
      final tMonth = monthFormatter.format(t.date);
      if (_selectedMonth != 'All Time' && tMonth != _selectedMonth) continue;

      _filteredTransactions.add(t);
      _filteredRevenue += t.platformFee;

      // Track Instructor Earnings (20% platform fee is based on this)
      // Actually instructor gets 80%, platform gets 20%. 
      // Profit for instructor is 80% of total.
      final instructorAmount = t.totalAmount * 0.8;
      _instructorEarnings[t.instructorName] = (_instructorEarnings[t.instructorName] ?? 0) + instructorAmount;

      // Track Student Spending
      _studentSpending[t.studentName] = (_studentSpending[t.studentName] ?? 0) + t.totalAmount;
    }

    // Find Top Instructor
    if (_instructorEarnings.isNotEmpty) {
      final topInst = _instructorEarnings.entries.reduce((a, b) => a.value > b.value ? a : b);
      _topInstructorName = topInst.key;
      _topInstructorAmount = topInst.value;
      // Find ID
      _topInstructorId = _allTransactions.firstWhere((t) => t.instructorName == topInst.key).instructorId;
    } else {
      _topInstructorName = null;
      _topInstructorId = null;
      _topInstructorAmount = 0;
    }

    // Find Top Student
    if (_studentSpending.isNotEmpty) {
      final topStud = _studentSpending.entries.reduce((a, b) => a.value > b.value ? a : b);
      _topStudentName = topStud.key;
      _topStudentAmount = topStud.value;
      // Find ID
      _topStudentId = _allTransactions.firstWhere((t) => t.studentName == topStud.key).studentId;
    } else {
      _topStudentName = null;
      _topStudentId = null;
      _topStudentAmount = 0;
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '$', decimalDigits: 2).format(amount);
  }

  void _navigateToUser(String userId, String role) {
    // We need to construct a partial AppUser or fetch the full one.
    // For now, I'll navigate with a placeholder AppUser and let the Detail screen handle it.
    // Actually, AdminUserDetailScreen requires an AppUser.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserDetailScreen(
          user: AppUser(
            userId: userId,
            username: role == 'INSTRUCTOR' ? _topInstructorName ?? 'User' : _topStudentName ?? 'User',
            email: 'Loading...',
            role: role,
            accountStatus: 'ACTIVE',
          ),
        ),
      ),
    );
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
          _buildMonthSelector(),
          const SizedBox(height: 24),
          _buildRevenueHero(),
          const SizedBox(height: 24),
          _buildTopPerformers(),
          const SizedBox(height: 32),
          _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMonth,
          isExpanded: true,
          items: _availableMonths.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          onChanged: (val) {
            setState(() {
              _selectedMonth = val!;
              _computeStats();
            });
          },
        ),
      ),
    );
  }

  Widget _buildRevenueHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGold, AppTheme.primaryGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryGold.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Platform Profit (20%)', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(_selectedMonth, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(_formatCurrency(_filteredRevenue), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildMiniStat(Icons.swap_horiz_rounded, '${_filteredTransactions.length}', 'Transactions'),
              const SizedBox(width: 24),
              _buildMiniStat(Icons.today_rounded, _formatCurrency(_summary?.todayRevenue ?? 0), "Today's Take"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white60, size: 14),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
          ],
        ),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTopPerformers() {
    return Row(
      children: [
        Expanded(child: _buildPerformerCard('Top Instructor', _topInstructorName, _topInstructorAmount, Colors.blue, () {
          if (_topInstructorId != null) _navigateToUser(_topInstructorId!, 'INSTRUCTOR');
        })),
        const SizedBox(width: 16),
        Expanded(child: _buildPerformerCard('Top Student', _topStudentName, _topStudentAmount, Colors.green, () {
          if (_topStudentId != null) _navigateToUser(_topStudentId!, 'STUDENT');
        })),
      ],
    );
  }

  Widget _buildPerformerCard(String title, String? name, double amount, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: name != null ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.paleGold.withOpacity(0.5)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(name ?? 'N/A', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(_formatCurrency(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 8),
            const Row(
              children: [
                Text('View Profile', style: TextStyle(fontSize: 10, color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right_rounded, size: 12, color: AppTheme.primaryGold),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        const SizedBox(height: 16),
        ..._filteredTransactions.map((t) => _buildTransactionItem(t)),
        if (_filteredTransactions.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No transactions for this period', style: TextStyle(color: AppTheme.textSecondary)))),
      ],
    );
  }

  Widget _buildTransactionItem(AdminTransaction t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryGold.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: AppTheme.primaryGold, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _navigateToUser(t.studentId, 'STUDENT'),
                      child: Text(t.studentName, style: const TextStyle(fontSize: 12, color: AppTheme.primaryGold, decoration: TextDecoration.underline)),
                    ),
                    const Text(' → ', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    GestureDetector(
                      onTap: () => _navigateToUser(t.instructorId, 'INSTRUCTOR'),
                      child: Text(t.instructorName, style: const TextStyle(fontSize: 12, color: AppTheme.primaryGold, decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_formatCurrency(t.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary)),
              Text('+${_formatCurrency(t.platformFee)}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
              Text(DateFormat('MMM dd').format(t.date), style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
