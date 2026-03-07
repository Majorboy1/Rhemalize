import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sermon.dart';
import '../../providers/sermon_provider.dart';
import '../../providers/audio_provider.dart';
import '../../widgets/modals/add_episode_modal.dart';
import '../../widgets/modals/edit_episode_modal.dart';
import '../../utils/dialog_utils.dart';
import '../../utils/app_colors.dart';

class SeriesDetailScreen extends StatelessWidget {
  final Sermon series;

  const SeriesDetailScreen({super.key, required this.series});

  @override
  Widget build(BuildContext context) {
    // Detect theme for daylight/night persistence
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Fixed: Background color now responds to theme
      backgroundColor:
          isDarkMode ? const Color(0xFF121212) : const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: Text(
          series.title,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Fixed: AppBar background and icon colors

        elevation: 0,
        centerTitle: false,
        iconTheme:
            IconThemeData(color: isDarkMode ? Colors.white : Colors.black),
      ),
      body: Consumer<SermonProvider>(
        builder: (context, provider, child) {
          // Find the latest version of this series from the provider to ensure UI sync
          final currentSeries = provider.seriesMessages.firstWhere(
            (s) => s.id == series.id,
            orElse: () => series,
          );

          if (currentSeries.episodes.isEmpty) {
            return Center(
              child: Text(
                "No episodes added yet.",
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 16,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            itemCount: currentSeries.episodes.length,
            itemBuilder: (context, index) {
              final ep = currentSeries.episodes[index];
              return Card(
                elevation: isDarkMode ? 0 : 2,
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onTap: () {
                    // ADMIN TEST PLAYBACK
                    context.read<AudioProvider>().playEpisode(
                          currentSeries,
                          ep,
                          provider.seriesMessages,
                          PlaybackContext.library,
                        );
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryPurple,
                    child: const Icon(Icons.play_arrow, color: Colors.white),
                  ),
                  title: Text(
                    ep.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Episode ${ep.episodeNumber} • ${ep.speaker}",
                      style: TextStyle(
                        color: isDarkMode ? Colors.white60 : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () =>
                            _showEditEpisode(context, currentSeries.id, ep),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          // IMMEDIATE DELETE LOGIC
                          bool confirmed =
                              await DialogUtils.showDeleteConfirmation(
                                  context, "episode '${ep.title}'");

                          if (confirmed) {
                            try {
                              // Perform deletion in database via provider
                              await provider.deleteEpisode(
                                  currentSeries.id, ep.id);

                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text("Episode removed immediately"),
                                    backgroundColor: Colors.redAccent,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Error deleting: $e"),
                                    backgroundColor: Colors.black,
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryPurple,
        onPressed: () => _showAddEpisode(context),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Episode",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showAddEpisode(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEpisodeModal(
        seriesId: series.id,
        nextEpisodeNumber: series.episodes.length + 1,
      ),
    );
  }

  void _showEditEpisode(
      BuildContext context, String seriesId, Episode episode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditEpisodeModal(
        seriesId: seriesId,
        episode: episode,
      ),
    );
  }
}
