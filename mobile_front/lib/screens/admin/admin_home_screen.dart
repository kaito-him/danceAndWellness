import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/app_drawer.dart';
import '../../utils/app_theme.dart';
import 'admin_profile_tab.dart';
import 'admin_courses_tab.dart';
import 'admin_accounts_tab.dart';
import 'admin_payments_tab.dart';
import 'admin_management_tabs.dart';
import 'admin_placeholder_tabs.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  String? _subSection;
  
  // To force refresh deep linked tabs
  Key _accountsKey = UniqueKey();
  Key _coursesKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().fetchUnreadCount();
    });
  }

  // Called by AppDrawer "Profile" tap to jump to the profile tab
  void goToProfile() => setState(() {
    _selectedIndex = 3;
    _subSection = null;
  });

  void onSectionTap(String section) {
    setState(() {
      _subSection = section;
      // If the section is a filtered version of an existing tab, we update those
      if (section == 'banned' || section == 'highlight') {
        _selectedIndex = 1; // Accounts tab
        _accountsKey = UniqueKey(); // Force rebuild with new initial filters
      } else if (section == 'archived') {
        _selectedIndex = 0; // Courses tab
        _coursesKey = UniqueKey();
      }
    });
  }

  List<Widget> get _tabs => [
    AdminCoursesTab(
      key: _coursesKey,
      initialSection: _subSection == 'archived' ? AdminCourseSection.archived : null,
    ),
    AdminAccountsTab(
      key: _accountsKey,
      initialStatusFilter: _subSection == 'banned' ? 'INACTIVE' : 'ALL',
      initialRoleFilter: _subSection == 'highlight' ? 'INSTRUCTOR' : 'ALL',
    ),
    const AdminPaymentsTab(),
    const AdminProfileTab(),
    const AdminBadgesTab(),
    const AdminCategoriesTab(),
  ];

  static const _tabMeta = [
    _TabMeta(Icons.menu_book_outlined,      Icons.menu_book_rounded,         'Courses'),
    _TabMeta(Icons.manage_accounts_outlined, Icons.manage_accounts_rounded,   'Accounts'),
    _TabMeta(Icons.payments_outlined,        Icons.payments_rounded,           'Payments'),
    _TabMeta(Icons.person_outline_rounded,   Icons.person_rounded,            'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppNavbar(
        title: _subSection != null ? _getSectionTitle(_subSection!) : 'Admin Dashboard',
        leading: _subSection != null ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => setState(() => _subSection = null),
        ) : null,
      ),
      drawer: AppDrawer(onProfileTap: goToProfile, onSectionTap: onSectionTap),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.pureWhite,
          border: Border(top: BorderSide(color: AppTheme.paleGold, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Color(0x18B89C4D),
              blurRadius: 12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List.generate(_tabMeta.length, (i) => _buildNavItem(i)),
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _subSection == 'badges' ? 4 : (_subSection == 'categories' ? 5 : _selectedIndex),
        children: _tabs,
      ),
    );
  }

  Widget _buildNavItem(int index) {
    final meta = _tabMeta[index];
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Indicator dot
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 3,
                width: isSelected ? 24 : 0,
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(
                isSelected ? meta.activeIcon : meta.icon,
                color: isSelected ? AppTheme.primaryGold : AppTheme.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                meta.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppTheme.primaryGold : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSectionTitle(String section) {
    switch (section) {
      case 'banned': return 'Banned Accounts';
      case 'highlight': return 'Highlight Instructors';
      case 'archived': return 'Archived Courses';
      case 'badges': return 'Manage Badges';
      case 'categories': return 'Manage Categories';
      default: return 'Admin Management';
    }
  }
}

class _TabMeta {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabMeta(this.icon, this.activeIcon, this.label);
}
