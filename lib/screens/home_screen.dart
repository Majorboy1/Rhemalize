import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sermon_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/sermon_card.dart';
import '../models/sermon.dart';
import '../screens/series_detail_screen.dart'; // Ensure this matches your filename

enum FilterCategory { all, sunday, wednesday }

enum FilterType { all, series, single }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  FilterCategory _selectedCategory = FilterCategory.all;
  FilterType _selectedType = FilterType.all;

  @override
  Widget build(BuildContext context) {
    final sermonProvider = context.watch<SermonProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final authProvider = context.read<AuthProvider>();

    // Optimized selector to prevent unnecessary rebuilds during audio playback
    final playedIds = context
        .select<AudioProvider, Set<String>>((pro) => pro.playedSermonIds);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sermons = sermonProvider.sermons;

    final filteredSermons = sermons.where((s) {
      bool catMatch = _selectedCategory == FilterCategory.all ||
          (s.category == SermonCategory.sunday &&
              _selectedCategory == FilterCategory.sunday) ||
          (s.category == SermonCategory.wednesday &&
              _selectedCategory == FilterCategory.wednesday);
      bool typeMatch = _selectedType == FilterType.all ||
          (s.messageType == MessageType.series &&
              _selectedType == FilterType.series) ||
          (s.messageType == MessageType.single &&
              _selectedType == FilterType.single);
      return catMatch && typeMatch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.primaryPurple,
      body: Stack(
        children: [
          _buildHeader(authProvider, sermons, isDark),
          Padding(
            padding: const EdgeInsets.only(top: 220),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFilters(sermons, isDark),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('All Sermons',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${filteredSermons.length} messages',
                            style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: filteredSermons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final sermon = filteredSermons[index];
                          return SermonCard(
                            sermon: sermon,
                            isFavorite: favoritesProvider.isFavorite(sermon.id),
                            isPlayed: playedIds.contains(sermon.id),
                            onToggleFavorite: () =>
                                favoritesProvider.toggleFavorite(sermon.id),
                            onPlay: () {
                              final audioPro = context.read<AudioProvider>();
                              if (sermon.messageType == MessageType.series) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SeriesDetailPage(
                                      series: sermon,
                                      allSermons:
                                          sermons, // FIXED: Added required argument
                                      onBack: () => Navigator.pop(context),
                                      playedSermons: playedIds,
                                      // FIXED: Removed undefined onPlayEpisode parameter
                                    ),
                                  ),
                                );
                              } else {
                                audioPro.playSermon(sermon, filteredSermons,
                                    PlaybackContext.home);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _buildHeader(
      AuthProvider authProvider, List<Sermon> sermons, bool isDark) {
    final sundayCount =
        sermons.where((s) => s.category == SermonCategory.sunday).length;
    final wednesdayCount =
        sermons.where((s) => s.category == SermonCategory.wednesday).length;
    final user = authProvider.user;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rhemalize',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  Text('Hear God’s Word Today',
                      style: TextStyle(color: Colors.white.withOpacity(0.7))),
                ],
              ),
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: user?.photoURL != null
                      ? Image.network(user!.photoURL!,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.person, color: Colors.white54))
                      : const Icon(Icons.person, color: Colors.white54),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _statCard('$sundayCount', 'Sunday Messages'),
              const SizedBox(width: 12),
              _statCard('$wednesdayCount', 'Wednesday Messages'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildFilters(List<Sermon> sermons, bool isDark) {
    final seriesCount =
        sermons.where((s) => s.messageType == MessageType.series).length;
    final singleCount =
        sermons.where((s) => s.messageType == MessageType.single).length;
    return Column(children: [
      Row(children: [
        _filterChip('All', _selectedCategory == FilterCategory.all, isDark,
            () => setState(() => _selectedCategory = FilterCategory.all)),
        const SizedBox(width: 8),
        _filterChip(
            'Sunday',
            _selectedCategory == FilterCategory.sunday,
            isDark,
            () => setState(() => _selectedCategory = FilterCategory.sunday)),
        const SizedBox(width: 8),
        _filterChip(
            'Wednesday',
            _selectedCategory == FilterCategory.wednesday,
            isDark,
            () => setState(() => _selectedCategory = FilterCategory.wednesday)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _filterChip('All Types', _selectedType == FilterType.all, isDark,
            () => setState(() => _selectedType = FilterType.all)),
        const SizedBox(width: 8),
        _filterChip('Series ($seriesCount)', _selectedType == FilterType.series,
            isDark, () => setState(() => _selectedType = FilterType.series)),
        const SizedBox(width: 8),
        _filterChip('Single ($singleCount)', _selectedType == FilterType.single,
            isDark, () => setState(() => _selectedType = FilterType.single)),
      ]),
    ]);
  }

  Widget _filterChip(
      String text, bool isActive, bool isDark, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryPurple
                : (isDark
                    ? Colors.white10
                    : AppColors.primaryPurple.withOpacity(0.05)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(text,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppColors.primaryPurple))),
          ),
        ),
      ),
    );
  }
}
