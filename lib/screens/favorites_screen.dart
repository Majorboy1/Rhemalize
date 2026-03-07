import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/audio_provider.dart';
import '../widgets/sermon_card.dart';
import '../utils/app_colors.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final favoritesProvider = context.watch<FavoritesProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final favoriteItems = favoritesProvider.favoriteSermons;

    return Scaffold(
      backgroundColor: AppColors.primaryPurple,
      body: Stack(
        children: [
          _buildHeader(favoriteItems.length),
          Padding(
            padding: const EdgeInsets.only(top: 180),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32)),
              ),
              child: favoriteItems.isEmpty
                  ? const Center(child: Text('No favorites yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 120),
                      itemCount: favoriteItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = favoriteItems[index];
                        return SermonCard(
                          sermon: item,
                          isFavorite: true,
                          isPlayed:
                              audioProvider.playedSermonIds.contains(item.id),
                          onPlay: () => audioProvider.playSermon(
                              item, favoriteItems, PlaybackContext.library),
                          onToggleFavorite: () =>
                              favoritesProvider.toggleFavorite(item.id),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('My Favorites',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        Text('$count saved messages',
            style: TextStyle(color: Colors.white.withAlpha(180))),
      ]),
    );
  }
}
