import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sermon_provider.dart';
import '../providers/audio_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/sermon_card.dart';
import '../models/sermon.dart';
import '../screens/series_detail_screen.dart';

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
    final audioProvider = context.watch<AudioProvider>();
    final favoritesProvider = context.watch<FavoritesProvider>();
    final authProvider = context.watch<AuthProvider>();

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
          // Header Background and Info
          _buildHeader(authProvider, sermons, isDark),

          // Main Content Panel
          Padding(
            padding: const EdgeInsets.only(
                top: 220), // Adjusted to give the header room to breathe
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
                        padding: const EdgeInsets.only(bottom: 120),
                        itemCount: filteredSermons.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final sermon = filteredSermons[index];
                          return SermonCard(
                            sermon: sermon,
                            isFavorite: favoritesProvider.isFavorite(sermon.id),
                            isPlayed: audioProvider.playedSermonIds
                                .contains(sermon.id),
                            onToggleFavorite: () =>
                                favoritesProvider.toggleFavorite(sermon.id),
                            onPlay: () {
                              if (sermon.messageType == MessageType.series) {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SeriesDetailPage(
                                              series: sermon,
                                              onBack: () =>
                                                  Navigator.pop(context),
                                              onPlayEpisode: (ep) =>
                                                  audioProvider.playEpisode(
                                                      sermon,
                                                      ep,
                                                      filteredSermons,
                                                      PlaybackContext.home),
                                              playedSermons:
                                                  audioProvider.playedSermonIds,
                                            )));
                              } else {
                                audioProvider.playSermon(sermon,
                                    filteredSermons, PlaybackContext.home);
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

  Widget _buildHeader(
      AuthProvider authProvider, List<Sermon> sermons, bool isDark) {
    final sundayCount =
        sermons.where((s) => s.category == SermonCategory.sunday).length;
    final wednesdayCount =
        sermons.where((s) => s.category == SermonCategory.wednesday).length;
    final user = authProvider.user;

    return Container(
      // Reduced top and bottom padding to fit the header within the available space
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
                key: ValueKey(user?.photoURL),
                radius: 22,
                backgroundColor: Colors.white24,
                child: ClipOval(
                  child: user?.photoURL != null
                      ? Image.network(
                          user!.photoURL!,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white);
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, color: Colors.white54),
                        )
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

class HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
        size.width * 0.5, size.height + 10, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> old) => false;
}
