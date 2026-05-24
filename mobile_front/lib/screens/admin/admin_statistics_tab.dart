import 'package:flutter/material.dart';
import '../../models/overall_stats.dart';
import '../../models/today_stats.dart';
import '../../services/statistics_service.dart';
import '../../services/api_client.dart';
import '../../utils/app_theme.dart';

class AdminStatisticsTab extends StatefulWidget {
  const AdminStatisticsTab({super.key});

  @override
  State<AdminStatisticsTab> createState() => _AdminStatisticsTabState();
}

class _AdminStatisticsTabState extends State<AdminStatisticsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late StatisticsService _statisticsService;
  bool _isLoading = true;
  OverallStats? _overallStats;
  TodayStats? _todayStats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _statisticsService = StatisticsService(ApiClient());
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _statisticsService.getOverallStats(),
        _statisticsService.getTodayStats(),
      ]);
      setState(() {
        _overallStats = results[0] as OverallStats;
        _todayStats = results[1] as TodayStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: AppTheme.pureWhite,
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryGold,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryGold,
            tabs: const [
              Tab(text: 'Overall Stats'),
              Tab(text: 'Today\'s Activity'),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
              : _error != null
                  ? _buildErrorView()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverallStatsView(),
                        _buildTodayStatsView(),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGold),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStatsView() {
    if (_overallStats == null) return const SizedBox.shrink();
    final stats = _overallStats!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroGrid([
              _StatData('Total Revenue', '\$${stats.totalRevenueDollars.toStringAsFixed(2)}', Icons.attach_money, Colors.amber),
              _StatData('Total Students', stats.totalStudents.toString(), Icons.people, Colors.blue),
              _StatData('Total Instructors', stats.totalInstructors.toString(), Icons.person_pin, Colors.green),
              _StatData('Total Courses', stats.totalCourses.toString(), Icons.book, Colors.purple),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('Courses by Category'),
            _buildCategoryDistribution(stats.coursesByCategory, stats.publishedCourses),
            const SizedBox(height: 24),
            _buildSectionTitle('Enrollment Split'),
            _buildEnrollmentSplit(stats.paidEnrollments, stats.freeEnrollments, stats.totalEnrollments),
            const SizedBox(height: 24),
            _buildSectionTitle('User Health'),
            _buildStatusSummary([
              _StatusItem('Active Accounts', stats.activeAccounts, Icons.check_circle, Colors.green),
              _StatusItem('Banned Accounts', stats.bannedAccounts, Icons.block, Colors.red),
              _StatusItem('Pending Instructors', stats.pendingInstructorApplications, Icons.pending, Colors.orange),
            ]),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayStatsView() {
    if (_todayStats == null) return const SizedBox.shrink();
    final stats = _todayStats!;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroGrid([
              _StatData('Today\'s Revenue', '\$${stats.revenueTodayDollars.toStringAsFixed(2)}', Icons.trending_up, Colors.amber),
              _StatData('New Students', stats.newStudents.toString(), Icons.person_add, Colors.blue),
              _StatData('New Enrollments', stats.totalEnrollmentsToday.toString(), Icons.star, Colors.green),
              _StatData('New Courses', stats.newCourses.toString(), Icons.library_add, Colors.purple),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('Today\'s Category Split'),
            _buildCategoryDistribution(stats.enrollmentsByCategoryToday, stats.totalEnrollmentsToday),
            const SizedBox(height: 24),
            _buildSectionTitle('Today\'s Enrollment Type'),
            _buildEnrollmentSplit(stats.paidEnrollmentsToday, stats.freeEnrollmentsToday, stats.totalEnrollmentsToday),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroGrid(List<_StatData> data) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: data.length,
      itemBuilder: (context, index) {
        final item = data[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.pureWhite,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.paleGold.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: item.color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(item.icon, color: item.color, size: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                  Text(item.label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryGold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCategoryDistribution(Map<String, int> distribution, int total) {
    if (distribution.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppTheme.pureWhite, borderRadius: BorderRadius.circular(16)),
        child: const Text('No data available', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSecondary)),
      );
    }

    final sortedItems = distribution.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.paleGold.withOpacity(0.3)),
      ),
      child: Column(
        children: sortedItems.take(5).map((entry) {
          final percentage = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(entry.value.toString(), style: const TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: AppTheme.pageBackground,
                    color: AppTheme.primaryGold,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEnrollmentSplit(int paid, int free, int total) {
    final paidPercentage = total > 0 ? paid / total : 0.0;
    final freePercentage = total > 0 ? free / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.paleGold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildSplitInfo('Paid', paid, paidPercentage, Colors.amber),
              const SizedBox(width: 24),
              _buildSplitInfo('Free', free, freePercentage, Colors.grey),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                if (paidPercentage > 0) Expanded(flex: (paidPercentage * 100).toInt(), child: Container(height: 12, color: Colors.amber)),
                if (freePercentage > 0) Expanded(flex: (freePercentage * 100).toInt(), child: Container(height: 12, color: Colors.grey.shade300)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitInfo(String label, int count, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Row(
          children: [
            Text(count.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            Text('(${ (percentage * 100).toStringAsFixed(0) }%)', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSummary(List<_StatusItem> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.pureWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.paleGold.withOpacity(0.3)),
      ),
      child: Column(
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(item.icon, size: 18, color: item.color),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500))),
                Text(item.value.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  _StatData(this.label, this.value, this.icon, this.color);
}

class _StatusItem {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  _StatusItem(this.label, this.value, this.icon, this.color);
}
