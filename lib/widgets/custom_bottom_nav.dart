import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// Expanded enum for User Experience
enum BottomTab { home, search, favorites, library, testimonies, profile }

class BottomNav extends StatelessWidget {
  final BottomTab activeTab;
  final ValueChanged<BottomTab>? onTabChange;

  const BottomNav({
    super.key,
    required this.activeTab,
    this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final double bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      height: 70 + bottomInset,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.1)
                  : const Color(0xFFE5E7EB)),
        ),
      ),
      child: Row(
        children: [
          _buildTab(
              context, BottomTab.home, Icons.home_outlined, 'Home', isDarkMode),
          _buildTab(context, BottomTab.search, Icons.search_rounded, 'Search',
              isDarkMode),
          _buildTab(context, BottomTab.favorites, Icons.favorite_border_rounded,
              'Favorite', isDarkMode),
          _buildTab(context, BottomTab.library, Icons.my_library_music_outlined,
              'Library', isDarkMode),
          _buildTab(context, BottomTab.testimonies,
              Icons.record_voice_over_rounded, 'Testimonies', isDarkMode),
          _buildTab(context, BottomTab.profile, Icons.person_outline_rounded,
              'Profile', isDarkMode),
        ],
      ),
    );
  }

  Widget _buildTab(BuildContext context, BottomTab tab, IconData icon,
      String label, bool isDarkMode) {
    final bool isActive = activeTab == tab;
    const activeColor = AppColors.primaryPurple;
    final inactiveColor = isDarkMode ? Colors.white60 : Colors.grey;

    return Expanded(
      child: InkWell(
        onTap: () => onTabChange?.call(tab),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8.5,
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
                  width: 35,
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
