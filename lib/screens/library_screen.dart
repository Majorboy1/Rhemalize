// lib/screens/library_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sermon.dart';
import '../providers/favorites_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/sermon_provider.dart';
import '../widgets/sermon_card.dart';
import '../utils/app_colors.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String searchQuery = '';
  SortBy sortBy = SortBy.date;

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final allSermons = context.watch<SermonProvider>().sermons;

    final playedSermons = allSermons
        .where((s) => audioProvider.playedSermonIds.contains(s.id))
        .toList();

    List<Sermon> filtered = playedSermons.where((s) {
      final q = searchQuery.toLowerCase();
      return s.title.toLowerCase().contains(q) ||
          s.speaker.toLowerCase().contains(q);
    }).toList();

    // Sorting Logic
    if (sortBy == SortBy.date) {
      filtered.sort((a, b) => b.date.compareTo(a.date));
    } else {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
      body: CustomScrollView(
        slivers: [
          // 1. Sleek Modern Header
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  20, MediaQuery.of(context).padding.top + 70, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Library',
                        style: TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      if (playedSermons.isNotEmpty)
                        TextButton.icon(
                          onPressed: () =>
                              _showClearHistoryDialog(audioProvider),
                          icon: const Icon(Icons.delete_sweep_outlined,
                              size: 20, color: Colors.redAccent),
                          label: const Text("Clear",
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                    ],
                  ),
                  const Text("Your listening journey so far",
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            ),
          ),

          // 2. Search & Filter Bar (Sticky-style feel)
          SliverAppBar(
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            toolbarHeight: 80,
            titleSpacing: 20,
            title: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      onChanged: (v) => setState(() => searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search your history...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildSortToggle(),
              ],
            ),
          ),

          // 3. Content Logic
          playedSermons.isEmpty
              ? SliverFillRemaining(child: _buildEmptyState())
              : SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final s = filtered[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 15),
                          child: SermonCard(
                            sermon: s,
                            isFavorite: favoritesProvider.isFavorite(s.id),
                            onPlay: () => audioProvider.playSermon(
                                s, filtered, PlaybackContext.library),
                            onToggleFavorite: () =>
                                favoritesProvider.toggleFavorite(s.id),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildSortToggle() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
      ),
      child: IconButton(
        icon: Icon(
          sortBy == SortBy.date ? Icons.calendar_today : Icons.sort_by_alpha,
          color: AppColors.primaryPurple,
        ),
        onPressed: () {
          setState(() {
            sortBy = sortBy == SortBy.date ? SortBy.title : SortBy.date;
          });
        },
      ),
    );
  }

  void _showClearHistoryDialog(AudioProvider audio) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear History?"),
        content: const Text(
            "This will remove all recently played sermons from your library."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              audio
                  .clearPlayedHistory(); // Ensure this method exists in your AudioProvider
              Navigator.pop(context);
            },
            child: const Text("Clear All", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 80, color: Colors.grey.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            const Text("Your library is empty",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            const Text("Start listening to build your collection.",
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
}

enum SortBy { date, title }

