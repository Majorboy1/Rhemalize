import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../screens/admin/upload_series_screen.dart';
import 'add_single_sermon_modal.dart';

class AddSermonModal extends StatelessWidget {
  const AddSermonModal({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 25),
          Text(
            "What would you like to upload?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 25),

          // Option 1: Single Message
          _buildOption(
            context,
            title: "Single Message",
            subtitle: "One-time Sunday or Wednesday sermon",
            icon: Icons.mic_none_rounded,
            onTap: () {
              Navigator.pop(context);
              _showSingleUpload(context);
            },
            isDark: isDark,
          ),

          const SizedBox(height: 16),

          // Option 2: Series Collection
          _buildOption(
            context,
            title: "Series Collection",
            subtitle: "Grouped messages with multiple episodes",
            icon: Icons.library_music_outlined,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const UploadSeriesScreen()),
              );
            },
            isDark: isDark,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey[50],
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryPurple.withOpacity(0.1),
              child: Icon(icon, color: AppColors.primaryPurple),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showSingleUpload(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSingleSermonModal(),
    );
  }
}
