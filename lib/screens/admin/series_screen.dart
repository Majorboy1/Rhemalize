import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sermon.dart';
import '../../providers/sermon_provider.dart';
import '../../widgets/modals/add_sermon_modal.dart';
import '../../widgets/modals/edit_sermon_modal.dart';
import '../../utils/dialog_utils.dart';
import 'series_detail_screen.dart';
import '../../utils/app_colors.dart';

class SeriesScreen extends StatelessWidget {
  const SeriesScreen({super.key});

  void _editSeries(BuildContext context, Sermon sermon) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSermonModal(sermon: sermon),
    );
  }

  // The "Best Decision" immediate delete logic
  void _confirmDelete(BuildContext context, Sermon sermon) async {
    bool confirmed = await DialogUtils.showDeleteConfirmation(
        context, "series '${sermon.title}'");

    if (confirmed) {
      if (!context.mounted) return;

      try {
        // Immediate removal from Provider and Database
        await context.read<SermonProvider>().deleteSermon(sermon.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Series and all episodes removed immediately"),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : const Color(0xFFF8F9FB),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Sermon Series",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black)),
                ElevatedButton.icon(
                  onPressed: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddSermonModal(),
                  ),
                  icon: const Icon(Icons.folder_open),
                  label: const Text("New Series"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<SermonProvider>(
              builder: (context, provider, child) {
                final docs = provider.seriesMessages;
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (docs.isEmpty) {
                  return Center(
                      child: Text("No series found.",
                          style: TextStyle(
                              color:
                                  isDarkMode ? Colors.white54 : Colors.grey)));
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final sermon = docs[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SeriesDetailScreen(series: sermon),
                        ),
                      ),
                      child: _buildSeriesCard(context, sermon, isDarkMode),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(
      BuildContext context, Sermon sermon, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.04),
                blurRadius: 10)
          ]),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(sermon.imageUrl ?? '',
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: isDarkMode ? Colors.white10 : Colors.grey[200],
                    width: 70,
                    height: 70,
                    child: const Icon(Icons.folder))),
          ),
          const SizedBox(width: 15),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(sermon.title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black)),
              const SizedBox(height: 4),
              Text("${sermon.episodes.length} Episodes",
                  style: TextStyle(
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                      fontSize: 13)),
            ]),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                color: isDarkMode ? Colors.white70 : Colors.black54),
            onSelected: (val) {
              if (val == 'edit') _editSeries(context, sermon);
              if (val == 'delete') _confirmDelete(context, sermon);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text("Edit Series"),
                    ],
                  )),
              const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text("Delete", style: TextStyle(color: Colors.red)),
                    ],
                  )),
            ],
          )
        ],
      ),
    );
  }
}
