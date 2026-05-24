import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';
import '../../widgets/app_navbar.dart';
import '../../widgets/app_drawer.dart';
import 'student_home_tab.dart';
import 'student_search_tab.dart';
import 'student_library_tab.dart';
import 'student_messages_tab.dart';
import 'student_profile_tab.dart';

class StudentMainLayout extends StatefulWidget {
  const StudentMainLayout({super.key});

  @override
  State<StudentMainLayout> createState() => _StudentMainLayoutState();
}

class _StudentMainLayoutState extends State<StudentMainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const StudentHomeTab(),
    const StudentSearchTab(),
    const StudentLibraryTab(),
    const StudentMessagesTab(),
    const StudentProfileTab(),
  ];

  static const _tabMeta = [
    _TabMeta(Icons.home_outlined, Icons.home_rounded, 'Home'),
    _TabMeta(Icons.search_outlined, Icons.search_rounded, 'Search'),
    _TabMeta(Icons.video_library_outlined, Icons.video_library_rounded, 'Library'),
    _TabMeta(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Messages'),
    _TabMeta(Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  void goToProfile() {
    setState(() {
      _selectedIndex = 4;
    });
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0: return 'Student Hub';
      case 1: return 'Search Courses & Instructors';
      case 2: return 'My Library';
      case 3: return 'Conversations';
      case 4: return 'My Profile';
      default: return 'Student';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.pageBackground,
      appBar: AppNavbar(
        title: _getTabTitle(_selectedIndex),
      ),
      drawer: AppDrawer(
        onProfileTap: goToProfile,
      ),
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
        index: _selectedIndex,
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
        onTap: () => setState(() {
          _selectedIndex = index;
        }),
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
}

class _TabMeta {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabMeta(this.icon, this.activeIcon, this.label);
}
