import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

enum AdminTab { sermons, series, pastors, users, profile }

class AdminBottomNav extends StatelessWidget {
  final AdminTab activeTab;
  final ValueChanged<AdminTab>? onTabChange;

  const AdminBottomNav({
    super.key,
    required this.activeTab,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      height: 80 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white12 : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab(context, AdminTab.sermons, Icons.mic_none_rounded, 'Single',
              isDarkMode),
          _buildTab(context, AdminTab.series, Icons.library_music_outlined,
              'Series', isDarkMode),
          _buildTab(context, AdminTab.pastors, Icons.people_outline_rounded,
              'Pastors', isDarkMode),
          // New User Management Tab
          _buildTab(context, AdminTab.users, Icons.manage_accounts_outlined,
              'Users', isDarkMode),
          _buildTab(context, AdminTab.profile,
              Icons.admin_panel_settings_outlined, 'Admin', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, AdminTab tab, IconData icon,
      String label, bool isDarkMode) {
    final bool isActive = activeTab == tab;
    const activeColor = AppColors.primaryPurple;
    final inactiveColor = isDarkMode ? Colors.white38 : Colors.grey.shade500;

    return Expanded(
      child: InkWell(
        onTap: () => onTabChange?.call(tab),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 24, color: isActive ? activeColor : inactiveColor),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive ? activeColor : inactiveColor,
                  ),
                ),
              ],
            ),
            if (isActive)
              Positioned(
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 3,
                  decoration: BoxDecoration(
                    color: activeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
